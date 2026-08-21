import pandas as pd
import random
import re

INPUT_FILE = "data/queries.csv"
OUTPUT_FILE = "data/queries_expanded.csv"
TARGET_PER_CLASS = 1000

random.seed(42)

# -----------------------------
# Load dataset
# -----------------------------
df = pd.read_csv(INPUT_FILE)

if "text" not in df.columns or "label" not in df.columns:
    raise ValueError("CSV must contain columns: text,label")

df = df.dropna(subset=["text", "label"])
df["text"] = df["text"].astype(str).str.strip()
df["label"] = df["label"].astype(str).str.strip()

df = df.drop_duplicates(subset=["text", "label"])

print("Original dataset:")
print(df["label"].value_counts())
print("Total:", len(df))


# -----------------------------
# General variations
# -----------------------------
prefixes = [
    "",
    "please ",
    "can you ",
    "could you ",
    "help me ",
    "i want to know ",
    "i need to know ",
    "tell me ",
    "can you tell me ",
    "could you tell me ",
]


# -----------------------------
# Study-specific endings
# -----------------------------
explain_endings = [
    "",
    " in simple words",
    " simply",
    " in an easy way",
    " step by step",
    " for beginners",
    " clearly",
    " with an example",
    " in detail",
    " in simple terms",
]

summary_endings = [
    "",
    " briefly",
    " in simple words",
    " for quick revision",
    " in a few points",
    " concisely",
    " for my exam",
    " in short",
]

notes_endings = [
    "",
    " in simple language",
    " for revision",
    " for my exam",
    " in a structured format",
    " with important points",
    " with headings",
    " in concise form",
]

quiz_endings = [
    "",
    " for practice",
    " for my exam",
    " for revision",
    " with answers",
    " with multiple choice options",
    " at beginner level",
    " at intermediate level",
]

flashcard_endings = [
    "",
    " for revision",
    " for my exam",
    " in simple language",
    " with questions and answers",
    " for quick revision",
    " covering important concepts",
]


# -----------------------------
# Generic variations
# -----------------------------
generic_prefixes = [
    "",
    "please ",
    "can you ",
    "could you ",
    "help me ",
    "i need help to ",
    "i want to ",
    "can you help me ",
    "could you help me ",
    "please help me ",
]

generic_endings = [
    "",
    " please",
    " for me",
    " if possible",
    " when you can",
    " right now",
    " today",
    " this weekend",
    " for this evening",
]

generic_replacements = {
    "what is a good": [
        "what is a good",
        "what is a great",
        "can you recommend a good",
        "can you suggest a good",
        "what would be a good",
    ],
    "recommend": [
        "recommend",
        "suggest",
        "give me recommendations for",
        "help me find",
        "can you suggest",
    ],
    "suggest": [
        "suggest",
        "recommend",
        "give me some ideas for",
        "can you suggest",
        "can you recommend",
    ],
    "help me": [
        "help me",
        "can you help me",
        "could you help me",
        "please help me",
    ],
}


# -----------------------------
# Cleaning
# -----------------------------
def clean_text(text):
    text = re.sub(r"\s+", " ", text).strip()
    text = re.sub(r"\s+([?.!,])", r"\1", text)
    return text


# -----------------------------
# Generate variations
# -----------------------------
def generate_variations(text, label):
    text = clean_text(text)
    variations = set()

    variations.add(text)
    variations.add(text.lower())

    if label == "generic":

        base = text.lower()

        # Prefix variations
        for prefix in generic_prefixes:
            candidate = prefix + base

            for ending in generic_endings:
                variations.add(
                    clean_text(candidate + ending)
                )

        # Word replacement variations
        for word, replacements in generic_replacements.items():

            if word in base:

                for replacement in replacements:

                    candidate = base.replace(
                        word,
                        replacement,
                        1
                    )

                    for ending in generic_endings:
                        variations.add(
                            clean_text(candidate + ending)
                        )

    else:

        for prefix in prefixes:

            candidate = prefix + text.lower()

            if label == "study_explain":
                endings = explain_endings

            elif label == "study_summary":
                endings = summary_endings

            elif label == "study_notes":
                endings = notes_endings

            elif label == "study_quiz":
                endings = quiz_endings

            elif label == "study_flashcards":
                endings = flashcard_endings

            else:
                endings = [""]

            for ending in endings:
                variations.add(
                    clean_text(candidate + ending)
                )

    return variations


# -----------------------------
# Create expanded dataset
# -----------------------------
classes = sorted(df["label"].unique())

print("\nClasses found:")
print(classes)

expanded = []

for label in classes:

    class_df = df[df["label"] == label]

    class_texts = set(
        class_df["text"].tolist()
    )

    attempts = 0
    max_attempts = TARGET_PER_CLASS * 500

    while (
        len(class_texts) < TARGET_PER_CLASS
        and attempts < max_attempts
    ):

        row = class_df.sample(1).iloc[0]

        variations = generate_variations(
            row["text"],
            label
        )

        for variation in variations:

            variation = clean_text(variation)

            if len(variation) < 5:
                continue

            if variation not in class_texts:
                class_texts.add(variation)

            if len(class_texts) >= TARGET_PER_CLASS:
                break

        attempts += 1

    print(
        f"{label}: {len(class_texts)} examples"
    )

    for text in class_texts:

        expanded.append({
            "text": text,
            "label": label
        })


# -----------------------------
# Save
# -----------------------------
expanded_df = pd.DataFrame(expanded)

expanded_df = expanded_df.sample(
    frac=1,
    random_state=42
).reset_index(drop=True)

expanded_df.to_csv(
    OUTPUT_FILE,
    index=False
)

print("\n==============================")
print("EXPANDED DATASET CREATED")
print("==============================")

print(expanded_df["label"].value_counts())

print(
    "\nTotal examples:",
    len(expanded_df)
)

print(
    "Saved to:",
    OUTPUT_FILE
)