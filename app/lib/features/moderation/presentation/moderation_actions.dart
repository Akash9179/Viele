import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/state/interactions.dart';
import '../../../core/theme/tokens.dart';

/// User-facing moderation actions — report + block. Reusable from a post
/// (outfit detail) and a user profile. A post report inserts a
/// `moderation_reports` row; a block inserts a `blocks` row (via
/// interactionsProvider). See `docs/moderation.md` (FR-CR.9 reasons, FR-SG.8).
const _danger = Color(0xFFD64545);

/// Report reasons — (icon, label, db reason code) from `docs/moderation.md` §3.
const _reportReasons = <(IconData, String, String)>[
  (Icons.no_adult_content_rounded, 'Nudity or sexual content', 'sexual'),
  (Icons.sentiment_very_dissatisfied_rounded, 'Harassment or bullying', 'harassment'),
  (Icons.warning_amber_rounded, 'Violence or threats', 'violence'),
  (Icons.gavel_rounded, 'Illegal or dangerous', 'illegal'),
  (Icons.report_gmailerrorred_rounded, 'Spam or scam', 'spam'),
  (Icons.copyright_rounded, 'Intellectual property', 'ip'),
  (Icons.more_horiz_rounded, 'Something else', 'other'),
];

/// Report a post or a person. [subject] is shown in the title. When [postId] is
/// given (a post report), a `moderation_reports` row is created for the founders
/// to review. (User-level reports have no post row in the schema yet — they show
/// the confirmation but aren't persisted.)
void showReportSheet(BuildContext context,
    {required String subject, String? postId}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.canvas,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      String? chosen;
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          Widget handle() => Center(
                child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(top: 8, bottom: 14),
                    decoration: BoxDecoration(
                        color: AppColors.ink3,
                        borderRadius: BorderRadius.circular(3))),
              );

          // Step 2 — confirmation.
          if (chosen != null) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    handle(),
                    const SizedBox(height: 4),
                    const Icon(Icons.check_circle_rounded,
                        size: 34, color: AppColors.match),
                    const SizedBox(height: 12),
                    Text('Thanks for letting us know',
                        style: t.headlineSmall?.copyWith(fontSize: 21)),
                    const SizedBox(height: 8),
                    Text(
                      'Our team reviews reports within 24 hours and takes action on anything that breaks the Community Guidelines. Your report is anonymous.',
                      style: t.bodyLarge
                          ?.copyWith(color: AppColors.ink2, height: 1.45),
                    ),
                    const SizedBox(height: 20),
                    _FilledButton(
                        label: 'Done', onTap: () => Navigator.of(ctx).pop()),
                  ],
                ),
              ),
            );
          }

          // Step 1 — reason picker.
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                handle(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Report $subject',
                          style: t.headlineSmall?.copyWith(fontSize: 21)),
                      const SizedBox(height: 6),
                      Text("Why are you reporting this? We won't tell them.",
                          style: t.bodyMedium),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                for (final (icon, label, code) in _reportReasons)
                  InkWell(
                    onTap: () {
                      setSheet(() => chosen = label);
                      final uid = Supabase.instance.client.auth.currentUser?.id;
                      if (postId != null && uid != null) {
                        // Fire-and-forget: create the report for founder review.
                        Supabase.instance.client.from('moderation_reports').insert({
                          'post_id': postId,
                          'reporter_id': uid,
                          'reason': code,
                        }).ignore();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 14),
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: AppColors.ink2),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Text(label,
                                  style: t.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w500))),
                          const Icon(Icons.chevron_right_rounded,
                              size: 20, color: AppColors.ink3),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Confirm + apply a block. Hides the user's content immediately (no review).
/// [onBlocked] runs after the block is applied (e.g. pop the blocked author's
/// post/profile).
void confirmBlock(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required String name,
  VoidCallback? onBlocked,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.canvas,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: AppColors.ink3,
                        borderRadius: BorderRadius.circular(3))),
              ),
              const SizedBox(height: 18),
              const Icon(Icons.block_rounded, size: 30, color: _danger),
              const SizedBox(height: 12),
              Text('Block $name?',
                  style: t.headlineSmall?.copyWith(fontSize: 21)),
              const SizedBox(height: 8),
              Text(
                "They won't be able to find your profile or posts, and you won't see "
                "theirs. They won't be notified. You can unblock anytime in Settings.",
                style: t.bodyLarge?.copyWith(color: AppColors.ink2, height: 1.45),
              ),
              const SizedBox(height: 20),
              _FilledButton(
                label: 'Block $name',
                color: _danger,
                onTap: () {
                  ref.read(interactionsProvider.notifier).block(userId);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.ink,
                    content: Text('Blocked $name'),
                  ));
                  onBlocked?.call();
                },
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Cancel',
                      style: t.labelLarge?.copyWith(
                          color: AppColors.ink2, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _FilledButton extends StatelessWidget {
  const _FilledButton(
      {required this.label, required this.onTap, this.color = AppColors.ink});
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        alignment: Alignment.center,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
        child: Text(label,
            style: t.labelLarge?.copyWith(
                color: AppColors.onInk, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
