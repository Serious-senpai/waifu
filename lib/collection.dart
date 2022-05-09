import "package:flutter/material.dart";

import "client.dart";
import "widgets.dart";

const imagesLimit = 12;

class CollectionPage extends StatefulWidget {
  final ImageClient client;
  const CollectionPage({required this.client, Key? key}) : super(key: key);

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  ImageClient get client => widget.client;

  final _futureList = <ImageFuture>[];

  bool _allFutureCompleted = true;

  void rebuildSelf() => setState(() {});

  void resetFutures() {
    if (!_allFutureCompleted) return;

    _futureList.clear();
    _allFutureCompleted = false;
    for (int i = 0; i < imagesLimit; i++) {
      var future = client.getFromCollection();
      future.whenComplete(rebuildSelf);
      _futureList.add(future);
    }
    Future.wait(_futureList).whenComplete(() => _allFutureCompleted = true);
  }

  @override
  void initState() {
    resetFutures();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    client.mode = ImageMode.random;
    var children = <Widget>[];

    Widget futureBuilder(BuildContext context, AsyncSnapshot snapshot) {
      var edge = MediaQuery.of(context).size.width / 2;
      if (snapshot.connectionState == ConnectionState.done) {
        return snapshot.hasData
            ? Image.memory(
                snapshot.data,
                width: edge,
                height: edge,
                fit: BoxFit.cover,
              )
            : errorIndicator(
                width: edge,
                height: edge,
              );
      } else if (snapshot.connectionState == ConnectionState.waiting) {
        return loadingIndicator(
          width: edge,
          height: edge,
          scale: 0.3,
        );
      } else {
        return errorIndicator(
          content: snapshot.connectionState.toString(),
          width: edge,
          height: edge,
        );
      }
    }

    for (var future in _futureList) {
      children.add(
        GestureDetector(
          child: FutureBuilder(
            future: future,
            builder: futureBuilder,
          ),
          onTap: () {
            client.future = future;
            Navigator.pushNamed(context, "/");
          },
        ),
      );
    }

    var rows = <Widget>[];
    for (int i = 0; i < children.length; i += 2) {
      var first = children[i];
      var second = children[i + 1];
      rows.add(Row(children: [first, second]));
    }

    var counter = 0;
    var scaffold = Scaffold(
      body: NotificationListener<ScrollEndNotification>(
        child: ListView(children: rows),
        onNotification: (notification) {
          var metrics = notification.metrics;
          if (metrics.maxScrollExtent > 0) {
            if (metrics.pixels == metrics.minScrollExtent) {
              counter--;
              client.backwardCollectionPointer(imagesLimit);
            } else if (metrics.pixels == metrics.maxScrollExtent) {
              counter++;
            }

            if (counter.abs() > 1) {
              resetFutures();
            }
          }
          return true;
        },
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

    return WillPopScope(
      child: scaffold,
      onWillPop: () async => false,
    );
  }
}
