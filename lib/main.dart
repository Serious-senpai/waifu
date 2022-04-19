import "dart:async";

import "package:flutter/material.dart";

import "client.dart";
import "image.dart";
import "recent_images.dart";

void main() async {
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
        "/image": (context) => ImagePage(client: client),
        "/recent_images": (context) => RecentImagesPage(client: client),
      },
    );
  }
}
