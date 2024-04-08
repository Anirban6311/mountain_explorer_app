class Mountain {
  final String name;
  final String imageUrl;
  final String description;

  Mountain({required this.name, required this.imageUrl, required this.description});

  factory Mountain.fromJson(Map<String, dynamic> json) {
    return Mountain(
      name: json['name'],
      imageUrl: json['imageUrl'],
      description: json['description'],
    );
  }
}