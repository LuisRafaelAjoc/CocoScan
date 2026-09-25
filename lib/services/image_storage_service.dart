import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  static Future<String> saveImage(File image) async {
    final directory = await getApplicationDocumentsDirectory();

    final scansDirectory = Directory(
      path.join(directory.path, 'scans'),
    );

    if (!await scansDirectory.exists()) {
      await scansDirectory.create(
        recursive: true,
      );
    }

    final extension = path.extension(image.path);

    final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}$extension';

    final destination = path.join(
      scansDirectory.path,
      fileName,
    );

    final savedImage = await image.copy(destination);

    return savedImage.path;
  }

  static Future<void> deleteImage(String imagePath,) async {
    final file = File(imagePath);

    if (await file.exists()) {
      await file.delete();
    }
  }
}