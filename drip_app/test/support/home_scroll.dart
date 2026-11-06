import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scrolls Home down until [target] is built and on screen. Home builds its
/// sections lazily, so the tools, the occasions and the board below today's
/// pick only exist once scrolled to.
Future<void> scrollHomeTo(WidgetTester t, Finder target) async {
  final home = find.byType(CustomScrollView).first;
  for (var i = 0; i < 14 && target.evaluate().isEmpty; i++) {
    await t.drag(home, const Offset(0, -300));
    await t.pump(const Duration(milliseconds: 250));
  }
  await t.ensureVisible(target.first);
  await t.pump(const Duration(milliseconds: 300));
}
