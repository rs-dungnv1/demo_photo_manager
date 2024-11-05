import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class MediaPickerScreen extends StatefulWidget {
  const MediaPickerScreen({super.key});

  @override
  State<MediaPickerScreen> createState() => _MediaPickerScreenState();
}

class _MediaPickerScreenState extends State<MediaPickerScreen> {
  List<AssetEntity> mediaList = [];

  @override
  void initState() {
    super.initState();
    _fetchMedia();
  }

  Future<void> _fetchMedia() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (permission.isAuth) {
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList();
      List<AssetEntity> media =
          await albums[0].getAssetListPaged(page: 0, size: 100);
      setState(() => mediaList = media);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Custom Media Picker")),
      body: GridView.builder(
        itemCount: mediaList.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemBuilder: (context, index) {
          return FutureBuilder(
            future: mediaList[index]
                .thumbnailDataWithSize(const ThumbnailSize(200, 200)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Image.memory(snapshot.data!, fit: BoxFit.cover);
              }
              return const CircularProgressIndicator();
            },
          );
        },
      ),
    );
  }
}
