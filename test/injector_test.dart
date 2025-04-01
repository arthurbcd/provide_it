import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provide_it/src/injector/injector.dart';
import 'package:provide_it/src/injector/param.dart';

void main() {
  group('Injector', () {
    test('should initialize and parse parameters correctly', () {
      final injector = Injector((String a, {required int b, double? c}) {});
      expect(injector.params.length, 3);
    });

    test('should filter private types correctly', () {
      final injector = Injector((String a, _PrivateType b) {});
      expect(injector.params.length, 1);
      expect(injector.params.first.rawType, 'String');
    });

    test('should return only named parameters', () {
      final injector = Injector((String a, {required int b, double? c}) {});
      expect(injector.namedParams.length, 2);
      expect(injector.namedParams.first.rawType, 'int');
      expect(injector.namedParams.last.rawType, 'double?');
    });

    test('should return only optional parameters', () {
      final injector = Injector((String a, {required int b, double? c}) {});
      expect(injector.params.optional.length, 1);
      expect(injector.params.optional.first.rawType, 'double?');
    });

    test('should return only positional parameters', () {
      final injector = Injector((String a, int b) {});
      expect(injector.positionalParams.length, 2);
      expect(injector.positionalParams.first.rawType, 'String');
      expect(injector.positionalParams.last.rawType, 'int');
    });

    test('should parse SomeClass.new constructor correctly', () {
      final injector = Injector(SomeClass.new);
      expect(injector.params.length, 2);
      expect(injector.params.first.rawType, 'String');
      expect(injector.params.last.rawType, 'int');
    });

    test('should parse SomeClass.named constructor correctly', () {
      final injector = Injector(SomeClass.named);
      expect(injector.namedParams.length, 2);
      expect(injector.namedParams.first.rawType, 'String');
      expect(injector.namedParams.last.rawType, 'int');
    });

    test('should parse SomeClass.staticConstructor correctly', () {
      final injector = Injector(SomeClass.staticConstructor);
      expect(injector.params.length, 2);
      expect(injector.params.first.rawType, 'String');
      expect(injector.params.last.rawType, 'int');
    });

    test('should parse getSomeClass function correctly', () {
      final injector = Injector(getSomeClass);
      expect(injector.params.length, 3);
      expect(injector.params.first.rawType, 'String');
      expect(injector.params[1].rawType, 'int');
      expect(injector.params.last.rawType, 'int?');
    });

    test('should parse SomeClass.withOptionalParams constructor correctly', () {
      final injector = Injector(SomeClass.withOptionalParams);
      expect(injector.hasParams, true);
      expect(injector.params.length, 3);
      expect(injector.params.first.rawType, 'String');
      expect(injector.params[1].rawType, 'String?');
      expect(injector.params.last.rawType, 'int?');
    });

    test('param functions', () {
      void create(VoidCallback fn, ValueSetter<int?> vs) {}
      final injector = Injector(create);
      expect(injector.params.length, 2);
      expect(injector.params.first.rawType, '() => void');
      expect(injector.params.last.rawType, '(int?) => void');
    });

    test('should parse ComplexClass constructor correctly', () {
      final injector = Injector(ComplexClass.new);
      expect(injector.params.length, 20);
      expect(injector.params[0].rawType, 'String');
      expect(injector.params[1].rawType, 'int');
      expect(injector.params[2].rawType, 'double');
      expect(injector.params[3].rawType, 'bool');
      expect(injector.params[4].rawType, 'List<String>');
      expect(injector.params[5].rawType, 'Map<String, int>');
      expect(injector.params[6].rawType, 'Set<double>');
      expect(injector.params[7].rawType, 'DateTime');
      expect(injector.params[8].rawType, 'Duration');
      expect(injector.params[9].rawType, 'Uri');
      expect(injector.params[10].rawType, 'BigInt');
      expect(injector.params[11].rawType, 'RegExp');
      expect(injector.params[12].rawType, 'Function');
      expect(injector.params[13].rawType, '() => Future<void>');
      expect(injector.params[14].rawType, 'Stream<int>');
      expect(injector.params[15].rawType, 'Iterable<String>');
      expect(injector.params[16].rawType, 'Runes');
      expect(injector.params[17].rawType, 'Symbol');
      expect(injector.params[18].rawType, 'Type');
      expect(injector.params[19].rawType, 'dynamic');
    });
  });

  test('should parse SomeClass.withTuples constructor correctly', () {
    final injector = Injector(SomeClass.withRecords);
    expect(injector.params.length, 1);
    expect(injector.params.first.rawType, '(String, int)');
  });

  test('should parse SomeClass.complexRecord constructor correctly', () {
    final injector = Injector(SomeClass.complexRecord);
    expect(injector.params.length, 7);
    expect(
      injector.params[0].rawType,
      '(String, int, double, bool, List<String>)',
    );
    expect(
      injector.params[1].rawType,
      '(Map<String, int>, Set<double>, DateTime, Duration, Uri, BigInt)',
    );
    expect(injector.params[2].rawType, 'RegExp');
    expect(injector.params[3].rawType, 'Function');
    expect(injector.params[4].rawType, '() => Future<void>');
    expect(
      injector.params[5].rawType,
      '(Stream<int>?, Iterable<String>?, Runes?)',
    );
    expect(injector.params[6].rawType, '(Symbol?, Type?, dynamic)?');
  });

  group('test type', () {
    test('should determine type of create function correctly for dynamic', () {
      final injector = Injector((dynamic a) => a);
      expect(injector.type, 'dynamic');
    });

    test('should determine type of create function correctly for specific type',
        () {
      final injector = Injector((String a) => a);
      expect(injector.type, 'String');
    });

    test('should determine type of create function correctly for function type',
        () {
      final injector = Injector((String Function(int) a) => a);
      expect(injector.type, '(int) => String');
    });

    test('should determine type of create function correctly for complex type',
        () {
      final injector = Injector((Map<String, List<int>> a) => a);
      expect(injector.type, 'Map<String, List<int>>');
    });

    test('async constructors', () async {
      locator(Param param) {
        if (param.type == 'String') return 'a';
        if (param.type == 'int') return 1;
        return null;
      }

      final injector = Injector(SomeClass.newAsync, locator: locator);
      expect(injector.type, 'SomeClass');
      expect(injector.rawType, 'Future<SomeClass>');

      final future = injector();
      expect(future, isA<Future>());

      final value = await future;
      expect(value, isA<SomeClass>());
    });

    test('sync constructors with async params', () async {
      locator(Param param) {
        if (param.type == 'String') return Future.value('a');
        if (param.type == 'int') return Future.value(1);
        return null;
      }

      final injector = Injector(SomeClass.new, locator: locator);
      expect(injector.type, 'SomeClass');
      expect(injector.rawType, 'SomeClass');

      final future = injector();
      expect(future, isA<Future>());

      final value = await future;
      expect(value, isA<SomeClass>());
    });

    test('async constructors with async params', () async {
      locator(Param param) {
        if (param.type == 'String') return Future.value('a');
        if (param.type == 'int') return Future.value(1);
        return null;
      }

      final injector = Injector(SomeClass.newAsync, locator: locator);
      expect(injector.type, 'SomeClass');
      expect(injector.rawType, 'Future<SomeClass>');

      final future = injector();
      expect(future, isA<Future>());

      final value = await future;
      expect(value, isA<SomeClass>());
    });

    test('nested async constructors/params', () async {
      final map = {
        'Leaf': Injector(Leaf.new), // needs Nested and Async
        'Async': Injector(Async.init), // -
        'Nested': Injector(Nested.new), // needs NestedA and NestedB
        'NestedA': Injector(NestedA.init), // -
        'NestedB': Injector(NestedB.init), // -
      };
      locator(Param param) => map[param.type]?.call();
      Injector.defaultLocator = locator;

      final injector = Injector(Leaf.new);
      expect(injector.type, '$Leaf');
      expect(injector.rawType, '$Leaf');

      final future = injector();
      expect(future, isA<Future>());

      final value = await future;
      expect(value, isA<Leaf>());
      expect(value.a, isA<Nested>());
      expect(value.b, isA<Async>());
      expect(value.a.a, isA<NestedA>());
      expect(value.a.b, isA<NestedB>());
    });

    test('should manually provide some parameters', () {
      final injector = Injector(({String? a = '', int? b}) => (a, b));
      expect(injector(), ('', null));
      expect(injector({'a': 'a'}), ('a', null));
      expect(injector({'b': 1}), ('', 1));
      expect(injector({'a': 'a', 'b': 1}), ('a', 1));
    });

    test('should inject by name, position or type', () {
      final injector = Injector(Text.new, parameters: {
        '0': 'Hello',
        'style': TextStyle(),
        '$TextAlign': TextAlign.center,
      });

      final result = injector();
      expect(result, isA<Text>());

      final text = result as Text;
      expect(text.data, 'Hello');
      expect(text.style, isA<TextStyle>());
      expect(text.textAlign, TextAlign.center);
    });

    test('should inject positional & default typed parameters', () {
      final injector = Injector(DateTime.new, parameters: {
        '0': 2018, // by position
        '1': 12,
        '2': 4,
        '3': 18,
        '4': 30,
        '$int': 60, // by type
      });

      final result = injector();
      expect(result, isA<DateTime>());
      expect(result, DateTime(2018, 12, 4, 18, 30, 60, 60, 60));
    });

    test('throws InjectorError', () async {
      final sizeA = await Injector(Size.new)({
        '0': 100.0,
        '1': 200.0,
      });
      expect(sizeA, isA<Size>());

      final sizeB = Injector(Size.new);
      expect(sizeB.call, throwsA(isA<InjectorError>()));
    });

    test('throws InjectorError', () async {
      final sizeA = Injector<Size>((double a, double b) async => Size(a, b))({
        '0': 100.0,
        '1': 200.0,
      });
      expect(sizeA, isA<Future<Size>>());

      final awaitA = await sizeA;
      expect(awaitA, isA<Size>());
    });

    test('Injector.isAsync resolves correctly', () async {
      final injector = Injector<Size>(() async => Size(0, 0));
      expect(injector.isAsync, true);

      final sizeA = injector();
      expect(sizeA, isA<Future<Size>>());

      final awaitA = await sizeA;
      expect(awaitA, isA<Size>());
    });

    test('incorrect void async abstractions throws', () async {
      final injector = Injector<Offset>(() async => Size(0, 0));

      expect(injector.isAsync, true);
      expect(injector.hasParams, false);
      expect(injector.call, throwsA(isA<TypeError>()));
    });
  });
}

