/// Result of processing a single scanned code, returned by a flow's `onCode`
/// handler so the continuous scanner can show inline feedback (a colored flash
/// + message) without the controller reaching for a snackbar.
///
/// Kept dependency-free (no Flutter imports) so controllers can build these
/// without pulling in the scanner widget. The scanner maps [status] → colors
/// and icons in its own presentation layer.
enum ScanStatus { ok, duplicate, unknown, error }

class ScanFeedback {
  final ScanStatus status;
  final String message;

  const ScanFeedback(this.status, this.message);

  factory ScanFeedback.ok(String message) =>
      ScanFeedback(ScanStatus.ok, message);
  factory ScanFeedback.duplicate(String message) =>
      ScanFeedback(ScanStatus.duplicate, message);
  factory ScanFeedback.unknown(String message) =>
      ScanFeedback(ScanStatus.unknown, message);
  factory ScanFeedback.error(String message) =>
      ScanFeedback(ScanStatus.error, message);
}
