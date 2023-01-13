import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:permission_handler/permission_handler.dart";

import "client.dart";
import "utils.dart";

class ImagesPage extends StatefulWidget {
  final ImageClient client;

  const ImagesPage({Key? key, required this.client}) : super(key: key);

  @override
  State<ImagesPage> createState() => _ImagesPageState();
}

class _ImagesPageState extends State<ImagesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  ImageClient get client => widget.client;
  ImageFetchingProcessor get processor => widget.client.processor;

  bool _buttonsExpanded = false;

  void openDrawer() => _scaffoldKey.currentState!.openDrawer();
  void closeDrawer() => _scaffoldKey.currentState!.closeDrawer();

  /// Create the [Drawer] for the [Scaffold]
  Drawer createDrawer() {
    var sfwTiles = <ListTile>[], nsfwTiles = <ListTile>[];

    var sfwCategories = List<String>.from(client.sfw.keys), nsfwCategories = List<String>.from(client.nsfw.keys);
    sfwCategories.sort();
    nsfwCategories.sort();

    void Function() createSetStateFunction(String imageCategory, bool isSfw) {
      return () {
        client.category = imageCategory;
        client.isSfw = isSfw;

        closeDrawer();
        processor.resetProgress(forced: true);
      };
    }

    for (var category in sfwCategories) {
      var tile = ListTile(
        title: Text(category),
        onTap: () => setState(createSetStateFunction(category, true)),
      );
      sfwTiles.add(tile);
    }

    for (var category in nsfwCategories) {
      var tile = ListTile(
        title: Text(category),
        onTap: () => setState(createSetStateFunction(category, false)),
      );
      nsfwTiles.add(tile);
    }

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Text("Current mode: ${client.describeMode}"),
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
      if (client.lastImage != null) {
        buttons.addAll(
          [
            FloatingActionButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (BuildContext ctx) => AlertDialog(
                    title: const Text("Image URL"),
                    content: Text(client.lastImage!.url),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("OK"),
                      ),
                      TextButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: client.lastImage!.url));
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
              await requestPermission(Permission.storage);
              var result = await client.saveCurrentImage();
              await Fluttertoast.showToast(msg: result ? "Saved image!" : "Unable to save this image!");
            },
            tooltip: "Save image",
            heroTag: null,
            child: const Icon(Icons.download),
          ),
          seperator,
          FloatingActionButton(
            onPressed: () => setState(() {
              processor.resetProgress();
            }),
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
          future: processor.inProgress.future,
          builder: processor.transform,
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
