import 'package:flutter/material.dart';

class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle style;
  final Duration duration;

  const AnimatedCounter({
    Key? key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final whole = value.floor();
        final decimal = ((value - whole) * 10).floor();
        return Text(
          '${whole.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}${decimal >= 5 ? '+' : ''}',
          style: style,
        );
      },
    );
  }
}