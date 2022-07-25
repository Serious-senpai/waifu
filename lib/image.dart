import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "package:fluttertoast/fluttertoast.dart";

import "client.dart";
import "widgets.dart";

class ImagePage extends StatefulWidget {
  final ImageClient client;
  const ImagePage({required this.client, Key? key}) : super(key: key);

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  /// The [GlobalKey] to open/close the drawer
  final _drawerKey = GlobalKey<ScaffoldState>(debugLabel: "_drawerKey");

  /// Will be filled in [loadCategories]
  final sfwTiles = <ListTile>[];

  /// Will be filled in [loadCategories]
  final nsfwTiles = <ListTile>[];

  /// Will be initialized in [initState]
  late Future<Drawer?> _drawerFuture;

  /// The underlying [ImageClient]
  ImageClient get client => widget.client;

  /// UI flag for buttons array
  bool _buttonExpanded = false;

  /// Process the future [snapshot] and turn it into a [Widget]
  Widget processImageFuture(BuildContext ctx, AsyncSnapshot snapshot) {
    if (snapshot.connectionState == ConnectionState.done) {
      return snapshot.hasData ? Image.memory(snapshot.data.data) : errorIndicator(content: "Cannot load this image!");
    } else if (snapshot.connectionState == ConnectionState.waiting) {
      return loadingIndicator(content: "Loading image");
    } else {
      return errorIndicator(content: "Invalid state: ${snapshot.connectionState}");
    }
  }

  /// Save the current image
  Future<void> saveCurrentImage() async {
    var result = await client.saveCurrentImage();
    await Fluttertoast.showToast(msg: result ? "Saved image!" : "Unable to save this image!");
  }

  /// Reset the drawer future [_drawerFuture]
  void resetDrawer() {
    _drawerFuture = createDrawer();
  }

  /// Load all image categories and place it in the drawer.
  Future<void> loadCategories() async {
    await client.waitUntilReady();

    var sfwCategories = List<String>.from(client.sfw);
    var nsfwCategories = List<String>.from(client.nsfw);

    void Function() createSetStateFunction(ImageMode mode, String category) {
      return () {
        client.mode = mode;
        client.category = category;
        Navigator.pop(context);
        client.resetFuture();
        resetDrawer();
      };
    }

    for (var category in sfwCategories) {
      var tile = ListTile(
        title: Text(category),
        onTap: () {
          setState(
            createSetStateFunction(
              ImageMode.sfw,
              category,
            ),
          );
        },
      );
      sfwTiles.add(tile);
    }

    for (var category in nsfwCategories) {
      var tile = ListTile(
        title: Text(category),
        onTap: () {
          setState(
            createSetStateFunction(
              ImageMode.nsfw,
              category,
            ),
          );
        },
      );
      nsfwTiles.add(tile);
    }
  }

  /// Create the drawer.
  Future<Drawer> createDrawer() async {
    if (sfwTiles.isEmpty && nsfwTiles.isEmpty) {
      await loadCategories();
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
            title: const Text("Random SFW"),
            onTap: () {
              setState(
                () {
                  client.mode = ImageMode.random;
                  Navigator.pop(context);
                  client.resetFuture();
                  resetDrawer();
                },
              );
            },
          ),
          ListTile(
            title: const Text("SFW images collection"),
            onTap: () => Navigator.pushNamed(context, "/collection"),
          ),
          ListTile(
            title: const Text("Recent images"),
            onTap: () => Navigator.pushNamed(context, "/recent_images"),
          )
        ],
      ),
    );
  }

  /// Create an array of [FloatingActionButton]
  List<Widget> createButtonArray() {
    List<Widget> buttons = [];
    if (_buttonExpanded) {
      if (client.currentImage != null) {
        buttons.addAll(
          [
            FloatingActionButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (BuildContext ctx) => AlertDialog(
                    title: const Text("Image URL"),
                    content: Text(client.currentImage!.url),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("OK"),
                      ),
                      TextButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: client.currentImage!.url));
                          Fluttertoast.showToast(msg: "Copied to clipboard");
                        },
                        child: const Text("Copy"),
                      ),
                    ],
                  ),
                );
              },
              child: const Icon(Icons.info),
              tooltip: "Show source",
              heroTag: null,
            ),
            seperator,
          ],
        );
      }
      buttons.addAll(
        [
          FloatingActionButton(
            onPressed: () => _drawerKey.currentState?.openDrawer(),
            child: const Icon(Icons.list),
            tooltip: "Open menu",
            heroTag: null,
          ),
          seperator,
          FloatingActionButton(
            onPressed: saveCurrentImage,
            child: const Icon(Icons.download),
            tooltip: "Save image",
            heroTag: null,
          ),
          seperator,
          FloatingActionButton(
            onPressed: () => setState(client.resetFuture),
            child: const Icon(Icons.refresh),
            tooltip: "Find another image",
            heroTag: null,
          ),
          seperator,
          FloatingActionButton(
            onPressed: () => setState(() => _buttonExpanded = false),
            child: const Icon(Icons.expand_more),
            heroTag: null,
          ),
        ],
      );
    } else {
      buttons = [
        FloatingActionButton(
          onPressed: () => setState(() => _buttonExpanded = true),
          child: const Icon(Icons.expand_less),
          heroTag: null,
        ),
      ];
    }
    return buttons;
  }

  /// Process the [_drawerFuture] and turn it into a [Drawer]
  Drawer processDrawerFuture(BuildContext ctx, AsyncSnapshot snapshot) {
    return snapshot.hasData
        ? snapshot.data
        : Drawer(
            child: Column(
              children: [
                seperator,
                seperator,
                loadingIndicator(size: 30),
              ],
            ),
          );
  }

  @override
  void initState() {
    resetDrawer();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var scaffold = Scaffold(
      key: _drawerKey,
      drawer: FutureBuilder(
        future: _drawerFuture,
        builder: processDrawerFuture,
      ),
      body: Center(
        child: FutureBuilder(
          future: client.future,
          builder: processImageFuture,
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: createButtonArray(),
      ),
    );

    return WillPopScope(
      child: scaffold,
      onWillPop: () async => false,
    );
  }
}
