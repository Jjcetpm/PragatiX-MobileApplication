import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/penalty/providers/penalty_provider.dart';
import 'package:pragatix/features/penalty/pages/tabs/cc_inbox_tab.dart';
import 'package:pragatix/features/penalty/pages/tabs/my_requests_tab.dart';

class PenaltyRequestsPage extends StatefulWidget {
  final bool isCC;

  const PenaltyRequestsPage({super.key, required this.isCC});

  @override
  State<PenaltyRequestsPage> createState() => _PenaltyRequestsPageState();
}

class _PenaltyRequestsPageState extends State<PenaltyRequestsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PenaltyProvider>();
      provider.loadMyRequests();
      if (widget.isCC) {
        provider.loadCcInbox();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: widget.isCC ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Penalty Requests',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1E293B),
          bottom: TabBar(
            indicatorColor: const Color(0xFF11998e),
            labelColor: const Color(0xFF11998e),
            unselectedLabelColor: Colors.grey,
            tabs: [
              if (widget.isCC) const Tab(text: 'My Class'),
              const Tab(text: 'My Requests'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            if (widget.isCC) const CcInboxTab(),
            const MyRequestsTab(),
          ],
        ),
      ),
    );
  }
}
