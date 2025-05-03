import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/file_downloader.dart';

class ExportedFilesView extends StatefulWidget {
  const ExportedFilesView({super.key});

  @override
  State<ExportedFilesView> createState() => _ExportedFilesViewState();
}

class _ExportedFilesViewState extends State<ExportedFilesView> {
  List<Map<String, dynamic>> allFiles = [];
  List<Map<String, dynamic>> filteredFiles = [];
  String selectedFilter = 'All Time';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('exported_files') ?? [];
    final parsed =
        data
            .map((e) => jsonDecode(e))
            .cast<Map<String, dynamic>>()
            .toList()
            .reversed
            .toList();
    setState(() {
      allFiles = parsed;
      _applyFilter();
    });
  }

  void _applyFilter() {
    final now = DateTime.now();
    if (selectedFilter == 'All Time') {
      filteredFiles = allFiles;
    } else {
      filteredFiles =
          allFiles.where((file) {
            final dt = DateTime.tryParse(file['dateTime'] ?? '');
            return dt != null && now.difference(dt).inDays <= 7;
          }).toList();
    }
    setState(() {});
  }

  void _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('exported_files');
    setState(() {
      allFiles.clear();
      filteredFiles.clear();
    });
  }

  void _previewFile(String content) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("CSV Preview"),
            content: SingleChildScrollView(child: Text(content)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exported Files"),
        backgroundColor: color.surface,
        actions: [
          DropdownButton<String>(
            value: selectedFilter,
            dropdownColor: color.surface,
            items: const [
              DropdownMenuItem(value: 'All Time', child: Text('All Time')),
              DropdownMenuItem(
                value: 'Last 7 Days',
                child: Text('Last 7 Days'),
              ),
            ],
            onChanged: (value) {
              selectedFilter = value!;
              _applyFilter();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () => _confirmClear(),
          ),
        ],
      ),
      body:
          filteredFiles.isEmpty
              ? const Center(child: Text("No exported files."))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredFiles.length,
                itemBuilder: (_, i) {
                  final file = filteredFiles[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: const Icon(Icons.file_present),
                      title: Text(file['fileName']),
                      subtitle: Text(
                        "🕒 ${file['dateTime']}\n📊 Sensors: ${file['sensors']?.join(', ')}",
                      ),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => _previewFile(file['content']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.download),
                            onPressed:
                                () => downloadFileMobile(
                                  context,
                                  file['content'],
                                  file['fileName'],
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Clear All History?"),
            content: const Text(
              "Are you sure you want to delete all export records?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearHistory();
                },
                child: const Text("Clear"),
              ),
            ],
          ),
    );
  }
}
