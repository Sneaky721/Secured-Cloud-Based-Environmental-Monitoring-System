import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final db = FirebaseDatabase.instance.ref("realtime_data");

  /// Stream sensor data from the latest document with thingy, server1, server2
  Stream<Map<String, dynamic>> streamSensorData() {
    return db.orderByChild("timestamp").limitToLast(1).onValue.map((event) {
      final raw = event.snapshot.value as Map?;
      if (raw == null) return {"thingy": {}, "server1": {}, "server2": {}};

      final latestEntry = raw.entries.last.value as Map;
      return {
        "thingy": latestEntry["thingy"] ?? {},
        "server1": latestEntry["server1"] ?? {},
        "server2": latestEntry["server2"] ?? {},
      };
    });
  }

  /// Helper to build formatted table data
  List<Map<String, dynamic>> buildTableList({
    required Map raw,
    required String key,
  }) {
    final now = DateTime.now();
    return [
      {
        "value": raw[key]?.toString() ?? "--",
        "time": "${now.hour}:${now.minute}:${now.second}",
      }
    ];
  }
}
