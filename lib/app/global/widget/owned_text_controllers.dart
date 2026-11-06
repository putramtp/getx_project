import 'package:flutter/material.dart';

/// Owns the text controllers of a dialog or bottom sheet and disposes them in
/// [State.dispose] — after the route's close animation, while its TextFields
/// are still mounted. Disposing when `Get.dialog` / `Get.bottomSheet` completes
/// throws "A TextEditingController was used after being disposed"; never
/// disposing them leaks them.
class OwnedTextControllers extends StatefulWidget {
  const OwnedTextControllers({super.key, required this.initialTexts, required this.builder});

  /// One controller per entry, starting with that text.
  final List<String> initialTexts;
  final Widget Function(List<TextEditingController> controllers) builder;

  @override
  State<OwnedTextControllers> createState() => _OwnedTextControllersState();
}

class _OwnedTextControllersState extends State<OwnedTextControllers> {
  late final List<TextEditingController> _controllers = [
    for (final text in widget.initialTexts) TextEditingController(text: text),
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controllers);
}
