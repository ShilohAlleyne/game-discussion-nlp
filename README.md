# Web scraping

Forum post titles where scraped from two sources, [Itch.IO General Discussions](https://itch.io/community) and [Steam Community Discussions](https://steamcommunity.com/discussions/) using the programming language F#. In total 2970 different titles where collected from Itch and further 6196 from Steam. Each title then underwent lexical analysis using the [SentenceTransformers (SBERT)](https://sbert.net/) python library.

# Topic Modeling with Bert

The SentenceTransformers (SBERT) library was used to find the semantic similarity between post titles in from each source and group them into overarching topics. SBERT has applications in:
- Semantic search
- Paraphrase mining
- Textual similarity
- Question answering
- Document clustering

In this work we are focused on Paraphrase mining and Document (forum titles) clustering. SBERT works by encoding each sentence into a dense vector representation to capture semantic meaning.
- SBERT contains 10,000 pre-trained models and in this work we made use of the model: `all-MiniLM-L6-v2`.

**Top 25 Most Captured topics**

| Topic Ranking | Steam Posts | Steam Topic                             | Itch Posts | Itch Topic                              |
|---------------|-------------|-----------------------------------------|------------|-----------------------------------------|
| 1             | 2275        | the_is_of_on                            | 1146       | games_to_you_how                        |
| 2             | 247         | putin_vac_ya_squad                      | 225        | itchio_itch_on_the                      |
| 3             | 107         | market_inventory_community_open         | 116        | notgdc_notatgdc_but_gdc                 |
| 4             | 85          | de_el_para_que                          | 88         | find_help_remember_played               |
| 5             | 68          | account_hacked_got_ea                   | 67         | dev_devs_developer_journey              |
| 6             | 67          | life_you_die_woke                       | 66         | youtube_channel_youtubers_play          |
| 7             | 60          | gift_gifting_region_card                | 56         | jam_jams_join_game                      |
| 8             | 60          | controller_xbox_controllers_switch      | 55         | de_en_chinese_localization              |
| 9             | 60          | looking_recommend_game_games            | 55         | indie_marketing_devs_postmortem         |
| 10            | 57          | cs2_cs_cheaters_vac                     | 51         | mobile_android_your_first               |
| 11            | 54          | idk_go_guh_haha                         | 42         | browser_html5_html_pages                |
| 12            | 54          | library_free_dlc_delete                 | 41         | bundle_coop_ultimate_bundles            |
| 13            | 52          | banned_ban_moderators_unban             | 35         | download_downloads_downloading_views    |
| 14            | 50          | 11_windows_10_civ                       | 34         | ai_chat_aigenerated_aipowered           |
| 15            | 48          | deck_steamdeck_diablo_lossless          | 34         | hello_hi_hey_nice                       |
| 16            | 45          | overlay_guide_performance_scale         | 34         | horror_looking_some_combat              |
| 17            | 43          | help_need_me_title                      | 33         | error_mac_not_cant                      |
| 18            | 42          | auf_ashuvaxpretentieux_iossteam_nba2k26 | 29         | ideas_idea_spread_game                  |
| 19            | 42          | music_metal_song_rock                   | 28         | championship_enter_imga_global          |
| 20            | 41          | reviews_review_neutral_filter           | 27         | money_make_pay_much                     |
| 21            | 41          | mac_linux_os_windows                    | 27         | visual_novel_novels_furry               |
| 22            | 40          | ui_store_old_new                        | 24         | music_composer_listen_listening         |
| 23            | 40          | achievements_achievement_showcase_dlc   | 24         | sale_music_packs_50                     |
| 24            | 40          | friends_looking_friend_making           | 23         | recommend_any_recommendations_games     |
| 25            | 40          | gpu_rtx_upgrade_gtx                     | 22         | publish_publishing_publishers_publisher |


The rest of the captured topics can be seen at:
- `./data/itch_topics.csv`
- `./data/steam_topics.csv`


# Visitation with Plotly

The SBERT library has a self contain Visitation framework which exports a [Plotly](https://plotly.com/python/) interactive graph, where users can isolate and zoom in different topic regions. Static images of these graphs can be found in `./docs/plots/` in this repo.

**Itch IO Topics and Posts**
![Itch IO topics](./docs/plots/itch_topic_graph.png)

**Steam Topics and Posts**
![Steam topics](./docs/plots/steam_topic_graph.png)

## How to Run the interactive graphs

Python and the dependencies in `.venv` are required

1. Clone this repo using git clone
```bash
git clone [REPO]
```
2. In the command line run the python scrip and specify which source you want to graph
```bash
python nlp.py "steam"
```
3. The interactive graph will open in browser

# Further Research

More forums can be scraped for other sources such as Reddit and further sub-forums from Steam and Itch could also be analysed.

## Citations 

The relevant citations for this research can be found in the docs folder in this repo
