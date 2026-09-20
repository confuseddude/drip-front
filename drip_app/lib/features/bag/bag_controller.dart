import 'package:flutter_riverpod/flutter_riverpod.dart';

class BagLine {
  const BagLine({
    required this.name,
    required this.subtitle,
    required this.price,
  });
  final String name;
  final String subtitle;
  final int price;
}

/// Shopping bag. Purely client-side until the store backend exists.
class BagController extends Notifier<List<BagLine>> {
  @override
  List<BagLine> build() => const [];

  bool contains(String name) => state.any((l) => l.name == name);

  /// Adds [lines], skipping ones already in the bag. Returns how many were added.
  int addAll(Iterable<BagLine> lines) {
    final fresh = [
      for (final l in lines)
        if (!contains(l.name)) l,
    ];
    if (fresh.isNotEmpty) state = [...state, ...fresh];
    return fresh.length;
  }

  void remove(String name) => state = [
    for (final l in state)
      if (l.name != name) l,
  ];

  void clear() => state = const [];

  int get total => state.fold(0, (s, l) => s + l.price);
}

final bagProvider = NotifierProvider<BagController, List<BagLine>>(
  BagController.new,
);
