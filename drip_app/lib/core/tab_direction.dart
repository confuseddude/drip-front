/// Direction of the last tab change (-1 left, +1 right, 0 = not a tab move,
/// e.g. a fit opened from a card). The tab transition reads it so pages slide
/// the way the lens moved, and shared-image (Hero) flights only run when it's
/// 0, so a tab swipe is never crossed by an image flying between screens.
abstract final class TabDirection {
  static int value = 0;
}
