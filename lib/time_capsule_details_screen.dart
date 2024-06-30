import 'dart:io'; // Import for File class
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:chronocapsules/capsule.dart'; // Import Capsule class
import 'package:chronocapsules/full_screen_image_screen.dart'; // Import the full screen image screen
import 'package:image_picker/image_picker.dart'; // Import image_picker for photo selection

class TimeCapsuleDetailsScreen extends StatefulWidget {
  final Capsule capsule;
  final Function(Capsule) onUpdate; // Callback for updating the capsule

  const TimeCapsuleDetailsScreen(
      {super.key, required this.capsule, required this.onUpdate});

  @override
  _TimeCapsuleDetailsScreenState createState() =>
      _TimeCapsuleDetailsScreenState();
}

class _TimeCapsuleDetailsScreenState extends State<TimeCapsuleDetailsScreen> {
  DateTime now = DateTime.now();
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

  Future<void> _selectPhotos() async {
    final List<XFile> selectedImages = await ImagePicker().pickMultiImage(
      imageQuality: 70, // Adjust as needed
    );

    if (selectedImages.isNotEmpty) {
      setState(() {
        capsule.uploadedPhotos
            .addAll(selectedImages.map((image) => image.path));
      });
      widget.onUpdate(capsule);
    }
  }

  Future<void> _addLetter() async {
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
        capsule.letters.add(letter);
      });
      widget.onUpdate(capsule);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.delete),
            onPressed: () {
              Navigator.pop(context, 'delete');
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey, // Light pastel blue color
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
                'Opening Date: ${formattedDate(capsule.date)}', // Use formattedDate function
                style: const TextStyle(fontSize: 18, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              if (capsule.date.isAfter(now))
                const Text(
                  'LOCKED',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount:
                        capsule.uploadedPhotos.length + capsule.letters.length,
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
                          ),
                        );
                      } else {
                        int letterIndex = index - capsule.uploadedPhotos.length;
                        return ListTile(
                          title: Text(
                            'Letter ${letterIndex + 1}',
                            style: const TextStyle(color: Colors.black),
                          ),
                          subtitle: Text(capsule.letters[letterIndex]),
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
        onPressed: () async {
          if (capsule.date.isBefore(now)) {
            final action = await showDialog<String>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Add to Capsule'),
                  content:
                      const Text('Would you like to add photos or a letter?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop('photos');
                      },
                      child: const Text('Add Photos'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop('letter');
                      },
                      child: const Text('Add Letter'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                );
              },
            );

            if (action == 'photos') {
              _selectPhotos();
            } else if (action == 'letter') {
              _addLetter();
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Capsule is locked until the opening date'),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
