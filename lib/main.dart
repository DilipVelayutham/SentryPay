import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactModel {
  final String name;
  final int riskScore;
  final String tag;
  final Color avatarColor;

  ContactModel({
    required this.name,
    required this.riskScore,
    required this.tag,
    required this.avatarColor,
  });
}

final List<ContactModel> appContacts = [
  ContactModel(name: "Rahul", riskScore: 3, tag: "Friend", avatarColor: const Color(0xFF8B5CF6)),
  ContactModel(name: "Priya", riskScore: 12, tag: "Merchant", avatarColor: const Color(0xFF3B82F6)),
  ContactModel(name: "Arun", riskScore: 0, tag: "Family", avatarColor: const Color(0xFF10B981)),
  ContactModel(name: "Sneha", riskScore: 8, tag: "Friend", avatarColor: const Color(0xFFF59E0B)),
  ContactModel(name: "Karthik", riskScore: 15, tag: "Business", avatarColor: const Color(0xFFEC4899)),
  ContactModel(name: "Divya", riskScore: 2, tag: "Family", avatarColor: const Color(0xFFEF4444)),
  ContactModel(name: "Vikram", riskScore: 10, tag: "Merchant", avatarColor: const Color(0xFF8B5CF6)),
  ContactModel(name: "Ananya", riskScore: 5, tag: "Friend", avatarColor: const Color(0xFF3B82F6)),
];

ContactModel getContactDetails(String name) {
  return appContacts.firstWhere(
    (c) => c.name.toLowerCase() == name.toLowerCase(),
    orElse: () => ContactModel(
      name: name,
      riskScore: 0,
      tag: "Friend",
      avatarColor: const Color(0xFF059669),
    ),
  );
}

Map<String, dynamic> lastTransactionContext = {
  "risk_score": null,
  "risk_level": null,
  "reasons": null,
  "url": null,
  "intent_result": null,
  "scam_result": null,
  "liveness_active": false,
};

double walletBalance = 15890.74;
List<Map<String, dynamic>> transactionHistory = [
  {
    "title": "To: Priya",
    "name": "Priya",
    "number": "+91 98765 43210",
    "amount": "- ₹1,200.00",
    "status": "SUCCESS",
    "date": "Yesterday, 4:15 PM"
  },
  {
    "title": "Blocked Payment",
    "name": "Suspicious Shop",
    "number": "upi://pay?pa=fake@upi",
    "amount": "- ₹5,000.00",
    "status": "BLOCKED",
    "date": "12 July 2026, 11:30 AM"
  },
  {
    "title": "To: Rahul",
    "name": "Rahul",
    "number": "+91 90123 45678",
    "amount": "- ₹500.00",
    "status": "SUCCESS",
    "date": "10 July 2026, 9:20 PM"
  },
  {
    "title": "Blocked Payment",
    "name": "Lottery Scam Link",
    "number": "https://win-free-prize.xyz",
    "amount": "- ₹15,000.00",
    "status": "BLOCKED",
    "date": "08 July 2026, 2:10 PM"
  },
  {
    "title": "To: Arun",
    "name": "Arun",
    "number": "+91 87654 32109",
    "amount": "- ₹250.00",
    "status": "SUCCESS",
    "date": "05 July 2026, 6:45 PM"
  }
];

class FraudLog {
  final String reason;
  final int riskScore;
  final String time;

  FraudLog({
    required this.reason,
    required this.riskScore,
    required this.time,
  }); 
}

/// GLOBAL LIST
List<FraudLog> fraudHistory = [];

late List<CameraDescription> cameras;

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();
  
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(SentryPayApp(isLoggedIn: isLoggedIn));
}

class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final primarySlide = Tween<Offset>(
      begin: const Offset(0.08, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
    );

    final primaryFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
    );

    final secondarySlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.04, 0.0),
    ).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
      ),
    );

    return SlideTransition(
      position: primarySlide,
      child: FadeTransition(
        opacity: primaryFade,
        child: SlideTransition(
          position: secondarySlide,
          child: child,
        ),
      ),
    );
  }
}

class SmoothTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDownTo;
  final Duration duration;

  const SmoothTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDownTo = 0.96,
    this.duration = const Duration(milliseconds: 80),
  });

  @override
  State<SmoothTap> createState() => _SmoothTapState();
}

class _SmoothTapState extends State<SmoothTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDownTo,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

