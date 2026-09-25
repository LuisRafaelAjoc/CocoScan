import 'dart:io';

import '../database/database_helper.dart';
import '../models/prediction.dart';
import '../models/scan.dart';
import 'image_storage_service.dart';

class ScanService {
  static Future<int> saveScanResult({
    required File image,
    required List<Map<String, dynamic>> results,
  }) async {
    // Save the image to the app's local storage
    final imagePath = await ImageStorageService.saveImage(image);

    // Create the scan record
    final scan = Scan(
      imagePath: imagePath,
      scannedAt: DateTime.now(),
    );

    // Create prediction records
    final predictions = <Prediction>[];

    for (int i = 0; i < results.length; i++) {
      predictions.add(
        Prediction(
          scanId: 0,
          diseaseClass: results[i]['class'] as String,
          confidence: (results[i]['confidence'] as num).toDouble(),
          rank: i + 1,
        ),
      );
    }

    // Save everything to SQLite
    final scanId = await DatabaseHelper.instance.insertScan(
      scan,
      predictions,
    );

    return scanId;
  }
}