import 'package:flutter/material.dart';
import 'package:pragatix/core/theme/app_colors.dart';
import 'package:pragatix/features/admin/pages/activity_tab.dart'; // We will use this or the global_activity_page
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';

class YearSelectionPage extends StatefulWidget {
  const YearSelectionPage({Key? key}) : super(key: key);

  @override
  State<YearSelectionPage> createState() => _YearSelectionPageState();
}

class _YearSelectionPageState extends State<YearSelectionPage> {
  final AdminRepository _repository = getIt<AdminRepository>();
  List<dynamic> _yearsList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchYears();
  }

  Future<void> _fetchYears() async {
    try {
      final years = await _repository.getYears();
      if (!mounted) return;
      setState(() {
        _yearsList = years;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  IconData _getIconForYear(int index) {
    switch (index) {
      case 0:
        return Icons.looks_one;
      case 1:
        return Icons.looks_two;
      case 2:
        return Icons.looks_3;
      case 3:
        return Icons.looks_4;
      case 4:
        return Icons.looks_5;
      case 5:
        return Icons.looks_6;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Activity & Thresholds'),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Academic Year',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please select an academic year to manage its stages and activities.',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _isLoading
                  ? const Center(child: PragatiXLoader())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchYears,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _yearsList.isEmpty
                          ? const Center(
                              child: Text(
                                'No configured years found.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _yearsList.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final year = _yearsList[index];
                                final String yearName =
                                    year['yearName'] ?? 'Unknown Year';
                                // Convert to enum format, e.g., "First Year" -> "FIRST_YEAR"
                                final String enumValue = yearName
                                    .toUpperCase()
                                    .replaceAll(' ', '_');
                                return _buildYearCard(
                                  context,
                                  '🎓 $yearName',
                                  enumValue,
                                  _getIconForYear(index),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearCard(
    BuildContext context,
    String title,
    String yearValue,
    IconData icon,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final authProvider = context.read<AuthProvider>();
          await authProvider.setSelectedAcademicYear(yearValue);

          if (!context.mounted) return;
          // Push to Activity Management with the selected year
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AdminActivityManagementPage(selectedYear: yearValue),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.adminPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.adminPrimary, size: 32),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
