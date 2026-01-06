import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provide_it/provide_it.dart';

import 'injector_test.dart';

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

    testWidgets('provides multiples', (tester) async {
      BuildContext? ctx;
      await provideIt(tester, (context) {
        ctx = context;
        context.provide(() => 1);
        context.provide(() => 'b');
        context.provide((int a, String b) => (a, b));
        return Container();
      });

      expect(ctx!.read<int>(), 1);
      expect(ctx!.read<String>(), 'b');
      expect(ctx!.read<(int, String)>(), (1, 'b'));
    });

    testWidgets('provides multiples un-ordered', (tester) async {
      BuildContext? ctx;
      await provideIt(tester, (context) {
        ctx = context;
        context.provide((int a, String b) => (a, b));
        context.provide(() => 'b');
        context.provide(() => 1);
        return Container();
      });

      expect(ctx!.read<int>(), 1);
      expect(ctx!.read<String>(), 'b');
      expect(ctx!.read<(int, String)>(), (1, 'b'));
    });

    testWidgets('reading multiples un-ordered', (tester) async {
      BuildContext? ctx;
      await provideIt(tester, (context) {
        ctx = context;
        context.provide((int a, String b) => (a, b));
        context.provide(() => 'b');
        context.provide(() => 1);
        return Container();
      });

      expect(ctx!.read<(int, String)>(), (1, 'b'));
      expect(ctx!.read<String>(), 'b');
      expect(ctx!.read<int>(), 1);
    });
  });

  group('ContextStates', () {
    testWidgets('value should bind value to context', (tester) async {
      await provideIt(tester, (context) {
        final (value, setValue) = context.useValue(0);
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
        final value = context.use<int>((_) {
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
      var key = Object();

      await provideIt(tester, (context) {
        snapshot =
            context.useFuture<int>(() async => 40 + ++createCount, key: key);
        return GestureDetector(
          key: Key('${snapshot!.data}'),
          onTap: () {
            key = Object();
            (context as Element).markNeedsBuild();
          },
        );
      });
      expect(snapshot, AsyncSnapshot.waiting());
      expect(createCount, 1);

      await tester.pump();
      expect(snapshot, AsyncSnapshot.withData(ConnectionState.done, 41));
      expect(createCount, 1);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(createCount, 2);

      await tester.pump();
      expect(snapshot, AsyncSnapshot.withData(ConnectionState.done, 42));
      expect(createCount, 2);
    });

    testWidgets('stream should subscribe to Stream function', (tester) async {
      AsyncSnapshot<int>? snapshot;
      int createCount = 0;
      var key = Object();

      await provideIt(tester, (context) {
        snapshot = context.useStream<int>(
          () => Stream.value(40 + ++createCount),
          key: key,
        );
        return GestureDetector(
          key: Key('${snapshot!.data}'),
          onTap: () {
            key = Object();
            (context as Element).markNeedsBuild();
          },
        );
      });
      expect(snapshot, AsyncSnapshot.waiting());
      expect(createCount, 1);

      await tester.pump();
      expect(snapshot, AsyncSnapshot.withData(ConnectionState.done, 41));
      expect(createCount, 1);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(createCount, 2);

      await tester.pump();
      expect(snapshot, AsyncSnapshot.withData(ConnectionState.done, 42));
      expect(createCount, 2);
    });

    testWidgets('should reset state when key changes', (tester) async {
      int createCount = 0;
      int disposeCount = 0;
      int? key = 1;

      await provideIt(tester, (context) {
        final (value, setValue) = context.useValue(0);

        return Column(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  context.provide(
                    () {
                      createCount++;
                      return Counter(42);
                    },
                    key: key,
                    dispose: (_) => disposeCount++,
                  );

                  final counter = context.watch<Counter>();
                  return GestureDetector(
                    key: Key('${counter.value}'),
                    onTap: () => counter.value++,
                  );
                },
              ),
            ),
            Expanded(
              child: GestureDetector(
                key: Key('change_key'),
                onTap: () {
                  key = 2;
                  setValue(value + 1);
                },
              ),
            ),
          ],
        );
      });

      expect(createCount, 1);
      expect(disposeCount, 0);
      expect(find.byKey(Key('42')), findsOneWidget);

      // Increment counter
      await tester.tap(find.byKey(Key('42')));
      await tester.pump();
      expect(find.byKey(Key('43')), findsOneWidget);

      // Change key
      await tester.tap(find.byKey(Key('change_key')));
      await tester.pump();

      // Old state should be disposed and new state created
      expect(createCount, 2);
      expect(disposeCount, 1);
      expect(find.byKey(Key('42')),
          findsOneWidget); // Counter reset to initial value
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
      int value = 0;

      await provideIt(tester, (context) {
        context.provideValue(value);
        context.listen<int>((v) => listenedValue = v);
        return GestureDetector(
          key: Key('$value'),
          onTap: () {
            value++;
            (context as Element).markNeedsBuild();
          },
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
      final counter = context.useValue(0);
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

  testWidgets('Bind dependent should be disposed', (tester) async {
    int count = 0;
    final contexts = <int, BuildContext>{};
    Bind? bind;

    await provideIt(tester, (context) {
      context.provide(() => Counter(0));
      final counter = context.useValue(0);
      count = counter.value;

      return Builder(
        key: Key(count.toString()),
        builder: (context) {
          contexts[counter.value] = context;
          context.watch<Counter>();
          bind = context.getBindOfType<Counter>();

          return GestureDetector(
            onTap: () => counter.value++,
          );
        },
      );
    });

    expect(count, 0);
    expect(bind?.dependents.length, 1);
    expect(bind?.dependents.first, contexts[0]);

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    expect(count, 1);
    expect(bind?.dependents.length, 1);
    expect(bind?.dependents.first, contexts[1]);
    expect(contexts[0] != contexts[1], true);
    expect(contexts[0]!.mounted, false);
    expect(contexts[1]!.mounted, true);
  });

  testWidgets('Bind dependent should be replaced', (tester) async {
    int createCount = 0;
    int disposeCount = 0;

    await provideIt(tester, (context) {
      final counter = context.useValue(0);

      return Builder(
        key: Key(counter.value.toString()),
        builder: (context) {
          context.provide(
            () {
              createCount++;
              return '';
            },
            lazy: false,
            dispose: (value) {
              disposeCount++;
            },
          );

          return GestureDetector(
            key: Key(context.read<String>()),
            onTap: () => counter.value++,
          );
        },
      );
    });

    expect(createCount, 1);
    expect(disposeCount, 0);
    expect(find.byKey(Key('')), findsOneWidget);

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    expect(createCount, 2);
    expect(disposeCount, 1);
    expect(find.byKey(Key('')), findsOneWidget);
  });

  testWidgets('Bind should deactivate and activate', (tester) async {
    final key = GlobalKey();
    late _ActivateBind bind;

    await provideIt(
      tester,
      (context) {
        final (swap, setSwap) = context.useValue(false);

        final button = Builder(
            key: key,
            builder: (context) {
              bind = (_ActivateRef(0).bind(context)..watch(context))
                  as _ActivateBind;

              return GestureDetector(
                key: Key(bind.value.toString()),
                onTap: () => setSwap(!swap),
              );
            });

        if (swap) {
          return button;
        }

        return SizedBox(
          child: button,
        );
      },
    );

    expect(bind.value, 0);

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    expect(bind.value, 1);
  });
}

class _ActivateRef extends UseValueRef<int> {
  _ActivateRef(super.initialValue);

  @override
  UseValueBind<int> createBind() => _ActivateBind();
}

class _ActivateBind extends UseValueBind<int> {
  @override
  void activate() {
    value = value! + 1;
    super.activate();
  }
}

class Counter extends ChangeNotifier {
  Counter([this._value = 42]);
  int _value;
  int get value => _value;
  set value(int value) {
    _value = value;
    notifyListeners();
  }

  int _value2 = 0;
  int get value2 => _value2;
  set value2(int value) {
    _value2 = value;
    notifyListeners();
  }
}
