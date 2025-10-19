import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/src/ui/key_repeat_controller.dart';

void main() {
  test('fires synthetic repeats after delay', () {
    fakeAsync((async) {
      final controller = KeyRepeatController(
        initialDelay: const Duration(milliseconds: 10),
        repeatInterval: const Duration(milliseconds: 5),
      );

      var repeatCount = 0;

      controller.handleKeyDown(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.backspace,
          logicalKey: LogicalKeyboardKey.backspace,
          timeStamp: Duration.zero,
        ),
        onRepeat: () => repeatCount++,
      );

      async.elapse(const Duration(milliseconds: 10));
      expect(repeatCount, 0);

      async.elapse(const Duration(milliseconds: 5));
      expect(repeatCount, 1);

      async.elapse(const Duration(milliseconds: 15));
      expect(repeatCount, greaterThanOrEqualTo(3));

      controller.handleKeyUp(
        const KeyUpEvent(
          physicalKey: PhysicalKeyboardKey.backspace,
          logicalKey: LogicalKeyboardKey.backspace,
          timeStamp: Duration(milliseconds: 40),
        ),
      );

      final repeatsAfterRelease = repeatCount;
      async.elapse(const Duration(milliseconds: 20));
      expect(repeatCount, repeatsAfterRelease);

      controller.dispose();
    });
  });

  test('cancels synthetic repeat when native repeat arrives', () {
    fakeAsync((async) {
      final controller = KeyRepeatController(
        initialDelay: const Duration(milliseconds: 10),
        repeatInterval: const Duration(milliseconds: 5),
      );

      var repeatCount = 0;

      controller.handleKeyDown(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.backspace,
          logicalKey: LogicalKeyboardKey.backspace,
          timeStamp: Duration.zero,
        ),
        onRepeat: () => repeatCount++,
      );

      controller.handleKeyRepeat(
        const KeyRepeatEvent(
          physicalKey: PhysicalKeyboardKey.backspace,
          logicalKey: LogicalKeyboardKey.backspace,
          timeStamp: Duration(milliseconds: 5),
        ),
      );

      async.elapse(const Duration(milliseconds: 50));
      expect(repeatCount, 0);

      controller.dispose();
    });
  });

  test('treats second key down as native repeat', () {
    fakeAsync((async) {
      final controller = KeyRepeatController(
        initialDelay: const Duration(milliseconds: 10),
        repeatInterval: const Duration(milliseconds: 5),
      );

      var repeatCount = 0;

      controller.handleKeyDown(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.backspace,
          logicalKey: LogicalKeyboardKey.backspace,
          timeStamp: Duration.zero,
        ),
        onRepeat: () => repeatCount++,
      );

      controller.handleKeyDown(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.backspace,
          logicalKey: LogicalKeyboardKey.backspace,
          timeStamp: Duration(milliseconds: 5),
        ),
        onRepeat: () => repeatCount++,
      );

      async.elapse(const Duration(milliseconds: 40));
      expect(repeatCount, 0);

      controller.dispose();
    });
  });
}
