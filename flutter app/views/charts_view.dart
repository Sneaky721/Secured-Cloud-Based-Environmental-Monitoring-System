import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartsView extends StatelessWidget {
  final double tempThingy;
  final double humThingy;
  final double oxyServer2;
  final double lightServer1;

  const ChartsView({
    super.key,
    required this.tempThingy,
    required this.humThingy,
    required this.oxyServer2,
    required this.lightServer1,
  });

  List<FlSpot> generateMockData(double base) {
    return List.generate(12, (i) {
      final val = base + (i.isEven ? 1.2 : -1.2) + i * 0.1;
      return FlSpot(i.toDouble(), val);
    });
  }

  Widget buildChartCard({
    required String label,
    required IconData icon,
    required double value,
    required Color color,
    required List<FlSpot> spots,
    required String unit,
    required String location,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  "${value.toStringAsFixed(1)} $unit",
                  style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Source: $location",
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.3)),
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        buildChartCard(
          label: "Temperature",
          icon: Icons.thermostat,
          value: tempThingy,
          unit: "°C",
          color: Colors.orange,
          spots: generateMockData(tempThingy),
          location: "Parking Spot (thingy)",
        ),
        buildChartCard(
          label: "Humidity",
          icon: Icons.water_drop,
          value: humThingy,
          unit: "%",
          color: Colors.blue,
          spots: generateMockData(humThingy),
          location: "Parking Spot (thingy)",
        ),
        buildChartCard(
          label: "Oxygen",
          icon: Icons.air,
          value: oxyServer2,
          unit: "%",
          color: Colors.teal,
          spots: generateMockData(oxyServer2),
          location: "Park Backyard (server2)",
        ),
        buildChartCard(
          label: "Light",
          icon: Icons.lightbulb,
          value: lightServer1,
          unit: "%",
          color: Colors.yellow.shade700,
          spots: generateMockData(lightServer1),
          location: "Park Entrance (server1)",
        ),
      ],
    );
  }
}
