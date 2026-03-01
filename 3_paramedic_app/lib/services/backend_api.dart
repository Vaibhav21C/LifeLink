import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendApi {
  // If running on an Android Emulator, 10.0.2.2 points to your computer's localhost:8000
  // If testing on a physical phone, change this to your laptop's local IP address (e.g., http://192.168.1.5:8000)
  static const String serverUrl = "http://127.0.0.1:8000";
  /// Locks the dispatch in the FastAPI server
  static Future<Map<String, dynamic>> acceptDispatch(String incidentId, String ambulanceId) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/api/accept-dispatch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "incident_id": incidentId,
          "ambulance_id": ambulanceId
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"status": "error", "message": "Failed to connect to server."};
    }
  }
  
  /// Sends live GPS to the server
  static Future<void> sendLocation(String incidentId, double lat, double lon) async {
    try {
      await http.post(
        Uri.parse('$serverUrl/api/update-location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"incident_id": incidentId, "lat": lat, "lon": lon}),
      );
    } catch (e) {}
  }
  /// Listens for new crashes from the Edge AI
  static Future<Map<String, dynamic>> checkPendingDispatch() async {
    try {
      final response = await http.get(Uri.parse('$serverUrl/api/check-dispatch'));
      return jsonDecode(response.body);
    } catch (e) {
      return {"status": "waiting"}; // Fail silently during polling if server is rebooting
    }
  }
  /// Triggers the AWS GenAI Triage summary via the backend
  static Future<Map<String, dynamic>> scanPatientId(String patientId) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/api/paramedic-scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"patient_id": patientId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"status": "error", "message": "Failed to connect to server."};
    }
  }
}