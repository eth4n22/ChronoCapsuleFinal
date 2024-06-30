class Capsule {
  final String title;
  final DateTime date;
  final List<String> uploadedPhotos; // List of photo paths
  final List<String> letters; // List of letters
  final List<String> uploadedVideos; // List of video paths

  Capsule({
    required this.title,
    required this.date,
    required this.uploadedPhotos,
    required this.letters,
    required this.uploadedVideos,
  });
}
