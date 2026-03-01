import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/backend_api.dart';

class ParamedicDashboard extends StatefulWidget {
  const ParamedicDashboard({super.key});

  @override
  State<ParamedicDashboard> createState() => _ParamedicDashboardState();
}

class _ParamedicDashboardState extends State<ParamedicDashboard> {
  bool isPatrolling = true;
  bool isDispatched = false;
  bool isScanning = false;
  String triageSummary = "Awaiting patient scan...";
  Timer? _pollingTimer;
  Timer? _driveTimer;

  // NEW: A realistic, road-following GPS path!
  final List<LatLng> greenCorridorRoute = [
    const LatLng(22.6116, 77.7810), // Start (Crash)
    const LatLng(22.6120, 77.7810), // Driving North...
    const LatLng(22.6125, 77.7810),
    const LatLng(22.6130, 77.7810), // Arrived at Main Junction
    const LatLng(22.6130, 77.7795), // Turning West...
    const LatLng(22.6130, 77.7780), // Passing Traffic Light 1
    const LatLng(22.6130, 77.7765), // Passing Traffic Light 2
    const LatLng(22.6130, 77.7750), // Arrived at Market Square Turn
    const LatLng(22.6140, 77.7750), // Turning North...
    const LatLng(22.6150, 77.7750), // Arrived at Hospital!
  ];

  double currentLat = 22.6116; 
  double currentLon = 77.7810;
  
  final double destLat = 22.6150;
  final double destLon = 77.7750;

  @override
  void initState() {
    super.initState();
    // Poll the server every 3 seconds to see if the Edge AI caught a crash
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (isPatrolling) checkForCrash();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _driveTimer?.cancel();
    super.dispose();
  }

  Future<void> checkForCrash() async {
    final response = await BackendApi.checkPendingDispatch();
    if (response['status'] == 'found') {
      setState(() { isPatrolling = false; });
    }
  }

  Future<void> handleAcceptDispatch() async {
    final response = await BackendApi.acceptDispatch("CRASH-991", "AMB-01");
    if (response['status'] == 'success') {
      setState(() { isDispatched = true; });
      startDrivingSimulator();
    }
  }

  // The flawless driving simulator
  void startDrivingSimulator() {
    int currentStep = 0;

    _driveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentStep < greenCorridorRoute.length) {
        setState(() {
          currentLat = greenCorridorRoute[currentStep].latitude;
          currentLon = greenCorridorRoute[currentStep].longitude;
        });
        
        // Broadcast the new location to the ER Dashboard
        BackendApi.sendLocation("CRASH-991", currentLat, currentLon);
        currentStep++;
      } else {
        timer.cancel(); // Arrived at the ER!
      }
    });
  }

  Future<void> handleScanPatient() async {
    setState(() { isScanning = true; triageSummary = "Querying MediChain..."; });
    final response = await BackendApi.scanPatientId("ABHA-123456");
    setState(() {
      isScanning = false;
      if (response['status'] == 'success') triageSummary = response['ai_triage_summary'];
    });
  }

  void resetApp() {
    _driveTimer?.cancel();
    setState(() { 
      // Reset position back to the start
      currentLat = greenCorridorRoute[0].latitude; 
      currentLon = greenCorridorRoute[0].longitude;
      isPatrolling = true; 
      isDispatched = false; 
      isScanning = false; 
      triageSummary = "Awaiting patient scan..."; 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LifeLink Paramedic Console', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: resetApp)], // Hidden reset button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // STATE 0: PATROLLING
            // ==========================================
            if (isPatrolling) ...[
              const Spacer(),
              const Icon(Icons.local_hospital, size: 100, color: Colors.grey),
              const SizedBox(height: 24),
              const Text("AMB-01 Active.\nPatrolling and listening for dispatches...", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, color: Colors.grey)),
              const Spacer(),
            ]

            // ==========================================
            // STATE 1: WAITING FOR DISPATCH
            // ==========================================
            else if (!isDispatched) ...[
              const Spacer(),
              const Icon(Icons.warning_amber_rounded, size: 120, color: Colors.redAccent),
              const SizedBox(height: 24),
              const Text("🚨 CRASH DETECTED\nINCIDENT: CRASH-991", textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(vertical: 24)),
                onPressed: handleAcceptDispatch,
                child: const Text("ACCEPT DISPATCH", style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
            ] 
            
            // ==========================================
            // STATE 2: EN ROUTE (LIVE NAVIGATION MAP + SCANNER)
            // ==========================================
            else ...[
              // THE LIVE NAVIGATION MAP
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(
                      // Centers the camera over the middle of the route
                      initialCenter: const LatLng(22.6135, 77.7780), 
                      initialZoom: 15.5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.lifelink.app',
                      ),
                      // Draws the Green Corridor Route Line
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: greenCorridorRoute, // Uses our L-shaped array!
                            strokeWidth: 6.0,
                            color: Colors.green.withOpacity(0.7), 
                          ),
                        ],
                      ),
                      // Draws the Hospital and the Moving Ambulance
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(destLat, destLon),
                            width: 40, height: 40,
                            child: const Icon(Icons.local_hospital, color: Colors.red, size: 40),
                          ),
                          Marker(
                            point: LatLng(currentLat, currentLon), // This variable updates every second!
                            width: 40, height: 40,
                            child: const Icon(Icons.emergency, color: Colors.blue, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // THE MEDICHAIN TRIAGE SECTION
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      icon: isScanning 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.qr_code_scanner, color: Colors.white),
                      label: const Text("SCAN ID", style: TextStyle(color: Colors.white, fontSize: 16)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: isScanning ? null : handleScanPatient,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                        child: SingleChildScrollView(
                          child: Text(triageSummary, style: const TextStyle(fontSize: 14, fontFamily: 'monospace', color: Colors.amberAccent)),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
