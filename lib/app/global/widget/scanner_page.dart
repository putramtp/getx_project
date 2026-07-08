import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../scan_feedback.dart';
import '../size_config.dart';
import '../styles/app_text_style.dart';

/// Open the scanner in single-shot mode and return the first scanned code
/// (or null if the worker backed out). For flows that need a follow-up dialog
/// after a scan (e.g. batch quantity), so the camera closes on the first read.
Future<String?> scanSingle({
  required Color accent,
  String title = 'Scan Barcode',
}) async {
  return await Get.to<String>(() => ScannerPage(title: title, accent: accent));
}

/// Full-screen camera scanner built on `mobile_scanner`.
///
/// Two modes, chosen by whether [onCode] is provided:
/// - **Continuous batch** (`onCode` set): the camera stays open and every
///   scan is fed to [onCode]; its returned [ScanFeedback] drives an inline
///   colored flash + running count, so a worker can scan many labels in a row
///   without reopening. Same-code re-reads are debounced and scans are
///   serialized against the in-flight save.
/// - **Single-shot** (`onCode` null): pops with the first scanned code.
class ScannerPage extends StatefulWidget {
  final String title;
  final Color accent;

  /// Continuous-mode handler. When null, the page is single-shot.
  final Future<ScanFeedback> Function(String code)? onCode;

  /// Optional manual-entry fallback (e.g. a keyboard dialog). When provided in
  /// continuous mode, a keyboard button routes the typed code through [onCode].
  final Future<String?> Function()? onManualEntry;

  const ScannerPage({
    super.key,
    required this.title,
    required this.accent,
    this.onCode,
    this.onManualEntry,
  });

  bool get continuous => onCode != null;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 250,
  );

  static const Duration _dupCooldown = Duration(seconds: 2);

  bool _processing = false;
  bool _popped = false;
  String? _lastCode;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);
  ScanFeedback? _feedback;
  int _accepted = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    String? code;
    for (final b in capture.barcodes) {
      final v = b.rawValue?.trim();
      if (v != null && v.isNotEmpty) {
        code = v;
        break;
      }
    }
    if (code == null) return;

    // Single-shot: hand the first code back to the caller and close.
    if (!widget.continuous) {
      if (_popped) return;
      _popped = true;
      Get.back(result: code);
      return;
    }

    // Continuous: skip while a save is in flight, and ignore rapid re-reads of
    // the same code (the camera fires many frames for one physical label).
    if (_processing) return;
    final now = DateTime.now();
    if (code == _lastCode && now.difference(_lastAt) < _dupCooldown) return;
    _process(code);
  }

  Future<void> _process(String code) async {
    _lastCode = code;
    _lastAt = DateTime.now();
    setState(() => _processing = true);
    final fb = await widget.onCode!(code);
    if (!mounted) return;
    setState(() {
      _feedback = fb;
      if (fb.status == ScanStatus.ok) _accepted++;
      _processing = false;
    });
  }

  Future<void> _manualEntry() async {
    final entry = widget.onManualEntry;
    if (entry == null || _processing) return;
    final code = await entry();
    if (code == null || code.trim().isEmpty || !mounted) return;
    await _process(code.trim());
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            fit: BoxFit.cover,
          ),
          _reticle(size),
          SafeArea(child: _topBar(size)),
          if (widget.continuous)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _bottomPanel(size),
              ),
            )
          else
            SafeArea(child: Align(alignment: Alignment.bottomCenter, child: _hint(size))),
        ],
      ),
    );
  }

  Widget _topBar(double size) {
    return Padding(
      padding: EdgeInsets.all(size * 1.2),
      child: Row(
        children: [
          _circleButton(size, Icons.close_rounded, () => Get.back()),
          SizedBox(width: size),
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.h5(size, color: Colors.white),
            ),
          ),
          ValueListenableBuilder<TorchState>(
            valueListenable: _controller.torchState,
            builder: (_, state, __) => _circleButton(
              size,
              state == TorchState.on
                  ? Icons.flash_on_rounded
                  : Icons.flash_off_rounded,
              _controller.toggleTorch,
              active: state == TorchState.on,
            ),
          ),
          SizedBox(width: size * 0.8),
          _circleButton(size, Icons.cameraswitch_rounded, _controller.switchCamera),
        ],
      ),
    );
  }

  Widget _reticle(double size) {
    return Center(
      child: Container(
        width: size * 26,
        height: size * 26,
        decoration: BoxDecoration(
          border: Border.all(color: widget.accent, width: size * 0.3),
          borderRadius: BorderRadius.circular(size * 2),
        ),
      ),
    );
  }

  Widget _hint(double size) {
    return Container(
      margin: EdgeInsets.only(bottom: size * 3),
      padding: EdgeInsets.symmetric(horizontal: size * 2, vertical: size),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(size * 2),
      ),
      child: Text("Point the camera at a barcode",
          style: AppTextStyle.body(size, color: Colors.white)),
    );
  }

  Widget _bottomPanel(double size) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(size * 1.2),
      padding: EdgeInsets.all(size * 1.6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(size * 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _feedbackChip(size),
          SizedBox(height: size * 1.2),
          Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: widget.accent, size: size * 2.2),
              SizedBox(width: size * 0.8),
              Text("Accepted: $_accepted",
                  style: AppTextStyle.bodyBold(size, color: Colors.white)),
              const Spacer(),
              if (widget.onManualEntry != null)
                _circleButton(size, Icons.keyboard_rounded, _manualEntry),
            ],
          ),
          SizedBox(height: size * 1.2),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.done_rounded),
              label: Text("Done", style: AppTextStyle.bodyBold(size, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: size * 1.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(size * 1.4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedbackChip(double size) {
    final fb = _feedback;
    if (_processing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size * 2,
            height: size * 2,
            child: const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.4),
          ),
          SizedBox(width: size),
          Text("Saving…", style: AppTextStyle.body(size, color: Colors.white)),
        ],
      );
    }
    if (fb == null) {
      return Text("Scan a label to begin",
          style: AppTextStyle.body(size, color: Colors.white70));
    }
    final color = _statusColor(fb.status);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: size * 1.4, vertical: size),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(size * 1.2),
        border: Border.all(color: color, width: size * 0.16),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(fb.status), color: color, size: size * 2.2),
          SizedBox(width: size * 0.8),
          Expanded(
            child: Text(fb.message,
                style: AppTextStyle.bodyBold(size, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(double size, IconData icon, VoidCallback onTap,
      {bool active = false}) {
    return Material(
      color: active ? widget.accent : Colors.black.withOpacity(0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(size),
          child: Icon(icon, color: Colors.white, size: size * 2.2),
        ),
      ),
    );
  }

  Color _statusColor(ScanStatus s) {
    switch (s) {
      case ScanStatus.ok:
        return const Color(0xFF3BB273);
      case ScanStatus.duplicate:
        return const Color(0xFFE0A72E);
      case ScanStatus.unknown:
      case ScanStatus.error:
        return const Color(0xFFE05B5B);
    }
  }

  IconData _statusIcon(ScanStatus s) {
    switch (s) {
      case ScanStatus.ok:
        return Icons.check_circle_rounded;
      case ScanStatus.duplicate:
        return Icons.info_rounded;
      case ScanStatus.unknown:
        return Icons.help_rounded;
      case ScanStatus.error:
        return Icons.error_rounded;
    }
  }
}
