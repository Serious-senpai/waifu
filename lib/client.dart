import "dart:convert";
import "dart:typed_data";

import "package:async_locks/async_locks.dart";
import "package:flutter/foundation.dart";
import "package:image_gallery_saver/image_gallery_saver.dart";

import "http.dart";

typedef ImageFutureData = Future<Uint8List?>;

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

  /// [HTTPClient] to communicate with Haruka server as well as third-party ones
  final HTTPClient _client;

  /// Cache for storing fetched images with URLs as keys
  final imageDataCache = <String, Uint8List>{};

  /// List of SFW categories
  final sfw = <String>[];

  /// List of NSFW categories
  final nsfw = <String>[];

  /// [Event] signal that will be set when this [ImageClient] is ready.
  final _ready = Event();

  /// The [Future] that actually fetches the images, initially set to `null`
  /// and will be initialized in [prepare]
  ImageFutureData? future;

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

  /// Clear the internal cache [imageDataCache]
  void clearCache() => imageDataCache.clear();

  /// Initialize this [ImageClient] so that it is ready to fetch images.
  Future<void> prepare() async {
    if (_ready.isSet) return;

    var response = await _client.harukaRequest("GET", "/image/endpoints");
    if (response.statusCode != 200) throw HTTPException(response);

    var data = jsonDecode(response.body);
    sfw
      ..addAll(List<String>.from(data["sfw"]))
      ..sort();
    nsfw
      ..addAll(List<String>.from(data["nsfw"]))
      ..sort();

    resetFuture();

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

  /// Fetch image of the current [category] and [mode]
  ImageFutureData fetchImage() async {
    await waitUntilReady();
    if (mode == ImageMode.random) {
      var response = await _client.harukaRequest("GET", "/collection");
      if (response.statusCode != 200) return null;
      var data = jsonDecode(response.body);
      var url = data["url"];
      return fetchAndCache(url);
    }

    var params = {
      "mode": describeEnum(mode),
      "category": category,
    };
    var response = await _client.harukaRequest("GET", "/image", params: params);
    if (response.statusCode != 200) return null;

    var data = jsonDecode(response.body);
    var host = data["host"];
    var apiUrl = data["url"];

    try {
      response = await _client.get(Uri.parse(apiUrl));
      data = jsonDecode(response.body);
    } catch (exc) {
      return null;
    }

    String imageUrl;

    switch (host) {
      case "waifu.im":
        imageUrl = data["images"][0]["url"];
        break;
      default:
        imageUrl = data["url"];
    }

    try {
      if (imageDataCache[imageUrl] != null) return imageDataCache[imageUrl];

      return await fetchAndCache(imageUrl);
    } catch (exc) {
      return null;
    }
  }

  /// Get image data from its URL, cache the result and return it.
  ImageFutureData fetchAndCache(String imageUrl) async {
    var response = await _client.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      var data = response.bodyBytes;
      imageDataCache[imageUrl] = data;
      return data;
    } else {
      throw HTTPException(response);
    }
  }

  /// Save the current image that [future] fetched. If [future] has not completed
  /// then this method will wait until its result is ready.
  ///
  /// Returns `true` on success and `false` otherwise.
  Future<bool> saveCurrentImage() async {
    if (future != null) {
      var data = await future;
      if (data != null) {
        var result = await ImageGallerySaver.saveImage(data);
        return result["isSuccess"];
      }
    }
    return false;
  }
}
