# NOVA Cloud Engine

FastAPI + Playwright Chromium remote renderer. Designed to run on the user's Windows 10 PC and be controlled by NOVA on iOS 12.

## Windows setup
```powershell
cd cloud
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
playwright install chromium
Copy-Item .env.example .env
# Edit .env and set NOVA_API_TOKEN to a random secret (24+ chars).
uvicorn nova_cloud.main:app --host 0.0.0.0 --port 8765
```

Health check: `http://127.0.0.1:8765/health`

Create session:
```powershell
$token = "YOUR_LONG_TOKEN"
$headers = @{ Authorization = "Bearer $token" }
$body = @{ url = "https://web.bale.ai/"; viewport_width = 375; viewport_height = 600 } | ConvertTo-Json
$r = Invoke-RestMethod -Method Post -Uri http://127.0.0.1:8765/v1/sessions -Headers $headers -ContentType "application/json" -Body $body
$r
```

Download screenshot:
```powershell
Invoke-WebRequest -Uri "http://127.0.0.1:8765/v1/sessions/$($r.session_id)/screenshot" -Headers $headers -OutFile nova.jpg
```

## API
- `POST /v1/sessions` create a Chromium context
- `GET /v1/sessions/{id}/screenshot` JPEG screenshot
- `POST /v1/sessions/{id}/navigate` navigate
- `POST /v1/sessions/{id}/tap` normalized tap coordinates (0..1)
- `POST /v1/sessions/{id}/scroll` wheel deltas
- `POST /v1/sessions/{id}/type` insert text
- `POST /v1/sessions/{id}/key/{key}` limited key set
- `DELETE /v1/sessions/{id}` close

## Security limitations
This initial version blocks obvious loopback/local destinations, requires a bearer token, limits sessions and expires idle sessions. It is intended for a trusted private LAN. Before internet exposure, add TLS, stronger SSRF/IP-range filtering, rate limiting, audit logs and per-session authorization. Session IDs are secrets and must not be logged or shared.
