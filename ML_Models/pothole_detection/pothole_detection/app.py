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

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Pothole Detection API")

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

def get_local_ip():
    """Get the local IP address of this machine"""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
    except:
        return "127.0.0.1"

def load_model():
    global model, model_loaded
    try:
        if os.path.exists("best.pt"):
            model = YOLO("best.pt")
            model_loaded = True
            logger.info("✅ YOLO Model loaded successfully")
            return True
        else:
            logger.error("❌ Model file 'best.pt' not found")
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
        "message": "Pothole Detection API Running", 
        "model": "loaded" if model_loaded else "failed",
        "server_ip": local_ip,
        "server_url": f"http://{local_ip}:8000",
        "timestamp": int(time.time())
    }

@app.get("/health")
def health():
    local_ip = get_local_ip()
    return {
        "status": "healthy", 
        "model": "ready" if model_loaded else "failed",
        "server_ip": local_ip,
        "api_type": "pothole_detection",
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
        logger.info(f"📥 Processing: {file.filename}")
        logger.info(f"📍 GPS Received: lat={latitude}, lon={longitude}")
        
        # Check model
        if not model_loaded:
            logger.error("❌ YOLO model not loaded")
            return JSONResponse({
                "isPothole": False,
                "confidence": 0.0,
                "detectionClass": "model_error",
                "error": "YOLO model not loaded",
                "hasGPS": False
            })
        
        # Read and validate image
        image_data = await file.read()
        if not image_data or len(image_data) == 0:
            logger.error("❌ Empty or invalid image")
            return JSONResponse({
                "isPothole": False,
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
                "isPothole": False,
                "confidence": 0.0,
                "detectionClass": "image_processing_error", 
                "error": f"Failed to process image: {e}",
                "hasGPS": False
            })
        
        # Run YOLO detection with VERY LOW threshold for better detection
        try:
            logger.info("🔍 Running YOLO detection...")
            
            results = model.predict(
                image_array, 
                conf=0.01,      # VERY LOW confidence threshold
                iou=0.3,        # Lower IoU for more detections
                verbose=False,
                save=False,
                show=False
            )
            
            # Enhanced detection logic - MORE SENSITIVE
            has_pothole = False
            max_confidence = 0.0
            detection_class = "road_surface"
            total_detections = 0
            
            if results and len(results) > 0:
                result = results[0]
                if hasattr(result, 'boxes') and result.boxes is not None and len(result.boxes) > 0:
                    # Get all detections
                    confidences = result.boxes.conf.cpu().numpy()
                    total_detections = len(confidences)
                    
                    if len(confidences) > 0:
                        max_confidence = float(confidences[0])  # Highest confidence
                        
                        # REMOVED HIGH THRESHOLD - Any detection above 1% = pothole!
                        if max_confidence > 0.01:  # Super low threshold (1%)
                            has_pothole = True
                            detection_class = "pothole_detected"
                            logger.info(f"🎯 POTHOLE DETECTED! Confidence: {max_confidence:.3f}")
                        else:
                            logger.info(f"ℹ️ Very low confidence: {max_confidence:.3f}")
                    
                    logger.info(f"📊 Total detections found: {total_detections}")
            
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
            
            # Build enhanced response with GPS
            processing_time = time.time() - start_time
            
            response = {
                "isPothole": has_pothole,
                "confidence": round(max_confidence, 3),
                "detectionClass": detection_class,
                "success": True,
                "message": "Pothole detection completed",
                "processingTime": round(processing_time, 2),
                "totalDetections": total_detections,
                "server_ip": get_local_ip(),
                **gps_data  # Merge GPS data into response
            }
            
            logger.info(f"🚀 Detection completed in {processing_time:.2f}s:")
            logger.info(f"   Result: {'POTHOLE FOUND' if has_pothole else 'NO POTHOLE'}")
            logger.info(f"   Confidence: {max_confidence:.3f}")
            logger.info(f"   GPS: {'Available' if gps_data['hasGPS'] else 'Not available'}")
            
            return JSONResponse(response)
            
        except Exception as e:
            logger.error(f"❌ YOLO detection failed: {e}")
            return JSONResponse({
                "isPothole": False,
                "confidence": 0.0,
                "detectionClass": "detection_error",
                "error": f"YOLO detection failed: {e}",
                "success": False,
                "hasGPS": False
            })
            
    except Exception as e:
        logger.error(f"💥 Unexpected server error: {e}")
        return JSONResponse({
            "isPothole": False,
            "confidence": 0.0,
            "detectionClass": "server_error",
            "error": f"Server error: {e}",
            "success": False,
            "hasGPS": False
        })

if __name__ == "__main__":
    import uvicorn
    local_ip = get_local_ip()
    logger.info(f"🚀 Starting Enhanced Pothole Detection Server...")
    logger.info(f"🌐 Server URLs:")
    logger.info(f"   Local: http://127.0.0.1:8000")
    logger.info(f"   Network: http://{local_ip}:8000")
    logger.info(f"🎯 Features: YOLO Detection + GPS Tracking + Auto-Discovery")
    uvicorn.run(app, host="0.0.0.0", port=8000)
