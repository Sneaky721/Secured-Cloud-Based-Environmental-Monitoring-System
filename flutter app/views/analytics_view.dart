import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../services/shared_preferences_service.dart';

class AnalyticsView extends StatefulWidget {
  final List<double> temperatureData;
  final List<double> humidityData;
  final List<double> oxygenData;
  final List<double> lightData;

  const AnalyticsView({
    super.key,
    required this.temperatureData,
    required this.humidityData,
    required this.oxygenData,
    required this.lightData,
  });

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  String selectedMetric = 'Average';

  double computeMetric(List<double> values, String metric) {
    if (values.isEmpty) return 0;
    switch (metric) {
      case 'Average':
        return values.average;
      case 'Median':
        final sorted = [...values]..sort();
        final mid = sorted.length ~/ 2;
        return sorted.length % 2 == 0
            ? (sorted[mid - 1] + sorted[mid]) / 2
            : sorted[mid];
      case 'Min':
        return values.reduce((a, b) => a < b ? a : b);
      case 'Max':
        return values.reduce((a, b) => a > b ? a : b);
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Analytics"),
        backgroundColor: color.surface,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: selectedMetric,
              items: ['Average', 'Median', 'Min', 'Max']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => selectedMetric = val!),
              decoration: InputDecoration(
                labelText: "Select Metric",
                labelStyle: const TextStyle(color: Colors.white),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: color.secondary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: color.secondary, width: 2),
                ),
                prefixIcon: const Icon(Icons.analytics, color: Colors.white),
              ),
              dropdownColor: color.surface,
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: Colors.white,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SummaryCard(
                  title: "Temperature",
                  source: "Parking Spot (thingy)",
                  value: computeMetric(widget.temperatureData, selectedMetric),
                  icon: Icons.thermostat,
                  color: Colors.orange,
                  unit: "°C",
                ),
                SummaryCard(
                  title: "Humidity",
                  source: "Parking Spot (thingy)",
                  value: computeMetric(widget.humidityData, selectedMetric),
                  icon: Icons.water_drop,
                  color: Colors.blue,
                  unit: "%",
                ),
                SummaryCard(
                  title: "Oxygen",
                  source: "Park Backyard (server2)",
                  value: computeMetric(widget.oxygenData, selectedMetric),
                  icon: Icons.air,
                  color: Colors.teal,
                  unit: "%",
                ),
                SummaryCard(
                  title: "Light",
                  source: "Park Entrance (server1)",
                  value: computeMetric(widget.lightData, selectedMetric),
                  icon: Icons.lightbulb,
                  color: Colors.yellow.shade700,
                  unit: "%",
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _exportCSV(),
        icon: const Icon(Icons.download),
        label: const Text("Export CSV"),
      ),
    );
  }

  Future<void> _exportCSV() async {
    final now = DateTime.now();
    final date = "${now.year}-${now.month}-${now.day}";
    final time = "${now.hour}-${now.minute}-${now.second}";
    final fileName = "analytics_$date\_$time.csv";

    final rows = [
      ["Sensor Dashboard Analytics Export"],
      ["Date:", date, "Time:", time],
      [],
      ["Metric:", selectedMetric],
      [],
      ["Metric", "Source", "Value"],
      [
        "Temperature",
        "Parking Spot (thingy)",
        computeMetric(widget.temperatureData, selectedMetric).toStringAsFixed(2),
      ],
      [
        "Humidity",
        "Parking Spot (thingy)",
        computeMetric(widget.humidityData, selectedMetric).toStringAsFixed(2),
      ],
      [
        "Oxygen",
        "Park Backyard (server2)",
        computeMetric(widget.oxygenData, selectedMetric).toStringAsFixed(2),
      ],
      [
        "Light",
        "Park Entrance (server1)",
        computeMetric(widget.lightData, selectedMetric).toStringAsFixed(2),
      ],
    ];

    final csvData = const ListToCsvConverter().convert(rows);

    final status = await Permission.storage.request();
    if (status.isGranted) {
      final dir = await getExternalStorageDirectory();
      final path = '${dir!.path}/$fileName';
      final file = File(path);
      await file.writeAsString(csvData);

      await SharedPreferencesService.saveExportedFile(
        ExportedFileModel(
          fileName: fileName,
          dateTime: SharedPreferencesService.getFormattedNow(),
          sensors: ["Temperature", "Humidity", "Oxygen", "Light"],
          content: csvData,
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ File saved to:\n$path")),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Storage permission denied")),
        );
      }
    }
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String source;
  final double value;
  final String unit;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.source,
    required this.value,
    required this.icon,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
            color: color.withOpacity(0.2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text("Source: $source", style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          Text("${value.toStringAsFixed(1)} $unit",
              style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
