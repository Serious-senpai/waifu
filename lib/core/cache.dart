import "package:async_locks/async_locks.dart";
import "package:quiver/collection.dart";

import "constants.dart";
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
  final _cache = LruMap<String, ImageData>(maximumSize: initialImagesCacheSize);
  final _urls = <String>{};

  /// Maximum size of this cache
  int get maxSize => _cache.maximumSize;
  set maxSize(int value) {
    _cache.maximumSize = value;
    _lengthInBytesEvent.set();
  }

  /// Number of fetched images
  ///
  /// This number may exceed [maxSize] because it also includes the images
  /// whose binary data was removed from the cache
  int get length => _urls.length;

  /// Number of images whose binary data is cached
  int get lengthCached => _cache.length;

  final _lengthInBytesEvent = Event();
  Stream<double>? _lengthInBytesStream;
  Stream<double> get lengthInBytesStream {
    if (_lengthInBytesStream != null) return _lengthInBytesStream!;

    Stream<double> singleStream() async* {
      while (true) {
        await _lengthInBytesEvent.wait();
        _lengthInBytesEvent.clear();
        yield lengthInBytes;
      }
    }

    return _lengthInBytesStream = singleStream().asBroadcastStream();
  }

  /// Total memory size of the images' binary data
  double get lengthInBytes {
    var sum = 0.0;
    _cache.forEach((_, data) => sum += data.data.lengthInBytes);
    return sum;
  }

  ImageData? operator [](String key) => _cache[key];
  void operator []=(String key, ImageData data) => add(key, data);

  /// Provide an [AsyncImageViewer] of the current cache images
  AsyncImageViewer view(Future<ImageData> Function(String) fetcher) => AsyncImageViewer(List<String>.from(_urls), fetcher);

  void add(String url, ImageData data) {
    _cache[url] = data;
    _urls.add(url);
    _lengthInBytesEvent.set();
  }
}
