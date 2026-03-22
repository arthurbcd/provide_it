import 'package:benchmark_harness/benchmark_harness.dart';

// As extensões corrigidas
extension StringTypeExt on Type {
  String get asString => toString();
}

extension SymbolTypeExt on Type {
  Symbol get asSymbol => Symbol(toString());
}

// 1. Cenários de Criação
class StringCreationBenchmark extends BenchmarkBase {
  StringCreationBenchmark() : super('1. Criacao: Type -> String');
  late Type type;

  @override
  void setup() => type = int;

  @override
  void run() {
    final _ = type.asString;
  }
}

class SymbolCreationBenchmark extends BenchmarkBase {
  SymbolCreationBenchmark() : super('2. Criacao: Type -> Symbol');
  late Type type;

  @override
  void setup() => type = int;

  @override
  void run() {
    final _ = type.asSymbol;
  }
}

// 2. Cenários de Busca em Map (O uso real no DI)
class StringMapBenchmark extends BenchmarkBase {
  StringMapBenchmark() : super('3. Lookup Map: String Key');
  late Map<String, String> map;
  late Type type;

  @override
  void setup() {
    type = int;
    map = {type.asString: 'dependencia'};
  }

  @override
  void run() {
    final _ = map[type.asString];
  }
}

class SymbolMapBenchmark extends BenchmarkBase {
  SymbolMapBenchmark() : super('4. Lookup Map: Symbol Key');
  late Map<Symbol, String> map;
  late Type type;

  @override
  void setup() {
    type = int;
    map = {type.asSymbol: 'dependencia'};
  }

  @override
  void run() {
    final _ = map[type.asSymbol];
  }
}

class RawTypeMapBenchmark extends BenchmarkBase {
  RawTypeMapBenchmark() : super('5. Lookup Map: Raw Type Key (Metal)');
  late Map<Type, String> map;
  late Type type;

  @override
  void setup() {
    type = int;
    map = {type: 'dependencia'};
  }

  @override
  void run() {
    final _ = map[type];
  }
}

void main() {
  print('Iniciando Benchmarks...\n');
  StringCreationBenchmark().report();
  SymbolCreationBenchmark().report();
  print('---');
  StringMapBenchmark().report();
  SymbolMapBenchmark().report();
  RawTypeMapBenchmark().report();
}
