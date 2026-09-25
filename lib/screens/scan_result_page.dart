import 'dart:io';

import 'package:flutter/material.dart';

import '../models/prediction.dart';

class ScanResultPage extends StatelessWidget {
  final int scanId;
  final String imagePath;
  final List<Prediction> predictions;

  const ScanResultPage({
    super.key,
    required this.scanId,
    required this.imagePath,
    required this.predictions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Results', style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xff008d55),
        iconTheme: IconThemeData(
          color: Colors.white
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(imagePath),
                height: 300,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Detection Results',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ...predictions.map(
              (prediction) {
                final percentage =
                    prediction.confidence * 100;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '#${prediction.rank}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(width: 12),

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
                          color: Color(0xff008d55),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('New Scan', style: TextStyle(color: Color(0xff008d55)),),
            ),
          ],
        ),
      ),
    );
  }
}