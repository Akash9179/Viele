import 'package:flutter_test/flutter_test.dart';
import 'package:viele/core/data/search_repository.dart';

void main() {
  test('normalizeQuery trims and lowercases', () {
    expect(normalizeQuery('  Mara  '), 'mara');
    expect(normalizeQuery(''), '');
  });
}
