/// `12400` → `12.4K`, `4200` → `4.2K`, `950` → `950`, `2_400_000` → `2.4M`.
String formatCount(int n) {
  String trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  if (n >= 1000000) return '${trim(n / 1000000)}M';
  if (n >= 1000) return '${trim(n / 1000)}K';
  return '$n';
}

/// `12420` → `12,420`.
String formatThousands(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// `189` → `$189.00`.
String formatPrice(num v) => '\$${v.toStringAsFixed(2)}';

/// `189` → `$189`.
String formatPriceShort(num v) => '\$${v.round()}';
