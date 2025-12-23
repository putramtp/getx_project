import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hexcolor/hexcolor.dart';

AppBar costumAppbar(String title) {
  return AppBar(
    title: Text(title),
    centerTitle: true,
    excludeHeaderSemantics: true,
    backgroundColor: Colors.green[100],
    elevation: 2,
  );
}

Widget titleApp(String text, double size) {
  return Text(
    text,
    style: TextStyle(
        fontSize: size * 1.8,
        letterSpacing: 0.5,
        wordSpacing: 2,
        color: Colors.white,
        fontWeight: FontWeight.w500),
    overflow: TextOverflow.ellipsis,
  );
}

Widget titleMenu(String text, double size) {
  return Text(text, style: TextStyle(fontSize: size * 1.17));
}

Widget testContainer(double size) {
  return Container(height: size, width: size, color: Colors.brown);
}

PreferredSizeWidget appBarOrder(String title,double size,{IconData? icon = Icons.inventory_2, String? routeBackName,bool showIcon = true, String? hex1,String? hex2}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(65),
    child: AppBar(
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration:  BoxDecoration(
          gradient: LinearGradient(
            colors: [HexColor(hex1 ?? "#4A70A9"),HexColor(hex2 ?? '#8FABD4')],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          IconButton(
            icon:  Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white,size: size *2),
            onPressed: () =>
                (routeBackName != null) ? Get.toNamed(routeBackName) : Get.back(),
          ),
          showIcon 
              ? Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(icon, color: Colors.white, size: size *2),
                ],
              )
              : const SizedBox.shrink(),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style:  TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: size * 2.2,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
      elevation: 4,
      centerTitle: false,
    ),
  );
}

// showRemoveDialog(context, code, onConfirm);
Future<void> showRemoveDialog(
  BuildContext context,
  String code,
  VoidCallback onConfirm,
) async {
  await Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.redAccent,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              "Remove Scanned Code",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 12),

            // Content message
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Are you sure you want to remove this code?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                Text(
                  code,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.blue.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    onConfirm();
                    Get.back();
                  },
                  child: const Text(
                    "Remove",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// showEditCodeDialog(context, oldCode, onSave: (newCode) ;
Future<void> showEditCodeDialog(
  BuildContext context,
  String code, {
  required ValueChanged<String> onSave,
}) async {
  final TextEditingController controller = TextEditingController(text: code);

  await Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_note_rounded,
                color: Colors.blueAccent, size: 48),
            const SizedBox(height: 16),
            const Text(
              "Edit Scanned Code",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: "Scanned Code",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newCode = controller.text.trim();
                    if (newCode.isNotEmpty) {
                      onSave(newCode);
                      Get.back();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}


Widget buildSyncButton({required VoidCallback onPressed,required double size,Color color = Colors.blue,String name = 'Synchronization'}){
   return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: SizedBox(
        width: double.infinity,
        height: size * 4,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon:  Icon(Icons.sync, color: Colors.white,size: size *2,),
          label:  Text(
            name,
            style: TextStyle(fontSize: size * 1.8, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
}

 Widget textWithIcon(double size, String text, IconData icon,Color iconColor) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(icon, color: iconColor, size: size * 2),
          ),
          WidgetSpan(
            child: SizedBox(width:size * 0.5), 
          ),
          TextSpan(
            text: text,
            style: TextStyle(fontSize: size * 1.3, color: Colors.black),
          ),
        ],
      ),
    );
  }