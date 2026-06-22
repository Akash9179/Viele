import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viele/core/data/guest_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('round-trips guest sets', () async {
    final store = GuestStore();
    await store.setLiked({'a', 'b'});
    final s = await store.load();
    expect(s.liked, {'a', 'b'});
    expect(s.saved, isEmpty);
    await store.clear();
    expect((await store.load()).liked, isEmpty);
  });
}
