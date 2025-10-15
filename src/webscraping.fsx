#r "nuget: Deedle"
#r "nuget: FSharp.Data, 5.0.2"
#r "nuget: Selenium.WebDriver"
#r "nuget: Selenium.WebDriver.ChromeDriver"

open OpenQA.Selenium
open OpenQA.Selenium.Chrome
open OpenQA.Selenium.Support.UI
open System
open System.IO
open System.Diagnostics
open Deedle
open FSharp.Collections
open FSharp.Data

let chromedriverPath = System.Environment.GetEnvironmentVariable("CHROMEDRIVER_PATH")
let chromePath       = System.Environment.GetEnvironmentVariable("CHROME_PATH")
let service          = ChromeDriverService.CreateDefaultService(chromedriverPath)

// ─────────────────────────────────────────────────────────────
// Logging
// ─────────────────────────────────────────────────────────────
let timestamp () : string =
    System.DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm")

let logScrapeProgress (target: string) (pageIndex: int) (total: int) (progress: float) =
    printf $"\r{timestamp()} | Scraping {target} -> page {pageIndex} of {total} [{progress:F1}%%]"

let extractPrefix (url: string) : string =
    let prefixStart = "https://".Length
    let afterProtocol = url.Substring(prefixStart)
    let cleaned = afterProtocol.Replace(".", " ")
    let takeCount = if afterProtocol.StartsWith(".") then 4 else 5
    cleaned.Substring(0, min takeCount cleaned.Length)


// ─────────────────────────────────────────────────────────────
// Webscraping
// ─────────────────────────────────────────────────────────────
let generateSteamForumUntils () : (string * string) list =
    [30; 1; 10; 0; 2; 8; 7; 11; 12]
    |> List.map (fun n -> 
        match n with
        | 0 -> ("https://steamcommunity.com/discussions/forum/0/",    "#forum_General_4009259_pagebtn_next")
        | n -> ($"https://steamcommunity.com/discussions/forum/{n}/", $"#forum_General_4009259_{n}_pagebtn_next"))

let scrapePage (url: string) (trgtCSS: string) : string list =
    let page = HtmlDocument.Load(url)
    page.CssSelect trgtCSS
    |> Seq.map (fun el -> el.DirectInnerText().Trim())
    |> Seq.toList

let loadNextPageSafe (url: string) (nextpg: string) : string option =
    try
        let options = ChromeOptions()
        options.BinaryLocation <- chromePath
        options.AddArgument("--headless=new")
        options.AddArgument("--no-sandbox")
        options.AddArgument("--window-size=1920,1080")

        use driver = new ChromeDriver(service, options)
        driver.Navigate().GoToUrl(url)

        let nextPage = driver.FindElement(By.CssSelector(nextpg))
        nextPage.Click()

        let wait = WebDriverWait(driver, TimeSpan.FromSeconds(10.0))
        wait.Until(fun d -> d.Url <> url) |> ignore

        Some driver.Url
    with
    | _ ->
        printfn $"{timestamp()} | [WARN] Failed to load next page from {url}"
        None

let rec scrapePages (url: string) (n: int) (total: int) (nextpg: string) (trgtCSS: string) : string list list =
    if n = 0 then
        []
    else
        let pageIndex = total - n + 1
        let progress  = float pageIndex / float total * 100.0
        logScrapeProgress (extractPrefix url) pageIndex total progress

        let pageResults = scrapePage url trgtCSS
        
        match loadNextPageSafe url nextpg with
        | Some nextUrl -> pageResults :: scrapePages nextUrl (n - 1) total nextpg trgtCSS
        | None ->
            printfn $"{timestamp()} | No next page found. Stopping at page %d{pageIndex}"
            [pageResults]


// ─────────────────────────────────────────────────────────────
// Python FFI
// ─────────────────────────────────────────────────────────────
let runPython (scriptPath: string) (args: string) : int =
    let psi = ProcessStartInfo()
    psi.FileName               <- "python"
    psi.Arguments              <- $"\"{scriptPath}\" {args}"
    psi.UseShellExecute        <- false
    psi.CreateNoWindow         <- true
    psi.RedirectStandardError  <- false
    psi.RedirectStandardOutput <- false

    printfn $"{timestamp()} | starting python process [{args}]"
    use proc = new Process()
    proc.StartInfo <- psi
    proc.Start() |> ignore
    proc.WaitForExit()

    let exitCode = proc.ExitCode
    
    match exitCode with
    | 0   -> printfn $"{timestamp()} | python process [{args}] completed successfully"
    | err -> printfn $"{timestamp()} | python process failed with error code: {err}"

    exitCode


// ─────────────────────────────────────────────────────────────
// Run code
// ─────────────────────────────────────────────────────────────
let run () : unit =

    let itchResults =
        scrapePages "https://itch.io/board/10017/general-discussion" 500 500 ".page_link.forward_link" ".topic_link"
        |> List.concat
        |> Set.ofList
        |> Set.toList

     File.WriteAllLines("./data/itch.txt", itchResults)

    printfn ""
    let steamResults =
        generateSteamForumUntils()
        |> List.collect (fun (url, nxtpg) -> scrapePages url 500 500 nxtpg ".forum_topic_name")
        |> List.concat
        |> Set.ofList
        |> Set.toList

    File.WriteAllLines("./data/steam.txt", steamResults)

    printfn ""
    let finalStatus =
        match runPython "nlp.py" "itch" with
        | 0    -> runPython "nlp.py" "steam"
        | code -> code

    printfn $"{timestamp()} | finished all processes with exit code: {finalStatus}"

run()
