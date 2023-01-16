import "package:flutter/material.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:url_launcher/url_launcher.dart";

import "sources.dart";

/// A transparent [SizedBox] with a width and height of 10.0
const seperator = SizedBox(width: 10.0, height: 10.0);

/// Display a loading indicator above [content]
Widget loadingIndicator({String? content, double size = 60}) {
  var sizedBox = SizedBox(
    width: size,
    height: size,
    child: const CircularProgressIndicator(),
  );

  var children = <Widget>[sizedBox];
  if (content != null) {
    children.addAll(
      [
        seperator,
        Text(content),
      ],
    );
  }

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: children,
  );
}

/// Display an error indicator with error message [content]
Widget errorIndicator({String? content, double size = 60}) {
  var sizedBox = SizedBox(
    width: size,
    height: size,
    child: Icon(Icons.highlight_off, size: size),
  );

  var children = <Widget>[sizedBox];
  if (content != null) {
    children.addAll(
      [
        seperator,
        Text(content),
      ],
    );
  }

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: children,
  );
}

/// Launch [url] in an external browser
Future<void> launch(Uri url) async {
  var status = await launchUrl(url, mode: LaunchMode.externalApplication);

  if (!status) {
    await Fluttertoast.showToast(msg: "Cannot launch $url");
  }
}

Widget renderOriginal(BuildContext context, AsyncSnapshot<ImageData> snapshot) {
  if (snapshot.connectionState == ConnectionState.done) {
    return Image.memory(snapshot.data!.data);
  } else if (snapshot.connectionState == ConnectionState.waiting) {
    return loadingIndicator(content: "Loading image");
  } else {
    return errorIndicator(content: "Invalid state: ${snapshot.connectionState}");
  }
}

Widget renderSmall(BuildContext context, AsyncSnapshot<ImageData> snapshot) {
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
}
