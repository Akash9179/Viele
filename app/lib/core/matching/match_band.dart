/// Maps a 0–100 attribute-similarity score (the `feed()` Gower `match_pct`) to a
/// user-facing band — or `null` when the score is too low or too uncertain to
/// show at all.
///
/// Per `docs/matching-algorithm.md` (grounded in the dating-app trust research):
/// only ever show the match as a POSITIVE signal — badge strong matches, and
/// HIDE low/uncertain scores rather than displaying a discouraging raw number
/// (a guest / profile-less viewer scores 0 → no badge). The look still appears
/// in the ranked feed when hidden; it just carries no badge.
///
/// Thresholds are a tunable prior; Phase 1+ will calibrate them to real
/// save-rate so each band label stays honest.
library;

enum MatchBand {
  great('Great match'),
  strong('Strong match');

  const MatchBand(this.label);

  /// Short user-facing label shown in the match badge.
  final String label;
}

/// Score at/above which a look earns the top "Great match" badge.
const int kGreatMatchFloor = 80;

/// Score at/above which a look earns a "Strong match" badge. Below this, no
/// badge is shown at all.
const int kStrongMatchFloor = 60;

/// The band for [pct], or `null` if it falls below [kStrongMatchFloor] (hidden).
MatchBand? matchBandFor(int pct) {
  if (pct >= kGreatMatchFloor) return MatchBand.great;
  if (pct >= kStrongMatchFloor) return MatchBand.strong;
  return null;
}
