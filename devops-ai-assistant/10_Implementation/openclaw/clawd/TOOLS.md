TOOLS.md - Local setup notes

Skills define how, this file defines your environment specifics

Web Search:
- Provider: SerpAPI (Google Search)
- Key: ~/.config/serpapi_key
- Rate: 100/month free tier
- Docs: https://serpapi.com/search-api

TTS Providers:
Edge-TTS (default): free unlimited Microsoft Edge unofficial API
OpenAI TTS: $15/1M chars 6 voices (alloy echo fable onyx nova shimmer)
sherpa-onnx: local offline requires setup

Calen Voice:
- Voice: en-US-GuyNeural (professional US male)
- Config: /home/openclaw/clawd/tts-config.json
- Output: /home/openclaw/clawd/media/ (gitignored)

Other male voices: en-US-ArthurNeural en-GB-RyanNeural en-GB-ThomasNeural de-DE-ChristophNeural fr-FR-HenriNeural es-ES-AlvaroNeural

Commands:
/tts provider edge
/tts text
./scripts/test_edge_voice.sh "voice" "text"
