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
  //sample
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'Student'; // Added role state

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    LoadingService.show(message: "Loading...");
    
    final String identity = _identityController.text.trim();
    final String password = _passwordController.text;

    try {
      if (_selectedRole == 'Admin' || _selectedRole == 'Teacher') {
        // Step 1: Attempt Staff (Teacher/Admin) Login
        final responseData = await getIt<AuthRepository>().staffLogin(
          identity,
          password,
        );

        final String userType = responseData['userType'] ?? '';
        final List<dynamic> roles = responseData['roles'] ?? [];
        final String token = responseData['token'] ?? '';
        if (context.mounted)
          await Provider.of<AuthProvider>(
            context,
            listen: false,
          ).login(token, userType, responseData);

        if (roles.contains('ROLE_ADMIN') ||
            roles.contains('ROLE_SUPER_ADMIN')) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          LoadingService.hide();

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
          return;
        } else if (userType == 'TEACHER' ||
            roles.contains('ROLE_TEACHER') ||
            roles.contains('ROLE_DISCIPLINE_COMMITTEE')) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          LoadingService.hide();
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
          return;
        }

        if (!mounted) return;
        setState(() => _isLoading = false);
        LoadingService.hide();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid username or password'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        // Step 2: Attempt Student Login
        final responseData = await getIt<AuthRepository>().studentLogin(
          identity,
          password,
        );

        if (!mounted) return;
        setState(() => _isLoading = false);
        LoadingService.hide();

        final String token = responseData['token'] ?? '';
        final String userType = responseData['userType'] ?? '';
        if (context.mounted)
          await Provider.of<AuthProvider>(
            context,
            listen: false,
          ).login(token, userType, responseData);
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
    _identityController.dispose();
    _passwordController.dispose();
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
                          // Login heading (logo and app name hidden for demo)
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

                          // Dynamic Subtitle
                          Text(
                            'Enter your credentials to access your portal',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Role Selector Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _selectedRole,
                            decoration: InputDecoration(
                              labelText: 'Select Role',
                              prefixIcon: const Icon(
                                Icons.admin_panel_settings_outlined,
                              ),
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
                            items: ['Student', 'Teacher', 'Admin']
                                .map(
                                  (role) =>
                                  DropdownMenuItem(
                                    value: role,
                                    child: Text(role),
                                  ),
                            )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedRole = value);
                              }
                            },
                          ),
                          const SizedBox(height: 24),

                          // Username / Identity Field
                          TextFormField(
                            controller: _identityController,
                            validator: (v) =>
                            v == null || v
                                .trim()
                                .isEmpty
                                ? 'Username, Email or Student ID is required'
                                : null,
                            decoration: InputDecoration(
                              labelText: 'Username / ID / Email',
                              hintText: 'Enter your Username, ID or Email',
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                              ),
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

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: (v) =>
                            v == null || v.isEmpty
                                ? 'Password is required'
                                : null,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                  Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
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

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
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
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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