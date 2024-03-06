// ignore_for_file: prefer_const_constructors, unnecessary_import

import 'dart:io';

import 'package:camara_application/gallery.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  void initState() {
    initializeCamera(selectedCamera); //at initial phase slected camera = 0
    super.initState();
  }

  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int selectedCamera = 0;
  List<File> capturedImages = [];

  initializeCamera(int cameraIndex) async {
    _controller = CameraController(
      widget.cameras[cameraIndex], //get specific camera from the list
      ResolutionPreset.medium, //resolution to use
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
    //disposing the controller
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: Column(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(
                    _controller); // future is complete then display the previw
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          Spacer(),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      onPressed: () {
                        if (widget.cameras.length > 1) {
                          setState(() {
                            selectedCamera = selectedCamera == 0 ? 1 : 0;
                            initializeCamera(selectedCamera);
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("No secondary Camera found"),
                            duration: Duration(seconds: 2),
                          ));
                        }
                      },
                      icon: Icon(
                        Icons.camera_enhance,
                        color: Colors.white,
                        size: 40,
                      )),
                  GestureDetector(
                    onTap: () async {
                      await _initializeControllerFuture;
                      var xFile = await _controller.takePicture();
                      final appDir = await getExternalStorageDirectory();
                      final fileName = DateTime.now().toIso8601String();
                      final savedImage = await File(xFile.path)
                          .copy('${appDir?.path}/$fileName.png');
                      setState(() {
                        capturedImages.add(savedImage);
                      });

                      await ImageGallerySaver.saveFile(savedImage.path);
                    },
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (capturedImages.isEmpty) {
                        return;
                      }
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => GalleryScreen(
                                  images: capturedImages.reversed.toList())));
                    },
                    child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          image: capturedImages.isNotEmpty
                              ? DecorationImage(
                                  image: FileImage(capturedImages.last),
                                  fit: BoxFit.cover)
                              : null,
                        )),
                  ),
                ],
              )),
          Spacer()
        ],
      ),
    );
  }
}