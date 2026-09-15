import 'package:flutter/material.dart';
import 'localization.dart';
import 'lesson_video_player.dart';

class EverydayConversationsLesson extends StatelessWidget {
  const EverydayConversationsLesson({super.key});

  @override
  Widget build(BuildContext context) {
    final textDir = Localization.textDirection;
    final darkSlate = const Color(0xFF0F172A);

    return Directionality(
      textDirection: textDir,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black12,
          iconTheme: IconThemeData(color: darkSlate),
          title: Text(
            Localization.get('tut_everyday'),
            style: TextStyle(color: darkSlate, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  Localization.get('tut_everyday_header'),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Video players
              LessonVideoPlayer(
                title: Localization.get('tut_video_basic'),
                videoUrl: 'https://signspeak.online/Conversations1.mp4',
              ),
              LessonVideoPlayer(
                title: Localization.get('tut_video_first'),
                videoUrl: 'https://signspeak.online/Conversations2.mp4',
              ),
              LessonVideoPlayer(
                title: Localization.get('tut_video_family'),
                videoUrl: 'https://signspeak.online/Conversations3.mp4',
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
