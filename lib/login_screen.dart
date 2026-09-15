import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'localization.dart';
import 'main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool _isLoading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF0284C7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog(String title, String content) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void submitForm() async {
    final emailVal = emailController.text.trim();
    final passwordVal = passwordController.text.trim();
    final nameVal = nameController.text.trim();

    if (emailVal.isEmpty || passwordVal.isEmpty) {
      _showSnackbar(Localization.currentLanguage == 'en' ? 'Please fill in all fields' : 'براہ کرم تمام فیلڈز پُر کریں');
      return;
    }

    if (!isLogin && nameVal.isEmpty) {
      _showSnackbar(Localization.currentLanguage == 'en' ? 'Please enter your full name' : 'براہ کرم اپنا پورا نام درج کریں');
      return;
    }

    if (!isLogin && passwordVal.length < 6) {
      _showSnackbar(Localization.currentLanguage == 'en' ? 'Password must be at least 6 characters' : 'پاس ورڈ کم از کم 6 حروف کا ہونا چاہیے');
      return;
    }

    if (!isLogin && passwordController.text != confirmPasswordController.text) {
      _showSnackbar(Localization.currentLanguage == 'en' ? 'Passwords do not match' : 'پاس ورڈز مطابقت نہیں رکھتے');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (isLogin) {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailVal,
          password: passwordVal,
        );
        final uid = userCredential.user?.uid;
        if (uid != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            Localization.userName = data['name'] ?? 'User';
            Localization.userEmail = data['email'] ?? emailVal;
          } else {
            Localization.userName = emailVal.split('@').first;
            Localization.userEmail = emailVal;
          }
        }
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainLayout()),
          );
        }
      } else {
        Localization.bypassStream = true;
        
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailVal,
          password: passwordVal,
        );
        final uid = userCredential.user?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'name': nameVal,
            'email': emailVal,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        
        await FirebaseAuth.instance.signOut();
        
        _showSuccessDialog(
          Localization.currentLanguage == 'en' ? 'Registration Successful' : 'رجسٹریشن کامیاب',
          Localization.currentLanguage == 'en' 
              ? 'Your account has been created. Please login now.' 
              : 'آپ کا اکاؤنٹ بن گیا ہے۔ براہ کرم اب لاگ ان کریں۔'
        );

        setState(() {
          isLogin = true;
          nameController.clear();
          passwordController.clear();
          confirmPasswordController.clear();
        });
      }
    } on FirebaseAuthException catch (e) {
      String errMsg = e.message ?? "An error occurred";
      if (e.code == 'user-not-found') errMsg = Localization.currentLanguage == 'en' ? 'No user found for that email.' : 'اس ای میل کے لیے کوئی صارف نہیں ملا۔';
      if (e.code == 'wrong-password') errMsg = Localization.currentLanguage == 'en' ? 'Wrong password provided.' : 'غلط پاس ورڈ فراہم کیا گیا ہے۔';
      if (e.code == 'email-already-in-use') errMsg = Localization.currentLanguage == 'en' ? 'The account already exists for that email.' : 'اس ای میل کا اکاؤنٹ پہلے سے موجود ہے۔';
      _showSnackbar(errMsg);
    } catch (e) {
      _showSnackbar(e.toString());
    } finally {
      Localization.bypassStream = false;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textDir = Localization.textDirection;
    final blueColor = const Color(0xFF0284C7);
    final darkSlate = const Color(0xFF0F172A);

    return Directionality(
      textDirection: textDir,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE0F2FE), Color(0xFFF8FAFC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  // Brand Logo & Heading (Using newly added logo.png asset)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        height: 90,
                        width: 90,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.settings_voice_rounded,
                          size: 64,
                          color: blueColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      Localization.get('brand_name'),
                      style: TextStyle(
                        color: darkSlate,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      isLogin ? Localization.get('welcome_back') : Localization.get('create_account'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tab switcher (Login vs SignUp)
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isLogin = true),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isLogin ? blueColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: isLogin
                                    ? [
                                        BoxShadow(
                                          color: blueColor.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                Localization.get('login'),
                                style: TextStyle(
                                  color: isLogin ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isLogin = false),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: !isLogin ? blueColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: !isLogin
                                    ? [
                                        BoxShadow(
                                          color: blueColor.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                Localization.get('signup'),
                                style: TextStyle(
                                  color: !isLogin ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Container Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isLogin) ...[
                          // Full Name (Only for signup)
                          TextField(
                            controller: nameController,
                            style: TextStyle(color: darkSlate),
                            decoration: InputDecoration(
                              labelText: Localization.get('full_name'),
                              labelStyle: const TextStyle(color: Colors.black54),
                              prefixIcon: Icon(Icons.person_outline, color: blueColor),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.02),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: blueColor, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email Field
                        TextField(
                          controller: emailController,
                          style: TextStyle(color: darkSlate),
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: Localization.get('email'),
                            labelStyle: const TextStyle(color: Colors.black54),
                            prefixIcon: Icon(Icons.mail_outline_rounded, color: blueColor),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.02),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: blueColor, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextField(
                          controller: passwordController,
                          style: TextStyle(color: darkSlate),
                          obscureText: !showPassword,
                          decoration: InputDecoration(
                            labelText: Localization.get('password'),
                            labelStyle: const TextStyle(color: Colors.black54),
                            prefixIcon: Icon(Icons.lock_outline_rounded, color: blueColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: Colors.black45,
                              ),
                              onPressed: () => setState(() => showPassword = !showPassword),
                            ),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.02),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: blueColor, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (!isLogin) ...[
                          // Confirm Password (Only for signup)
                          TextField(
                            controller: confirmPasswordController,
                            style: TextStyle(color: darkSlate),
                            obscureText: !showConfirmPassword,
                            decoration: InputDecoration(
                              labelText: Localization.get('confirm_password'),
                              labelStyle: const TextStyle(color: Colors.black54),
                              prefixIcon: Icon(Icons.lock_reset_rounded, color: blueColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: Colors.black45,
                                ),
                                onPressed: () => setState(() => showConfirmPassword = !showConfirmPassword),
                              ),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.02),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: blueColor, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Forgot Password (Only for login)
                        if (isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _resetPassword,
                              child: Text(
                                Localization.get('forgot_password'),
                                style: TextStyle(color: blueColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blueColor,
                            shadowColor: blueColor.withValues(alpha: 0.3),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isLogin ? Localization.get('login') : Localization.get('signup'),
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggle Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLogin ? Localization.get('no_account') : Localization.get('have_account'),
                        style: const TextStyle(color: Colors.black54),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => isLogin = !isLogin),
                        child: Text(
                          isLogin ? Localization.get('signup') : Localization.get('login'),
                          style: TextStyle(
                            color: blueColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  void _resetPassword() async {
    final emailResetController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final blueColor = const Color(0xFF0284C7);
        final darkSlate = const Color(0xFF0F172A);
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            Localization.currentLanguage == 'en' ? 'Reset Password' : 'پاس ورڈ دوبارہ ترتیب دیں',
            style: TextStyle(color: darkSlate, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                Localization.currentLanguage == 'en'
                    ? 'Enter your registered email address to receive a password reset link.'
                    : 'پاس ورڈ دوبارہ ترتیب دینے کا لنک حاصل کرنے کے لیے اپنا رجسٹرڈ ای میل درج کریں۔',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailResetController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: darkSlate),
                decoration: InputDecoration(
                  labelText: Localization.get('email'),
                  labelStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: Icon(Icons.email_outlined, color: blueColor),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.02),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: blueColor, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                Localization.currentLanguage == 'en' ? 'Cancel' : 'منسوخ کریں',
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailResetController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(Localization.currentLanguage == 'en' ? 'Please enter email' : 'براہ کرم ای میل درج کریں')),
                  );
                  return;
                }
                Navigator.pop(context);
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  _showSuccessDialog(
                    Localization.currentLanguage == 'en' ? 'Email Sent' : 'ای میل بھیج دی گئی',
                    Localization.currentLanguage == 'en'
                        ? 'Password reset link sent to your email.'
                        : 'آپ کے ای میل پر پاس ورڈ دوبارہ ترتیب دینے کا لنک بھیج دیا گیا ہے۔',
                  );
                } catch (e) {
                  _showSnackbar(e.toString());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: blueColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                Localization.currentLanguage == 'en' ? 'Send Link' : 'لنک بھیجیں',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
  }

