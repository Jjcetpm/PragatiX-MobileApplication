class StringUtils {
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;

    return text
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
