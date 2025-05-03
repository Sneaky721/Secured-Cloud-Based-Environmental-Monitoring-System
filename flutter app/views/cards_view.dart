import 'package:flutter/material.dart';

class CardsView extends StatelessWidget {
  final Map<String, dynamic> thingy;
  final Map<String, dynamic> server1;
  final Map<String, dynamic> server2;

  const CardsView({
    super.key,
    required this.thingy,
    required this.server1,
    required this.server2,
  });

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCard(String label, dynamic value, IconData icon,
      {Color? color}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.blue),
        title: Text(label),
        trailing: Text(
          "$value",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle("Parking Spot (Thingy)"),
        _buildCard(
          "Temperature",
          "${thingy['temperature'] ?? "--"} °C",
          Icons.thermostat,
          color: Colors.orange,
        ),
        _buildCard(
          "Humidity",
          "${thingy['humidity'] ?? "--"} %",
          Icons.water_drop,
          color: Colors.blue,
        ),
        _buildCard(
          "Pressure",
          "${thingy['pressure'] ?? "--"} hPa",
          Icons.speed,
          color: Colors.deepPurple,
        ),
        _buildCard(
          "Air Quality",
          "${thingy['air_quality'] ?? "--"}",
          Icons.air,
          color: Colors.green,
        ),
        _buildCard(
          "Coordinates",
          "${thingy['latitude'] ?? "--"}, ${thingy['longitude'] ?? "--"}",
          Icons.location_on,
          color: Colors.red,
        ),
        const SizedBox(height: 20),
        _buildSectionTitle("Park Entrance (Server 1)"),
        _buildCard(
          "Temperature",
          "${server1['temperature'] ?? "--"} °C",
          Icons.thermostat,
          color: Colors.orange,
        ),
        _buildCard(
          "Humidity",
          "${server1['humidity'] ?? "--"} %",
          Icons.water_drop,
          color: Colors.blue,
        ),
        _buildCard(
          "Light",
          "${server1['light'] ?? "--"}",
          Icons.lightbulb,
          color: Colors.yellow,
        ),
        const SizedBox(height: 20),
        _buildSectionTitle("Park Backyard (Server 2)"),
        _buildCard(
          "Temperature",
          "${server2['temperature'] ?? "--"} °C",
          Icons.thermostat,
          color: Colors.orange,
        ),
        _buildCard(
          "Humidity",
          "${server2['humidity'] ?? "--"} %",
          Icons.water_drop,
          color: Colors.blue,
        ),
        _buildCard(
          "Oxygen",
          "${server2['oxygen'] ?? "--"} %",
          Icons.air,
          color: Colors.teal,
        ),
      ],
    );
  }
}
