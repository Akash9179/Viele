import 'package:flutter_test/flutter_test.dart';
import 'package:viele/core/matching/match_band.dart';

void main() {
  group('matchBandFor', () {
    test('great match at/above the great floor', () {
      expect(matchBandFor(100), MatchBand.great);
      expect(matchBandFor(kGreatMatchFloor), MatchBand.great);
    });

    test('strong match between the strong and great floors', () {
      expect(matchBandFor(kGreatMatchFloor - 1), MatchBand.strong);
      expect(matchBandFor(75), MatchBand.strong); // seed: Anya
      expect(matchBandFor(68), MatchBand.strong); // seed: Mara
      expect(matchBandFor(kStrongMatchFloor), MatchBand.strong);
    });

    test('hidden (null) below the strong floor — never a discouraging number', () {
      expect(matchBandFor(kStrongMatchFloor - 1), isNull);
      expect(matchBandFor(41), isNull); // seed: Ella
      expect(matchBandFor(30), isNull); // seed: Sofia
      expect(matchBandFor(0), isNull); // guest / profile-less viewer
    });

    test('labels read as positive signals', () {
      expect(MatchBand.great.label, 'Great match');
      expect(MatchBand.strong.label, 'Strong match');
    });
  });
}
