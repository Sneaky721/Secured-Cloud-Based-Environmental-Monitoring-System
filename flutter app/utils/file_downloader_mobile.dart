import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> downloadFileMobile(
  BuildContext context,
  String content,
  String fileName,
) async {
  final status = await Permission.storage.request();
  if (!status.isGranted) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Storage permission denied")),
      );
    }
    return;
  }

  final dir = await getExternalStorageDirectory();
  final path = '${dir!.path}/$fileName';
  final file = File(path);

  try {
    await file.writeAsString(content);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("✅ CSV saved to:\n$path")));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Failed to write file")));
    }
  }
}
