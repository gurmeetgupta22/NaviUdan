import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common_widgets.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<UserProvider>().uid;
      if (uid != null) context.read<JobProvider>().loadMyApplications(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobProv = context.watch<JobProvider>();
    final apps = jobProv.myApplications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Applications'),
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
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.work_outline_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Job ID: ${app.jobId}',
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Applied',
                                    style: const TextStyle(
                                        color: AppColors.textHint, fontSize: 12)),
                                if ((app.applicationText ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      app.applicationText!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11),
                                    ),
                                  ),
                                if (app.attachments.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Attachments: ${app.attachments.length}',
                                      style: const TextStyle(
                                          color: AppColors.textHint, fontSize: 11),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          StatusChip(status: app.status),
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
        Icon(Icons.assignment_outlined, color: AppColors.textHint, size: 64),
        SizedBox(height: 16),
        Text("You haven't applied to any jobs yet",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        SizedBox(height: 8),
        Text('Browse jobs and tap Apply Now',
            style: TextStyle(color: AppColors.textHint, fontSize: 13)),
      ],
    ),
  );
}
