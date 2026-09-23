import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashVideoBackground extends StatefulWidget {
  const SplashVideoBackground({super.key});

  @override
  State<SplashVideoBackground> createState() => _SplashVideoBackgroundState();
}

class _SplashVideoBackgroundState extends State<SplashVideoBackground> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/videos/splash_fluid_background.mp4',
    );
    _initialization = _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    await _controller.initialize();
    await _controller.setLooping(true);
    await _controller.setVolume(0);
    await _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError ||
            !_controller.value.isInitialized) {
          return const ColoredBox(
            color: Color(0xFFF5F9FF),
          );
        }

        final videoSize = _controller.value.size;

        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: videoSize.width,
              height: videoSize.height,
              child: VideoPlayer(_controller),
            ),
          ),
        );
      },
    );
  }
}
