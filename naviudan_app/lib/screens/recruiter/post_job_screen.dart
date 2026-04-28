import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/india_regions.dart';
import '../../providers/user_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common_widgets.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _salaryCtrl   = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _skillInput   = TextEditingController();

  String _jobType = 'full_time';
  String _state   = 'Maharashtra';
  int _listingDays = 30;
  final List<String> _skills = [];
  bool _isLoading = false;

  static const List<String> _jobTypes = [
    'full_time', 'part_time', 'internship', 'contract'
  ];

  String _jobTypeLabel(String v) {
    switch (v) {
      case 'part_time':  return 'Part Time';
      case 'internship': return 'Internship';
      case 'contract':   return 'Contract';
      default:           return 'Full Time';
    }
  }

  Future<void> _post() async {
    if (_titleCtrl.text.isEmpty || _locationCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')));
      return;
    }
    final uid = context.read<UserProvider>().uid;
    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in and load your profile before posting.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'recruiter_uid':   uid,
      'title':           _titleCtrl.text.trim(),
      'description':     _descCtrl.text.trim(),
      'skills_required': _skills,
      'salary':          _salaryCtrl.text.trim().isEmpty ? null : _salaryCtrl.text.trim(),
      'job_type':        _jobType,
      'location':        _locationCtrl.text.trim(),
      'state':           _state,
      'listing_days':    _listingDays,
    };

    final ok = await context.read<JobProvider>().postJob(
          data,
          recruiterUid: uid,
        );
    setState(() => _isLoading = false);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '✅ Job posted successfully!' : '❌ Failed to post job'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ));
      if (ok) {
        _titleCtrl.clear();
        _descCtrl.clear();
        _salaryCtrl.clear();
        _locationCtrl.clear();
        setState(() => _skills.clear());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post a Job'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _lbl('Job Title *'),
            AppTextField(
              hint: 'e.g. Frontend Developer',
              controller: _titleCtrl,
              prefixIcon: const Icon(Icons.work_outline_rounded, color: AppColors.textHint),
            ),
            const SizedBox(height: 16),

            _lbl('Job Description'),
            AppTextField(
              hint: 'Describe the role, responsibilities, and requirements...',
              controller: _descCtrl,
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            _lbl('Job Type'),
            _JobTypeSelector(
              selected: _jobType,
              types: _jobTypes,
              labelFn: _jobTypeLabel,
              onSelected: (v) => setState(() => _jobType = v),
            ),
            const SizedBox(height: 16),

            _lbl('Location *'),
            AppTextField(
              hint: 'City / Area',
              controller: _locationCtrl,
              prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textHint),
            ),
            const SizedBox(height: 16),

            _lbl('State'),
            DropdownButtonFormField<String>(
              value: _state,
              onChanged: (v) => setState(() => _state = v!),
              dropdownColor: AppColors.surfaceCard,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceCard,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.surfaceLight)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: kIndiaStatesAndUTs
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
            ),
            const SizedBox(height: 16),

            _lbl('How long should this job stay visible?'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [7, 14, 30, 60, 90].map((d) {
                final sel = _listingDays == d;
                return ChoiceChip(
                  label: Text('$d days'),
                  selected: sel,
                  onSelected: (_) => setState(() => _listingDays = d),
                  selectedColor: AppColors.saffron.withValues(alpha: 0.35),
                  labelStyle: TextStyle(
                    color: sel ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: sel ? AppColors.saffron : AppColors.surfaceLight,
                  ),
                  backgroundColor: AppColors.surfaceCard,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            _lbl('Salary (Optional)'),
            AppTextField(
              hint: 'e.g. ₹15,000/month or 3-6 LPA',
              controller: _salaryCtrl,
              prefixIcon: const Icon(Icons.currency_rupee_rounded, color: AppColors.textHint),
            ),
            const SizedBox(height: 16),

            _lbl('Skills Required'),
            Row(children: [
              Expanded(
                child: AppTextField(hint: 'Add required skill', controller: _skillInput),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final v = _skillInput.text.trim();
                  if (v.isNotEmpty) {
                    setState(() { _skills.add(v); _skillInput.clear(); });
                  }
                },
                child: Container(
                  width: 44, height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ]),
            if (_skills.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: _skills
                    .map((s) => Chip(
                          label: Text(s),
                          onDeleted: () => setState(() => _skills.remove(s)),
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          labelStyle: const TextStyle(
                              color: AppColors.primaryLight, fontSize: 12),
                          deleteIconColor: AppColors.primaryLight,
                          side: BorderSide.none,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 32),
            GradientButton(
              text: 'Post Job',
              onPressed: _post,
              isLoading: _isLoading,
              icon: Icons.rocket_launch_rounded,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(
        color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
  );
}

class _JobTypeSelector extends StatelessWidget {
  final String selected;
  final List<String> types;
  final String Function(String) labelFn;
  final ValueChanged<String> onSelected;

  const _JobTypeSelector({
    required this.selected,
    required this.types,
    required this.labelFn,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: types.map((t) {
        final isSel = t == selected;
        return GestureDetector(
          onTap: () => onSelected(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSel ? AppColors.primaryGradient : null,
              color: isSel ? null : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isSel ? Colors.transparent : AppColors.surfaceLight),
            ),
            child: Text(labelFn(t),
                style: TextStyle(
                    color: isSel ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: isSel ? FontWeight.w600 : FontWeight.w400)),
          ),
        );
      }).toList(),
    );
  }
}
