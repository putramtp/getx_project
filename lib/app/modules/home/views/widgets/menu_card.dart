import 'package:flutter/material.dart';

class CircleMenuItem extends StatelessWidget {
  final double size;
  final IconData icon;
  final String title;
  final Color iconColor;
  final VoidCallback onTap;

  const CircleMenuItem({
    super.key,
    required this.size,
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(size *2),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size * 4,
            height: size * 4,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: size *2.6,
            ),
          ),
           SizedBox(height: size *0.8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: size * 0.9,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                shadows: [
                  Shadow(
                    color: Colors.white.withOpacity(0.9),
                    offset: const Offset(0, 1),
                    blurRadius: 1,
                  ),
                  Shadow(
                    color: Colors.black.withOpacity(0.15),
                    offset: const Offset(0, -0.5),
                    blurRadius: 1,
                  ),
                ]),
          ),
        ],
      ),
    );
  }
}

