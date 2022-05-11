import "dart:io";

import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "client.dart";
import "collection.dart";
import "image.dart";
import "recent_images.dart";
import "socket_error_app.dart";

void main() async {
  try {
    var client = await ImageClient.create();
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setSystemUIChangeCallback(
      (systemOverlaysAreVisible) async {
        await Future.delayed(const Duration(seconds: 3));
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      },
    );

    runApp(MainApp(client: client));
  } on SocketException catch (exception) {
    runApp(SocketExceptionApp(exception: exception));
  }
}

class MainApp extends StatelessWidget {
  final ImageClient client;

  const MainApp({
    Key? key,
    required this.client,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Waifu Generator",
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
      ),
      themeMode: ThemeMode.dark,
      routes: {
        "/": (context) => ImagePage(client: client),
        "/recent_images": (context) => RecentImagesPage(client: client),
        "/collection": (context) => CollectionPage(client: client),
      },
    );
  }
}
