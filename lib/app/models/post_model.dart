class PostModel {
  final String userId;
  final String id;
  final String title;
  final String body;
  PostModel({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });



  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        userId: json["userId"],
        id    : json["id"],
        title : json['title'], 
        body  : json['body'],
      );

  static List<PostModel> listFromJson(list) => List<PostModel>.from(list.map((x) => PostModel.fromJson(x)));
}