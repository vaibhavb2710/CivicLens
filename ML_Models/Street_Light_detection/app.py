from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO
from PIL import Image
import io
import logging
import numpy as np
import time
import os
import socket
import torch

logging.basicConfig(level=logging.INFO)                                                                                                                                                             
logger = logging.getLogger(__name__)

app = FastAPI(title="Streetlight Detection API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global variables
model = None
model_loaded = False
device = None

def get_local_ip():
    """Get the local IP address of this machine"""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
    except:
        return "127.0.0.1"

def get_device():
    """Determine available device (CUDA or CPU)"""
    global device
    try:
        if torch.cuda.is_available():
            device = "cuda"
            logger.info("✅ CUDA available - using GPU")
        else:
            device = "cpu"
            logger.info("ℹ️ CUDA not available - using CPU")
    except:
        device = "cpu"
        logger.info("ℹ️ Using CPU (fallback)")
    return device

def load_model():
    global model, model_loaded
    try:
        if not os.path.exists("best.pt"):
            logger.error("❌ Model file 'best.pt' not found")
            return False
        
        get_device()
        model = YOLO("best.pt")
        model.to(device)
        model_loaded = True
        logger.info("✅ Streetlight YOLO Model loaded successfully")
        return True
    except ImportError as e:
        logger.error(f"❌ Missing dependency: {e}. Install with: pip install ultralytics torch")
        model_loaded = False
        return False
    except Exception as e:
        logger.error(f"❌ Model load failed: {e}")
        model_loaded = False
        return False

# Load model at startup
load_model()

@app.get("/")
def root():
    local_ip = get_local_ip()
    return {
        "message": "Streetlight Detection API Running", 
        "model": "loaded" if model_loaded else "failed",
        "server_ip": local_ip,
        "server_url": f"http://{local_ip}:8001",
        "timestamp": int(time.time())
    }

@app.get("/health")
def health():
    local_ip = get_local_ip()
    return {
        "status": "healthy", 
        "model": "ready" if model_loaded else "failed",
        "server_ip": local_ip,
        "api_type": "streetlight_detection",  # UNIQUE API TYPE
        "version": "1.0.0",
        "timestamp": int(time.time())
    }

@app.post("/predict/")
async def predict(
    file: UploadFile = File(...),
    latitude: str = Form("0.0"),
    longitude: str = Form("0.0")
):
    start_time = time.time()
    
    try:
        logger.info(f"🚦 Processing streetlight detection: {file.filename}")
        logger.info(f"📍 GPS Received: lat={latitude}, lon={longitude}")
        
        # Check model
        if not model_loaded:
            logger.error("❌ Streetlight YOLO model not loaded")
            return JSONResponse({
                "isStreetlight": False,
                "confidence": 0.0,
                "detectionClass": "model_error",
                "error": "Streetlight YOLO model not loaded",
                "hasGPS": False
            })
        
        # Read and validate image
        image_data = await file.read()
        if not image_data or len(image_data) == 0:
            logger.error("❌ Empty or invalid image")
            return JSONResponse({
                "isStreetlight": False,
                "confidence": 0.0,
                "detectionClass": "image_error",
                "error": "Empty or invalid image",
                "hasGPS": False
            })
        
        logger.info(f"📷 Image size: {len(image_data)} bytes")
        
        # Process image for YOLO
        try:
            pil_image = Image.open(io.BytesIO(image_data))
            if pil_image.mode != 'RGB':
                pil_image = pil_image.convert('RGB')
            image_array = np.array(pil_image)
            logger.info(f"✅ Image processed: {image_array.shape}")
        except Exception as e:
            logger.error(f"❌ Image processing failed: {e}")
            return JSONResponse({
                "isStreetlight": False,
                "confidence": 0.0,
                "detectionClass": "image_processing_error", 
                "error": f"Failed to process image: {e}",
                "hasGPS": False
            })
        
        # Run YOLO detection for streetlights
        try:
            logger.info("🔍 Running streetlight YOLO detection...")
            
            results = model.predict(
                image_array, 
                conf=0.01,
                iou=0.3,
                verbose=False,
                save=False,
                show=False,
                device=device
            )
            
            # Enhanced streetlight detection logic
            has_streetlight = False
            max_confidence = 0.0
            detection_class = "no_streetlight"
            total_detections = 0
            
            if results and len(results) > 0:
                result = results[0]
                if hasattr(result, 'boxes') and result.boxes is not None and len(result.boxes) > 0:
                    try:
                        confidences = result.boxes.conf.cpu().numpy()
                        total_detections = len(confidences)
                        
                        if len(confidences) > 0:
                            max_confidence = float(np.max(confidences))
                            
                            if max_confidence > 0.01:
                                has_streetlight = True
                                detection_class = "streetlight_detected"
                                logger.info(f"🚦 STREETLIGHT DETECTED! Confidence: {max_confidence:.3f}")
                            else:
                                logger.info(f"ℹ️ Very low confidence: {max_confidence:.3f}")
                        
                        logger.info(f"📊 Total streetlight detections found: {total_detections}")
                    except Exception as e:
                        logger.error(f"❌ Error processing detection results: {e}")
            else:
                logger.info("ℹ️ No detections found")
            
            # Process GPS coordinates
            gps_data = {
                "hasGPS": False,
                "latitude": 0.0,
                "longitude": 0.0
            }
            
            try:
                if latitude and latitude != "0.0" and longitude and longitude != "0.0":
                    gps_lat = float(latitude)
                    gps_lon = float(longitude)
                    
                    # Validate GPS coordinates
                    if -90 <= gps_lat <= 90 and -180 <= gps_lon <= 180:
                        gps_data = {
                            "hasGPS": True,
                            "latitude": round(gps_lat, 6),
                            "longitude": round(gps_lon, 6)
                        }
                        logger.info(f"✅ Valid GPS: {gps_lat:.6f}, {gps_lon:.6f}")
                    else:
                        logger.warning(f"⚠️ Invalid GPS coordinates: {gps_lat}, {gps_lon}")
                else:
                    logger.info("ℹ️ No GPS coordinates provided")
            except ValueError as e:
                logger.warning(f"⚠️ GPS parsing error: {e}")
            
            # Build response
            processing_time = time.time() - start_time
            
            response = {
                "isStreetlight": has_streetlight,  # UNIQUE RESPONSE KEY
                "confidence": round(max_confidence, 3),
                "detectionClass": detection_class,
                "success": True,
                "message": "Streetlight detection completed",
                "processingTime": round(processing_time, 2),
                "totalDetections": total_detections,
                "server_ip": get_local_ip(),
                **gps_data
            }
            
            logger.info(f"🚀 Streetlight detection completed in {processing_time:.2f}s:")
            logger.info(f"   Result: {'STREETLIGHT FOUND' if has_streetlight else 'NO STREETLIGHT'}")
            logger.info(f"   Confidence: {max_confidence:.3f}")
            logger.info(f"   GPS: {'Available' if gps_data['hasGPS'] else 'Not available'}")
            
            return JSONResponse(response)
            
        except Exception as e:
            logger.error(f"❌ Streetlight YOLO detection failed: {e}")
            return JSONResponse({
                "isStreetlight": False,
                "confidence": 0.0,
                "detectionClass": "detection_error",
                "error": f"Streetlight YOLO detection failed: {e}",
                "success": False,
                "hasGPS": False
            })
            
    except Exception as e:
        logger.error(f"💥 Unexpected streetlight server error: {e}")
        return JSONResponse({
            "isStreetlight": False,
            "confidence": 0.0,
            "detectionClass": "server_error",
            "error": f"Streetlight server error: {e}",
            "success": False,
            "hasGPS": False
        })

if __name__ == "__main__":
    import uvicorn
    local_ip = get_local_ip()
    logger.info(f"🚦 Starting Streetlight Detection Server...")
    logger.info(f"🌐 Server URLs:")
    logger.info(f"   Local: http://127.0.0.1:8001")
    logger.info(f"   Network: http://{local_ip}:8001")
    logger.info(f"🎯 Features: Streetlight YOLO Detection + GPS + Auto-Discovery")
    uvicorn.run(app, host="0.0.0.0", port=8001)
