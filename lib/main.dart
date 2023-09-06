import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RandomImageList(),
    );
  }
}

class RandomImageList extends StatefulWidget {
  @override
  _RandomImageListState createState() => _RandomImageListState();
}

class _RandomImageListState extends State<RandomImageList> {
  late Future<List<String>> _images;

  @override
  void initState() {
    super.initState();
    _images = getCachedImages().then((cachedImages) {
      if (cachedImages != null && cachedImages.isNotEmpty) {
        return cachedImages;
      } else {
        return fetchAndCacheImages(10); // Load from cache or fetch new images
      }
    });
  }

  Future<List<String>?> getCachedImages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? cachedImages = prefs.getStringList('cached_images');
    return cachedImages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Image Caching'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<String>>(
        future: _images,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a single common progress indicator at the center
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            final images = snapshot.data;
            if (images != null) {
              return ImageList(images: images);
            } else {
              return const Center(
                child: Text('No images found.'),
              );
            }
          }
        },
      ),
    );
  }
}

class ImageList extends StatelessWidget {
  final List<String> images;

  ImageList({required this.images});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: images.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: images[index],
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) {
              // Use an empty container as a placeholder
              return Container();
            },
            errorWidget: (context, url, error) => Icon(Icons.error),
            // Use a consistent cache key
            cacheKey: images[index],
          ),
        );
      },
    );
  }
}

Future<List<String>> fetchAndCacheImages(int count) async {
  const String apiKey = 'mGAoL9Vcf_SuMcfasu_9L33MXgb09lCOOrud7r9ppp4';
  const String apiUrl = 'https://api.unsplash.com/photos/random';
  final Uri uri = Uri.parse('$apiUrl?client_id=$apiKey&count=$count');
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    final imageUrls = List<String>.from(data.map((item) => item['urls']['regular']));

    // Store image URLs in shared preferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('cached_images', imageUrls);

    return imageUrls;
  } else {
    throw Exception('Failed to load random images. Status code: ${response.statusCode}');
  }
}
