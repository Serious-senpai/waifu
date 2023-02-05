import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:permission_handler/permission_handler.dart";

import "../core/client.dart";
import "../core/sources.dart";
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
                      var value = await showDialog<int?>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Maximum cached images"),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration.collapsed(hintText: "Cache size (1 - 200)"),
                            keyboardType: TextInputType.number,
                            showCursor: true,
                            enableSuggestions: false,
                            maxLength: 3,
                            maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                if (controller.text.isNotEmpty) {
                                  Navigator.pop(context, int.tryParse(controller.text));
                                }
                              },
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );

                      if (value != null) {
                        if (value < 0 || value > 200) {
                          await Fluttertoast.showToast(msg: "Invalid cache size");
                        } else {
                          client.history.maxSize = value;
                          await Fluttertoast.showToast(msg: "Changed cache size to $value");
                        }
                      }
                    },
                  ),
                  ListTile(
                    title: StreamBuilder(
                      stream: client.history.lengthInBytesStream,
                      builder: (_, __) {
                        return Text("Cache size: ${displayBytes(client.history.lengthInBytes)} (${client.history.lengthCached}/${client.history.maxSize})");
                      },
                    ),
                  ),
                ],
              ),
              ListTile(
                title: const Text("Recent images"),
                onTap: () {
                  client.http.cancelAll();
                  Navigator.pushReplacementNamed(context, "/recent-images");
                },
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

  /// Create an array of [FloatingActionButton] for single image mode
  List<Widget> createSingleImageButtonArray(BuildContext context, AsyncSnapshot<ImageData> snapshot) {
    List<Widget> buttons = [];
    if (_buttonsExpanded) {
      var data = snapshot.data;
      if (snapshot.connectionState == ConnectionState.done && data != null) {
        buttons.addAll(
          [
            FloatingActionButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Image URL"),
                    content: Text(data.url.toString()),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("OK"),
                      ),
                      TextButton(
                        onPressed: () async {
                          Clipboard.setData(ClipboardData(text: data.url.toString()));
                          await Fluttertoast.showToast(msg: "Copied to clipboard");
                        },
                        child: const Text("Copy"),
                      ),
                      TextButton(
                          onPressed: () async {
                            await launch(Uri.parse(data.url.toString()));
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
                  Uri.https("saucenao.com", "/search.php", {"url": data.url}),
                );
              },
              tooltip: "Search on saucenao.com",
              heroTag: null,
              child: const Icon(Icons.search_outlined),
            ),
            seperator,
            FloatingActionButton(
              onPressed: () async {
                var proceed = client.forceSaveImage
                    ? true
                    : await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          content: const Text("This image does not have the highest quality and you are "
                              "recommended to use the saucenao.com search function instead.\nDo you still "
                              "want to download this image?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Yes"),
                            ),
                            TextButton(
                              onPressed: () {
                                client.forceSaveImage = true;
                                Navigator.pop(context, true);
                              },
                              child: const Text("Yes, don't ask again"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("No"),
                            ),
                          ],
                        ),
                      );

                if (proceed == true) {
                  await Fluttertoast.showToast(msg: "Saving image...");
                  var result = await client.saveImage(data.url);
                  if (result) {
                    await Fluttertoast.showToast(msg: "Saved image!");
                  } else {
                    var request = await Permission.storage.request();
                    if (request.isGranted) {
                      result = await client.saveImage(data.url);
                      await Fluttertoast.showToast(msg: result ? "Saved image!" : "Unable to save this image!");
                    } else {
                      await Fluttertoast.showToast(msg: "Missing permission");
                    }
                  }
                }
              },
              tooltip: "Save image",
              heroTag: null,
              child: const Icon(Icons.download),
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
            onPressed: () => setState(() {
              singleProcessor.resetProgress();
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

  /// Build [Scaffold]'s body when fetching multiple images
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
            multiProcessor.clearProcess();
            setState(() => _displayMultipleImages = false);
          }
        },
        child: FutureBuilder(
          future: process.future,
          builder: (context, snapshot) {
            var edge = MediaQuery.of(context).size.width / 2;
            if (snapshot.connectionState == ConnectionState.done) {
              var data = snapshot.data;
              if (data != null) {
                return Image.memory(
                  data.data,
                  width: edge,
                  height: edge,
                  fit: BoxFit.cover,
                );
              }

              var error = snapshot.error;
              if (error != null) {
                return SizedBox(
                  width: edge,
                  height: edge,
                  child: errorIndicator(
                    content: "Error: $error",
                    size: edge / 4,
                  ),
                );
              }
            }

            return SizedBox(
              width: edge,
              height: edge,
              child: loadingIndicator(
                content: "Loading image",
                size: edge / 4,
              ),
            );
          },
        ),
      );
    }

    assert(_displayMultipleImages);
    return ListView.builder(
      cacheExtent: 1000.0,
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
                builder: (_, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    var data = snapshot.data;
                    if (data != null) {
                      return Image.memory(data.data);
                    }

                    var error = snapshot.error;
                    if (error != null) {
                      return errorIndicator(content: "Error: $error");
                    }
                  }

                  return loadingIndicator(content: "Loading image");
                },
              ),
            ),
      floatingActionButton: _displayMultipleImages
          ? FloatingActionButton(
              onPressed: openDrawer,
              tooltip: "Open menu",
              heroTag: null,
              child: const Icon(Icons.list),
            )
          : FutureBuilder(
              future: singleProcessor.inProgress.future,
              builder: (context, snapshot) => Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: createSingleImageButtonArray(context, snapshot),
              ),
            ),
    );

    return WillPopScope(
      child: scaffold,
      onWillPop: () async => false,
    );
  }
}
