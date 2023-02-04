import "package:flutter/material.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:url_launcher/url_launcher.dart";

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

/// Return a string displaying a certain memory amount.
///
/// For example:
/// - 2 bytes -> "2 B"
/// - 1024 bytes -> "1 KB"
/// - 1048576 bytes -> "1 MB"
String displayBytes(num bytes) {
  var units = ["B", "KB", "MB", "GB", "TB"];

  int unitIndex = 0;
  while (bytes >= 1024) {
    bytes /= 1024;
    unitIndex++;
  }

  return "${bytes.toStringAsFixed(2)} ${units[unitIndex]}";
}
