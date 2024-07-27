import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final List<String> tags;
  final String title;
  final String displayName;
  final String timestamp;
  final String bodies;
  final String? imageUrl;
  final String? videoUrl;
  final double rating;
  List<Map<String, String>> comments;

  Review({
    this.id = '',
    required this.tags,
    required this.title,
    required this.displayName,
    required this.timestamp,
    required this.bodies,
    this.imageUrl,
    this.videoUrl,
    required this.rating,
    required this.comments,
  });

  factory Review.fromFirestore(Map<String, dynamic> firestore, String id) {
    return Review(
      id: id,
      tags: List<String>.from(firestore['tags'] ?? []),
      title: firestore['title'] ?? '',
      displayName: firestore['displayName'] ?? '',
      timestamp: firestore['timestamp'] ?? '',
      bodies: firestore['bodies'] ?? '',
      imageUrl: firestore['imageUrl'],
      videoUrl: firestore['videoUrl'],
      rating: (firestore['rating'] as num?)?.toDouble() ?? 0.0,
      comments: (firestore['comments'] as List<dynamic>? ?? [])
          .map((c) => Map<String, String>.from(c))
          .toList(),
    );
  }
}

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadMedia(XFile file, String folder) async {
    File fileToUpload = File(file.path);
    try {
      String filePath =
          '$folder/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      TaskSnapshot uploadTask =
          await _storage.ref(filePath).putFile(fileToUpload);
      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      print(e);
      return null;
    }
  }
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addReview(Review review) async {
    await _db.collection('reviews').add({
      'tags': review.tags,
      'title': review.title,
      'displayName': review.displayName,
      'timestamp': review.timestamp,
      'bodies': review.bodies,
      'imageUrl': review.imageUrl,
      'videoUrl': review.videoUrl,
      'rating': review.rating,
      'comments': review.comments,
    });
  }
}

class AddReviewButton extends StatelessWidget {
  final Function(Review) onReviewAdded;

  const AddReviewButton({required this.onReviewAdded});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return AddReviewScreen(onReviewAdded: onReviewAdded);
            },
          ),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}

class AddReviewScreen extends StatefulWidget {
  final Function(Review) onReviewAdded;

  const AddReviewScreen({required this.onReviewAdded});

  @override
  _AddReviewScreenState createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final TextEditingController tagsController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();

  XFile? _image;
  XFile? _video;
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoController;
  double _ratingScore = 0;

  Future getImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = pickedFile;
      } else {
        print('No image selected.');
      }
    });
  }

  Future getVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _video = pickedFile;
        _videoController = VideoPlayerController.file(File(_video!.path))
          ..initialize().then((_) {
            setState(() {});
            _videoController!.play();
          });
      } else {
        print('No video selected.');
      }
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Add a Review'),
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                      labelText: 'Tags (comma-separated)'),
                ),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: bodyController,
                  decoration: const InputDecoration(labelText: 'Body Text'),
                  maxLines: null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: getImage,
                  child: const Text('Pick Image'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: getVideo,
                  child: const Text('Pick Video'),
                ),
                if (_image != null)
                  Image.file(
                    File(_image!.path),
                    height: 200,
                    width: 200,
                  ),
                if (_video != null)
                  Container(
                    height: 200,
                    width: 200,
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                const SizedBox(height: 20),
                RatingBar.builder(
                  initialRating: _ratingScore,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => Icon(
                    Icons.emoji_events,
                    color: Colors.blue[200],
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _ratingScore = rating;
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final tagsList = tagsController.text
                        .split(',')
                        .map((tag) => tag.trim())
                        .where((tag) => tag.isNotEmpty)
                        .toList();
                    final reviewText = titleController.text;
                    final bodyText = bodyController.text;
                    if (reviewText.isNotEmpty && bodyText.isNotEmpty) {
                      User? user = FirebaseAuth.instance.currentUser;
                      String displayName = user?.displayName ?? 'Anonymous';
                      String? imageUrl;
                      String? videoUrl;

                      if (_image != null) {
                        imageUrl = await StorageService()
                            .uploadMedia(_image!, 'review_images');
                      }

                      if (_video != null) {
                        videoUrl = await StorageService()
                            .uploadMedia(_video!, 'review_videos');
                      }

                      final review = Review(
                        tags: tagsList,
                        title: reviewText,
                        displayName: displayName,
                        timestamp: DateTime.now().toIso8601String(),
                        bodies: bodyText,
                        imageUrl: imageUrl,
                        videoUrl: videoUrl,
                        rating: _ratingScore,
                        comments: [],
                      );

                      await FirestoreService().addReview(review);
                      widget.onReviewAdded(review);
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Title and body cannot be empty.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Submit Review'),
                ),
              ],
            ),
          ),
        ));
  }
}
