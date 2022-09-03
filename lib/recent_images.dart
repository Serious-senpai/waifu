import "package:flutter/material.dart";

import "client.dart";

class RecentImagesPage extends StatefulWidget {
  final ImageClient client;
  final ImageCategory category;

  const RecentImagesPage({Key? key, required this.client, required this.category}) : super(key: key);

  @override
  State<RecentImagesPage> createState() => _RecentImagesPageState();
}

class _RecentImagesPageState extends State<RecentImagesPage> {
  ImageClient get client => widget.client;
  ImageCategory get category => widget.category;

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[];

    for (var imageData in client.history.values) {
      children.add(
        ListTile(
          title: Image.memory(imageData),
          onTap: () {
            category.inProgress = Future.value(imageData);
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
        tooltip: "Back",
        heroTag: null,
        child: const Icon(Icons.home),
      ),
    );
  }
}
