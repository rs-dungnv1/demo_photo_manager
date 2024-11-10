import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class Classifier {
  Classifier();
  List<Map<String, int>> faceMaps = [];

  Future<void> tfLteInit() async {
    await Tflite.loadModel(
        model: "assets/mask_detection/model_mask_detection.tflite",
        labels: "assets/mask_detection/labels.txt",
        numThreads: 1, // defaults to 1
        isAsset:
            true, // defaults to true, set to false to load resources outside assets
        useGpuDelegate:
            false // defaults to false, set to true to use GPU delegate
        );
  }

  Future<void> tfLteDispose() async {
    await Tflite.close();
  }

  Future<bool> detectFaces(XFile? imageFile) async {
    if (imageFile == null) {
      return false;
    }
    final FaceDetector faceDetector = FaceDetector(
        options: FaceDetectorOptions(
      enableContours:
          true, // Kích hoạt để lấy contour (đường viền) của khuôn mặt
      enableLandmarks:
          true, // Kích hoạt để lấy landmarks (điểm đặc trưng) của khuôn mặt
    ));

    final inputImage = InputImage.fromFilePath(imageFile.path);
    final List<Face> faces = await faceDetector.processImage(inputImage);
    // Xử lý các khuôn mặt được phát hiện
    if (faces.isEmpty) {
      return false;
    } else {
      for (Face face in faces) {
        int x = face.boundingBox.left.toInt();
        int y = face.boundingBox.top.toInt();
        int w = face.boundingBox.width.toInt();
        int h = face.boundingBox.height.toInt();
        Map<String, int> thisMap = {'x': x, 'y': y, 'w': w, 'h': h};
        faceMaps.add(thisMap);
        print(faceMaps.first);
      }
      return true;
    }
  }

  Future<XFile?> classifierImage(XFile image) async {
    print("readAsBytesSync");
    img.Image? originalImage =
        img.decodeImage(File(image.path).readAsBytesSync());
    print("readAsBytesSync done");
    img.Image faceCrop = img.copyCrop(originalImage!, faceMaps[0]['x']!,
        faceMaps[0]['y']!, faceMaps[0]['w']!, faceMaps[0]['h']!);
    print("crop done ");
    final imageXFile = await imageToXFile(faceCrop);
    return imageXFile;
  }

  Future<XFile?> imageToXFile(img.Image image) async {
    try {
      // Encode the image to PNG or JPEG format
      Uint8List encodedBytes = Uint8List.fromList(img.encodePng(image));

      // Get a temporary directory to save the file
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/temp_image.png';

      // Write the encoded image bytes to a file
      final file = await File(filePath).writeAsBytes(encodedBytes);

      // Convert the file to XFile
      return XFile(file.path);
    } catch (e) {
      print("Error converting image.Image to XFile: $e");
      return null;
    }
  }

  Future<List<dynamic>?> predict(XFile image) async {
    var recognitions = await Tflite.runModelOnImage(
        path: image.path, // required
        imageMean: 0.0, // defaults to 117.0
        imageStd: 255.0, // defaults to 1.0
        numResults: 5, // defaults to 5
        threshold: 0.2, // defaults to 0.1
        asynch: true // defaults to true
        );

    if (recognitions == null) {
      return null;
    }
    return recognitions;
  }
}
