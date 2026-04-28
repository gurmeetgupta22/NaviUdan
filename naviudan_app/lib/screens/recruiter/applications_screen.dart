import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../providers/job_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<UserProvider>().uid;
      if (uid != null) {
        context.read<JobProvider>().loadRecruiterApplications(uid);
      }
    });
  }

  Future<void> _updateStatus(String appId, String status) async {
    try {
      await ApiService.updateApplicationStatus(appId, status);
      final uid = context.read<UserProvider>().uid;
      if (uid != null && mounted) {
        await context.read<JobProvider>().loadRecruiterApplications(uid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobProv = context.watch<JobProvider>();
    final apps = jobProv.recruiterApplications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Applications (${apps.length})'),
        backgroundColor: AppColors.background,
      ),
      body: jobProv.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : apps.isEmpty
              ? _empty()
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: apps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final app = apps[i];
                    return GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  gradient: AppColors.greenGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.person_rounded,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Applicant',
                                        style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    Text(
                                      app.applicantUid.length > 16
                                          ? '${app.applicantUid.substring(0, 16)}...'
                                          : app.applicantUid,
                                      style: const TextStyle(
                                          color: AppColors.textHint, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              StatusChip(status: app.status),
                            ],
                          ),
                          if (app.status == 'pending' && app.id != null) ...[
                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _updateStatus(app.id!, 'rejected'),
                                    icon: const Icon(Icons.close_rounded,
                                        size: 16, color: AppColors.error),
                                    label: const Text('Reject',
                                        style: TextStyle(color: AppColors.error)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.error),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _updateStatus(app.id!, 'accepted'),
                                    icon: const Icon(Icons.check_rounded,
                                        size: 16, color: Colors.white),
                                    label: const Text('Accept'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _empty() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inbox_rounded, color: AppColors.textHint, size: 64),
        SizedBox(height: 16),
        Text('No applications yet',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        SizedBox(height: 8),
        Text('Post jobs to start receiving applications',
            style: TextStyle(color: AppColors.textHint, fontSize: 13)),
      ],
    ),
  );
}
