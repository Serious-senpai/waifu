import "package:flutter/material.dart";

import "../core/client.dart";
import "../core/sources.dart";

class RecentImagesPage extends StatefulWidget {
  final ImageClient client;

  const RecentImagesPage({Key? key, required this.client}) : super(key: key);

  @override
  State<RecentImagesPage> createState() => _RecentImagesPageState();
}

GestureDetector createRedirectImage(BuildContext context, ImageClient client, ImageData image, double edge) {
  return GestureDetector(
    onTap: () {
      client.singleProcessor.resetProgress(forced: true, customData: image);
      Navigator.pushNamed(context, "/");
    },
    child: Image.memory(image.data, width: edge, height: edge, fit: BoxFit.cover),
  );
}

class _RecentImagesPageState extends State<RecentImagesPage> {
  ImageClient get client => widget.client;

  @override
  Widget build(BuildContext context) {
    var history = List<ImageData>.from(client.history.values);
    var edge = MediaQuery.of(context).size.width / 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recent images"),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        itemCount: (history.length / 2).ceil(),
        itemBuilder: (context, index) {
          var children = <Widget>[createRedirectImage(context, client, history[2 * index], edge)];
          if (2 * index + 1 < history.length) {
            children.add(createRedirectImage(context, client, history[2 * index + 1], edge));
          }

          return Row(children: children);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, "/");
        },
        tooltip: "Back",
        heroTag: null,
        child: const Icon(Icons.home),
      ),
    );
  }
}
