import 'package:flutter/services.dart' show rootBundle;

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


// class Person {
//   final String name;
//   final int age;

//   Person({required this.name, required this.age});
// }

// class Animal {
//   final String name;
//   final String species;

//   Animal({required this.name, required this.species});
// }

// List<T> getModels<T>() {
//   if (T == Person) {
//     return [
//       Person(name: "John", age: 30),
//       Person(name: "Alice", age: 25),
//       Person(name: "Bob", age: 35),
//     ] as List<T>;
//   } else if (T == Animal) {
//     return [
//       Animal(name: "Fluffy", species: "Dog"),
//       Animal(name: "Whiskers", species: "Cat"),
//     ] as List<T>;
//   } else {
//     throw ArgumentError("Invalid model type");
//   }
// }


