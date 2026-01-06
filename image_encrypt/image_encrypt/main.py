import os
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import cloudinary
import cloudinary.uploader as uploader
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load .env variables
load_dotenv()

app = FastAPI(title="Civic Lens Cloudinary Uploader")

# Configure CORS
ALLOW_ORIGINS = [o.strip() for o in os.getenv("ALLOWED_ORIGINS", "*").split(",")]
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOW_ORIGINS,
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

# Cloudinary credentials from .env
cloudinary.config(
    cloud_name=os.getenv("CLOUD_NAME"),
    api_key=os.getenv("CLOUD_API_KEY"),
    api_secret=os.getenv("CLOUD_API_SECRET"),
    secure=True,
)

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "ok",
        "service": "Civic Lens Cloudinary Uploader",
        "port": int(os.getenv("PORT", "8003")),
        "cloudinary_configured": bool(os.getenv("CLOUD_NAME"))
    }

@app.post("/upload")
async def upload(file: UploadFile = File(...)):
    """Upload file to Cloudinary"""
    try:
        logger.info(f"📤 Uploading file: {file.filename} ({file.content_type})")
        
        # Validate file
        if not file.filename:
            raise HTTPException(status_code=400, detail="No filename provided")
        
        # Upload to Cloudinary
        result = uploader.upload(
            file.file,
            resource_type="auto",  # CHANGED: auto-detect file type
            folder="civic_lens_uploads",  # CHANGED: better folder name
            public_id=f"civic_lens_{file.filename}",  # CHANGED: better naming
            overwrite=True,
            quality="auto",  # Optimize file size
            fetch_format="auto",  # Optimize format
        )
        
        logger.info(f"✅ Upload successful: {result.get('secure_url')}")
        
        return {
            "success": True,
            "public_id": result.get("public_id"),
            "secure_url": result.get("secure_url"),
            "resource_type": result.get("resource_type"),
            "bytes": result.get("bytes"),
            "version": result.get("version"),
            "format": result.get("format"),
            "width": result.get("width"),
            "height": result.get("height"),
        }
    except Exception as e:
        logger.error(f"❌ Upload failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")

@app.get("/test")
async def test():
    """Test endpoint"""
    return {
        "status": "ok",
        "message": "Cloudinary uploader is working",
        "cloudinary_config": {
            "cloud_name": os.getenv("CLOUD_NAME"),
            "api_key_set": bool(os.getenv("CLOUD_API_KEY")),
            "api_secret_set": bool(os.getenv("CLOUD_API_SECRET")),
        }
    }

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8003"))  # Port 8003 for Cloudinary
    logger.info(f"🚀 Starting Cloudinary uploader on port {port}")
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
