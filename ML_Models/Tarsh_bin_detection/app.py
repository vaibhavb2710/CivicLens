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

app = FastAPI(title="Trash Bin Detection API")

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
            logger.info("✅ Trash Detection YOLO Model loaded successfully")
            return True
        else:
            logger.error("❌ Model file 'best.pt' not found")
            return False
    except Exception as e:
        logger.error(f"❌ Trash model load failed: {e}")
        model_loaded = False
        return False

# Load model at startup
load_model()

@app.get("/")
def root():
    local_ip = get_local_ip()
    return {
        "message": "Trash Bin Detection API Running", 
        "model": "loaded" if model_loaded else "failed",
        "server_ip": local_ip,
        "server_url": f"http://{local_ip}:8002",
        "timestamp": int(time.time())
    }

@app.get("/health")
def health():
    local_ip = get_local_ip()
    return {
        "status": "healthy", 
        "model": "ready" if model_loaded else "failed",
        "server_ip": local_ip,
        "api_type": "trash_detection",  # UNIQUE API TYPE
        "version": "1.0.0",
        "model_name": "Trash Bin YOLO",
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
        logger.info(f"🗑️ Processing trash bin detection: {file.filename}")
        logger.info(f"📍 GPS Received: lat={latitude}, lon={longitude}")
        
        # Check model
        if not model_loaded:
            logger.error("❌ Trash Detection YOLO model not loaded")
            return JSONResponse({
                "isTrash": False,
                "confidence": 0.0,
                "detectionClass": "model_error",
                "error": "Trash Detection YOLO model not loaded",
                "hasGPS": False,
                "success": False
            })
        
        # Read and validate image
        image_data = await file.read()
        if not image_data or len(image_data) == 0:
            logger.error("❌ Empty or invalid image")
            return JSONResponse({
                "isTrash": False,
                "confidence": 0.0,
                "detectionClass": "image_error",
                "error": "Empty or invalid image",
                "hasGPS": False,
                "success": False
            })
        
        logger.info(f"📷 Trash detection image size: {len(image_data)} bytes")
        
        # Process image for YOLO
        try:
            pil_image = Image.open(io.BytesIO(image_data))
            if pil_image.mode != 'RGB':
                pil_image = pil_image.convert('RGB')
            image_array = np.array(pil_image)
            logger.info(f"✅ Trash image processed: {image_array.shape}")
        except Exception as e:
            logger.error(f"❌ Trash image processing failed: {e}")
            return JSONResponse({
                "isTrash": False,
                "confidence": 0.0,
                "detectionClass": "image_processing_error", 
                "error": f"Failed to process trash image: {e}",
                "hasGPS": False,
                "success": False
            })
        
        # Run YOLO detection for trash bins
        try:
            logger.info("🔍 Running trash bin YOLO detection...")
            
            results = model.predict(
                image_array, 
                conf=0.01,      # Very low confidence threshold for better detection
                iou=0.3,        # Lower IoU for more detections
                verbose=False,
                save=False,
                show=False
            )
            
            # Enhanced trash bin detection logic
            has_trash = False
            max_confidence = 0.0
            detection_class = "no_trash_bin"
            total_detections = 0
            detection_details = []
            
            if results and len(results) > 0:
                result = results[0]
                if hasattr(result, 'boxes') and result.boxes is not None and len(result.boxes) > 0:
                    # Get all detections
                    confidences = result.boxes.conf.cpu().numpy()
                    total_detections = len(confidences)
                    
                    if len(confidences) > 0:
                        max_confidence = float(confidences[0])  # Highest confidence
                        
                        # Collect all detection details
                        for i, conf in enumerate(confidences):
                            if conf > 0.01:  # 1% threshold
                                detection_details.append({
                                    "detection_id": i + 1,
                                    "confidence": round(float(conf), 3),
                                    "type": "trash_bin"
                                })
                        
                        # Main detection logic
                        if max_confidence > 0.01:  # 1% threshold
                            has_trash = True
                            detection_class = "trash_bin_detected"
                            logger.info(f"🗑️ TRASH BIN DETECTED! Confidence: {max_confidence:.3f}")
                        else:
                            logger.info(f"ℹ️ Very low trash confidence: {max_confidence:.3f}")
                    
                    logger.info(f"📊 Total trash bin detections found: {total_detections}")
            
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
            
            # Build comprehensive response
            processing_time = time.time() - start_time
            
            response = {
                "isTrash": has_trash,  # UNIQUE RESPONSE KEY FOR TRASH
                "confidence": round(max_confidence, 3),
                "detectionClass": detection_class,
                "success": True,
                "message": "Trash bin detection completed successfully",
                "processingTime": round(processing_time, 2),
                "totalDetections": total_detections,
                "detectionDetails": detection_details,
                "modelType": "trash_detection",
                "server_ip": get_local_ip(),
                "server_port": 8002,
                "api_version": "1.0.0",
                **gps_data  # Merge GPS data into response
            }
            
            logger.info(f"🚀 Trash detection completed in {processing_time:.2f}s:")
            logger.info(f"   Result: {'TRASH BIN FOUND' if has_trash else 'NO TRASH BIN'}")
            logger.info(f"   Confidence: {max_confidence:.3f}")
            logger.info(f"   Total detections: {total_detections}")
            logger.info(f"   GPS: {'Available' if gps_data['hasGPS'] else 'Not available'}")
            
            return JSONResponse(response)
            
        except Exception as e:
            logger.error(f"❌ Trash bin YOLO detection failed: {e}")
            return JSONResponse({
                "isTrash": False,
                "confidence": 0.0,
                "detectionClass": "detection_error",
                "error": f"Trash bin YOLO detection failed: {e}",
                "success": False,
                "hasGPS": False,
                "processingTime": round(time.time() - start_time, 2)
            })
            
    except Exception as e:
        logger.error(f"💥 Unexpected trash detection server error: {e}")
        return JSONResponse({
            "isTrash": False,
            "confidence": 0.0,
            "detectionClass": "server_error",
            "error": f"Trash detection server error: {e}",
            "success": False,
            "hasGPS": False,
            "processingTime": round(time.time() - start_time, 2)
        })

@app.get("/test")
def test_endpoint():
    """Test endpoint to verify server is running"""
    local_ip = get_local_ip()
    return {
        "message": "Trash Detection API Test Successful",
        "server_status": "running",
        "model_status": "loaded" if model_loaded else "failed",
        "server_ip": local_ip,
        "port": 8002,
        "api_type": "trash_detection",
        "endpoints": {
            "health_check": "/health",
            "prediction": "/predict/",
            "root": "/",
            "test": "/test"
        },
        "timestamp": int(time.time())
    }

if __name__ == "__main__":
    import uvicorn
    local_ip = get_local_ip()
    logger.info(f"🗑️ Starting Trash Bin Detection Server...")
    logger.info(f"🌐 Server URLs:")
    logger.info(f"   Local: http://127.0.0.1:8002")
    logger.info(f"   Network: http://{local_ip}:8002")
    logger.info(f"🎯 Features:")
    logger.info(f"   ✅ Trash Bin YOLO Detection")
    logger.info(f"   ✅ GPS Tracking & Validation")
    logger.info(f"   ✅ Auto IP Discovery")
    logger.info(f"   ✅ Enhanced Error Handling")
    logger.info(f"   ✅ Detailed Detection Results")
    
    uvicorn.run(app, host="0.0.0.0", port=8002)
