class Prediction {
  final int? id;
  final int scanId;
  final String diseaseClass;
  final double confidence;
  final int rank;

  Prediction({
    this.id,
    required this.scanId,
    required this.diseaseClass,
    required this.confidence,
    required this.rank,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scan_id': scanId,
      'disease_class': diseaseClass,
      'confidence': confidence,
      'rank': rank,
    };
  }

  factory Prediction.fromMap(Map<String, dynamic> map) {
    return Prediction(
      id: map['id'] as int?,
      scanId: map['scan_id'] as int,
      diseaseClass: map['disease_class'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      rank: map['rank'] as int,
    );
  }
}