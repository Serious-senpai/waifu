import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "client.dart";
import "collection.dart";
import "image.dart";
import "recent_images.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  SystemChrome.setSystemUIChangeCallback(
    (systemOverlaysAreVisible) async {
      await Future.delayed(const Duration(seconds: 3));
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    },
  );

  var client = await ImageClient.create();
  runApp(MainApp(client: client));
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
      title: "Haruka Client",
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
