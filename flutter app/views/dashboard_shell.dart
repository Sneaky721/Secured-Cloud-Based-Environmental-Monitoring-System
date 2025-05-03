import 'package:flutter/material.dart';
import '../views/cards_view.dart';
import '../views/charts_view.dart';
import '../views/tables_view.dart';
import '../views/analytics_view.dart';
import '../views/settings_view.dart';
import '../views/team_view.dart';
import '../views/exported_files_view.dart';
import '../services/firebase_service.dart';

class DashboardShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleMute;
  final bool isDark;
  final bool isMuted;

  const DashboardShell({
    super.key,
    required this.onToggleTheme,
    required this.onToggleMute,
    required this.isDark,
    required this.isMuted,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 0;
  final firebaseService = FirebaseService();

  Map<String, dynamic> thingy = {};
  Map<String, dynamic> server1 = {};
  Map<String, dynamic> server2 = {};

  List<Map<String, dynamic>> temperatureData = [];
  List<Map<String, dynamic>> humidityData = [];
  List<Map<String, dynamic>> oxygenData = [];
  List<Map<String, dynamic>> lightData = [];

  @override
  void initState() {
    super.initState();

    firebaseService.streamSensorData().listen((data) {
      setState(() {
        thingy = data['thingy'] ?? {};
        server1 = data['server1'] ?? {};
        server2 = data['server2'] ?? {};

        temperatureData = firebaseService.buildTableList(raw: thingy, key: 'temperature');
        humidityData = firebaseService.buildTableList(raw: thingy, key: 'humidity');
        oxygenData = firebaseService.buildTableList(raw: server2, key: 'oxygen');
        lightData = firebaseService.buildTableList(raw: server1, key: 'light');
      });
    });
  }

  String _getPageTitle(int index) {
    return ['Dashboard', 'Charts', 'Tables', 'Analytics', 'Settings'][index];
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CardsView(thingy: thingy, server1: server1, server2: server2),
      ChartsView(
        tempThingy: double.tryParse(thingy['temperature']?.toString() ?? '0') ?? 0,
        humThingy: double.tryParse(thingy['humidity']?.toString() ?? '0') ?? 0,
        oxyServer2: double.tryParse(server2['oxygen']?.toString() ?? '0') ?? 0,
        lightServer1: double.tryParse(server1['light']?.toString() ?? '0') ?? 0,
      ),
      TablesView(
        temperatureData: temperatureData,
        humidityData: humidityData,
        oxygenData: oxygenData,
        lightData: lightData,
      ),
      AnalyticsView(
        temperatureData: temperatureData.map((e) => double.tryParse(e['value'] ?? '0') ?? 0).toList(),
        humidityData: humidityData.map((e) => double.tryParse(e['value'] ?? '0') ?? 0).toList(),
        oxygenData: oxygenData.map((e) => double.tryParse(e['value'] ?? '0') ?? 0).toList(),
        lightData: lightData.map((e) => double.tryParse(e['value'] ?? '0') ?? 0).toList(),
      ),
      SettingsView(
        isDark: widget.isDark,
        isMuted: widget.isMuted,
        toggleTheme: widget.onToggleTheme,
        toggleMute: widget.onToggleMute,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle(_currentIndex)),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      drawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage('https://avatars.githubusercontent.com/u/9919?s=280&v=4'),
                  ),
                  SizedBox(height: 10),
                  Text('Sensor Dashboard', style: TextStyle(fontSize: 20, color: Colors.white)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text("Meet Our Team"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamView()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_copy),
              title: const Text("Exported Files"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportedFilesView()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text("Privacy Policy"),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Privacy Policy"),
                    content: const Text("This app collects sensor data to display in real-time. Your data is stored securely on Firebase."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Cards'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Charts'),
          NavigationDestination(icon: Icon(Icons.table_chart), label: 'Tables'),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
