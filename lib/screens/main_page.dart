import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import 'scan_result_page.dart';
import 'scan_history_page.dart';

import '../models/prediction.dart';
import '../services/image_picker_service.dart';
import '../services/image_storage_service.dart';
import '../services/model_service.dart';
import '../database/database_helper.dart';
import '../models/scan.dart';


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final ImagePickerService _imagePickerService = ImagePickerService(); // instance of image picker class to access camera and gallery functionality
  final ModelService _modelService = ModelService(); // For CV model functionality

  bool _isProcessing = false;

  Future<void> _scanImage(ImageSource source) async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Pick image
      final XFile? pickedImage = source == ImageSource.camera
          ? await _imagePickerService.takePhoto()
          : await _imagePickerService.pickFromGallery();

      if (pickedImage == null) {
        return;
      }

      final originalImage = File(pickedImage.path);

      // Save original image to app storage
      final savedImagePath =
          await ImageStorageService.saveImage(originalImage);

      final savedImage = File(savedImagePath);

      // Run the CV model
      final predictions = await _modelService.predict(savedImage);

      // Create Scan record
      final scan = Scan(
        imagePath: savedImagePath,
        scannedAt: DateTime.now(),
      );

      // Save scan and predictions to database
      final scanId = await DatabaseHelper.instance.insertScan(
        scan,
        predictions,
      );

      // Show results
      if (!mounted) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultPage(
            scanId: scanId,
            imagePath: savedImagePath,
            predictions: predictions,
          ),
        ),
      );

    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Scan failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // void _showResults(
  //   int scanId,
  //   String imagePath,
  //   List<Prediction> predictions,
  // ) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => _ScanResultPage(
  //         scanId: scanId,
  //         imagePath: imagePath,
  //         predictions: predictions,
  //       ),
  //     ),
  //   );
  // }

  @override
  void dispose() {
    _modelService.dispose();
    super.dispose();
  }




  // Future<void> _takePhoto() async {
  //   final image = await _imagePickerService.takePhoto();

  //   if (image != null) {
  //     print('Selected image: ${image.path}');
  //   }
  // }

  // Future<void> _pickFromGallery() async {
  //   final image = await _imagePickerService.pickFromGallery();

  //   if (image != null) {
  //     print('Selected image: ${image.path}');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xffffffff), Color(0xffc3ff8f)], begin: AlignmentGeometry.topEnd, end: AlignmentGeometry.bottomEnd)
          ),
        child: Stack(
          children: <Widget>[
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 30,
                  children: <Widget>[
                    Image.asset("assets/cocoscan_logo.png", scale: 4,),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 40,
                      children: <Widget>[
                        // ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.camera), label: const Text('Camera')),
                        // ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.photo_library), label: const Text('Browse Gallery'))
                        
                        ElevatedButton(
                          onPressed: _isProcessing ? null : () => _scanImage(ImageSource.camera),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)
                            )
                          ), 
                          child: Column(
                            children: <Widget>[
                              Icon(Icons.camera, size: 70, color: Color(0xff008d55)),
                              Text('Camera', style: TextStyle(fontSize: 20, color: Color(0xff008d55)),)
                            ],
                          )
                        ),
                        
                        ElevatedButton(
                          onPressed: _isProcessing ? null : () => _scanImage(ImageSource.gallery),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)
                            )
                          ),
                          child: Column(
                            children: <Widget>[
                              Icon(Icons.photo_library, size: 70, color: Color(0xff008d55),),
                              Text('Gallery', style: TextStyle(fontSize: 20, color: Color(0xff008d55)))
                            ],
                          )
                        )
                      ],
                    ),

                    ElevatedButton(
                      onPressed: _isProcessing ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScanHistoryPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)
                        )
                      ),
                      child: const Text('Scan History', style: TextStyle(fontSize: 20, color: Color(0xff008d55)),)
                    ),

                    ElevatedButton(
                        onPressed: () {
                          SystemNavigator.pop();
                        }, 
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)
                          ),
                        ),
                        child: const Text('Exit', style: TextStyle(fontSize: 20, color: Color(0xff008d55)),)
                    )
                  ],
                ),
              )
            ),

            if (_isProcessing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xff008d55),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Analyzing image...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff008d55)
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Please wait.',
                            style: TextStyle(
                              color: Color(0xff008d55)
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ]
        )
      ),
      backgroundColor: Colors.white
    );
  }
}