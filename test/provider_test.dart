import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provide_it/provide_it.dart';

extension on WidgetTester {
  Future<BuildContext> provideIt(Widget widget) async {
    BuildContext? context;
    await pumpWidget(
      ProvideIt(
        scope: ReadIt.asNewInstance(),
        child: Builder(builder: (ctx) {
          context = ctx;
          return widget;
        }),
      ),
    );
    return context!;
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
      Widget? widget;
      final key = GlobalKey();

      await tester.provideIt(
        Provider<int>(
          key: key,
          lazy: false,
          create: (context) => 42,
          dispose: (context, value) {
            widget = context.widget;
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

      // accessing the widget in dispose is only available in RefWidget.dispose.
      expect(widget, isA<Provider>());
    });

    testWidgets('shouldn\'t dispose when lazy value is not init',
        (tester) async {
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
          final (count, setCount) = context.useValue(0.0);
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

    testWidgets('should update when context.watch is used', (tester) async {
      int value = 0;

      await tester.provideIt(
        Provider<int>(
          create: (context) => 42,
          builder: (context, child) {
            return Consumer<int>(
              builder: (context, val, child) {
                value = val;
                return Text('$val', textDirection: TextDirection.ltr);
              },
            );
          },
        ),
      );

      expect(find.text('42'), findsOneWidget);
      expect(value, 42);
    });
  });

  group('MultiProvider', () {
    testWidgets('should bind multiple providers', (tester) async {
      bool provider1Called = false;
      bool provider2Called = false;

      final context = await tester.provideIt(
        MultiProvider(
          providers: [
            Provider<int>(
              create: (context) {
                provider1Called = true;
                return 42;
              },
              builder: (context, child) => Container(),
            ),
            Provider<String>(
              create: (context) {
                provider2Called = true;
                return 'Hello';
              },
              builder: (context, child) => Container(),
            ),
          ],
          builder: (context, child) => Container(),
        ),
      );

      expect(provider1Called, isFalse);
      expect(provider2Called, isFalse);

      context.read<int>();
      context.read<String>();

      expect(provider1Called, isTrue);
      expect(provider2Called, isTrue);
    });

    testWidgets('ValueListenableProvider should update when value changes',
        (tester) async {
      final valueNotifier = ValueNotifier<int>(0);

      await tester.provideIt(
        ValueListenableProvider<int>.value(
          value: valueNotifier,
          builder: (context, child) {
            final value = context.watch<int>();
            return Text('$value', textDirection: TextDirection.ltr);
          },
        ),
      );

      expect(find.text('0'), findsOneWidget);

      // Update ValueNotifier
      valueNotifier.value = 1;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });
  });
}
