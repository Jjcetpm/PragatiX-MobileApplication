import 'package:pragatix/features/auth/repository/auth_repository.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:pragatix/features/student/pages/student_dashboard_page.dart';
import 'package:pragatix/features/teacher/pages/teacher_dashboard.dart';
import 'package:pragatix/features/admin/pages/admin_dashboard.dart';
import 'package:pragatix/features/admin/pages/super_admin_dashboard.dart';
import 'package:pragatix/features/captain/pages/captain_dashboard_page.dart';
import 'package:pragatix/shared/widgets/app_copyright_footer.dart';
import 'package:pragatix/core/services/loading_service.dart';

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
      });
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
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
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
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Card(
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
                              const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 6),

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
                                const SizedBox(height: 32),

                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleRequestOtp,
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
                                TextFormField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'OTP is required';
                                    if (v.trim().length != 4) return 'OTP must be 4 digits';
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'OTP',
                                    hintText: 'Enter 4-digit OTP',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded),
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
                                
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isOtpStep = false;
                                      _otpController.clear();
                                    });
                                  },
                                  child: const Text('Change Email', style: TextStyle(color: primaryColor)),
                                ),
                                const SizedBox(height: 8),

                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleVerifyOtp,
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
                  ),
                ),
              ),
              const Positioned(
                bottom: 16.0,
                left: 0,
                right: 0,
                child: AppCopyrightFooter(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}