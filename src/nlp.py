import sys
import time
import pandas as pd
import plotly.io as pio

from sentence_transformers import SentenceTransformer, util
from bertopic import BERTopic
from sklearn.datasets import fetch_20newsgroups
from umap import UMAP


pio.renderers.default = "browser"

# 1. Load a pretrained Sentence Transformer model
model = SentenceTransformer("all-MiniLM-L6-v2")


def topic_model(src, embeddings, sentences):
    topic_model = BERTopic()

    # Train BERTopic
    topic_model = topic_model.fit(sentences, embeddings)

    # Save topics
    df = get_topics_dataframe(topic_model)
    df.to_csv(f"./data/{src}_topics.csv", index=False)

    # Run the visualization with the original embeddings
    topic_model.visualize_documents(sentences, embeddings=embeddings)

    # Reduce dimensionality of embeddings, this step is optional but much faster to perform iteratively:
    reduced_embeddings = UMAP(
        n_neighbors=10, n_components=2, min_dist=0.0, metric="cosine"
    ).fit_transform(embeddings)
    fig = topic_model.visualize_documents(
        sentences,
        embeddings=embeddings,
        title=f"{src.capitalize()} Posts and Topics",
    )

    # show and save
    fig.show()
    fig.write_image(f"./docs/plots/{src}_topic_graph.png")

def get_topics_dataframe(topic_model):
    topic_info = topic_model.get_topic_info()
    # Clean the Name column by removing the leading topic number and underscore
    topic_info["Cleaned Name"] = topic_info["Name"].apply(
        lambda name: name.split("_", 1)[1] if "_" in name else name
    )
    # Select and rename columns for clarity
    df = topic_info[["Topic", "Count", "Cleaned Name"]].rename(columns={"Cleaned Name": "Name"})
    return df

def cluster(embeddings, sentences):
    print("Start clustering")
    start_time = time.time()

    clusters = util.community_detection(
        embeddings, min_community_size=10, threshold=0.75
    )

    print(f"Clustering done after {time.time() - start_time:.2f} sec")

    for i, cluster in enumerate(clusters):
        print(f"\nCluster {i + 1}, #{len(cluster)} Elements ")
        for sentence_id in cluster[0:3]:
            print("\t", sentences[sentence_id])
        print("\t", "...")
        for sentence_id in cluster[-3:]:
            print("\t", sentences[sentence_id])


def run():
    src = sys.argv[1]

    # The sentences to encode
    with open(f"./data/{src}.txt", "r", encoding="utf-8") as file:
        lines = [line.strip() for line in file]

    # 2. Calculate embeddings by calling model.encode()
    embeddings = model.encode(lines, batch_size=64, show_progress_bar=True)

    # 3 Cluster sentences based on topics
    cluster(embeddings, lines)

    # 4 Visualize topics
    topic_model(src, embeddings, lines)


run()
