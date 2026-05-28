import 'package:sync_app/features/social/models/social_models.dart';

bool socialUrlIsVideo(String url) {
  final lower = url.toLowerCase();
  return lower.endsWith('.mp4') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.mov') ||
      lower.contains('/video/');
}

bool socialUrlIsImage(String url) {
  if (socialUrlIsVideo(url)) return false;
  final lower = url.toLowerCase();
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.webp') ||
      lower.contains('/image/');
}

List<String> imageUrlsFromPosts(List<SocialPost> posts) {
  final urls = <String>[];
  for (final post in posts) {
    for (final url in post.mediaUrls) {
      if (socialUrlIsImage(url)) urls.add(url);
    }
  }
  return urls;
}

List<SocialPost> videoPostsFrom(List<SocialPost> posts) =>
    posts.where((p) => p.mediaUrls.any(socialUrlIsVideo)).toList();
