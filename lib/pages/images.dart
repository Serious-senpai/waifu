import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:permission_handler/permission_handler.dart";

import "../core/client.dart";
import "../core/utils.dart";

class ImagesPage extends StatefulWidget {
  final ImageClient client;

  const ImagesPage({Key? key, required this.client}) : super(key: key);

  @override
  State<ImagesPage> createState() => _ImagesPageState();
}

class _ImagesPageState extends State<ImagesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  ImageClient get client => widget.client;
  SingleImageProcessor get singleProcessor => widget.client.singleProcessor;
  MultipleImagesProcessor get multiProcessor => widget.client.multiProcessor;

  bool _buttonsExpanded = false;
  bool _displayMultipleImages = false;

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
        singleProcessor.resetProgress(forced: true);
        multiProcessor.clearProcess();
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
              ExpansionTile(
                title: const Text("Settings"),
                children: [
                  SwitchListTile(
                    title: const Text("Display multiple images"),
                    value: _displayMultipleImages,
                    onChanged: (newValue) {
                      closeDrawer();
                      setState(
                        () {
                          multiProcessor.clearProcess();
                          _displayMultipleImages = newValue;
                        },
                      );
                    },
                  ),
                  ListTile(
                    title: const Text("Edit images cache size"),
                    onTap: () async {
                      var controller = TextEditingController(text: client.history.maxSize.toString());
                      var value = await showDialog<int>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Maximum cached images"),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration.collapsed(hintText: "Cache size"),
                            keyboardType: TextInputType.number,
                            showCursor: true,
                            enableSuggestions: false,
                            maxLength: 2,
                            maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                if (controller.text.isNotEmpty) {
                                  Navigator.pop(context, int.parse(controller.text));
                                }
                              },
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );

                      if (value != null) {
                        client.history.maxSize = value;
                        await Fluttertoast.showToast(msg: "Changed cache size to $value");
                      }
                    },
                  )
                ],
              ),
              ListTile(
                title: const Text("Recent images"),
                onTap: () => Navigator.pushReplacementNamed(context, "/recent-images"),
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
      if (!_displayMultipleImages) {
        // Displaying single image
        if (singleProcessor.currentImage != null) {
          // Mustn't store singleProcessor.currentImage in a variable
          buttons.addAll(
            [
              FloatingActionButton(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Image URL"),
                      content: Text(singleProcessor.currentImage!.url),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("OK"),
                        ),
                        TextButton(
                          onPressed: () async {
                            Clipboard.setData(ClipboardData(text: singleProcessor.currentImage!.url));
                            await Fluttertoast.showToast(msg: "Copied to clipboard");
                          },
                          child: const Text("Copy"),
                        ),
                        TextButton(
                            onPressed: () async {
                              await launch(Uri.parse(singleProcessor.currentImage!.url));
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
                        "url": singleProcessor.currentImage!.url,
                      },
                    ),
                  );
                },
                tooltip: "Search on saucenao.com",
                heroTag: null,
                child: const Icon(Icons.search_outlined),
              ),
              seperator,
              FloatingActionButton(
                onPressed: () async {
                  var result = await singleProcessor.saveCurrentImage();
                  if (result) {
                    await Fluttertoast.showToast(msg: "Saved image!");
                  } else {
                    var request = await Permission.storage.request();
                    if (request.isGranted) {
                      result = await singleProcessor.saveCurrentImage();
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
                  singleProcessor.resetProgress();
                }),
                tooltip: "Find another image",
                heroTag: null,
                child: const Icon(Icons.refresh),
              ),
              seperator,
            ],
          );
        }
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

  Widget buildMultipleImages() {
    Widget buildImage(int index) {
      while (index >= multiProcessor.inProgress.length) {
        multiProcessor.addProcess();
      }

      var process = multiProcessor.inProgress[index];
      return GestureDetector(
        onTap: () async {
          if (process.isCompleted) {
            var result = await process.future;
            singleProcessor.resetProgress(forced: true, customData: result);
            setState(() => _displayMultipleImages = false);
          }
        },
        child: FutureBuilder(
          future: process.future,
          builder: (context, snapshot) {
            var edge = MediaQuery.of(context).size.width / 2;
            if (snapshot.connectionState == ConnectionState.done) {
              return Image.memory(
                snapshot.data!.data,
                width: edge,
                height: edge,
                fit: BoxFit.cover,
              );
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                width: edge,
                height: edge,
                child: loadingIndicator(
                  content: "Loading image",
                  size: edge / 4,
                ),
              );
            } else {
              return SizedBox(
                width: edge,
                height: edge,
                child: errorIndicator(
                  content: "Invalid state: ${snapshot.connectionState}",
                  size: edge / 4,
                ),
              );
            }
          },
        ),
      );
    }

    assert(_displayMultipleImages);
    return ListView.builder(
      itemBuilder: (context, index) => Row(
        children: [buildImage(2 * index), buildImage(2 * index + 1)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var scaffold = Scaffold(
      key: _scaffoldKey,
      drawer: createDrawer(),
      body: _displayMultipleImages
          ? buildMultipleImages()
          : Center(
              child: FutureBuilder(
                future: singleProcessor.inProgress.future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Image.memory(snapshot.data!.data);
                  } else if (snapshot.connectionState == ConnectionState.waiting) {
                    return loadingIndicator(content: "Loading image");
                  } else {
                    return errorIndicator(content: "Invalid state: ${snapshot.connectionState}");
                  }
                },
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