class SentryPayApp extends StatelessWidget {
  final bool isLoggedIn;
  const SentryPayApp({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SentryPay',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF8FFFC),
        splashFactory: InkRipple.splashFactory,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            for (var platform in TargetPlatform.values)
              platform: const SmoothPageTransitionsBuilder(),
          },
        ),
      ),
      home: isLoggedIn ? const DashboardPage() : const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  static const String baseUrl =
    "https://sentrypay-backend.onrender.com";

  bool get _isValidPhone => _phoneController.text.trim().length == 10;

  Future<void> _sendOtp() async {
  if (!_isValidPhone) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Enter a valid 10-digit mobile number"),
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final response = await http.post(
      Uri.parse("$baseUrl/api/send-otp"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "phone": "+91${_phoneController.text.trim()}",
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["success"] == true) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerifyPage(
            phoneNumber: _phoneController.text.trim(),
          ),
        ),
      );
    } else {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data["message"] ?? "Failed to send OTP"),
        ),
      );
    }
  } catch (e) {
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF34D399),
                        Color(0xFF059669),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white, size: 44),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                "Welcome to SentryPay",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your mobile number to continue",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 36),
              Text(
                "Mobile Number",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD1FAE5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Text(
                            "+91",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(height: 24, width: 1, color: const Color(0xFFD1FAE5)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          hintText: "98765 43210",
                          border: InputBorder.none,
                          counterText: "",
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Text(
                          "Send OTP",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "By continuing, you agree to our Terms & Privacy Policy",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpVerifyPage extends StatefulWidget {
  final String phoneNumber;
  const OtpVerifyPage({super.key, required this.phoneNumber});

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _errorText;
  static const String baseUrl =
    "https://sentrypay-backend.onrender.com";

  String get _enteredOtp => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
  if (_enteredOtp.length != 6) {
    setState(() {
      _errorText = "Enter the complete 6-digit OTP";
    });
    return;
  }

  setState(() {
    _isLoading = true;
    _errorText = null;
  });

  try {
    final response = await http.post(
      Uri.parse("$baseUrl/api/verify-otp"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "phone": "+91${widget.phoneNumber}",
        "otp": _enteredOtp,
      }),
    );

    final data = jsonDecode(response.body);

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200 &&
        data["verified"] == true) {

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardPage(),
        ),
        (route) => false,
      );

    } else {

      setState(() {
        _errorText = "Invalid OTP";
      });

      for (final c in _controllers) {
        c.clear();
      }

      _focusNodes[0].requestFocus();
    }

  } catch (e) {

    setState(() {
      _isLoading = false;
      _errorText = "Server Error";
    });

  }
}

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 46,
      height: 54,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD1FAE5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() => _errorText = null);
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
         
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF34D399),
                      Color(0xFF059669),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.sms_outlined, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 24),
              const Text(
                "Verify OTP",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter the 6-digit code sent to +91 ${widget.phoneNumber}",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => _otpBox(index)),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Text(
                          "Verify & Continue",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () async {

  try {

    final response = await http.post(
      Uri.parse("$baseUrl/api/send-otp"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "phone": "+91${widget.phoneNumber}",
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 &&
        data["success"] == true) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("OTP Sent Again"),
        ),
      );

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to resend OTP"),
        ),
      );

    }

  } catch (_) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Network Error"),
      ),
    );

  }

},
                  child: const Text(
                    "Resend OTP",
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScanPage extends StatefulWidget {
  final int initialTab;
  final bool isAnalysisOnly;
  const ScanPage({super.key, this.initialTab = 0, this.isAnalysisOnly = false});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {

  bool isScanned = false;
  late int selectedTab;
   final MobileScannerController controller =
      MobileScannerController();

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _scanFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final bool success = await controller.analyzeImage(image.path);
      if (!success) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text("Scan Failed"),
            content: const Text("No QR Detected in this Image"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: Color(0xFF059669))),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("Error scanning from gallery: $e");
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: Text("Unable to analyze image: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }
  @override
Widget build(BuildContext context) {

  return Scaffold(
    backgroundColor: Colors.black,

    body: SafeArea(
      child: Column(
        children: [

          /// TOP TAB BAR
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 16.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        /// SCAN QR
                        Expanded(
                          child: SmoothTap(
                            onTap: () {
                              setState(() {
                                selectedTab = 0;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: selectedTab == 0
                                    ? const Color(0xFF10B981)
                                    : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(18),
                              ),
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                style: TextStyle(
                                  color: selectedTab == 0
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                                child: const Text("Scan QR"),
                              ),
                            ),
                          ),
                        ),

                        /// MY QR
                        Expanded(
                          child: SmoothTap(
                            onTap: () {
                              setState(() {
                                selectedTab = 1;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: selectedTab == 1
                                    ? const Color(0xFF10B981)
                                    : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(18),
                              ),
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                style: TextStyle(
                                  color: selectedTab == 1
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                                child: const Text("My QR"),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// CONTENT
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: selectedTab == 0
                  ? KeyedSubtree(key: const ValueKey(0), child: scannerView())
                  : KeyedSubtree(key: const ValueKey(1), child: myQrView()),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget scannerView() {

  return Stack(
    children: [

      /// CAMERA
      MobileScanner(
        controller: controller,

        onDetect: (BarcodeCapture capture) async {

          if (isScanned) return;
          isScanned = true;

          for (final barcode
              in capture.barcodes) {

            final String? code =
                barcode.rawValue;

            if (code != null) {

              await controller.stop();

              controller.dispose();

              await Future.delayed(
                const Duration(
                  milliseconds: 500,
                ),
              );

              Navigator.push(
                context,

                MaterialPageRoute(
                  builder: (context) =>
                      AnalysisPage(
                    qrData: code,
                    isAnalysisOnly: widget.isAnalysisOnly,
                  ),
                ),
              );

              break;
            }
          }
        },
      ),

      /// DARK OVERLAY
      Container(
        color: Colors.black.withOpacity(0.55),
      ),

      /// CORNER FRAME
      Center(
        child: Center(
  child: Container(
    width: 260,
    height: 260,

    decoration: BoxDecoration(
      border: Border.all(
        color: const Color(0xFF10B981),
        width: 4,
      ),

      borderRadius:
          BorderRadius.circular(24),

      boxShadow: [
        BoxShadow(
          color: const Color(
            0xFF10B981,
          ).withOpacity(0.4),

          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    ),
  ),
)

      ),

      const Positioned(
        bottom: 180,
        left: 0,
        right: 0,

        child: Text(
          "Align QR within the frame",

          textAlign: TextAlign.center,

          style: TextStyle(
            color: Colors.white70,
          ),
        ),
      ),

      Positioned(
        bottom: 60,
        left: 0,
        right: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.flash_on, color: Colors.white),
                onPressed: () {
                  controller.toggleTorch();
                },
              ),
            ),
            const SizedBox(width: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 4,
              ),
              onPressed: _scanFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text(
                "Choose from Library",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget myQrView() {

  return Center(
    child: SingleChildScrollView(
      child: Column(
        children: [

          Container(
            margin:
                const EdgeInsets.all(20),

            padding:
                const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius:
                  BorderRadius.circular(24),

              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                ),
              ],
            ),

            child: Column(
              children: [

                Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/QR Code.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Dilip Velayutham",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  "dilipvelayuthamiob@sentrypay",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 15),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),

                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFE8FFF5),

                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),

                  child: const Text(
                    "Receive Money Securely",
                    style: TextStyle(
                      color:
                          Color(0xFF059669),
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget corner(Color color) {

  return Container(
    width: 40,
    height: 40,

    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: color,
          width: 5,
        ),

        left: BorderSide(
          color: color,
          width: 5,
        ),
      ),

      borderRadius:
          BorderRadius.circular(12),
    ),
  );
}
}
class AnalysisPage extends StatefulWidget {
  final String qrData;
  final bool isAnalysisOnly;

  const AnalysisPage({super.key, required this.qrData, this.isAnalysisOnly = false});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {

  int riskScore = 0;
  String riskLevel = "";
  Color riskColor = Colors.green;
  String riskReason = "";

  @override
  void initState() {
    super.initState();
    analyzeQR();
  }

  Future<void> analyzeQR() async {

  try {

    final response = await http.post(

      // CHANGE THIS IP
      Uri.parse("https://sentrypay.onrender.com/analyze"),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({
        "url": widget.qrData,
      }),
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      lastTransactionContext = {
        "risk_score": data["risk_score"] ?? 0,
        "risk_level": data["risk_level"] ?? "LOW",
        "reasons": data["reasons"] as List? ?? [],
        "url": widget.qrData,
        "intent_result": null,
        "scam_result": null,
        "liveness_active": false,
      };

      riskScore = data["risk_score"] ?? 0;

      riskReason = (data["reasons"] as List)
          .join("\n• ");

      if (riskReason.isEmpty) {
        riskReason = "No suspicious activity detected";
      }

      if (riskScore > 75) {

        riskLevel = "HIGH RISK";
        riskColor = Colors.red;

        setState(() {});

        if (widget.isAnalysisOnly) return;

        showHighRisk();

      } else if (riskScore > 40) {

        riskLevel = "MEDIUM RISK";
        riskColor = Colors.orange;

        setState(() {});

        if (widget.isAnalysisOnly) return;

        final rawReasonsList = data["reasons"] as List? ?? [];
        final List<String> reasonsList = rawReasonsList.map((e) => e.toString()).toList();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => IntentVerificationPage(
              qrData: widget.qrData,
              riskScore: riskScore,
              riskLevel: riskLevel,
              riskReason: riskReason,
              reasonsList: reasonsList,
            ),
          ),
        );

      } else {

        riskLevel = "LOW RISK";
        riskColor = Colors.green;

        setState(() {});

        if (widget.isAnalysisOnly) return;

        goToPayment();
      }

    } else {

      riskScore = 100;
      riskLevel = "HIGH RISK";
      riskColor = Colors.red;

      riskReason =
          "Unable to verify QR through Risk Engine";

      setState(() {});
    }

  } catch (e) {

    riskScore = 100;

    riskLevel = "HIGH RISK";

    riskColor = Colors.red;

    riskReason =
        "Risk Engine connection failed.\n$e";

    setState(() {});
  }
}
  /// 🧠 AI Explanation Logic
  String getRiskReason(String qrData, int riskScore) {

    List<String> reasons = [];

    if (qrData.contains("scam")) {
      reasons.add("Suspicious QR source detected");
    }

    if (riskScore > 75) {
      reasons.add("High-risk transaction pattern");
    }

    if (qrData.contains("unknown")) {
      reasons.add("Unverified receiver");
    }

    if (riskScore > 40 && riskScore <= 75) {
      reasons.add("Moderate risk behavior observed");
    }

    if (reasons.isEmpty) {
      reasons.add("No suspicious activity detected");
    }

    return reasons.join("\n• ");
  }

  void showHighRisk() {
    fraudHistory.add(
      FraudLog(
        reason: riskReason,
        riskScore: riskScore,
        time: TimeOfDay.now().format(context),
      ),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠ Scam Alert"),
        content: Text(
          "Risk Score: $riskScore%\n\n⚠ Reason:\n• $riskReason\n\nTransaction Blocked.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              transactionHistory.add({
                "title": "Blocked Payment",
                "name": "Suspicious Merchant",
                "number": widget.qrData,
                "amount": "- ₹0.00",
                "status": "BLOCKED",
                "date": "Today, ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
              });
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void showMediumRisk() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠ Warning"),
        content: Text(
          "Risk Score: $riskScore%\n\n⚠ Reason:\n• $riskReason\n\nProceed carefully.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              goToPayment();
            },
            child: const Text("Proceed"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void goToPayment() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          qrData: widget.qrData,
          riskScore: riskScore,
          receiverName: "Scanned Merchant", // ✅ IMPORTANT FIX
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: widget.isAnalysisOnly
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (riskLevel.isEmpty) ...[
                      const CircularProgressIndicator(color: Colors.green),
                      const SizedBox(height: 24),
                      const Text(
                        "Analyzing Transaction QR...",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ] else ...[
                      Icon(
                        riskScore > 75
                            ? Icons.dangerous
                            : (riskScore > 40 ? Icons.warning : Icons.verified),
                        color: riskColor,
                        size: 80,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        riskLevel,
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Threat Score: $riskScore%",
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "QR Content / Data:",
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              widget.qrData,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Risk Assessment Reasons:",
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              riskReason,
                              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Done / Back to QR Shield",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  const CircularProgressIndicator(color: Colors.green),

                  const SizedBox(height: 20),

                  const Text(
                    "Analyzing Transaction...",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    "Risk Score: $riskScore%",
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    riskLevel,
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// 🔥 AI Explanation UI
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "⚠ Reason:\n $riskReason",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class IntentVerificationPage extends StatefulWidget {
  final String qrData;
  final int riskScore;
  final String riskLevel;
  final String riskReason;
  final List<String> reasonsList;

  const IntentVerificationPage({
    super.key,
    required this.qrData,
    required this.riskScore,
    required this.riskLevel,
    required this.riskReason,
    required this.reasonsList,
  });

  @override
  State<IntentVerificationPage> createState() => _IntentVerificationPageState();
}

class _IntentVerificationPageState extends State<IntentVerificationPage> {
  List<String> questions = [];
  final List<String?> answers = [null, null, null];
  bool isLoading = true;
  bool isSubmitting = false;
  String errorMessage = "";
  Map<String, dynamic>? resultData;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  String getIntentAiUrl() {
    return "https://sentrypay-intent-ai.onrender.com";
  }

  Future<void> fetchQuestions() async {
    try {
      final response = await http.post(
        Uri.parse("${getIntentAiUrl()}/generate-intent-questions"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "url": widget.qrData,
          "ml_score": 0,
          "rule_score": 0,
          "risk_score": widget.riskScore,
          "risk_level": widget.riskLevel,
          "reasons": widget.reasonsList,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          questions = List<String>.from(data["questions"] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load questions from Intent AI (status: ${response.statusCode})";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Connection to Intent AI failed.\nMake sure the intent-ai service is running.\n$e";
        isLoading = false;
      });
    }
  }

  Future<void> submitAnswers() async {
    if (answers.contains(null)) {
      setState(() {
        errorMessage = "Please select an answer for all three questions.";
      });
      return;
    }

    setState(() {
      isSubmitting = true;
      errorMessage = "";
    });

    try {
      final response = await http.post(
        Uri.parse("${getIntentAiUrl()}/verify-intent"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "risk_result": {
            "url": widget.qrData,
            "ml_score": 0,
            "rule_score": 0,
            "risk_score": widget.riskScore,
            "risk_level": widget.riskLevel,
            "reasons": widget.reasonsList,
          },
          "questions": questions,
          "answers": answers,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final decision = data["decision"] ?? "BLOCK";
        lastTransactionContext["intent_result"] = decision;
        
        setState(() {
          resultData = data;
          isSubmitting = false;
        });

        if (decision == "SAFE") {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentPage(
                qrData: widget.qrData,
                riskScore: widget.riskScore,
                receiverName: "Scanned Merchant",
              ),
            ),
          );
        }
      } else {
        setState(() {
          errorMessage = "Failed to verify intent (status: ${response.statusCode})";
          isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Connection to Intent AI failed.\n$e";
        isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildOptionButton(int questionIndex, String optionText) {
    bool isSelected = answers[questionIndex] == optionText;
    Color buttonColor = isSelected ? const Color(0xFF059669) : Colors.white;
    Color textColor = isSelected ? Colors.white : Colors.black87;
    Color borderColor = isSelected ? const Color(0xFF059669) : Colors.grey.shade300;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            answers[questionIndex] = optionText;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: buttonColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              optionText,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (resultData != null && resultData!["decision"] != "SAFE") {
      final reasons = List<String>.from(resultData!["reason"] ?? []);
      final intentScore = resultData!["intent_score"] ?? 0;
      final confidence = resultData!["confidence"] ?? 0.0;

      return Scaffold(
        backgroundColor: const Color(0xFFFFFBEB),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 80.0,
                ),
                const SizedBox(height: 24.0),
                const Text(
                  "High Risk Alert",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12.0),
                Text(
                  "Security Intent Score: $intentScore/100 (Confidence: ${(confidence * 100).toInt()}%)",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12.0),
                const Text(
                  "Warning: SentryPay AI detected potential scam indicators based on your answers. Please review the threat explanation carefully before proceeding.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24.0),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.08),
                        blurRadius: 10.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Risk Indicators Identified:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      ...reasons.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                                Expanded(
                                  child: Text(
                                    r,
                                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 40.0),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentPage(
                                qrData: widget.qrData,
                                riskScore: widget.riskScore,
                                receiverName: "Scanned Merchant",
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Proceed to Payment",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const DashboardPage()),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          "Cancel & Go Back",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      appBar: AppBar(
        title: const Text("Intent Verification"),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPage()),
              (route) => false,
            );
          },
        ),
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF10B981)),
                  SizedBox(height: 16),
                  Text("Generating Verification Questions..."),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Transaction Security Verification",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Please answer the following three questions to help us verify that you understand the payment you are making.",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  if (errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ...List.generate(questions.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Question ${index + 1}",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            questions[index],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildOptionButton(index, "Yes"),
                              const SizedBox(width: 8),
                              _buildOptionButton(index, "No"),
                              const SizedBox(width: 8),
                              _buildOptionButton(index, "I don't know"),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: isSubmitting ? null : submitAnswers,
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Verify & Proceed",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class PaymentPage extends StatefulWidget {  
  final String qrData;
  final int riskScore;
  final String receiverName;
  final bool isPreLivenessVerified;
  final String prefilledAmount;

  const PaymentPage({
    super.key,
    required this.qrData,
    required this.riskScore,
    this.receiverName = "Divakar",
    this.isPreLivenessVerified = false,
    this.prefilledAmount = "",
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {

  TextEditingController amountController = TextEditingController();
  TextEditingController intentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.prefilledAmount.isNotEmpty) {
      amountController.text = widget.prefilledAmount;
    }
  }

  final List<String> intents = [
    "Paying a friend",
    "Shopping",
    "Food order",
    "Bill payment",
    "Subscription",
    "Other"
  ];

  /// 🔍 Intent Detection
  bool isSuspiciousIntent(String intent) {
    final keywords = [
      "urgent",
      "lottery",
      "gift",
      "free",
      "reward",
      "verify",
      "refund",
      "claim"
    ];

    for (var word in keywords) {
      if (intent.toLowerCase().contains(word)) {
        return true;
      }
    }
    return false;
  }

  @override
Widget build(BuildContext context) {

  return Scaffold(
    backgroundColor: const Color(0xFFF8FFFC),

    body: Column(
      children: [

        /// HEADER
        Container(
          width: double.infinity,
          height: 200,

          padding: const EdgeInsets.only(
            top: 55,
            left: 20,
            right: 20,
          ),

          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF34D399),
                Color(0xFF059669),
              ],
            ),

            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Pay Securely",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                "Receiver: ${widget.receiverName}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Risk Score: ${widget.riskScore}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        /// CONTENT
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [

                const SizedBox(height: 20),

                /// AMOUNT

                const Text(
                  "Amount",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),

                Row(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [

    const Text(
      "₹",
      style: TextStyle(
        fontSize: 52,
        fontWeight: FontWeight.bold,
      ),
    ),

    const SizedBox(width: 6),

    SizedBox(
      width: 180,

      child: TextField(
        controller: amountController,
        keyboardType: TextInputType.number,

        textAlign: TextAlign.center,

        style: const TextStyle(
          fontSize: 52,
          fontWeight: FontWeight.bold,
        ),

        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "0",
        ),
      ),
    ),
  ],
),

                const SizedBox(height: 5),

                const Text(
                  "Available Balance ₹45,320",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 35),

                /// INTENT TITLE

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Purpose of Payment",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// INTENT BOX

                TextField(
                  controller: intentController,

                  decoration: InputDecoration(
                    hintText:
                        "Why are you making this payment?",

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),

                    contentPadding:
                        const EdgeInsets.all(18),
                  ),
                ),

                const SizedBox(height: 20),

                /// QUICK INTENTS

                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,

                    children:
                        intents.map((intent) {

                      return ChoiceChip(
                        label: Text(intent),

                        selected:
                            intentController.text ==
                                intent,

                        selectedColor:
                            const Color(
                                0xFFE8FFF5),

                        onSelected: (_) {
                          setState(() {
                            intentController.text =
                                intent;
                          });
                        },
                      );

                    }).toList(),
                  ),
                ),

                const SizedBox(height: 40),

                /// PAY BUTTON

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF059669),

                      foregroundColor:
                          Colors.white,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                                18),
                      ),
                    ),

                    onPressed: () {

                      if (amountController
                          .text.isEmpty) {
                        return;
                      }

                      bool suspicious =
                          isSuspiciousIntent(
                        intentController.text,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UpiPinPage(
                            amount: amountController.text,
                            riskScore: widget.riskScore,
                            suspiciousIntent: suspicious,
                            isPreLivenessVerified: widget.isPreLivenessVerified,
                            receiverName: widget.receiverName,
                          ),
                        ),
                      );
                    },

                    child: const Text(
                      "Pay Now",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  }
}

class UpiPinPage extends StatefulWidget {
  final String amount;
  final int riskScore;
  final bool suspiciousIntent;
  final bool isBalanceCheck;
  final bool isPreLivenessVerified;
  final String receiverName;

  const UpiPinPage({
    super.key,
    required this.amount,
    required this.riskScore,
    required this.suspiciousIntent,
    this.isBalanceCheck = false,
    this.isPreLivenessVerified = false,
    this.receiverName = "UPI Merchant",
  });

  @override
  State<UpiPinPage> createState() => _UpiPinPageState();
}

class _UpiPinPageState extends State<UpiPinPage> {

  String pin = "";

  void addDigit(String digit) {
    if (pin.length < 4) {
      setState(() {
        pin += digit;
      });

      if (pin.length == 4) {

        Future.delayed(const Duration(milliseconds: 300), () {

          /// 🔐 BALANCE CHECK FLOW
          if (widget.isBalanceCheck) {

            Navigator.pop(context, true); // 👈 return success
            return;
          }

          /// 🔐 NORMAL FLOW
          if ((widget.riskScore > 40 || widget.suspiciousIntent) && !widget.isPreLivenessVerified) {

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    LivenessPage(
                      amount: widget.amount,
                      receiverName: widget.receiverName,
                    ),
              ),
            );

          } else {

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SuccessPage(
                      amount: widget.amount,
                      amountValue: double.parse(widget.amount),
                      receiverName: widget.receiverName,
                    ),
                ),
            );

          }

        });
      }
    }
  }

  void removeDigit() {
    if (pin.isNotEmpty) {
      setState(() {
        pin = pin.substring(0, pin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {

  return Scaffold(
    backgroundColor: Colors.white,

    body: SafeArea(
      child: Column(
        children: [

          const SizedBox(height: 20),

          /// HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [

                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),

                const Spacer(),

                const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.blue,
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// AMOUNT
          if (!widget.isBalanceCheck)
            Column(
              children: [

                Text(
                  "₹${widget.amount}",
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Paying to",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  "Scanned Merchant",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

          if (widget.isBalanceCheck)
            const Text(
              "Check Account Balance",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

          const SizedBox(height: 25),

          /// BANK CARD
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(15),

            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),

            child: const Row(
              children: [

                Icon(Icons.account_balance),

                SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        "Indian Overseas Bank",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        "XXXXXX8742",
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            "Enter UPI PIN",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 20),

          /// PIN DOTS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              4,
              (index) => Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),

                width: 18,
                height: 18,

                decoration: BoxDecoration(
                  color: index < pin.length
                      ? Colors.black
                      : Colors.transparent,

                  border: Border.all(
                    color: Colors.black54,
                  ),

                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "UPI PIN is issued by your bank",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),

          const Spacer(),

          /// KEYPAD
          Container(
            color: Colors.grey.shade50,

            child: Column(
              children: [

                keypadRow(["1", "2", "3"]),

                keypadRow(["4", "5", "6"]),

                keypadRow(["7", "8", "9"]),

                Row(
                  children: [

                    Expanded(
                      child: IconButton(
                        icon: const Icon(
                          Icons.backspace_outlined,
                          size: 28,
                        ),
                        onPressed: removeDigit,
                      ),
                    ),

                    Expanded(
                      child: keyButton("0"),
                    ),

                    const Expanded(
                      child: SizedBox(),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    ),
  );
  }
  Widget keypadRow(List<String> numbers) {

    return Row(
      children: numbers
          .map(
            (number) => Expanded(
              child: keyButton(number),
            ),
          )
          .toList(),
    );
  }

  Widget keyButton(String number) {
    return Container(
      margin: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => addDigit(number),
          borderRadius: BorderRadius.circular(40),
          child: Container(
            height: 70,
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class LivenessPage extends StatefulWidget {

  final String amount;
  final bool isPrePayment;
  final int? riskScore;
  final String? qrData;
  final String receiverName;

  const LivenessPage({
    super.key,
    required this.amount,
    this.isPrePayment = false,
    this.riskScore,
    this.qrData,
    this.receiverName = "UPI Merchant",
  });

  @override
  State<LivenessPage> createState() => _LivenessPageState();
}
class _LivenessPageState extends State<LivenessPage> {

  CameraController? cameraController;
  late FaceDetector faceDetector;

  bool detecting = false;
  bool faceDetected = false;
  bool isCameraInitialized = false;
  bool verified = false;

  bool eyesWereOpen = false;

  bool timeoutOccurred = false;

  int attemptCount = 1;

  bool dialogShowing = false;

  @override
  void initState() {
    super.initState();
    lastTransactionContext["liveness_active"] = true;

    faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
      ),
    );

    initCamera();
  }

  Future<void> initCamera() async {

    try {

      final frontCamera = cameras.firstWhere(
        (camera) =>
            camera.lensDirection == CameraLensDirection.front,
      );

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        isCameraInitialized = true;
      });

      await Future.delayed(
        const Duration(seconds: 1),
      );

      detectFace();
      startTimeout();

    } catch (e) {

      debugPrint("Camera Error: $e");
    }
  }

  void startTimeout() {

    timeoutOccurred = false;

    Future.delayed(
      const Duration(seconds: 12),
      () {

        if (!mounted) return;

        if (!verified && !dialogShowing) {

          timeoutOccurred = true;
          dialogShowing = true;

          if (attemptCount < 3) {

            showDialog(
              context: context,
              barrierDismissible: false,

              builder: (_) => AlertDialog(

                title: const Text(
                  "Verification Failed",
                ),

                content: Text(
                  "Blink not detected.\n\nAttempt $attemptCount of 3",
                ),

                actions: [

                  TextButton(

                    onPressed: () {

                      Navigator.pop(context);

                      eyesWereOpen = false;

                      timeoutOccurred = false;
                      dialogShowing = false;

                      attemptCount++;

                      detectFace();
                      startTimeout();
                    },

                    child: const Text("Retry"),
                  ),
                ],
              ),
            );

          } else {

            showDialog(
              context: context,
              barrierDismissible: false,

              builder: (_) => AlertDialog(

                title: const Text(
                  "Payment Cancelled",
                ),

                content: const Text(
                  "Blink verification failed 3 times.",
                ),

                actions: [

                  TextButton(

                    onPressed: () {

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const DashboardPage(),
                        ),
                        (route) => false,
                      );
                    },

                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
        }
      },
    );
  }

  Future<void> detectFace() async {

    if (detecting ||
        verified ||
        timeoutOccurred ||
        dialogShowing) {
      return;
    }

    detecting = true;

    try {

      final image =
          await cameraController!.takePicture();

      final inputImage =
          InputImage.fromFilePath(image.path);

      final faces =
          await faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {

        if (mounted) {
          setState(() {
            faceDetected = true;
          });
        }

        await Future.delayed(
          const Duration(milliseconds: 300),
        );

        final face = faces.first;

        if (face.leftEyeOpenProbability == null ||
            face.rightEyeOpenProbability == null) {

          detecting = false;

          Future.delayed(
            const Duration(milliseconds: 500),
            detectFace,
          );

          return;
        }

        final leftEye =
            face.leftEyeOpenProbability!;

        final rightEye =
            face.rightEyeOpenProbability!;

        debugPrint(
          "Left Eye: $leftEye | Right Eye: $rightEye",
        );

        if (leftEye > 0.5 &&
            rightEye > 0.5) {

          eyesWereOpen = true;
        }

        if (timeoutOccurred) {

          detecting = false;

          return;
        }

        if (eyesWereOpen &&
            leftEye < 0.45 &&
            rightEye < 0.45) {

          if (!mounted) return;

          setState(() {
            verified = true;
          });

          showDialog(
            context: context,
            barrierDismissible: false,

            builder: (_) => AlertDialog(

              title: const Text("Success"),

              content: const Text(
                "Blink Verification Successful",
              ),

              actions: [

                TextButton(

                  onPressed: () {
                    if (widget.isPrePayment) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentPage(
                            qrData: widget.qrData ?? "",
                            riskScore: widget.riskScore ?? 0,
                            isPreLivenessVerified: true,
                          ),
                        ),
                      );
                    } else {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SuccessPage(
                            amount: widget.amount,
                            amountValue:
                                double.parse(widget.amount),
                            receiverName: widget.receiverName,
                          ),
                        ),
                        (route) => false,
                      );
                    }
                  },

                  child: const Text("OK"),
                ),
              ],
            ),
          );

          detecting = false;

          return;
        }

        Future.delayed(
          const Duration(milliseconds: 400),
          detectFace,
        );

      } else {

        if (mounted) {
          setState(() {
            faceDetected = false;
          });
        }

        Future.delayed(
          const Duration(seconds: 1),
          detectFace,
        );
      }

    } catch (e) {

      debugPrint(
        "Face Detection Error: $e",
      );
    }

    detecting = false;
  }

  @override
  void dispose() {

    cameraController?.dispose();

    faceDetector.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Liveness Verification",
        ),
        backgroundColor: Colors.green,
      ),

      body: isCameraInitialized

          ? Column(
              children: [

                Expanded(
                  child: CameraPreview(
                    cameraController!,
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.all(20),

                  child: Column(
                    children: [

                      Text(
                        verified
                            ? "✔ Blink Verification Done Successfully"
                            : faceDetected
                                ? "Blink your eyes to continue..."
                                : "Show your face to camera...",

                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,

                          color: verified
                              ? Colors.green
                              : Colors.black,
                        ),
                      ),

                      const SizedBox(height: 20),

                     
                    ],
                  ),
                ),
              ],
            )

          : const Center(
              child:
                  CircularProgressIndicator(),
            ),
    );
  }
}
class SuccessPage extends StatefulWidget {
  final String amount;
  final double amountValue;
  final String receiverName;

  const SuccessPage({
    super.key,
    required this.amount,
    required this.amountValue,
    this.receiverName = "UPI Merchant",
  });

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    walletBalance -= widget.amountValue;

    transactionHistory.add({
      "title": "To: ${widget.receiverName}",
      "name": widget.receiverName,
      "number": "+91 XXXXX XXXXX",
      "amount": "- ₹${widget.amount}",
      "status": "SUCCESS",
      "date": "Today, ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.bounceOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
      ),
    );

    _animationController.forward();
    _playSuccessSound();
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('Payment Success Sound.mp3'));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140 * _pulseAnimation.value,
                        height: 140 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981).withOpacity(0.05 * (2.0 - _pulseAnimation.value)),
                        ),
                      ),
                      Container(
                        width: 120 * _pulseAnimation.value,
                        height: 120 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981).withOpacity(0.1 * (2.0 - _pulseAnimation.value)),
                        ),
                      ),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF10B981),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              const Text(
                "Payment Successful",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Sent to ${widget.receiverName}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "₹${widget.amount}",
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DashboardPage(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      "Done / Back to Home",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SendMoneyPage extends StatefulWidget {
  final String name;

  const SendMoneyPage({super.key, required this.name});

  @override
  State<SendMoneyPage> createState() => _SendMoneyPageState();
}

class _SendMoneyPageState extends State<SendMoneyPage> {

  TextEditingController amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Money"),
        backgroundColor: Colors.green,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            const SizedBox(height: 30),

            /// Receiver Profile
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.green.shade100,
              child: Text(
                widget.name[0],
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            /// Amount Field
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter Amount",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// Send Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(15),
                ),
                onPressed: () {

                  String amount = amountController.text;

                  if(amount.isNotEmpty){

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "₹$amount sent to ${widget.name}",
                        ),
                      ),
                    );

                    Navigator.pop(context);
                  }
                },

                child: const Text(
                  "Send Money",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )

          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  bool showBalance = false;
  int selectedIndex = 0;

  final List<String> people = [
    "Rahul","Priya","Arun","Sneha","Karthik","Divya","Vikram","Ananya"
  ];
  final List<String> businesses = [
    "Amazon","Flipkart","Swiggy","Zomato","Uber","Ola","Netflix","Spotify"
  ];

final PageController _pageController =
    PageController();

    @override
void dispose() {
  _pageController.dispose();
  super.dispose();
}

  @override
Widget build(BuildContext context) {

  return Scaffold(

    floatingActionButton: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Sentry Chatbot Button
        SmoothTap(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SentryChatPage(),
              ),
            );
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFF10B981),
                  Color(0xFF047857),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x3310B981),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.forum_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Scanner Button
        Container(
          width: 63,
          height: 63,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF34D399),
                Color.fromARGB(255, 2, 83, 57),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x5510B981),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton(
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 35,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScanPage(),
                ),
              );
            },
          ),
        ),
      ],
    ),

    bottomNavigationBar: BottomNavigationBar(
      backgroundColor: const Color(0xFF064E3B),

      currentIndex: selectedIndex,

      onTap: (index) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      },

      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,

      selectedLabelStyle:
          const TextStyle(
        fontWeight: FontWeight.bold,
      ),

      items: const [

        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.currency_rupee),
          label: "Money",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: "More",
        ),
      ],
    ),

    body: PageView(
      controller: _pageController,

      onPageChanged: (index) {
        setState(() {
          selectedIndex = index;
        });
      },

      children: [
        homeContent(),
        const HistoryPage(),
        const MorePage(),
      ],
    ),
  );
}

  Widget homeContent() {
  return SafeArea(
    child: Column(
      children: [

        /// 🔥 FIXED HEADER
        Container(
          height: 100,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF34D399),
                Color(0xFF059669),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Row(
                children: [
                  
                  const SizedBox(width: 7),
                  const Text(
                    "Sentry₹Pay",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                ],
              ),

              SmoothTap(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD1FAE5),
                      width: 2.5,
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage(
                      "assets/Casual Profile.jpeg",
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// 🔽 SCROLLABLE CONTENT
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 💳 BALANCE CARD
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                      Colors.white,
                      Color(0xFFF0FDF4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text("Wallet Balance",
                          style: TextStyle(color: Colors.grey)),

                      const SizedBox(height: 10),

                      showBalance
                          ? Text(
                              "₹ ${walletBalance.toStringAsFixed(2)}",
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold),
                            )
                          : const Text(
                              "••••••••",
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold),
                            ),

                      const SizedBox(height: 10),

                      SmoothTap(
                        onTap: () {
                          if (!showBalance) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UpiPinPage(
                                  amount: "0",
                                  riskScore: 0,
                                  suspiciousIntent: false,
                                  isBalanceCheck: true,
                                ),
                              ),
                            ).then((value) {
                              if (value == true) {
                                setState(() {
                                  showBalance = true;
                                });
                              }
                            });
                          } else {
                            setState(() {
                              showBalance = false;
                            });
                          }
                        },
                        child: Text(
                          showBalance
                              ? "Hide Balance"
                              : "View Balance",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30),
            
          
                const Text("Quick Actions",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                const SizedBox(height: 30),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Row(
                    children: [
                      const Spacer(flex: 1),
                      quickAction(Icons.send, "Send", () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const SendUserPage())
                        );
                      }),
                      const Spacer(flex: 2),
                      quickAction(Icons.receipt_long, "Bills", () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const BillsPage())
                        );
                      }),
                      const Spacer(flex: 2),
                      quickAction(Icons.request_page, "Request", () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const RequestPage())
                        );
                      }),
                      const Spacer(flex: 2),
                      quickAction(Icons.account_balance, "Transfer", () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const BankTransferPage())
                        );
                      }),
                      const Spacer(flex: 1)
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                /// 👥 PEOPLE
                const Text("People",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                const SizedBox(height: 30),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: people.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    return peopleAvatar(people[index]);
                  },
                ),

                const SizedBox(height: 40),

                /// 🏢 BUSINESSES
                const Text("Businesses",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                const SizedBox(height: 30),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: businesses.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    return businessAvatar(businesses[index]);
                  },
                ),

                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      const Text(
                        "",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "© SentryPay | A DV Tech",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    ),
  );
} 

 Widget quickAction(
    IconData icon,
    String label,
    VoidCallback onTap,
) {
  return SmoothTap(
    onTap: onTap,
    child: Column(
      children: [

        Container(
          width: 60,
          height: 60,

          decoration: BoxDecoration(
            shape: BoxShape.circle,

            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF34D399),
                Color.fromARGB(255, 27, 213, 151),
              ],
            ),

            boxShadow: const [
              BoxShadow(
                color: Color(0x4410B981),
                blurRadius: 20,
                spreadRadius: 3,
                offset: Offset(0, 8),
              ) ,
            ],
          ),

          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
  Widget peopleAvatar(String name) {
    return SmoothTap(
      onTap: () {

      /// 👇 Navigate to Payment Page directly
      final isBusiness = getContactDetails(name).tag == "Business" || 
                         ["netflix", "spotify", "amazon", "uber", "ola", "swiggy", "zomato", "flipkart"]
                             .contains(name.toLowerCase());
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => isBusiness
              ? BusinessInteractionPage(businessName: name)
              : ChatPage(contactName: name),
        ),
      );

    },

    child: Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
          shape: BoxShape.circle,

    color: getContactDetails(name).avatarColor,

    boxShadow: const [
      BoxShadow(
        color: Color(0x3310B981),
        blurRadius: 20,
        spreadRadius: 3,
        offset: Offset(0, 8),
      ),
    ],
  ),

  child: Center(
    child: Text(
      name[0].toUpperCase(),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
    ),
  ),
),
          const SizedBox(height: 5),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
    );
  }

  Widget businessAvatar(String name) {
    final lowercase = name.toLowerCase();
    final extensions = {
      'netflix': 'jpg',
      'ola': 'jpg',
      'swiggy': 'jpg',
    };
    final ext = extensions[lowercase] ?? 'png';
    final imagePath = 'assets/business/$lowercase.$ext';

    return SmoothTap(
      onTap: () {
        /// 👇 Navigate to Payment Page directly
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BusinessInteractionPage(
              businessName: name,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3310B981),
                  blurRadius: 20,
                  spreadRadius: 3,
                  offset: Offset(0, 8),
                ),
              ],
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
    );
  }
}
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _showBalance = false;

  void _checkBalance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UpiPinPage(
          amount: "0",
          riskScore: 0,
          suspiciousIntent: false,
          isBalanceCheck: true,
        ),
      ),
    ).then((value) {
      if (value == true) {
        setState(() {
          _showBalance = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 100,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF34D399),
                    Color(0xFF059669),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Money",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Manage accounts, cards and transactions",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    moneyCard(
                      icon: Icons.account_balance,
                      title: "Indian Overseas Bank",
                      subtitle: _showBalance ? "Balance: ₹$walletBalance" : "•••• 8742",
                      trailing: _showBalance ? "Checked" : "Check Balance",
                      onTap: _showBalance ? null : _checkBalance,
                    ),
                    moneyCard(
                      icon: Icons.credit_card,
                      title: "Cards",
                      subtitle: "2 Active Cards",
                      trailing: "Manage",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ManageCardsPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Recent Transactions",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    transactionHistory.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(40),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 70,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "No History Now",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "Your payments will appear here",
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: transactionHistory.length,
                            itemBuilder: (context, index) {
                              final tx = transactionHistory.reversed.toList()[index];
                              return transactionTile(tx);
                            },
                          ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManageCardsPage extends StatefulWidget {
  const ManageCardsPage({super.key});

  @override
  State<ManageCardsPage> createState() => _ManageCardsPageState();
}

class _ManageCardsPageState extends State<ManageCardsPage> {
  bool _cardBlocked = false;
  bool _onlineTxEnabled = true;
  bool _internationalTxEnabled = false;
  double _limitValue = 25000.0;
  bool _showCvv = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Manage Cards"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 210,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _cardBlocked
                      ? [Colors.grey.shade800, Colors.grey.shade900]
                      : [
                          const Color(0xFF6366F1),
                          const Color(0xFFEC4899),
                          const Color(0xFF3B82F6),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _cardBlocked ? Colors.black26 : const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "SentryPay Premium",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            "Secure Debit",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _cardBlocked ? Icons.lock : Icons.contactless,
                        color: Colors.white70,
                        size: 28,
                      ),
                    ],
                  ),
                  const Text(
                    "••••  ••••  ••••  5694",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CARDHOLDER",
                            style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.5),
                          ),
                          Text(
                            "SentryPay User",
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "EXPIRES",
                            style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.5),
                          ),
                          Text(
                            _cardBlocked ? "••/••" : "12/31",
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "CVV",
                            style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.5),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showCvv = !_showCvv;
                              });
                            },
                            child: Row(
                              children: [
                                Text(
                                  _showCvv && !_cardBlocked ? "415" : "•••",
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _showCvv ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "CARD CONTROLS",
              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            _buildControlTile(
              "Temporary Block Card",
              "Instantly lock card transactions anytime",
              Icons.block,
              _cardBlocked,
              (val) {
                setState(() {
                  _cardBlocked = val;
                });
              },
            ),
            _buildControlTile(
              "Online / E-Commerce Transactions",
              "Allow payment on web apps and websites",
              Icons.shopping_cart,
              _onlineTxEnabled,
              _cardBlocked
                  ? null
                  : (val) {
                      setState(() {
                        _onlineTxEnabled = val;
                      });
                    },
            ),
            _buildControlTile(
              "International Usage",
              "Transactions outside country borders",
              Icons.public,
              _internationalTxEnabled,
              _cardBlocked
                  ? null
                  : (val) {
                      setState(() {
                        _internationalTxEnabled = val;
                      });
                    },
            ),
            const SizedBox(height: 25),
            const Text(
              "TRANSACTION LIMITS",
              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Daily POS/ATM Limit",
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "₹${_limitValue.toInt()}",
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: _limitValue,
                    min: 5000,
                    max: 100000,
                    divisions: 19,
                    activeColor: const Color(0xFF10B981),
                    inactiveColor: Colors.white24,
                    onChanged: _cardBlocked
                        ? null
                        : (val) {
                            setState(() {
                              _limitValue = val;
                            });
                          },
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("₹5,000", style: TextStyle(color: Colors.white38, fontSize: 12)),
                      Text("₹1,00,000", style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildControlTile(String title, String subtitle, IconData icon, bool val, ValueChanged<bool>? onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (onChanged == null ? Colors.grey.shade700 : const Color(0xFF10B981)).withOpacity(0.12),
            child: Icon(icon, color: onChanged == null ? Colors.grey : const Color(0xFF10B981)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: onChanged == null ? Colors.grey : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: val,
            onChanged: onChanged,
            activeColor: const Color(0xFF10B981),
            activeTrackColor: const Color(0xFF10B981).withOpacity(0.4),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }
}
Widget moneyCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required String trailing,
  VoidCallback? onTap,
}) {
  return SmoothTap(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [

          CircleAvatar(
            backgroundColor:
                const Color(0xFFE8FFF5),
            child: Icon(
              icon,
              color: const Color(0xFF059669),
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              trailing,
              style: const TextStyle(
                color: Color(0xFF059669),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget transactionTile(Map<String, dynamic> tx) {
  String title = tx["title"] ?? "Payment";
  String amount = tx["amount"] ?? "₹0.00";
  String status = tx["status"] ?? "SUCCESS";
  String name = tx["name"] ?? "";
  String number = tx["number"] ?? "";
  String date = tx["date"] ?? "";

  IconData icon;
  Color color;

  switch (status) {
    case "SUCCESS":
      icon = Icons.check_circle;
      color = Colors.green;
      break;
    case "BLOCKED":
      icon = Icons.cancel;
      color = Colors.red;
      break;
    default:
      icon = Icons.warning;
      color = Colors.orange;
  }

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          radius: 22,
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 3),
              if (name.isNotEmpty || number.isNotEmpty)
                Text(
                  "${name.isNotEmpty ? name : ''} ${number.isNotEmpty ? '($number)' : ''}".trim(),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (date.isNotEmpty)
                    Text(
                      date,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                ],
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: status == "BLOCKED" ? Colors.grey : (status == "SUCCESS" ? Colors.red.shade700 : Colors.black87),
          ),
        ),
      ],
    ),
  );
}

class SendUserPage extends StatefulWidget {
  const SendUserPage({super.key});

  @override
  State<SendUserPage> createState() => _SendUserPageState();
}

class _SendUserPageState extends State<SendUserPage> {
  TextEditingController userController = TextEditingController();

 @override
Widget build(BuildContext context) {

  return Scaffold(
    backgroundColor: const Color(0xFFF8FFFC),

    body: Column(
      children: [

        /// HEADER
        Container(
          width: double.infinity,
          height: 180,

          padding: const EdgeInsets.only(
            top: 55,
            left: 20,
            right: 20,
          ),

          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF34D399),
                Color(0xFF059669),
              ],
            ),

            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Send Money",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              TextField(
                controller: userController,

                decoration: InputDecoration(
                  hintText:
                      "Search contact or enter number",

                  prefixIcon:
                      const Icon(Icons.search),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                /// QUICK SERVICES

                const Text(
                  "Quick Services",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceAround,

                  children: [

                    quickOption(
                      Icons.phone_android,
                      "Recharge",
                    ),

                    quickOption(
                      Icons.tv,
                      "DTH",
                    ),

                    quickOption(
                      Icons.card_giftcard,
                      "Gift Cards",
                    ),

                    quickOption(
                      Icons.star,
                      "Favorites",
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// RECENT CONTACTS

                const Text(
                  "Recent Contacts",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                recentContact("Rahul"),
                recentContact("Priya"),
                recentContact("Amazon"),
                recentContact("Netflix"),
                recentContact("Divya"),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                              0xFF059669),

                      foregroundColor:
                          Colors.white,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                                    18),
                      ),
                    ),

                    onPressed: () {

                      if (userController.text
                          .trim()
                          .isEmpty) {
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PaymentPage(
                            qrData:
                                "manual://pay",

                            riskScore: 20,

                            receiverName:
                                userController
                                    .text,
                          ),
                        ),
                      );
                    },

                    child: const Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
Widget quickOption(
  IconData icon,
  String title,
) {

  return Column(
    children: [

      Container(
        width: 65,
        height: 65,

        decoration: BoxDecoration(
          color:
              const Color(0xFFE8FFF5),

          borderRadius:
              BorderRadius.circular(
                  18),
        ),

        child: Icon(
          icon,
          color:
              const Color(0xFF059669),
        ),
      ),

      const SizedBox(height: 8),

      Text(
        title,
        style:
            const TextStyle(fontSize: 12),
      ),
    ],
  );
}
Widget recentContact(
  String name,
) {

  return ListTile(

    contentPadding:
        EdgeInsets.zero,

    leading: CircleAvatar(
      backgroundColor:
          const Color(0xFFE8FFF5),

      child: Text(
        name[0],

        style: const TextStyle(
          color: Color(0xFF059669),
          fontWeight:
              FontWeight.bold,
        ),
      ),
    ),

    title: Text(name),

    trailing:
        const Icon(Icons.chevron_right),

    onTap: () {

      userController.text = name;
    },
  );
}
}

class BillsPage extends StatelessWidget {
  const BillsPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),

      body: Column(
        children: [

          /// HEADER
          Container(
            width: double.infinity,
            height: 170,

            padding: const EdgeInsets.only(
              top: 55,
              left: 20,
              right: 20,
            ),

            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF34D399),
                  Color(0xFF059669),
                ],
              ),

              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Bills & Recharge",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                const Text(
                  "Manage and pay your bills",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    "Categories",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),

                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,

                    children: [

                      billCategory(
                        Icons.phone_android,
                        "Mobile",
                      ),

                      billCategory(
                        Icons.tv,
                        "DTH",
                      ),

                      billCategory(
                        Icons.flash_on,
                        "Electricity",
                      ),

                      billCategory(
                        Icons.water_drop,
                        "Water",
                      ),

                      billCategory(
                        Icons.wifi,
                        "Internet",
                      ),

                      billCategory(
                        Icons.local_gas_station,
                        "Gas",
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Upcoming Bills",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  billCard(
                    "Electricity Bill",
                    "Due in 4 days",
                    "₹1,250",
                  ),

                  billCard(
                    "Broadband",
                    "Due in 8 days",
                    "₹899",
                  ),

                  billCard(
                    "Mobile Recharge",
                    "Expires tomorrow",
                    "₹299",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget billCategory(
    IconData icon,
    String title,
  ) {

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),

      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Icon(
            icon,
            size: 30,
            color: const Color(
              0xFF059669,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget billCard(
    String title,
    String due,
    String amount,
  ) {

    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),

      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),

      child: Row(
        children: [

          Container(
            width: 50,
            height: 50,

            decoration: BoxDecoration(
              color:
                  const Color(0xFFE8FFF5),

              borderRadius:
                  BorderRadius.circular(
                      14),
            ),

            child: const Icon(
              Icons.receipt_long,
              color:
                  Color(0xFF059669),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  title,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                Text(
                  due,
                  style:
                      const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          Text(
            amount,
            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  TextEditingController userController = TextEditingController();

  @override
Widget build(BuildContext context) {

  return Scaffold(
    backgroundColor: const Color(0xFFF8FFFC),

    body: Column(
      children: [

        /// HEADER
        Container(
          width: double.infinity,
          height: 180,

          padding: const EdgeInsets.only(
            top: 55,
            left: 20,
            right: 20,
          ),

          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF34D399),
                Color(0xFF059669),
              ],
            ),

            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Request Money",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              TextField(
                controller: userController,

                decoration: InputDecoration(
                  hintText:
                      "Search contact or enter number",

                  prefixIcon:
                      const Icon(Icons.search),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                const Text(
                  "Quick Amount",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,

                  children: [
                    amountChip("₹100"),
                    amountChip("₹500"),
                    amountChip("₹1000"),
                    amountChip("₹2000"),
                  ],
                ),

                const SizedBox(height: 30),

                const Text(
                  "Recent Contacts",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                recentContact("Rahul"),
                recentContact("Priya"),
                recentContact("Amazon"),
                recentContact("Divya"),

                const SizedBox(height: 25),

                TextField(
                  decoration: InputDecoration(
                    labelText:
                        "Reason for Request",

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                              18),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                              0xFF059669),

                      foregroundColor:
                          Colors.white,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                                    18),
                      ),
                    ),

                    onPressed: () {

                      if (userController.text
                          .trim()
                          .isEmpty) {
                        return;
                      }

                      showDialog(
                        context: context,

                        builder: (_) =>
                            AlertDialog(
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    20),
                          ),

                          title: const Text(
                            "Request Sent",
                          ),

                          content: Text(
                            "Payment request sent to ${userController.text}",
                          ),

                          actions: [

                            TextButton(
                              onPressed: () {

                                Navigator.pop(
                                    context);

                                Navigator.pop(
                                    context);
                              },

                              child:
                                  const Text(
                                      "OK"),
                            ),
                          ],
                        ),
                      );
                    },

                    child: const Text(
                      "Send Request",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
Widget amountChip(
  String amount,
) {

  return Container(
    padding:
        const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 10,
    ),

    decoration: BoxDecoration(
      color: const Color(0xFFE8FFF5),

      borderRadius:
          BorderRadius.circular(20),
    ),

    child: Text(
      amount,

      style: const TextStyle(
        color: Color(0xFF059669),
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
Widget recentContact(
  String name,
) {

  return ListTile(

    contentPadding:
        EdgeInsets.zero,

    leading: CircleAvatar(
      backgroundColor:
          const Color(0xFFE8FFF5),

      child: Text(
        name[0],

        style: const TextStyle(
          color: Color(0xFF059669),
          fontWeight:
              FontWeight.bold,
        ),
      ),
    ),

    title: Text(name),

    trailing:
        const Icon(Icons.chevron_right),

    onTap: () {

      userController.text = name;
    },
  );
}
}

class BankTransferPage extends StatefulWidget {
  const BankTransferPage({super.key});

  @override
  State<BankTransferPage> createState() => _BankTransferPageState();
}

class _BankTransferPageState extends State<BankTransferPage> {

  TextEditingController accController = TextEditingController();
  TextEditingController ifscController = TextEditingController();
  TextEditingController bankController = TextEditingController();

  @override
Widget build(BuildContext context) {

  return Scaffold(
    backgroundColor: const Color(0xFFF8FFFC),

    body: Column(
      children: [

        /// HEADER
        Container(
          width: double.infinity,
          height: 170,

          padding: const EdgeInsets.only(
            top: 55,
            left: 20,
            right: 20,
          ),

          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF34D399),
                Color(0xFF059669),
              ],
            ),

            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Bank Transfer",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              const Text(
                "Transfer directly to bank account",
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                /// ACCOUNT CARD

                Container(
                  padding:
                      const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(
                            20),

                    boxShadow: const [
                      BoxShadow(
                        color:
                            Colors.black12,
                        blurRadius: 8,
                      ),
                    ],
                  ),

                  child: const Row(
                    children: [

                      CircleAvatar(
                        radius: 25,

                        backgroundColor:
                            Color(
                                0xFFE8FFF5),

                        child: Icon(
                          Icons
                              .account_balance,
                          color: Color(
                              0xFF059669),
                        ),
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [

                            Text(
                              "Indian Overseas Bank",

                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            Text(
                              "Savings Account ••••8742",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                /// ACCOUNT NUMBER

                TextField(
                  controller:
                      accController,

                  decoration:
                      InputDecoration(
                    labelText:
                        "Account Number",

                    prefixIcon:
                        const Icon(
                      Icons.credit_card,
                    ),

                    filled: true,
                    fillColor:
                        Colors.white,

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                              18),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                /// IFSC

                TextField(
                  controller:
                      ifscController,

                  decoration:
                      InputDecoration(
                    labelText:
                        "IFSC Code",

                    prefixIcon:
                        const Icon(
                      Icons.qr_code,
                    ),

                    filled: true,
                    fillColor:
                        Colors.white,

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                              18),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                /// BANK

                TextField(
                  controller:
                      bankController,

                  decoration:
                      InputDecoration(
                    labelText:
                        "Bank Name",

                    prefixIcon:
                        const Icon(
                      Icons.account_balance,
                    ),

                    filled: true,
                    fillColor:
                        Colors.white,

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                              18),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                /// INFO CARD

                Container(
                  padding:
                      const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color:
                        const Color(
                            0xFFE8FFF5),

                    borderRadius:
                        BorderRadius.circular(
                            18),
                  ),

                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      Icon(
                        Icons.security,
                        color: Color(
                            0xFF059669),
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          "Transfers are protected by SentryPay risk analysis and secure verification.",
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                /// PROCEED BUTTON

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                              0xFF059669),

                      foregroundColor:
                          Colors.white,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                                    18),
                      ),
                    ),

                    onPressed: () {

                      if (accController
                              .text
                              .isEmpty ||
                          ifscController
                              .text
                              .isEmpty ||
                          bankController
                              .text
                              .isEmpty) {
                        return;
                      }

                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) =>
                              PaymentPage(
                            qrData:
                                "bank://transfer",

                            riskScore: 30,

                            receiverName:
                                bankController
                                    .text,
                          ),
                        ),
                      );
                    },

                    child: const Text(
                      "Proceed Transfer",

                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
}

class ScamDetectionPage extends StatefulWidget {
  const ScamDetectionPage({super.key});

  @override
  State<ScamDetectionPage> createState() => _ScamDetectionPageState();
}

class _ScamDetectionPageState extends State<ScamDetectionPage> {

  TextEditingController messageController =
    TextEditingController();

String suspiciousWords = "";

String result = "";

String reason = "";

int riskScore = 0;

Color resultColor = Colors.green;

  List<String> attachedFiles = [];

  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastRecognizedWords = "";

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    bool hasPermission = await Permission.microphone.request().isGranted;
    if (hasPermission) {
      await _speech.initialize();
      setState(() {});
    }
  }

  void _attachAndTranscribeAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isListening = true; // We use this flag to show loading state
      });
      
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://sentrypay-backend.onrender.com/api/audio/transcribe'), // Uses your Render backend
        );
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            result.files.single.path!,
          ),
        );

        var response = await request.send();
        if (response.statusCode == 200) {
          var responseData = await response.stream.bytesToString();
          var data = jsonDecode(responseData);
          if (data['text'] != null && data['text'].toString().isNotEmpty) {
            setState(() {
              messageController.text = data['text'];
            });
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not transcribe audio')),
            );
          }
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${response.statusCode}')),
            );
        }
      } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading audio: $e')),
         );
      } finally {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  void showAttachFileDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Attach Suspicious File/Document",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Select a template file below to simulate uploading an email attachment, document, or screenshot.",
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFECEF),
                  child: Icon(Icons.picture_as_pdf, color: Colors.red),
                ),
                title: const Text("Amazon_Invoice_9482.pdf"),
                subtitle: const Text("Simulates order confirmation phishing link"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    attachedFiles = ["Amazon_Invoice_9482.pdf"];
                    messageController.text =
                        "Dear Customer,\n\nWe successfully processed your Amazon order payment of \$1,299.99 for Apple MacBook Air. If you did not make this purchase, immediately login to cancel your payment to avoid fraud charges: http://amazon-secure-order.bit.ly/cancel";
                  });
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFFAEB),
                  child: Icon(Icons.article, color: Colors.orange),
                ),
                title: const Text("IRS_Tax_Refund_Notice.txt"),
                subtitle: const Text("Simulates government/KYC impersonation scam"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    attachedFiles = ["IRS_Tax_Refund_Notice.txt"];
                    messageController.text =
                        "IRS Notice: You have a pending tax refund of \$489.50. To claim your refund, click this link immediately to verify your identity and banking credentials: http://verify-irs-tax.xyz/refund";
                  });
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEEF2FF),
                  child: Icon(Icons.image, color: Colors.blue),
                ),
                title: const Text("Win_Cash_Lottery.png"),
                subtitle: const Text("Simulates cash reward lottery ticket scam"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    attachedFiles = ["Win_Cash_Lottery.png"];
                    messageController.text =
                        "CONGRATULATIONS!\n\nYou have been selected as the Grand Prize Winner of the \$1,000,000 Cash Reward! To claim your winnings, click here to contact our transfer agent: http://claim-reward.top/fee";
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }



Future<void> analyzeMessage() async {

  String text =
      messageController.text.trim();

  if (text.isEmpty) return;

  setState(() {

    result = "Analyzing...";
    reason = "";
    suspiciousWords = "";
    riskScore = 0;

  });

  try {

    final response = await http.post(

      Uri.parse(
        "https://diva41-sentrypay-ai.hf.space/predict",
      ),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({
        "message": text,
      }),

    ).timeout(
      const Duration(seconds: 30),
    );

    debugPrint(response.body);

    if (response.statusCode == 200) {

      final data =
          jsonDecode(response.body);
      lastTransactionContext["scam_result"] = data;

      final reasons =
          data["reason"];

      final suspiciousKeywords =
          data["suspicious_keywords"];

      String formattedReason = "";

      if (reasons is List) {

        formattedReason =
            reasons.join("\n• ");

      } else {

        formattedReason =
            reasons.toString();
      }

      if (!mounted) return;

      setState(() {

        result =
            data["status"] ?? "UNKNOWN";

        suspiciousWords =
            suspiciousKeywords is List
                ? suspiciousKeywords.join(", ")
                : "";

        riskScore =
            (data["risk"] ?? 0).toInt();

        double confidence =
            (data["confidence"] ?? 0)
                .toDouble();

        reason =
            "Confidence: ${confidence.toStringAsFixed(2)}%\n\n• $formattedReason";

        if (riskScore >= 75) {

          resultColor = Colors.red;

        } else if (riskScore >= 40) {

          resultColor = Colors.orange;

        } else {

          resultColor = Colors.green;
        }
      });

    } else {

      if (!mounted) return;

      setState(() {

        result = "SERVER ERROR";

        reason =
            "Backend returned ${response.statusCode}";

        suspiciousWords = "";

        resultColor = Colors.red;
      });
    }

  } catch (e) {

    debugPrint(
      "Scam Detection Error: $e",
    );

    if (!mounted) return;

    setState(() {

      result = "ERROR";

      reason =
          "Unable to connect to AI server";

      suspiciousWords = "";

      resultColor = Colors.red;
    });
  }
}

 @override
Widget build(BuildContext context) {

  return Scaffold(
    backgroundColor: const Color(0xFFF8FFFC),

    body: Column(
      children: [

        /// HEADER
        Container(
          width: double.infinity,
          height: 160,

          padding: const EdgeInsets.only(
            top: 55,
            left: 20,
            right: 20,
          ),

          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF34D399),
                Color(0xFF059669),
              ],
            ),

            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Scam Check",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              const Text(
                "Analyze suspicious messages and scams",
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        /// SCROLLABLE CONTENT
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                /// INPUT LABEL
                const Text(
                  "Paste or Enter Message",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                /// INPUT BOX
                TextField(
                  controller: messageController,
                  maxLines: 5,

                  decoration: InputDecoration(
                    hintText:
                        "Enter suspicious message here...",

                    filled: true,
                    fillColor: Colors.white,

                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(
                        bottom: 70,
                      ),
                      child: Icon(
                        Icons.message,
                        color: Color(0xFF059669),
                      ),
                    ),

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),

                    contentPadding:
                        const EdgeInsets.all(18),
                  ),
                ),

                const SizedBox(height: 10),

                if (attachedFiles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: attachedFiles.map((fileName) {
                        return Chip(
                          backgroundColor: const Color(0xFFE8FFF5),
                          avatar: Icon(
                            fileName.endsWith('.png') || fileName.endsWith('.jpg')
                                ? Icons.image
                                : Icons.insert_drive_file,
                            size: 16,
                            color: const Color(0xFF059669),
                          ),
                          label: Text(
                            fileName,
                            style: const TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 14,
                            color: Color(0xFF059669),
                          ),
                          onDeleted: () {
                            setState(() {
                              attachedFiles.remove(fileName);
                              if (attachedFiles.isEmpty) {
                                messageController.clear();
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _attachAndTranscribeAudio,
                    icon: _isListening ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.attach_file, size: 18),
                    label: Text(
                      _isListening ? "Transcribing..." : "Attach Voice message",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: const BorderSide(color: Color(0xFF34D399)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: _isListening ? const Color(0xFFD1FAE5) : null,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// ANALYZE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    onPressed: analyzeMessage,

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF059669),

                      foregroundColor:
                          Colors.white,

                      elevation: 4,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                    ),

                    child: const Text(
                      "Analyze Message",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                /// RESULT CARD
                if (result.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(18),

                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Row(
                          children: [

                            Icon(
                              Icons.verified_user,
                              color: resultColor,
                              size: 30,
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                result,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.bold,
                                  color: resultColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Text(
  "Risk Score: $riskScore%",
  style: TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.bold,
    color: resultColor,
  ),
),

const SizedBox(height: 10),

Text(
  reason,
  style: const TextStyle(
    fontSize: 15,
  ),
),

if (suspiciousWords.isNotEmpty) ...[

  const SizedBox(height: 15),

  Text(
    "🚨 Suspicious Keywords:\n$suspiciousWords",
    style: const TextStyle(
      color: Colors.red,
      fontWeight: FontWeight.bold,
    ),
  ),
],
                      ],
                    ),
                  ),

                const SizedBox(height: 25),

                /// SECURITY TIPS
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(18),

                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),

                  child: const Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        "Security Tips",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 12),

                      Text(
                        "• Never share OTPs or PINs",
                      ),

                      SizedBox(height: 5),

                      Text(
                        "• Verify unknown senders",
                      ),

                      SizedBox(height: 5),

                      Text(
                        "• Avoid clicking suspicious links",
                      ),

                      SizedBox(height: 5),

                      Text(
                        "• Check URLs before making payments",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
@override
void dispose() {
  messageController.dispose();
  super.dispose();
}
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
Widget build(BuildContext context) {

  return Scaffold(
    backgroundColor: const Color(0xFFF8FFFC),

    body: Column(
      children: [

        /// HEADER
        Container(
          width: double.infinity,
          height: 200,

          padding: const EdgeInsets.only(
            top: 55,
            left: 20,
            right: 20,
          ),

          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF34D399),
                Color(0xFF059669),
              ],
            ),

            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),

          child: Row(
            children: [

              /// USER INFO
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [

                    Text(
                      "Dilip Velayutham",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      "dilipvelayuthamiob@sentrypay",
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),

                    SizedBox(height: 8),

                    Row(
                      children: [

                        Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 18,
                        ),

                        SizedBox(width: 4),

                        Text(
                          "Protected by SentryPay",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              /// PROFILE PHOTO
              Container(
                padding: const EdgeInsets.all(3),

                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFFD1FAE5),
                    width: 3,
                  ),
                ),

                child: const CircleAvatar(
                  radius: 42,
                  backgroundImage: AssetImage(
                    "assets/Casual Profile.jpeg",
                  ),
                ),
              ),
            ],
          ),
        ),
 
        const SizedBox(height: 20),
        /// SCROLLABLE CONTENT
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [

                  profileCard(
                    Icons.account_balance,
                    "Bank Account",
                    "Indian Overseas Bank ••••8742",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BankAccountPage(),
                        ),
                      );
                    },
                  ),

                  profileCard(
                    Icons.phone,
                    "Phone Number",
                    "+91 97904 68298",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PhoneNumberPage(),
                        ),
                      );
                    },
                  ),

                  profileCard(
                    Icons.qr_code,
                    "My QR Code",
                    "Show personal payment QR",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScanPage(initialTab: 1),
                        ),
                      );
                    },
                  ),

                  profileCard(
                    Icons.manage_accounts,
                    "Manage Account",
                    "Profile & account settings",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageAccountPage(),
                        ),
                      );
                    },
                  ),

                  profileCard(
                    Icons.settings,
                    "Settings",
                    "Security, notifications & more",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsPage(),
                        ),
                      );
                    },
                  ),

                  profileCard(
                    Icons.logout,
                    "Logout",
                    "Sign out from SentryPay",
                    iconColor: Colors.red,
                    onTap: () {
                      _showLogoutDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget profileCard(
  IconData icon,
  String title,
  String subtitle, {
  Color iconColor = const Color(0xFF059669),
  VoidCallback? onTap,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),

    decoration: const BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),

    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8FFF5),

          child: Icon(
            icon,
            color: iconColor,
          ),
        ),

        title: Text(title),

        subtitle: Text(subtitle),

        trailing: const Icon(
          Icons.chevron_right,
        ),

        onTap: onTap,
      ),
    ),
  );
}
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),

      body: Column(
        children: [

          /// HEADER
          Container(
            width: double.infinity,
            height: 160,

            padding: const EdgeInsets.only(
              top: 55,
              left: 20,
              right: 20,
            ),

            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF34D399),
                  Color(0xFF059669),
                ],
              ),

              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),

            child: const Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [

                Text(
                  "More",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  "Security tools and extra features",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [

                  moreTile(
                    context,
                    Icons.security,
                    "Scam Check",
                    "Check suspicious messages and links",
                    const ScamDetectionPage(),
                  ),

                  moreTile(
                    context,
                    Icons.qr_code_scanner,
                    "QR Intelligence",
                    "Learn about QR risk detection",
                    const QrIntelligencePage(),
                  ),

                  moreTile(
                    context,
                    Icons.warning_amber,
                    "Fraud Alerts",
                    "Latest scam awareness",
                    const FraudAlertsPage(),
                  ),

                  moreTile(
                    context,
                    Icons.tips_and_updates,
                    "Security Tips",
                    "Stay protected from fraud",
                    const SecurityTipsPage(),
                  ),

                  moreTile(
                    context,
                    Icons.info_outline,
                    "About SentryPay",
                    "Version & project information",
                    const AboutSentryPayPage(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
Widget moreTile(
  BuildContext context,
  IconData icon,
  String title,
  String subtitle,
  Widget? page,
) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),

    decoration: const BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),

    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8FFF5),

          child: Icon(
            icon,
            color: const Color(0xFF059669),
          ),
        ),

        title: Text(title),

        subtitle: Text(subtitle),

        trailing: const Icon(
          Icons.chevron_right,
        ),

        onTap: () {

          if (page != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => page,
              ),
            );
          }
        },
      ),
    ),
  );
}

