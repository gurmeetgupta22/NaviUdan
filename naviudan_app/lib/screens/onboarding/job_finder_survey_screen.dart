import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/india_regions.dart';
import '../../services/account_context.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import '../job_finder/home_screen.dart';

class JobFinderSurveyScreen extends StatefulWidget {
  const JobFinderSurveyScreen({super.key});

  @override
  State<JobFinderSurveyScreen> createState() => _JobFinderSurveyScreenState();
}

class _JobFinderSurveyScreenState extends State<JobFinderSurveyScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Form data
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();

  String _language = 'English';
  String _ageGroup = '20-30';
  String _state = 'Maharashtra';
  String _educationStatus = 'college';
  String _classOrStream = '';
  final List<String> _skills = [];
  final List<String> _interests = [];
  final _skillInput = TextEditingController();
  final _interestInput = TextEditingController();

  static const List<String> _languages = [
    'English', 'Hindi', 'Marathi', 'Tamil', 'Telugu',
    'Bengali', 'Gujarati', 'Kannada', 'Malayalam',
  ];

  static const List<String> _ageGroups = ['18-20', '20-30', '30+'];

  static const List<String> _educationStatuses = [
    'school',
    'college',
    'job',
    'other',
  ];

  static const List<String> _suggestedInterests = [
    'IT', 'Data Science', 'AI/ML', 'Web Development', 'Mobile Development',
    'Sales', 'Marketing', 'Finance', 'Healthcare', 'Teaching', 'Agriculture',
    'Design', 'Content Writing', 'Photography', 'Entrepreneurship',
  ];

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  static String _educationDetailLabel(String status) {
    switch (status) {
      case 'school':
        return 'Class & Subject';
      case 'college':
        return 'Stream / Course';
      case 'job':
        return 'Current Role / Skills';
      case 'other':
        return 'What you do for a living';
      default:
        return 'Details';
    }
  }

  static String _educationDetailHint(String status) {
    switch (status) {
      case 'school':
        return 'e.g. Class 12, Science';
      case 'college':
        return 'e.g. B.Tech Computer Science';
      case 'job':
        return 'e.g. Software Engineer, 2 years';
      case 'other':
        return 'e.g. Daily wage labour, homemaker, between jobs, street vendor…';
      default:
        return '';
    }
  }

  Future<void> _submit() async {
    final uid = loggedInUid;
    if (uid == null) return;
    setState(() => _isLoading = true);

    final profileData = {
      'uid': uid,
      'name': _nameCtrl.text.trim(),
      'phone': loggedInPhone ?? '',
      'email': _emailCtrl.text.trim(),
      'preferred_language': _language,
      'role': 'job_finder',
      'state': _state,
      'district': _districtCtrl.text.trim(),
      'age_group': _ageGroup,
      'education_status': _educationStatus,
      'class_or_stream': _classOrStream,
      'skills': _skills,
      'interests': _interests,
    };

    try {
      await ApiService.createProfile(profileData);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const JobFinderHomeScreen()),
        (_) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                ],
              ),
            ),
            _buildNavButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step ${_currentPage + 1} of 3',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              Text('${((_currentPage + 1) / 3 * 100).round()}%',
                  style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / 3,
              backgroundColor: AppColors.surfaceLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Basic Info 👤',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          _label('Full Name'),
          AppTextField(hint: 'Enter your full name', controller: _nameCtrl,
              prefixIcon: const Icon(Icons.person_outline, color: AppColors.textHint)),
          const SizedBox(height: 16),
          _label('Email (Optional)'),
          AppTextField(hint: 'Enter your email', controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.mail_outline, color: AppColors.textHint)),
          const SizedBox(height: 16),
          _label('Preferred Language'),
          _Dropdown(
            value: _language,
            items: _languages,
            onChanged: (v) => setState(() => _language = v!),
          ),
          const SizedBox(height: 16),
          _label('Age Group'),
          _ToggleGroup(
            items: _ageGroups,
            selected: _ageGroup,
            onSelected: (v) => setState(() => _ageGroup = v),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Location & Education 📍',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          _label('State / UT'),
          _Dropdown(
            value: _state,
            items: kIndiaStatesAndUTs,
            onChanged: (v) => setState(() => _state = v!),
          ),
          const SizedBox(height: 16),
          _label('District'),
          AppTextField(hint: 'Enter your district', controller: _districtCtrl,
              prefixIcon:
                  const Icon(Icons.location_on_outlined, color: AppColors.textHint)),
          const SizedBox(height: 16),
          _label('Education / Work Status'),
          _ToggleGroup(
            items: _educationStatuses,
            selected: _educationStatus,
            onSelected: (v) => setState(() => _educationStatus = v),
            capitalize: true,
            crossAxisCount: 2,
          ),
          const SizedBox(height: 16),
          _label(_educationDetailLabel(_educationStatus)),
          AppTextField(
            key: ValueKey<String>(_educationStatus),
            hint: _educationDetailHint(_educationStatus),
            onChanged: (v) => _classOrStream = v,
            prefixIcon: Icon(
              _educationStatus == 'other'
                  ? Icons.work_outline_rounded
                  : Icons.school_outlined,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Skills & Interests 🚀',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          _label('Your Skills'),
          _ChipInput(
            controller: _skillInput,
            chips: _skills,
            hint: 'Add a skill (e.g. Python)',
            onAdd: (v) => setState(() => _skills.add(v)),
            onRemove: (v) => setState(() => _skills.remove(v)),
          ),
          const SizedBox(height: 20),
          _label('Fields of Interest'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedInterests.map((interest) {
              final selected = _interests.contains(interest);
              return GestureDetector(
                onTap: () => setState(() {
                  selected
                      ? _interests.remove(interest)
                      : _interests.add(interest);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.primaryGradient : null,
                    color: selected ? null : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : AppColors.surfaceLight,
                    ),
                  ),
                  child: Text(interest,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _ChipInput(
            controller: _interestInput,
            chips: _interests
                .where((i) => !_suggestedInterests.contains(i))
                .toList(),
            hint: 'Add custom interest',
            onAdd: (v) => setState(() => _interests.add(v)),
            onRemove: (v) => setState(() => _interests.remove(v)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _prevPage,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: GradientButton(
              text: _currentPage == 2 ? 'Finish 🎉' : 'Next →',
              onPressed: _nextPage,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500)),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _Dropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown(
      {required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      dropdownColor: AppColors.surfaceCard,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.surfaceLight),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
          .toList(),
    );
  }
}

class _ToggleGroup extends StatelessWidget {
  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool capitalize;
  /// When set (e.g. 2), lays out options in a grid so four labels fit on small screens.
  final int? crossAxisCount;

  const _ToggleGroup({
    required this.items,
    required this.selected,
    required this.onSelected,
    this.capitalize = false,
    this.crossAxisCount,
  });

  String _labelFor(String item) {
    if (!capitalize) return item;
    if (item.isEmpty) return item;
    return '${item[0].toUpperCase()}${item.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    if (crossAxisCount == null || crossAxisCount! < 2) {
      return Row(
        children: items.map((item) {
          return Expanded(
            child: _toggleCell(item),
          );
        }).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final n = crossAxisCount!;
        final spacing = 8.0;
        final usable = constraints.maxWidth - spacing * (n - 1);
        final cellW = usable / n;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: cellW,
              child: _toggleCell(item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _toggleCell(String item) {
    final isSelected = selected == item;
    final label = _labelFor(item);
    return GestureDetector(
      onTap: () => onSelected(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: crossAxisCount == null
            ? const EdgeInsets.symmetric(horizontal: 3)
            : EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.surfaceLight,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _ChipInput extends StatelessWidget {
  final TextEditingController controller;
  final List<String> chips;
  final String hint;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  const _ChipInput({
    required this.controller,
    required this.chips,
    required this.hint,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                  hint: hint,
                  controller: controller),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                final v = controller.text.trim();
                if (v.isNotEmpty) {
                  onAdd(v);
                  controller.clear();
                }
              },
              child: Container(
                width: 44,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: chips
                .map((chip) => Chip(
                      label: Text(chip),
                      onDeleted: () => onRemove(chip),
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      labelStyle: const TextStyle(
                          color: AppColors.primaryLight, fontSize: 12),
                      deleteIconColor: AppColors.primaryLight,
                      side: BorderSide.none,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
