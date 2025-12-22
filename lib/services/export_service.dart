import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/repositories/repositories.dart';

enum ExportFormat { json, csv }

class ExportService {
  final VisitsRepository _repository;

  ExportService(this._repository);

  Future<String> _getExportDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  String _generateFileName(ExportFormat format) {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final extension = format == ExportFormat.json ? 'json' : 'csv';
    return 'coordinate_export_$timestamp.$extension';
  }

  Future<File> exportToFile(ExportFormat format) async {
    final dir = await _getExportDirectory();
    final fileName = _generateFileName(format);
    final file = File('$dir/$fileName');

    String content;
    if (format == ExportFormat.json) {
      final data = _repository.exportToJson();
      content = const JsonEncoder.withIndent('  ').convert(data);
    } else {
      content = _repository.exportToCsv();
    }

    await file.writeAsString(content);
    return file;
  }

  Future<void> shareExport(ExportFormat format) async {
    final file = await exportToFile(format);
    final xFile = XFile(file.path);
    await Share.shareXFiles(
      [xFile],
      subject: 'Coordinate Travel Data Export',
      text: 'My travel history from Coordinate app',
    );
  }

  Future<String> getExportPreview(ExportFormat format, {int maxItems = 3}) async {
    if (format == ExportFormat.json) {
      final data = _repository.exportToJson();
      final preview = data.take(maxItems).toList();
      return const JsonEncoder.withIndent('  ').convert(preview);
    } else {
      final csv = _repository.exportToCsv();
      final lines = csv.split('\n');
      return lines.take(maxItems + 1).join('\n'); // +1 for header
    }
  }

  Future<int> importFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as List<dynamic>;
      return await _repository.importFromJson(data);
    } catch (e) {
      throw FormatException('Invalid JSON format: $e');
    }
  }

  Future<int> importFromFile(File file) async {
    final content = await file.readAsString();
    return importFromJson(content);
  }

  int getTotalVisitsCount() {
    return _repository.getAllVisits().length;
  }
}










