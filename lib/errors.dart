class RequestCancelledException implements Exception {
  String message = "Request to fetch image has been cancelled";
}

class NotImplementedError implements Exception {
  String message = "This member needs to be implemented in the subclass";
}
