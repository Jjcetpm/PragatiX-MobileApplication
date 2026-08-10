import 'package:flutter/material.dart';
import 'package:pragatix/features/activity/models/activity_model.dart';
import 'package:pragatix/features/activity/providers/activity_provider.dart';
import 'package:pragatix/features/activity/widgets/activity_form.dart';
import 'package:pragatix/features/activity/widgets/sticky_bottom_buttons.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Edit Activity Page – reuses ActivityForm with pre-filled data.
// Shares the same form widget as CreateActivityPage (no code duplication).
// ─────────────────────────────────────────────────────────────────────────────

class EditActivityPage extends StatefulWidget {
  final ActivityProvider provider;
  final ActivityModel activity;
  final bool isCc;
  final int? stageId;
  final String? subgroupName;
  final String? academicYear;

  const EditActivityPage({
    super.key,
    required this.provider,
    required this.activity,
    this.isCc = false,
    this.stageId,
    this.subgroupName,
    this.academicYear,
  });

  @override
  State<EditActivityPage> createState() => _EditActivityPageState();
}

class _EditActivityPageState extends State<EditActivityPage>
    with SingleTickerProviderStateMixin {
  static const Color _dark = Color(0xFF1E293B);

  final _formKey = GlobalKey<ActivityFormState>();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final body = _formKey.currentState?.buildBody();
    if (body == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ok = await widget.provider.updateActivity(
      widget.activity.id, 
      body,
      stageId: widget.stageId,
      subgroupName: widget.subgroupName,
      academicYear: widget.academicYear,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.provider.error ?? 'Failed to update event.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: 110,
              backgroundColor: _dark,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Edit Event',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E293B), Color(0xFF334155)],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _onSave,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
          body: ListenableBuilder(
            listenable: widget.provider,
            builder: (context, _) {
              if (widget.provider.isLoadingDependencies) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: [
                  Expanded(
                    child: ActivityForm(
                      key: _formKey,
                      allTeachers: widget.provider.allTeachers,
                      sections: widget.provider.sections,
                      provider: widget.provider,
                      initialData: widget.activity,
                      isCc: widget.isCc,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.provider,
        builder: (context, _) => StickyBottomButtons(
          saveLabel: 'Save Changes',
          onSave: _onSave,
          onCancel: () => Navigator.pop(context),
          isSaving: widget.provider.isSaving,
        ),
      ),
    );
  }
}
