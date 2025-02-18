import 'dart:async';

import 'package:flutter/foundation.dart';

import 'param.dart';

export 'injector.dart';

typedef ParamLocator = FutureOr Function(Param param);
typedef NamedLocator = FutureOr Function(NamedParam param);

/// A class that injects dependencies into a function.
///
/// You must provide [T] if you wanna inject an abstract class.
/// Otherwise, it will be inferred from the [create] function.
class Injector<T> {
  /// Creates a new instance of [Injector].
  ///
  /// The [create] function is used to extract the constructor parameters.
  /// All parameters are lazily resolved.
  ///
  /// - [locator] is used to locate the dependencies by type.
  /// - [parameters] is used to manually provide a dependency by name or type.
  /// - [ignorePrivateTypes] is used to ignore private types.
  ///
  /// A default [ParamLocator] can be set using [Injector.defaultLocator].
  ///
  /// Example:
  /// ```dart
  /// final vmInjector = Injector(ViewModel.new, parameters: pathParameters);
  /// final viewModel = vmInjector(parameters: {'someId': 1});
  /// ```
  ///
  Injector(
    this.create, {
    this.parameters,
    ParamLocator? locator,
    this.ignorePrivateTypes = true,
  }) : locator = locator ?? defaultLocator;

  /// The default locator to use while injecting.
  ///
  /// This is used when [locator] is not provided.
  static ParamLocator? defaultLocator;

  /// The [T] function to inject.
  final Function create;

  /// The locate args by [Param] while injecting.
  final ParamLocator? locator;

  /// The arguments by name/type [String] to use while injecting.
  final Map<String, dynamic>? parameters;

  /// Whether to ignore private types.
  final bool ignorePrivateTypes;

  /// The return type of [create] function.
  ///
  /// If [create] is a [Future] or [Stream], the subtype is returned.
  late final type = _type();

  /// The type of [create] function.
  late final rawType = _rawType();

  String _type() {
    if (T != dynamic) return T.type;

    if (rawType.startsWith('Future') || rawType.startsWith('Stream')) {
      return rawType.split('<').last.split('>').first.replaceAll('?', '');
    }

    return rawType.replaceAll('?', '');
  }

  String _rawType() {
    const types = [dynamic, Future, Stream];
    if (!types.contains(T)) return T.toString();

    final typeLine = _createTexts.last.replaceFirst(' => ', '');
    final buffer = StringBuffer();
    var nestedLevel = 0;

    for (final char in typeLine.split('')) {
      if (nestedLevel == 0 && char == ' ') {
        final type = buffer.toString();
        if (!type.endsWith(')') && !type.endsWith('=>')) return type;
      }
      if (char == '<' || char == '(') nestedLevel++;
      if (char == '>' || char == ')') nestedLevel--;
      buffer.write(char);
    }

    return buffer.toString();
  }

  /// Whether [create] has parameters.
  /// If false, we can treat it as a [ValueGetter] of [T].
  late final hasParams = !_createText.startsWith('() => ');

  /// All parameters of the constructor.
  List<Param> get params => List.of(_params);

  /// Named parameters of the constructor.
  List<NamedParam> get namedParams => List.of(_named);

  /// Positional parameters of the constructor.
  List<PositionalParam> get positionalParams => List.of(_positional);

  /// Performs the injection.
  ///
  /// You can add locators on top of pre-existing ones. No overriding.
  /// - Use [locator] to locate args by [Param].
  /// - Use [parameters] to manually provide args by name/type [String].
  ///
  /// Example:
  /// ```dart
  /// final userInjector = Injector(User.new, parameters: userJson);
  /// final user = userInjector(parameters: {'id': 1, 'Role': Role.admin});
  /// ```
  ///
  FutureOr<T> call({
    ParamLocator? locator,
    Map<String, dynamic>? parameters,
  }) {
    final waitFor = <Future>[];

    locate(Param param) {
      var arg = parameters?[param.type];
      final errors = [];

      try {
        if (locator != null) {
          arg ??= locator(param);
        }
      } catch (e) {
        errors.add(e);
      }

      try {
        if (this.locator != null) arg ??= this.locator!(param);
      } catch (e) {
        errors.add(e);
      }

      if (arg == null && !param.isNullable && param.isRequired) {
        final t = arg.runtimeType;

        throw ArgumentError.notNull(
          'Injector got $t. Expected ${param.type}\n${errors.join('\n')}',
        );
      }

      return arg;
    }

    final positionalArgs = <int, dynamic>{};
    for (final (i, param) in _positional.indexed) {
      final arg = locate(param);
      if (arg == null && !param.isNullable && !param.isRequired) continue;

      if (arg is Future && !param.isFuture) {
        waitFor.add(Future(() async => positionalArgs[i] = await arg));
      } else {
        positionalArgs[i] = arg;
      }
    }

    final namedArgs = <Symbol, dynamic>{};
    for (final param in _named) {
      var arg = parameters?[param.name] ?? locate(param);
      if (arg == null && !param.isNullable && !param.isRequired) continue;

      if (arg is Future && !param.isFuture) {
        waitFor.add(Future(() async => namedArgs[param.symbol] = await arg));
      } else {
        namedArgs[param.symbol] = arg;
      }
    }

    if (waitFor.isNotEmpty) {
      return Future.wait(waitFor).then(
        (_) =>
            Function.apply(create, positionalArgs.toListByIndex(), namedArgs),
      );
    }

    final value =
        Function.apply(create, positionalArgs.toListByIndex(), namedArgs);

    if (value is! T) {
      final t = value.runtimeType;
      throw ArgumentError.value(value, null, 'Injector got $t. Expected $T');
    }

    return value;
  }

