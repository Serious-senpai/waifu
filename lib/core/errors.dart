abstract class ApplicationException implements Exception {
  abstract final String message;

  @override
  String toString() {
    return message;
  }
}

class RequestCancelledException implements ApplicationException {
  @override
  final message = "Request to fetch image has been cancelled";
}

class ReSmushClientException implements ApplicationException {
  @override
  final message = "Unexpected data from resmush.it";

  final dynamic data;

  ReSmushClientException(this.data);

  @override
  String toString() {
    return "$message:\n$data";
  }
}
