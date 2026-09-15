import 'package:flutter/material.dart';
import 'localization.dart';
import 'alphabet_numbers_lesson.dart';
import 'everyday_conversations_lesson.dart';
import 'advanced_grammar_lesson.dart';

class TutorialsTab extends StatelessWidget {
  const TutorialsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final darkSlate = const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Text(
              Localization.get('tut_main_title'),
              style: TextStyle(
                color: darkSlate,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Lesson Card 1: Alphabet & Numbers
            _buildLessonCard(
              context: context,
              icon: Icons.spellcheck_rounded,
              title: Localization.get('tut_alphabet'),
              desc: Localization.get('tut_alphabet_desc'),
              targetScreen: const AlphabetNumbersLesson(),
              color: const Color(0xFF0284C7),
            ),
            const SizedBox(height: 20),

            // Lesson Card 2: Everyday Conversations
            _buildLessonCard(
              context: context,
              icon: Icons.forum_rounded,
              title: Localization.get('tut_everyday'),
              desc: Localization.get('tut_everyday_desc'),
              targetScreen: const EverydayConversationsLesson(),
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 20),

            // Lesson Card 3: Advanced Grammar
            _buildLessonCard(
              context: context,
              icon: Icons.school_rounded,
              title: Localization.get('tut_advanced'),
              desc: Localization.get('tut_advanced_desc'),
              targetScreen: const AdvancedGrammarLesson(),
              color: const Color(0xFFEC4899),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String desc,
    required Widget targetScreen,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12.withValues(alpha: 0.04)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => targetScreen),
              );
            },
            splashColor: color.withValues(alpha: 0.1),
            highlightColor: color.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        Localization.get('tut_btn1'),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, color: color, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
