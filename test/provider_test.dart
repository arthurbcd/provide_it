import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provide_it/provide_it.dart';

extension on WidgetTester {
  Future<void> provideIt(Widget widget) {
    return pumpWidget(
      ProvideIt(
        scope: ReadIt.asNewInstance(),
        child: widget,
      ),
    );
  }
}

void main() {
  group('Provider', () {
    testWidgets('should create value immediately if lazy is false',
        (tester) async {
      bool createCalled = false;

      await tester.provideIt(
        Provider<int>(
          create: (context) {
            createCalled = true;
            return 42;
          },
          lazy: false,
          builder: (context, child) => Container(),
        ),
      );

      expect(createCalled, isTrue);
    });

    testWidgets('should create value lazily if lazy is true', (tester) async {
      bool createCalled = false;

      await tester.provideIt(
        Provider<int>(
          create: (context) {
            createCalled = true;
            return 42;
          },
          lazy: true,
          builder: (context, _) => GestureDetector(
            onTap: () {
              context.read<int>();
            },
          ),
        ),
      );

      expect(createCalled, isFalse);

      // Trigger the lazy creation
      await tester.tap(find.byType(GestureDetector));

      expect(createCalled, isTrue);
    });

    testWidgets('should dispose value when widget is disposed', (tester) async {
      bool disposeCalled = false;
      final key = GlobalKey();

      await tester.provideIt(
        Provider<int>(
          key: key,
          lazy: false,
          create: (context) => 42,
          dispose: (context, value) {
            disposeCalled = true;
          },
          builder: (context, child) => Container(),
        ),
      );

      expect(key.currentContext?.mounted, isTrue);
      expect(disposeCalled, isFalse);

      await tester.provideIt(Container());

      expect(key.currentContext?.mounted, isNull);
      expect(disposeCalled, isTrue);
    });

    testWidgets('shouldnt dispose when lazy value is not init', (tester) async {
      bool disposeCalled = false;
      final key = GlobalKey();

      await tester.provideIt(
        Provider<int>(
          key: key,
          lazy: true,
          create: (context) => 42,
          dispose: (context, value) {
            disposeCalled = true;
          },
          builder: (context, child) => Container(),
        ),
      );

      expect(key.currentContext?.mounted, isTrue);
      expect(disposeCalled, isFalse);

      await tester.provideIt(Container());

      expect(key.currentContext?.mounted, isNull);
      expect(disposeCalled, isFalse);
    });

    testWidgets('should provide value directly when using Provider.value',
        (tester) async {
      await tester.provideIt(
        Provider<int>.value(
          value: 42,
          builder: (context, child) {
            final value = context.read<int>();
            return Text('$value', textDirection: TextDirection.ltr);
          },
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('should update value when updateShouldNotify returns true',
        (tester) async {
      int value = 0;
      await tester.provideIt(
        Builder(builder: (context) {
          final (count, setCount) = context.value(0.0);
          return Provider<int>.value(
            value: count.toInt(),
            updateShouldNotify: (previous, current) => current < 3,
            builder: (context, child) {
              value = context.read<int>();
              return GestureDetector(
                onTap: () => setCount(count + 1),
              );
            },
          );
        }),
      );

      expect(value, 0);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(value, 1);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(value, 2);

      await tester.tap(find.byType(GestureDetector));
      await tester.tap(find.byType(GestureDetector));
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(value, 2);
    });
  });
}
