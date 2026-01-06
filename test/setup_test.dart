import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provide_it/provide_it.dart';

void main() {
  group('Setup', () {
    testWidgets('should throw AssertionError when not above app',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ProvideIt(child: Text('Hello')),
      ));

      final e = tester.takeException();
      expect(e, isA<AssertionError>());
      expect(
        e.toString(),
        contains('The root `ProvideIt` widget must be above your app.'),
      );
    });

    testWidgets('should throw StateError when re-attaching a scope',
        (tester) async {
      final scope = ReadIt.asNewInstance();

      await tester.pumpWidget(ProvideIt(
        scope: scope,
        child: ProvideIt(scope: scope, child: Text('Hello')),
      ));

      final e = tester.takeException();
      expect(e, isA<StateError>());
      expect(
        e.toString(),
        contains('Scope already attached to:'),
      );
    });

    testWidgets('throws when using ReadIt.instance & !mounted', (tester) async {
      try {
        await ReadIt.instance.allReady();
      } catch (e) {
        expect(e, isA<AssertionError>());
        expect(
          e.toString(),
          contains('Scope not attached.'),
        );
      }
    });
  });
}
