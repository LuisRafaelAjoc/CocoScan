import 'dart:convert';
import 'dart:io';
// import 'dart:math' as math;
// import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/prediction.dart';

class ModelService {
  static const String _modelPath =
      'assets/models/cocoscan_efficientnetb4_v1_portable.tflite';

  static const String _labelsPath =
      'assets/models/class_labels.json';

  static const int _imageSize = 456;
  static const int _numClasses = 8;

  Interpreter? _interpreter;
  Map<int, String>? _classNames;

  // Loads the TFLite model and class labels
  Future<void> loadModel() async {
    if (_interpreter != null && _classNames != null) {
      return;
    }

    // Load TFLite model from Flutter assets
    _interpreter = await Interpreter.fromAsset(_modelPath);

    // Load tensors
    _interpreter!.allocateTensors();

    // Load class labels
    final labelsJson = await rootBundle.loadString(_labelsPath);
    final Map<String, dynamic> labelMap = jsonDecode(labelsJson);

    _classNames = {
      for (final entry in labelMap.entries)
        int.parse(entry.value.toString()): entry.key,
    };

    // Print model information for debugging.
    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);

    print('CocoScan model loaded.');
    print('Input shape: ${inputTensor.shape}');
    print('Input type: ${inputTensor.type}');
    print('Output shape: ${outputTensor.shape}');
    print('Output type: ${outputTensor.type}');
    print('Classes: $_classNames');

    // Verify the expected model configuration
    if (inputTensor.shape.length != 4 ||
        inputTensor.shape[0] != 1 ||
        inputTensor.shape[1] != _imageSize ||
        inputTensor.shape[2] != _imageSize ||
        inputTensor.shape[3] != 3) {
      throw Exception(
        'Unexpected model input shape: ${inputTensor.shape}. '
        'Expected [1, $_imageSize, $_imageSize, 3].',
      );
    }

    if (_classNames!.length != _numClasses) {
      throw Exception(
        'Expected $_numClasses classes, '
        'but ${_classNames!.length} were found in class_labels.json.',
      );
    }
  }

  // Runs the CocoScan model on an image
  // Returns predictions sorted from highest confidence to lowest
  // The returned Prediction objects temporarily use scanId = 0
  // DatabaseHelper will assign the real scan ID when the scan is saved
  Future<List<Prediction>> predict(File imageFile) async {
    await loadModel();

    final interpreter = _interpreter!;
    final classNames = _classNames!;

    // Read image
    final imageBytes = await imageFile.readAsBytes();

    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      throw Exception(
        'Could not decode image: ${imageFile.path}',
      );
    }

    // Resize to 456 × 456
    final resizedImage = img.copyResize(
      decodedImage,
      width: _imageSize,
      height: _imageSize,
      interpolation: img.Interpolation.linear,
    );

    // Create float32 input tensor
    final input = List.generate(
      1,
      (_) => List.generate(
        _imageSize,
        (y) => List.generate(
          _imageSize,
          (x) {
            final pixel = resizedImage.getPixel(x, y);

            return <double>[
              pixel.r.toDouble(),
              pixel.g.toDouble(),
              pixel.b.toDouble(),
            ];
          },
        ),
      ),
    );

    // Prepare output tensor
    final output = List.generate(
      1,
      (_) => List<double>.filled(
        _numClasses,
        0.0,
      ),
    );

    // Run TFLite inference
    interpreter.run(
      input,
      output,
    );

    // Extract probabilities
    final probabilities = output[0];

    if (probabilities.length != _numClasses) {
      throw Exception(
        'Unexpected model output size: ${probabilities.length}. '
        'Expected $_numClasses.',
      );
    }

    // Create indexed prediction list
    final indexedPredictions = <_IndexedPrediction>[];

    for (int i = 0; i < probabilities.length; i++) {
      final probability = probabilities[i];

      indexedPredictions.add(
        _IndexedPrediction(
          index: i,
          probability: probability,
        ),
      );
    }

    // Sort highest probability first
    indexedPredictions.sort(
      (a, b) => b.probability.compareTo(a.probability),
    );

    // Convert to Prediction objects
    final predictions = <Prediction>[];

    for (int i = 0; i < indexedPredictions.length; i++) {
      final result = indexedPredictions[i];

      final className = classNames[result.index];

      if (className == null) {
        throw Exception(
          'No class label found for output index ${result.index}.',
        );
      }

      predictions.add(
        Prediction(
          scanId: 0,
          diseaseClass: className,
          confidence: result.probability,
          rank: i + 1,
        ),
      );
    }

    return predictions;
  }

  // Returns the highest-confidence prediction.
  Future<Prediction> predictTop(File imageFile) async {
    final predictions = await predict(imageFile);

    if (predictions.isEmpty) {
      throw Exception('The model returned no predictions.');
    }

    return predictions.first;
  }

  // Releases the TFLite interpreter.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _classNames = null;
  }
}

class _IndexedPrediction {
  final int index;
  final double probability;

  _IndexedPrediction({
    required this.index,
    required this.probability,
  });
}