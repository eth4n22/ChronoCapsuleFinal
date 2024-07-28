import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _friendEmailController = TextEditingController();
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _sendFriendRequest() async {
    if (_friendEmailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address.')),
      );
      return;
    }

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated.')),
      );
      return;
    }

    try {
      // Find user by email
      QuerySnapshot<Map<String, dynamic>> userSnapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .where('email', isEqualTo: _friendEmailController.text)
          .get();

      if (userSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User with this email does not exist.')),
        );
        return;
      }

      DocumentSnapshot<Map<String, dynamic>> friendDoc =
          userSnapshot.docs.first;
      String friendUid = friendDoc.id;

      // Send friend request
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .update({
        'friendRequestsReceived': FieldValue.arrayUnion([currentUser!.uid])
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
        'friendRequestsSent': FieldValue.arrayUnion([friendUid])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send friend request: $e')),
      );
    }
  }

  Future<String> _getEmailFromUid(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc['email'];
  }

  Future<void> _acceptFriendRequest(String friendUid) async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated.')),
      );
      return;
    }

    try {
      // Add each user to the other's friends list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
        'friends': FieldValue.arrayUnion([friendUid]),
        'friendRequestsReceived': FieldValue.arrayRemove([friendUid])
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .update({
        'friends': FieldValue.arrayUnion([currentUser!.uid]),
        'friendRequestsSent': FieldValue.arrayRemove([currentUser!.uid])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request accepted.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept friend request: $e')),
      );
    }
  }

  Future<void> _removeFriend(String friendUid) async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated.')),
      );
      return;
    }

    try {
      // Remove each user from the other's friends list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
        'friends': FieldValue.arrayRemove([friendUid])
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .update({
        'friends': FieldValue.arrayRemove([currentUser!.uid])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend removed.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove friend: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Friends'),
        ),
        body: const Center(
          child: Text('User not authenticated.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Add Friend by Email'),
            TextField(
              controller: _friendEmailController,
              decoration: const InputDecoration(
                hintText: 'Enter friend\'s email',
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _sendFriendRequest,
              child: const Text('Send Friend Request'),
            ),
            const SizedBox(height: 32.0),
            const Text('Friend Requests'),
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  var userDoc = snapshot.data!;
                  List<dynamic> friendRequestsReceived =
                      userDoc['friendRequestsReceived'] ?? [];

                  if (friendRequestsReceived.isEmpty) {
                    return const Text('No friend requests.');
                  }

                  return ListView.builder(
                    itemCount: friendRequestsReceived.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder<String>(
                        future: _getEmailFromUid(friendRequestsReceived[index]),
                        builder: (context, emailSnapshot) {
                          if (!emailSnapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          return ListTile(
                            title: Text(emailSnapshot.data!),
                            trailing: IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () {
                                _acceptFriendRequest(
                                    friendRequestsReceived[index]);
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 32.0),
            const Text('Friends List'),
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  var userDoc = snapshot.data!;
                  List<dynamic> friends = userDoc['friends'] ?? [];

                  if (friends.isEmpty) {
                    return const Text('No friends yet.');
                  }

                  return ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder<String>(
                        future: _getEmailFromUid(friends[index]),
                        builder: (context, emailSnapshot) {
                          if (!emailSnapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          return ListTile(
                            title: Text(emailSnapshot.data!),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.red),
                              onPressed: () {
                                _removeFriend(friends[index]);
                              },
                            ),
                            onTap: () {
                              // Navigate to friend's active capsules
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
