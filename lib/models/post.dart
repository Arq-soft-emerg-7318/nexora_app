class Post {
  final int id;
  final String title;
  final int? authorId;
  final String body;
  final int? reactions;
  final int? categoryId;
  final int? fileId;
  final int? communityId;
  final String? fileUrl;

  Post({
    required this.id,
    required this.title,
    this.authorId,
    required this.body,
    this.reactions,
    this.categoryId,
    this.fileId,
    this.communityId,
    this.fileUrl,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      authorId: json['authorId'] as int?,
      body: json['body'] as String? ?? '',
      // Ignore `reactions` coming from /api/v1/posts — use likes API instead.
      reactions: null,
      categoryId: json['categoryId'] as int?,
      fileId: json['fileId'] as int?,
      communityId: json['communityId'] as int?,
      fileUrl: json['fileUrl'] as String?,
    );
  }

  Post copyWith({
    int? id,
    String? title,
    int? authorId,
    String? body,
    int? reactions,
    int? categoryId,
    int? fileId,
    int? communityId,
    String? fileUrl,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      authorId: authorId ?? this.authorId,
      body: body ?? this.body,
      reactions: reactions ?? this.reactions,
      categoryId: categoryId ?? this.categoryId,
      fileId: fileId ?? this.fileId,
      communityId: communityId ?? this.communityId,
      fileUrl: fileUrl ?? this.fileUrl,
    );
  }
}