class BusinessInteractionPage extends StatefulWidget {
  final String businessName;

  const BusinessInteractionPage({super.key, required this.businessName});

  @override
  State<BusinessInteractionPage> createState() => _BusinessInteractionPageState();
}

class _BusinessInteractionPageState extends State<BusinessInteractionPage> {
  int _selectedPlanIndex = 0;
  final List<Map<String, dynamic>> _netflixPlans = [
    {"name": "Mobile Plan", "price": "149", "desc": "1 Screen, 480p resolution"},
    {"name": "Basic Plan", "price": "199", "desc": "1 Screen, 720p resolution"},
    {"name": "Standard Plan", "price": "499", "desc": "2 Screens, 1080p resolution"},
    {"name": "Premium Plan", "price": "649", "desc": "4 Screens, 4K+HDR resolution"},
  ];
  final List<Map<String, dynamic>> _spotifyPlans = [
    {"name": "Individual Mini", "price": "25", "desc": "1 Account, 1 Week premium"},
    {"name": "Individual Monthly", "price": "119", "desc": "1 Account, 1 Month premium"},
    {"name": "Duo Monthly", "price": "149", "desc": "2 Accounts, 1 Month premium"},
    {"name": "Family Monthly", "price": "179", "desc": "6 Accounts, 1 Month premium"},
  ];
  final List<Map<String, dynamic>> _amazonPlans = [
    {"name": "Prime Shopping Edition", "price": "399", "desc": "1 Year free shopping & delivery"},
    {"name": "Prime Lite Annual", "price": "799", "desc": "1 Year prime video (720p) & delivery"},
    {"name": "Prime Monthly", "price": "299", "desc": "Full Prime features for 1 Month"},
    {"name": "Prime Annual", "price": "1499", "desc": "Full Prime features for 1 Year"},
  ];

