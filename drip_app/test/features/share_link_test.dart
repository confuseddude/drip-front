import 'package:drip/data/models/outfit.dart';
import 'package:drip/features/share/share_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('share ids (the backend\'s /f/<id62>)', () {
    test('a uuid is its 128-bit number in base 62, 22 characters', () {
      expect(
        shareId('0f8fad5b-d9cb-469f-a165-70867728950e'),
        '0TMXp8QPR6yGvKuV2GZQ10',
      );
      expect(
        shareId('00000000-0000-0000-0000-000000000001'),
        '0000000000000000000001',
      );
      expect(
        shareId('ffffffff-ffff-ffff-ffff-ffffffffffff'),
        '7n42DGM5Tflk9n8mt7Fhc7',
      );
    });

    test('round-trips, and rejects what is not one', () {
      const id = '0f8fad5b-d9cb-469f-a165-70867728950e';
      expect(uuidFromShareId(shareId(id)), id);
      expect(uuidFromShareId('short'), isNull);
      expect(uuidFromShareId('zzzzzzzzzzzzzzzzzzzzzz'), isNull);
    });

    test('a non-uuid id passes through', () {
      expect(shareId('o_gray'), 'o_gray');
    });
  });

  test('the link and its message', () {
    final fit = Outfit.fromJson({
      'id': '0f8fad5b-d9cb-469f-a165-70867728950e',
      'title': 'Floral night layers',
      'image': 'https://x/y.webp',
      'price': 66847,
      'pieces': [
        {'slot': 'top', 'name': 'Hoodie', 'brand': 'X', 'price': 1},
        {'slot': 'bottom', 'name': 'Trousers', 'brand': 'X', 'price': 1},
      ],
    });
    final url = fitShareUrl(fit, base: 'https://drip.example/');
    expect(url, 'https://drip.example/f/0TMXp8QPR6yGvKuV2GZQ10');
    final text = fitShareText(fit, url: url);
    expect(text, startsWith('${fit.title} on Drip: 2 pieces'));
    expect(text, endsWith('\n$url'));
  });
}
