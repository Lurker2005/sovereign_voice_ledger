import requests
from dotenv import load_dotenv
import os
import io
from pathlib import Path

ENV_PATH = Path(__file__).resolve().parents[3] / "Backend" / ".env"
load_dotenv(ENV_PATH)
# load_dotenv()

API_KEY = os.getenv("speach_to_text")

def transcribe_audio(audio,language_code):
    audio_file = io.BytesIO(audio)

    r = requests.post(
        "https://api.vachana.ai/stt/v3",
        headers={"X-API-Key-ID": API_KEY},
        files={"audio_file": ("clip.wav", audio_file, "audio/wav")},
        data={"language_code": language_code},
        timeout=60,
    )

    # body = r.json()
    print("HTTP Status:", r.status_code)
    print("Content-Type:", r.headers.get("Content-Type"))
    print("Response:", repr(r.text[:1000]))

    body = r.json()
    if body.get("success"):
        return body["transcript"]
    else:
        return body["error"]["type"], body["error"]["message"]