  final TextEditingController _pickupController = TextEditingController(text: "Your Current Location");
  final TextEditingController _dropController = TextEditingController();
  int _selectedRideIndex = 0;
  final List<Map<String, dynamic>> _rides = [
    {"type": "Moto Bike", "price": "55", "time": "2 mins away", "icon": Icons.motorcycle},
    {"type": "Auto Rickshaw", "price": "110", "time": "4 mins away", "icon": Icons.electric_rickshaw},
    {"type": "Go Mini Hatch", "price": "175", "time": "3 mins away", "icon": Icons.directions_car},
    {"type": "Prime Sedan Lux", "price": "240", "time": "5 mins away", "icon": Icons.local_taxi},
  ];

  final Map<int, int> _cartQuantities = {};
  final List<Map<String, dynamic>> _foodItems = [
    {"id": 1, "name": "Classic Veg Burger", "price": 129, "desc": "Crispy veg patty with cheese and mayo"},
    {"id": 2, "name": "Cheese Pepperoni Pizza", "price": 349, "desc": "Mozzarella cheese, pepperoni slices, fresh crust"},
    {"id": 3, "name": "Chocolate Brownie Shake", "price": 149, "desc": "Rich milk chocolate blended with brownie chunks"},
    {"id": 4, "name": "Paneer Butter Masala Combo", "price": 249, "desc": "Paneer masala with 2 Butter Naan and Salad"},
  ];
  final List<Map<String, dynamic>> _ecommerceItems = [
    {"id": 1, "name": "Noise ColorFit Smartwatch", "price": 1899, "desc": "1.8-inch display, health tracking, BT calling"},
    {"id": 2, "name": "OnePlus Nord Buds 2", "price": 2499, "desc": "Active Noise Cancellation, 36hr battery, BT Calling"},
    {"id": 3, "name": "Mi Power Bank 3i 20000mAh", "price": 2199, "desc": "18W Fast Charging, Triple Port Output, Sandstone finish"},
    {"id": 4, "name": "SentryPay Smart Hardware Shield", "price": 4999, "desc": "Secure physical OTP token for SentryPay transactions"},
  ];

  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _customInvoiceController = TextEditingController();

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    _customAmountController.dispose();
    _customInvoiceController.dispose();
    super.dispose();
  }

  String _getLogoPath(String name) {
    final lowercase = name.toLowerCase();
    final extensions = {
      'netflix': 'jpg',
      'ola': 'jpg',
      'swiggy': 'jpg',
      'zomato': 'jpg',
      'amazon': 'png',
      'flipkart': 'png',
      'spotify': 'png',
      'uber': 'png',
    };
    final ext = extensions[lowercase] ?? 'png';
    return 'assets/business/$lowercase.$ext';
  }

  void _initiatePayment(String amount) {
    if (double.tryParse(amount) == null || double.parse(amount) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter or select a valid amount."), backgroundColor: Colors.red),
      );
      return;
    }

    final String qrUri = "upi://pay?pa=${widget.businessName.toLowerCase()}@sentrypay&pn=${widget.businessName}&am=$amount";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisPage(
          qrData: qrUri,
          isAnalysisOnly: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lowercase = widget.businessName.toLowerCase();
    final bool isSubscription = ["netflix", "spotify", "amazon"].contains(lowercase);
    final bool isRide = ["uber", "ola"].contains(lowercase);
    final bool isOrder = ["swiggy", "zomato", "flipkart"].contains(lowercase);

    Widget pageBody;

    if (isSubscription) {
      final plans = lowercase == "netflix" 
          ? _netflixPlans 
          : (lowercase == "spotify" ? _spotifyPlans : _amazonPlans);
      
      pageBody = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select a Subscription Plan",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final p = plans[index];
                final isSelected = _selectedPlanIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlanIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF10B981).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF10B981) : Colors.white24,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p["name"],
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p["desc"],
                                style: const TextStyle(color: Colors.white60, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "₹${p["price"]}",
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF10B981) : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                _initiatePayment(plans[_selectedPlanIndex]["price"]);
              },
              child: Text(
                "Subscribe & Pay (₹${plans[_selectedPlanIndex]["price"]})",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    } else if (isRide) {
      pageBody = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Book a Ride",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pickupController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Pickup Address",
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.my_location, color: Color(0xFF10B981)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dropController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Destination Address",
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.location_on, color: Colors.red),
              hintText: "Enter destination",
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Available Rides",
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _rides.length,
              itemBuilder: (context, index) {
                final r = _rides[index];
                final isSelected = _selectedRideIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRideIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF10B981).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF10B981) : Colors.white24,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(r["icon"], color: isSelected ? const Color(0xFF10B981) : Colors.white70, size: 30),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r["type"],
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                r["time"],
                                style: const TextStyle(color: Colors.white60, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "₹${r["price"]}",
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF10B981) : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                if (_dropController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please specify your destination drop location."), backgroundColor: Colors.red),
                  );
                  return;
                }
                _initiatePayment(_rides[_selectedRideIndex]["price"]);
              },
              child: Text(
                "Book & Pay (₹${_rides[_selectedRideIndex]["price"]})",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    } else if (isOrder) {
      final items = lowercase == "flipkart" ? _ecommerceItems : _foodItems;
      double total = 0;
      _cartQuantities.forEach((index, qty) {
        if (qty > 0) {
          total += items[index]["price"] * qty;
        }
      });

      pageBody = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Items to Order",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final it = items[index];
                final qty = _cartQuantities[index] ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it["name"],
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              it["desc"],
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "₹${it["price"]}",
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: qty > 0 
                                ? () {
                                    setState(() {
                                      _cartQuantities[index] = qty - 1;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
                          ),
                          Text(
                            "$qty",
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _cartQuantities[index] = qty + 1;
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Grand Total:",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "₹${total.toInt()}",
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: total > 0 
                  ? () {
                      _initiatePayment(total.toInt().toString());
                    }
                  : null,
              child: Text(
                "Place Order & Pay (₹${total.toInt()})",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    } else {
      pageBody = SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pay Invoice / Bill",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customAmountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Enter Amount (₹)",
                labelStyle: const TextStyle(color: Colors.white70),
                prefixText: "₹ ",
                prefixStyle: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customInvoiceController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Invoice / Bill Notes",
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: "Enter details (e.g. consultation fee, payment ref)",
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  _initiatePayment(_customAmountController.text.trim());
                },
                child: const Text(
                  "Proceed with Payment",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final hasAsset = ["netflix", "spotify", "amazon", "uber", "ola", "swiggy", "zomato", "flipkart"].contains(lowercase);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(widget.businessName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: getContactDetails(widget.businessName).avatarColor,
                    backgroundImage: hasAsset ? AssetImage(_getLogoPath(widget.businessName)) : null,
                    child: !hasAsset 
                        ? Text(
                            widget.businessName[0], 
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.businessName,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "Verified Business",
                                style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Score: ${getContactDetails(widget.businessName).riskScore}/15",
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: pageBody),
          ],
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {

  final String contactName;

  const ChatPage({
    super.key,
    required this.contactName,
  });

  @override
  State<ChatPage> createState() =>
      _ChatPageState();
}

class _ChatPageState
    extends State<ChatPage> {

  final TextEditingController
      messageController =
          TextEditingController();

  final List<Map<String, dynamic>>
      messages = [

    {
      "text": "Hi 👋",
      "mine": false,
    },

    {
      "text": "Hello!",
      "mine": true,
    },

    {
      "text": "How are you?",
      "mine": false,
    },
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FFFC),

      body: Column(
        children: [

          /// HEADER
          Container(
            width: double.infinity,
            height: 130,

            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
            ),

            decoration:
                const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,

                colors: [
                  Color(0xFF34D399),
                  Color(0xFF059669),
                ],
              ),

              borderRadius:
                  BorderRadius.only(
                bottomLeft:
                    Radius.circular(30),
                bottomRight:
                    Radius.circular(30),
              ),
            ),

            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ContactProfilePage(
                            contactName:
                                widget.contactName,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: getContactDetails(widget.contactName).avatarColor,
                          child: Text(
                            widget.contactName[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.contactName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// MESSAGES
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.all(
                      16),

              itemCount:
                  messages.length,

              itemBuilder:
                  (context, index) {

                return messageBubble(
                  messages[index]
                      ["text"],

                  messages[index]
                      ["mine"],
                );
              },
            ),
          ),

          /// INPUT AREA
          Container(
            padding:
                const EdgeInsets.all(
                    12),

            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller:
                        messageController,

                    decoration:
                        InputDecoration(
                      hintText:
                          "Type message",

                      filled: true,

                      fillColor:
                          Colors.white,

                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                                20),

                        borderSide:
                            BorderSide
                                .none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                    width: 8),

                /// SEND BUTTON
                Container(
                  decoration:
                      const BoxDecoration(
                    color:
                        Color(
                            0xFF059669),

                    shape:
                        BoxShape.circle,
                  ),

                  child: IconButton(
                    icon:
                        const Icon(
                      Icons.send,
                      color:
                          Colors.white,
                    ),

                    onPressed: () {

                      if (messageController
                          .text
                          .trim()
                          .isEmpty) {
                        return;
                      }

                      setState(() {

                        messages.add({
                          "text":
                              messageController
                                  .text,

                          "mine": true,
                        });

                        messageController
                            .clear();
                      });
                    },
                  ),
                ),

                const SizedBox(
                    width: 8),

                /// PAY BUTTON
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.payments,
                  ),

                  label:
                      const Text(
                    "Pay",
                  ),

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        const Color(
                            0xFF059669),

                    foregroundColor:
                        Colors.white,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                              18),
                    ),
                  ),

                  onPressed: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PaymentPage(
                          qrData:
                              "manual://pay",

                          riskScore: 10,

                          receiverName:
                              widget
                                  .contactName,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget messageBubble(
    String text,
    bool mine,
  ) {

    return Align(
      alignment: mine
          ? Alignment.centerRight
          : Alignment.centerLeft,

      child: Container(
        margin:
            const EdgeInsets.symmetric(
          vertical: 5,
        ),

        padding:
            const EdgeInsets.all(
                12),

        decoration: BoxDecoration(
          color: mine
              ? const Color(
                  0xFF10B981)
              : Colors.white,

          borderRadius:
              BorderRadius.circular(
                  16),

          boxShadow: const [
            BoxShadow(
              color:
                  Colors.black12,

              blurRadius: 5,
            ),
          ],
        ),

        child: Text(
          text,

          style: TextStyle(
            color: mine
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
    );
  }
}

class ContactProfilePage
    extends StatelessWidget {

  final String contactName;

  const ContactProfilePage({
    super.key,
    required this.contactName,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FFFC),

      body: Column(
        children: [

          Container(
            width: double.infinity,
            height: 220,

            decoration:
                const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,

                colors: [
                  Color(0xFF34D399),
                  Color(0xFF059669),
                ],
              ),

              borderRadius:
                  BorderRadius.only(
                bottomLeft:
                    Radius.circular(30),

                bottomRight:
                    Radius.circular(30),
              ),
            ),

            child: Stack(
              children: [
                Positioned(
                  top: 50,
                  left: 15,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,

                    children: [

                      CircleAvatar(
                        radius: 45,
                        backgroundColor: getContactDetails(contactName).avatarColor,
                        child: Text(
                          contactName[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 12),

                      Text(
                        contactName,

                        style:
                            const TextStyle(
                          color:
                              Colors.white,

                          fontSize: 24,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          ListTile(
            leading:
                const Icon(
              Icons.phone,
            ),

            title:
                const Text(
              "Phone Number",
            ),

            subtitle:
                const Text(
              "+91 XXXXX XXXXX",
            ),
          ),

          ListTile(
            leading:
                const Icon(
              Icons.qr_code,
            ),

            title:
                const Text(
              "UPI ID",
            ),

            subtitle: Text(
              "${contactName.toLowerCase()}@sentrypay",
            ),
          ),

          ListTile(
            leading:
                const Icon(
              Icons.account_balance,
            ),

            title:
                const Text(
              "Bank",
            ),

            subtitle:
                const Text(
              "Indian Overseas Bank",
            ),
          ),
          ListTile(
            leading: const Icon(Icons.tag),
            title: const Text("Category / Relation"),
            subtitle: Text(getContactDetails(contactName).tag),
          ),
          ListTile(
            leading: Icon(
              Icons.warning_amber_rounded,
              color: getContactDetails(contactName).riskScore > 10
                  ? Colors.red
                  : (getContactDetails(contactName).riskScore > 5 ? Colors.orange : Colors.green),
            ),
            title: const Text("SentryPay Risk Score"),
            subtitle: Text("${getContactDetails(contactName).riskScore} / 15"),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (getContactDetails(contactName).riskScore > 10
                    ? Colors.red
                    : (getContactDetails(contactName).riskScore > 5 ? Colors.orange : Colors.green))
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                getContactDetails(contactName).riskScore > 10
                    ? "High Risk"
                    : (getContactDetails(contactName).riskScore > 5 ? "Medium Risk" : "Safe Contact"),
                style: TextStyle(
                  color: getContactDetails(contactName).riskScore > 10
                      ? Colors.red
                      : (getContactDetails(contactName).riskScore > 5 ? Colors.orange : Colors.green),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// NEW ACTIVE SCREENS AND HELPER FUNCTIONS
// ==========================================

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to sign out from SentryPay?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Pop profile page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Logged out successfully"),
                  backgroundColor: Color(0xFF059669),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Logout"),
          ),
        ],
      );
    },
  );
}

class BankAccountPage extends StatefulWidget {
  const BankAccountPage({super.key});

  @override
  State<BankAccountPage> createState() => _BankAccountPageState();
}

class _BankAccountPageState extends State<BankAccountPage> {
  String? _balanceText;

  void _checkBalance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UpiPinPage(
          amount: "0",
          riskScore: 0,
          suspiciousIntent: false,
          isBalanceCheck: true,
        ),
      ),
    ).then((value) {
      if (value == true) {
        setState(() {
          _balanceText = "₹${walletBalance.toStringAsFixed(2)}";
        });
      }
    });
  }

  void _resetUpiPin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Reset UPI PIN"),
        content: const Text("Would you like to reset your UPI PIN for Indian Overseas Bank?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("UPI PIN reset link sent to your registered mobile number"),
                  backgroundColor: Color(0xFF059669),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      body: Column(
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            height: 160,
            padding: const EdgeInsets.only(top: 55, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF34D399), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Bank Account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  "Linked bank and UPI details",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// BANK DETAILS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: Color(0xFFE8FFF5),
                              child: Icon(Icons.account_balance, color: Color(0xFF059669)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Indian Overseas Bank",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Savings Account •••• 8742",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        _buildDetailRow("Account Holder", "Dilip Velayutham"),
                        _buildDetailRow("IFSC Code", "IOBA0001234"),
                        _buildDetailRow("Branch", "Chennai Main Branch"),
                        _buildDetailRow("Status", "Active", valueColor: const Color(0xFF059669), isVerified: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  /// UPI DETAILS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "UPI Settings",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),
                        _buildDetailRow("UPI ID", "dilipvelayuthamiob@sentrypay"),
                        _buildDetailRow("Daily Limit", "₹1,00,000"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  /// ACTION BUTTONS
                  if (_balanceText != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8FFF5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF34D399), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Available Balance",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                          ),
                          Text(
                            _balanceText!,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _checkBalance,
                      icon: const Icon(Icons.account_balance_wallet),
                      label: const Text("Check Balance"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _resetUpiPin,
                      icon: const Icon(Icons.lock_reset),
                      label: const Text("Reset UPI PIN"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF059669),
                        side: const BorderSide(color: Color(0xFF059669)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isVerified = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
          Row(
            children: [
              if (isVerified) ...[
                const Icon(Icons.verified, color: Color(0xFF059669), size: 16),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PhoneNumberPage extends StatefulWidget {
  const PhoneNumberPage({super.key});

  @override
  State<PhoneNumberPage> createState() => _PhoneNumberPageState();
}

class _PhoneNumberPageState extends State<PhoneNumberPage> {
  bool _otpRequired = true;
  bool _smsAlerts = true;
  bool _whatsappAlerts = false;

  void _changePhoneNumber() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Change Phone Number"),
        content: const Text("To request a change of registered mobile number, please verify with an OTP sent to your email or contact SentryPay support."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Color(0xFF059669))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      body: Column(
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            height: 160,
            padding: const EdgeInsets.only(top: 55, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF34D399), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Phone Number",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  "Registered mobile number settings",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// PHONE CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: Color(0xFFE8FFF5),
                              child: Icon(Icons.phone, color: Color(0xFF059669)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "+91 97904 68298",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Primary Verified Number",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        _buildDetailRow("Verification Status", "Verified", valueColor: const Color(0xFF059669), isVerified: true),
                        _buildDetailRow("Registered On", "August 15, 2025"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  /// SECURITY SETTINGS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Security & OTP Settings",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          activeColor: const Color(0xFF059669),
                          contentPadding: EdgeInsets.zero,
                          title: const Text("High-Value Payment OTP"),
                          subtitle: const Text("Require SMS OTP for transactions above ₹10,000"),
                          value: _otpRequired,
                          onChanged: (val) {
                            setState(() {
                              _otpRequired = val;
                            });
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          activeColor: const Color(0xFF059669),
                          contentPadding: EdgeInsets.zero,
                          title: const Text("SMS Activity Alerts"),
                          subtitle: const Text("Receive instant SMS for every transaction activity"),
                          value: _smsAlerts,
                          onChanged: (val) {
                            setState(() {
                              _smsAlerts = val;
                            });
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          activeColor: const Color(0xFF059669),
                          contentPadding: EdgeInsets.zero,
                          title: const Text("WhatsApp Fraud Alerts"),
                          subtitle: const Text("Receive alert messages on WhatsApp when suspect activity is noticed"),
                          value: _whatsappAlerts,
                          onChanged: (val) {
                            setState(() {
                              _whatsappAlerts = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _changePhoneNumber,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Change Registered Number"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isVerified = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
          Row(
            children: [
              if (isVerified) ...[
                const Icon(Icons.verified, color: Color(0xFF059669), size: 16),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ManageAccountPage extends StatelessWidget {
  const ManageAccountPage({super.key});

  void _blockAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Temporarily Block Account"),
        content: const Text("This will prevent any payment outgoing from SentryPay. You can unblock it later by completing biometric verification. Proceed?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Account temporarily blocked. Secure shield enabled."),
                  backgroundColor: Colors.amber,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Block"),
          ),
        ],
      ),
    );
  }

  void _deleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to permanently delete your SentryPay account? This action is irreversible and all your transaction data will be erased."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Account deletion request submitted"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      body: Column(
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            height: 160,
            padding: const EdgeInsets.only(top: 55, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF34D399), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Manage Account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  "Profile and account details",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// PROFILE HEADER CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage("assets/Casual Profile.jpeg"),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "Dilip Velayutham",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "dilipvelayuthamiob@sentrypay",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8FFF5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.verified, color: Color(0xFF059669), size: 16),
                              SizedBox(width: 4),
                              Text(
                                "KYC Verified",
                                style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  /// DETAILS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Personal Information",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),
                        _buildDetailRow("Mobile Number", "+91 97904 68298"),
                        _buildDetailRow("KYC Document", "Aadhaar Card"),
                        _buildDetailRow("Gender", "Male"),
                        _buildDetailRow("Date of Birth", "12-05-1998"),
                        _buildDetailRow("Account Type", "Primary Personal"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  /// ACCOUNT CONTROLS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Danger Zone",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 15),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.block, color: Colors.amber),
                          title: const Text("Block Account"),
                          subtitle: const Text("Temporarily deactivate all transaction functionalities"),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _blockAccount(context),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.delete_forever, color: Colors.red),
                          title: const Text("Delete Account"),
                          subtitle: const Text("Permanently delete data and close SentryPay profile"),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _deleteAccount(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _biometricAuth = true;
  bool _sentryShield = true;
  bool _blockSuspicious = true;
  bool _pushNotifications = true;
  bool _emailAlerts = false;
  double _dailyLimit = 50000;

  void _savePreferences() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Preferences saved successfully"),
        backgroundColor: Color(0xFF059669),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      body: Column(
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            height: 160,
            padding: const EdgeInsets.only(top: 55, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF34D399), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Settings",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  "Security, notifications & preferences",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// SECURITY SETTINGS
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Security Settings",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          activeColor: const Color(0xFF059669),
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Biometric Login"),
                          subtitle: const Text("Use fingerprint or face recognition to unlock"),
                          value: _biometricAuth,
                          onChanged: (val) {
                            setState(() {
                              _biometricAuth = val;
                            });
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          activeColor: const Color(0xFF059669),
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Enable Sentry Shield"),
                          subtitle: const Text("Real-time transaction threat analysis"),
                          value: _sentryShield,
                          onChanged: (val) {
                            setState(() {
                              _sentryShield = val;
                            });
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          activeColor: const Color(0xFF059669),
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Block Suspicious Merchants"),
                          subtitle: const Text("Automatically block transactions to high-risk receivers"),
                          value: _blockSuspicious,
                          onChanged: (val) {
                            setState(() {
                              _blockSuspicious = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  /// TRANSACTION LIMIT
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Daily Limit",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "₹${_dailyLimit.toInt().toString()}",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Slider(
                          activeColor: const Color(0xFF059669),
                          inactiveColor: const Color(0xFFE8FFF5),
                          min: 5000,
                          max: 100000,
                          divisions: 19,
                          label: "₹${_dailyLimit.toInt()}",
                          value: _dailyLimit,
                          onChanged: (val) {
                            setState(() {
                              _dailyLimit = val;
                            });
                          },
                        ),
                        const Text(
                          "Drag slider to set your maximum daily outbound payment limit.",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  /// NOTIFICATIONS
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Notification Preferences",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          activeColor: const Color(0xFF059669),
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Push Notifications"),
                          subtitle: const Text("Instant payment alerts and security updates"),
                          value: _pushNotifications,
                          onChanged: (val) {
                            setState(() {
                              _pushNotifications = val;
                            });
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          activeColor: const Color(0xFF059669),
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Email Alerts"),
                          subtitle: const Text("Weekly summary reports and news"),
                          value: _emailAlerts,
                          onChanged: (val) {
                            setState(() {
                              _emailAlerts = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _savePreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Save Preferences"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QrIntelligencePage extends StatefulWidget {
  const QrIntelligencePage({super.key});

  @override
  State<QrIntelligencePage> createState() => _QrIntelligencePageState();
}

class _QrIntelligencePageState extends State<QrIntelligencePage> {
  final TextEditingController _urlController = TextEditingController();
  String _riskResult = "";
  Color _riskColor = Colors.green;
  String _riskReason = "";

  void _analyzeUrl() {
    String url = _urlController.text.trim().toLowerCase();
    if (url.isEmpty) return;

    bool isSuspicious = false;
    List<String> riskyKeywords = ["win", "free", "lottery", "prize", "refund", "claim", "gift", "giveaway", "credential", "login-upi", "verify-bank"];
    List<String> foundWords = [];

    for (var word in riskyKeywords) {
      if (url.contains(word)) {
        isSuspicious = true;
        foundWords.add(word);
      }
    }

    if (!url.startsWith("https://") && (url.startsWith("http://") || url.contains("www."))) {
      isSuspicious = true;
      foundWords.add("unsecured protocol (HTTP)");
    }

    setState(() {
      if (isSuspicious) {
        _riskResult = "⚠ HIGH RISK DETECTED";
        _riskColor = Colors.red;
        _riskReason = "This URL shows characteristics of a payment scam. Reasons: ${foundWords.join(', ')}. SentryPay advises not to send any funds to this address.";
      } else {
        _riskResult = "✅ VERIFIED SECURE";
        _riskColor = const Color(0xFF059669);
        _riskReason = "No suspicious pattern detected. The domain looks legitimate and uses a secure protocol. Safe to transact.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      body: Column(
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            height: 160,
            padding: const EdgeInsets.only(top: 55, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF34D399), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "QR Intelligence",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  "Learn about QR risk detection",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// INTRODUCTION CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "SentryPay QR Shield",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "Our QR intelligence engine analyzes UPI deep-links, web addresses, and merchant registration codes. Every time you scan a QR code using SentryPay, we verify it against three main pillars of threat detection.",
                          style: TextStyle(fontSize: 15, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  /// DETECTIVE METRIC CARDS
                  _buildPillarCard("1. Domain Analysis", "SentryPay checks if the QR contains links to external web addresses. If the domain is newly registered or resembles a popular bank's login site, we flag it.", Icons.dns),
                  _buildPillarCard("2. Merchant Reputation", "Our system checks the age and transaction volume history of the merchant. A new UPI ID requesting large funds is flagged as medium risk.", Icons.star_border),
                  _buildPillarCard("3. Secure Protocols Check", "Unsecured HTTP connections, raw IP addresses, or redirects inside the payment URL are automatically blocked to prevent phishing attacks.", Icons.security),
                  
                  const SizedBox(height: 25),
                  const Text(
                    "Try SentryPay QR Analyzer",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  /// INTERACTIVE WORKFLOW
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          size: 60,
                          color: Color(0xFF059669),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "Scan any UPI QR code or link to run a full risk assessment without initiating a payment.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ScanPage(isAnalysisOnly: true),
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text(
                              "Scan and Analyze QR",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarCard(String title, String description, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE8FFF5),
            child: Icon(icon, color: const Color(0xFF059669)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FraudAlertsPage extends StatefulWidget {
  const FraudAlertsPage({super.key});

  @override
  State<FraudAlertsPage> createState() => _FraudAlertsPageState();
}

class _FraudAlertsPageState extends State<FraudAlertsPage> {
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = "UPI Phishing ID";
  XFile? _screenshotFile;

  @override
  void dispose() {
    _targetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _screenshotFile = image;
        });
      }
    } catch (e) {
      debugPrint("Error picking screenshot: $e");
    }
  }

  void _submitReport() {
    if (_targetController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all the details before reporting."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Fraud Report Submitted"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your scam report has been received successfully! Our security analysts will verify the details immediately."),
            const SizedBox(height: 12),
            Text("Category: $_selectedCategory", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Target: ${_targetController.text}", style: const TextStyle(fontWeight: FontWeight.bold)),
            if (_screenshotFile != null) ...[
              const SizedBox(height: 4),
              Text("Screenshot: ${_screenshotFile!.name}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _targetController.clear();
                _descriptionController.clear();
                _screenshotFile = null;
              });
            },
            child: const Text("OK", style: TextStyle(color: Color(0xFF059669))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      body: Column(
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            height: 160,
            padding: const EdgeInsets.only(top: 55, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF34D399), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Fraud Alerts",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  "Latest scam awareness & community alerts",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ALERTS LIST
                  _buildAlertItem(
                    "Electricity Disconnection SMS Scam",
                    "Fraudsters send messages stating power will be cut tonight unless you call a given number. NEVER call or click such links.",
                    "CRITICAL ALERT",
                    Colors.red,
                  ),
                  _buildAlertItem(
                    "Fake Customer Care Search Fraud",
                    "Scammers upload false support numbers on Google Maps listings of banks. Always call numbers from official web pages.",
                    "HIGH THREAT",
                    Colors.orange,
                  ),
                  _buildAlertItem(
                    "UPI Refund and Reward Links",
                    "An SMS asking you to open a link to claim 'cashback' or 'gas subsidy refund' is fake. Remember, you never need a PIN to RECEIVE money.",
                    "CRITICAL ALERT",
                    Colors.red,
                  ),
                  _buildAlertItem(
                    "Express Courier / Delivery Scam",
                    "Demands are sent to pay customs or warehouse release charges for a package you never ordered. Do not pay.",
                    "ACTIVE THREAT",
                    Colors.amber[800]!,
                  ),

                  const SizedBox(height: 25),
                  const Text(
                    "Report a Suspicious Entity",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  /// REPORT FORM CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Submit Fraud Information",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Report a scammer's UPI ID, phone number, or URL to add to our SentryPay threat database.",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        
                        // Category Dropdown
                        const Text("Scam Type", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          items: [
                            "UPI Phishing ID",
                            "Fraudulent Website / URL",
                            "Impersonation SMS / Call",
                            "Lottery / Reward Link"
                          ].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategory = val;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FFFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Target Input
                        const Text("Offending UPI / Phone / URL", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _targetController,
                          decoration: InputDecoration(
                            hintText: "e.g. upi: fraud@okaxis, Phone: +91 98765...",
                            hintStyle: const TextStyle(fontSize: 14),
                            filled: true,
                            fillColor: const Color(0xFFF8FFFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Description Input
                        const Text("Scam Description", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: "Briefly explain what happened...",
                            hintStyle: const TextStyle(fontSize: 14),
                            filled: true,
                            fillColor: const Color(0xFFF8FFFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Image attachment picker
                        const Text("Proof Screenshot (Optional)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickScreenshot,
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: const Text("Select Image"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF059669),
                                side: const BorderSide(color: Color(0xFF34D399)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _screenshotFile != null
                                    ? _screenshotFile!.name
                                    : "No file selected",
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _submitReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Report Scam", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String title, String description, String badgeText, Color badgeColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.warning, color: Colors.amber, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class SecurityTipsPage extends StatefulWidget {
  const SecurityTipsPage({super.key});

  @override
  State<SecurityTipsPage> createState() => _SecurityTipsPageState();
}

class _SecurityTipsPageState extends State<SecurityTipsPage> {
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _isAnswered = false;
  int _score = 0;

  final List<Map<String, dynamic>> _quizQuestions = [
    {
      "question": "When receiving money via UPI, do you need to enter your UPI PIN?",
      "options": [
        "Yes, to confirm receipt.",
        "No, PIN is only needed to send money.",
        "Only if the amount is above ₹5,000."
      ],
      "correctIndex": 1,
      "explanation": "Correct! You never need to enter your UPI PIN to receive money. If someone asks you to enter your PIN to claim money, it is a scam!"
    },
    {
      "question": "An unknown sender claims they sent you money by mistake and asks you to pay it back. What should you do?",
      "options": [
        "Send it back immediately to be polite.",
        "Ignore them and ask them to coordinate with their bank.",
        "Keep the money and block them."
      ],
      "correctIndex": 1,
      "explanation": "Correct! Coordinates of the transaction must be settled officially through banks to prevent money mules or chargeback scams."
    },
    {
      "question": "What is the best way to contact SentryPay Customer Support?",
      "options": [
        "Google the support number online.",
        "Use the support details in the official app.",
        "Post on Twitter/X asking for help."
      ],
      "correctIndex": 1,
      "explanation": "Correct! Google maps or Twitter/X listings are frequently infested with fake helpline numbers. Always use official in-app contacts."
    }
  ];

  void _answerQuestion(int index) {
    if (_isAnswered) return;
    setState(() {
      _selectedAnswerIndex = index;
      _isAnswered = true;
      if (index == _quizQuestions[_currentQuestionIndex]["correctIndex"]) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_currentQuestionIndex < _quizQuestions.length - 1) {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _isAnswered = false;
      } else {
        _currentQuestionIndex = _quizQuestions.length;
      }
    });
  }

  void _resetQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswerIndex = null;
      _isAnswered = false;
      _score = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      body: Column(
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            height: 160,
            padding: const EdgeInsets.only(top: 55, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF34D399), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Security Tips",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  "Stay protected from digital fraud",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// SECURITY RULES LIST CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Crucial Rules of Safety",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                        const SizedBox(height: 15),
                        _buildTipRow(Icons.pin, "Never Share UPI PIN", "SentryPay or banks will never call and ask you for your PIN, OTP, or passwords."),
                        _buildTipRow(Icons.phonelink_erase, "Avoid Remote Apps", "Do not download screen sharing apps (e.g. AnyDesk, TeamViewer) at the request of anyone claiming to help."),
                        _buildTipRow(Icons.drive_file_rename_outline, "Verify Merchant Name", "Before typing your PIN in a transaction, read the verified merchant name displayed on the screen."),
                        _buildTipRow(Icons.mark_email_unread, "Beware of Suspicious Links", "Double check link addresses. Avoid payment clicks sent via WhatsApp or SMS."),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "SentryPay Security Quiz",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  /// INTERACTIVE QUIZ CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildQuizContent(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizContent() {
    if (_currentQuestionIndex >= _quizQuestions.length) {
      return Column(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 50),
          const SizedBox(height: 12),
          const Text("Quiz Finished!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            "You scored $_score / ${_quizQuestions.length}",
            style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          const Text(
            "Knowledge is your best armor against payment scams. Keep Sentry Shield active!",
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.3),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: _resetQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Restart Quiz"),
            ),
          )
        ],
      );
    }

    var q = _quizQuestions[_currentQuestionIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Question ${_currentQuestionIndex + 1}/${_quizQuestions.length}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            Text("Score: $_score", style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Text(q["question"], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        ...List.generate(q["options"].length, (idx) {
          Color btnColor = Colors.white;
          Color borderClr = Colors.grey[300]!;
          Color textClr = Colors.black87;

          if (_isAnswered) {
            if (idx == q["correctIndex"]) {
              btnColor = const Color(0xFFD1FAE5);
              borderClr = const Color(0xFF34D399);
              textClr = const Color(0xFF065F46);
            } else if (idx == _selectedAnswerIndex) {
              btnColor = const Color(0xFFFEE2E2);
              borderClr = const Color(0xFFF87171);
              textClr = const Color(0xFF991B1B);
            }
          }

          return SmoothTap(
            onTap: () => _answerQuestion(idx),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: btnColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderClr),
              ),
              child: Text(q["options"][idx], style: TextStyle(color: textClr, fontWeight: FontWeight.w500)),
            ),
          );
        }),
        if (_isAnswered) ...[
          const SizedBox(height: 10),
          Text(q["explanation"], style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.3)),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_currentQuestionIndex == _quizQuestions.length - 1 ? "Finish Quiz" : "Next Question"),
            ),
          )
        ]
      ],
    );
  }

  Widget _buildTipRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF059669), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AboutSentryPayPage extends StatelessWidget {
  const AboutSentryPayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      body: Column(
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            height: 160,
            padding: const EdgeInsets.only(top: 55, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF34D399), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "About SentryPay",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  "Version & developer details",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// LOGO CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: const [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.transparent,
                          backgroundImage: AssetImage("assets/logo2.png"),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "SentryPay",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Version 1.0.2",
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "AI-Powered Secure Payment Guard",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  /// DESCRIPTION CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "What is SentryPay?",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "SentryPay is an experimental mobile payment application integrated with ML-based risk engines. By evaluating merchant trust metrics, payment link protocols, and potential SMS patterns in real time, SentryPay aims to block fraud before money is lost.",
                          style: TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  /// LEGAL LINKS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Legal & Info",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        _buildLegalRow(context, "Terms of Service"),
                        const Divider(),
                        _buildLegalRow(context, "Privacy Policy"),
                        const Divider(),
                        _buildLegalRow(context, "Open Source Licenses"),
                        const Divider(),
                        _buildLegalRow(context, "Contact Support (support@sentrypay.com)"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalRow(BuildContext context, String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(title),
            content: Text("Mock content for $title. This information is for demonstration purposes in the SentryPay app."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(color: Color(0xFF059669))),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SentryChatPage extends StatefulWidget {
  const SentryChatPage({super.key});

  @override
  State<SentryChatPage> createState() => _SentryChatPageState();
}

class _SentryChatPageState extends State<SentryChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {
      "role": "sentry",
      "content": "Hi, I'm Sentry. How can I help you today?",
      "time": DateTime.now().toLocal().toString().substring(11, 16),
    }
  ];
  bool _isLoading = false;

  final List<String> _suggestions = [
    "Is my QR safe?",
    "Why is this payment risky?",
    "Explain Risk Score.",
    "What is QR phishing?",
    "How does Intent Verification work?",
    "Why do I need Face Verification?",
    "Safe payment tips.",
    "Common QR scams.",
    "Report suspicious activity.",
    "Help me understand this transaction."
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getChatbotUrl() {
    return "http://localhost:8003";
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = {
      "role": "user",
      "content": text,
      "time": DateTime.now().toLocal().toString().substring(11, 16),
    };

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse("${_getChatbotUrl()}/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "message": text,
          "context": lastTransactionContext,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data["response"] ?? "I couldn't process that request.";
        setState(() {
          _messages.add({
            "role": "sentry",
            "content": reply,
            "time": DateTime.now().toLocal().toString().substring(11, 16),
          });
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.add({
            "role": "sentry",
            "content": "Error: Sentry backend returned status ${response.statusCode}.",
            "time": DateTime.now().toLocal().toString().substring(11, 16),
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "sentry",
          "content": "Connection error: Sentry is offline. Please make sure the Sentry chatbot backend is running.",
          "time": DateTime.now().toLocal().toString().substring(11, 16),
        });
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _clearChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await http.post(Uri.parse("${_getChatbotUrl()}/clear"));
    } catch (_) {}

    setState(() {
      _messages.clear();
      _messages.add({
        "role": "sentry",
        "content": "Hi, I'm Sentry. How can I help you today?",
        "time": DateTime.now().toLocal().toString().substring(11, 16),
      });
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0x2210B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Sentry", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Online Security Advisor", style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white70),
            tooltip: "Clear Conversation",
            onPressed: _clearChat,
          )
        ],
      ),
      body: Column(
        children: [
          // Suggestions Area (Horizontal Scroll)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    side: const BorderSide(color: Colors.white24, width: 0.5),
                    label: Text(
                      _suggestions[index],
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    onPressed: () {
                      _sendMessage(_suggestions[index]);
                    },
                  ),
                );
              },
            ),
          ),
          
          const Divider(height: 1, color: Colors.white12),
          
          // Chat Bubbles
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // Typing indicator bubble
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Sentry is typing...",
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final m = _messages[index];
                final isUser = m["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF10B981)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                        bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                      ),
                      border: isUser ? null : Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m["content"],
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            m["time"],
                            style: TextStyle(
                              color: isUser ? Colors.white70 : Colors.white30,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const Divider(height: 1, color: Colors.white12),
          
          // Input Box
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Ask Sentry about QR, payment security...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (val) {
                      _sendMessage(val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF10B981),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () {
                      _sendMessage(_messageController.text);
                    },
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