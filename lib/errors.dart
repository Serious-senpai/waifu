abstract class ApplicationException implements Exception {
  abstract final String message;

  @override
  String toString() {
    return message;
  }
}

class RequestCancelledException implements ApplicationException {
  @override
  final String message = "Request to fetch image has been cancelled";
}
