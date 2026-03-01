from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import green_corridor 

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class CrashAlert(BaseModel):
    incident_id: str; gps_location: str; severity: str; patient_id: str
class DispatchAccept(BaseModel):
    incident_id: str; ambulance_id: str
class QRScan(BaseModel):
    patient_id: str
class LocationUpdate(BaseModel):
    incident_id: str; lat: float; lon: float

active_incidents = {}
MEDICHAIN_DB = {"ABHA-123456": {"name": "Rahul Sharma", "blood_group": "O-Negative", "allergies": "Penicillin, Peanuts", "medical_history": "Asthma"}}

@app.post("/api/trigger")
async def receive_crash(alert: CrashAlert):
    active_incidents[alert.incident_id] = {
        "status": "PENDING", "gps_location": alert.gps_location, "assigned_to": None,
        "destination_hospital": None, "patient": None, "ai_summary": "Awaiting Paramedic Scan...",
        "amb_lat": 0.0, "amb_lon": 0.0
    }
    return {"status": "success"}

@app.get("/api/check-dispatch")
async def check_dispatch():
    for inc_id, data in active_incidents.items():
        if data["status"] == "PENDING":
            return {"status": "found", "incident_id": inc_id, "gps_location": data["gps_location"]}
    return {"status": "waiting"}

@app.post("/api/accept-dispatch")
async def accept_dispatch(dispatch: DispatchAccept):
    if dispatch.incident_id in active_incidents:
        active_incidents[dispatch.incident_id]["status"] = "ASSIGNED"
        return {"status": "success"}
    return {"error": "Not found"}

@app.post("/api/update-location")
async def update_location(loc: LocationUpdate):
    if loc.incident_id in active_incidents:
        active_incidents[loc.incident_id]["amb_lat"] = loc.lat
        active_incidents[loc.incident_id]["amb_lon"] = loc.lon
        green_corridor.update_dynamic_lights(loc.lat, loc.lon)
    return {"status": "success"}

@app.post("/api/paramedic-scan")
async def process_triage(scan: QRScan):
    summary_text = ""
    for inc_id, data in active_incidents.items():
        if data["status"] == "ASSIGNED":
            data["patient"] = MEDICHAIN_DB.get("ABHA-123456")
            summary_text = f"⚠️ IMMEDIATE RISKS:\n1. REQUIRES {data['patient']['blood_group']} BLOOD.\n2. ALLERGIES: {data['patient']['allergies']}."
            data["ai_summary"] = summary_text
            
    # THIS is the crucial line that prevents the Flutter app from crashing!
    return {"status": "success", "ai_triage_summary": summary_text}

@app.get("/api/er-updates")
async def get_er_updates():
    for inc_id, data in active_incidents.items():
        if data["status"] == "ASSIGNED":
            return {
                "status": "incoming", 
                "patient": data["patient"], 
                "ai_summary": data["ai_summary"],
                "amb_lat": data["amb_lat"],
                "amb_lon": data["amb_lon"],
                "lights": green_corridor.IOT_TRAFFIC_LIGHTS
            }
    return {"status": "waiting"}

@app.post("/api/clear-er")
async def clear_er():
    active_incidents.clear()
    return {"status": "success"}

@app.get("/dashboard", response_class=HTMLResponse)
async def serve_dashboard():
    with open("templates/er_dashboard.html", "r", encoding="utf-8") as f:
        return f.read()