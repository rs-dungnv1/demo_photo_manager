import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class PhotoGalleryPage extends StatefulWidget {
  const PhotoGalleryPage({super.key});

  @override
  State<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<PhotoGalleryPage> {
  List<AssetPathEntity> albums = [];
  List<AssetEntity> media = [];
  List<AssetEntity> selectedMedia = [];
  AssetPathEntity? selectedAlbum;
  @override
  void initState() {
    super.initState();
    checkPermission();
  }

  Future<void> checkPermission() async {
    final permissionState = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission:
            AndroidPermission(type: RequestType.image, mediaLocation: true),
      ),
    );
    if (permissionState.isAuth) {
      fetchAlbums();
    } else {
      PhotoManager.openSetting();
    }
  }

  Future<void> fetchAlbums() async {
    final List<AssetPathEntity> result = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        containsPathModified: true,
        // Dùng `hasAll` để lấy tất cả các thư mục chứa ảnh

        // Không giới hạn theo bất kỳ thư mục nào
      ),
    );
    setState(() {
      albums = result;
      selectedAlbum = albums.isNotEmpty ? albums.first : null;
    });
    if (selectedAlbum != null) {
      fetchMedia(selectedAlbum!); // Lấy ảnh từ album đầu tiên
    }
  }

  Future<void> fetchMedia(AssetPathEntity album) async {
    final List<AssetEntity> result =
        await album.getAssetListPaged(page: 0, size: 100);
    setState(() {
      media = result;
    });
  }

  void toggleSelection(AssetEntity asset, {bool isRemove = false}) {
    if (isRemove) {
      setState(() {
        if (selectedMedia.contains(asset)) {
          selectedMedia.remove(asset); // Bỏ chọn nếu đã được chọn
        }
      });
      return;
    }
    setState(() {
      if (selectedMedia.contains(asset)) {
        selectedMedia.remove(asset); // Bỏ chọn nếu đã được chọn
      } else if (selectedMedia.length < 5) {
        selectedMedia.add(asset); // Chọn ảnh nếu chưa đạt tối đa
      }
    });
  }

  void onAlbumSelected(AssetPathEntity? album) {
    if (album != null) {
      setState(() {
        selectedAlbum = album;
      });
      fetchMedia(album); // Cập nhật ảnh theo album mới được chọn
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 197, 192, 192),
      appBar: AppBar(
        centerTitle: true,
        title: DropdownButton<AssetPathEntity>(
          value: selectedAlbum,
          items: albums.map((album) {
            return DropdownMenuItem(
              value: album,
              child: Text(album.name,
                  style:
                      const TextStyle(color: Color.fromARGB(255, 92, 81, 81))),
            );
          }).toList(),
          onChanged: onAlbumSelected,
          dropdownColor: Colors.white,
          underline: Container(),
          iconEnabledColor: Colors.white,
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (selectedMedia.length == 5) {
                print("Đã chọn đủ 5 ảnh");
              } else {
                print("Vui lòng chọn đủ 5 ảnh");
              }
            },
            child: const Text('Done', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                ),
                itemCount: media.length,
                itemBuilder: (context, index) {
                  final asset = media[index];
                  final isSelected = selectedMedia.contains(asset);
                  return GestureDetector(
                    onTap: () => toggleSelection(asset),
                    child: Stack(
                      children: [
                        AssetEntityImage(
                          asset,
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                        if (isSelected)
                          const Positioned(
                            right: 5,
                            top: 5,
                            child: Icon(Icons.check_circle,
                                color: Colors.blue, size: 24),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: (selectedMedia.isNotEmpty)
          ? Container(
              height: 132,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              color: Colors.grey[200],
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Chọn 10 đến 20 ảnh')),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Text(
                          'Gần đây',
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Text(
                          'Tiếp theo',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedMedia.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Stack(
                            children: [
                              AssetEntityImage(
                                selectedMedia[index],
                                width: 60,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                color: Colors.black.withOpacity(0.5),
                                height: 70,
                                width: 60,
                              ),
                              Positioned(
                                right: 2,
                                top: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    toggleSelection(selectedMedia[index],
                                        isRemove: true);
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(),
    );
  }

  Widget buildThumbnail(AssetEntity asset) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
