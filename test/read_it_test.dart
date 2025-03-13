import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provide_it/provide_it.dart';

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

void main() {
  group('ReadIt', () {
    test('should bind and read a value', () {
      final readIt = ReadIt.asNewInstance();
      readIt.provide(Counter.new);
      final value = readIt.read<Counter>().value;
      expect(value, 42);
    });

    test('should provide a value directly', () {
      final readIt = ReadIt.asNewInstance();
      readIt.provideValue(42);
      final value = readIt.read<int>();
      expect(value, 42);
    });

    test('should provide a lazy value', () {
      final readIt = ReadIt.asNewInstance();
      int? lazyValue;
      readIt.provide<int>(() => lazyValue = 42, lazy: true);
      expect(lazyValue, isNull);

      final value = readIt.read<int>();
      expect(value, 42);
      expect(lazyValue, 42);
    });

    test('should be all ready', () async {
      final readIt = ReadIt.asNewInstance();
      readIt.provide(() async => 42);
      expect(() => readIt.read<int>(), throwsStateError);
      await readIt.allReady();
      expect(readIt.read<int>(), 42);
    });

    test('should be ready for specific type', () async {
      final readIt = ReadIt.asNewInstance();
      readIt.provide(() async => 42);
      expect(() => readIt.read<int>(), throwsStateError);
      await readIt.isReady<int>();
      expect(readIt.read<int>(), 42);
    });

    test('should be read asychronously', () async {
      final readIt = ReadIt.asNewInstance();
      readIt.provide(() async => 42);
      expect(() => readIt.read<int>(), throwsStateError);
      expect(await readIt.readAsync<int>(), 42);
    });
  });
}
