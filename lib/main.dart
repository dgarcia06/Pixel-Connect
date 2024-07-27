import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'firebase_options.dart';
import 'review_submission.dart';
import 'review_detail.dart';
import 'sign_in_screen.dart';
import 'tag_search.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(PixelConnect());
}

class PixelConnect extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return SignInScreen();
          } else {
            return Home();
          }
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pixel Connect'),
        leading: IconButton(
          icon: const Icon(Icons.gamepad),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => SignInScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => TagSearchScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Review> reviews = snapshot.data!.docs
              .map((doc) => Review.fromFirestore(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          return ReviewList(reviews: reviews);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddReviewScreen(
                onReviewAdded: (Review newReview) {},
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ReviewList extends StatelessWidget {
  final List<Review> reviews;

  const ReviewList({required this.reviews});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Column(
          children: [
            ListTile(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ReviewDetailScreen(review: review),
                  ),
                );
              },
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8.0,
                    children: review.tags
                        .map((tag) => Chip(label: Text(tag)))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(review.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text('${review.displayName} - ${review.timestamp}'),
                  const SizedBox(height: 20),
                  RatingBarIndicator(
                    rating: review.rating,
                    itemBuilder: (context, _) => const Icon(
                      Icons.emoji_events,
                      color: Colors.blue,
                    ),
                    itemCount: 5,
                    itemSize: 20.0,
                    direction: Axis.horizontal,
                  ),
                  const SizedBox(height: 20),
                  Text(review.bodies),
                  const SizedBox(height: 20),
                  if (review.imageUrl != null) Image.network(review.imageUrl!),
                  const SizedBox(height: 20),
                  if (review.videoUrl != null)
                    ReviewVideoPlayer(videoUrl: review.videoUrl!),
                ],
              ),
            ),
            if (index < reviews.length - 1) const Divider(color: Colors.blue),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:mobileapp/SocialMedia/create_post.dart';
import 'package:mobileapp/platforms/sidemenu.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({Key? key, required List<Post> posts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.red[400],
        title: const Text('BELLBOARD FEED', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: const SideMenu(),
      body: FutureBuilder<List<Post>>(
        future: FirestoreService().getPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<Post>? posts = snapshot.data;

            if (posts == null || posts.isEmpty) {
              return Center(child: Text('No posts available'));
            }

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return _buildPostItem(post);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildPostItem(Post post) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (post.imageUrl != null)
              Image.network(
                post.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            if (post.videoUrl != null)
              _buildVideoPlayer(post.videoUrl!),
            const SizedBox(height: 8),
            Text(
              post.caption,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(String videoUrl) {
    return FutureBuilder<VideoPlayerController>(
      future: _initializeVideoPlayer(videoUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading video'));
        } else if (snapshot.hasData) {
          final VideoPlayerController controller = snapshot.data!;
          return AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          );
        } else {
          return Center(child: Text('Video not available'));
        }
      },
    );
  }

  Future<VideoPlayerController> _initializeVideoPlayer(String videoUrl) async {
    final firebase_storage.Reference ref =
        firebase_storage.FirebaseStorage.instance.ref(videoUrl);
    final downloadUrl = await ref.getDownloadURL();
    final controller = VideoPlayerController.network(downloadUrl);
    await controller.initialize();
    return controller;
  }
}

