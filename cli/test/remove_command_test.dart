import 'package:dojjo/src/commands/remove_command.dart';
import 'package:test/test.dart';

void main() {
  group('shouldReturnToDefault', () {
    test('returns to default when removing the current (non-default) workspace', () {
      expect(
        shouldReturnToDefault(removingCurrent: true, removedRoot: '/repo/feature', defaultRoot: '/repo/default'),
        isTrue,
      );
    });

    test('does not cd when not removing the current workspace', () {
      expect(
        shouldReturnToDefault(removingCurrent: false, removedRoot: '/repo/feature', defaultRoot: '/repo/default'),
        isFalse,
      );
    });

    test('does not cd into the just-deleted directory when removing the default itself', () {
      expect(
        shouldReturnToDefault(removingCurrent: true, removedRoot: '/repo/default', defaultRoot: '/repo/default'),
        isFalse,
      );
    });

    test('compares paths normalized', () {
      expect(
        shouldReturnToDefault(removingCurrent: true, removedRoot: '/repo/default/', defaultRoot: '/repo/./default'),
        isFalse,
      );
    });
  });
}
