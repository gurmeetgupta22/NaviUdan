import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/cards.dart';
import 'job_application_form_screen.dart';

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<UserProvider>().uid;
      if (uid != null) {
        context.read<JobProvider>().loadSavedJobs(uid);
        context.read<JobProvider>().loadMyApplications(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobProv = context.watch<JobProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Jobs'),
        backgroundColor: AppColors.background,
      ),
      body: jobProv.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : jobProv.savedJobs.isEmpty
              ? _empty()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: jobProv.savedJobs.length,
                  itemBuilder: (_, i) => JobCard(
                    job: jobProv.savedJobs[i],
                    isSaved: true,
                    isApplied: jobProv.savedJobs[i].id != null &&
                        jobProv.hasAppliedToJob(jobProv.savedJobs[i].id!),
                    onApply: () async {
                      final uid = context.read<UserProvider>().uid;
                      final job = jobProv.savedJobs[i];
                      final jobId = job.id;
                      if (uid != null && jobId != null) {
                        if (jobProv.hasAppliedToJob(jobId)) return;
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobApplicationFormScreen(job: job),
                          ),
                        );
                      }
                    },
                  ),
                ),
    );
  }

  Widget _empty() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bookmark_border_rounded, color: AppColors.textHint, size: 64),
        SizedBox(height: 16),
        Text('No saved jobs yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        SizedBox(height: 8),
        Text('Browse jobs and tap Save', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
      ],
    ),
  );
}
