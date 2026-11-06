import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/badge/models/badge_item.dart';
import 'package:pragatix/features/badge/providers/badge_provider.dart';

class AdminAddEditBadgePage extends StatefulWidget {
  final BadgeItem? badge;

  const AdminAddEditBadgePage({super.key, this.badge});

  @override
  State<AdminAddEditBadgePage> createState() => _AdminAddEditBadgePageState();
}

class _AdminAddEditBadgePageState extends State<AdminAddEditBadgePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _authorityController;

  final List<String> _tiers = ['FOUNDATION', 'ACHIEVEMENT', 'EXCELLENCE', 'ELITE', 'LEGACY'];
  final List<String> _rarities = ['COMMON', 'RARE', 'EPIC', 'LEGENDARY'];
  final List<Map<String, String>> _yearOptions = [
    {'value': '', 'label': 'All Years (General)'},
    {'value': 'FIRST_YEAR', 'label': '1st Year'},
    {'value': 'SECOND_YEAR', 'label': '2nd Year'},
    {'value': 'THIRD_YEAR', 'label': '3rd Year'},
    {'value': 'FOURTH_YEAR', 'label': '4th Year'},
  ];

  late String _selectedTier;
  late String _selectedRarity;
  late String _selectedAcademicYear;
  late bool _proofRequired;
  late bool _isActive;

  bool _isSaving = false;

  bool get isEditing => widget.badge != null;

  @override
  void initState() {
    super.initState();
    final badge = widget.badge;

    _nameController = TextEditingController(text: badge?.name ?? '');
    _descriptionController = TextEditingController(text: badge?.description ?? '');
    _authorityController = TextEditingController(text: badge?.approvalAuthority ?? 'Admin');

    final String rawTier = (badge?.tier ?? 'ACHIEVEMENT').trim().toUpperCase();
    _selectedTier = _tiers.contains(rawTier) ? rawTier : _tiers.first;

    final String rawRarity = (badge?.rarity ?? 'COMMON').trim().toUpperCase();
    _selectedRarity = _rarities.contains(rawRarity) ? rawRarity : _rarities.first;

    _selectedAcademicYear = badge?.academicYear ?? '';
    _proofRequired = badge?.proofRequired ?? true;
    _isActive = badge?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _authorityController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _isSaving = true);

    final data = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'tier': _selectedTier,
      'rarity': _selectedRarity,
      'xpRequired': widget.badge?.xpRequired ?? 0,
      'approvalAuthority': _authorityController.text.trim().isEmpty ? 'Admin' : _authorityController.text.trim(),
      'iconUrl': widget.badge?.iconUrl ?? '',
      'proofRequired': _proofRequired,
      'isActive': _isActive,
      'academicYear': _selectedAcademicYear.trim().isEmpty ? null : _selectedAcademicYear.trim(),
    };

    final badgeProvider = context.read<BadgeProvider>();
    final res = isEditing
        ? await badgeProvider.updateBadge(token, widget.badge!.id, data)
        : await badgeProvider.createBadge(token, data);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Saved successfully'),
          backgroundColor: res['success'] == true ? Colors.green : Colors.red,
        ),
      );
      if (res['success'] == true) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Badge' : 'Add New Badge',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA4335),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    isEditing ? 'Save Changes' : 'Create Badge',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── LIVE PREVIEW CARD ──────────────────────────────────────────
              _buildLivePreviewCard(),

              const SizedBox(height: 20),

              // ── SECTION 1: BADGE DETAILS ──────────────────────────────────
              _buildSectionCard(
                title: 'Badge Details',
                icon: Icons.badge_outlined,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Badge Name *',
                      hintText: 'e.g. Hackathon Winner, Active Contributor',
                      prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF1E293B)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter badge name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the criteria or activity required to earn this badge',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.description_outlined, color: Color(0xFF1E293B)),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── SECTION 2: CLASSIFICATION & APPROVAL ──────────────────────
              _buildSectionCard(
                title: 'Badge Classification & Target Year',
                icon: Icons.military_tech_outlined,
                children: [
                  // Year Selection
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAcademicYear,
                    decoration: InputDecoration(
                      labelText: 'Target Academic Year',
                      hintText: 'Select eligible year (or All Years)',
                      prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFF1E293B)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: _yearOptions
                        .map((y) => DropdownMenuItem(
                              value: y['value'],
                              child: Text(
                                y['label']!,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedAcademicYear = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedTier,
                          decoration: InputDecoration(
                            labelText: 'Tier',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          items: _tiers
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedTier = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedRarity,
                          decoration: InputDecoration(
                            labelText: 'Rarity',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          items: _rarities
                              .map((r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedRarity = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _authorityController,
                    decoration: InputDecoration(
                      labelText: 'Approval Authority',
                      hintText: 'Admin / Faculty / Class Coordinator',
                      prefixIcon: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF1E293B)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── SECTION 3: BADGE ACTIVE STATUS (ON / OFF) ─────────────────
              _buildActiveStatusToggleCard(),

              const SizedBox(height: 16),

              // ── SECTION 4: PROOF REQUIREMENT TOGGLE ────────────────────────
              _buildProofToggleCard(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLivePreviewCard() {
    final previewName = _nameController.text.trim().isEmpty ? 'Badge Name Preview' : _nameController.text.trim();
    final previewDesc = _descriptionController.text.trim().isEmpty ? 'Badge description will appear here...' : _descriptionController.text.trim();
    final yearOption = _yearOptions.firstWhere((y) => y['value'] == _selectedAcademicYear, orElse: () => {'label': 'All Years'});

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.preview_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE PREVIEW',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.8),
                  ),
                ],
              ),
              _buildBadgeChip(
                _isActive ? 'ACTIVE (ON)' : 'INACTIVE (OFF)',
                _isActive ? Colors.green.shade50 : Colors.grey.shade100,
                _isActive ? Colors.green.shade800 : Colors.grey.shade700,
                icon: _isActive ? Icons.power_settings_new_rounded : Icons.power_off_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Icon(Icons.workspace_premium, color: Colors.amber, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      previewName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildBadgeChip(yearOption['label']!, Colors.blue.shade50, Colors.blue.shade800, icon: Icons.calendar_today_outlined),
                        _buildBadgeChip(_selectedTier, Colors.indigo.shade50, Colors.indigo.shade700),
                        _buildBadgeChip(_selectedRarity, Colors.purple.shade50, Colors.purple.shade700),
                        _proofRequired
                            ? _buildBadgeChip('Proof Required', Colors.green.shade50, Colors.green.shade800, icon: Icons.verified_user_rounded)
                            : _buildBadgeChip('No Proof Needed', Colors.grey.shade100, Colors.grey.shade700, icon: Icons.link_off_rounded),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            previewDesc,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStatusToggleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isActive ? Colors.green.shade50.withValues(alpha: 0.6) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isActive ? Colors.green.shade300 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                color: _isActive ? Colors.green.shade700 : Colors.grey.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Badge Status (ON / OFF)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _isActive ? Colors.green.shade900 : Colors.grey.shade900,
                      ),
                    ),
                    Text(
                      _isActive ? 'ON: Active & Claimable by students' : 'OFF: Inactive & Hidden from students',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isActive ? Colors.green.shade800 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isActive,
                activeThumbColor: Colors.green,
                onChanged: (val) {
                  setState(() => _isActive = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _isActive
                ? 'Students meeting the year eligibility criteria can view and request to claim this badge.'
                : 'This badge will be temporarily disabled and cannot be claimed by any student until switched ON.',
            style: TextStyle(
              fontSize: 12,
              color: _isActive ? Colors.green.shade800 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFFEA4335)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProofToggleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _proofRequired ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _proofRequired ? Colors.green.shade300 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _proofRequired ? Icons.verified_user_rounded : Icons.link_off_rounded,
                color: _proofRequired ? Colors.green.shade700 : Colors.grey.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proof Link Compulsory',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _proofRequired ? Colors.green.shade900 : Colors.grey.shade900,
                      ),
                    ),
                    Text(
                      _proofRequired ? 'Mandatory URL required to claim' : 'Proof link is optional',
                      style: TextStyle(
                        fontSize: 12,
                        color: _proofRequired ? Colors.green.shade800 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _proofRequired,
                activeThumbColor: Colors.green,
                onChanged: (val) {
                  setState(() => _proofRequired = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _proofRequired ? Colors.green.shade200 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: _proofRequired ? Colors.green.shade700 : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _proofRequired
                        ? 'When enabled, students MUST provide a valid proof link (e.g. GitHub repo, Certificate link) to submit a request.'
                        : 'When disabled, students can directly claim this badge without submitting any proof link.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _proofRequired ? Colors.green.shade800 : Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeChip(String label, Color bg, Color text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: text.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: text),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
