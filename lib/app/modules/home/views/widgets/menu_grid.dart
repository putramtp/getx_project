import 'package:flutter/material.dart';
import 'package:getx_project/app/global/widget/animated_counter.dart';
import 'package:hexcolor/hexcolor.dart';

class MenuGrid extends StatelessWidget {
  final double size;
  final String hex1;
  final String hex2;
  final String status;
  final String? statusLabel;
  final String title;
  final IconData iconData;
  final VoidCallback onTap;
  
  const MenuGrid({
    super.key,
    required this.size,
    required this.hex1,
    required this.hex2,
    required this.status,
    this.statusLabel,
    required this.title,
    required this.iconData,
    required this.onTap,

  });


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 1.6),
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [HexColor(hex1), HexColor(hex2)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: size * 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin:EdgeInsets.symmetric(vertical: size *1),
                width: size * 4,
                height: size * 3,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(iconData,
                    color: HexColor(hex1),
                    size: size * 1.9),
              ),
              SizedBox(height: size*1),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      AnimatedCounter(
                        value : int.tryParse(status) ?? 0,
                        style: TextStyle(
                            fontSize: size * 1.2,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      // const SizedBox(width: 3),
                      // statusLabel == null
                      //   ? const SizedBox.shrink()
                      //   : Text(
                      //       statusLabel ?? "",
                      //       style: TextStyle(
                      //         fontSize: size * 1,
                      //         fontWeight: FontWeight.bold,
                      //         color: Colors.white70,
                      //       ),
                      //   )
                    ],
                  ),
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: size * 1,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                    ],
                  ),
                  Text("Tap to View",
                      style: TextStyle(
                          fontSize: size * 0.8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}