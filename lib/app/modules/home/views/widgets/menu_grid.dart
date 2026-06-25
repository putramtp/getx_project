import 'package:flutter/material.dart';
import 'package:getx_project/app/global/widget/animated_counter.dart';

class MenuGrid extends StatelessWidget {
  final double size;
  final Color color1;
  final Color color2;
  final String title;
  final IconData iconData;
  final VoidCallback onTap;
  final String status;

  const MenuGrid({
    super.key,
    required this.size,
    required this.color1,
    required this.color2,
    required this.title,
    required this.iconData,
    required this.onTap,
    this.status = '',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size * 1.8),
        child: Container(
          padding: EdgeInsets.all(size * 1.6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * 1.8),
            border: Border.all(color: color1.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: color1.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(size * 0.9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color1, color2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(size * 1.2),
                ),
                child: Icon(iconData, color: Colors.white, size: size * 2),
              ),
              SizedBox(height: size * 1.2),
              AnimatedCounter(
                value: int.tryParse(status) ?? 0,
                style: TextStyle(
                  fontSize: size * 2.2,
                  fontWeight: FontWeight.bold,
                  color: color1,
                ),
              ),
              SizedBox(height: size * 0.3),
              Text(
                title,
                style: TextStyle(
                  fontSize: size * 1.1,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: size * 0.8),
              Row(
                children: [
                  Text(
                    'View',
                    style: TextStyle(
                      fontSize: size * 1.1,
                      color: color1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: size * 0.3),
                  Icon(Icons.arrow_forward_rounded, size: size * 1.3, color: color1),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
