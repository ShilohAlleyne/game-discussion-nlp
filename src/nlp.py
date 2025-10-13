import sys
import spacy
import pandas as pd
from sentence_transformers import SentenceTransformer


# 1. Load a pretrained Sentence Transformer model
model = SentenceTransformer("all-MiniLM-L6-v2")


def run():
    src = sys.argv[1]

    # The sentences to encode
    with open(f"../data/{src}.txt", "r", encoding="utf-8") as file:
        lines = [line.strip() for line in file]

    # 2. Calculate embeddings by calling model.encode()
    embeddings = model.encode(lines, convert_to_tensor=True)

    # 3. Calculate the embedding similarities
    similarities = model.similarity(embeddings, embeddings)

    df = pd.DataFrame(similarities.numpy())
    
    # save
    df.to_csv(f"../data/{src}.csv", index=True)

run()
