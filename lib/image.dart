import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:fluttertoast/fluttertoast.dart";

import "client.dart";

class ImagePage extends StatefulWidget {
  final ImageClient client;
  const ImagePage({required this.client, Key? key}) : super(key: key);

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  /// A transparent [SizedBox] with height of 10.0
  final seperator = const SizedBox(height: 10.0);

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

  /// Display a loading indicator above [content]
  Widget loadingIndicator(String content) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(),
        ),
        seperator,
        Text(content),
      ],
    );
  }

  /// Display an error indicator with error message [content]
  Widget errorIndicator(String content) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 60,
          height: 60,
          child: Icon(Icons.highlight_off, size: 60),
        ),
        seperator,
        Text(content),
      ],
    );
  }

  /// Process the future [snapshot] and turn it into a [Widget]
  Widget processImageFuture(BuildContext ctx, AsyncSnapshot snapshot) {
    if (snapshot.connectionState == ConnectionState.done) {
      return snapshot.hasData ? Image.memory(snapshot.data) : errorIndicator("Cannot load this image!");
    } else if (snapshot.connectionState == ConnectionState.waiting) {
      return loadingIndicator("Loading image");
    } else {
      return errorIndicator("Invalid state: ${snapshot.connectionState}");
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
              ImageMode.sfw,
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
            title: const Text("Recent images"),
            onTap: () => Navigator.pushNamed(context, "/recent_images"),
          )
        ],
      ),
    );
  }

  /// Create an array of [FloatingActionButton]
  List<Widget> createButtonArray() {
    List<Widget> buttons;
    if (_buttonExpanded) {
      buttons = [
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
      ];
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
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(),
                ),
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
