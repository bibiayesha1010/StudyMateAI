import joblib

# Load trained model
model = joblib.load("model/classifier.joblib")
vectorizer = joblib.load("model/vectorizer.joblib")

print("StudyMate Classifier Test")
print("-------------------------")

while True:
    text = input("\nEnter a query (or type 'exit'): ")

    if text.lower() == "exit":
        break

    # Convert query to TF-IDF
    features = vectorizer.transform([text])

    # Predict
    prediction = model.predict(features)[0]

    # Confidence
    probabilities = model.predict_proba(features)[0]
    confidence = max(probabilities) * 100

    print("Predicted label:", prediction)
    print(f"Confidence: {confidence:.2f}%")