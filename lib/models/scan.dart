class Scan {
  final int? id;
  final String imagePath;
  final DateTime scannedAt;

  Scan({
    this.id,
    required this.imagePath,
    required this.scannedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'scanned_at': scannedAt.toIso8601String(),
    };
  }

  factory Scan.fromMap(Map<String, dynamic> map) {
    return Scan(
      id: map['id'] as int?,
      imagePath: map['image_path'] as String,
      scannedAt: DateTime.parse(map['scanned_at'] as String),
    );
  }
}