import 'package:flutter/material.dart';
import 'localization.dart';

class HomeTab extends StatelessWidget {
  final Function(int) onTabSelected;

  const HomeTab({
    super.key,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final blueColor = const Color(0xFF0284C7);
    final darkSlate = const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Banner Section (With Unsplash Office Background Image and Blue Tint Overlay)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 48),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const NetworkImage(
                    'https://images.unsplash.com/photo-1552664730-d307ca884978?ixlib=rb-4.0.3&auto=format&fit=crop&w=2070&q=80',
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    blueColor.withValues(alpha: 0.85),
                    BlendMode.srcOver,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    Localization.get('hero_title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                      shadows: [
                        Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    Localization.get('hero_desc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 14,
                      height: 1.6,
                      shadows: const [
                        Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Row of Buttons: Launch SignCam (Solid White) next to Start Learning Free (Outlined Transparent)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Launch SignCam Button (White Background, Blue Text, Solid Style)
                      ElevatedButton.icon(
                        onPressed: () => onTabSelected(1), // Switch to SignCam Tab
                        icon: Icon(Icons.camera_alt_rounded, color: blueColor, size: 18),
                        label: Text(
                          Localization.get('hero_btn1'),
                          style: TextStyle(color: blueColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      
                      // Start Learning Free Button (Transparent with White Border)
                      ElevatedButton.icon(
                        onPressed: () => onTabSelected(2), // Switch to Tutorials Tab
                        icon: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
                        label: Text(
                          Localization.get('hero_btn2'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.white, width: 2.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Features Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 36),
                  Text(
                    Localization.get('features_title'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: darkSlate,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Feature Cards
                  _buildFeatureCard(
                    icon: Icons.bolt_rounded,
                    title: Localization.get('feature_fast'),
                    desc: Localization.get('feature_fast_desc'),
                    color: const Color(0xFF0284C7),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.language_rounded,
                    title: Localization.get('feature_lang'),
                    desc: Localization.get('feature_lang_desc'),
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.shield_rounded,
                    title: Localization.get('feature_privacy'),
                    desc: Localization.get('feature_privacy_desc'),
                    color: const Color(0xFFEC4899),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12.withValues(alpha: 0.04)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
