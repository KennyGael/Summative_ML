import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Public address of the deployed FastAPI service on Render.
/// Swagger UI for the same service: $apiBaseUrl/docs
const String apiBaseUrl = 'https://rwanda-food-price-api.onrender.com';

/// Names shown to the user when an input is rejected.
const Map<String, String> fieldLabels = {
  'market': 'Market',
  'commodity': 'Commodity',
  'pricetype': 'Price type',
  'year': 'Year',
  'month': 'Month',
};

const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// What the screen needs after calling the API: either a price or a list of
/// readable error messages.
class PredictionResult {
  PredictionResult.success({required this.price, required this.details})
      : errors = const [];

  PredictionResult.failure(this.errors)
      : price = null,
        details = '';

  final double? price;
  final String details;
  final List<String> errors;

  bool get isSuccess => price != null;
}

/// Formats 1234.6 as "1,235".
String formatPrice(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Sends the user's inputs to POST /predict and turns the answer into a
/// [PredictionResult].
///
/// The app does not re-implement the validation rules. Empty fields are left
/// out of the request, and year/month are sent exactly as typed when they are
/// not whole numbers, so the API itself reports a missing value, a wrong type
/// or an out-of-range value. Those answers are then rewritten in plain words.
Future<PredictionResult> predictPrice(Map<String, String> inputs) async {
  final body = <String, dynamic>{};
  inputs.forEach((key, raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return; // missing value: the API reports "field required"
    }
    if (key == 'year' || key == 'month') {
      body[key] = int.tryParse(text) ?? text;
    } else {
      body[key] = text;
    }
  });

  try {
    final response = await http
        .post(
          Uri.parse('$apiBaseUrl/predict'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        // A free Render service can take up to a minute to wake up.
        .timeout(const Duration(seconds: 90));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final price = (data['predicted_price'] as num).toDouble();
      return PredictionResult.success(
        price: price,
        details: _describeInputs(data['inputs']),
      );
    }

    if (response.statusCode == 422) {
      final data = jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      return PredictionResult.failure(_readableErrors(data['detail']));
    }

    return PredictionResult.failure([
      'The server returned an error (code ${response.statusCode}). '
          'Please try again in a moment.',
    ]);
  } on TimeoutException {
    return PredictionResult.failure([
      'The server took too long to answer. It may be waking up, '
          'so please try again.',
    ]);
    } catch (e) {
    print('Predict failed: $e');
    return PredictionResult.failure([
      'Could not reach the server. Check your internet connection '
          'and try again.',
    ]);
  }
}
String _describeInputs(dynamic inputs) {
  if (inputs is! Map) {
    return '';
  }
  final month = inputs['month'];
  final monthName = (month is int && month >= 1 && month <= 12)
      ? _monthNames[month - 1]
      : '$month';
  return '${inputs['commodity']} at ${inputs['market']} market '
      '(${inputs['pricetype']}), $monthName ${inputs['year']}';
}

/// Rewrites FastAPI's validation errors (HTTP 422) in plain language.
List<String> _readableErrors(dynamic detail) {
  if (detail is! List) {
    return ['The server did not accept these values.'];
  }

  final messages = <String>[];
  for (final item in detail) {
    if (item is! Map) {
      continue;
    }
    final loc = item['loc'];
    final field = (loc is List && loc.isNotEmpty) ? loc.last.toString() : '';
    final label = fieldLabels[field] ?? field;
    final type = item['type']?.toString() ?? '';
    final ctx = item['ctx'];
    final rawMessage = item['msg']?.toString() ?? 'Invalid value.';

    String message;
    if (type == 'missing') {
      message = '$label is missing. Please enter a value.';
    } else if (type == 'int_type' || type == 'int_parsing') {
      message = '$label must be a whole number.';
    } else if (type == 'string_type') {
      message = '$label must be text.';
    } else if (type == 'string_too_short') {
      message = '$label cannot be empty.';
    } else if (type == 'greater_than_equal' && ctx is Map) {
      message = '$label is out of range: it must be at least ${ctx['ge']}.';
    } else if (type == 'less_than_equal' && ctx is Map) {
      message = '$label is out of range: it must be at most ${ctx['le']}.';
    } else if (type == 'value_error') {
      // e.g. "Unknown commodity 'Pizza'. Examples of valid values: ..."
      message = rawMessage.replaceFirst('Value error, ', '');
    } else {
      message = label.isEmpty ? rawMessage : '$label: $rawMessage';
    }

    if (!messages.contains(message)) {
      messages.add(message);
    }
  }

  return messages.isEmpty ? ['The server did not accept these values.'] : messages;
}
