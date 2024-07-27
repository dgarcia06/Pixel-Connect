import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'review_submission.dart';
import 'review_detail.dart';

class TagSearchScreen extends StatefulWidget {
  @override
  _TagSearchScreenState createState() => _TagSearchScreenState();
}

class _TagSearchScreenState extends State<TagSearchScreen> {
  String _searchTag = '';
  List<Review> _searchResults = [];

  void _searchReviewsByTag() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('tags', arrayContains: _searchTag)
        .get();

    var searchedReviews = snapshot.docs
        .map((doc) =>
            Review.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    setState(() {
      _searchResults = searchedReviews;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Reviews by Tag'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                _searchTag = value;
              },
              decoration: InputDecoration(
                labelText: 'Enter a tag',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchReviewsByTag,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final Review review = _searchResults[index];
                return ListTile(
                  title: Text(review.title),
                  subtitle: Row(
                    children: [
                      RatingBarIndicator(
                        rating: review.rating,
                        itemBuilder: (context, index) => const Icon(
                          Icons.emoji_events,
                          color: Colors.blue,
                        ),
                        itemCount: 5,
                        itemSize: 20.0,
                        direction: Axis.horizontal,
                      ),
                      const SizedBox(width: 10),
                      Text('${review.rating}'),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ReviewDetailScreen(review: review),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
