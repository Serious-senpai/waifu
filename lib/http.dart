import "dart:convert";
import "dart:typed_data";

import "package:async_locks/async_locks.dart";
import "package:http/http.dart";

class HTTPException implements Exception {
  int statusCode;
  String response;

  HTTPException(Response response)
      : statusCode = response.statusCode,
        response = response.body;

  @override
  String toString() => "HTTPException ($statusCode): $response";
}

void raiseForStatus(Response response) {
  if (response.statusCode >= 400) throw HTTPException(response);
}

/// Low-level class for handling HTTP requests to the Haruka server
class HTTPClient {
  /// Default headers for making requests to web servers
  final _defaultHeaders = <String, String>{
    "Accept": "*/*",
    "Accept-Encoding": "gzip, deflate",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3725.4 Safari/537.36",
  };

  /// The underlying [Client]
  final Client _client;

  /// The Haruka server this client is currently connected to
  final String harukaHost;

  /// Haruka's current avatar
  late Uint8List avatar;

  /// Haruka's information
  late Map<String, dynamic> info;

  final _ready = Event();

  HTTPClient._(this._client, this.harukaHost);

  /// Create a new [HTTPClient] that connects to an appropriate [harukaHost]
  static Future<HTTPClient> create() async {
    var client = Client();
    var response = await client.get(Uri.https("haruka39.herokuapp.com", "/"));
    var harukaHost = response.statusCode == 200 ? "haruka39.herokuapp.com" : "haruka39-clone.herokuapp.com";

    var httpClient = HTTPClient._(client, harukaHost);
    return httpClient;
  }

  /// Whether this client is ready
  bool get ready => _ready.isSet;

  /// Asynchronously block until [ready] becomes `true`
  Future<void> waitUntilReady() async {
    await _ready.wait();
  }

  /// Make a HTTP request to the Haruka server
  Future<Response> harukaRequest(
    String method,
    String path, {
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    var uri = Uri.https(harukaHost, path, params);
    method = method.toUpperCase();
    switch (method) {
      case "DELETE":
        return _client.delete(uri, headers: headers, body: body, encoding: encoding);
      case "GET":
        return _client.get(uri, headers: headers);
      case "HEAD":
        return _client.head(uri, headers: headers);
      case "PATCH":
        return _client.patch(uri, headers: headers, body: body, encoding: encoding);
      case "POST":
        return _client.post(uri, headers: headers, body: body, encoding: encoding);
      case "PUT":
        return _client.put(uri, headers: headers, body: body, encoding: encoding);
    }
    throw ArgumentError("Unknown method $method");
  }

  /// Make a HTTP GET request by providing the default headers
  Future<Response> get(
    Uri url, {
    Map<String, dynamic>? params,
    Map<String, String>? headers,
  }) {
    var _headers = Map<String, String>.from(_defaultHeaders);
    if (headers != null) _headers.addAll(headers);
    return _client.get(url, headers: _headers);
  }
}
