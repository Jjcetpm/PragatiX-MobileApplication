part of 'teacher_student_detail.dart';

extension _TeacherStudentDetailDialogs on _TeacherStudentDetailState {
  void _showAddPointsSheet() {
    _showPointsBottomSheet(true);
  }

  void _showDeductPointsSheet() {
    _showPointsBottomSheet(false);
  }

  void _showPointsBottomSheet(bool isAdding) {
    final reasons = isAdding
        ? [
            'Attendance Above 95% (+10)',
            'Placement Training (+15)',
            'Internship Completion (+20)',
            'Hackathon Winner (+25)',
            'Academic Topper (+30)',
            'Faculty Appreciation (+10)',
          ]
        : [
            'Late Arrival (-3)',
            'Missing ID Card (-2)',
            'Mobile Usage (-5)',
            'Misbehavior (-10)',
            'Proxy Attendance (-15)',
            'Ragging (-50)',
            'Severe Misconduct (-100)',
          ];

    int? selectedSubgroupId;
    String? selectedReason = reasons.first;
    final TextEditingController customReasonController =
        TextEditingController();

    // Flatten all subgroups across stages for the dropdown
    final List<Map<String, dynamic>> allSubgroups = [];
    for (var stage in stagesList) {
      final List<dynamic> subs = stage['subgroups'] ?? [];
      for (var sub in subs) {
        allSubgroups.add({
          'id': sub['id'],
          'name': "${stage["name"]} - ${StringUtils.toTitleCase(sub["name"])}",
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20.0,
                left: 20.0,
                right: 20.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAdding ? 'Add Points' : 'Deduct Points',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Activity Assignment Dropdown
                  DropdownButtonFormField<int?>(
                    initialValue: selectedSubgroupId,
                    decoration: const InputDecoration(
                      labelText: 'Activity / Stage Assignment',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('General (No Activity Group)'),
                      ),
                      ...allSubgroups.map((sub) {
                        return DropdownMenuItem<int?>(
                          value: sub['id'],
                          child: Text(sub['name']),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      selectedSubgroupId = val;
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Select Reason & Value:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Reasons List
                  SizedBox(
                    height: 150,
                    child: RadioGroup<String>(
                      groupValue: selectedReason,
                      onChanged: (val) {
                        setDialogState(() {
                          selectedReason = val;
                        });
                      },
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: reasons.length,
                        itemBuilder: (context, index) {
                          final r = reasons[index];
                          return RadioListTile<String>(
                            title: Text(r),
                            value: r,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextField(
                    controller: customReasonController,
                    decoration: const InputDecoration(
                      labelText:
                          'Custom Reason (Overrides selected reason description)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final finalReason =
                            customReasonController.text.trim().isNotEmpty
                                ? customReasonController.text.trim()
                                : selectedReason!;

                        // Parse points value from selectedReason
                        final int val = int.parse(
                          selectedReason!
                              .split(RegExp(r'[()]'))[1]
                              .replaceAll('+', '')
                              .replaceAll('-', '')
                              .trim(),
                        );
                        final points = val * (isAdding ? 1 : -1);

                        _changeScore(points, finalReason, selectedSubgroupId);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAdding ? Colors.green : Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isAdding ? 'Add Points' : 'Deduct Points',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
