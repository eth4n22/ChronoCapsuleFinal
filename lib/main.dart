import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chronocapsules/sign_in_screen.dart';
import 'package:chronocapsules/create_capsule_screen.dart';
import 'package:chronocapsules/time_capsule_details_screen.dart';
import 'package:chronocapsules/capsule.dart';
import 'package:intl/intl.dart';
import 'package:chronocapsules/friends_screen.dart';
import 'package:chronocapsules/update_firestore_schema.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    await updateFirestoreSchema();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return const TimeCapsuleHomeScreen();
        } else {
          return const SigninScreen();
        }
      },
    );
  }
}

class TimeCapsuleHomeScreen extends StatefulWidget {
  const TimeCapsuleHomeScreen({super.key});

  @override
  _TimeCapsuleHomeScreenState createState() => _TimeCapsuleHomeScreenState();
}

class _TimeCapsuleHomeScreenState extends State<TimeCapsuleHomeScreen> {
  List<Capsule> capsules = [];
  List<Map<String, dynamic>> friendsCapsules = [];

  @override
  void initState() {
    super.initState();
    _fetchCapsules();
  }

  Future<void> _fetchCapsules() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    // Fetch user's capsules
    QuerySnapshot<Map<String, dynamic>> userCapsulesSnapshot =
        await FirebaseFirestore.instance
            .collection('capsules')
            .where('ownerId', isEqualTo: currentUser.uid)
            .get();
    List<Capsule> userCapsules = userCapsulesSnapshot.docs
        .map((doc) => Capsule.fromMap(doc.data()))
        .toList();

    // Fetch friends' capsules
    DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    List<String> friends = List<String>.from(userDoc['friends'] ?? []);

    List<Map<String, dynamic>> allFriendsCapsules = [];
    for (String friendId in friends) {
      // Fetch friend email
      DocumentSnapshot<Map<String, dynamic>> friendDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(friendId)
          .get();
      String friendEmail = friendDoc['email'];

      QuerySnapshot<Map<String, dynamic>> friendCapsulesSnapshot =
          await FirebaseFirestore.instance
              .collection('capsules')
              .where('ownerId', isEqualTo: friendId)
              .get();
      List<Map<String, dynamic>> friendCapsules = friendCapsulesSnapshot.docs
          .map((doc) => {
                'capsule': Capsule.fromMap(doc.data()),
                'ownerEmail': friendEmail // Use friend's email
              })
          .toList();
      allFriendsCapsules.addAll(friendCapsules);
    }

    setState(() {
      capsules = userCapsules;
      friendsCapsules = allFriendsCapsules;
    });
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ChronoCapsule',
          style: TextStyle(
            fontSize: 30.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: Colors.white,
            fontFamily: 'IndieFlower',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: Icon(Icons.group),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FriendsScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.black87, Colors.black26],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            child: Column(
              children: <Widget>[
                const SizedBox(
                  width: 200,
                  height: 200,
                  child: Image(
                    image: AssetImage('images/chest.png'),
                  ),
                ),
                Center(
                  child: Container(
                    child: const Text(
                      'Active ChronoCapsules',
                      style: TextStyle(
                        fontSize: 30.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Colors.white,
                        fontFamily: 'IndieFlower',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Your Email: ${currentUser?.email ?? ''}',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.white,
                    fontFamily: 'IndieFlower',
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Your Capsules',
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.yellow,
                    fontFamily: 'IndieFlower',
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: capsules.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          border: Border.all(
                            color: Colors.white10,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8.0),
                          title: Text(
                            capsules[index].title,
                            style: const TextStyle(color: Colors.yellow),
                          ),
                          subtitle: Text(
                            'Opens on: ${DateFormat('MMMM d, yyyy').format(capsules[index].date)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TimeCapsuleDetailsScreen(
                                  capsule: capsules[index],
                                  onUpdate: (updatedCapsule) {
                                    setState(() {
                                      capsules[index] = updatedCapsule;
                                    });
                                  },
                                  onDelete: (deletedCapsule) {
                                    setState(() {
                                      capsules.remove(deletedCapsule);
                                    });
                                  },
                                ),
                              ),
                            );
                            if (result == 'delete') {
                              setState(() {
                                capsules.removeAt(index);
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Friends\' Capsules',
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.yellow,
                    fontFamily: 'IndieFlower',
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: friendsCapsules.length,
                    itemBuilder: (context, index) {
                      final capsule =
                          friendsCapsules[index]['capsule'] as Capsule;
                      final ownerEmail =
                          friendsCapsules[index]['ownerEmail'] as String;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          border: Border.all(
                            color: Colors.white10,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8.0),
                          title: Text(
                            '${capsule.title} by $ownerEmail',
                            style: const TextStyle(color: Colors.yellow),
                          ),
                          subtitle: Text(
                            'Opens on: ${DateFormat('MMMM d, yyyy').format(capsule.date)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TimeCapsuleDetailsScreen(
                                  capsule: capsule,
                                  onUpdate: (updatedCapsule) {
                                    setState(() {
                                      friendsCapsules[index]['capsule'] =
                                          updatedCapsule;
                                    });
                                  },
                                  onDelete: (deletedCapsule) {
                                    setState(() {
                                      friendsCapsules.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            );
                            if (result == 'delete') {
                              setState(() {
                                friendsCapsules.removeAt(index);
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut().then((value) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SigninScreen(),
                      ),
                    );
                  });
                },
                child: const Text("Logout"),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red[600],
        onPressed: () async {
          final newCapsule = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateCapsuleScreen(),
            ),
          );
          if (newCapsule != null) {
            setState(() {
              capsules.add(newCapsule);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
