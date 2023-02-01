import "dart:convert";
import "dart:typed_data";

import "package:http/http.dart";

import "client.dart";

class ImageData {
  final String url;
  final String category;
  final bool isSfw;
  final Uint8List data;

  ImageData(this.url, this.category, this.isSfw, this.data);

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

class WaifuPICS extends _BaseImageSource {
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
  Future<String> getImageUrl(String category, {required bool isSfw}) async {
    var mode = sfwStateExpression(isSfw);
    var response = await http.get(Uri.https(baseUrl, "/$mode/$category"));
    var data = jsonDecode(response.body);

    return data["url"];
  }
}

class WaifuIM extends _BaseImageSource {
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
  Future<String> getImageUrl(String category, {required bool isSfw}) async {
    var response = await http.get(
      Uri.https(
        baseUrl,
        "/search",
        {
          "included_tags": category,
          "is_nsfw": isSfw ? "false" : "true",
        },
      ),
      headers: {
        "Accept-Version": "v4",
      },
    );
    var data = jsonDecode(response.body);

    return data["images"][0]["url"];
  }
}

class AsunaGA extends _BaseImageSource {
  @override
  final baseUrl = "asuna.ga";

  final _urlMap = <String, String>{};

  AsunaGA(ImageClient client) : super(client);

  @override
  Future<void> populateCategories() async {
    final converter = <String, String>{"wholesome_foxes": "foxes"};

    var response = await http.get(Uri.https("asuna.ga", "/api"));
    var data = json.decode(response.body);
    for (var tag in data["allEndpoints"]) {
      var url = data["endpointInfo"][tag]["url"];
      tag = converter[tag] ?? tag;
      _urlMap[tag] = url;

      sfw.add(tag);
    }
  }

  @override
  Future<String> getImageUrl(String category, {required bool isSfw}) async {
    var response = await http.get(Uri.parse(_urlMap[category]!));
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
