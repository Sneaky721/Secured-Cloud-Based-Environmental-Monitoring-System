import 'package:flutter/material.dart';

class TablesView extends StatelessWidget {
  final List<Map<String, dynamic>> temperatureData;
  final List<Map<String, dynamic>> humidityData;
  final List<Map<String, dynamic>> oxygenData;
  final List<Map<String, dynamic>> lightData;

  const TablesView({
    super.key,
    required this.temperatureData,
    required this.humidityData,
    required this.oxygenData,
    required this.lightData,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SensorTableCard(
          title: "Temperature",
          icon: Icons.thermostat,
          color: Colors.orange,
          data: temperatureData,
          source: "Parking Spot (thingy)",
        ),
        SensorTableCard(
          title: "Humidity",
          icon: Icons.water_drop,
          color: Colors.blue,
          data: humidityData,
          source: "Parking Spot (thingy)",
        ),
        SensorTableCard(
          title: "Oxygen",
          icon: Icons.air,
          color: Colors.teal,
          data: oxygenData,
          source: "Park Backyard (server2)",
        ),
        SensorTableCard(
          title: "Light",
          icon: Icons.lightbulb,
          color: Colors.yellow.shade700,
          data: lightData,
          source: "Park Entrance (server1)",
        ),
      ],
    );
  }
}

class SensorTableCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> data;
  final String source;

  const SensorTableCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.data,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text("Source: $source"),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SensorDetailTable(title: title, data: data, source: source),
            ),
          );
        },
      ),
    );
  }
}

class SensorDetailTable extends StatelessWidget {
  final String title;
  final String source;
  final List<Map<String, dynamic>> data;

  const SensorDetailTable({
    super.key,
    required this.title,
    required this.data,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text("$title - $source"),
        backgroundColor: color.surface,
      ),
      body: data.isEmpty
          ? const Center(child: Text("No data available"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        itemBuilder: (context, i) {
          final row = data[i];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.data_array),
              title: Text("Value: ${row['value']}"),
              subtitle: Text("Time: ${row['time']}"),
            ),
          );
        },
      ),
    );
  }
}
