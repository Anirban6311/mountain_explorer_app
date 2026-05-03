import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class Env {
  String get openWeatherApiKey;

  /// Web OAuth 2.0 client ID used by `google_sign_in` on Android to obtain
  /// an `idToken` suitable for Firebase Auth. Null when Google sign-in is
  /// not yet configured — the feature must degrade to a clear error.
  String? get googleSignInServerClientId;

  /// MapTiler API key. Required for OSM-style offline tile downloads.
  String get maptilerApiKey;

  /// Tile URL template (e.g. MapTiler Outdoor). `{apiKey}` is substituted
  /// at request time with [maptilerApiKey].
  String get osmTileUrlTemplate;

  /// Attribution string rendered on the map, required by the tile
  /// provider's terms of use.
  String get osmTileAttribution;
}

class DotenvEnv implements Env {
  DotenvEnv() {
    _openWeatherApiKey = _required('OPENWEATHER_API_KEY');
    _maptilerApiKey = _required('MAPTILER_API_KEY');
    _osmTileUrlTemplate = _required('OSM_TILE_URL_TEMPLATE');
    _osmTileAttribution = _required('OSM_TILE_ATTRIBUTION');
    if (!_osmTileUrlTemplate.contains('{apiKey}')) {
      throw ArgumentError(
        'OSM_TILE_URL_TEMPLATE must contain the literal `{apiKey}` '
        'placeholder; otherwise tile requests would leave the key out.',
      );
    }

    final googleId = dotenv.maybeGet('GOOGLE_SIGN_IN_SERVER_CLIENT_ID');
    _googleSignInServerClientId =
        (googleId == null || googleId.isEmpty) ? null : googleId;
  }

  late final String _openWeatherApiKey;
  late final String? _googleSignInServerClientId;
  late final String _maptilerApiKey;
  late final String _osmTileUrlTemplate;
  late final String _osmTileAttribution;

  static String _required(String name) {
    final v = dotenv.maybeGet(name);
    if (v == null || v.isEmpty) {
      throw ArgumentError('$name missing from .env. See .env.example.');
    }
    return v;
  }

  @override
  String get openWeatherApiKey => _openWeatherApiKey;

  @override
  String? get googleSignInServerClientId => _googleSignInServerClientId;

  @override
  String get maptilerApiKey => _maptilerApiKey;

  @override
  String get osmTileUrlTemplate => _osmTileUrlTemplate;

  @override
  String get osmTileAttribution => _osmTileAttribution;
}
