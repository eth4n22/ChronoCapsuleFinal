import 'dart:io'; // Import for File class
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:chronocapsules/capsule.dart'; // Import Capsule class
import 'package:chronocapsules/full_screen_image_screen.dart'; // Import the full screen image screen
import 'package:chronocapsules/full_screen_video_screen.dart'; // Import the full screen video screen
import 'package:image_picker/image_picker.dart'; // Import for image picker
import 'package:video_player/video_player.dart'; // Import for video player
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Firestore

class TimeCapsuleDetailsScreen extends StatefulWidget {
  final Capsule capsule;
  final Function(Capsule) onUpdate;
  final Function(Capsule) onDelete; // Add a callback function for deletion

  const TimeCapsuleDetailsScreen({
    super.key,
    required this.capsule,
    required this.onUpdate,
    required this.onDelete, // Add this parameter
  });

  @override
  _TimeCapsuleDetailsScreenState createState() =>
      _TimeCapsuleDetailsScreenState();
}

class _TimeCapsuleDetailsScreenState extends State<TimeCapsuleDetailsScreen> {
  late Capsule capsule;

  @override
  void initState() {
    super.initState();
    capsule = widget.capsule;
  }

  // Function to format DateTime to display only the date
  String formattedDate(DateTime dateTime) {
    return DateFormat('MMMM d, yyyy').format(dateTime);
  }

  Future<void> _addPhotos() async {
    final List<XFile>? selectedImages = await ImagePicker().pickMultiImage(
      imageQuality: 70, // Adjust as needed
    );

    if (selectedImages != null && selectedImages.isNotEmpty) {
      setState(() {
        // Add new photos to the existing list
        capsule.uploadedPhotos
            .addAll(selectedImages.map((image) => image.path));
        _updateCapsule(); // Update the capsule in Firestore
      });
    }
  }

  Future<void> _addVideos() async {
    final XFile? selectedVideo = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
    );

    if (selectedVideo != null) {
      setState(() {
        capsule.uploadedVideos.add(selectedVideo.path);
        _updateCapsule(); // Update the capsule in Firestore
      });
    }
  }

  Future<void> _addLetter() async {
    final TextEditingController letterController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Letter"),
        content: TextField(
          controller: letterController,
          maxLines: 10,
          decoration: const InputDecoration(hintText: "Enter your letter here"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (letterController.text.isNotEmpty) {
                setState(() {
                  capsule.letters.add(letterController.text);
                  _updateCapsule(); // Update the capsule in Firestore
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                setState(() {
                  if (index < capsule.uploadedPhotos.length) {
                    capsule.uploadedPhotos.removeAt(index);
                  } else if (index <
                      capsule.uploadedPhotos.length +
                          capsule.uploadedVideos.length) {
                    capsule.uploadedVideos
                        .removeAt(index - capsule.uploadedPhotos.length);
                  } else {
                    capsule.letters.removeAt(index -
                        capsule.uploadedPhotos.length -
                        capsule.uploadedVideos.length);
                  }
                  _updateCapsule(); // Update the capsule in Firestore
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCapsule() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this capsule?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('capsules')
                    .doc(capsule.id)
                    .delete();
                widget.onDelete(capsule);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateCapsule() async {
    await FirebaseFirestore.instance
        .collection('capsules')
        .doc(capsule.id)
        .update({
      'uploadedPhotos': capsule.uploadedPhotos,
      'uploadedVideos': capsule.uploadedVideos,
      'letters': capsule.letters,
    });
    widget.onUpdate(capsule);
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          capsule.title,
          style: const TextStyle(
            fontSize: 24.0,
            color: Colors.black,
            fontFamily: 'IndieFlower',
          ),
        ),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteCapsule,
          ),
        ],
      ),
      body: Container(
        color: Colors.white, // Light pastel blue color
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'VIRTUAL CAPSULE:',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.black,
                  fontFamily: 'IndieFlower',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Opening Date: ${formattedDate(capsule.date)}',
                style: const TextStyle(fontSize: 18, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              if (capsule.date.isAfter(now))
                _buildLockedCapsuleInfo() // Show locked capsule info
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: capsule.uploadedPhotos.length +
                        capsule.letters.length +
                        capsule.uploadedVideos.length,
                    itemBuilder: (context, index) {
                      if (index < capsule.uploadedPhotos.length) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullScreenImageScreen(
                                  imagePath: capsule.uploadedPhotos[index],
                                ),
                              ),
                            );
                          },
                          child: ListTile(
                            leading: Image.file(
                              File(capsule.uploadedPhotos[index]),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            title: Text(
                              'Photo ${index + 1}',
                              style: const TextStyle(color: Colors.black),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteItem(index),
                            ),
                          ),
                        );
                      } else if (index <
                          capsule.uploadedPhotos.length +
                              capsule.uploadedVideos.length) {
                        int videoIndex = index - capsule.uploadedPhotos.length;
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullScreenVideoScreen(
                                  videoPath: capsule.uploadedVideos[videoIndex],
                                ),
                              ),
                            );
                          },
                          child: ListTile(
                            leading: FutureBuilder<VideoPlayerController>(
                              future: _initializeVideoPlayer(
                                  capsule.uploadedVideos[videoIndex]),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.done) {
                                  return AspectRatio(
                                    aspectRatio:
                                    snapshot.data!.value.aspectRatio,
                                    child: VideoPlayer(snapshot.data!),
                                  );
                                } else {
                                  return const CircularProgressIndicator();
                                }
                              },
                            ),
                            title: Text(
                              'Video ${videoIndex + 1}',
                              style: const TextStyle(color: Colors.black),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteItem(index),
                            ),
                          ),
                        );
                      } else {
                        int letterIndex = index -
                            capsule.uploadedPhotos.length -
                            capsule.uploadedVideos.length;
                        return ListTile(
                          title: Text(
                            'Letter ${letterIndex + 1}',
                            style: const TextStyle(color: Colors.black),
                          ),
                          subtitle: Text(capsule.letters[letterIndex]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteItem(index),
                          ),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red[600],
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<VideoPlayerController> _initializeVideoPlayer(String path) async {
    final controller = VideoPlayerController.file(File(path));
    await controller.initialize();
    return controller;
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text("Add Photos"),
            onTap: () {
              Navigator.pop(context);
              _addPhotos();
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text("Add Video"),
            onTap: () {
              Navigator.pop(context);
              _addVideos();
            },
          ),
          ListTile(
            leading: const Icon(Icons.note),
            title: const Text("Add Letter"),
            onTap: () {
              Navigator.pop(context);
              _addLetter();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLockedCapsuleInfo() {
    return Column(
      children: [
        const Text(
          'LOCKED',
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
        const SizedBox(height: 10),
        Text(
          'Photos: ${capsule.uploadedPhotos.length}',
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
        Text(
          'Videos: ${capsule.uploadedVideos.length}',
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
        Text(
          'Letters: ${capsule.letters.length}',
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
      ],
    );
  }
}