  // lazy cache
  late final _createText = create.toString();
  late final _createTexts = _createText.splitBetween('(', ')')..removeAt(0);
  late final _input = _createTexts.first;
  late final _namedInput = _input.firstMatch(r'\{(.+)\}')?.group(1);
  late final _positionalInput =
      _namedInput != null ? _input.replaceAll('{$_namedInput}', '') : _input;

  // lazy params
  late final _params = [..._positional, ..._named];
  late final _named = _namedParams();
  late final _positional = _positionalParams();

  List<NamedParam> _namedParams() {
    if (!hasParams) return [];
    if (_namedInput == null) return [];

    final list = <NamedParam>[];
    final paramList = splitParams(_namedInput);

    for (final paramText in paramList) {
      final parts = paramText.split(' '); // ex: required Type name
      final isRequired = parts.remove('required');
      final name = parts.removeLast();
      final type = parts.join(' '); // for: () => void

      if (ignorePrivateTypes && type.startsWith('_')) continue;

      list.add(NamedParam(type, name: name, isRequired: isRequired));
    }

    return list;
  }

  List<PositionalParam> _positionalParams() {
    if (!hasParams) return [];
    if (_positionalInput.isEmpty) return [];

    final list = <PositionalParam>[];
    final paramList = splitParams(_positionalInput);

    for (final paramText in paramList) {
      var isRequired = true;
      var type = paramText;

      if (paramText.startsWith('[')) {
        isRequired = false;
        type = paramText.substring(1).trim();
      }

      if (paramText.endsWith(']')) {
        isRequired = true;
        type = paramText.substring(0, paramText.length - 1).trim();
      }

      if (ignorePrivateTypes && type.startsWith('_')) continue;

      list.add(PositionalParam(type, isRequired: isRequired));
    }

    return list;
  }

  List<String> splitParams(String input) {
    final list = <String>[];
    final currentParam = StringBuffer();
    var nestedLevel = 0;

    void addCurrent() {
      if (currentParam.isNotEmpty) {
        final param = currentParam.toString().trim();

        if (param.isNotEmpty) list.add(param);
        currentParam.clear();
      }
    }

    for (var i = 0; i < input.length; i++) {
      final char = input[i];

      if (char == ',' && nestedLevel == 0) {
        addCurrent();
      } else {
        // handle subtypes & records
        if (char == '<' || char == '(') nestedLevel++;
        if (char == '>' || char == ')') nestedLevel--;
        if (nestedLevel < 0) nestedLevel = 0;
        currentParam.write(char);
      }
    }
    addCurrent(); // add the last param, if any

    return list;
  }
}

extension on String {
  RegExpMatch? firstMatch(String regex) => RegExp(regex).firstMatch(this);
}

extension<T> on Map<int, T> {
  List<T> toListByIndex() {
    final list = entries.toList();
    list.sort((a, b) => a.key.compareTo(b.key));
    return list.map((e) => e.value).toList();
  }
}

extension SplitBetweenExtension on String {
  List<String> splitBetween(String start, String end) {
    if (start.length != 1 || end.length != 1) {
      throw ArgumentError('Delimiter must be a single character');
    }

    final startIndex = indexOf(start);
    if (startIndex == -1) throw ArgumentError('Start delimiter not found');

    int balance = 1;
    int currentIndex = startIndex + 1;

    // Find matching closing delimiter
    while (currentIndex < length && balance > 0) {
      if (this[currentIndex] == start) balance++;
      if (this[currentIndex] == end) balance--;
      currentIndex++;
    }

    if (balance != 0) throw ArgumentError('Unbalanced delimiters');

    return [
      substring(0, startIndex), // Before
      substring(startIndex + 1, currentIndex - 1), // Between
      substring(currentIndex) // After
    ];
  }
}

extension TypeExtension on Type {
  String get type => toString().replaceAll('?', '');
}
