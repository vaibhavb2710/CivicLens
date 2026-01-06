# Image Encrypt Uploader (FastAPI)

This is a FastAPI replacement for your existing Express server. It exposes a single `/upload` endpoint that accepts a file field named `file` and uploads it to Cloudinary under the `encrypted_uploads` folder as a `raw` resource (so encrypted/binary files are preserved).

## Endpoints
- `GET /` -> health check `{ status: "ok" }`
- `POST /upload` -> form-data with `file`: returns Cloudinary upload JSON

## Setup
1. Create and activate a Python environment (Windows PowerShell):

```powershell
# from the project root
python -m venv .venv
. .venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

2. Configure environment variables:

```powershell
Copy-Item .env.example .env
# then edit .env and set CLOUD_NAME, CLOUD_API_KEY, CLOUD_API_SECRET
```

## Run locally

```powershell
# default port 3000 to match the Node server
python main.py
# or
uvicorn main:app --host 0.0.0.0 --port 3000 --reload
```

## CORS
CORS is enabled for all origins by default. To restrict it, edit `allow_origins` in `main.py`.

## Notes
- The FastAPI app mirrors the behavior of the original Express app in `index.js`.
- For production, consider running with `uvicorn` behind a process manager and set explicit allowed origins.
