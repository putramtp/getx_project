import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

String capitalizeFirstofEach(String text) {
  List<String> words = text.split(" ");
  for (int i = 0; i < words.length; i++) {
    String word = words[i];
    if (word.isNotEmpty) {
      words[i] = word[0].toUpperCase() + word.substring(1);
    }
  }
  return words.join(" ");
}

bool urlValid(String imageUrl) {
  Uri? uri = Uri.tryParse(imageUrl);
  return uri != null &&
      uri.isAbsolute &&
      (uri.scheme == 'http' || uri.scheme == 'https');
}

bool isImageUrl(String imageUrl) {
  final imageExtensions = ['.jpg', '.jpeg', '.png'];
  final lowercaseUrl = imageUrl.toLowerCase();

  // Check if the URL ends with a known image extension
  if (imageExtensions.any((extension) => lowercaseUrl.endsWith(extension))) {
    return true;
  }

  // Alternatively, you can check the content type of the resource
  // using a package like http or dio
  // Example:
  // final response = await http.head(Uri.parse(url));
  // final contentType = response.headers['content-type'];
  // return contentType?.startsWith('image/') ?? false;

  return false;
}

bool isPdfUrl(String pdfUrl) {
  final pdfExtensions = ['.pdf'];
  final lowercaseUrl = pdfUrl.toLowerCase();
  if (pdfExtensions.any((extension) => lowercaseUrl.endsWith(extension))) {
    return true;
  } else {
    return false;
  }
}

bool searchString(String query, String string) {
  query = query.replaceAll(' ', '').toLowerCase();
  string = string.replaceAll(' ', '').toLowerCase();
  return string.contains(query);
}

Future<bool> checkImageAssetExist(String pathImage) async {
  try {
    await rootBundle.load(pathImage);
    return true;
  } catch (error) {
    return false;
  }
}

String formatDateTime(DateTime dateTime) {
  return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} "
      "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
}

String formatTime(DateTime dateTime) {
  return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
}

Future<DateTime?> pickDate(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  return await showDatePicker(
    context: context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: firstDate ?? DateTime(2020),
    lastDate: lastDate ?? DateTime.now(),
  );
}

int safeToInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String formatPrice(dynamic value) {
  if (value == null) return "-";

  final number = num.tryParse(value.toString()) ?? 0;
  return NumberFormat.decimalPattern('id_ID').format(number);
}
