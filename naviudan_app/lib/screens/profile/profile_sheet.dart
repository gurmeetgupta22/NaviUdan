import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../auth/login_screen.dart';

Future<void> showProfileSheet(BuildContext context) async {
  final up = context.read<UserProvider>();
  await up.loadUserProfile();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _ProfileSheetBody(),
  );
}

class _ProfileSheetBody extends StatelessWidget {
  const _ProfileSheetBody();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final h = MediaQuery.sizeOf(context).height * 0.78;

    return SizedBox(
      height: h,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                const Text(
                  'Your profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () async {
                    await context.read<UserProvider>().loadUserProfile();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                8 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                if (user == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No profile loaded. Complete the survey after sign-in.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  _ProfileDetails(user: user),
                const Divider(height: 32, color: AppColors.surfaceLight),
                ListTile(
                  leading:
                      const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text(
                    'Log out',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await context.read<UserProvider>().signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  final UserModel user;
  const _ProfileDetails({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.saffron.withValues(alpha: 0.3),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                user.name.isNotEmpty ? user.name : '—',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Contact'),
        _detailRow('Email', (user.email ?? '').isNotEmpty ? user.email! : '—'),
        _detailRow('Phone', user.phone.isNotEmpty ? user.phone : '—'),
        const SizedBox(height: 16),
        const _SectionLabel('Address'),
        _detailRow(
          'State / UT',
          (user.state ?? '').isNotEmpty ? user.state! : '—',
        ),
        _detailRow(
          'District',
          (user.district ?? '').isNotEmpty ? user.district! : '—',
        ),
        if (user.organization != null && user.organization!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SectionLabel('Organisation'),
          _detailRow('Company', user.organization!),
        ],
        const SizedBox(height: 16),
        const _SectionLabel('Account'),
        _detailRow('Role', user.role.isNotEmpty ? user.role : '—'),
        _detailRow(
          'Preferred language',
          user.preferredLanguage.isNotEmpty ? user.preferredLanguage : '—',
        ),
        const SizedBox(height: 16),
        const _SectionLabel('Skills (from survey)'),
        const SizedBox(height: 8),
        if (user.skills.isEmpty)
          const Text('—',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.skills
                .map((s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      backgroundColor: AppColors.surfaceLight,
                      side: BorderSide.none,
                    ))
                .toList(),
          ),
        const SizedBox(height: 16),
        const _SectionLabel('Fields of interest'),
        const SizedBox(height: 8),
        if (user.interests.isEmpty)
          const Text('—',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.interests
                .map((s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      backgroundColor:
                          AppColors.secondaryGreen.withValues(alpha: 0.2),
                      side: BorderSide.none,
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.saffron,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }
}
