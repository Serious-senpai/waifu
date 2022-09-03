import "dart:typed_data";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:fluttertoast/fluttertoast.dart";

import "client.dart";
import "utils.dart";

class ImagesPage extends StatefulWidget {
  final ImageClient client;
  final ImageCategory category;

  const ImagesPage({Key? key, required this.client, required this.category}) : super(key: key);

  @override
  State<ImagesPage> createState() => _ImagesPageState();
}

class _ImagesPageState extends State<ImagesPage> {
  ImageClient get client => widget.client;
  ImageCategory get category => widget.category;

  bool _buttonsExpanded = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  /// Process the future [snapshot] and turn it into a [Widget]
  Widget processImageFuture(BuildContext ctx, AsyncSnapshot<Uint8List> snapshot) {
    if (snapshot.connectionState == ConnectionState.done) {
      return Image.memory(snapshot.data!);
    } else if (snapshot.connectionState == ConnectionState.waiting) {
      return loadingIndicator(content: "Loading image");
    } else {
      return errorIndicator(content: "Invalid state: ${snapshot.connectionState}");
    }
  }

  void openDrawer() => _scaffoldKey.currentState!.openDrawer();
  void closeDrawer() => _scaffoldKey.currentState!.closeDrawer();

  /// Create the [Drawer] for the [Scaffold]
  Drawer createDrawer() {
    var sfwTiles = <ListTile>[], nsfwTiles = <ListTile>[];

    var sfwCategories = List<String>.from(client.sfw.keys), nsfwCategories = List<String>.from(client.nsfw.keys);
    sfwCategories.sort();
    nsfwCategories.sort();

    void Function() createSetStateFunction(String imageMode, String imageCategory) {
      return () {
        category.category = imageCategory;
        category.mode = imageMode;

        closeDrawer();
        category.resetFuture();
      };
    }

    for (var category in sfwCategories) {
      var tile = ListTile(
        title: Text(category),
        onTap: () => setState(createSetStateFunction("sfw", category)),
      );
      sfwTiles.add(tile);
    }

    for (var category in nsfwCategories) {
      var tile = ListTile(
        title: Text(category),
        onTap: () => setState(createSetStateFunction("nsfw", category)),
      );
      nsfwTiles.add(tile);
    }

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Text("Current mode: ${category.describeMode}"),
          ),
          ExpansionTile(
            title: const Text("SFW"),
            children: sfwTiles,
          ),
          ExpansionTile(
            title: const Text("NSFW"),
            children: nsfwTiles,
          ),
          ListTile(
            title: const Text("Recent images"),
            onTap: () => Navigator.pushNamed(context, "/recent-images"),
          )
        ],
      ),
    );
  }

  /// Create an array of [FloatingActionButton]
  List<Widget> createButtonArray(BuildContext context) {
    List<Widget> buttons = [];
    if (_buttonsExpanded) {
      // Add the "info" button
      if (client.currentUrl != null) {
        var currentUrl = client.currentUrl!;
        buttons.addAll(
          [
            FloatingActionButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (BuildContext ctx) => AlertDialog(
                    title: const Text("Image URL"),
                    content: Text(currentUrl),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("OK"),
                      ),
                      TextButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: currentUrl));
                          Fluttertoast.showToast(msg: "Copied to clipboard");
                        },
                        child: const Text("Copy"),
                      ),
                    ],
                  ),
                );
              },
              tooltip: "Show source",
              heroTag: null,
              child: const Icon(Icons.info),
            ),
            seperator,
          ],
        );
      }

      buttons.addAll(
        [
          FloatingActionButton(
            onPressed: openDrawer,
            tooltip: "Open menu",
            heroTag: null,
            child: const Icon(Icons.list),
          ),
          seperator,
          FloatingActionButton(
            onPressed: () async {
              var result = await client.saveCurrentImage();
              await Fluttertoast.showToast(msg: result ? "Saved image!" : "Unable to save this image!");
            },
            tooltip: "Save image",
            heroTag: null,
            child: const Icon(Icons.download),
          ),
          seperator,
          FloatingActionButton(
            onPressed: () => setState(category.resetFuture),
            tooltip: "Find another image",
            heroTag: null,
            child: const Icon(Icons.refresh),
          ),
          seperator,
          FloatingActionButton(
            onPressed: () => setState(() => _buttonsExpanded = false),
            heroTag: null,
            child: const Icon(Icons.expand_more),
          ),
        ],
      );
    } else {
      buttons = [
        FloatingActionButton(
          onPressed: () => setState(() => _buttonsExpanded = true),
          heroTag: null,
          child: const Icon(Icons.expand_less),
        ),
      ];
    }
    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    var scaffold = Scaffold(
      key: _scaffoldKey,
      drawer: createDrawer(),
      body: Center(
        child: FutureBuilder(
          future: category.inProgress,
          builder: processImageFuture,
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: createButtonArray(context),
      ),
    );

    return WillPopScope(
      child: scaffold,
      onWillPop: () async => false,
    );
  }
}
