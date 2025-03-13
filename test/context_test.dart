import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provide_it/provide_it.dart';

import 'injector_test.dart';
import 'read_it_test.dart';

Future<void> provideIt(
  WidgetTester tester,
  WidgetBuilder builder, {
  void Function(BuildContext context)? provide,
}) async {
  await tester.pumpWidget(
    ProvideIt(
      key: UniqueKey(),
      provide: provide,
      scope: ReadIt.asNewInstance(),
      child: Builder(
        builder: builder,
      ),
    ),
  );
}

void main() {
  group('ContextProviders', () {
    testWidgets('provide should call create immediately', (tester) async {
      bool createCalled = false;

      await provideIt(tester, (context) {
        context.provide<int>(() {
          createCalled = true;
          return 42;
        }, lazy: false);
        return Container();
      });

      expect(createCalled, isTrue);
    });

    testWidgets('provideLazy should call create on first read', (tester) async {
      int createCount = 0;

      await provideIt(tester, (context) {
        context.provide<int>(() {
          createCount++;
          return 42;
        }, lazy: true);
        return GestureDetector(
          onTap: () => context.read<int>(),
        );
      });
      expect(createCount, 0);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(createCount, 1);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(createCount, 1);
    });

    testWidgets('provideValue should directly provide a value', (tester) async {
      int? tappedValue;

      await provideIt(tester, (context) {
        final value = context.provideValue(42);
        return GestureDetector(
          key: Key('$value'),
          onTap: () => tappedValue = context.read<int>(),
        );
      });

      expect(find.byKey(Key('42')), findsOneWidget);
      expect(tappedValue, isNull);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(find.byKey(Key('42')), findsOneWidget);
      expect(tappedValue, 42);
    });
  });

  group('ContextStates', () {
    testWidgets('value should bind value to context', (tester) async {
      await provideIt(tester, (context) {
        final (value, setValue) = context.value(0);
        return GestureDetector(
          key: Key('$value'),
          onTap: () => setValue(value + 1),
        );
      });
      expect(find.byKey(Key('0')), findsOneWidget);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(find.byKey(Key('1')), findsOneWidget);

      await tester.pump();
      expect(find.byKey(Key('1')), findsOneWidget);
    });

    testWidgets('create should bind created value to context', (tester) async {
      int createCount = 0;
      await provideIt(tester, (context) {
        final value = context.create<int>(() {
          createCount++;
          return 42;
        });
        return Container(key: Key('$value'));
      });

      expect(find.byKey(Key('42')), findsOneWidget);
      expect(createCount, 1);

      // add a reassemble to test if the value is recreated
      await tester.pump();

      expect(find.byKey(Key('42')), findsOneWidget);
      expect(createCount, 1);
    });

    testWidgets('future should subscribe to Future function', (tester) async {
      AsyncSnapshot<int>? snapshot;
      int createCount = 0;
      await provideIt(tester, (context) {
        snapshot = context.future<int>(() async => 40 + ++createCount);
        return GestureDetector(
          key: Key('${snapshot!.data}'),
          onTap: () => context.reload<int>(),
        );
      });
      expect(snapshot, AsyncSnapshot.waiting());
      expect(createCount, 1);

      await tester.pump();
      expect(snapshot, AsyncSnapshot.withData(ConnectionState.done, 41));
      expect(createCount, 1);

      await tester.tap(find.byType(GestureDetector));
      expect(createCount, 2);

      await tester.pump();
      expect(snapshot, AsyncSnapshot.withData(ConnectionState.done, 42));
      expect(createCount, 2);
    });

    testWidgets('stream should subscribe to Stream function', (tester) async {
      AsyncSnapshot<int>? snapshot;
      int createCount = 0;

      await provideIt(tester, (context) {
        snapshot = context.stream<int>(() => Stream.value(40 + ++createCount));
        return GestureDetector(
          key: Key('${snapshot!.data}'),
          onTap: () => context.reload<int>(),
        );
      });
      expect(snapshot, AsyncSnapshot.waiting());
      expect(createCount, 1);

      await tester.pump();
      expect(snapshot, AsyncSnapshot.withData(ConnectionState.done, 41));
      expect(createCount, 1);

      await tester.tap(find.byType(GestureDetector));
      expect(createCount, 2);

      await tester.pump();
      expect(snapshot, AsyncSnapshot.withData(ConnectionState.done, 42));
      expect(createCount, 2);
    });
  });

  group('ContextReaders', () {
    testWidgets('context should watch previously bound value', (tester) async {
      int buildCount = 0;
      await provideIt(tester, (context) {
        buildCount++;
        context.provide(() => Counter(0));

        return Builder(builder: (context) {
          final counter = context.watch<Counter>();
          return GestureDetector(
            key: Key('${counter.value}'),
            onTap: () => counter.value++,
          );
        });
      });

      expect(find.byKey(Key('0')), findsOneWidget);
      expect(buildCount, 1);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(find.byKey(Key('1')), findsOneWidget);
      expect(buildCount, 1);
    });

    testWidgets('select should select value from previously bound value',
        (tester) async {
      int rootBuildCount = 0;
      int newBuildCount = 0;
      int? selectedValue;

      await provideIt(tester, (context) {
        rootBuildCount++;
        context.provide(() => Counter(0));
        return Builder(builder: (context) {
          newBuildCount++;
          selectedValue = context.select((Counter s) => s.value);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: GestureDetector(
                  key: Key('value'),
                  onTap: () => context.read<Counter>().value++,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  key: Key('value2'),
                  onTap: () => context.read<Counter>().value2++,
                ),
              ),
            ],
          );
        });
      });

      expect(rootBuildCount, 1);
      expect(newBuildCount, 1);
      expect(selectedValue, 0);

      // should watch selected value
      await tester.tap(find.byKey(Key('value')));
      await tester.pump();

      expect(rootBuildCount, 1);
      expect(newBuildCount, 2);
      expect(selectedValue, 1);

      // should ignore unselected values
      await tester.tap(find.byKey(Key('value2')));
      await tester.pump();

      expect(rootBuildCount, 1);
      expect(newBuildCount, 2);
      expect(selectedValue, 1);
    });

    testWidgets('listen should listen to previously bound value',
        (tester) async {
      int listenedValue = 0;

      await provideIt(tester, (context) {
        final (value, setValue) = context.value<int>(0);
        context.listen<int>((v) => listenedValue = v);
        return GestureDetector(
          key: Key('$value'),
          onTap: () => setValue(value + 1),
        );
      });

      expect(listenedValue, 0);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(listenedValue, 1);
    });

    testWidgets('nested async constructors/params', (tester) async {
      Leaf? value;
      NestedA? nestedA;

      await provideIt(tester, provide: (context) {
        context.provide(NestedA.init);
        context.provide(NestedB.init);
        context.provide(Nested.new); // needs NestedA and NestedB
        context.provide(Async.init);
        context.provide(Leaf.new); // needs Nested and Async
      }, (context) {
        value = context.watch<Leaf>();

        return GestureDetector(
          key: ObjectKey(value),
          onTap: () {
            nestedA = context.read();
          },
        );
      });

      expect(value, isNull);
      expect(nestedA, isNull);
      await tester.pumpAndSettle();

      expect(nestedA, isNull);
      expect(value, isA<Leaf>());
      expect(value!.a, isA<Nested>());
      expect(value!.b, isA<Async>());
      expect(value!.a.a, isA<NestedA>());
      expect(value!.a.b, isA<NestedB>());

      await tester.tap(find.byType(GestureDetector));
      expect(nestedA, isA<NestedA>());
    });
  });

  testWidgets('Ref.bind should be disposed', (tester) async {
    bool disposed = false;
    int count = 0;
    final contexts = <int, BuildContext>{};

    await provideIt(tester, (context) {
      final counter = context.value(0);
      count = counter.value;

      return Builder(
        key: Key(count.toString()),
        builder: (context) {
          contexts[counter.value] = context;

          context.provide(() => Counter(0), dispose: (_) => disposed = true);
          return GestureDetector(
            onTap: () => counter.value++,
          );
        },
      );
    });

    expect(count, 0);
    expect(disposed, isFalse);

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    expect(count, 1);
    expect(disposed, isTrue);
    expect(contexts[0] != contexts[1], true);
    expect(contexts[0]!.mounted, false);
    expect(contexts[1]!.mounted, true);
  });

  testWidgets('RefState dependent should be disposed', (tester) async {
    int count = 0;
    final contexts = <int, BuildContext>{};
    RefState? refState;

    await provideIt(tester, (context) {
      context.provide(() => Counter(0));
      final counter = context.value(0);
      count = counter.value;

      return Builder(
        key: Key(count.toString()),
        builder: (context) {
          contexts[counter.value] = context;
          context.watch<Counter>();
          refState = context.getRefStateOfType<Counter>();

          return GestureDetector(
            onTap: () => counter.value++,
          );
        },
      );
    });

    expect(count, 0);
    expect(refState?.dependents.length, 1);
    expect(refState?.dependents.first, contexts[0]);

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    expect(count, 1);
    expect(refState?.dependents.length, 1);
    expect(refState?.dependents.first, contexts[1]);
    expect(contexts[0] != contexts[1], true);
    expect(contexts[0]!.mounted, false);
    expect(contexts[1]!.mounted, true);
  });
}
