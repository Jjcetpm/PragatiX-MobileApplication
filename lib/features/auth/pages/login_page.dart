import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/services/loading_service.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/features/admin/pages/admin_dashboard.dart';
import 'package:pragatix/features/admin/pages/super_admin_dashboard.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/auth/repository/auth_repository.dart';
import 'package:pragatix/features/captain/pages/captain_dashboard_page.dart';
import 'package:pragatix/features/enrollment/repository/enrollment_repository.dart';
import 'package:pragatix/features/enrollment/widgets/student_enrollment_dialog.dart';
import 'package:pragatix/features/student/pages/student_dashboard_page.dart';
import 'package:pragatix/features/teacher/pages/teacher_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isOtpStep = false;
  bool _agreedToTerms = false;
  bool _enrollmentEnabled = true;

  Timer? _timer;
  int _secondsRemaining = 0;

  late TapGestureRecognizer _policyTapRecognizer;

  static const Color primaryPurple = Color(0xFF6366F1);
  static const Color secondaryPurple = Color(0xFF7C3AED);
  static const Color darkTextColor = Color(0xFF0F172A);
  static const Color subtitleTextColor = Color(0xFF64748B);
  static const Color inputBorderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _policyTapRecognizer = TapGestureRecognizer()..onTap = _showPolicyDialog;
    _checkEnrollmentStatus();
  }

  Future<void> _checkEnrollmentStatus() async {
    try {
      final enabled = await getIt<EnrollmentRepository>().getPublicStatus();
      if (mounted) {
        setState(() {
          _enrollmentEnabled = enabled;
        });
      }
    } catch (_) {}
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  String _formatTimer(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    final String minutesStr = minutes.toString().padLeft(2, '0');
    final String secondsStr = seconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  Future<void> _handleRequestOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    LoadingService.show(message: 'Sending OTP...');

    final String email = _emailController.text.trim();

    try {
      final message = await getIt<AuthRepository>().requestOtp(email);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isOtpStep = true;
        _secondsRemaining = 180;
      });
      _startTimer();
      LoadingService.hide();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      LoadingService.hide();

      ErrorHandler.showSnackBar(context, e);
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_secondsRemaining == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP has expired. Please click Resend OTP.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    LoadingService.show(message: 'Verifying OTP...');

    final String email = _emailController.text.trim();
    final String otp = _otpController.text.trim();

    try {
      final responseData = await getIt<AuthRepository>().verifyOtp(email, otp);

      final String userType = responseData['userType'] ?? '';
      final List<dynamic> roles = responseData['roles'] ?? [];
      final List<dynamic> subRoles = responseData['subRoles'] ?? [];
      final String token = responseData['token'] ?? '';

      if (!mounted) return;
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).login(token, userType, responseData);

      if (!mounted) return;
      setState(() => _isLoading = false);
      LoadingService.hide();

      // Routing Logic
      if (roles.contains('ROLE_ADMIN') || roles.contains('ROLE_SUPER_ADMIN')) {
        final String? assignedYear = responseData['academicYear'];
        String welcomeMessage = 'Admin Access Granted. Welcome!';
        if (roles.contains('ROLE_SUPER_ADMIN')) {
          welcomeMessage = 'Super Admin Access Granted. Welcome!';
        } else if (assignedYear != null) {
          String cleanYear = assignedYear.replaceAll('_', ' ').toLowerCase();
          cleanYear = cleanYear
              .split(' ')
              .map((str) => str[0].toUpperCase() + str.substring(1))
              .join(' ');
          welcomeMessage = '$cleanYear Admin Access Granted. Welcome!';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(welcomeMessage),
            backgroundColor: Colors.green,
          ),
        );

        if (roles.contains('ROLE_SUPER_ADMIN')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SuperAdminDashboard(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        }
      } else if (userType == 'TEACHER' ||
          roles.contains('ROLE_TEACHER') ||
          roles.contains('ROLE_DISCIPLINE_COMMITTEE') ||
          roles.contains('ROLE_HOD') ||
          roles.contains('HOD') ||
          subRoles.contains('HOD') ||
          subRoles.contains('CC')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to Teacher Portal!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TeacherDashboard()),
        );
      } else {
        // Student routing
        final bool isCaptain = responseData['teamRole'] == 'CAPTAIN' ||
            responseData['teamRole'] == 'VICE_CAPTAIN';

        if (userType == 'CAPTAIN' || isCaptain) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login Successful! Welcome to Student Portal.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CaptainDashboardPage(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login Successful! Welcome to Student Portal.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentDashboardPage(),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      LoadingService.hide();

      ErrorHandler.showSnackBar(context, e);
    }
  }

  @override
  void dispose() {
    _policyTapRecognizer.dispose();
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showPolicyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.policy_rounded,
                        color: primaryPurple,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Policies & Terms',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildPolicyLinkItem(
                            icon: Icons.contact_support_outlined,
                            title: 'Contact',
                            url: 'https://pragatix.in/contact',
                          ),
                          _buildPolicyLinkItem(
                            icon: Icons.gavel_outlined,
                            title: 'Terms',
                            url: 'https://pragatix.in/terms',
                          ),
                          _buildPolicyLinkItem(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy',
                            url: 'https://pragatix.in/privacy',
                          ),
                          _buildPolicyLinkItem(
                            icon: Icons.security_outlined,
                            title: 'Security',
                            url: 'https://pragatix.in/security',
                          ),
                          _buildPolicyLinkItem(
                            icon: Icons.cookie_outlined,
                            title: 'Cookies',
                            url: 'https://pragatix.in/cookies',
                          ),
                          _buildPolicyLinkItem(
                            icon: Icons.feedback_outlined,
                            title: 'DPDP Complaints',
                            url: 'https://pragatix.in/dpdp-compliance',
                          ),
                          _buildPolicyLinkItem(
                            icon: Icons.delete_outline_rounded,
                            title: 'Data deletion',
                            url: 'https://pragatix.in/data-deletion',
                          ),
                          _buildPolicyLinkItem(
                            icon: Icons.info_outline_rounded,
                            title: 'Disclaimer',
                            url: 'https://pragatix.in/disclaimer',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPolicyLinkItem({
    required IconData icon,
    required String title,
    required String url,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final Uri uri = Uri.parse(url);
            try {
              final bool launched = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!launched) {
                await launchUrl(uri);
              }
            } catch (e) {
              debugPrint('Error launching URL: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not open link: $url'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(icon, color: primaryPurple, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                const Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F9),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0E7FF), // Soft periwinkle / lavender top
              Color(0xFFF1F5F9), // Slate white middle
              Color(0xFFEEF2FF), // Subtle light purple bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _buildLoginCard(context),
                  ),
                  const SizedBox(height: 20),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Header Image with Overlapping Floating Logo ─────────────────
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Top Graduation Illustration Banner with Smooth Transparent Gradient Fade
                Container(
                  width: double.infinity,
                  height: 235,
                  decoration: const BoxDecoration(
                    color: Color(0xFFBFDBFE),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/graduate_celebration.jpg',
                        width: double.infinity,
                        height: 235,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.15),
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFEEF2FF),
                          child: const Center(
                            child: Icon(
                              Icons.school_rounded,
                              size: 64,
                              color: primaryPurple,
                            ),
                          ),
                        ),
                      ),
                      // Smooth gradient fade from image to white
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.40, 0.72, 1.0],
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.65),
                                Colors.white,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating App Logo Badge (Zoomed & Prominent)
                Positioned(
                  bottom: -43,
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFF1F5F9),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Center(
                        child: Transform.scale(
                          scale: 1.45,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.school_rounded,
                              size: 44,
                              color: primaryPurple,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 52),

            // ── Form Body ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title: Welcome Back!
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                        children: [
                          TextSpan(
                            text: _isOtpStep ? 'Verify ' : 'Welcome ',
                            style: const TextStyle(color: darkTextColor),
                          ),
                          TextSpan(
                            text: _isOtpStep ? 'OTP' : 'Back!',
                            style: const TextStyle(color: primaryPurple),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      _isOtpStep
                          ? 'Enter the 4-digit OTP sent to your email'
                          : 'Enter your email to receive an OTP',
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: subtitleTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 22),

                    if (!_isOtpStep) ...[
                      // Email Input Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!v.contains('@') || !v.contains('.')) return 'Invalid email format';
                          return null;
                        },
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: darkTextColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Email Address',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Icon(
                              Icons.mail_outline_rounded,
                              color: primaryPurple,
                              size: 22,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 46,
                            minHeight: 46,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFAFAFE),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: inputBorderColor, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: inputBorderColor, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: primaryPurple, width: 2.0),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Policy Checkbox (Shifted right for clean alignment)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreedToTerms,
                                onChanged: (value) {
                                  setState(() {
                                    _agreedToTerms = value ?? false;
                                  });
                                },
                                activeColor: primaryPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF6366F1),
                                  width: 1.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF334155),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    const TextSpan(text: 'I accept '),
                                    TextSpan(
                                      text: 'our policy',
                                      style: const TextStyle(
                                        color: primaryPurple,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: _policyTapRecognizer,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Send OTP Primary Gradient Button
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: (_isLoading || !_agreedToTerms)
                              ? null
                              : const LinearGradient(
                                  colors: [primaryPurple, secondaryPurple],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          color: (_isLoading || !_agreedToTerms)
                              ? const Color(0xFFCBD5E1)
                              : null,
                          boxShadow: (_isLoading || !_agreedToTerms)
                              ? []
                              : [
                                  BoxShadow(
                                    color: primaryPurple.withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: (_isLoading || !_agreedToTerms) ? null : _handleRequestOtp,
                            borderRadius: BorderRadius.circular(14),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Send OTP',
                                          style: TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),

                      // "OR" Divider and Enroll Button
                      if (_enrollmentEnabled) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => StudentEnrollmentDialog.show(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: primaryPurple, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  color: primaryPurple,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Enroll Now',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: primaryPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      // ── OTP Step ───────────────────────────────────────────────
                      Pinput(
                        controller: _otpController,
                        length: 4,
                        onCompleted: (pin) {
                          if (!_isLoading) {
                            _handleVerifyOtp();
                          }
                        },
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'OTP is required';
                          if (v.trim().length != 4) return 'OTP must be 4 digits';
                          return null;
                        },
                        defaultPinTheme: PinTheme(
                          width: 56,
                          height: 56,
                          textStyle: const TextStyle(
                            fontSize: 22,
                            color: primaryPurple,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFE),
                            border: Border.all(color: inputBorderColor, width: 1.5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        focusedPinTheme: PinTheme(
                          width: 56,
                          height: 56,
                          textStyle: const TextStyle(
                            fontSize: 22,
                            color: primaryPurple,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: primaryPurple, width: 2),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: primaryPurple.withValues(alpha: 0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                        errorPinTheme: PinTheme(
                          width: 56,
                          height: 56,
                          textStyle: const TextStyle(
                            fontSize: 22,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            border: Border.all(color: Colors.redAccent, width: 1.5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _secondsRemaining > 0
                                ? 'Expires in: ${_formatTimer(_secondsRemaining)}'
                                : 'OTP expired',
                            style: TextStyle(
                              color: _secondsRemaining > 0
                                  ? const Color(0xFF64748B)
                                  : Colors.redAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: _secondsRemaining == 0 ? _handleRequestOtp : null,
                            child: Text(
                              'Resend OTP',
                              style: TextStyle(
                                color: _secondsRemaining == 0 ? primaryPurple : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: (_isLoading || _secondsRemaining == 0)
                              ? null
                              : const LinearGradient(
                                  colors: [primaryPurple, secondaryPurple],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          color: (_isLoading || _secondsRemaining == 0)
                              ? const Color(0xFFCBD5E1)
                              : null,
                          boxShadow: (_isLoading || _secondsRemaining == 0)
                              ? []
                              : [
                                  BoxShadow(
                                    color: primaryPurple.withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: (_isLoading || _secondsRemaining == 0)
                                ? null
                                : _handleVerifyOtp,
                            borderRadius: BorderRadius.circular(14),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Verify & Sign In',
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isOtpStep = false;
                            _otpController.clear();
                          });
                        },
                        child: const Text(
                          'Change Email',
                          style: TextStyle(
                            color: subtitleTextColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Security & Privacy Trust Badge
                    _buildSecurityBadge(),

                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
    );
  }

  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 14,
            color: Color(0xFF334155),
          ),
          SizedBox(width: 6),
          Text(
            '© 2026 All Rights Reserved',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}