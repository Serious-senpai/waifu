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
  /// The underlying [ImageClient]
  ImageClient get client => widget.client;

  /// Futures which are used to fetch images
  final _futureList = <ImageFuture>[];

  /// Rebuild this widget
  void rebuildSelf() => setState(() {});

  /// UI flag for buttons array
  bool _buttonExpanded = false;

  /// Reset all futures
  void resetFutures() {
    _futureList.clear();
    for (int i = 0; i < imagesLimit; i++) {
      var future = client.getFromCollection();
      future.whenComplete(rebuildSelf);
      _futureList.add(future);
    }
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
            : SizedBox(
                child: errorIndicator(size: 20),
                width: edge,
                height: edge,
              );
      } else if (snapshot.connectionState == ConnectionState.waiting) {
        return SizedBox(
          child: loadingIndicator(size: 20),
          width: edge,
          height: edge,
        );
      } else {
        return SizedBox(
          child: errorIndicator(
            content: snapshot.connectionState.toString(),
            size: 20,
          ),
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

    var scaffold = Scaffold(
      body: ListView(children: rows),
      floatingActionButton: _buttonExpanded
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    resetFutures();
                    rebuildSelf();
                  },
                  child: const Icon(
                    Icons.chevron_right,
                  ),
                  tooltip: "Next",
                  heroTag: null,
                ),
                seperator,
                FloatingActionButton(
                  onPressed: () {
                    client.backwardCollectionPointer(2 * imagesLimit);
                    resetFutures();
                    rebuildSelf();
                  },
                  child: const Icon(
                    Icons.chevron_left,
                  ),
                  tooltip: "Back",
                  heroTag: null,
                ),
                seperator,
                FloatingActionButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/");
                  },
                  child: const Icon(Icons.home),
                  tooltip: "Home",
                  heroTag: null,
                ),
                seperator,
                FloatingActionButton(
                  onPressed: () => setState(() => _buttonExpanded = false),
                  child: const Icon(Icons.expand_more),
                  heroTag: null,
                ),
              ],
            )
          : FloatingActionButton(
              onPressed: () => setState(() => _buttonExpanded = true),
              child: const Icon(Icons.expand_less),
              heroTag: null,
            ),
    );

    return WillPopScope(
      child: scaffold,
      onWillPop: () async => false,
    );
  }
}
