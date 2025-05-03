import 'package:flutter/material.dart';

class TeamView extends StatelessWidget {
  const TeamView({super.key});

  @override
  Widget build(BuildContext context) {
    final team = [
      {
        "name": "Aleksandr Moskalev",
        "role": "Embedded & Firmware Engineer",
        "photo": "https://randomuser.me/api/portraits/men/32.jpg",
      },
      {
        "name": "Harikant Sharma",
        "role": "Firebase & Data Engineer",
        "photo": "https://randomuser.me/api/portraits/men/40.jpg",
      },
      {
        "name": "Kaushal Khadka",
        "role": "Flutter UI & UX Developer",
        "photo": "https://randomuser.me/api/portraits/men/58.jpg",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meet Our Team"),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "We are a team of passionate developers and engineers who worked together to build a real-time sensor monitoring dashboard using Firebase, ESP32, and Flutter.",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          ...team.map((member) {
            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(member['photo']!),
                ),
                title: Text(
                  member['name']!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(member['role']!),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
