class MyPost {
  int? userId;
  int? id;
  String? title;
  String? body;

  MyPost({this.userId, this.id, this.title, this.body});

  MyPost.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    id = json['id'];
    title = json['title'];
    body = json['body'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['userId'] = userId;
    data['id'] = id;
    data['title'] = title;
    data['body'] = body;
    return data;
  }

  static List<MyPost> listFromJson(list) => List<MyPost>.from(list.map((x) => MyPost.fromJson(x)));
}
