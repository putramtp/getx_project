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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size * 1.6),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: size * 1.2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [iconColor.withOpacity(0.12), iconColor.withOpacity(0.22)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 1.6),
            border: Border.all(color: iconColor.withOpacity(0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(size * 0.8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: size * 2.2),
              ),
              SizedBox(height: size * 0.8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: size * 1.1,
                  fontWeight: FontWeight.w600,
                  color: iconColor.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

