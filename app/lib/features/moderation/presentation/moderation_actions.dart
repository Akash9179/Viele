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

/// Submit a moderation report. Returns true on success. A report must target a
/// post ([postId]) or a user ([reportedUserId]); the DB enforces this too.
Future<bool> _submitReport({
  String? postId,
  String? reportedUserId,
  required String reason,
}) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null || (postId == null && reportedUserId == null)) return false;
  try {
    await Supabase.instance.client.from('moderation_reports').insert({
      'post_id': ?postId,
      'reported_user_id': ?reportedUserId,
      'reporter_id': uid,
      'reason': reason,
    });
    return true;
  } catch (_) {
    return false;
  }
}

/// Report a post or a person. [subject] is shown in the title. Provide [postId]
/// for a post report or [reportedUserId] for a user report — the report is
/// persisted to `moderation_reports` (awaited) and feeds auto-takedown + the
/// founder review queue. The confirmation only shows once the write succeeds.
void showReportSheet(BuildContext context,
    {required String subject, String? postId, String? reportedUserId}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.canvas,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      bool submitting = false;
      bool done = false;
      bool failed = false;
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

          Future<void> pick(String code) async {
            setSheet(() {
              submitting = true;
              failed = false;
            });
            final ok = await _submitReport(
                postId: postId, reportedUserId: reportedUserId, reason: code);
            if (!ctx.mounted) return;
            setSheet(() {
              submitting = false;
              done = ok;
              failed = !ok;
            });
          }

          // Step 2 — confirmation.
          if (done) {
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
                      'Our team reviews reports and takes action on anything that breaks the Community Guidelines. Your report is anonymous.',
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
                      if (failed) ...[
                        const SizedBox(height: 8),
                        Text("Couldn't submit your report. Please try again.",
                            style: t.bodyMedium?.copyWith(color: _danger)),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                if (submitting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  for (final (icon, label, code) in _reportReasons)
                    InkWell(
                      onTap: () => pick(code),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                        child: Row(
                          children: [
                            Icon(icon, size: 20, color: AppColors.ink2),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Text(label,
                                    style: t.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w500))),
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
