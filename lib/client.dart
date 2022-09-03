import "dart:math";
import "dart:typed_data";

import "package:async_locks/async_locks.dart";
import "package:http/http.dart";
import "package:image_gallery_saver/image_gallery_saver.dart";

import "sources.dart";

class ImageCategory {
  /// The [ImageClient] to use for searching images
  final ImageClient client;

  /// The current category
  String category;

  /// The current image mode, must be "sfw" or "nsfw"
  String mode;

  /// A string describe the current mode
  String get describeMode => "${mode.toUpperCase()}/$category";

  /// The current image fetching progress
  late Future<Uint8List> inProgress;

  /// Initialize this [ImageCategory] with an [ImageClient]
  ImageCategory(this.client)
      : category = client.sfw.keys.first,
        mode = "sfw";

  void resetFuture() {
    inProgress = fetchImage();
  }

  Future<Uint8List> fetchImage() => client.fetchImage(category, mode: mode);
}

class ImageClient {
  final _client = Client();
  final _ready = Event();

  final sfw = <String, List<ImageSource>>{};
  final nsfw = <String, List<ImageSource>>{};

  final history = <String, Uint8List>{};

  String? currentUrl;

  Future<void> prepare() async {
    await populateSources(_client);
    for (var imageSource in imageSources) {
      for (var category in imageSource.sfw) {
        sfw.putIfAbsent(category, () => <ImageSource>[]);
        sfw[category]!.add(imageSource);
      }

      for (var category in imageSource.nsfw) {
        nsfw.putIfAbsent(category, () => <ImageSource>[]);
        nsfw[category]!.add(imageSource);
      }
    }

    _ready.set();
  }

  Future<void> waitUntilReady() async {
    await _ready.wait();
  }

  Future<String> getImageUrl(String category, {required String mode}) async {
    await waitUntilReady();
    var sources = mode == "sfw" ? sfw[category] : nsfw[category], index = Random().nextInt(sources!.length);
    var source = sources[index];
    return source.getImageUrl(category, mode: mode, client: _client);
  }

  Future<Uint8List> fetchImage(String category, {required String mode}) async {
    var url = currentUrl = await getImageUrl(category, mode: mode);
    if (history[url] == null) {
      var response = await _client.get(Uri.parse(url));
      history[url] = response.bodyBytes;
    }

    return history[url]!;
  }

  /// Save the current image which has been completely fetched.
  ///
  /// Returns `true` on success and `false` otherwise.
  Future<bool> saveCurrentImage() async {
    if (currentUrl != null) {
      var result = await ImageGallerySaver.saveImage(history[currentUrl]!);
      return result["isSuccess"];
    }
    return false;
  }
}
