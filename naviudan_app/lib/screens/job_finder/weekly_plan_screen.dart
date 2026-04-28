import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../providers/job_provider.dart';
class WeeklyPlanScreen extends StatefulWidget {
  /// Catalogue or AI-generated course id (optional if [courseTitle] + [courseUrl] set).
  final String? courseId;
  final String? courseTitle;
  final String? courseUrl;

  const WeeklyPlanScreen({
    super.key,
    this.courseId,
    this.courseTitle,
    this.courseUrl,
  });

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<UserProvider>().uid;
      if (uid == null) return;
      final hasId =
          widget.courseId != null && widget.courseId!.trim().isNotEmpty;
      final hasDirect = (widget.courseTitle ?? '').trim().isNotEmpty &&
          (widget.courseUrl ?? '').trim().isNotEmpty;
      if (hasId || hasDirect) {
        context.read<JobProvider>().loadWeeklyPlan(
          uid,
          courseId: hasId ? widget.courseId : null,
          courseTitle: widget.courseTitle,
          courseUrl: widget.courseUrl,
        );
      }
    });
  }

  static const List<Color> _dayColors = [
    Color(0xFFFF8C42),
    Color(0xFFFFB340),
    Color(0xFF138808),
    Color(0xFF000080),
    Color(0xFFFF6B6B),
    Color(0xFFFF8C42),
    Color(0xFF138808),
  ];

  static const List<String> _dayIcons = ['🌟', '🎯', '📚', '💡', '🚀', '🔥', '🏆'];

  @override
  Widget build(BuildContext context) {
    final jobProv = context.watch<JobProvider>();
    final plan = jobProv.weeklyPlan;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          jobProv.weeklyPlanCourseTitle != null && jobProv.weeklyPlanCourseTitle!.isNotEmpty
              ? '📅 ${jobProv.weeklyPlanCourseTitle!}'
              : '📅 Weekly Learning Plan',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.background,
      ),
      body: jobProv.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : plan.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      (jobProv.weeklyPlanMessage ?? '').isNotEmpty
                          ? jobProv.weeklyPlanMessage!
                          : 'No plan generated yet.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: plan.length,
                  itemBuilder: (_, i) {
                    final day = plan[i];
                    final color = _dayColors[i % _dayColors.length];
                    final emoji = _dayIcons[i % _dayIcons.length];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.surfaceLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                bottomLeft: Radius.circular(18),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(emoji, style: const TextStyle(fontSize: 22)),
                                  const SizedBox(height: 6),
                                  RotatedBox(
                                    quarterTurns: 1,
                                    child: Text(
                                      day.day.substring(0, 3).toUpperCase(),
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    day.day,
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    day.topic,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    day.goal,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                        height: 1.4),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.link_rounded,
                                            color: color, size: 14),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            day.resource,
                                            style: TextStyle(
                                                color: color,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
