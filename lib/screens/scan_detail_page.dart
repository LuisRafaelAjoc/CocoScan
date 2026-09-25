import 'dart:io';

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/scan.dart';
import '../models/prediction.dart';

class ScanDetailPage extends StatefulWidget {
  final int scanId;

  const ScanDetailPage({
    super.key,
    required this.scanId,
  });

  @override
  State<ScanDetailPage> createState() =>
      _ScanDetailPageState();
}

class _ScanDetailPageState
    extends State<ScanDetailPage> {

  late Future<_ScanDetails> _details;

  @override
  void initState() {
    super.initState();

    _loadDetails();
  }

  void _loadDetails() {
    _details = _getDetails();
  }

  Future<_ScanDetails> _getDetails() async {
    final scan = await DatabaseHelper.instance
        .getScan(widget.scanId);

    if (scan == null) {
      throw Exception('Scan not found.');
    }

    final predictions =
        await DatabaseHelper.instance
            .getPredictions(widget.scanId);

    return _ScanDetails(
      scan: scan,
      predictions: predictions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan #${widget.scanId}',
        ),
      ),

      body: FutureBuilder<_ScanDetails>(
        future: _details,

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final details = snapshot.data!;

          return _buildContent(details);
        },
      ),
    );
  }

  Widget _buildContent(_ScanDetails details) {
    final scan = details.scan;
    final predictions = details.predictions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // IMAGE
          _buildImage(scan.imagePath),

          const SizedBox(height: 20),

          // DATE
          const Text(
            'Scan Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Date scanned: ${_formatDate(scan.scannedAt)}',
          ),

          const SizedBox(height: 5),

          const SizedBox(height: 25),

          // PREDICTIONS
          const Text(
            'Predictions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          if (predictions.isEmpty)
            const Text(
              'No predictions available.',
            ),

          ...predictions.map(
            (prediction) =>
                _buildPredictionCard(prediction),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    final file = File(imagePath);

    if (!file.existsSync()) {
      return Container(
        height: 250,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 60,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),

      child: Image.file(
        file,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildPredictionCard(
    Prediction prediction,
  ) {
    final percentage =
        prediction.confidence * 100;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [

                Expanded(
                  child: Text(
                    prediction.diseaseClass,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Text(
                  '${percentage.toStringAsFixed(2)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            LinearProgressIndicator(
              value: prediction.confidence,
            ),

            const SizedBox(height: 5),

            Text(
              'Rank ${prediction.rank}',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

class _ScanDetails {
  final Scan scan;
  final List<Prediction> predictions;

  _ScanDetails({
    required this.scan,
    required this.predictions,
  });
}