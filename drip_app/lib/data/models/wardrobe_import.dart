/// Where a gallery import is on the server: still working through the
/// photos, done (the pieces are in the wardrobe), or stopped.
enum ImportStatus { processing, done, failed, cancelled }

/// A batch of the user's photos turned into wardrobe pieces
/// (`/wardrobe/imports` in docs/BACKEND_REQUESTS.md, 2026-10-21).
///
/// There's no review step: once every photo is cut out and the duplicates
/// are folded together, the pieces land in the wardrobe by themselves.
class WardrobeImport {
  const WardrobeImport({
    required this.id,
    required this.status,
    required this.photosTotal,
    this.photosDone = 0,
    this.stage = 'photos',
    this.piecesAdded = 0,
    this.duplicatesMerged = 0,
    this.alreadyOwned = 0,
    this.photosSkipped = 0,
  });

  final String id;
  final ImportStatus status;
  final int photosTotal;
  final int photosDone;

  /// `photos` (cutting out, one photo at a time) or `grouping` (folding the
  /// same piece seen in several photos into one).
  final String stage;

  /// New wardrobe items this import created.
  final int piecesAdded;

  /// Cut-outs folded into another card because they were the same piece.
  final int duplicatesMerged;

  /// Pieces skipped because the wardrobe already had them.
  final int alreadyOwned;

  /// Photos the server couldn't use (no one in them, a group, unreadable).
  final int photosSkipped;

  bool get finished => status != ImportStatus.processing;
  bool get grouping => stage == 'grouping';

  /// 0–1 for a progress bar. Grouping sits at the very end.
  double get progress {
    if (finished) return 1;
    if (photosTotal == 0) return 0;
    return (photosDone / photosTotal).clamp(0.0, 1.0) * (grouping ? 1 : 0.94);
  }

  factory WardrobeImport.fromJson(Map<String, dynamic> json) {
    int n(String k) => (json[k] as num?)?.toInt() ?? 0;
    return WardrobeImport(
      id: json['id'] as String,
      status: switch (json['status']) {
        'done' => ImportStatus.done,
        'failed' => ImportStatus.failed,
        'cancelled' => ImportStatus.cancelled,
        _ => ImportStatus.processing,
      },
      photosTotal: n('photosTotal'),
      photosDone: n('photosDone'),
      stage: json['stage'] as String? ?? 'photos',
      piecesAdded: n('piecesAdded'),
      duplicatesMerged: n('duplicatesMerged'),
      alreadyOwned: n('alreadyOwned'),
      photosSkipped: n('photosSkipped'),
    );
  }

  WardrobeImport copyWith({
    ImportStatus? status,
    int? photosDone,
    String? stage,
    int? piecesAdded,
    int? duplicatesMerged,
    int? alreadyOwned,
    int? photosSkipped,
  }) => WardrobeImport(
    id: id,
    status: status ?? this.status,
    photosTotal: photosTotal,
    photosDone: photosDone ?? this.photosDone,
    stage: stage ?? this.stage,
    piecesAdded: piecesAdded ?? this.piecesAdded,
    duplicatesMerged: duplicatesMerged ?? this.duplicatesMerged,
    alreadyOwned: alreadyOwned ?? this.alreadyOwned,
    photosSkipped: photosSkipped ?? this.photosSkipped,
  );
}

/// One signed upload slot handed out by `POST /wardrobe/imports`.
class ImportSlot {
  const ImportSlot({required this.uploadUrl, required this.path});
  final String uploadUrl;
  final String path;
}

/// A new import and where to put its photos.
class ImportTicket {
  const ImportTicket({required this.id, required this.slots});
  final String id;
  final List<ImportSlot> slots;
}

/// A photo that reached storage, ready for the server to work on.
class ImportedPhoto {
  const ImportedPhoto({required this.path, this.takenAt});
  final String path;

  /// When the photo was taken (from its EXIF date). Gives the piece its wear
  /// history; null when the photo carries no date.
  final DateTime? takenAt;

  /// EXIF dates carry no time zone, so only the day is sent: wear history
  /// counts days, like the worn calendar.
  Map<String, dynamic> toJson() => {
    'path': path,
    if (takenAt != null) 'takenOn': takenAt!.toIso8601String().substring(0, 10),
  };
}
