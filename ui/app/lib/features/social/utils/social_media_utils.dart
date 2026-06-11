import 'package:sync_app/features/social/models/social_models.dart';

enum SocialMediaKind { image, video, unknown }

bool socialUrlIsVideo(String url) => SocialMediaUtils.isVideoUrl(url);

List<SocialPost> videoPostsFrom(List<SocialPost> posts) =>
    posts.where((p) => p.mediaUrls.any(SocialMediaUtils.isVideoUrl)).toList();

List<String> imageUrlsFromPosts(List<SocialPost> posts) =>
    posts.expand((p) => p.mediaUrls).where(SocialMediaUtils.isImageUrl).toList();

abstract final class SocialMediaUtils {
  static const maxPostImages = 5;
  static const maxPostVideos = 1;

  static SocialMediaKind kindForUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mov') ||
        lower.contains('video/')) {
      return SocialMediaKind.video;
    }
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.contains('image/')) {
      return SocialMediaKind.image;
    }
    return SocialMediaKind.unknown;
  }

  static bool isImageUrl(String url) => kindForUrl(url) == SocialMediaKind.image;

  static bool isVideoUrl(String url) => kindForUrl(url) == SocialMediaKind.video;

  static List<String> imageUrlsFrom(Iterable<String> urls) =>
      urls.where(isImageUrl).toList();
}
