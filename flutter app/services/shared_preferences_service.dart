import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ExportedFileModel {
  final String fileName;
  final String dateTime; // formatted like '2024-04-07 18:44:55'
  final List<String> sensors;
  final String content;

  ExportedFileModel({
    required this.fileName,
    required this.dateTime,
    required this.sensors,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'dateTime': dateTime,
    'sensors': sensors,
    'content': content,
  };

  static ExportedFileModel fromJson(Map<String, dynamic> json) {
    return ExportedFileModel(
      fileName: json['fileName'],
      dateTime: json['dateTime'],
      sensors: List<String>.from(json['sensors']),
      content: json['content'],
    );
  }
}

class SharedPreferencesService {
  static const _key = 'exported_files';

  /// Save a new exported file to the export history list
  static Future<void> saveExportedFile(ExportedFileModel model) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> existing = prefs.getStringList(_key) ?? [];

    final updated = [...existing, jsonEncode(model.toJson())];
    await prefs.setStringList(_key, updated);
  }

  /// Load all exported files as model objects
  static Future<List<ExportedFileModel>> loadExportedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_key) ?? [];

    return raw.map((e) => ExportedFileModel.fromJson(jsonDecode(e))).toList();
  }

  /// Remove all saved export history
  static Future<void> clearExportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Optional helper if you want to return raw maps for list views
  static Future<List<Map<String, dynamic>>> loadAsMapList() async {
    final data = await loadExportedFiles();
    return data.map((e) => e.toJson()).toList();
  }

  /// Get current formatted datetime
  static String getFormattedNow() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
  }
}
