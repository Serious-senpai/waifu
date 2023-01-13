import "dart:async";
import "dart:math";

import "package:flutter/material.dart";
import "package:http/http.dart";
import "package:image_gallery_saver/image_gallery_saver.dart";

import "errors.dart";
import "sources.dart";
import "utils.dart";

String sfwStateExpression(bool isSfw) => isSfw ? "sfw" : "nsfw";

class ImageClient {
  final _client = Client();
  final _rng = Random();

  /// Mapping of SFW categories to providable image sources
  final sfw = <String, List<ImageSource>>{};

  /// Mapping of NSFW categories to providable image sources
  final nsfw = <String, List<ImageSource>>{};

  /// Mapping of image URLs to image data
  final history = <String, ImageData>{};

  /// Processor that manages the image fetching process
  late final ImageFetchingProcessor processor;

  /// The last fetched image;
  ImageData? lastImage;

  /// The current image category
  String category = "waifu";

  /// Is the current image mode SFW?
  bool isSfw = true;

  /// A [String] describes the current mode
  String get describeMode => "${sfwStateExpression(isSfw)}/$category";

  Future<void> prepare() async {
    var sources = constructSources(_client);
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

    processor = ImageFetchingProcessor(this);
  }

  Future<ImageData> fetchImage() async {
    var sources = isSfw ? sfw[category] : nsfw[category];
    var index = _rng.nextInt(sources!.length);
    var source = sources[index];

    var image = await source.fetchImage(category, isSfw: isSfw);
    lastImage = history[image.url] = image;
    return image;
  }

  /// Save the current image which has been completely fetched.
  ///
  /// Returns `true` on success and `false` otherwise.
  Future<bool> saveCurrentImage() async {
    if (lastImage != null) {
      var result = await ImageGallerySaver.saveImage(lastImage!.data);
      return result["isSuccess"];
    }
    return false;
  }
}

class ImageFetchingProcessor {
  final ImageClient client;

  Completer<ImageData> inProgress = Completer<ImageData>();

  ImageFetchingProcessor(this.client) {
    inProgress.complete(client.fetchImage());
  }

  void resetProgress({bool forced = false, ImageData? customData}) {
    if (!inProgress.isCompleted) {
      if (forced) {
        inProgress.completeError(RequestCancelledException);
      } else {
        return;
      }
    }

    inProgress = Completer<ImageData>();
    if (customData == null) {
      var future = client.fetchImage();
      future.then(
        (data) {
          if (!inProgress.isCompleted) {
            inProgress.complete(data);
          }
          return data;
        },
      );
    } else {
      inProgress.complete(customData);
    }
  }

  Widget transform(BuildContext context, AsyncSnapshot<ImageData> snapshot) {
    if (snapshot.connectionState == ConnectionState.done) {
      return Image.memory(snapshot.data!.data);
    } else if (snapshot.connectionState == ConnectionState.waiting) {
      return loadingIndicator(content: "Loading image");
    } else {
      return errorIndicator(content: "Invalid state: ${snapshot.connectionState}");
    }
  }
}
