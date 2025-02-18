import 'package:flutter/foundation.dart';
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

    test('async constructors', () {
      final injector = Injector(SomeClass.newAsync);
      expect(injector.type, 'SomeClass');
      expect(injector.rawType, 'Future<SomeClass>');
      expect(injector.params.length, 2);
      expect(injector.params.first.rawType, 'String');
      expect(injector.params.last.rawType, 'int');
    });
  });
}

abstract class _PrivateType {}

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
