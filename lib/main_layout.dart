import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'localization.dart';
import 'home_tab.dart';
import 'signcam_tab.dart';
import 'tutorials_tab.dart';
import 'profile_tab.dart';
import 'login_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Localization.userName = 'Guest User';
      Localization.userEmail = 'guest@signspeak.online';
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Logout error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final blueColor = const Color(0xFF0284C7);
    final darkSlate = const Color(0xFF0F172A);

    return ValueListenableBuilder<String>(
      valueListenable: Localization.appLanguageNotifier,
      builder: (context, langCode, child) {
        final textDir = Localization.textDirection;

        final List<Widget> tabs = [
          HomeTab(onTabSelected: _changeTab),
          const SignCamTab(),
          const TutorialsTab(),
          ProfileTab(onTabSelected: _changeTab),
        ];

        return Directionality(
          textDirection: textDir,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              shadowColor: Colors.black12,
              iconTheme: IconThemeData(color: darkSlate),
              title: Row(
                children: [
                  Image.asset('assets/logo.png', height: 32, width: 32, fit: BoxFit.contain),
                  const SizedBox(width: 10),
                  Text(
                    Localization.get('brand_name'),
                    style: TextStyle(
                      color: darkSlate,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              actions: [
                // Language Dropdown Selector - Displayed ONLY when on the Home Tab (index 0)
                if (_currentIndex == 0)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: Colors.white,
                        value: Localization.currentLanguage,
                        icon: Icon(Icons.keyboard_arrow_down, color: darkSlate.withValues(alpha: 0.7), size: 18),
                        items: const [
                          DropdownMenuItem(
                            value: 'en',
                            child: Text('EN', style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          DropdownMenuItem(
                            value: 'ur',
                            child: Text('اردو', style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          DropdownMenuItem(
                            value: 'sd',
                            child: Text('سنڌي', style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          DropdownMenuItem(
                            value: 'ar',
                            child: Text('AR', style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            Localization.changeLanguage(val);
                          }
                        },
                      ),
                    ),
                  ),

                // Profile Popup Menu
                PopupMenuButton<String>(
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundColor: blueColor.withValues(alpha: 0.1),
                    child: Icon(Icons.person, color: blueColor, size: 20),
                  ),
                  color: Colors.white,
                  onSelected: (value) {
                    if (value == 'logout') {
                      _logout();
                    } else if (value == 'profile') {
                      _changeTab(3);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Row(
                        children: [
                          Icon(Icons.account_circle, color: darkSlate.withValues(alpha: 0.5), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            Localization.userName == 'Guest User'
                                ? Localization.get('guest')
                                : Localization.userName,
                            style: TextStyle(color: darkSlate, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.face_rounded, color: blueColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            Localization.get('profile_title'),
                            style: TextStyle(color: darkSlate, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(Icons.exit_to_app, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            Localization.get('logout_btn'),
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: tabs[_currentIndex],
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _changeTab,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: blueColor,
                unselectedItemColor: Colors.black45,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontSize: 11),
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined),
                    activeIcon: const Icon(Icons.home_rounded),
                    label: Localization.get('nav_home'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.camera_alt_outlined),
                    activeIcon: const Icon(Icons.camera_alt_rounded),
                    label: Localization.get('nav_signcam'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.menu_book_outlined),
                    activeIcon: const Icon(Icons.menu_book_rounded),
                    label: Localization.get('nav_tutorials'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person_outline_rounded),
                    activeIcon: const Icon(Icons.person_rounded),
                    label: Localization.get('profile_title'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
