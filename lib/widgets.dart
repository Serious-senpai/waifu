import "package:flutter/material.dart";

/// A transparent [SizedBox] with height of 10.0
const seperator = SizedBox(height: 10.0);

/// Display a loading indicator above [content]
Widget loadingIndicator({String? content, double width = 100, double height = 100, double scale = 0.6}) {
  var sizedBox = SizedBox(
    width: width * scale,
    height: height * scale,
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

  return SizedBox(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    ),
    width: width,
    height: height,
  );
}

/// Display an error indicator with error message [content]
Widget errorIndicator({String? content, double width = 100, double height = 100, double scale = 0.6}) {
  var sizedBox = SizedBox(
    width: width * scale,
    height: height * scale,
    child: const Icon(Icons.highlight_off, size: 60),
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
