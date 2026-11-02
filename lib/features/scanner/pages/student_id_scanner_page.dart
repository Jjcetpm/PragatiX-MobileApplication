import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/scanner/models/scanned_student_models.dart';
import 'package:pragatix/features/scanner/services/student_scanner_service.dart';

class StudentIdScannerPage extends StatefulWidget {
  const StudentIdScannerPage({super.key});

  @override
  State<StudentIdScannerPage> createState() => _StudentIdScannerPageState();
}

class _StudentIdScannerPageState extends State<StudentIdScannerPage> {
  late final MobileScannerController _scannerController;
  StudentScannerService? _scannerService;

  bool _isTorchOn = false;
  bool _isProcessingScan = false;
  bool _isLoading = false;
  String? _errorMessage;

  ScannedStudentProfileModel? _student;
  List<EligibleActivityModel> _activities = [];
  bool _isLoadingActivities = false;
  String _activityFilter = '';

  final TextEditingController _manualInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token ?? '';
      _scannerService = StudentScannerService(token: token);
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (_) {}
  }

  void _switchCamera() async {
    try {
      await _scannerController.switchCamera();
    } catch (_) {}
  }

  void _resetScanner() {
    setState(() {
      _student = null;
      _activities = [];
      _errorMessage = null;
      _isProcessingScan = false;
      _manualInputController.clear();
      _activityFilter = '';
    });
    _scannerController.start();
  }

  Future<void> _handleScanPayload(String rawPayload) async {
    if (_isProcessingScan || rawPayload.trim().isEmpty) return;

    setState(() {
      _isProcessingScan = true;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_scannerService == null) {
        final token = context.read<AuthProvider>().token ?? '';
        _scannerService = StudentScannerService(token: token);
      }

      final studentProfile = await _scannerService!.lookupStudent(rawPayload);
      if (!mounted) return;

      setState(() {
        _student = studentProfile;
        _isLoading = false;
      });

      _scannerController.stop();

      // Fetch eligible activities
      _fetchActivities(studentProfile.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'Student not found'),
          backgroundColor: Colors.redAccent,
        ),
      );

      // Re-enable scanning after short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _student == null) {
          setState(() {
            _isProcessingScan = false;
          });
        }
      });
    }
  }

  Future<void> _fetchActivities(int studentId) async {
    setState(() {
      _isLoadingActivities = true;
    });

    try {
      final list = await _scannerService!.getEligibleActivities(studentId);
      if (!mounted) return;
      setState(() {
        _activities = list;
        _isLoadingActivities = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingActivities = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load activities: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _openManualSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Manual SPR Search',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the student\'s SPR Number or Register Number below:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _manualInputController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g. 24CS036, SPR001, 2402021',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF11998e)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF11998e),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final query = _manualInputController.text.trim();
                    if (query.isNotEmpty) {
                      Navigator.pop(ctx);
                      _handleScanPayload(query);
                    }
                  },
                  child: const Text(
                    'Find Student',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAwardDialog(EligibleActivityModel activity) {
    int xpToAward = activity.isVariableXp ? (activity.awardXp > 0 ? activity.awardXp : activity.minXp) : activity.awardXp;
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Award XP: ${activity.activityName}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student: ${_student?.fullName} (${_student?.sprNo})',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 12),
                    if (activity.isVariableXp) ...[
                      Text('XP Points to Award: $xpToAward',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF11998e))),
                      Slider(
                        value: xpToAward.toDouble(),
                        min: activity.minXp.toDouble(),
                        max: activity.maxXp.toDouble(),
                        divisions: (activity.maxXp - activity.minXp) > 0 ? (activity.maxXp - activity.minXp) : 1,
                        activeColor: const Color(0xFF11998e),
                        onChanged: (val) {
                          setDialogState(() {
                            xpToAward = val.round();
                          });
                        },
                      ),
                      Text('Allowed: ${activity.minXp} to ${activity.maxXp} XP',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          '+${activity.awardXp} XP (Fixed)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: remarksController,
                      decoration: const InputDecoration(
                        labelText: 'Remarks (Optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF11998e)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmAndExecute(
                      activity: activity,
                      isPenalty: false,
                      xpPoints: xpToAward,
                      reasonOrRemarks: remarksController.text.trim(),
                    );
                  },
                  child: const Text('Proceed', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPenaltyDialog(EligibleActivityModel activity) {
    final int penaltyXp = activity.penaltyXp > 0 ? activity.penaltyXp : 20;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Apply Penalty',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student: ${_student?.fullName} (${_student?.sprNo})',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('Activity: ${activity.activityName}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Text('Points to Deduct: -$penaltyXp XP',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.redAccent)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Reason for Penalty *',
                        hintText: 'e.g. Inappropriate lab behavior, late submission',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: () {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reason for penalty is mandatory!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    _confirmAndExecute(
                      activity: activity,
                      isPenalty: true,
                      xpPoints: penaltyXp,
                      reasonOrRemarks: reason,
                    );
                  },
                  child: const Text('Proceed', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmAndExecute({
    required EligibleActivityModel activity,
    required bool isPenalty,
    required int xpPoints,
    required String reasonOrRemarks,
  }) {


    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setConfirmState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isPenalty ? 'Confirm XP Penalty' : 'Confirm XP Award',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPenalty ? Colors.redAccent : const Color(0xFF11998e),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _confirmRow('Student:', '${_student?.fullName} (${_student?.sprNo})'),
                  _confirmRow('Activity:', activity.activityName),
                  _confirmRow(
                    'Transaction:',
                    isPenalty ? '-$xpPoints XP (Penalty)' : '+$xpPoints XP (Award)',
                    highlightColor: isPenalty ? Colors.red : Colors.green.shade800,
                  ),
                  if (reasonOrRemarks.isNotEmpty)
                    _confirmRow('Reason / Note:', reasonOrRemarks),
                  const SizedBox(height: 12),
                  const Text(
                    'This action cannot be undone. Balances and audit logs will be updated.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                if (!isSubmitting)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Back'),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPenalty ? Colors.redAccent : const Color(0xFF11998e),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(ctx);
                          setConfirmState(() => isSubmitting = true);
                          final idempotencyKey = '${DateTime.now().millisecondsSinceEpoch}_${activity.activityId}';

                          try {
                            ScannerTransactionResultModel result;
                            if (isPenalty) {
                              result = await _scannerService!.applyPenalty(
                                ScannerPenaltyModel(
                                  studentId: _student!.id,
                                  activityId: activity.activityId,
                                  assignmentId: activity.assignmentId,
                                  penaltyXp: xpPoints,
                                  reason: reasonOrRemarks,
                                  idempotencyKey: idempotencyKey,
                                ),
                              );
                            } else {
                              result = await _scannerService!.awardXp(
                                ScannerAwardModel(
                                  studentId: _student!.id,
                                  activityId: activity.activityId,
                                  assignmentId: activity.assignmentId,
                                  xp: xpPoints,
                                  remarks: reasonOrRemarks,
                                  idempotencyKey: idempotencyKey,
                                ),
                              );
                            }

                            nav.pop();
                            if (!mounted) return;

                            setState(() {
                              _student = ScannedStudentProfileModel(
                                id: _student!.id,
                                sprNo: _student!.sprNo,
                                regNo: _student!.regNo,
                                fullName: _student!.fullName,
                                email: _student!.email,
                                departmentId: _student!.departmentId,
                                departmentName: _student!.departmentName,
                                year: _student!.year,
                                academicYear: _student!.academicYear,
                                sectionId: _student!.sectionId,
                                sectionName: _student!.sectionName,
                                teamId: _student!.teamId,
                                teamName: _student!.teamName,
                                teamRole: _student!.teamRole,
                                isCaptain: _student!.isCaptain,
                                currentStage: _student!.currentStage,
                                stageName: _student!.stageName,
                                currentXp: result.newCurrentXp,
                                lifetimeXp: result.newLifetimeXp,
                                avatar: _student!.avatar,
                              );
                            });

                            _fetchActivities(_student!.id);

                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  isPenalty
                                      ? 'Deducted $xpPoints XP from ${_student!.fullName}'
                                      : 'Awarded $xpPoints XP to ${_student!.fullName}!',
                                ),
                                backgroundColor: isPenalty ? Colors.redAccent : Colors.green,
                              ),
                            );
                          } catch (e) {
                            setConfirmState(() => isSubmitting = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceAll('Exception: ', '')),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Confirm & Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _confirmRow(String label, String value, {Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: highlightColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student ID Scanner',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF11998e),
        foregroundColor: Colors.white,
        actions: [
          if (_student == null) ...[
            IconButton(
              icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
              tooltip: 'Toggle Flashlight',
              onPressed: _toggleTorch,
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              tooltip: 'Switch Camera',
              onPressed: _switchCamera,
            ),
          ] else ...[
            TextButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
              label: const Text('Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: _resetScanner,
            ),
          ],
        ],
      ),
      body: _student == null ? _buildScannerBody() : _buildStudentDetailsBody(),
    );
  }

  Widget _buildScannerBody() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          errorBuilder: (context, error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off, color: Colors.amberAccent, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      error.errorDetails?.message ?? 'Camera error: ${error.errorCode.name}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please grant camera permissions or use manual search below.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
          onDetect: (BarcodeCapture capture) {
            final barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final raw = barcode.rawValue;
              if (raw != null && raw.trim().isNotEmpty) {
                _handleScanPayload(raw);
                break;
              }
            }
          },
        ),

        // Scanning Target Frame
        Center(
          child: Container(
            width: 260,
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF38ef7d), width: 2.5),
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
            ),
            child: const Stack(
              children: [
                Positioned(
                  top: 8,
                  left: 8,
                  child: Text(
                    'ALIGN BARCODE / QR',
                    style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom manual search bar
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Column(
            children: [
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.tealAccent),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Looking up student profile...',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF11998e),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.keyboard),
                  label: const Text(
                    'Manual SPR Search',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _openManualSearchSheet,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentDetailsBody() {
    final filtered = _activities.where((a) {
      if (_activityFilter.isEmpty) return true;
      final q = _activityFilter.toLowerCase();
      return a.activityName.toLowerCase().contains(q) || a.scopeLabel.toLowerCase().contains(q);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF11998e),
                        child: Text(
                          _student!.fullName.isNotEmpty ? _student!.fullName[0].toUpperCase() : 'S',
                          style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _student!.fullName,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (_student!.isCaptain)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Captain',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'SPR: ${_student!.sprNo} ${_student!.regNo != null ? '• Reg: ${_student!.regNo}' : ''}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF11998e), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_student!.departmentName ?? 'Department'} • ${_student!.sectionName ?? ''} • ${_student!.stageName}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              const Text('Current XP', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('${_student!.currentXp}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              const Text('Lifetime XP', style: TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('${_student!.lifetimeXp}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Activities Title & Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Authorized Activities',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${filtered.length} available',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Search Field
          TextField(
            onChanged: (val) => setState(() => _activityFilter = val),
            decoration: InputDecoration(
              hintText: 'Filter activities...',
              prefixIcon: const Icon(Icons.filter_list, size: 18),
              isDense: true,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (_isLoadingActivities)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text('No authorized activities found for this student.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final act = filtered[idx];
                final isCompleted = act.alreadyCompleted && !act.repeatAllowed;

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: act.scope == 'GLOBAL'
                                    ? Colors.blue.shade50
                                    : act.scope == 'SPECIFIC_FACULTY'
                                        ? Colors.purple.shade50
                                        : Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                act.scopeLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: act.scope == 'GLOBAL'
                                      ? Colors.blue.shade800
                                      : act.scope == 'SPECIFIC_FACULTY'
                                          ? Colors.purple.shade800
                                          : Colors.teal.shade800,
                                ),
                              ),
                            ),
                            if (isCompleted)
                              const Text('Completed', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))
                            else
                              const Text('Eligible', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          act.activityName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        if (act.description != null && act.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            act.description!,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              act.isVariableXp ? 'Award: 1–${act.maxXp} XP (Var)' : 'Award: +${act.awardXp} XP',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade800),
                            ),
                            if (act.penaltyEnabled) ...[
                              const SizedBox(width: 12),
                              Text(
                                'Penalty: -${act.penaltyXp} XP',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.redAccent),
                              ),
                            ],
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (act.penaltyEnabled && !isCompleted) ...[
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.shield_outlined, size: 14),
                                label: const Text('Penalty', style: TextStyle(fontSize: 12)),
                                onPressed: () => _showPenaltyDialog(act),
                              ),
                              const SizedBox(width: 8),
                            ],
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCompleted ? Colors.grey : const Color(0xFF11998e),
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.card_giftcard, size: 14),
                              label: const Text('Award XP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: isCompleted ? null : () => _showAwardDialog(act),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
