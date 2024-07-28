import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> updateFirestoreSchema() async {
  // Ensure the user is authenticated before updating the schema
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    return;
  }

  CollectionReference<Map<String, dynamic>> users = FirebaseFirestore.instance
      .collection('users')
      .withConverter(
        fromFirestore: (snapshot, _) => snapshot.data() as Map<String, dynamic>,
        toFirestore: (value, _) => value,
      );

  // Get all user documents
  QuerySnapshot<Map<String, dynamic>> querySnapshot = await users.get();
  for (QueryDocumentSnapshot<Map<String, dynamic>> doc in querySnapshot.docs) {
    // Add new fields to each user document if they don't already exist
    if (!doc.exists) continue;
    Map<String, dynamic> data = doc.data();
    if (!data.containsKey('friends')) {
      await doc.reference.update({
        'friends': [],
        'friendRequestsSent': [],
        'friendRequestsReceived': [],
      });
    }
  }
}
