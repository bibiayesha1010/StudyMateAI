import os
import pandas as pd
import joblib

from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix
)

# ==========================================
# 1. Load cleaned dataset
# ==========================================

DATA_FILE = "data/queries_cleaned.csv"

df = pd.read_csv(DATA_FILE)

print("Loaded", len(df), "rows from", DATA_FILE)

# ==========================================
# 2. Check dataset
# ==========================================

print("\n=== Dataset Distribution ===")
print(df["label"].value_counts())

# Remove any remaining invalid rows
df = df.dropna(subset=["text", "label"])

X = df["text"]
y = df["label"]

# ==========================================
# 3. Train/Test Split
# ==========================================

X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.20,
    random_state=42,
    stratify=y
)

print("\nTraining samples:", len(X_train))
print("Testing samples:", len(X_test))

# ==========================================
# 4. TF-IDF Feature Extraction
# ==========================================

vectorizer = TfidfVectorizer(
    lowercase=True,
    ngram_range=(1, 2),
    max_features=10000,
    sublinear_tf=True
)

X_train_tfidf = vectorizer.fit_transform(X_train)
X_test_tfidf = vectorizer.transform(X_test)

print("\nTF-IDF training shape:", X_train_tfidf.shape)
print("TF-IDF testing shape:", X_test_tfidf.shape)

# ==========================================
# 5. Train Logistic Regression
# ==========================================

classifier = LogisticRegression(
    max_iter=1000,
    random_state=42
)

classifier.fit(
    X_train_tfidf,
    y_train
)

print("\nModel training complete.")

# ==========================================
# 6. Predictions
# ==========================================

y_pred = classifier.predict(X_test_tfidf)

# ==========================================
# 7. Evaluation
# ==========================================

accuracy = accuracy_score(y_test, y_pred)

print("\n=== Evaluation ===")

print(
    f"Accuracy: {accuracy:.4f} "
    f"({accuracy * 100:.2f}%)"
)

print("\n=== Classification Report ===")

print(
    classification_report(
        y_test,
        y_pred,
        digits=4
    )
)

print("\n=== Confusion Matrix ===")

labels = classifier.classes_

cm = confusion_matrix(
    y_test,
    y_pred,
    labels=labels
)

print("\nLabels:")
print(labels)

print("\nMatrix:")
print(cm)

# ==========================================
# 8. Save model
# ==========================================

os.makedirs("model", exist_ok=True)

joblib.dump(
    classifier,
    "model/classifier.joblib"
)

joblib.dump(
    vectorizer,
    "model/vectorizer.joblib"
)

print("\n=== Model Saved ===")

print("model/classifier.joblib")
print("model/vectorizer.joblib")