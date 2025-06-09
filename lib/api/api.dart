import 'package:flutter_dotenv/flutter_dotenv.dart';

class Api {
  static final String baseUrl = dotenv.env['BACKEND_URL'] ?? '';

  static const String userMe = '/users/me';

  static Uri getUserMe() => Uri.parse('$baseUrl$userMe');
}
