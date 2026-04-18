import 'package:flutter_test/flutter_test.dart';
import 'package:provide_it/provide_it.dart';
import 'package:provide_it/src/framework.dart';

import 'injector_test.dart';

Future<void> provideIt(
  WidgetTester tester,
  WidgetBuilder builder, {
  void Function(BuildContext context)? provide,
}) async {
  await tester.pumpWidget(
    ProvideIt(
      provide: provide,
      child: Builder(builder: builder),
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
        return GestureDetector(onTap: () => context.read<int>());
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

    testWidgets('observe multiples providers', (tester) async {
      Object? value1;
      Object? value2;
      Object? value3;
      Object? value4;
      await provideIt(tester, (context) {
        context.provide((int a, String b) => (a, b));
        context.provide(() => 'b');
        context.provide(() => 1);
        return Builder(
          builder: (context) {
            value1 = context.select(((int, String) s) => s.$1);
            value2 = context.watch<String>();
            value3 = context.watch<int>();
            value4 = context.select(((int, String) s) => s.$2);
            return Container();
          },
        );
      });

      await tester.pump();

      expect(value1, 1);
      expect(value2, 'b');
      expect(value3, 1);
      expect(value4, 'b');
    });

    testWidgets(
      'provides/read same type in different contexts (disambiguation)',
      (tester) async {
        int? outerValue;
        int? innerValue;

        await provideIt(tester, (context) {
          // Provedor externo
          context.provide<int>(() => 1);

          return Builder(
            builder: (context) {
              outerValue = context.read<int>();
              return Builder(
                builder: (context) {
                  context.provide<int>(() => 2);
                  return Builder(
                    builder: (context) {
                      innerValue = context.read<int>();
                      return Container();
                    },
                  );
                },
              );
            },
          );
        });

        await tester.pump();

        expect(outerValue, 1);
        expect(innerValue, 2);
      },
    );
    testWidgets(
      'provide same type in different contexts & read in the same context',
      (tester) async {
        int? outerValue;
        int? innerValue;
        Element? readContext;

        await provideIt(tester, (context) {
          // Provedor externo
          context.provide<int>(() => 1);

          return Builder(
            builder: (context) {
              context.provide<int>(() => 2);

              return Builder(
                builder: (context) {
                  readContext = context as Element;
                  outerValue = context.read<int>();
                  context.provide<int>(() => 3);
                  innerValue = context.read<int>();
                  return Container();
                },
              );
            },
          );
        });

        await tester.pump();

        expect(outerValue, 2);
        expect(innerValue, 3);

        readContext?.markNeedsBuild();
        await tester.pump();

        expect(outerValue, 2);
        expect(innerValue, 3);
      },
    );

    testWidgets(
      'inherits providers from a sibling context (logical ancestor)',
      (tester) async {
        late BuildContext contextA;
        late BuildContext contextB;
        late BuildContext contextC;

        await provideIt(tester, (context) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                // Branch A
                Builder(
                  builder: (context) {
                    contextA = context;
                    context.provide(() => 'A');
                    return const Text('Provider Branch');
                  },
                ),
                // Branch B
                Builder(
                  builder: (context) {
                    contextB = context;
                    context.provide(() => 'B');
                    return const Text('Provider Branch');
                  },
                ),

                // Branch C
                Builder(
                  builder: (context) {
                    contextC = context;
                    return const Text('Consumer Branch');
                  },
                ),
              ],
            ),
          );
        });

        expect(
          () => contextC.read<String>(),
          throwsA(isA<ProviderMultipleFoundException>()),
        );

        contextC.inheritProviders(contextA);
        expect(contextC.read<String>(), 'A');

        expect(
          () => contextC.inheritProviders(contextB),
          throwsA(
            isA<AssertionError>(),
          ), // cannot inherit from multiple ancestors
        );
      },
    );
  });

  group('ContextStates', () {
    testWidgets('value should bind value to context', (tester) async {
      await provideIt(tester, (context) {
        final (value, setValue) = context.useState(0);
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

    testWidgets('value should bind multiple values to context', (tester) async {
      await provideIt(tester, (context) {
        final (value, setValue) = context.useState(0);
        final (value2, setValue2) = context.useState(10);
        return GestureDetector(
          key: Key('$value $value2'),
          onTap: () {
            setValue(value + 1);
            setValue2(value2 + 10);
          },
        );
      });
      expect(find.byKey(Key('0 10')), findsOneWidget);

      // should change both values
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(find.byKey(Key('1 20')), findsOneWidget);

      // should preserve
      await tester.pump();
      expect(find.byKey(Key('1 20')), findsOneWidget);
    });

    testWidgets('create should bind created value to context', (tester) async {
      int createCount = 0;
      await provideIt(tester, (context) {
        final value = context.use<int>(() {
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
        snapshot = context.useFuture<int>(
          () async => 40 + ++createCount,
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

    testWidgets('stream should subscribe to Stream function', (tester) async {
      AsyncSnapshot<int>? snapshot;
      int createCount = 0;
      var key = Object();

      await provideIt(tester, (context) {
        snapshot = context.useStream<int>(() {
          return Stream.value(40 + ++createCount);
        }, key: key);
        return GestureDetector(
          key: Key('${snapshot!.data}'),
          onTap: () {
            key = Object();
            (context as Element).markNeedsBuild();
          },
        );
      });
      expect(createCount, 1);
      expect(snapshot, AsyncSnapshot.waiting());

      await tester.pump();
      expect(createCount, 1);
      expect(snapshot, AsyncSnapshot.withData(ConnectionState.done, 41));

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(createCount, 2);
      expect(snapshot, AsyncSnapshot.waiting());

      await tester.pump();
      expect(snapshot, AsyncSnapshot.withData(ConnectionState.done, 42));
      expect(createCount, 2);
    });

    testWidgets('should reset state when key changes', (tester) async {
      int createCount = 0;
      int disposeCount = 0;
      int? key = 1;

      await provideIt(tester, (context) {
        final (value, setValue) = context.useState(0);

        return Column(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  context.provideAsync(
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
                    onTap: () {
                      counter.value++;
                    },
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
      await tester.pumpAndSettle();
      expect(find.byKey(Key('43')), findsOneWidget);

      // Change key
      await tester.tap(find.byKey(Key('change_key')));
      await tester.pump();

      // Old state should be disposed and new state created
      expect(disposeCount, 1);
      expect(createCount, 2);
      expect(
        find.byKey(Key('42')),
        findsOneWidget,
      ); // Counter reset to initial value
    });
  });

  group('ContextReaders', () {
    testWidgets('context should watch previously bound value', (tester) async {
      int buildCount = 0;
      await provideIt(tester, (context) {
        buildCount++;
        context.provide(() => Counter(0));

        return Builder(
          builder: (context) {
            final counter = context.watch<Counter>();
            return GestureDetector(
              key: Key('${counter.value}'),
              onTap: () => counter.value++,
            );
          },
        );
      });

      expect(find.byKey(Key('0')), findsOneWidget);
      expect(buildCount, 1);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(find.byKey(Key('1')), findsOneWidget);
      expect(buildCount, 1);
    });

    testWidgets('select should select value from previously bound value', (
      tester,
    ) async {
      int rootBuildCount = 0;
      int newBuildCount = 0;
      int? selectedValue;

      await provideIt(tester, (context) {
        rootBuildCount++;
        context.provide(() => Counter(0));
        return Builder(
          builder: (context) {
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
          },
        );
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

    testWidgets('listen should listen to previously bound value', (
      tester,
    ) async {
      int listenedValue = 0;
      int value = 0;

      await provideIt(tester, (context) {
        context.provideValue(value);
        context.listen<int>((v) {
          listenedValue = v;
        });
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

      await provideIt(
        tester,
        provide: (context) {
          context.provideAsync(NestedA.init);
          context.provideAsync(NestedB.init);
          context.provide(Nested.new); // needs NestedA and NestedB
          context.provideAsync(Async.init);
          context.provide(Leaf.new); // needs Nested and Async
        },
        (context) {
          value = context.watch<Leaf>();

          return GestureDetector(
            key: ObjectKey(value),
            onTap: () {
              nestedA = context.read();
            },
          );
        },
      );

      expect(value, isNull);
      expect(nestedA, isNull);

      await tester.pumpAndSettle(Duration(seconds: 1));

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
      final counter = context.useState(0);
      count = counter.value;

      return Builder(
        key: Key(count.toString()),
        builder: (context) {
          contexts[counter.value] = context;

          context.provide(
            () => Counter(0),
            lazy: false,
            dispose: (_) => disposed = true,
          );
          return GestureDetector(onTap: () => counter.value++);
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
    InheritedState? state;

    await provideIt(tester, (context) {
      context.provide(() => Counter(0));
      final counter = context.useState(0);
      count = counter.value;

      final scope = ScopeIt.of(context);

      return Builder(
        key: Key(count.toString()),
        builder: (context) {
          contexts[counter.value] = context;
          context.watch<Counter>();
          state = scope.getInheritedBind<Counter>()?.state;

          return GestureDetector(onTap: () => counter.value++);
        },
      );
    });

    expect(count, 0);
    expect(state?.dependents.length, 1);
    expect(state?.dependents.first, contexts[0]);

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    expect(count, 1);
    expect(state?.dependents.length, 1);
    expect(state?.dependents.first, contexts[1]);
    expect(contexts[0] != contexts[1], true);
    expect(contexts[0]!.mounted, false);
    expect(contexts[1]!.mounted, true);
  });

  testWidgets('Bind dependent should be replaced', (tester) async {
    int createCount = 0;
    int disposeCount = 0;

    await provideIt(tester, (context) {
      final counter = context.useState(0);

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

  testWidgets('Provider lifecycle should match widget lifecycle', (
    tester,
  ) async {
    final key = GlobalKey();
    final builderEvents = <String>[];
    final providerEvents = <String>[];

    await provideIt(tester, (context) {
      final (swap, setSwap) = context.useState(false);

      final button = _LifecycleBuilder(
        key: key,
        onInit: () => builderEvents.add('init'),
        onUpdate: () => builderEvents.add('update'),
        onActivate: () => builderEvents.add('activate'),
        onDeactivate: () => builderEvents.add('deactivate'),
        onDispose: () => builderEvents.add('dispose'),
        builder: (context) {
          context._useLifecyleProvider(
            onInit: () => providerEvents.add('init'),
            onUpdate: () => providerEvents.add('update'),
            onActivate: () => providerEvents.add('activate'),
            onDeactivate: () => providerEvents.add('deactivate'),
            onDispose: () => providerEvents.add('dispose'),
          );

          return GestureDetector(onTap: () => setSwap(!swap));
        },
      );

      if (swap) {
        return button;
      }

      return Builder(builder: (_) => button);
    });

    expect(builderEvents, ['init']);
    expect(providerEvents, ['init']);
    builderEvents.clear();
    providerEvents.clear();

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    expect(builderEvents, ['deactivate', 'activate', 'update']);
    expect(providerEvents, ['deactivate', 'activate', 'update']);
  });
}

typedef IntString = (int, String);

class _LifecycleBuilder extends StatefulWidget {
  const _LifecycleBuilder({
    super.key,
    this.onDeactivate,
    this.onUpdate,
    this.onDispose,
    this.onInit,
    this.onActivate,
    this.builder,
  });
  final VoidCallback? onDeactivate;
  final VoidCallback? onDispose;
  final VoidCallback? onInit;
  final VoidCallback? onActivate;
  final VoidCallback? onUpdate;
  final WidgetBuilder? builder;

  @override
  State<_LifecycleBuilder> createState() => _LifecycleBuilderState();
}

class _LifecycleBuilderState extends State<_LifecycleBuilder> {
  @override
  void initState() {
    widget.onInit?.call();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _LifecycleBuilder oldWidget) {
    widget.onUpdate?.call();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void activate() {
    widget.onActivate?.call();
    super.activate();
  }

  @override
  void deactivate() {
    widget.onDeactivate?.call();
    super.deactivate();
  }

  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder?.call(context) ?? Container();
  }
}

extension on BuildContext {
  void _useLifecyleProvider({
    VoidCallback? onInit,
    VoidCallback? onDispose,
    VoidCallback? onActivate,
    VoidCallback? onDeactivate,
    VoidCallback? onUpdate,
  }) {
    return bind(
      _LifecyleProvider(
        onInit: onInit,
        onDispose: onDispose,
        onActivate: onActivate,
        onDeactivate: onDeactivate,
        onUpdate: onUpdate,
      ),
    );
  }
}

class _LifecyleProvider extends HookProvider<void> {
  const _LifecyleProvider({
    this.onInit,
    this.onDispose,
    this.onActivate,
    this.onDeactivate,
    this.onUpdate,
  });
  final VoidCallback? onInit;
  final VoidCallback? onDispose;
  final VoidCallback? onActivate;
  final VoidCallback? onDeactivate;
  final VoidCallback? onUpdate;

  @override
  _ProviderState createState() => _ProviderState();
}

class _ProviderState extends HookState<void, _LifecyleProvider> {
  @override
  String get debugLabel => '_useLifecyleProvider';

  @override
  void initState() {
    provider.onInit?.call();
    super.initState();
  }

  @override
  void didUpdateProvider(_LifecyleProvider oldProvider) {
    provider.onUpdate?.call();
    super.didUpdateProvider(oldProvider);
  }

  @override
  void activate() {
    provider.onActivate?.call();
    super.activate();
  }

  @override
  void deactivate() {
    provider.onDeactivate?.call();
    super.deactivate();
  }

  @override
  void dispose() {
    provider.onDispose?.call();
    super.dispose();
  }

  @override
  void build(BuildContext context) {}
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
