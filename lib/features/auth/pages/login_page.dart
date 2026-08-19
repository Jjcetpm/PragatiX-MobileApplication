import 'package:pragatix/features/auth/repository/auth_repository.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:pinput/pinput.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:pragatix/features/student/pages/student_dashboard_page.dart';
import 'package:pragatix/features/teacher/pages/teacher_dashboard.dart';
import 'package:pragatix/features/admin/pages/admin_dashboard.dart';
import 'package:pragatix/features/admin/pages/super_admin_dashboard.dart';
import 'package:pragatix/features/captain/pages/captain_dashboard_page.dart';
import 'package:pragatix/shared/widgets/app_copyright_footer.dart';
import 'package:pragatix/core/services/loading_service.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

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
  
  Timer? _timer;
  int _secondsRemaining = 0;

  late TapGestureRecognizer _policyTapRecognizer;

  @override
  void initState() {
    super.initState();
    _policyTapRecognizer = TapGestureRecognizer()..onTap = _showPolicyDialog;
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
    LoadingService.show(message: "Sending OTP...");
    
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
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
    LoadingService.show(message: "Verifying OTP...");
    
    final String email = _emailController.text.trim();
    final String otp = _otpController.text.trim();

    try {
      final responseData = await getIt<AuthRepository>().verifyOtp(email, otp);

      final String userType = responseData['userType'] ?? '';
      final List<dynamic> roles = responseData['roles'] ?? [];
      final String token = responseData['token'] ?? '';
      
      if (context.mounted) {
        await Provider.of<AuthProvider>(
          context,
          listen: false,
        ).login(token, userType, responseData);
      }

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
          roles.contains('ROLE_DISCIPLINE_COMMITTEE')) {
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
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
                        color: Color(0xFF4F46E5),
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
                      backgroundColor: const Color(0xFF4F46E5),
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
                Icon(icon, color: const Color(0xFF4F46E5), size: 20),
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
    const primaryColor = Color(0xFF4F46E5); // Modern Indigo brand color
    const bgGradient = [
      Color(0xFF1E293B),
      Color(0xFF0F172A),
    ]; // Sleek slate gradient

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgGradient,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Card(
                      elevation: 16,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      color: Colors.white.withValues(alpha: 0.95),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── App Logo ──────────────────────────────────
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: OverflowBox(
                                    minWidth: 140,
                                    maxWidth: 140,
                                    minHeight: 140,
                                    maxHeight: 140,
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.school_rounded,
                                        size: 64,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // ── App Name & Title ──────────────────────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'PragatiX',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF4F46E5),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),


                              Text(
                                _isOtpStep 
                                  ? 'Enter the 4-digit OTP sent to your email'
                                  : 'Enter your email to receive an OTP',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              if (!_isOtpStep) ...[
                                TextFormField(
                                  controller: _emailController,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Email is required';
                                    if (!v.contains('@')) return 'Invalid email format';
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                    hintText: 'Enter your email address',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: primaryColor,
                                        width: 2.0,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _agreedToTerms,
                                      onChanged: (value) {
                                        setState(() {
                                          _agreedToTerms = value ?? false;
                                        });
                                      },
                                      activeColor: primaryColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                            fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                                          ),
                                          children: [
                                            const TextSpan(text: 'I accept '),
                                            TextSpan(
                                              text: 'our policy',
                                              style: const TextStyle(
                                                color: primaryColor,
                                                fontWeight: FontWeight.bold,
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
                                const SizedBox(height: 24),

                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: (_isLoading || !_agreedToTerms) ? null : _handleRequestOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            'Send OTP',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ] else ...[
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
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  focusedPinTheme: PinTheme(
                                    width: 56,
                                    height: 56,
                                    textStyle: const TextStyle(
                                      fontSize: 22,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: primaryColor, width: 2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  errorPinTheme: PinTheme(
                                    width: 56,
                                    height: 56,
                                    textStyle: const TextStyle(
                                      fontSize: 22,
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.redAccent, width: 2),
                                      borderRadius: BorderRadius.circular(16),
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
                                         color: _secondsRemaining > 0 ? Colors.grey.shade700 : Colors.red,
                                         fontWeight: FontWeight.bold,
                                       ),
                                     ),
                                     TextButton(
                                       onPressed: _secondsRemaining == 0 ? _handleRequestOtp : null,
                                       child: Text(
                                         'Resend OTP',
                                         style: TextStyle(
                                           color: _secondsRemaining == 0 ? primaryColor : Colors.grey,
                                           fontWeight: FontWeight.bold,
                                         ),
                                       ),
                                     ),
                                   ],
                                 ),
                                 const SizedBox(height: 16),

                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: (_isLoading || _secondsRemaining == 0) ? null : _handleVerifyOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            'Verify & Sign In',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: AppCopyrightFooter(),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
),
    );
  }
}