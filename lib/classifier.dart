import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_picker/image_picker.dart';

class Classifier {
  Classifier();

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

  Future<bool> getImageLabels(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    ImageLabeler imageLabeler =
        ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.75));
    List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
    for (ImageLabel imgLabel in labels) {
      String lblText = imgLabel.label;
      if (lblText == 'Dog') {
        imageLabeler.close();
        return true;
      }
    }
    imageLabeler.close();
    return false;
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
