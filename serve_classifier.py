"""
StudyMate classifier API.

Run:
    python serve_classifier.py

Endpoint:
    POST http://localhost:8000/classify
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import joblib

app = FastAPI(title="StudyMate Classifier")


# ============================================================
# CORS
# Allows Flutter Web / Chrome to communicate with FastAPI
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# LOAD TRAINED ML MODEL
# ============================================================

clf = joblib.load("model/classifier.joblib")
vectorizer = joblib.load("model/vectorizer.joblib")

CONFIDENCE_THRESHOLD = 0.60


class Query(BaseModel):
    text: str


# ============================================================
# CLASSIFY
# ============================================================

@app.post("/classify")
def classify(query: Query):

    # Convert text to TF-IDF
    vec = vectorizer.transform([query.text])

    # Predict label
    label = clf.predict(vec)[0]

    # Calculate confidence
    proba = clf.predict_proba(vec)[0]
    confidence = float(max(proba))

    # Check confidence threshold
    is_confident = confidence >= CONFIDENCE_THRESHOLD

    return {
        "label": label,
        "confidence": confidence,
        "is_confident": is_confident
    }


# ============================================================
# HEALTH CHECK
# ============================================================

@app.get("/health")
def health():
    return {"status": "ok"}