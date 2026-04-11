import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provide_it/provide_it.dart';

void main() {
  group('context.provide', () {
    testWidgets('should provide a value manually', (tester) async {
      int? captured;

      await tester.pumpWidget(
        ProvideIt(
          child: Builder(
            builder: (context) {
              context.provide(() => 42);
              return Builder(
                builder: (context) {
                  captured = context.watch<int>();
                  return const SizedBox();
                },
              );
            },
          ),
        ),
      );

      expect(captured, equals(42));
    });

    testWidgets('should call dispose when removed from tree', (tester) async {
      bool disposed = false;
      final toggle = ValueNotifier<bool>(true);

      await tester.pumpWidget(
        ProvideIt(
          child: ValueListenableBuilder<bool>(
            valueListenable: toggle,
            builder: (context, value, child) {
              if (value) {
                return Builder(
                  builder: (context) {
                    context.provide(
                      () => 42,
                      dispose: (_) {
                        disposed = true;
                      },
                    );
                    return Builder(
                      builder: (context) {
                        context.watch<int>();
                        return const SizedBox();
                      },
                    );
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ),
      );

      expect(disposed, isFalse);

      toggle.value = false;
      await tester.pump(Duration(milliseconds: 100));

      expect(disposed, isTrue);
    });

    testWidgets('should support lazy initialization', (tester) async {
      bool created = false;

      await tester.pumpWidget(
        ProvideIt(
          provide: (context) {
            context.provide(() {
              created = true;
              return 42;
            }, lazy: true);
          },
          child: Builder(
            builder: (context) {
              return const SizedBox();
            },
          ),
        ),
      );

      expect(created, isFalse);

      await tester.pumpWidget(
        ProvideIt(
          provide: (context) {
            context.provide(() {
              created = true;
              return 42;
            }, lazy: true);
          },
          child: Builder(
            builder: (context) {
              context.watch<int>();
              return const SizedBox();
            },
          ),
        ),
      );

      expect(created, isTrue);
    });
  });
}
