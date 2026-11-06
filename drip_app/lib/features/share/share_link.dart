import '../../core/config/env.dart';
import '../../core/utils/format.dart';
import '../../data/models/outfit.dart';

const _alphabet =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

/// A fit's uuid as the backend's short link id: the 128-bit number written in
/// base 62, left-padded to 22 characters. Anything that isn't a uuid (a mock
/// id) is passed through as it is; the backend accepts a raw id as well.
String shareId(String id) {
  final hex = id.replaceAll('-', '');
  if (!RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(hex)) return id;
  var n = BigInt.parse(hex, radix: 16);
  final b62 = BigInt.from(62);
  final out = StringBuffer();
  while (n > BigInt.zero) {
    out.write(_alphabet[(n % b62).toInt()]);
    n ~/= b62;
  }
  return out.toString().split('').reversed.join().padLeft(22, '0');
}

/// The reverse of [shareId], for links that open the app. Null when [code]
/// isn't one.
String? uuidFromShareId(String code) {
  if (!RegExp(r'^[0-9A-Za-z]{22}$').hasMatch(code)) return null;
  var n = BigInt.zero;
  final b62 = BigInt.from(62);
  for (final c in code.split('')) {
    n = n * b62 + BigInt.from(_alphabet.indexOf(c));
  }
  if (n.bitLength > 128) return null;
  final h = n.toRadixString(16).padLeft(32, '0');
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// The link to share for [outfit]: its page unfurls with the fit's picture
/// and the Drip logo in WhatsApp, Discord and the rest.
String fitShareUrl(Outfit outfit, {String base = Env.shareBaseUrl}) {
  final root = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  return '$root/f/${shareId(outfit.id)}';
}

/// The message that goes with the link: the fit, how much, and the link.
String fitShareText(Outfit outfit, {String? url}) {
  final n = outfit.pieces.length;
  final parts = [
    if (n > 0) '$n ${n == 1 ? 'piece' : 'pieces'}',
    if (outfit.price > 0) formatPrice(outfit.price),
  ];
  final what = parts.isEmpty ? '' : ': ${parts.join(', ')}';
  return '${outfit.title} on Drip$what\n${url ?? fitShareUrl(outfit)}';
}
