import "package:flutter/material.dart";

import "client.dart";

class RecentImagesPage extends StatefulWidget {
  final ImageClient client;
  const RecentImagesPage({required this.client, Key? key}) : super(key: key);

  @override
  State<RecentImagesPage> createState() => _RecentImagesPageState();
}

class _RecentImagesPageState extends State<RecentImagesPage> {
  ImageClient get client => widget.client;

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[];

    for (var imageData in client.imageDataCache.values) {
      children.add(
        ListTile(
          title: Image.memory(imageData),
          onTap: () {
            client.future = Future.value(imageData);
            Navigator.pushNamed(context, "/");
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recent images"),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, "/");
        },
        child: const Icon(Icons.home),
        tooltip: "Back",
        heroTag: null,
      ),
    );
  }
}
