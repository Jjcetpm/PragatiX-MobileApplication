part of 'students_tab.dart';

extension StudentsTabDialogs on _StudentsTabState {
  void _showAddStudentOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Add Students',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Color(0xFF11998e),
                ),
                title: const Text('Register Single Student'),
                subtitle: const Text(
                  'Enter Name, Reg No, DOB, and details manually',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showSingleStudentDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.upload_file_rounded,
                  color: Colors.green,
                ),
                title: const Text('Excel Bulk Upload'),
                subtitle: const Text(
                  'Upload spreadsheet with columns mapping details',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _uploadBulkExcel();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showSingleStudentDialog() {
    _clearControllers();
    final isCc = widget.subRoles.contains('CC');

    int? selectedDeptId;
    int? selectedYearId;
    int? selectedSectionId;
    int? selectedAcademicYearId;
    int? selectedSemesterId;
    int? selectedGenderId;
    int? selectedGroupId;
    final TextEditingController addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Perform CC resolution inside builder if not resolved yet
            if (isCc) {
              selectedDeptId ??= ccDeptId;
              selectedSectionId ??= ccSectionId;

              if (selectedYearId == null && ccYear != null) {
                String normalizedCcYear = ccYear!;
                switch (normalizedCcYear.toUpperCase().trim()) {
                  case 'I': normalizedCcYear = '1'; break;
                  case 'II': normalizedCcYear = '2'; break;
                  case 'III': normalizedCcYear = '3'; break;
                  case 'IV': normalizedCcYear = '4'; break;
                  case 'V': normalizedCcYear = '5'; break;
                }
                
                final yMatch = years.firstWhere(
                  (y) =>
                      y['yearNo']?.toString() == normalizedCcYear ||
                      "Year ${y["yearNo"]}" == normalizedCcYear,
                  orElse: () => null,
                );
                if (yMatch != null) selectedYearId = yMatch['id'];
              }

              if (selectedAcademicYearId == null && ccAcademicYear != null) {
                final ayMatch = academicYears.firstWhere(
                  (ay) => ay['academicYear'] == ccAcademicYear,
                  orElse: () => null,
                );
                if (ayMatch != null) selectedAcademicYearId = ayMatch['id'];
              }
            } else {
              if (selectedDeptId == null && departments.isNotEmpty) {
                selectedDeptId = departments.first['id'];
              }
            }

            if (selectedAcademicYearId == null && academicYears.isNotEmpty) {
              selectedAcademicYearId = academicYears.first['id'];
            }
            if (selectedSemesterId == null && semesters.isNotEmpty) {
              selectedSemesterId = semesters.first['id'];
            }
            if (selectedGenderId == null && genders.isNotEmpty) {
              selectedGenderId = genders.first['id'];
            }

            // Filter sections by department ID (Section entity nests department as a sub-object)
            final filteredSections = sections.where((sec) {
              final depId = sec['department'] != null
                  ? sec['department']['id']
                  : sec['departmentId'];
              return depId == selectedDeptId;
            }).toList();
            if (!isCc &&
                selectedSectionId != null &&
                !filteredSections.any(
                  (sec) => sec['id'] == selectedSectionId,
                )) {
              selectedSectionId = null;
            }

            // Resolve display strings for CC locked fields
            String ccDeptDisplay = ccDeptName ?? '';
            if (isCc && selectedDeptId != null) {
              final d = departments.firstWhere(
                (d) => d['id'] == selectedDeptId,
                orElse: () => null,
              );
              if (d != null) ccDeptDisplay = d['code'] ?? d['name'] ?? '';
            }
            String ccYearDisplay = ccYear != null ? 'Year $ccYear' : '';
            if (isCc && selectedYearId != null) {
              final y = years.firstWhere(
                (y) => y['id'] == selectedYearId,
                orElse: () => null,
              );
              if (y != null) ccYearDisplay = "Year ${y["yearNo"]}";
            }
            final String ccSectionDisplay =
                ccSection != null && ccSection!.isNotEmpty
                ? ccSection!
                : 'None';

            return AlertDialog(
              title: const Text(
                'Register Single Student',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Student Name *',
                      ),
                    ),
                    TextField(
                      controller: regNoController,
                      decoration: const InputDecoration(
                        labelText: 'Register Number * (reg_no)',
                      ),
                    ),
                    TextField(
                      controller: sprNoController,
                      decoration: const InputDecoration(
                        labelText: 'SPR Number (spr_no)',
                      ),
                    ),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email *'),
                    ),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        counterText: '',
                      ),
                    ),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDob == null
                              ? 'Select Date of Birth *'
                              : "DOB: ${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selectedDob == null
                                ? Colors.redAccent
                                : Colors.black87,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2004),
                              firstDate: DateTime(1995),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedDob = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Pick'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // -- CC locked fields shown as info rows --
                    if (isCc) ...[
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade100,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Department',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  ccDeptDisplay,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.lock_outline,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade100,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Year',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  ccYearDisplay,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.lock_outline,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade100,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Section',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  ccSectionDisplay,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.lock_outline,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Non-CC: full editable dropdowns
                      DropdownButtonFormField<int>(
                        initialValue: selectedDeptId,
                        decoration: const InputDecoration(
                          labelText: 'Department *',
                        ),
                        items: departments.map((d) {
                          return DropdownMenuItem<int>(
                            value: d['id'],
                            child: Text(d['code'] ?? d['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDeptId = value;
                            selectedSectionId = null;
                          });
                        },
                      ),
                      DropdownButtonFormField<int>(
                        initialValue: selectedYearId,
                        decoration: const InputDecoration(labelText: 'Year *'),
                        items: years.map((y) {
                          return DropdownMenuItem<int>(
                            value: y['id'],
                            child: Text(
                              y['yearNo'] != null ? "Year ${y["yearNo"]}" : '',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedYearId = value;
                          });
                        },
                      ),
                      DropdownButtonFormField<int?>(
                        initialValue:
                            filteredSections.any(
                              (sec) => sec['id'] == selectedSectionId,
                            )
                            ? selectedSectionId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Section (Optional)',
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('No Section Selected (Optional)'),
                          ),
                          ...filteredSections.map((sec) {
                            return DropdownMenuItem<int?>(
                              value: sec['id'],
                              child: Text(sec['sectionName'] ?? ''),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedSectionId = value;
                          });
                        },
                      ),
                    ],

                    DropdownButtonFormField<int>(
                      initialValue: selectedAcademicYearId,
                      decoration: const InputDecoration(
                        labelText: 'Academic Year *',
                      ),
                      items: academicYears.map((ay) {
                        return DropdownMenuItem<int>(
                          value: ay['id'],
                          child: Text(ay['academicYear'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedAcademicYearId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: selectedSemesterId,
                      decoration: const InputDecoration(
                        labelText: 'Semester *',
                      ),
                      items: semesters.map((s) {
                        return DropdownMenuItem<int>(
                          value: s['id'],
                          child: Text(
                            s['semesterNo'] != null
                                ? "Semester ${s["semesterNo"]}"
                                : '',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedSemesterId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: selectedGenderId,
                      decoration: const InputDecoration(labelText: 'Gender *'),
                      items: genders.map((g) {
                        return DropdownMenuItem<int>(
                          value: g['id'],
                          child: Text(g['genderName'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGenderId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<int?>(
                      initialValue: selectedGroupId,
                      decoration: const InputDecoration(
                        labelText: 'Group (Optional)',
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('No Group Selected (Optional)'),
                        ),
                        ...groups.map((grp) {
                          return DropdownMenuItem<int?>(
                            value: grp['teamId'],
                            child: Text(grp['teamName'] ?? ''),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGroupId = value;
                        });
                      },
                    ),
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Guardian Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: guardianNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Guardian Name *',
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: selectedGuardianRel,
                              decoration: const InputDecoration(
                                labelText: 'Relationship *',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Father',
                                  child: Text('Father'),
                                ),
                                DropdownMenuItem(
                                  value: 'Mother',
                                  child: Text('Mother'),
                                ),
                                DropdownMenuItem(
                                  value: 'Guardian',
                                  child: Text('Guardian'),
                                ),
                                DropdownMenuItem(
                                  value: 'Parent',
                                  child: Text('Parent'),
                                ),
                              ],
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedGuardianRel = value;
                                  guardianRelCtrl.text = value ?? '';
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: guardianPhoneCtrl,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              decoration: const InputDecoration(
                                labelText: 'Parent Mobile Number *',
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: guardianEmailCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Guardian Email',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addSingleStudent(
                      departmentId: selectedDeptId,
                      academicYearId: selectedAcademicYearId,
                      yearId: selectedYearId,
                      semesterId: selectedSemesterId,
                      genderId: selectedGenderId,
                      sectionId: selectedSectionId,
                      groupId: selectedGroupId,
                      address: addressController.text.trim(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF11998e),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showManageGroupsDialog() {
    final TextEditingController groupNameController = TextEditingController();
    final TextEditingController groupSizeController = TextEditingController();
    final TextEditingController captainIdController = TextEditingController();
    final TextEditingController membersController = TextEditingController();
    List<dynamic> localGroups = [];
    bool isGroupsLoading = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void loadGroups() async {
              try {
                final response = await getIt<TeacherProxyService>().get(
                  Uri.parse('${ApiConfig.baseUrl}/api/v1/teams'),
                  headers: {
                    'Authorization':
                        'Bearer ${context.read<AuthProvider>().token!}',
                  },
                );
                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  if (data['success'] == true) {
                    setDialogState(() {
                      localGroups = data['data'] ?? [];
                      isGroupsLoading = false;
                    });
                  }
                }
              } catch (e) {
                setDialogState(() {
                  isGroupsLoading = false;
                });
              }
            }

            if (isGroupsLoading) {
              loadGroups();
            }

            return DefaultTabController(
              length: 2,
              child: AlertDialog(
                title: const Text(
                  'Group Management (CC)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 450,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Color(0xFF11998e),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Color(0xFF11998e),
                        tabs: [
                          Tab(text: 'Create Group'),
                          Tab(text: 'View Groups'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          children: [
                            SingleChildScrollView(
                              child: Column(
                                children: [
                                  TextField(
                                    controller: groupNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Group Name *',
                                    ),
                                  ),
                                  TextField(
                                    controller: groupSizeController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Group Size Limit * (e.g. 5)',
                                    ),
                                  ),
                                  TextField(
                                    controller: captainIdController,
                                    decoration: const InputDecoration(
                                      labelText: 'Captain Student ID *',
                                    ),
                                  ),
                                  TextField(
                                    controller: membersController,
                                    decoration: const InputDecoration(
                                      labelText:
                                          'Member Student IDs (Comma separated)',
                                      hintText: 'e.g. CSE002, CSE003, CSE004',
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final String gName = groupNameController
                                          .text
                                          .trim();
                                      final String gSizeStr =
                                          groupSizeController.text.trim();
                                      final String captId = captainIdController
                                          .text
                                          .trim();
                                      final String memsStr = membersController
                                          .text
                                          .trim();

                                      if (gName.isEmpty ||
                                          gSizeStr.isEmpty ||
                                          captId.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please fill in all required fields.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final int size =
                                          int.tryParse(gSizeStr) ?? 0;
                                      if (size <= 0) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Size must be a valid positive integer.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final List<String> memberIds =
                                          memsStr.isNotEmpty
                                          ? memsStr
                                                .split(',')
                                                .map((s) => s.trim())
                                                .where((s) => s.isNotEmpty)
                                                .toList()
                                          : [];

                                      final int total = 1 + memberIds.length;
                                      if (total > size) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Member count ($total including captain) cannot exceed size limit ($size).',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      try {
                                        final response =
                                            await getIt<TeacherProxyService>().post(
                                              Uri.parse(
                                                '${ApiConfig.baseUrl}/api/v1/teams',
                                              ),
                                              headers: {
                                                'Content-Type':
                                                    'application/json',
                                                'Authorization':
                                                    'Bearer ${context.read<AuthProvider>().token!}',
                                              },
                                              body: jsonEncode({
                                                'name': gName,
                                                'size': size,
                                                'captainStudentId': captId,
                                                'memberStudentIds': memberIds,
                                              }),
                                            );

                                        final data = jsonDecode(response.body);
                                        if (response.statusCode == 201 ||
                                            (response.statusCode == 200 &&
                                                data['success'] == true)) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Group created successfully!',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          groupNameController.clear();
                                          groupSizeController.clear();
                                          captainIdController.clear();
                                          membersController.clear();
                                          setDialogState(() {
                                            isGroupsLoading = true;
                                          });
                                          _fetchStudents();
                                        } else {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                data['message'] ??
                                                    'Failed to create group',
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        ErrorHandler.showSnackBar(context, e);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF11998e),
                                    ),
                                    child: const Text(
                                      'Create Group',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            isGroupsLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : localGroups.isEmpty
                                ? const Center(
                                    child: Text('No groups created yet.'),
                                  )
                                : ListView.builder(
                                    itemCount: localGroups.length,
                                    itemBuilder: (context, index) {
                                      final g = localGroups[index];
                                      final List<dynamic> mems =
                                          g['teamMembers'] ?? [];
                                      return Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                g['teamName'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Captain: ${g["captainName"] ?? ""} (${g["captainId"] ?? ""})",
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                              Text(
                                                "Size Limit: ${g["teamCapacity"] ?? 0} | Current Members: ${mems.length}",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              const Text(
                                                'Members List:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              ...mems.map((m) {
                                                final isCap =
                                                    m['regNo'] ==
                                                    g['captainId'];
                                                return Text(
                                                  "• ${m["fullName"]} (${m["regNo"]})${isCap ? ' - Captain' : ''}",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: isCap
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                );
                                              }),
                                            ],
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
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReportMonitorDialog() {
    final TextEditingController studentIdController = TextEditingController();
    List<dynamic> logs = [];
    bool isSearching = false;
    String? searchError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Discipline Report Monitor',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: studentIdController,
                            decoration: const InputDecoration(
                              labelText: 'Enter Student Registration No',
                              hintText: 'e.g. CSE001',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final String sId = studentIdController.text.trim();
                            if (sId.isEmpty) return;

                            setDialogState(() {
                              isSearching = true;
                              searchError = null;
                              logs = [];
                            });

                            try {
                              final studentResponse =
                                  await getIt<TeacherProxyService>().get(
                                    Uri.parse(
                                      '${ApiConfig.baseUrl}/api/v1/students/search?keyword=$sId',
                                    ),
                                    headers: {
                                      'Authorization':
                                          'Bearer ${context.read<AuthProvider>().token!}',
                                    },
                                  );
                              final studentData = jsonDecode(
                                studentResponse.body,
                              );
                              if (studentResponse.statusCode == 200 &&
                                  studentData['success'] == true) {
                                final List<dynamic> students =
                                    studentData['data']['content'] ?? [];
                                final match = students.firstWhere(
                                  (element) =>
                                      element['regNo']
                                          .toString()
                                          .toLowerCase() ==
                                      sId.toLowerCase(),
                                  orElse: () => null,
                                );
                                if (match != null) {
                                  final int dbId = match['id'];
                                  if (!context.mounted) return;
                                  final logsResponse =
                                      await getIt<TeacherProxyService>().get(
                                        Uri.parse(
                                          '${ApiConfig.baseUrl}/api/v1/students/$dbId/discipline-logs',
                                        ),
                                        headers: {
                                          'Authorization':
                                              'Bearer ${context.read<AuthProvider>().token!}',
                                        },
                                      );
                                  final logsData = jsonDecode(
                                    logsResponse.body,
                                  );
                                  if (logsResponse.statusCode == 200) {
                                    setDialogState(() {
                                      logs = logsData['data'] ?? [];
                                      isSearching = false;
                                      if (logs.isEmpty) {
                                        searchError =
                                            'No discipline entries recorded for this student.';
                                      }
                                    });
                                    return;
                                  }
                                }
                              }
                              setDialogState(() {
                                isSearching = false;
                                searchError =
                                    'Student ID not found in records.';
                              });
                            } catch (e) {
                              setDialogState(() {
                                isSearching = false;
                                searchError = 'Network error fetching logs.';
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                          ),
                          child: const Text(
                            'Search',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: isSearching
                          ? const Center(child: CircularProgressIndicator())
                          : searchError != null
                          ? Center(
                              child: Text(
                                searchError!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : logs.isEmpty
                          ? const Center(
                              child: Text(
                                'Search for a student to monitor discipline logs history.',
                              ),
                            )
                          : ListView.builder(
                              itemCount: logs.length,
                              itemBuilder: (context, index) {
                                final log = logs[index];
                                final int pts = log['points'] ?? 0;
                                final String reason =
                                    log['reason'] ?? 'No reason given';
                                final String recordedBy =
                                    log['recordedByName'] ?? 'Faculty';
                                final String actName = StringUtils.toTitleCase(
                                  log['subgroupName'] ?? 'General',
                                );
                                final String dtStr = log['createdAt'] != null
                                    ? log['createdAt']
                                          .toString()
                                          .replaceAll('T', ' ')
                                          .substring(0, 16)
                                    : '';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: pts >= 0
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.red.withValues(alpha: 0.1),
                                      child: Icon(
                                        pts >= 0
                                            ? Icons.add_circle
                                            : Icons.remove_circle,
                                        color: pts >= 0
                                            ? Colors.green
                                            : Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      reason,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'By: $recordedBy • Act: $actName\nDate: $dtStr',
                                    ),
                                    trailing: Text(
                                      pts >= 0 ? '+$pts' : '$pts',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: pts >= 0
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editStudent({
    required int id,
    required String fullName,
    required String email,
    required String phone,
    required int? genderId,
    required int? departmentId,
    required int? academicYearId,
    required int? yearId,
    required int? semesterId,
    required int? sectionId,
    required int? groupId,
    required String sprNo,
    required DateTime? dob,
    required String address,
    required bool active,
    required String password,
    required String? guardianName,
    required String? guardianRel,
    required String? guardianPhone,
    required String? guardianEmail,
  }) async {
    if (fullName.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Email are required.')),
      );
      return;
    }

    try {
      final response = await getIt<TeacherProxyService>().put(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/students/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'genderId': genderId,
          'departmentId': departmentId,
          'academicYearId': academicYearId,
          'yearId': yearId,
          'semesterId': semesterId,
          'sectionId': sectionId,
          'groupId': groupId,
          'sprNo': sprNo,
          'dob': dob != null
              ? "${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}"
              : null,
          'address': address,
          'active': active,
          'password': password.isEmpty ? null : password,
          'guardian': {
            'guardianName': guardianName,
            'relationship': guardianRel,
            'phoneNo': guardianPhone,
            'email': guardianEmail,
          },
        }),
      );

      if (!context.mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student details updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        setState(() => isLoading = true);
        _fetchStudents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to update student'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showSnackBar(context, e);
    }
  }

  Future<void> _deleteStudent(int id) async {
    try {
      final response = await getIt<TeacherProxyService>().delete(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/students/$id'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );

      debugPrint('DELETE /students/$id => status=${response.statusCode}');
      debugPrint('DELETE body: ${response.body}');

      if (!context.mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => isLoading = true);
        _fetchStudents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Delete failed: ${response.statusCode} - ${response.body}',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint('DELETE exception: $e');
      if (!context.mounted) return;
      ErrorHandler.showSnackBar(context, e);
    }
  }

  void _showEditStudentDialog(Map<String, dynamic> student) {
    final TextEditingController nameCtrl = TextEditingController(
      text: student['fullName'] ?? '',
    );
    final TextEditingController emailCtrl = TextEditingController(
      text: student['email'] ?? '',
    );
    final TextEditingController phoneCtrl = TextEditingController(
      text: student['phone'] ?? '',
    );
    final TextEditingController sprCtrl = TextEditingController(
      text: student['sprNo'] ?? '',
    );
    final TextEditingController addressCtrl = TextEditingController(
      text: student['address'] ?? '',
    );
    final TextEditingController passwordCtrl = TextEditingController();

    // Guardian Controllers
    final TextEditingController guardianNameCtrl = TextEditingController();
    final TextEditingController guardianRelCtrl = TextEditingController();
    final TextEditingController guardianPhoneCtrl = TextEditingController();
    final TextEditingController guardianEmailCtrl = TextEditingController();
    String? selectedGuardianRel;
    final List<String> guardianRelations = [
      'Father',
      'Mother',
      'Guardian',
      'Parent',
    ];

    final g = student['guardian'];
    if (g != null) {
      guardianNameCtrl.text = g['guardianName'] ?? '';
      guardianPhoneCtrl.text = g['phoneNo'] ?? '';
      guardianEmailCtrl.text = g['email'] ?? '';
      String relStr = g['relationship'] ?? '';
      if (relStr.isNotEmpty) {
        relStr = relStr[0].toUpperCase() + relStr.substring(1).toLowerCase();
        if (guardianRelations.contains(relStr)) {
          selectedGuardianRel = relStr;
        } else if (relStr.toUpperCase() == 'LOCAL_GUARDIAN') {
          selectedGuardianRel = 'Parent';
        }
      }
      guardianRelCtrl.text = selectedGuardianRel ?? '';
    }

    List<dynamic> dedup(List<dynamic> list) {
      final seenIds = <int>{};
      return list.where((item) {
        if (item == null || item['id'] == null) return false;
        final id = item['id'] as int;
        if (seenIds.contains(id)) return false;
        seenIds.add(id);
        return true;
      }).toList();
    }

    final uniqueDepartments = dedup(departments);
    final uniqueAcademicYears = dedup(academicYears);
    final uniqueYears = dedup(years);
    final uniqueSemesters = dedup(semesters);
    final uniqueGenders = dedup(genders);
    final uniqueGroups = dedup(groups);

    DateTime? editDob;
    if (student['dateOfBirth'] != null) {
      try {
        editDob = DateTime.parse(student['dateOfBirth']);
      } catch (_) {}
    }

    int? selectedDeptId = student['departmentId'];
    if (selectedDeptId == null && student['departmentName'] != null) {
      final match = uniqueDepartments.firstWhere(
        (d) => d['name'] == student['departmentName'],
        orElse: () => null,
      );
      if (match != null) selectedDeptId = match['id'];
    }
    if (selectedDeptId == null && uniqueDepartments.isNotEmpty) {
      selectedDeptId = uniqueDepartments.first['id'];
    }

    int? selectedAcademicYearId = student['academicYearId'];
    if (selectedAcademicYearId == null && student['academicYear'] != null) {
      final match = uniqueAcademicYears.firstWhere(
        (ay) => ay['academicYear'] == student['academicYear'],
        orElse: () => null,
      );
      if (match != null) selectedAcademicYearId = match['id'];
    }
    if (selectedAcademicYearId == null && uniqueAcademicYears.isNotEmpty) {
      selectedAcademicYearId = uniqueAcademicYears.first['id'];
    }

    int? selectedYearId = student['yearId'];
    if (selectedYearId == null && student['year'] != null) {
      final match = uniqueYears.firstWhere(
        (y) => y['yearNo']?.toString() == student['year'],
        orElse: () => null,
      );
      if (match != null) selectedYearId = match['id'];
    }
    if (selectedYearId == null && uniqueYears.isNotEmpty) {
      selectedYearId = uniqueYears.first['id'];
    }

    int? selectedSemesterId = student['semesterId'];
    if (selectedSemesterId == null && student['semester'] != null) {
      final match = uniqueSemesters.firstWhere(
        (s) => s['semesterNo']?.toString() == student['semester'],
        orElse: () => null,
      );
      if (match != null) selectedSemesterId = match['id'];
    }
    if (selectedSemesterId == null && uniqueSemesters.isNotEmpty) {
      selectedSemesterId = uniqueSemesters.first['id'];
    }

    int? selectedGenderId = student['genderId'];
    if (selectedGenderId == null && student['gender'] != null) {
      final match = uniqueGenders.firstWhere(
        (g) =>
            g['genderName']?.toString().toUpperCase() ==
            student['gender'].toString().toUpperCase(),
        orElse: () => null,
      );
      if (match != null) selectedGenderId = match['id'];
    }
    if (selectedGenderId == null && uniqueGenders.isNotEmpty) {
      selectedGenderId = uniqueGenders.first['id'];
    }

    int? selectedSectionId = student['sectionId'];
    if (selectedSectionId == null && student['section'] != null) {
      final match = sections.firstWhere((sec) {
        final depId = sec['department'] != null
            ? sec['department']['id']
            : sec['departmentId'];
        final sName = _normalizeSectionName(sec['sectionName'] ?? '');
        final targetSec = _normalizeSectionName(student['section'].toString());
        return depId == selectedDeptId && sName == targetSec;
      }, orElse: () => null);
      if (match != null) selectedSectionId = match['id'];
    }
    int? selectedGroupId = student['groupId'];
    bool active = student['active'] ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Filter sections by department ID (Section entity nests department as a sub-object)
            final filteredSections = sections.where((sec) {
              final depId = sec['department'] != null
                  ? sec['department']['id']
                  : sec['departmentId'];
              return depId == selectedDeptId;
            }).toList();
            final uniqueFilteredSections = dedup(filteredSections);
            if (selectedSectionId != null &&
                !uniqueFilteredSections.any(
                  (sec) => sec['id'] == selectedSectionId,
                )) {
              selectedSectionId = null;
            }

            return AlertDialog(
              title: Text(
                "Edit Student: ${student["regNo"]}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                      ),
                    ),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email *'),
                    ),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        counterText: '',
                      ),
                    ),
                    TextField(
                      controller: sprCtrl,
                      decoration: const InputDecoration(labelText: 'SPR No'),
                    ),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText:
                            'Change Password (leave empty to keep current)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          editDob == null
                              ? 'Select Date of Birth *'
                              : "DOB: ${editDob!.year}-${editDob!.month.toString().padLeft(2, '0')}-${editDob!.day.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: editDob ?? DateTime(2004),
                              firstDate: DateTime(1995),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                editDob = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Select'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value:
                          uniqueDepartments.any(
                            (d) => d['id'] == selectedDeptId,
                          )
                          ? selectedDeptId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Department *',
                      ),
                      items: uniqueDepartments.map((d) {
                        return DropdownMenuItem<int>(
                          value: d['id'],
                          child: Text(d['code'] ?? d['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedDeptId = value;
                          selectedSectionId = null;
                        });
                      },
                    ),
                    DropdownButtonFormField<int>(
                      value:
                          uniqueAcademicYears.any(
                            (ay) => ay['id'] == selectedAcademicYearId,
                          )
                          ? selectedAcademicYearId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Academic Year *',
                      ),
                      items: uniqueAcademicYears.map((ay) {
                        return DropdownMenuItem<int>(
                          value: ay['id'],
                          child: Text(ay['academicYear'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedAcademicYearId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<int>(
                      value: uniqueYears.any((y) => y['id'] == selectedYearId)
                          ? selectedYearId
                          : null,
                      decoration: const InputDecoration(labelText: 'Year *'),
                      items: uniqueYears.map((y) {
                        return DropdownMenuItem<int>(
                          value: y['id'],
                          child: Text(
                            y['yearNo'] != null ? "Year ${y["yearNo"]}" : '',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedYearId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<int>(
                      value:
                          uniqueSemesters.any(
                            (s) => s['id'] == selectedSemesterId,
                          )
                          ? selectedSemesterId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Semester *',
                      ),
                      items: uniqueSemesters.map((s) {
                        return DropdownMenuItem<int>(
                          value: s['id'],
                          child: Text(
                            s['semesterNo'] != null
                                ? "Semester ${s["semesterNo"]}"
                                : '',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedSemesterId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<int>(
                      value:
                          uniqueGenders.any((g) => g['id'] == selectedGenderId)
                          ? selectedGenderId
                          : null,
                      decoration: const InputDecoration(labelText: 'Gender *'),
                      items: uniqueGenders.map((g) {
                        return DropdownMenuItem<int>(
                          value: g['id'],
                          child: Text(g['genderName'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGenderId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<int?>(
                      value:
                          uniqueFilteredSections.any(
                            (sec) => sec['id'] == selectedSectionId,
                          )
                          ? selectedSectionId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Section (Optional)',
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('No Section Selected (Optional)'),
                        ),
                        ...uniqueFilteredSections.map((sec) {
                          return DropdownMenuItem<int?>(
                            value: sec['id'],
                            child: Text(sec['sectionName'] ?? ''),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedSectionId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<int?>(
                      value:
                          uniqueGroups.any(
                            (grp) => grp['id'] == selectedGroupId,
                          )
                          ? selectedGroupId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Group (Optional)',
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('No Group Selected (Optional)'),
                        ),
                        ...uniqueGroups.map((grp) {
                          return DropdownMenuItem<int?>(
                            value: grp['id'],
                            child: Text(grp['name'] ?? ''),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGroupId = value;
                        });
                      },
                    ),
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Guardian Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: guardianNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Guardian Name *',
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: selectedGuardianRel,
                              decoration: const InputDecoration(
                                labelText: 'Relationship *',
                              ),
                              items: guardianRelations.map((rel) {
                                return DropdownMenuItem<String>(
                                  value: rel,
                                  child: Text(rel),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedGuardianRel = value;
                                  guardianRelCtrl.text = value ?? '';
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: guardianPhoneCtrl,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              decoration: const InputDecoration(
                                labelText: 'Parent Mobile Number *',
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: guardianEmailCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Guardian Email',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: active,
                      onChanged: (value) {
                        setDialogState(() {
                          active = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _editStudent(
                      id: student['id'],
                      fullName: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      genderId: selectedGenderId,
                      departmentId: selectedDeptId,
                      academicYearId: selectedAcademicYearId,
                      yearId: selectedYearId,
                      semesterId: selectedSemesterId,
                      sectionId: selectedSectionId,
                      groupId: selectedGroupId,
                      sprNo: sprCtrl.text.trim(),
                      dob: editDob,
                      address: addressCtrl.text.trim(),
                      active: active,
                      password: passwordCtrl.text.trim(),
                      guardianName: guardianNameCtrl.text.trim(),
                      guardianRel: selectedGuardianRel,
                      guardianPhone: guardianPhoneCtrl.text.trim(),
                      guardianEmail: guardianEmailCtrl.text.trim(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF11998e),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
