import "package:flutter/material.dart";

import "client.dart";
import "sources.dart";

class RecentImagesPage extends StatefulWidget {
  final ImageClient client;

  const RecentImagesPage({Key? key, required this.client}) : super(key: key);

  @override
  State<RecentImagesPage> createState() => _RecentImagesPageState();
}

class _RecentImagesPageState extends State<RecentImagesPage> {
  ImageClient get client => widget.client;

  @override
  Widget build(BuildContext context) {
    var history = List<ImageData>.from(client.history.values);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recent images"),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) => ListTile(
          title: Image.memory(history[index].data),
          onTap: () {
            client.processor.resetProgress(forced: true, customData: history[index]);
            Navigator.pushNamed(context, "/");
          },
        ),
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
