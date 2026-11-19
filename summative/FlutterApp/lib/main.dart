import 'package:flutter/material.dart';

import 'api_service.dart';

void main() => runApp(const FoodPriceApp());

class FoodPriceApp extends StatelessWidget {
  const FoodPriceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rwanda Food Price Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const PredictionPage(),
    );
  }
}

enum _Status { idle, loading, success, error }

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final _marketController = TextEditingController();
  final _commodityController = TextEditingController();
  final _priceTypeController = TextEditingController();
  final _yearController = TextEditingController();
  final _monthController = TextEditingController();

  _Status _status = _Status.idle;
  PredictionResult? _result;

  @override
  void dispose() {
    _marketController.dispose();
    _commodityController.dispose();
    _priceTypeController.dispose();
    _yearController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  Future<void> _predict() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _status = _Status.loading;
      _result = null;
    });

    final result = await predictPrice({
      'market': _marketController.text,
      'commodity': _commodityController.text,
      'pricetype': _priceTypeController.text,
      'year': _yearController.text,
      'month': _monthController.text,
    });

    if (!mounted) {
      return;
    }
    setState(() {
      _result = result;
      _status = result.isSuccess ? _Status.success : _Status.error;
    });
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool last = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        onSubmitted: last ? (_) => _predict() : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  /// The display area: shows the prediction, or a readable error message.
  Widget _buildDisplayArea(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color background = Colors.grey.shade200;
    Color foreground = Colors.black87;
    Widget content;

    if (_status == _Status.loading) {
      content = Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Contacting the server... the first request can take up to '
              'a minute while it wakes up.',
              style: TextStyle(color: foreground),
            ),
          ),
        ],
      );
    } else if (_status == _Status.success && _result != null) {
      background = scheme.primaryContainer;
      foreground = scheme.onPrimaryContainer;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Predicted price', style: TextStyle(color: foreground)),
          const SizedBox(height: 6),
          Text(
            '${formatPrice(_result!.price!)} RWF per kg',
            style: TextStyle(
              color: foreground,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(_result!.details, style: TextStyle(color: foreground)),
        ],
      );
    } else if (_status == _Status.error && _result != null) {
      background = scheme.errorContainer;
      foreground = scheme.onErrorContainer;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Could not predict',
            style: TextStyle(color: foreground, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          for (final message in _result!.errors)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(message, style: TextStyle(color: foreground)),
            ),
        ],
      );
    } else {
      content = Text(
        'Enter the values above and press Predict.',
        style: TextStyle(color: foreground),
      );
    }

    return Container(
      key: const Key('display_area'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Price Predictor')),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Estimate the retail price per kg of a food item in a '
                'Rwandan market.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              _field(
                label: 'Market',
                hint: 'e.g. Kigali',
                controller: _marketController,
              ),
              _field(
                label: 'Commodity',
                hint: 'e.g. Maize',
                controller: _commodityController,
              ),
              _field(
                label: 'Price type',
                hint: 'Retail or Wholesale',
                controller: _priceTypeController,
              ),
              _field(
                label: 'Year',
                hint: 'e.g. 2025 (2000 to 2030)',
                controller: _yearController,
              ),
              _field(
                label: 'Month',
                hint: '1 to 12',
                controller: _monthController,
                last: true,
              ),
              const SizedBox(height: 6),
              FilledButton(
                onPressed: _status == _Status.loading ? null : _predict,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Predict', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
              _buildDisplayArea(context),
            ],
          ),
        ),
      ),
    );
  }
}
