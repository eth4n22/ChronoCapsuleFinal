import 'package:flutter/material.dart';
import 'package:chronocapsules/capsule.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class CreateCapsuleScreen extends StatefulWidget {
  const CreateCapsuleScreen({super.key});

  @override
  _CreateCapsuleScreenState createState() => _CreateCapsuleScreenState();
}

class _CreateCapsuleScreenState extends State<CreateCapsuleScreen> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDate;
  final List<File> _selectedPhotos = [];
  final List<String> _letters = [];
  final List<File> _selectedVideos = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Capsule'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Capsule Title'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: const Text('Select Date'),
            ),
            const SizedBox(height: 20),
            Text(
              _selectedDate != null
                  ? 'Selected Date: ${_selectedDate!.toLocal()}'
                  : 'No Date Selected',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _selectPhotos(context),
              child: const Text('Select Photos'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _selectVideos(context),
              child: const Text('Select Videos'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _addLetter(context),
              child: const Text('Add Letter'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _selectedPhotos.length +
                    _letters.length +
                    _selectedVideos.length,
                itemBuilder: (context, index) {
                  if (index < _selectedPhotos.length) {
                    return ListTile(
                      leading: Image.file(
                        _selectedPhotos[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle),
                        onPressed: () {
                          setState(() {
                            _selectedPhotos.removeAt(index);
                          });
                        },
                      ),
                    );
                  } else if (index <
                      _selectedPhotos.length + _selectedVideos.length) {
                    int videoIndex = index - _selectedPhotos.length;
                    return ListTile(
                      leading: Icon(Icons.video_library),
                      title: Text('Video ${videoIndex + 1}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle),
                        onPressed: () {
                          setState(() {
                            _selectedVideos.removeAt(videoIndex);
                          });
                        },
                      ),
                    );
                  } else {
                    int letterIndex =
                        index - _selectedPhotos.length - _selectedVideos.length;
                    return ListTile(
                      title: Text('Letter ${letterIndex + 1}'),
                      subtitle: Text(_letters[letterIndex]),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle),
                        onPressed: () {
                          setState(() {
                            _letters.removeAt(letterIndex);
                          });
                        },
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _createCapsule(context);
              },
              child: const Text('Create Capsule'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectPhotos(BuildContext context) async {
    final List<XFile> selectedImages = await ImagePicker().pickMultiImage(
      imageQuality: 70,
    );

    if (selectedImages.isNotEmpty) {
      setState(() {
        _selectedPhotos.addAll(selectedImages.map((image) => File(image.path)));
      });
    }
  }

  Future<void> _selectVideos(BuildContext context) async {
    final XFile? selectedVideo = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
    );

    if (selectedVideo != null) {
      setState(() {
        _selectedVideos.add(File(selectedVideo.path));
      });
    }
  }

  Future<void> _addLetter(BuildContext context) async {
    String? letter = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController letterController = TextEditingController();
        return AlertDialog(
          title: const Text('Add a Letter'),
          content: TextField(
            controller: letterController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Type your letter here...',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                Navigator.of(context).pop(letterController.text);
              },
            ),
          ],
        );
      },
    );

    if (letter != null && letter.isNotEmpty) {
      setState(() {
        _letters.add(letter);
      });
    }
  }

  Future<void> _createCapsule(BuildContext context) async {
    if (_titleController.text.isNotEmpty && _selectedDate != null) {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
          ),
        );
        return;
      }

      final newCapsule = Capsule(
        id: Uuid().v4(),
        title: _titleController.text,
        date: _selectedDate!,
        uploadedPhotos: _selectedPhotos.map((photo) => photo.path).toList(),
        letters: _letters,
        uploadedVideos: _selectedVideos.map((video) => video.path).toList(),
        ownerId: currentUser.uid,
      );

      await Capsule.addCapsule(newCapsule);

      Navigator.pop(context, newCapsule);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title and select a date'),
        ),
      );
    }
  }
}
