class Community {
  final int id;
  final String name;
  final String? description;
  final int? userId;

  Community({required this.id, required this.name, this.description, this.userId});

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      userId: json['userId'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'userId': userId,
      };
}
