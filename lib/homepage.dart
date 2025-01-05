import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late StreamSubscription _intentSub;
  String _videoUrl = ''; // Holds the video URL

  @override
  void initState() {
    super.initState();

    // Listen for shared media or URLs
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      for (var file in value) {
        if (file.type == SharedMediaType.text) {
          final sharedText = file.path;
          if (sharedText.contains('youtube.com/watch?v=')) {
            final videoId = _extractVideoId(sharedText);
            final newUrl =
                'https://www.gameyoutube.com/watch?v=$videoId'; // Construct the gameyoutube URL
            setState(() {
              _videoUrl = newUrl;
            });
            openAppWebView(newUrl); // Open the custom URL
          }
        }
      }
    }, onError: (err) {
      print("getMediaStream error: $err");
    });

    // Check if there is initial shared content (when app is launched with shared data)
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty) {
        for (var file in value) {
          if (file.type == SharedMediaType.text) {
            final sharedText = file.path;
            if (sharedText.contains('youtube.com/watch?v=')) {
              final videoId = _extractVideoId(sharedText);
              final newUrl =
                  'https://www.gameyoutube.com/watch?v=$videoId'; // Construct the gameyoutube URL
              setState(() {
                _videoUrl = newUrl;
              });
              openAppWebView(newUrl); // Open the custom URL
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _intentSub.cancel();
    super.dispose();
  }

  // Function to extract YouTube video ID from URL
  String _extractVideoId(String url) {
    final Uri uri = Uri.parse(url);
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'] ?? '';
    } else if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : '';
    }
    return ''; // Return an empty string if it's not a valid YouTube URL
  }

  // Function to open the custom gameyoutube URL in app's WebView
  Future<void> openAppWebView(String url) async {
    try {
      if (!await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      // Handle error (could show a dialog or a snackbar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open URL: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _videoUrl.isEmpty
            ? const Text('Waiting for shared URL...')
            : Text('Opening: $_videoUrl'),
      ),
    );
  }
}
