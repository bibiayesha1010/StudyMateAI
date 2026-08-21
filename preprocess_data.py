import pandas as pd
import re

INPUT_FILE = "data/queries_expanded.csv"
OUTPUT_FILE = "data/queries_cleaned.csv"

# -----------------------------
# Load dataset
# -----------------------------
df = pd.read_csv(INPUT_FILE)

print("Original dataset shape:", df.shape)

# -----------------------------
# Check required columns
# -----------------------------
if "text" not in df.columns or "label" not in df.columns:
    raise ValueError("CSV must contain 'text' and 'label' columns")

# -----------------------------
# Remove missing values
# -----------------------------
print("\nMissing values before cleaning:")
print(df.isnull().sum())

df = df.dropna(subset=["text", "label"])

# -----------------------------
# Convert to string
# -----------------------------
df["text"] = df["text"].astype(str)
df["label"] = df["label"].astype(str)

# -----------------------------
# Clean text
# -----------------------------
def clean_text(text):
    text = text.lower()
    text = re.sub(r"\s+", " ", text)
    text = text.strip()
    return text

df["text"] = df["text"].apply(clean_text)
df["label"] = df["label"].str.strip().str.lower()

# -----------------------------
# Remove empty text
# -----------------------------
df = df[df["text"].str.len() > 0]

# -----------------------------
# Remove duplicate texts
# -----------------------------
before_duplicates = len(df)

df = df.drop_duplicates(
    subset=["text"],
    keep="first"
)

duplicates_removed = before_duplicates - len(df)

# -----------------------------
# Shuffle dataset
# -----------------------------
df = df.sample(
    frac=1,
    random_state=42
).reset_index(drop=True)

# -----------------------------
# Display results
# -----------------------------
print("\nCleaning complete!")

print("Duplicates removed:", duplicates_removed)
print("Final dataset shape:", df.shape)

print("\nFinal class distribution:")
print(df["label"].value_counts())

# -----------------------------
# Save cleaned dataset
# -----------------------------
df.to_csv(
    OUTPUT_FILE,
    index=False
)

print("\nSaved cleaned dataset to:")
print(OUTPUT_FILE)