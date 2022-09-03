import "dart:convert";

import "package:http/http.dart";

abstract class ImageSource {
  /// The SFW categories that this source can handle
  abstract final Set<String> sfw;

  /// The NSFW categories that this source can handle
  abstract final Set<String> nsfw;

  /// Base URL for the API
  abstract final String baseUrl;

  /// Get all categories that this image source can provide.
  Future<void> populateCategories(Client client);

  /// Get the URL for an image
  Future<String> getImageUrl(String category, {required String mode, required Client client});
}

class WaifuPics implements ImageSource {
  @override
  final Set<String> sfw = <String>{};

  @override
  final Set<String> nsfw = <String>{};

  @override
  final String baseUrl = "api.waifu.pics";

  @override
  Future<void> populateCategories(Client client) async {
    var response = await client.get(Uri.https(baseUrl, "/endpoints"));
    var data = jsonDecode(response.body);

    sfw.addAll(data["sfw"]);
    nsfw.addAll(data["nsfw"]);
  }

  @override
  Future<String> getImageUrl(String category, {required String mode, required Client client}) async {
    var response = await client.get(Uri.https(baseUrl, "/$mode/$category"));
    var data = jsonDecode(response.body);

    return data["url"];
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
  Future<void> populateCategories(Client client) async {
    var response = await client.get(Uri.https(baseUrl, "/endpoints"));
    var data = jsonDecode(response.body);

    sfw.addAll(data["versatile"]);
    nsfw.addAll(data["versatile"]);
    nsfw.addAll(data["nsfw"]);
  }

  @override
  Future<String> getImageUrl(String category, {required String mode, required Client client}) async {
    var response = await client.get(
      Uri.https(
        baseUrl,
        "/random",
        {
          "selected_tags": category,
          "is_nsfw": mode == "nsfw",
        },
      ),
    );
    var data = jsonDecode(response.body);

    return data["url"];
  }
}

Future<void> populateSources(Client client) async {
  for (var imageSource in imageSources) {
    await imageSource.populateCategories(client);
  }
}

var imageSources = <ImageSource>[
  WaifuPics(),
  WaifuIm(),
];
