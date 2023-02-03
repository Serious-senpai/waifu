import "dart:collection";
import "dart:convert";
import "dart:typed_data";

import "package:flutter_image_compress/flutter_image_compress.dart";
import "package:meta/meta.dart";

import "client.dart";

class ImageData {
  final String url;
  final String category;
  final bool isSfw;
  Uint8List _data;
  bool _compressed = false;

  Uint8List get data => _data;

  ImageData(this.url, this.category, this.isSfw, this._data);

  Future<void> compress({bool force = false}) async {
    if (_compressed && !force) return;

    _data = await FlutterImageCompress.compressWithList(_data, quality: 80, format: CompressFormat.webp);
    _compressed = true;
  }

  @override
  String toString() => "<ImageData url = $url>";
}

abstract class ImageSource {
  /// The SFW categories that this source can handle
  abstract final Set<String> sfw;

  /// The NSFW categories that this source can handle
  abstract final Set<String> nsfw;

  /// Base URL for the API
  abstract final String baseUrl;

  /// The [ImageClient] that manages this source
  abstract final ImageClient client;

  HTTPClient get http => client.http;

  /// Get all categories that this image source can provide.
  Future<void> populateCategories();

  /// Get the URL for an image
  Future<String> getImageUrl(String category, {required bool isSfw});
}

class _BaseImageSource extends ImageSource {
  @override
  final sfw = <String>{};

  @override
  final nsfw = <String>{};

  @override
  String get baseUrl => throw UnimplementedError;

  @override
  final ImageClient client;

  _BaseImageSource(this.client);

  @override
  Future<void> populateCategories() => throw UnimplementedError;

  @override
  Future<String> getImageUrl(String category, {required bool isSfw}) => throw UnimplementedError;
}

mixin _SupportFetchingMultipleImages on _BaseImageSource {
  final _sfwResults = <String, ListQueue<String>>{};
  final _nsfwResults = <String, ListQueue<String>>{};

  Future<List<String>> _getImagesUrl(String category, {required bool isSfw}) => throw UnimplementedError;

  @override
  @nonVirtual
  Future<String> getImageUrl(String category, {required bool isSfw}) async {
    var fetchedResults = isSfw ? _sfwResults : _nsfwResults;
    if (fetchedResults[category] == null || fetchedResults[category]!.isEmpty) {
      fetchedResults[category] = ListQueue<String>();
      fetchedResults[category]!.addAll(await _getImagesUrl(category, isSfw: isSfw));
    }

    return fetchedResults[category]!.removeFirst();
  }
}

class WaifuPICS extends _BaseImageSource with _SupportFetchingMultipleImages {
  @override
  final baseUrl = "api.waifu.pics";

  WaifuPICS(ImageClient client) : super(client);

  @override
  Future<void> populateCategories() async {
    var response = await http.get(Uri.https(baseUrl, "/endpoints"));
    var data = jsonDecode(response.body);

    sfw.addAll(List<String>.from(data["sfw"]));
    nsfw.addAll(List<String>.from(data["nsfw"]));
  }

  @override
  Future<List<String>> _getImagesUrl(String category, {required bool isSfw}) async {
    var mode = sfwStateExpression(isSfw);
    var response = await http.post(
      Uri.https(baseUrl, "/many/$mode/$category"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({}),
    );
    var data = jsonDecode(response.body);

    return List<String>.from(data["files"]);
  }
}

class WaifuIM extends _BaseImageSource with _SupportFetchingMultipleImages {
  @override
  final baseUrl = "api.waifu.im";

  WaifuIM(ImageClient client) : super(client);

  @override
  Future<void> populateCategories() async {
    var response = await http.get(
      Uri.https(baseUrl, "/tags", {"full": "true"}),
      headers: {"Accept-Version": "v4"},
    );
    var data = jsonDecode(response.body);

    for (var tag in data["versatile"]) {
      sfw.add(tag["name"]);
      nsfw.add(tag["name"]);
    }

    for (var tag in data["nsfw"]) {
      nsfw.add(tag["name"]);
    }
  }

  @override
  Future<List<String>> _getImagesUrl(String category, {required bool isSfw}) async {
    var response = await http.get(
      Uri.https(
        baseUrl,
        "/search",
        {
          "included_tags": category,
          "is_nsfw": isSfw ? "false" : "true",
          "many": "true",
        },
      ),
      headers: {
        "Accept-Version": "v4",
      },
    );
    var data = jsonDecode(response.body);

    var results = <String>[];
    for (var result in data["images"]) {
      results.add(result["url"]);
    }

    return results;
  }
}

class AsunaGA extends _BaseImageSource {
  @override
  final baseUrl = "asuna.ga";

  final _urlMap = <String, Uri>{};

  AsunaGA(ImageClient client) : super(client);

  @override
  Future<void> populateCategories() async {
    final converter = <String, String>{"wholesome_foxes": "foxes"};

    var response = await http.get(Uri.https("asuna.ga", "/api"));
    var data = json.decode(response.body);
    for (var tag in data["allEndpoints"]) {
      var url = data["endpointInfo"][tag]["url"];
      tag = converter[tag] ?? tag;
      _urlMap[tag] = Uri.parse(url);

      sfw.add(tag);
    }
  }

  @override
  Future<String> getImageUrl(String category, {required bool isSfw}) async {
    var response = await http.get(_urlMap[category]!);
    var data = json.decode(response.body);
    return data["url"];
  }
}

List<ImageSource> constructSources(ImageClient client) {
  return <ImageSource>[
    WaifuPICS(client),
    WaifuIM(client),
    AsunaGA(client),
  ];
}
