import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stashly/services/notification_service.dart';

void main() {
  group('computeInitialDelay', () {
    test('target più avanti questa settimana', () {
      // Mercoledì 12/08/2026, target venerdì 18:00.
      final now = DateTime(2026, 8, 12, 10, 0);
      final delay = computeInitialDelay(
        now: now,
        targetWeekday: DateTime.friday,
        targetTime: const TimeOfDay(hour: 18, minute: 0),
      );
      expect(now.add(delay), DateTime(2026, 8, 14, 18, 0));
    });

    test('target già passato questa settimana, rolla alla prossima', () {
      // Mercoledì 12/08/2026, target lunedì 18:00 (già passato).
      final now = DateTime(2026, 8, 12, 10, 0);
      final delay = computeInitialDelay(
        now: now,
        targetWeekday: DateTime.monday,
        targetTime: const TimeOfDay(hour: 18, minute: 0),
      );
      expect(now.add(delay), DateTime(2026, 8, 17, 18, 0));
    });

    test('target oggi ma ora già passata, rolla alla settimana dopo', () {
      // Mercoledì 12/08/2026 alle 20:00, target mercoledì 18:00.
      final now = DateTime(2026, 8, 12, 20, 0);
      final delay = computeInitialDelay(
        now: now,
        targetWeekday: DateTime.wednesday,
        targetTime: const TimeOfDay(hour: 18, minute: 0),
      );
      expect(now.add(delay), DateTime(2026, 8, 19, 18, 0));
    });

    test('target oggi con ora futura', () {
      // Mercoledì 12/08/2026 alle 10:00, target mercoledì 18:00.
      final now = DateTime(2026, 8, 12, 10, 0);
      final delay = computeInitialDelay(
        now: now,
        targetWeekday: DateTime.wednesday,
        targetTime: const TimeOfDay(hour: 18, minute: 0),
      );
      expect(now.add(delay), DateTime(2026, 8, 12, 18, 0));
    });

    test('uguaglianza esatta: rolla di una settimana intera, non zero', () {
      final now = DateTime(2026, 8, 12, 18, 0);
      final delay = computeInitialDelay(
        now: now,
        targetWeekday: DateTime.wednesday,
        targetTime: const TimeOfDay(hour: 18, minute: 0),
      );
      expect(delay, const Duration(days: 7));
    });
  });
}
