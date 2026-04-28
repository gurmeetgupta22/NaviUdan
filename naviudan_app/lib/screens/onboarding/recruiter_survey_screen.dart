import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/india_regions.dart';
import '../../services/account_context.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import '../recruiter/recruiter_home_screen.dart';

class RecruiterSurveyScreen extends StatefulWidget {
  const RecruiterSurveyScreen({super.key});

  @override
  State<RecruiterSurveyScreen> createState() => _RecruiterSurveyScreenState();
}

class _RecruiterSurveyScreenState extends State<RecruiterSurveyScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _skillInput = TextEditingController();

  String _language = 'English';
  String _state = 'Maharashtra';
  final List<String> _requiredSkills = [];
  bool _isLoading = false;

  static const List<String> _languages = [
    'English', 'Hindi', 'Marathi', 'Tamil', 'Telugu', 'Bengali', 'Gujarati',
  ];
  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')));
      return;
    }
    final uid = loggedInUid;
    if (uid == null) return;
    setState(() => _isLoading = true);

    final data = {
      'uid': uid,
      'name': _nameCtrl.text.trim(),
      'phone': loggedInPhone ?? '',
      'email': _emailCtrl.text.trim(),
      'preferred_language': _language,
      'role': 'recruiter',
      'state': _state,
      'district': _districtCtrl.text.trim(),
      'organization': _orgCtrl.text.trim(),
      'required_skills': _requiredSkills,
    };

    try {
      await ApiService.createProfile(data);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RecruiterHomeScreen()),
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
      appBar: AppBar(
        title: const Text('Recruiter Profile'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tell us about you 🏢',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 24),
              _lbl('Preferred Language'),
              _Drop(value: _language, items: _languages,
                  onChanged: (v) => setState(() => _language = v!)),
              const SizedBox(height: 14),
              _lbl('Full Name'),
              AppTextField(hint: 'Your name', controller: _nameCtrl,
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.textHint)),
              const SizedBox(height: 14),
              _lbl('Email (Optional)'),
              AppTextField(hint: 'Email address', controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.mail_outline, color: AppColors.textHint)),
              const SizedBox(height: 14),
              _lbl('State / UT'),
              _Drop(value: _state, items: kIndiaStatesAndUTs,
                  onChanged: (v) => setState(() => _state = v!)),
              const SizedBox(height: 14),
              _lbl('District'),
              AppTextField(hint: 'Your district', controller: _districtCtrl,
                  prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textHint)),
              const SizedBox(height: 14),
              _lbl('Organisation / Company'),
              AppTextField(hint: 'Company or organisation name', controller: _orgCtrl,
                  prefixIcon: const Icon(Icons.business_outlined, color: AppColors.textHint)),
              const SizedBox(height: 14),
              _lbl('Skills You Look For'),
              Row(children: [
                Expanded(child: AppTextField(hint: 'Add required skill', controller: _skillInput)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final v = _skillInput.text.trim();
                    if (v.isNotEmpty) {
                      setState(() { _requiredSkills.add(v); _skillInput.clear(); });
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
              if (_requiredSkills.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 6,
                  children: _requiredSkills.map((s) => Chip(
                    label: Text(s),
                    onDeleted: () => setState(() => _requiredSkills.remove(s)),
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    labelStyle: const TextStyle(color: AppColors.primaryLight, fontSize: 12),
                    deleteIconColor: AppColors.primaryLight,
                    side: BorderSide.none,
                  )).toList(),
                ),
              ],
              const SizedBox(height: 32),
              GradientButton(
                text: 'Complete Setup 🎉',
                onPressed: _submit,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lbl(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(
        color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
  );
}

class _Drop extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _Drop({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value, onChanged: onChanged,
      dropdownColor: AppColors.surfaceCard,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        filled: true, fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.surfaceLight)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
    );
  }
}
