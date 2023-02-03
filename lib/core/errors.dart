abstract class ApplicationException implements Exception {
  abstract final String message;

  @override
  String toString() {
    return message;
  }
}
