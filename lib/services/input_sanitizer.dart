class InputSanitizer {
  static String sanitize(String input) {
    var result = input
        .replaceAll(RegExp(r'[\n\r\t]'), ' ')
        .replaceAll(RegExp(r'```'), '')
        .replaceAll(RegExp(r'---'), '')
        .replaceAll(RegExp(r'###'), '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
    if (result.length > 20) {
      result = result.substring(0, 20);
    }
    return result;
  }
}
