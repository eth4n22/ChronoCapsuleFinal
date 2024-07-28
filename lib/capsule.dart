import 'package:cloud_firestore/cloud_firestore.dart';

class Capsule {
  final String id;
  final String title;
  final DateTime date;
  final List<String> uploadedPhotos;
  final List<String> letters;
  final List<String> uploadedVideos;
  final String ownerId;

  Capsule({
    required this.id,
    required this.title,
    required this.date,
    required this.uploadedPhotos,
    required this.letters,
    required this.uploadedVideos,
    required this.ownerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'uploadedPhotos': uploadedPhotos,
      'letters': letters,
      'uploadedVideos': uploadedVideos,
      'ownerId': ownerId,
    };
  }

  static Capsule fromMap(Map<String, dynamic> map) {
    return Capsule(
      id: map['id'],
      title: map['title'],
      date: (map['date'] as Timestamp).toDate(),
      uploadedPhotos: List<String>.from(map['uploadedPhotos']),
      letters: List<String>.from(map['letters']),
      uploadedVideos: List<String>.from(map['uploadedVideos']),
      ownerId: map['ownerId'],
    );
  }

  static Future<void> addCapsule(Capsule capsule) {
    return FirebaseFirestore.instance
        .collection('capsules')
        .doc(capsule.id)
        .set(capsule.toMap());
  }

  static Future<void> deleteCapsule(String id) {
    return FirebaseFirestore.instance.collection('capsules').doc(id).delete();
  }
}
