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
      child: Stack(
        children: [
          ListView(
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
          Positioned(
            bottom: 5.0,
            left: 5.0,
            child: IconButton(
              iconSize: 15,
              onPressed: () => launch(Uri.https("github.com", "Serious-senpai/waifu")),
              icon: Image.asset("assets/github-mark-white.png"),
            ),
          ),
        ],
      ),
    );
  }

  /// Create an array of [FloatingActionButton]
  List<Widget> createButtonArray(BuildContext context) {
    List<Widget> buttons = [];
    if (_buttonsExpanded) {
      if (processor.currentImage != null) {
        // Mustn't store processor.currentImage in a variable
        buttons.addAll(
          [
            FloatingActionButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (BuildContext ctx) => AlertDialog(
                    title: const Text("Image URL"),
                    content: Text(processor.currentImage!.url),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("OK"),
                      ),
                      TextButton(
                        onPressed: () async {
                          Clipboard.setData(ClipboardData(text: processor.currentImage!.url));
                          await Fluttertoast.showToast(msg: "Copied to clipboard");
                        },
                        child: const Text("Copy"),
                      ),
                      TextButton(
                          onPressed: () async {
                            await launch(Uri.parse(processor.currentImage!.url));
                          },
                          child: const Text("Open")),
                    ],
                  ),
                );
              },
              tooltip: "Show source",
              heroTag: null,
              child: const Icon(Icons.info),
            ),
            seperator,
            FloatingActionButton(
              onPressed: () async {
                await launch(
                  Uri.https(
                    "saucenao.com",
                    "/search.php",
                    {
                      "url": processor.currentImage!.url,
                    },
                  ),
                );
              },
              tooltip: "Search on saucenao.com",
              heroTag: null,
              child: const Icon(Icons.search_outlined),
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
              var result = await processor.saveCurrentImage();
              if (result) {
                await Fluttertoast.showToast(msg: "Saved image!");
              } else {
                var request = await Permission.storage.request();
                if (request.isGranted) {
                  result = await processor.saveCurrentImage();
                  await Fluttertoast.showToast(msg: result ? "Saved image!" : "Unable to save this image!");
                } else {
                  await Fluttertoast.showToast(msg: "Missing permission");
                }
              }
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
