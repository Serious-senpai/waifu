import "dart:async";
import "dart:math";

import "package:async_locks/async_locks.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:http/http.dart";
import "package:image_gallery_saver/image_gallery_saver.dart";

import "cache.dart";
import "errors.dart";
import "sources.dart";

String sfwStateExpression(bool isSfw) => isSfw ? "sfw" : "nsfw";

class ImageClient {
  /// [Client] to perform HTTP requests
  final http = Client();

  /// Mapping of SFW categories to providable image sources
  final sfw = <String, List<ImageSource>>{};

  /// Mapping of NSFW categories to providable image sources
  final nsfw = <String, List<ImageSource>>{};

  /// Mapping of image URLs to image data
  final history = ImageCache();

  /// Single processor that manages the image fetching process
  late final SingleImageProcessor singleProcessor;

  /// Multi-processor that manages the image fetching process
  late final MultipleImagesProcessor multiProcessor;

  /// The current image category
  String category = "waifu";

  /// Is the current image mode SFW?
  bool isSfw = true;

  /// A [String] describes the current mode
  String get describeMode => "${sfwStateExpression(isSfw)}/$category";

  final _rng = Random();
  final _semaphore = Semaphore(5);

  Future<void> prepare() async {
    var sources = constructSources(this);
    var prepareFutures = <Future<void>>[];
    for (var source in sources) {
      prepareFutures.add(source.populateCategories());
    }

    await Future.wait(prepareFutures);

    for (var source in sources) {
      for (var category in source.sfw) {
        sfw.putIfAbsent(category, () => <ImageSource>[]).add(source);
      }

      for (var category in source.nsfw) {
        nsfw.putIfAbsent(category, () => <ImageSource>[]).add(source);
      }
    }

    singleProcessor = SingleImageProcessor(this);
    multiProcessor = MultipleImagesProcessor(this);
  }

  Future<ImageData> fetchImage() async {
    var sources = isSfw ? sfw[category] : nsfw[category];
    var index = _rng.nextInt(sources!.length);
    var source = sources[index];

    return await _semaphore.run(
      () async {
        var url = await source.getImageUrl(category, isSfw: isSfw);
        history.add(url, await fetchFromURL(url));

        return history[url]!;
      },
    );
  }

  Future<ImageData> fetchFromURL(String url) async {
    if (history[url] != null) {
      return history[url]!;
    }

    var response = await http.get(Uri.parse(url));
    return ImageData(url, category, isSfw, response.bodyBytes);
  }
}

class SingleImageProcessor {
  final ImageClient client;

  Completer<ImageData> inProgress = Completer<ImageData>();

  /// The last fetched image;
  ImageData? currentImage;

  SingleImageProcessor(this.client) {
    resetProgress(forced: true);
  }

  void resetProgress({bool forced = false, ImageData? customData}) {
    if (!inProgress.isCompleted) {
      if (forced) {
        inProgress.completeError(RequestCancelledException);
      } else {
        Fluttertoast.showToast(msg: "You are on a cooldown!");
        return;
      }
    }

    inProgress = Completer<ImageData>();
    if (customData == null) {
      var future = client.fetchImage();
      future.then(
        (data) {
          if (!inProgress.isCompleted) {
            currentImage = data;
            inProgress.complete(data);
          }
          return data;
        },
      );
    } else {
      currentImage = customData;
      inProgress.complete(customData);
    }
  }

  /// Save the current image which has been completely fetched.
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

class MultipleImagesProcessor {
  final ImageClient client;

  final inProgress = <Completer<ImageData>>[];

  MultipleImagesProcessor(this.client);

  void clearProcess() => inProgress.clear();

  void addProcess({ImageData? customData}) {
    var process = Completer<ImageData>();
    inProgress.add(process);

    if (customData == null) {
      var future = client.fetchImage();
      future.then(
        (data) {
          if (!process.isCompleted) {
            process.complete(data);
          }
          return data;
        },
      );
    } else {
      process.complete(customData);
    }
  }
}
