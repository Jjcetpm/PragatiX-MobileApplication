import 'package:flutter/material.dart';
import 'package:pragatix/features/activity/providers/activity_provider.dart';
import 'package:pragatix/features/activity/widgets/activity_form.dart';
import 'package:pragatix/features/activity/widgets/sticky_bottom_buttons.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Create Activity Page – full-screen form for new activities.
// Delegates save to ActivityProvider. Pops with true on success.
// ─────────────────────────────────────────────────────────────────────────────

class CreateActivityPage extends StatefulWidget {
  final ActivityProvider provider;
  final int? stageId;
  final int? subgroupId;
  final String? subgroupName;
  final String? academicYear;
  final bool isCc;

  const CreateActivityPage({
    super.key,
    required this.provider,
    this.stageId,
    this.subgroupId,
    this.subgroupName,
    this.academicYear,
    this.isCc = false,
  });

  @override
  State<CreateActivityPage> createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage>
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

    body['stageId'] = widget.stageId;
    body['subgroupId'] = widget.subgroupId;
    body['subgroup'] = widget.subgroupName;
    body['isMandatory'] = (widget.subgroupName?.toLowerCase().contains('must') == true);

    final ok = await widget.provider.createActivity(
      body,
      stageId: widget.stageId,
      subgroupName: widget.subgroupName,
      academicYear: widget.academicYear,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity created successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.provider.error ?? 'Failed to create activity.'),
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
                  'Create Event',
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
          saveLabel: 'Create Event',
          onSave: _onSave,
          onCancel: () => Navigator.pop(context),
          isSaving: widget.provider.isSaving,
        ),
      ),
    );
  }
}
