import 'dart:ui' as ui;

import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// What the phone decided about one picked photo, before anything uploads.
enum PhotoVerdict {
  pending,
  ok,

  /// Two or more people. Groups arrive in the next update.
  group,

  /// Nobody in it (a screenshot, a flat-lay, a view).
  noPerson,

  /// Too dark to cut clothes out cleanly.
  dark,

  /// Near-identical to a photo already kept (a burst, a re-take).
  duplicate,

  /// The phone couldn't open it.
  unreadable;

  bool get kept => this == ok;

  /// Short reason for the badge and the summary line.
  String get reason => switch (this) {
    PhotoVerdict.group => 'Group photo',
    PhotoVerdict.noPerson => 'No one in it',
    PhotoVerdict.dark => 'Too dark',
    PhotoVerdict.duplicate => 'Same as another',
    PhotoVerdict.unreadable => "Couldn't open",
    _ => '',
  };
}

/// What the phone measured in a photo (cheap, on-device, nothing uploaded).
class PhotoSignals {
  const PhotoSignals({
    required this.faces,
    required this.person,
    required this.brightness,
    required this.hash,
    this.takenAt,
  });

  /// Faces big enough to be a subject, not a passer-by.
  final int faces;

  /// A body was found (shoulders and hips), face or not: mirror selfies
  /// often hide the face behind the phone.
  final bool person;

  /// Mean luminance, 0–1.
  final double brightness;

  /// 64-bit difference hash: near-identical photos differ in a few bits.
  final int hash;
  final DateTime? takenAt;
}

/// Below this mean luminance a photo is too dark to cut out well.
const darkBelow = 0.14;

/// Photos whose hashes differ in at most this many bits are the same shot.
const sameShotBits = 6;

/// The verdict for one photo, given the signals of photos already kept.
PhotoVerdict judge(PhotoSignals s, Iterable<PhotoSignals> kept) {
  if (s.faces >= 2) return PhotoVerdict.group;
  if (!s.person && s.faces == 0) return PhotoVerdict.noPerson;
  if (s.brightness < darkBelow) return PhotoVerdict.dark;
  for (final k in kept) {
    if (hamming(s.hash, k.hash) <= sameShotBits) return PhotoVerdict.duplicate;
  }
  return PhotoVerdict.ok;
}

int hamming(int a, int b) {
  var x = a ^ b;
  var n = 0;
  while (x != 0) {
    x &= x - 1;
    n++;
  }
  return n;
}

/// EXIF `2024:05:01 18:22:10` → a local [DateTime]. Null if unparseable or
/// a camera default far in the past.
DateTime? parseExifDate(String? raw) {
  if (raw == null) return null;
  final m = RegExp(r'^(\d{4}):(\d{2}):(\d{2})[ T](\d{2}):(\d{2}):(\d{2})')
      .firstMatch(raw.trim());
  if (m == null) return null;
  final parts = [for (var i = 1; i <= 6; i++) int.parse(m.group(i)!)];
  if (parts[0] < 2000 || parts[1] < 1 || parts[1] > 12) return null;
  final date = DateTime(
    parts[0],
    parts[1],
    parts[2],
    parts[3],
    parts[4],
    parts[5],
  );
  return date.isAfter(DateTime.now().add(const Duration(days: 1)))
      ? null
      : date;
}

/// Difference hash and mean brightness from a 9×8 grey thumbnail of the
/// photo (decoded natively, so it's quick even for big photos).
Future<(int, double)> fingerprint(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: 9,
    targetHeight: 8,
  );
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  frame.image.dispose();
  codec.dispose();
  if (data == null) throw StateError('no pixels');
  final grey = List<double>.generate(72, (i) {
    final r = data.getUint8(i * 4);
    final g = data.getUint8(i * 4 + 1);
    final b = data.getUint8(i * 4 + 2);
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255;
  });
  var hash = 0;
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      hash = (hash << 1) | (grey[y * 9 + x] > grey[y * 9 + x + 1] ? 1 : 0);
    }
  }
  final mean = grey.reduce((a, b) => a + b) / grey.length;
  return (hash, mean);
}

/// Runs the on-device checks. ML Kit models load once and are reused for
/// every photo in a batch; call [close] when done. If a model can't run on
/// this phone the check passes (the server checks again).
class PhotoChecker {
  PhotoChecker();

  FaceDetector? _faces;
  PoseDetector? _pose;

  static bool get _mlKit =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<PhotoSignals> inspect(String path, Uint8List bytes) async {
    final (hash, brightness) = await fingerprint(bytes);
    DateTime? takenAt;
    try {
      final exif = await readExifFromBytes(bytes, details: false);
      takenAt =
          parseExifDate(exif['EXIF DateTimeOriginal']?.printable) ??
          parseExifDate(exif['Image DateTime']?.printable);
    } catch (_) {}

    var faces = 0;
    var person = true;
    if (_mlKit) {
      try {
        final input = InputImage.fromFilePath(path);
        _faces ??= FaceDetector(
          // A subject's face, not someone in the background.
          options: FaceDetectorOptions(minFaceSize: 0.08),
        );
        faces = (await _faces!.processImage(input)).length;
        if (faces == 0) {
          _pose ??= PoseDetector(
            options: PoseDetectorOptions(mode: PoseDetectionMode.single),
          );
          final poses = await _pose!.processImage(input);
          person = poses.any(_hasBody);
        }
      } catch (e) {
        debugPrint('On-device photo check skipped: $e');
        person = true;
      }
    }
    return PhotoSignals(
      faces: faces,
      person: person,
      brightness: brightness,
      hash: hash,
      takenAt: takenAt,
    );
  }

  static bool _hasBody(Pose pose) {
    const core = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    ];
    var seen = 0.0;
    for (final t in core) {
      seen += pose.landmarks[t]?.likelihood ?? 0;
    }
    return seen / core.length > 0.5;
  }

  Future<void> close() async {
    await _faces?.close();
    await _pose?.close();
    _faces = null;
    _pose = null;
  }
}

/// The bytes to upload and their type. JPEG, PNG and WebP go as they are;
/// anything else the phone can decode (HEIC from some cameras) is re-encoded
/// as PNG, at most [maxEdge] px.
Future<(Uint8List, String)> uploadable(
  Uint8List bytes,
  String? contentType, {
  int maxEdge = 1600,
}) async {
  if (contentType != null &&
      const {'image/jpeg', 'image/png', 'image/webp'}.contains(contentType)) {
    return (bytes, contentType);
  }
  final probe = await ui.ImmutableBuffer.fromUint8List(bytes);
  final descriptor = await ui.ImageDescriptor.encoded(probe);
  final w = descriptor.width, h = descriptor.height;
  final scale = w > h ? maxEdge / w : maxEdge / h;
  final codec = await descriptor.instantiateCodec(
    targetWidth: scale < 1 ? (w * scale).round() : w,
    targetHeight: scale < 1 ? (h * scale).round() : h,
  );
  final frame = await codec.getNextFrame();
  final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
  frame.image.dispose();
  codec.dispose();
  descriptor.dispose();
  probe.dispose();
  if (png == null) throw StateError('could not re-encode');
  return (png.buffer.asUint8List(), 'image/png');
}
