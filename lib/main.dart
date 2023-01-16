import "dart:io";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:fluttertoast/fluttertoast.dart";

import "core/client.dart";
import "pages/images.dart";
import "pages/recent_images.dart";

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setSystemUIChangeCallback(
      (systemOverlaysAreVisible) async {
        await Future.delayed(const Duration(seconds: 4));
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      },
    );

    var client = ImageClient();
    await client.prepare();

    runApp(MainApp(client: client));
  } on SocketException {
    await Fluttertoast.showToast(msg: "Please check your Internet connection and try again");
  }
}

class MainApp extends StatelessWidget {
  final ImageClient client;

  const MainApp({Key? key, required this.client}) : super(key: key);

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
        "/": (context) => ImagesPage(client: client),
        "/recent-images": (context) => RecentImagesPage(client: client),
      },
    );
  }
}
