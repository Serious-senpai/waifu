import "dart:io";

import "package:flutter/material.dart";

class SocketExceptionApp extends StatelessWidget {
  final SocketException exception;

  const SocketExceptionApp({Key? key, required this.exception}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "HWaifu Generator",
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
      ),
      home: SocketExceptionPage(exception: exception),
      themeMode: ThemeMode.dark,
    );
  }
}

class SocketExceptionPage extends StatefulWidget {
  final SocketException exception;
  const SocketExceptionPage({Key? key, required this.exception}) : super(key: key);

  @override
  State<SocketExceptionPage> createState() => _SocketExceptionPageState();
}

class _SocketExceptionPageState extends State<SocketExceptionPage> {
  SocketException get exception => widget.exception;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Please check your Internet connection and try again",
        ),
      ),
    );
  }
}
