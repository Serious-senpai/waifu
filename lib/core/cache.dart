import "package:quiver/collection.dart";

import "sources.dart";

class AsyncImageViewer {
  final List<String> _urls;
  final Future<ImageData> Function(String) _fetcher;
  final progress = <Future<ImageData>?>[];

  AsyncImageViewer(this._urls, this._fetcher) {
    for (var i = 0; i < length; i++) {
      progress.add(null);
    }
  }

  int get length => _urls.length;

  Future<ImageData> get(int index) => progress[index] ?? (progress[index] = _fetcher(_urls[index]));
}

/// Cache of all fetched images
/// This class actually only holds the data for some latest images,
/// earlier images will be fetched again from the servers instead.
class ImageCache {
  final _cache = LruMap<String, ImageData>(maximumSize: 30);
  final _urls = <String>{};

  int get maxSize => _cache.maximumSize;
  set maxSize(int value) => _cache.maximumSize = value;

  int get length => _urls.length;

  ImageData? operator [](String key) => _cache[key];
  void operator []=(String key, ImageData data) => add(key, data);

  /// Provide an [AsyncImageViewer] of the current cache images
  AsyncImageViewer view(Future<ImageData> Function(String) fetcher) => AsyncImageViewer(List<String>.from(_urls), fetcher);

  void add(String url, ImageData data) {
    _cache[url] = data;
    _urls.add(url);
  }
}
