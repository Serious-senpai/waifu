import "package:flutter/material.dart";

import "../core/cache.dart";
import "../core/client.dart";
import "../core/sources.dart";
import "../core/utils.dart";

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
      Navigator.pushReplacementNamed(context, "/");
    },
    child: Image.memory(image.data, width: edge, height: edge, fit: BoxFit.cover),
  );
}

class _RecentImagesPageState extends State<RecentImagesPage> {
  ImageClient get client => widget.client;

  Widget buildHistoryImage(AsyncImageViewer historyView, int index) {
    return FutureBuilder(
      future: historyView.get(index),
      builder: (context, snapshot) {
        var edge = MediaQuery.of(context).size.width / 2;
        if (snapshot.connectionState == ConnectionState.done) {
          return createRedirectImage(context, client, snapshot.data!, edge);
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: edge,
            height: edge,
            child: loadingIndicator(
              content: "Loading image",
              size: edge / 4,
            ),
          );
        } else {
          return SizedBox(
            width: edge,
            height: edge,
            child: errorIndicator(
              content: "Invalid state: ${snapshot.connectionState}",
              size: edge / 4,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var historyView = client.history.view(client.fetchFromURL);

    var scaffold = Scaffold(
      appBar: AppBar(
        title: const Text("Recent images"),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        itemCount: (historyView.length / 2).ceil(),
        itemBuilder: (context, index) {
          var children = <Widget>[buildHistoryImage(historyView, 2 * index)];
          if (2 * index + 1 < historyView.length) {
            children.add(buildHistoryImage(historyView, 2 * index + 1));
          }

          return Row(children: children);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacementNamed(context, "/");
        },
        tooltip: "Back",
        heroTag: null,
        child: const Icon(Icons.home),
      ),
    );

    return WillPopScope(
      child: scaffold,
      onWillPop: () => Future.value(false),
    );
  }
}
