import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_price_app/main.dart';

void main() {
  testWidgets('shows five labelled fields and a Predict button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FoodPriceApp());

    expect(find.byType(TextField), findsNWidgets(5));
    for (final label in ['Market', 'Commodity', 'Price type', 'Year', 'Month']) {
      expect(find.widgetWithText(TextField, label), findsOneWidget);
    }
    expect(find.text('Predict'), findsOneWidget);
  });
}