abstract class _PrivateType {}

class NestedA {
  NestedA(this.value);
  final String value;

  static Future<NestedA> init() async {
    await Future.delayed(Duration(seconds: 1));
    return NestedA('a');
  }
}

class NestedB {
  NestedB(this.value);
  final int value;

  static Future<NestedB> init() async {
    await Future.delayed(Duration(seconds: 1));
    return NestedB(0);
  }
}

class Nested {
  Nested(this.a, this.b);
  final NestedA a;
  final NestedB b;
}

class Async {
  Async(this.value);
  final bool value;

  static Future<Async> init() async {
    await Future.delayed(Duration(seconds: 1));
    return Async(true);
  }
}

class Leaf {
  Leaf(this.a, this.b);
  final Nested a;
  final Async b;
}

class SomeClass {
  SomeClass(this.a, this.b);

  SomeClass.named({required this.a, required this.b});
  final String a;
  final int b;

  static Future<SomeClass> newAsync(String a, int b) async {
    return SomeClass(a, b);
  }

  static SomeClass staticConstructor(String a, int b) {
    return SomeClass(a, b);
  }

  static SomeClass withOptionalParams(String a, [String? b, int? c]) {
    return SomeClass(a, c ?? 0);
  }

  static SomeClass withRecords((String a, int b) record) {
    return SomeClass(record.$1, record.$2);
  }

