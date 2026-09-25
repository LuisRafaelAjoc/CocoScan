class Scan {
  final int? id;
  final String imagePath;
  final DateTime scannedAt;
  final String modelVersion;

  Scan({
    this.id,
    required this.imagePath,
    required this.scannedAt,
    required this.modelVersion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'scanned_at': scannedAt.toIso8601String(),
      'model_version': modelVersion,
    };
  }

  factory Scan.fromMap(Map<String, dynamic> map) {
    return Scan(
      id: map['id'] as int?,
      imagePath: map['image_path'] as String,
      scannedAt: DateTime.parse(map['scanned_at'] as String),
      modelVersion: map['model_version'] as String,
    );
  }
}