import 'package:url_launcher/url_launcher.dart';

abstract class SmsDataSource {
  /// Opens the platform SMS composer pre-filled with [body] and addressed
  /// to [phone]. Returns true when the launcher reports success.
  Future<bool> sendSms({required String phone, required String body});
}

class UrlLauncherSmsDataSource implements SmsDataSource {
  const UrlLauncherSmsDataSource();

  @override
  Future<bool> sendSms({required String phone, required String body}) async {
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': body},
    );
    return launchUrl(uri);
  }
}
