import 'package:basic_crud_flutter/core/env/env.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

const _validEnv = '''
OPENWEATHER_API_KEY=abc123
MAPTILER_API_KEY=mt_key
OSM_TILE_URL_TEMPLATE=https://api.maptiler.com/maps/outdoor-v2/{z}/{x}/{y}.png?key={apiKey}
OSM_TILE_ATTRIBUTION=© MapTiler © OpenStreetMap contributors
''';

void main() {
  group('DotenvEnv', () {
    setUp(() => dotenv.testLoad(fileInput: ''));
    tearDown(() => dotenv.testLoad(fileInput: ''));

    test('exposes OPENWEATHER_API_KEY when present in dotenv', () {
      dotenv.testLoad(fileInput: _validEnv);
      final env = DotenvEnv();
      expect(env.openWeatherApiKey, 'abc123');
    });

    test('throws ArgumentError when OPENWEATHER_API_KEY is missing', () {
      dotenv.testLoad(fileInput: '');
      expect(() => DotenvEnv(), throwsArgumentError);
    });

    test('throws ArgumentError when OPENWEATHER_API_KEY is blank', () {
      dotenv.testLoad(fileInput: 'OPENWEATHER_API_KEY=');
      expect(() => DotenvEnv(), throwsArgumentError);
    });

    test('exposes MapTiler keys when present', () {
      dotenv.testLoad(fileInput: _validEnv);
      final env = DotenvEnv();
      expect(env.maptilerApiKey, 'mt_key');
      expect(
        env.osmTileUrlTemplate,
        'https://api.maptiler.com/maps/outdoor-v2/{z}/{x}/{y}.png?key={apiKey}',
      );
      expect(
        env.osmTileAttribution,
        '© MapTiler © OpenStreetMap contributors',
      );
    });

    test('throws ArgumentError when MAPTILER_API_KEY is missing', () {
      dotenv.testLoad(fileInput: '''
OPENWEATHER_API_KEY=abc123
OSM_TILE_URL_TEMPLATE=https://example/{z}/{x}/{y}.png
OSM_TILE_ATTRIBUTION=© test
''');
      expect(() => DotenvEnv(), throwsArgumentError);
    });

    test('throws ArgumentError when OSM_TILE_URL_TEMPLATE is missing', () {
      dotenv.testLoad(fileInput: '''
OPENWEATHER_API_KEY=abc123
MAPTILER_API_KEY=mt_key
OSM_TILE_ATTRIBUTION=© test
''');
      expect(() => DotenvEnv(), throwsArgumentError);
    });

    test('exposes googleSignInServerClientId when present', () {
      dotenv.testLoad(fileInput: '''
$_validEnv
GOOGLE_SIGN_IN_SERVER_CLIENT_ID=some-client-id.googleusercontent.com
''');
      final env = DotenvEnv();
      expect(
        env.googleSignInServerClientId,
        'some-client-id.googleusercontent.com',
      );
    });

    test('googleSignInServerClientId is null when blank', () {
      dotenv.testLoad(fileInput: _validEnv);
      final env = DotenvEnv();
      expect(env.googleSignInServerClientId, isNull);
    });

    test('throws ArgumentError when OSM_TILE_ATTRIBUTION is missing', () {
      dotenv.testLoad(fileInput: '''
OPENWEATHER_API_KEY=abc123
MAPTILER_API_KEY=mt_key
OSM_TILE_URL_TEMPLATE=https://example/{z}/{x}/{y}.png?key={apiKey}
''');
      expect(() => DotenvEnv(), throwsArgumentError);
    });

    test('throws ArgumentError when URL template lacks {apiKey}', () {
      dotenv.testLoad(fileInput: '''
OPENWEATHER_API_KEY=abc123
MAPTILER_API_KEY=mt_key
OSM_TILE_URL_TEMPLATE=https://example/{z}/{x}/{y}.png
OSM_TILE_ATTRIBUTION=© test
''');
      expect(() => DotenvEnv(), throwsArgumentError);
    });
  });
}
