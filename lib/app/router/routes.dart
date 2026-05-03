class Routes {
  const Routes._();

  static const String root = '/';
  static const String onboarding = '/onboarding';

  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';

  static const String home = '/home';
  static const String mountains = '/mountains';
  static const String mountainSearch = '/mountains/search';
  static const String likedMountains = '/liked-mountains';
  static const String profile = '/profile';

  static const String checklist = '/checklist';

  static const String feed = '/community';
  static const String createPost = '/community/new';
  static String postDetail(String id) => '/community/post/$id';
  static String editPost(String id) => '/community/post/$id/edit';
  static const String postDetailPattern = '/community/post/:id';
  static const String editPostPattern = '/community/post/:id/edit';

  static const String backgroundLocationConsent =
      '/consent/background-location';

  static const String map = '/map';

  static const String settings = '/settings';
  static const String offlineRegions = '/offline-regions';
  static const String emergencyContacts = '/sos/contacts';
}
