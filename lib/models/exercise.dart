class Exercise {
  final int id;
  final String title;
  final String name;
  final String mainMuscle;
  final String secondaryMuscles;
  final List<String> tips;
  final String videoUrl;
  final String imageUrl;
  final List<String> otherNames;
  final String content;
  bool isFavorite;
  int likes;
  bool isLikedByUser;

  Exercise({
    required this.id,
    required this.title,
    required this.name,
    required this.mainMuscle,
    required this.secondaryMuscles,
    required this.tips,
    required this.videoUrl,
    required this.imageUrl,
    required this.otherNames,
    required this.content,
    this.isFavorite = false,
    this.likes = 0,
    this.isLikedByUser = false,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    // Parse tips
    List<String> tipsList = [];
    if (json['meta'] != null) {
      if (json['meta']['tip_1'] != null &&
          json['meta']['tip_1'].toString().isNotEmpty) {
        tipsList.add(json['meta']['tip_1'].toString());
      }
      if (json['meta']['tip_2'] != null &&
          json['meta']['tip_2'].toString().isNotEmpty) {
        tipsList.add(json['meta']['tip_2'].toString());
      }
      if (json['meta']['tip_3'] != null &&
          json['meta']['tip_3'].toString().isNotEmpty) {
        tipsList.add(json['meta']['tip_3'].toString());
      }
    }

    // Parse other names
    List<String> otherNamesList = [];
    if (json['meta'] != null &&
        json['meta']['other_names_app'] != null &&
        json['meta']['other_names_app']['item-0'] != null) {
      var names = json['meta']['other_names_app']['item-0'];
      for (int i = 1; i <= 6; i++) {
        if (names['$i'] != null && names['$i'].toString().isNotEmpty) {
          otherNamesList.add(names['$i'].toString());
        }
      }
    }

    return Exercise(
      id: json['id'] ?? 0,
      title: json['title']['rendered'] ?? '',
      name: json['meta']?['name_app'] ?? json['title']['rendered'] ?? '',
      mainMuscle: json['meta']?['main_muscle'] ?? '',
      secondaryMuscles: json['meta']?['secondary_muscles'] ?? '',
      tips: tipsList,
      videoUrl: json['meta']?['videoforapp'] ?? '',
      imageUrl: json['meta']?['sample_image_forapp'] ?? '',
      otherNames: otherNamesList,
      content: json['meta']?['learn'] ?? json['content']['rendered'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'name': name,
      'mainMuscle': mainMuscle,
      'secondaryMuscles': secondaryMuscles,
      'tips': tips,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'otherNames': otherNames,
      'content': content,
      'isFavorite': isFavorite,
      'likes': likes,
      'isLikedByUser': isLikedByUser,
    };
  }
}
