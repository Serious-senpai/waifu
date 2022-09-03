import "dart:io";

import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "client.dart";
import "images.dart";
import "recent_images.dart";

Future<void> main() async {
  try {
    var client = ImageClient();
    await client.prepare();

    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setSystemUIChangeCallback(
      (systemOverlaysAreVisible) async {
        await Future.delayed(const Duration(seconds: 3));
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      },
    );

    runApp(MainApp(client: client));
  } on SocketException {
    runApp(
      const Scaffold(
        body: Center(
          child: Text("Please check your Internet connection and try again"),
        ),
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  final ImageClient client;
  final ImageCategory category;

  MainApp({Key? key, required this.client})
      : category = ImageCategory(client),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    category.resetFuture();

    return MaterialApp(
      title: "Waifu Generator",
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
      ),
      themeMode: ThemeMode.dark,
      routes: {
        "/": (context) => ImagesPage(client: client, category: category),
        "/recent-images": (context) => RecentImagesPage(client: client, category: category),
      },
    );
  }
}
