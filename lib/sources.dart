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

    var sfwCategories = List<String>.from(data["sfw"]), nsfwCategories = List<String>.from(data["nsfw"]);
    sfw.addAll(sfwCategories);
    nsfw.addAll(nsfwCategories);
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
    var response = await client.get(Uri.https(baseUrl, "/tags", {"full": "true"}));
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
  Future<String> getImageUrl(String category, {required String mode, required Client client}) async {
    var response = await client.get(
      Uri.https(
        baseUrl,
        "/search",
        {
          "included_tags": category,
          "is_nsfw": mode == "nsfw" ? "true" : "false",
        },
      ),
    );
    var data = jsonDecode(response.body);

    return data["images"][0]["url"];
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
