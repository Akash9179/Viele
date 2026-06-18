import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/data/onboarding_data.dart';

/// Snapshot of the anonymous teaser answers, captured when onboarding finishes
/// and held until the user creates an account (possibly much later). On signup
/// these migrate into the user's `profiles` / `profiles_private` row. If the
/// guest never signs up, it's simply discarded. See [[viele-onboarding-design]].
class OnboardingDraft {
  const OnboardingDraft({
    this.bodyType = BodyTypeSet.women,
    this.aesthetics = const [],
    this.silhouette,
    this.skinToneIndex,
    this.undertone,
    this.heightFeet = 5,
    this.heightInches = 6,
    this.weightLb = 150,
  });

  final BodyTypeSet bodyType;
  final List<String> aesthetics;
  final SilhouetteShape? silhouette;
  final int? skinToneIndex; // 0-9 Monk index
  final Undertone? undertone;
  final int heightFeet;
  final int heightInches;
  final int weightLb;

  // App enum -> DB enum text (must match the CHECK constraints in 0001).
  static const _silhouetteDb = {
    SilhouetteShape.hourglass: 'hourglass',
    SilhouetteShape.pear: 'pear',
    SilhouetteShape.rectangle: 'rectangle',
    SilhouetteShape.apple: 'apple',
    SilhouetteShape.invertedTriangle: 'inverted_triangle',
  };

  int get heightCm => ((heightFeet * 12 + heightInches) * 2.54).round();

  /// Private (owner-only), never publicly displayed.
  num get weightKg => (weightLb * 0.45359237 * 10).round() / 10;

  /// Public `profiles` columns derived from the teaser answers (no weight here).
  Map<String, dynamic> publicProfileFields() => {
        'body_type_set': bodyType.name, // women|men|both
        if (silhouette != null) 'body_silhouette': _silhouetteDb[silhouette],
        'height_cm': heightCm,
        if (skinToneIndex != null) 'skin_tone': skinToneIndex! + 1, // 1-10
        if (undertone != null) 'undertone': undertone!.name, // warm|cool|neutral
        'aesthetics': aesthetics,
      };
}

class OnboardingDraftNotifier extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() => const OnboardingDraft();

  void set(OnboardingDraft draft) => state = draft;
}

final onboardingDraftProvider =
    NotifierProvider<OnboardingDraftNotifier, OnboardingDraft>(
        OnboardingDraftNotifier.new);
