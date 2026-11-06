# import os
# from dotenv import load_dotenv
# import requests
# import io

# load_dotenv()

# api_key = os.getenv("text_to_speach")

# def tts(text,language,speed=1.0):
#     response = requests.post(
#         "https://api.vachana.ai/api/v1/tts/inference",
#         headers={
#             "Content-Type": "application/json",
#             "X-API-Key-ID": api_key,
#         },
#         json={
#             "text": text,
#             "voice": "Nalini",
#             "model": "timbre-v2.5",
#             "language": language,
#             "speed": speed,
#             "audio_config": {
#                 "sample_rate": 48000,
#                 "num_channels": 1,
#                 "sample_width": 2,
#                 "encoding": "linear_pcm",
#                 "container": "wav",
#             },
#         },
#     )
#     buffer = io.BytesIO(response.content)
#     buffer.seek(0)
#     return buffer

import os
from dotenv import load_dotenv
import requests
from pathlib import Path
# load_dotenv()
ENV_PATH = Path(__file__).resolve().parents[3] / "Backend" / ".env"
load_dotenv(ENV_PATH)
API_KEY = os.getenv("text_to_speach")


def tts(text, language, speed=1.0):

    if not API_KEY:
        raise ValueError("TTS API key not found")

    response = requests.post(
        "https://api.vachana.ai/api/v1/tts/inference",
        headers={
            "Content-Type": "application/json",
            "X-API-Key-ID": API_KEY,
        },
        json={
            "text": text,
            "voice": "Nalini",
            "model": "timbre-v2.5",
            "language": language,
            "speed": speed,
            "audio_config": {
                "sample_rate": 48000,
                "num_channels": 1,
                "sample_width": 2,
                "encoding": "linear_pcm",
                "container": "wav",
            },
        },
        timeout=60,
    )

    response.raise_for_status()

    return response.content
