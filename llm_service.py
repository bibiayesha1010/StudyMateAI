"""
StudyMate Local LLM Service.

Flutter
   ↓
FastAPI (port 8001)
   ↓
Ollama (port 11434)
   ↓
llama3.2
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import requests

app = FastAPI(title="StudyMate Local LLM")

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
# OLLAMA CONFIGURATION
# ============================================================

OLLAMA_URL = "http://localhost:11434/api/generate"
OLLAMA_MODEL = "llama3.2"


class ChatRequest(BaseModel):
    text: str


# ============================================================
# HEALTH CHECK
# ============================================================

@app.get("/health")
def health():
    return {
        "status": "ok",
        "model": OLLAMA_MODEL,
    }


# ============================================================
# CHAT WITH LOCAL LLM
# ============================================================

@app.post("/chat")
def chat(request: ChatRequest):

    system_prompt = """
You are StudyMate, a friendly and encouraging AI study companion.

Your role:
- Explain academic topics clearly and simply.
- Break difficult concepts into small steps.
- Use headings and bullet points when useful.
- Give examples when they help understanding.
- Keep answers focused and easy to revise.
- Do not claim to know something if you are unsure.
"""

    payload = {
        "model": OLLAMA_MODEL,
        "prompt": request.text,
        "system": system_prompt,
        "stream": False,
    }

    try:
        response = requests.post(
            OLLAMA_URL,
            json=payload,
            timeout=120,
        )

        response.raise_for_status()

        data = response.json()

        return {
            "response": data.get("response", "")
        }

    except requests.exceptions.ConnectionError:
        return {
            "response": "StudyMate could not connect to Ollama. Please make sure Ollama is running."
        }

    except requests.exceptions.Timeout:
        return {
            "response": "StudyMate is taking too long to respond. Please try again."
        }

    except Exception as e:
        print("OLLAMA ERROR:", e)

        return {
            "response": "Something went wrong while communicating with the local AI."
        }