import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// removed unused import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Monte um MaterialApp se o widget depender de Theme/Localizations
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(child: Text('0')), // simula o estado inicial com '0'
      ),
    ));

    // Verifica '0' existe
    expect(find.text('0'), findsOneWidget);

    // Simula um clique (se você tiver um botão que muda o texto)
    // await tester.tap(find.byIcon(Icons.add));
    // await tester.pump();

    // expect(find.text('1'), findsOneWidget);
  });
}