  static SomeClass complexRecord(
    (
      String a,
      int b,
      double c,
      bool d,
      List<String> e,
    ) r1,
    (
      Map<String, int> f,
      Set<double> g,
      DateTime h,
      Duration i,
      Uri j,
      BigInt k,
    ) r2, {
    required RegExp l,
    required Function m,
    required Future<void> Function() n,
    required (Stream<int>? o, Iterable<String>? p, Runes? q) r3,
    (Symbol? r, Type? s, dynamic t)? r4,
  }) {
    return SomeClass('a', 0);
  }
}

SomeClass getSomeClass(String a, int b, {required int? c}) {
  return SomeClass(a, b);
}

class ComplexClass {
  ComplexClass(
    this.a,
    this.b,
    this.c,
    this.d,
    this.e,
    this.f,
    this.g,
    this.h,
    this.i,
    this.j,
    this.k,
    this.l,
    this.m,
    this.n,
    this.o,
    this.p,
    this.q,
    this.r,
    this.s,
    this.t,
  );

  final String a;
  final int b;
  final double c;
  final bool d;
  final List<String> e;
  final Map<String, int> f;
  final Set<double> g;
  final DateTime h;
  final Duration i;
  final Uri j;
  final BigInt k;
  final RegExp l;
  final Function m;
  final Future<void> Function() n;
  final Stream<int> o;
  final Iterable<String> p;
  final Runes q;
  final Symbol r;
  final Type s;
  final dynamic t;
}
