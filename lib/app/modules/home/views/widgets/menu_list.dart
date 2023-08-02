import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MenuList extends StatelessWidget {
  const MenuList({
    super.key,
    required this.size,
    required this.title,
    required this.onTap,
  });

  final double size;
  final String  title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: size*0.4),
      decoration: BoxDecoration(
        color: Colors.white, // Set a default color if you want
        borderRadius: BorderRadius.circular( 10), // Optional: Add border radius
      ),
      child: ListTile(
        leading:  Icon(CupertinoIcons.clock_solid,color:Colors.grey[400]),
        title: Text( title,style: TextStyle(fontWeight: FontWeight.w400,fontSize: size * 1.6),),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
       
      ),
    );
  }
}