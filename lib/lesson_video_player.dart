import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LessonVideoPlayer extends StatefulWidget {
  final String title;
  final String videoUrl;

  const LessonVideoPlayer({
    super.key,
    required this.title,
    required this.videoUrl,
  });

  @override
  State<LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends State<LessonVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    final uri = Uri.parse(widget.videoUrl);
    _controller = VideoPlayerController.networkUrl(uri);

    try {
      await _controller.initialize();
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      debugPrint("Video Player Error: $e");
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skip(int seconds) {
    if (!_initialized) return;
    final currentPos = _controller.value.position;
    final targetPos = currentPos + Duration(seconds: seconds);
    
    if (targetPos < Duration.zero) {
      _controller.seekTo(Duration.zero);
    } else if (targetPos > _controller.value.duration) {
      _controller.seekTo(_controller.value.duration);
    } else {
      _controller.seekTo(targetPos);
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkSlate = const Color(0xFF0F172A);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black12.withValues(alpha: 0.04)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Video aspect ratio box
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_initialized) ...[
                    VideoPlayer(_controller),
                    // Tap to play/pause overlay
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _controller.value.isPlaying ? _controller.pause() : _controller.play();
                        });
                      },
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                    // Controls overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black54, Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Current position / Duration text
                            ValueListenableBuilder(
                              valueListenable: _controller,
                              builder: (context, VideoPlayerValue value, child) {
                                return Text(
                                  "${_formatDuration(value.position)} / ${_formatDuration(value.duration)}",
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                );
                              },
                            ),
                            // Progress bar
                            Expanded(
                              child: Container(
                                height: 4,
                                margin: const EdgeInsets.symmetric(horizontal: 12),
                                child: VideoProgressIndicator(
                                  _controller,
                                  allowScrubbing: true,
                                  colors: const VideoProgressColors(
                                    playedColor: Color(0xFF38BDF8),
                                    bufferedColor: Colors.white24,
                                    backgroundColor: Colors.white10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (_hasError) ...[
                    Container(
                      color: Colors.black12,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                          SizedBox(height: 8),
                          Text(
                            "Failed to load video stream",
                            style: TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      color: Colors.black12,
                      child: const CircularProgressIndicator(
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Title & Playback controller buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: darkSlate,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Button row: -10s, Play/Pause, +10s
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPlaybackButton(
                      icon: Icons.replay_10_rounded,
                      onPressed: () => _skip(-10),
                    ),
                    const SizedBox(width: 20),
                    _buildPlaybackButton(
                      icon: _initialized && _controller.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      isMain: true,
                      onPressed: () {
                        if (!_initialized) return;
                        setState(() {
                          _controller.value.isPlaying ? _controller.pause() : _controller.play();
                        });
                      },
                    ),
                    const SizedBox(width: 20),
                    _buildPlaybackButton(
                      icon: Icons.forward_10_rounded,
                      onPressed: () => _skip(10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isMain = false,
  }) {
    final blueColor = const Color(0xFF0284C7);
    return Container(
      decoration: BoxDecoration(
        color: isMain ? blueColor : Colors.black.withValues(alpha: 0.04),
        shape: BoxShape.circle,
        boxShadow: isMain
            ? [
                BoxShadow(
                  color: blueColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: IconButton(
        icon: Icon(icon, color: isMain ? Colors.white : Colors.black87, size: isMain ? 28 : 20),
        onPressed: onPressed,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
