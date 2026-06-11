/// Parses avatar URLs produced by IAM registration (`randomavatar:{seed}`).
/// The seed is consumed by the [random_avatar] Multiavatar wrapper on Flutter.
class RandomAvatarUrl {
  RandomAvatarUrl._();

  static const prefix = 'randomavatar:';

  /// Returns the Multiavatar seed when [avatarUrl] uses the IAM random-avatar scheme.
  static String? extractSeed(String? avatarUrl) {
    final url = avatarUrl?.trim();
    if (url == null || url.isEmpty) return null;
    if (!url.startsWith(prefix)) return null;
    final seed = url.substring(prefix.length);
    return seed.isEmpty ? null : seed;
  }
}
