import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "package:async_locks/async_locks.dart";
import "package:flutter/foundation.dart";
import "package:image_gallery_saver/image_gallery_saver.dart";

import "http.dart";

class ImageData {
  final Uint8List data;
  final String url;

  ImageData(this.data, this.url);
}

typedef ImageFuture = Future<ImageData>;

enum ImageMode {
  sfw,
  nsfw,
  random,
}

/// Class for fetching random images from the Internet
class ImageClient {
  /// The current image mode of the application, initially set to [ImageMode.sfw]
  ImageMode mode = ImageMode.sfw;

  /// The current image category of the application, initially set to `waifu`
  String category = "waifu";

  /// A string describing the current image mode
  String get describeMode {
    if (mode == ImageMode.random) {
      return "random";
    } else {
      var modeString = describeEnum(mode).toUpperCase();
      return "$modeString $category";
    }
  }

  /// [HTTPClient] to communicate with Haruka server as well as third-party ones
  final HTTPClient _client;

  /// Cache for storing fetched images with URLs as keys
  final imageDataCache = <String, ImageData>{};

  /// List of SFW categories
  final sfw = <String>[];

  /// List of NSFW categories
  final nsfw = <String>[];

  /// List of SFW images in the collection
  final collection = <String>[];

  int __collectionPointer = 0;

  final __collectionUpdateLock = Lock();

  int get _collectionPointer {
    var current = __collectionPointer;
    if (__collectionPointer == collection.length - 1) {
      __collectionPointer = 0;
    } else {
      __collectionPointer++;
    }
    return current;
  }

  /// [Event] signal that will be set when this [ImageClient] is ready.
  final _ready = Event();

  /// The [Future] that actually fetches the images, initially set to `null`
  /// and will be initialized in [prepare]
  ImageFuture? future;

  /// The current image
  ImageData? currentImage;

  /// Signal that [future] has completed, initially set to `true`.
  bool _futureCompleted = true;

  ImageClient._(HTTPClient httpClient) : _client = httpClient;

  /// Create a new [ImageClient]
  static Future<ImageClient> create() async {
    var httpClient = await HTTPClient.create();
    var imageClient = ImageClient._(httpClient);
    imageClient.prepare();
    return imageClient;
  }

  /// Clear the internal cache
  void clearCache() => imageDataCache.clear();

  /// Initialize this [ImageClient] so that it is ready to fetch images.
  Future<void> prepare() async {
    resetFuture();
    if (ready) return;

    var response = await _client.harukaRequest("GET", "/image/endpoints");
    raiseForStatus(response);

    var data = jsonDecode(response.body);
    sfw
      ..addAll(List<String>.from(data["sfw"]))
      ..sort();
    nsfw
      ..addAll(List<String>.from(data["nsfw"]))
      ..sort();

    await updateCollection();

    _ready.set();
  }

  /// Whether this client is ready
  bool get ready => _ready.isSet;

  /// Wait until this [ImageClient] is ready (that is, when [prepare] is completed).
  Future<void> waitUntilReady() async => await _ready.wait();

  /// Reset the [future] to fetch another images.
  ///
  /// Have no effect if [future] has not yet completed.
  void resetFuture() {
    if (!_futureCompleted) return;

    _futureCompleted = false;
    future = fetchImage();
    future?.whenComplete(() => _futureCompleted = true);
  }

  /// Update the internal SFW images collection, return `true` on success
  Future<bool> updateCollection() async {
    var response = await _client.harukaRequest("GET", "/collection/list");
    try {
      if (response.statusCode == 200) {
        collection.clear();
        collection.addAll(List<String>.from(jsonDecode(response.body)));
        return true;
      }
    } catch (e) {
      null;
    }
    return false;
  }

  /// Fetch image of the current [category] and [mode]
  ImageFuture fetchImage() async {
    await waitUntilReady();
    if (mode == ImageMode.random) {
      var response = await _client.harukaRequest("GET", "/collection");
      raiseForStatus(response);
      var data = jsonDecode(response.body);
      var url = data["url"];
      return currentImage = await fetchAndCache(url);
    }

    var params = {
      "mode": describeEnum(mode),
      "category": category,
    };
    var response = await _client.harukaRequest("GET", "/image", params: params);
    raiseForStatus(response);

    var data = jsonDecode(response.body);
    var host = data["host"];
    var apiUrl = data["url"];

    response = await _client.get(Uri.parse(apiUrl));
    raiseForStatus(response);
    data = jsonDecode(response.body);

    String imageUrl;

    switch (host) {
      case "waifu.im":
        imageUrl = data["images"][0]["url"];
        break;
      default:
        imageUrl = data["url"];
    }

    var cached = imageDataCache[imageUrl];
    if (cached != null) return cached;

    return currentImage = await fetchAndCache(imageUrl);
  }

  /// Get an image from the collection
  ///
  /// This operation does not cache the image data
  ImageFuture getFromCollection() async {
    await __collectionUpdateLock.run(
      () async {
        while (collection.isEmpty) {
          var status = await updateCollection();
          if (!status) {
            await Future.delayed(const Duration(seconds: 30));
          }
        }
      },
    );

    var filename = collection[_collectionPointer];
    var response = await _client.harukaRequest("GET", "/assets/images/$filename");
    raiseForStatus(response);
    return ImageData(response.bodyBytes, _client.harukaHost + "/assets/images/$filename");
  }

  void backwardCollectionPointer(int backward) {
    __collectionPointer -= backward;
    if (__collectionPointer < 0) {
      __collectionPointer += collection.length;
    }
  }

  /// Get image data from its URL
  ImageFuture fetch(String imageUrl) async {
    var response = await _client.get(Uri.parse(imageUrl));
    raiseForStatus(response);
    return ImageData(response.bodyBytes, imageUrl);
  }

  /// Get image data from its URL, cache the result and return it.
  ImageFuture fetchAndCache(String imageUrl) async {
    var data = await fetch(imageUrl);
    imageDataCache[imageUrl] = data;
    return data;
  }

  /// Save the current image that [future] fetched. If [future] has not completed
  /// then this method will wait until its result is ready.
  ///
  /// Returns `true` on success and `false` otherwise.
  Future<bool> saveCurrentImage() async {
    if (currentImage != null) {
      var result = await ImageGallerySaver.saveImage(currentImage!.data);
      return result["isSuccess"];
    }
    return false;
  }
}
