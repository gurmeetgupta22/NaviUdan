import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/job_model.dart';
import '../../providers/job_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common_widgets.dart';

class JobApplicationFormScreen extends StatefulWidget {
  final JobModel job;

  const JobApplicationFormScreen({super.key, required this.job});

  @override
  State<JobApplicationFormScreen> createState() =>
      _JobApplicationFormScreenState();
}

class _JobApplicationFormScreenState extends State<JobApplicationFormScreen> {
  final TextEditingController _applicationCtrl = TextEditingController();
  final List<TextEditingController> _attachmentCtrls = [];
  bool _isSubmitting = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    final name = context.read<UserProvider>().user?.name ?? 'Candidate';
    _applicationCtrl.text =
        'Dear Hiring Team,\n\nI am excited to apply for the ${widget.job.title} role. '
        'I believe my experience and skills align with your requirements and I would love to contribute.\n\n'
        'Thank you for your consideration.\n\nRegards,\n$name';
    _addAttachmentField();
  }

  @override
  void dispose() {
    _applicationCtrl.dispose();
    for (final c in _attachmentCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addAttachmentField() {
    _attachmentCtrls.add(TextEditingController());
  }

  Future<void> _generateAiDraft() async {
    final uid = context.read<UserProvider>().uid;
    final jobId = widget.job.id;
    if (uid == null || jobId == null) return;
    setState(() => _isGenerating = true);
    final text =
        await context.read<JobProvider>().generateAiApplicationDraft(jobId, uid);
    if (mounted) {
      if (text != null && text.trim().isNotEmpty) {
        _applicationCtrl.text = text.trim();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate AI draft right now.')),
        );
      }
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _submit() async {
    final uid = context.read<UserProvider>().uid;
    final jobId = widget.job.id;
    if (uid == null || jobId == null) return;
    final text = _applicationCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application text cannot be empty.')),
      );
      return;
    }
    final attachments = _attachmentCtrls
        .map((e) => e.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    setState(() => _isSubmitting = true);
    final ok = await context.read<JobProvider>().submitJobApplication(
          jobId: jobId,
          uid: uid,
          applicationText: text,
          attachments: attachments,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Application submitted successfully.'
            : 'Could not submit application (maybe already applied).'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
    if (ok) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Job Application'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.job.title,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            widget.job.location,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Application Letter',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: _isGenerating ? null : _generateAiDraft,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('AI application'),
              )
            ],
          ),
          AppTextField(
            hint: 'Write your application...',
            controller: _applicationCtrl,
            maxLines: 10,
          ),
          const SizedBox(height: 18),
          const Text(
            'Attachments (resume/CV links or file paths)',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._attachmentCtrls.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppTextField(
                hint: 'https://... or C:\\resume.pdf',
                controller: c,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(_addAttachmentField),
              icon: const Icon(Icons.attach_file_rounded),
              label: const Text('Add attachment'),
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(
            text: 'Submit Application',
            onPressed: _submit,
            isLoading: _isSubmitting,
            icon: Icons.send_rounded,
          ),
        ],
      ),
    );
  }
}
