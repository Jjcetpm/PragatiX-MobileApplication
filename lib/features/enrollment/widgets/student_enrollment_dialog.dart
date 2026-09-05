import 'package:flutter/material.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/features/enrollment/models/enrollment_model.dart';
import 'package:pragatix/features/enrollment/repository/enrollment_repository.dart';

class StudentEnrollmentDialog extends StatefulWidget {
  const StudentEnrollmentDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StudentEnrollmentDialog(),
    );
  }

  @override
  State<StudentEnrollmentDialog> createState() => _StudentEnrollmentDialogState();
}

class _StudentEnrollmentDialogState extends State<StudentEnrollmentDialog> {
  final EnrollmentRepository _repository = getIt<EnrollmentRepository>();

  int _currentStep = 1;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1 data
  List<PendingDepartment> _departments = [];
  PendingDepartment? _selectedDept;

  // Step 2 data
  List<String> _alphabets = [];
  String? _selectedAlphabet;

  // Step 3 data
  List<PendingStudent> _pendingStudents = [];
  PendingStudent? _selectedStudent;

  // Step 4 data
  bool _isSubmitting = false;
  bool _isEnrolledSuccess = false;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final depts = await _repository.getPendingDepartments();
      if (!mounted) return;
      setState(() {
        _departments = depts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorHandler.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  static const List<String> allAlphabets = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ];

  Future<void> _fetchAlphabets(PendingDepartment dept) async {
    setState(() {
      _selectedDept = dept;
      _alphabets = allAlphabets;
      _currentStep = 2;
      _isLoading = false;
      _errorMessage = null;
      _selectedAlphabet = null;
      _selectedStudent = null;
    });
  }

  Future<void> _fetchStudents(String letter) async {
    if (_selectedDept == null) return;
    setState(() {
      _selectedAlphabet = letter;
      _isLoading = true;
      _errorMessage = null;
      _selectedStudent = null;
    });
    try {
      final students = await _repository.getPendingStudents(_selectedDept!.id, letter);
      if (!mounted) return;
      setState(() {
        _pendingStudents = students;
        _currentStep = 3;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorHandler.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _completeEnrollment() async {
    if (_selectedStudent == null) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _repository.completeEnrollment(_selectedStudent!.id);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isEnrolledSuccess = true;
        _successMessage = result['message'] ?? 'Enrollment completed successfully!';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = ErrorHandler.getErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2563EB);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
              children: [
                if (_currentStep > 1 && !_isEnrolledSuccess)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () {
                      setState(() {
                        _currentStep--;
                        _errorMessage = null;
                      });
                    },
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEnrolledSuccess
                            ? 'Enrollment Success'
                            : 'Student Self-Enrollment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (!_isEnrolledSuccess)
                        Text(
                          'Step $_currentStep of 4: ${_getStepTitle()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Progress Indicator
          if (!_isEnrolledSuccess)
            LinearProgressIndicator(
              value: _currentStep / 4.0,
              backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              minHeight: 3,
            ),

          // Error Banner
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Body Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isEnrolledSuccess
                    ? _buildSuccessView(primaryColor, isDark)
                    : _buildStepContent(primaryColor, isDark),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Select Your Department';
      case 2:
        return 'Select First Letter of Name';
      case 3:
        return 'Select Your Name';
      case 4:
        return 'Confirm & Complete Enrollment';
      default:
        return '';
    }
  }

  Widget _buildStepContent(Color primaryColor, bool isDark) {
    switch (_currentStep) {
      case 1:
        return _buildDepartmentStep(isDark);
      case 2:
        return _buildAlphabetStep(primaryColor, isDark);
      case 3:
        return _buildStudentListStep(primaryColor, isDark);
      case 4:
        return _buildConfirmationStep(primaryColor, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: Department List
  Widget _buildDepartmentStep(bool isDark) {
    if (_departments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No Pending Enrollments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'There are currently no students awaiting enrollment.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _departments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final dept = _departments[index];
        return Card(
          elevation: 0,
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFDBEAFE),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                dept.deptCode.isNotEmpty ? dept.deptCode.substring(0, 1) : 'D',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              dept.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              'Code: ${dept.deptCode}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _fetchAlphabets(dept),
          ),
        );
      },
    );
  }

  // STEP 2: First Letter of Name Chips (All 26 Alphabets A to Z)
  Widget _buildAlphabetStep(Color primaryColor, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select the first letter of your name Name',
                    style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _alphabets.map((letter) {
                final isSelected = _selectedAlphabet == letter;
                return InkWell(
                  onTap: () => _fetchStudents(letter),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor
                            : (isDark ? const Color(0xFF475569) : Colors.grey.shade300),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3: Student Selection (with masked mobile privacy)
  Widget _buildStudentListStep(Color primaryColor, bool isDark) {
    if (_pendingStudents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No Students Starting with "$_selectedAlphabet"',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'No pending students starting with letter "$_selectedAlphabet" in ${_selectedDept?.name ?? "this department"}.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep = 2),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Choose Another Letter'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingStudents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final student = _pendingStudents[index];
        final isSelected = _selectedStudent?.id == student.id;

        return Card(
          elevation: isSelected ? 2 : 0,
          color: isSelected
              ? primaryColor.withOpacity(0.08)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isSelected
                  ? primaryColor
                  : (isDark ? const Color(0xFF475569) : Colors.grey.shade300),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isSelected ? primaryColor : (isDark ? const Color(0xFF475569) : Colors.grey.shade200),
              foregroundColor: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
              child: Text(
                student.fullName.isNotEmpty ? student.fullName.substring(0, 1).toUpperCase() : 'S',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              student.fullName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_locked_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Mobile: ${student.maskedMobile}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Dept: ${student.deptCode.isNotEmpty ? student.deptCode : student.departmentName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle_rounded, color: primaryColor)
                : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              setState(() {
                _selectedStudent = student;
                _currentStep = 4;
              });
            },
          ),
        );
      },
    );
  }

  // STEP 4: Confirmation & Final Enroll Button
  Widget _buildConfirmationStep(Color primaryColor, bool isDark) {
    if (_selectedStudent == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm Your Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please verify that this is your student record before proceeding.',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          // Detail Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
              ),
            ),
            child: Column(
              children: [
                _buildConfirmRow('Full Name', _selectedStudent!.fullName, Icons.person_outline, isDark),
                const Divider(height: 24),
                _buildConfirmRow('Department', _selectedStudent!.departmentName, Icons.school_outlined, isDark),

                Builder(
                  builder: (context) {
                    final rawEmail = _selectedStudent!.email;
                    final maskedEmail = _selectedStudent!.maskedEmail;
                    String? displayEmail;

                    if (rawEmail != null && rawEmail.trim().isNotEmpty && !rawEmail.startsWith('ENC:')) {
                      displayEmail = rawEmail.trim();
                    } else if (maskedEmail != null && maskedEmail.trim().isNotEmpty && !maskedEmail.startsWith('ENC:')) {
                      displayEmail = maskedEmail.trim();
                    }

                    if (displayEmail != null && displayEmail.isNotEmpty) {
                      return Column(
                        children: [
                          const Divider(height: 24),
                          _buildConfirmRow('Email ID', displayEmail, Icons.mail_outline, isDark),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const Divider(height: 24),
                _buildConfirmRow('Registered Mobile', _selectedStudent!.maskedMobile, Icons.phone_locked_outlined, isDark),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Privacy note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.security_rounded, color: Colors.amber.shade800, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Once enrolled, your student account will be activated in the PragatiX system.',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _completeEnrollment,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.how_to_reg_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Enroll Now',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value, IconData icon, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2563EB)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // SUCCESS VIEW
  Widget _buildSuccessView(Color primaryColor, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Enrollment Complete!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _successMessage ?? 'Your student record has been created successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Login',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
