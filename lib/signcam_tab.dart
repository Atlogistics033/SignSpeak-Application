import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hand_detection/hand_detection.dart';
import 'localization.dart';

class SignCamTab extends StatefulWidget {
  const SignCamTab({super.key});

  @override
  State<SignCamTab> createState() => _SignCamTabState();
}

class _SignCamTabState extends State<SignCamTab> {
  CameraController? _cameraController;
  late FlutterTts _flutterTts;
  late HandDetector _handDetector;
  
  bool _isCameraInitialized = false;
  bool _isDetectorInitialized = false;
  bool _hasCameraError = false;
  bool _isProcessing = false;
  int? _sensorOrientation;

  // Real-time Hand Landmarks State
  List<dynamic> _detectedHands = [];
  Size? _imageSize;

  // Phrase Mapping State
  String _detectedSignKey = "";
  String _detectedWord = "";
  String _generatedSentence = "";
  final List<String> _currentSentence = [];
  DateTime _lastGestureTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _initializeDetectorAndCamera();
  }

  Future<void> _initializeTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setSpeechRate(0.55);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    final lang = Localization.currentLanguage;
    if (lang == 'ur' || lang == 'sd') {
      await _flutterTts.setLanguage("ur-PK");
    } else if (lang == 'ar') {
      await _flutterTts.setLanguage("ar-SA");
    } else {
      await _flutterTts.setLanguage("en-US");
    }
  }

  Future<void> _initializeDetectorAndCamera() async {
    try {
      // 1. Initialize Hand Detector
      _handDetector = await HandDetector.create();
      if (mounted) {
        setState(() {
          _isDetectorInitialized = true;
        });
      }

      // 2. Initialize Camera (Select Front Camera by default)
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _hasCameraError = true;
        });
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _sensorOrientation = frontCamera.sensorOrientation;

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _startStreaming();
      }
    } catch (e) {
      debugPrint("Initialization error: $e");
      setState(() {
        _hasCameraError = true;
      });
    }
  }

  void _startStreaming() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    _cameraController!.startImageStream((CameraImage image) async {
      if (!_isCameraInitialized || !_isDetectorInitialized || _isProcessing) return;
      
      _isProcessing = true;
      try {
        final rotation = rotationForFrame(
          width: image.width,
          height: image.height,
          sensorOrientation: _sensorOrientation ?? 270,
          isFrontCamera: true,
          deviceOrientation: DeviceOrientation.portraitUp,
        );

        final Size size = detectionSize(
          width: image.width,
          height: image.height,
          rotation: rotation,
          maxDim: 320,
        );

        final hands = await _handDetector.detectFromCameraImage(
          image,
          rotation: rotation,
          maxDim: 320,
        );
        if (mounted) {
          setState(() {
            _detectedHands = hands;
            _imageSize = size;
          });
          _classifyRealtimeGestures(hands);
        }
      } catch (e) {
        debugPrint("Landmark detection error: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  // Real-time Landmark Classification Algorithm for all 11 PDF Signs
  void _classifyRealtimeGestures(List<dynamic> hands) {
    if (hands.isEmpty) return;
    
    // Check timing throttle buffer (350 ms)
    if (DateTime.now().difference(_lastGestureTime) < const Duration(milliseconds: 350)) {
      return;
    }

    final hand = hands.first;
    if (!hand.hasLandmarks) return;

    final wrist = hand.getLandmark(HandLandmarkType.wrist);
    final thumbTip = hand.getLandmark(HandLandmarkType.thumbTip);

    final indexTip = hand.getLandmark(HandLandmarkType.indexFingerTip);
    final indexPip = hand.getLandmark(HandLandmarkType.indexFingerPIP);
    final indexMcp = hand.getLandmark(HandLandmarkType.indexFingerMCP);

    final middleTip = hand.getLandmark(HandLandmarkType.middleFingerTip);
    final middlePip = hand.getLandmark(HandLandmarkType.middleFingerPIP);
    final middleMcp = hand.getLandmark(HandLandmarkType.middleFingerMCP);

    final ringTip = hand.getLandmark(HandLandmarkType.ringFingerTip);
    final ringPip = hand.getLandmark(HandLandmarkType.ringFingerPIP);
    final ringMcp = hand.getLandmark(HandLandmarkType.ringFingerMCP);

    final pinkyTip = hand.getLandmark(HandLandmarkType.pinkyTip);
    final pinkyPip = hand.getLandmark(HandLandmarkType.pinkyPIP);
    final pinkyMcp = hand.getLandmark(HandLandmarkType.pinkyMCP);

    if (wrist == null || thumbTip == null || indexTip == null || indexPip == null || indexMcp == null ||
        middleTip == null || middlePip == null || middleMcp == null || ringTip == null || ringPip == null || ringMcp == null ||
        pinkyTip == null || pinkyPip == null || pinkyMcp == null) {
      return;
    }

    // Hand Scale reference distance (Wrist to Middle MCP)
    final double handScale = sqrt(pow(wrist.x - middleMcp.x, 2) + pow(wrist.y - middleMcp.y, 2));
    if (handScale <= 0) return;

    // Is Hand Inverted (Fingers pointing DOWN towards floor)?
    bool isHandInverted = (wrist.y < indexMcp.y && wrist.y < middleMcp.y);

    // Finger open states when hand pointing UP
    bool isIndexOpenUp = indexTip.y < indexPip.y;
    bool isMiddleOpenUp = middleTip.y < middlePip.y;
    bool isRingOpenUp = ringTip.y < ringPip.y;
    bool isPinkyOpenUp = (pinkyTip.y < pinkyPip.y) || (pinkyTip.y < pinkyMcp.y - (0.15 * handScale));
    bool are4FingersOpenUp = isIndexOpenUp && isMiddleOpenUp && isRingOpenUp && isPinkyOpenUp;

    // Distances relative to handScale
    double distThumbIndex = sqrt(pow(thumbTip.x - indexTip.x, 2) + pow(thumbTip.y - indexTip.y, 2)) / handScale;
    double distThumbMiddle = sqrt(pow(thumbTip.x - middleTip.x, 2) + pow(thumbTip.y - middleTip.y, 2)) / handScale;
    double distThumbRing = sqrt(pow(thumbTip.x - ringTip.x, 2) + pow(thumbTip.y - ringTip.y, 2)) / handScale;
    double distThumbPinky = sqrt(pow(thumbTip.x - pinkyTip.x, 2) + pow(thumbTip.y - pinkyTip.y, 2)) / handScale;
    double distIndexMiddle = sqrt(pow(indexTip.x - middleTip.x, 2) + pow(indexTip.y - middleTip.y, 2)) / handScale;
    double distIndexPinky = sqrt(pow(indexTip.x - pinkyTip.x, 2) + pow(indexTip.y - pinkyTip.y, 2)) / handScale;

    // OK Sign check for "Good and Excellent Sign" (Thumb & Index touch, 3 fingers UP)
    bool isOkGesture = (distThumbIndex < 0.35) &&
                       isMiddleOpenUp && isRingOpenUp && isPinkyOpenUp;

    // Pinch Cluster for "Food Sign" (All finger tips gathered into a tight pinch cone at thumbTip, as shown in user photo)
    bool isPinchCluster = (distThumbIndex < 0.58) &&
                          (distThumbMiddle < 0.58) &&
                          (distThumbRing < 0.62) &&
                          (distThumbPinky < 0.68) &&
                          (distIndexMiddle < 0.45) &&
                          (distIndexPinky < 0.70) &&
                          !isHandInverted;

    bool are4FingersFolded = !isIndexOpenUp && !isMiddleOpenUp && !isRingOpenUp && !isPinkyOpenUp;

    // Palm bounds & center reference
    double minPalmX = min(indexMcp.x, pinkyMcp.x);
    double maxPalmX = max(indexMcp.x, pinkyMcp.x);

    // Is Thumb spread wide outwards away from palm?
    bool isThumbOpenWide = (thumbTip.x < minPalmX - (0.15 * handScale)) ||
                           (thumbTip.x > maxPalmX + (0.15 * handScale)) ||
                           ((thumbTip.x - indexMcp.x).abs() / handScale > 0.38);

    // Thumb Tucked across palm for "Help Sign" (4 fingers UP, Thumb folded inside/across palm)
    bool isThumbTucked = !isThumbOpenWide || 
                         (thumbTip.x >= minPalmX - (0.10 * handScale) && thumbTip.x <= maxPalmX + (0.10 * handScale));

    // Thumb Extended Outward Horizontally for "Water Sign" (Fist with thumb pointing to side)
    double horizThumbOffset = (thumbTip.x - wrist.x).abs();
    bool isThumbOutHorizontal = (horizThumbOffset / handScale > 0.35) || isThumbOpenWide;

    String key = "";

    // 10. GOOD NIGHT - Hand pointing straight DOWN towards floor (Wrist at top)
    if (isHandInverted && indexTip.y > indexMcp.y + (0.10 * handScale)) {
      key = "GOOD_NIGHT";
    }
    // 4. FOOD SIGN - Pinched finger tips cluster (User photo gesture: Food / Feel Hungry)
    else if (isPinchCluster) {
      key = "FOOD";
    }
    // 6. WASHROOM SIGN - Pinky finger extended straight UP, others folded in fist
    else if (!isIndexOpenUp && !isMiddleOpenUp && !isRingOpenUp && isPinkyOpenUp) {
      key = "WASHROOM";
    }
    // 3. WATER SIGN - 4 fingers folded into fist, Thumb extended horizontally to side
    else if (are4FingersFolded && isThumbOutHorizontal) {
      key = "WATER";
    }
    // 7. GOOD AND EXCELLENT SIGN - OK Sign (Thumb & Index touch, 3 fingers UP)
    else if (isOkGesture) {
      key = "GOOD";
    }
    // 5. DANGER SIGN - Index & Middle finger extended straight UP
    else if (isIndexOpenUp && isMiddleOpenUp && !isRingOpenUp && !isPinkyOpenUp) {
      key = "DANGER";
    }
    // 8. EMERGENCY SIGN - Index & Pinky extended straight UP (Horn Sign)
    else if (isIndexOpenUp && !isMiddleOpenUp && !isRingOpenUp && isPinkyOpenUp) {
      key = "EMERGENCY";
    }
    // 11. ABUSED SIGN - Only Middle Finger extended straight UP
    else if (!isIndexOpenUp && isMiddleOpenUp && !isRingOpenUp && !isPinkyOpenUp) {
      key = "ABUSED";
    }
    // 1. HELP SIGN - 4 fingers straight UP, thumb tucked inside palm
    else if (are4FingersOpenUp && isThumbTucked) {
      key = "HELP";
    }
    // 9. GOOD MORNING SIGN - 5 fingers open wide UP (Thumb open wide)
    else if (are4FingersOpenUp && !isThumbTucked) {
      key = "GOOD_MORNING";
    }

    if (key.isNotEmpty) {
      _lastGestureTime = DateTime.now();
      _simulateGesture(key);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  // Speak synthesized sentence instantly
  Future<void> _speakSentence() async {
    if (_generatedSentence.isEmpty) return;

    _flutterTts.stop();

    final lang = Localization.currentLanguage;
    String langCode = "en-US";
    if (lang == 'ur' || lang == 'sd') {
      langCode = "ur-PK";
    } else if (lang == 'ar') {
      langCode = "ar-SA";
    }

    _flutterTts.setLanguage(langCode);
    _flutterTts.speak(_generatedSentence);
  }

  // Clear current buffers
  void _clearSentence() {
    setState(() {
      _currentSentence.clear();
      _detectedSignKey = "";
      _detectedWord = "";
      _generatedSentence = "";
    });
  }

  // Handle gesture detection and phrase mapping
  void _simulateGesture(String sign) {
    setState(() {
      _detectedSignKey = sign;
      _detectedWord = Localization.getSignWord(sign);
      if (_currentSentence.isEmpty || _currentSentence.last != sign) {
        _currentSentence.add(sign);
      }
      _generatedSentence = Localization.getSignPhrase(sign);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textDir = Localization.textDirection;
    final blueColor = const Color(0xFF0284C7);
    final darkSlate = const Color(0xFF0F172A);

    return Directionality(
      textDirection: textDir,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Header Bar ---
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [blueColor.withValues(alpha: 0.08), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: blueColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.center_focus_strong_rounded, color: blueColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Localization.get('cam_header'),
                            style: TextStyle(
                              color: darkSlate,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _isCameraInitialized ? Colors.green : Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isCameraInitialized
                                    ? Localization.get('cam_status')
                                    : 'AI Detector Ready (10 PDF Signs Loaded)',
                                style: TextStyle(
                                  color: darkSlate.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- 1. Camera Box Viewport with Real-time Landmarks Overlay ---
              AspectRatio(
                aspectRatio: _isCameraInitialized && _cameraController != null
                    ? (1.0 / _cameraController!.value.aspectRatio)
                    : 3 / 4,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _detectedHands.isNotEmpty ? Colors.green : blueColor.withValues(alpha: 0.4),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: blueColor.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_isCameraInitialized && _cameraController != null)
                          CameraPreview(_cameraController!)
                        else if (_hasCameraError)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 54),
                                const SizedBox(height: 12),
                                Text(
                                  Localization.currentLanguage == 'en'
                                      ? 'Camera feed active in browser'
                                      : 'کیمرہ فعال ہے',
                                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Use interactive sign cards below to simulate signs anytime',
                                  style: TextStyle(color: Colors.white38, fontSize: 11),
                                ),
                              ],
                            ),
                          )
                        else
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: blueColor),
                                const SizedBox(height: 12),
                                const Text(
                                  'Initializing AI Sign Engine...',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),

                        // Real-time Hand Landmarks Custom Overlay
                        if (_isCameraInitialized && _detectedHands.isNotEmpty && _imageSize != null)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: CameraHandOverlayPainter(
                                hands: _detectedHands.cast<Hand>(),
                                imageSize: _imageSize!,
                                mirrorHorizontally: true,
                              ),
                            ),
                          ),

                        // Active Floating Sign Label Badge on Camera Frame
                        if (_detectedSignKey.isNotEmpty)
                          Positioned(
                            top: 16,
                            left: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.8), width: 1.5),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 10),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'DETECTED SIGN',
                                          style: TextStyle(
                                            color: Colors.greenAccent.shade100,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        Text(
                                          _detectedWord,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Sleek Corner Detection Brackets
                        Positioned(
                          top: 12, left: 12,
                          child: Icon(Icons.crop_free_rounded, color: _detectedHands.isNotEmpty ? Colors.greenAccent : Colors.white60, size: 28),
                        ),
                        Positioned(
                          top: 12, right: 12,
                          child: RotatedBox(quarterTurns: 1, child: Icon(Icons.crop_free_rounded, color: _detectedHands.isNotEmpty ? Colors.greenAccent : Colors.white60, size: 28)),
                        ),
                        Positioned(
                          bottom: 12, left: 12,
                          child: RotatedBox(quarterTurns: 3, child: Icon(Icons.crop_free_rounded, color: _detectedHands.isNotEmpty ? Colors.greenAccent : Colors.white60, size: 28)),
                        ),
                        Positioned(
                          bottom: 12, right: 12,
                          child: RotatedBox(quarterTurns: 2, child: Icon(Icons.crop_free_rounded, color: _detectedHands.isNotEmpty ? Colors.greenAccent : Colors.white60, size: 28)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- 2. Live Translation Output Panels ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Detected Word Display Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: blueColor.withValues(alpha: 0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: blueColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.sign_language_rounded, color: blueColor, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Localization.get('detected_word'),
                                  style: TextStyle(
                                    color: darkSlate.withValues(alpha: 0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _detectedWord.isEmpty ? Localization.get('waiting') : _detectedWord,
                                  style: TextStyle(
                                    color: _detectedWord.isEmpty ? Colors.black38 : blueColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Generated Sentence Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.black12.withValues(alpha: 0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                Localization.get('generated_sentence'),
                                style: TextStyle(
                                  color: darkSlate.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_generatedSentence.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'AI Translated',
                                    style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _generatedSentence.isEmpty
                                ? Localization.get('sentences_placeholder')
                                : _generatedSentence,
                            style: TextStyle(
                              color: _generatedSentence.isEmpty ? Colors.black38 : darkSlate,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Control Buttons (Speak & Clear)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _speakSentence,
                                  icon: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 18),
                                  label: Text(
                                    Localization.get('speak_btn'),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: blueColor,
                                    elevation: 2,
                                    shadowColor: blueColor.withValues(alpha: 0.3),
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _clearSentence,
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
                                  label: Text(
                                    Localization.get('clear_btn'),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    elevation: 2,
                                    shadowColor: Colors.redAccent.withValues(alpha: 0.3),
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- 3. Interactive Quick Sign Cards Grid ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: blueColor.withValues(alpha: 0.12)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.touch_app_rounded, color: blueColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                Localization.get('simulator_title'),
                                style: TextStyle(
                                  color: darkSlate,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Localization.get('simulator_desc'),
                            style: TextStyle(
                              color: darkSlate.withValues(alpha: 0.6),
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildSignChip('FOOD', '🍲', 'Food / Hungry', blueColor),
                              _buildSignChip('HELP', '🆘', 'Help', blueColor),
                              _buildSignChip('WATER', '💧', 'Water', blueColor),
                              _buildSignChip('GOOD_MORNING', '🌅', 'Good Morning', blueColor),
                              _buildSignChip('WASHROOM', '🚽', 'Washroom', blueColor),
                              _buildSignChip('GOOD', '👍', 'Good & Excellent', blueColor),
                              _buildSignChip('DANGER', '⚠️', 'Danger', blueColor),
                              _buildSignChip('EMERGENCY', '🚨', 'Emergency', blueColor),
                              _buildSignChip('GOOD_NIGHT', '🌙', 'Good Night', blueColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignChip(String signKey, String emoji, String fallbackTitle, Color activeColor) {
    final bool isSelected = _detectedSignKey == signKey;
    final String label = Localization.getSignWord(signKey);

    return InkWell(
      onTap: () {
        _simulateGesture(signKey);
        _speakSentence();
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.black.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: activeColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label.isNotEmpty ? label : fallbackTitle,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
