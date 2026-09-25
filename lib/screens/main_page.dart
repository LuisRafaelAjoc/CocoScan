import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/image_picker_service.dart'; // for usage of device camera and image gallery

import 'scan_history_page.dart';


class MainPage extends StatelessWidget {
  MainPage({super.key});

  final ImagePickerService _imagePickerService = ImagePickerService(); // instance of image picker class to access camera and gallery functionality

  Future<void> _takePhoto() async {
    final image = await _imagePickerService.takePhoto();

    if (image != null) {
      print('Selected image: ${image.path}');
    }
  }

  Future<void> _pickFromGallery() async {
    final image = await _imagePickerService.pickFromGallery();

    if (image != null) {
      print('Selected image: ${image.path}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xffffffff), Color(0xffc3ff8f)], begin: AlignmentGeometry.topEnd, end: AlignmentGeometry.bottomEnd)
          ),
        child: Center(
          child: IntrinsicWidth(
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
                      onPressed: _takePhoto,
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
                      onPressed: _pickFromGallery,
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ScanHistoryPage(),
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
      ),
      backgroundColor: Colors.white
    );
  }
}