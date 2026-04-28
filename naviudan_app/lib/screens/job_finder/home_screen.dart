import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/cards.dart';
import '../profile/profile_sheet.dart';
import 'ai_chat_screen.dart';
import 'job_application_form_screen.dart';
import 'saved_jobs_screen.dart';
import 'my_applications_screen.dart';
import 'weekly_plan_screen.dart';

class JobFinderHomeScreen extends StatefulWidget {
  const JobFinderHomeScreen({super.key});

  @override
  State<JobFinderHomeScreen> createState() => _JobFinderHomeScreenState();
}

class _JobFinderHomeScreenState extends State<JobFinderHomeScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final user = context.read<UserProvider>();
    final jobs = context.read<JobProvider>();
    await user.loadUserProfile();
    final uid = user.uid;
    if (uid != null) {
      await Future.wait([
        jobs.loadMyApplications(uid),
        jobs.loadSavedJobs(uid),
        jobs.loadMatchedJobs(uid),
        jobs.loadCourses(uid),
        jobs.loadWeeklyPlan(uid),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _HomeTab(onRefresh: _loadData),
          const SavedJobsScreen(),
          const MyApplicationsScreen(),
          const AIChatScreen(),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
      floatingActionButton: _navIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _navIndex = 3),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.smart_toy_rounded, color: Colors.white),
              label: const Text('NaviBot',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceLight, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_rounded), label: 'Saved'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_rounded), label: 'Applied'),
          BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_rounded), label: 'NaviBot'),
        ],
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const _HomeTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();
    final jobProv  = context.watch<JobProvider>();
    final user     = userProv.user;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A2E), AppColors.background],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${user?.name.split(' ').first ?? 'there'} 👋',
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Find your perfect career path',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => showProfileSheet(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stats row
                  if (user != null)
                    Row(children: [
                      _stat(Icons.star_rounded, '${user.skills.length}', 'Skills',
                          AppColors.accentAmber),
                      const SizedBox(width: 12),
                      _stat(Icons.interests_rounded, '${user.interests.length}',
                          'Interests', AppColors.primaryLight),
                      const SizedBox(width: 12),
                      _stat(Icons.work_rounded, '${jobProv.matchedJobs.length}',
                          'Jobs Found', AppColors.accentGreen),
                    ]),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // AI Career Analysis card
                _AIAnalysisCard(user: user, jobProv: jobProv),
                const SizedBox(height: 24),

                // Weekly Plan teaser
                SectionHeader(
                  title: '📅 Weekly Plan',
                  actionText: 'View Full Plan',
                  onAction: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const WeeklyPlanScreen())),
                ),
                if (jobProv.weeklyPlanCourseTitle != null &&
                    jobProv.weeklyPlanCourseTitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Focused on: ${jobProv.weeklyPlanCourseTitle}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (jobProv.weeklyPlan.isNotEmpty)
                  _WeeklyPlanTeaser(day: jobProv.weeklyPlan.first)
                else if ((jobProv.weeklyPlanMessage ?? '').isNotEmpty)
                  _EmptyCard(text: jobProv.weeklyPlanMessage!),
                const SizedBox(height: 24),

                // Courses
                const SectionHeader(title: '📚 AI picks — free courses for you'),
                const SizedBox(height: 12),
                if (jobProv.isLoading && jobProv.courses.isEmpty)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary))
                else if (jobProv.courses.isEmpty)
                  _EmptyCard(
                    text: jobProv.coursesMessage ??
                        'No courses found. Update your interests!',
                  )
                else
                  SizedBox(
                    height: 248,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: jobProv.courses.length,
                      itemBuilder: (_, i) {
                        final c = jobProv.courses[i];
                        return CourseCard(
                          course: c,
                          onWeeklyPlan: (course) async {
                            final uid = context.read<UserProvider>().uid;
                            if (uid == null) return;
                            if (course.url.isEmpty) return;
                            final jp = context.read<JobProvider>();
                            await jp.loadWeeklyPlan(
                              uid,
                              courseId: course.id,
                              courseTitle: course.title,
                              courseUrl: course.url,
                            );
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WeeklyPlanScreen(
                                  courseId: course.id,
                                  courseTitle: course.title,
                                  courseUrl: course.url,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),

                // Jobs
                SectionHeader(title: '💼 Job Matches'),
                const SizedBox(height: 12),
                if (jobProv.isLoading && jobProv.matchedJobs.isEmpty)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary))
                else if (jobProv.matchedJobs.isEmpty)
                  const _EmptyCard(text: 'No jobs matched yet. Complete your profile!')
                else
                  ...jobProv.matchedJobs
                      .take(5)
                      .map((job) => JobCard(
                            job: job,
                            isApplied:
                                job.id != null && jobProv.hasAppliedToJob(job.id!),
                            onApply: () async {
                              final uid = context.read<UserProvider>().uid;
                              if (uid != null && job.id != null) {
                                final jp = context.read<JobProvider>();
                                if (jp.hasAppliedToJob(job.id!)) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Applied successfully already.'),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                final submitted = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        JobApplicationFormScreen(job: job),
                                  ),
                                );
                                if (submitted == true) {
                                  await jp.loadMatchedJobs(uid);
                                }
                              }
                            },
                            onSave: () async {
                              final uid = context.read<UserProvider>().uid;
                              if (uid != null && job.id != null) {
                                await context
                                    .read<JobProvider>()
                                    .saveJob(uid, job.id!);
                              }
                            },
                          )),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AIAnalysisCard extends StatelessWidget {
  final dynamic user;
  final JobProvider jobProv;
  const _AIAnalysisCard({this.user, required this.jobProv});

  @override
  Widget build(BuildContext context) {
    final analysis = jobProv.aiAnalysis;
    if (analysis == null) {
      return GlassCard(
        gradient: AppColors.primaryGradient,
        child: Row(
          children: [
            const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI Career Analysis',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text('Get your personalised career roadmap',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12, height: 1.4)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      if (user != null) {
                        await jobProv.runAiAnalysis({
                          'uid': user.uid,
                          'skills': user.skills,
                          'interests': user.interests,
                          'education': user.educationStatus,
                          'state': user.state ?? 'default',
                          'language': user.preferredLanguage,
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Analyse Now →',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      gradient: AppColors.primaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Text('AI Career Insight',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('✨ AI',
                    style:
                        TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '🎯 ${analysis.careerDirection}',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14),
          ),
          if (analysis.skillGaps.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Skill gaps: ${analysis.skillGaps.take(3).join(', ')}',
              style:
                  const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyPlanTeaser extends StatelessWidget {
  final dynamic day;
  const _WeeklyPlanTeaser({required this.day});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: AppColors.greenGradient,
      child: Row(
        children: [
          const Icon(Icons.today_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day.day,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
                Text(day.topic,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                Text(day.goal,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Center(
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center),
      ),
    );
  }
}
