String sanitizeText(String? input) {
  if (input == null) return '';
  return input.replaceAll('**', '');
}
