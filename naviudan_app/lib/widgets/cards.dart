import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../models/job_model.dart';
import '../models/course_model.dart';

// ─── Job Card ─────────────────────────────────────────────────────────────────

String? _formatJobExpiry(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  try {
    final d = DateTime.parse(iso);
    return '${d.day}/${d.month}/${d.year}';
  } catch (_) {
    return null;
  }
}

class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback? onApply;
  final VoidCallback? onSave;
  final bool isSaved;
  final bool isApplied;

  const JobCard({
    super.key,
    required this.job,
    this.onApply,
    this.onSave,
    this.isSaved = false,
    this.isApplied = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
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
                      Text(job.title,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(job.location,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      if (_formatJobExpiry(job.expiresAt) != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Listed until ${_formatJobExpiry(job.expiresAt)}',
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _jobTypeBadge(job.jobTypLabel),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              job.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 10),
          if (job.skillsRequired.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: job.skillsRequired
                    .take(4)
                    .map((s) => _skillChip(s))
                    .toList(),
              ),
            ),
          const SizedBox(height: 12),
          if (job.salary != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.currency_rupee_rounded,
                      color: AppColors.accentGreen, size: 16),
                  const SizedBox(width: 4),
                  Text(job.salary!,
                      style: const TextStyle(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onSave,
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
                      size: 18,
                      color: isSaved
                          ? AppColors.accentAmber
                          : AppColors.textSecondary,
                    ),
                    label: Text(
                      isSaved ? 'Saved' : 'Save',
                      style: TextStyle(
                        color: isSaved
                            ? AppColors.accentAmber
                            : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isApplied ? null : onApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isApplied ? AppColors.success : AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      isApplied ? 'Applied Successfully' : 'Apply Now',
                      style: const TextStyle(fontSize: 13),
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

  Widget _jobTypeBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.primaryLight,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _skillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(skill,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 11)),
    );
  }
}

// ─── Course Card ──────────────────────────────────────────────────────────────

class CourseCard extends StatelessWidget {
  final CourseModel course;
  final void Function(CourseModel course)? onWeeklyPlan;

  const CourseCard({
    super.key,
    required this.course,
    this.onWeeklyPlan,
  });

  Color get _platformColor {
    switch (course.platform.toLowerCase()) {
      case 'youtube':  return const Color(0xFFFF0000);
      case 'coursera': return const Color(0xFF0056D2);
      case 'udemy':    return const Color(0xFFEC5252);
      default:         return AppColors.primary;
    }
  }

  IconData get _platformIcon {
    switch (course.platform.toLowerCase()) {
      case 'youtube':  return Icons.smart_display_rounded;
      case 'coursera': return Icons.school_rounded;
      case 'udemy':    return Icons.play_circle_filled_rounded;
      default:         return Icons.book_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () async {
              final uri = Uri.parse(course.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: _platformColor.withOpacity(0.15),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Icon(_platformIcon, color: _platformColor, size: 32),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.35),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _platformColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(course.platform,
                                style: TextStyle(
                                    color: _platformColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: course.isFree
                                  ? AppColors.success.withOpacity(0.15)
                                  : AppColors.accentAmber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              course.isFree ? 'FREE' : 'PAID',
                              style: TextStyle(
                                  color: course.isFree
                                      ? AppColors.success
                                      : AppColors.accentAmber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      if (course.duration != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded,
                                color: AppColors.textHint, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                course.duration!,
                                style: const TextStyle(
                                    color: AppColors.textHint, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onWeeklyPlan != null &&
              course.url.isNotEmpty &&
              (course.id != null || course.title.isNotEmpty)) ...[
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: TextButton.icon(
                onPressed: () => onWeeklyPlan!(course),
                icon: Icon(Icons.calendar_month_rounded,
                    size: 16, color: _platformColor),
                label: Text(
                  '7-day plan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _platformColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
