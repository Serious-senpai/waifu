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

  /// The [Client] to perform HTTP requests
  abstract final Client client;

  /// Get all categories that this image source can provide.
  Future<void> populateCategories();

  /// Get the URL for an image
  Future<String> getImageUrl(String category, {required bool isSfw});

  /// Get the URL for an image
  Future<ImageData> fetchImage(String category, {required bool isSfw});
}

class WaifuPics implements ImageSource {
  @override
  final Set<String> sfw = <String>{};

  @override
  final Set<String> nsfw = <String>{};

  @override
  final String baseUrl = "api.waifu.pics";

  @override
  final Client client;

  WaifuPics(this.client);

  @override
  Future<void> populateCategories() async {
    var response = await client.get(Uri.https(baseUrl, "/endpoints"));
    var data = jsonDecode(response.body);

    sfw.addAll(List<String>.from(data["sfw"]));
    nsfw.addAll(List<String>.from(data["nsfw"]));
  }

  @override
  Future<String> getImageUrl(String category, {required bool isSfw}) async {
    var mode = sfwStateExpression(isSfw);
    var response = await client.get(Uri.https(baseUrl, "/$mode/$category"));
    var data = jsonDecode(response.body);

    return data["url"];
  }

  @override
  Future<ImageData> fetchImage(String category, {required bool isSfw}) async {
    var url = await getImageUrl(category, isSfw: isSfw);
    var response = await client.get(Uri.parse(url));
    return ImageData(url, category, isSfw, response.bodyBytes);
  }
}

class WaifuIm implements ImageSource {
  @override
  final Set<String> sfw = <String>{};

  @override
  final Set<String> nsfw = <String>{};

  @override
  final String baseUrl = "api.waifu.im";

  @override
  final Client client;

  WaifuIm(this.client);

  @override
  Future<void> populateCategories() async {
    var response = await client.get(
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
    var response = await client.get(
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

  @override
  Future<ImageData> fetchImage(String category, {required bool isSfw}) async {
    var url = await getImageUrl(category, isSfw: isSfw);
    var response = await client.get(Uri.parse(url));
    return ImageData(url, category, isSfw, response.bodyBytes);
  }
}

List<ImageSource> constructSources(Client client) {
  return <ImageSource>[WaifuPics(client), WaifuIm(client)];
}
