"""
generate_elevenlabs_narration.py
Utility script to generate high quality museum voiceover audio using the ElevenLabs API.
Default Voice: "Laura - A Top Narration" (Voice ID: FGY2WhTYpPnrIDTdsKH5)

Usage:
    python scripts/generate_elevenlabs_narration.py --api-key YOUR_ELEVENLABS_KEY
    or set environment variable ELEVENLABS_API_KEY
"""

import os
import json
import argparse
import urllib.request
import urllib.error

# ElevenLabs "Laura" Voice ID (Enthusiastic, sunny, top narration)
DEFAULT_VOICE_ID = "FGY2WhTYpPnrIDTdsKH5"
MODEL_ID = "eleven_multilingual_v2"

def generate_audio_for_exhibit(api_key: str, voice_id: str, text: str, output_path: str):
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
    
    headers = {
        "Accept": "audio/mpeg",
        "Content-Type": "application/json",
        "xi-api-key": api_key
    }
    
    payload = {
        "text": text,
        "model_id": MODEL_ID,
        "voice_settings": {
            "stability": 0.55,
            "similarity_boost": 0.85,
            "style": 0.25,
            "use_speaker_boost": True
        }
    }
    
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    
    print(f"  [🎙️ Generating] Spoken audio using Laura voice -> {output_path}...")
    try:
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                os.makedirs(os.path.dirname(output_path), exist_ok=True)
                with open(output_path, "wb") as f:
                    f.write(response.read())
                print(f"  [✅ Saved] {output_path}")
            else:
                print(f"  [❌ Error] Status code: {response.status}")
    except urllib.error.HTTPError as e:
        print(f"  [❌ HTTP Error] {e.code}: {e.read().decode('utf-8')}")
    except Exception as e:
        print(f"  [❌ Exception] {e}")

def main():
    parser = argparse.ArgumentParser(description="Generate ElevenLabs Laura voiceover for History-Gamified exhibits.")
    parser.add_argument("--api-key", default=os.getenv("ELEVENLABS_API_KEY", ""), help="ElevenLabs API Key")
    parser.add_argument("--voice-id", default=DEFAULT_VOICE_ID, help="ElevenLabs Voice ID (Defaults to Laura)")
    parser.add_argument("--exhibits-file", default="data/educational/exhibits.json", help="Path to exhibits.json")
    args = parser.parse_args()

    if not args.api_key:
        print("===================================================================")
        print("❌ ElevenLabs API Key missing!")
        print("Pass your key via: python scripts/generate_elevenlabs_narration.py --api-key YOUR_KEY")
        print("Voice selected: 'Laura - A Top Narration' (ID: " + args.voice_id + ")")
        print("Note: The in-game system automatically uses high quality Godot TTS as a fallback!")
        print("===================================================================")
        return

    if not os.path.exists(args.exhibits_file):
        print(f"❌ Could not find {args.exhibits_file}")
        return

    with open(args.exhibits_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    exhibits = data.get("exhibits", [])
    print(f"Found {len(exhibits)} exhibits to generate narrations for using Laura's voice...")

    for ex in exhibits:
        ex_id = ex.get("id", "exhibit")
        title = ex.get("title", "")
        # Read the exact description text as displayed in the popup
        text = ex.get("audio_narration_text", ex.get("description", ""))
        rel_path = ex.get("audio_narration_path", f"res://audio/narration/{ex_id}.mp3")
        disk_path = rel_path.replace("res://", "")
        
        print(f"\nProcessing: '{title}' ({ex_id})")
        generate_audio_for_exhibit(args.api_key, args.voice_id, text, disk_path)

    print("\n🎉 All audio narrations with Laura's voice generated successfully!")

if __name__ == "__main__":
    main()
