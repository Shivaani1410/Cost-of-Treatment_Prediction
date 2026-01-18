import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF4F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
      home: const PredictionPage(),
    );
  }
}

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  // Dropdown data (representative & realistic)
  final List<String> procedures = [
    "039 - EXTRACRANIAL PROCEDURES W/O CC/MCC",
    "470 - MAJOR JOINT REPLACEMENT",
    "291 - HEART FAILURE",
    "690 - KIDNEY & URINARY TRACT INFECTIONS",
    "194 - SIMPLE PNEUMONIA"
  ];

  final List<String> states = ["AL", "CA", "TX", "FL", "NY"];

  final List<String> regions = [
    "AL - Dothan",
    "AL - Birmingham",
    "CA - Los Angeles",
    "TX - Houston",
    "NY - New York"
  ];

  String selectedProcedure = "039 - EXTRACRANIAL PROCEDURES W/O CC/MCC";
  String selectedState = "AL";
  String selectedRegion = "AL - Dothan";

  final dischargeController = TextEditingController();
  final coveredController = TextEditingController();
  final medicareController = TextEditingController();

  double? predictedCost;
  String comparisonText = "";
  bool isLoading = false;

  Future<void> predictCost() async {
    if (dischargeController.text.isEmpty ||
        coveredController.text.isEmpty ||
        medicareController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      predictedCost = null;
    });

    final url = Uri.parse(
       "https://branson-unpiteous-prognostically.ngrok-free.dev/predict" // 🔴 replace this
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "drg_definition": selectedProcedure,
        "provider_state": selectedState,
        "hospital_region": selectedRegion,
        "total_discharges": int.parse(dischargeController.text),
        "avg_covered_charges": double.parse(coveredController.text),
        "avg_medicare_payments": double.parse(medicareController.text),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      double prediction = data["predicted_cost"];

      setState(() {
        predictedCost = prediction;
        isLoading = false;

        if (prediction < 7000) {
          comparisonText = "Lower than average treatment cost";
        } else if (prediction < 10000) {
          comparisonText = "Close to average treatment cost";
        } else {
          comparisonText = "Higher than average treatment cost";
        }
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Treatment Cost Predictor")),
      body: Center(
        child: Card(
          elevation: 6,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  "Predict Hospital Treatment Cost",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "AI-based estimation. Actual costs may vary.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),

                // Procedure
                DropdownButtonFormField<String>(
                  value: selectedProcedure,
                  decoration: const InputDecoration(
                    labelText: "Procedure Type",
                    prefixIcon: Icon(Icons.medical_services),
                  ),
                  items: procedures
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.split(" - ")[1]),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedProcedure = v!),
                ),

                const SizedBox(height: 12),

                // State
                DropdownButtonFormField<String>(
                  value: selectedState,
                  decoration: const InputDecoration(
                    labelText: "Hospital State",
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  items: states
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedState = v!),
                ),

                const SizedBox(height: 12),

                // Region
                DropdownButtonFormField<String>(
                  value: selectedRegion,
                  decoration: const InputDecoration(
                    labelText: "Hospital Location",
                    prefixIcon: Icon(Icons.local_hospital),
                  ),
                  items: regions
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedRegion = v!),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: dischargeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Number of Patients",
                    prefixIcon: Icon(Icons.people),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: coveredController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Estimated Treatment Cost",
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: medicareController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Insurance Coverage Amount",
                    prefixIcon: Icon(Icons.health_and_safety),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  icon: const Icon(Icons.analytics),
                  label: const Text("Predict Cost"),
                  onPressed: predictCost,
                ),

                const SizedBox(height: 20),

                if (isLoading)
                  const Center(child: CircularProgressIndicator()),

                if (predictedCost != null) ...[
                  Card(
                    color: Colors.teal.shade50,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.trending_up,
                              size: 40, color: Colors.teal),
                          const SizedBox(height: 10),
                          const Text(
                            "AI-Predicted Treatment Cost",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "₹ ${predictedCost!.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(comparisonText),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value:
                                (predictedCost! / 15000).clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade300,
                            color: Colors.teal,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Compared with average hospital treatment cost",
                            style: TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
