import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'review_submission.dart';

class ReviewDetailScreen extends StatefulWidget {
  final Review review;

  const ReviewDetailScreen({required this.review});

  @override
  _ReviewDetailScreenState createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  VideoPlayerController? _videoController;
  final TextEditingController _commentController = TextEditingController();
  bool _isCommenting = false;
  bool _isPlaying = false;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();

    if (widget.review.videoUrl != null) {
      _videoController = VideoPlayerController.network(widget.review.videoUrl!)
        ..initialize().then((_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _addComment() async {
    final String commentText = _commentController.text.trim();
    final User? user = FirebaseAuth.instance.currentUser;

    if (commentText.isNotEmpty && user != null) {
      String displayName = user.displayName ?? user.email ?? 'Anonymous';
      Map<String, String> newComment = {
        'text': commentText,
        'user': displayName,
      };

      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.review.id)
          .update({
        'comments': FieldValue.arrayUnion([newComment])
      });

      setState(() {
        widget.review.comments.add(newComment);
      });

      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Review Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.review.title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text('${widget.review.displayName} - ${widget.review.timestamp}',
                style: const TextStyle(color: Colors.black)),
            const SizedBox(height: 20),
            RatingBarIndicator(
              rating: widget.review.rating,
              itemBuilder: (context, _) => const Icon(
                Icons.emoji_events,
                color: Colors.blue,
              ),
              itemCount: 5,
              itemSize: 20.0,
              direction: Axis.horizontal,
            ),
            const SizedBox(height: 20),
            Text(widget.review.bodies),
            const SizedBox(height: 20),
            if (widget.review.imageUrl != null)
              Image.network(widget.review.imageUrl!),
            if (widget.review.videoUrl != null &&
                _videoController != null &&
                _videoController!.value.isInitialized)
              GestureDetector(
                onTap: () {
                  if (!_isPlaying) {
                    _videoController!.play();
                    setState(() {
                      _isPlaying = true;
                    });
                  } else {
                    _videoController!.pause();
                    setState(() {
                      _isPlaying = false;
                    });
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                    if (!_isPlaying)
                      const Icon(Icons.play_circle_outline,
                          size: 64, color: Colors.white),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    _isLiked
                        ? Icons.videogame_asset
                        : Icons.videogame_asset_outlined,
                    color: _isLiked ? Colors.blue : Colors.blue,
                    size: 35,
                  ),
                  onPressed: () {
                    setState(() {
                      _isLiked = !_isLiked;
                    });
                  },
                ),
                const Text(
                  'Favorite Review',
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                )
              ],
            ),
            if (_isCommenting)
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: 'Add a comment...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _addComment,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _isCommenting = true),
              child: const Text('Add Comment'),
            ),
            const SizedBox(height: 16),
            const Text('Comments',
                style: TextStyle(fontWeight: FontWeight.bold)),
            for (final comment in widget.review.comments)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('${comment['user']}: ${comment['text']}'),
              ),
          ],
        ),
      ),
    );
  }
}
