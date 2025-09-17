import 'package:provide_it/injector.dart';

/// An abstract class representing a parameter of an instance constructor.
///
/// The [Param] class is used to define a parameter with a given type and
/// whether it is required or optional.
///
/// [rawType] - The type of the parameter.
/// [isRequired] - A boolean indicating if the parameter is required.
///
/// See: [NamedParam], [PositionalParam].
sealed class Param {
  /// Creates a new instance of the [Param] class.
  const Param(
    this.rawType, {
    required this.isRequired,
    required this.owner,
  });

  /// The owner of the parameter.
  final Injector owner;

  /// The raw type of the parameter, may contain the nullable operator.
  final String rawType;

  /// Whether the parameter is required.
  final bool isRequired;

  /// The [NamedParam.name] or null.
  String? get name => null;

  /// The [PositionalParam.index] or null.
  int? get index => null;

  /// The type name, without nullable operator.
  /// If [rawType] is a [Future] or [Stream], the subtype is returned.
  String get type {
    if (!isAsync) return rawType.replaceAll('?', '');

    return rawType.split('<').last.split('>').first.replaceAll('?', '');
  }

  /// Whether the type is nullable.
  bool get isNullable => rawType.endsWith('?');

  /// Whether the type is private.
  bool get isPrivate => rawType.startsWith('_');

  /// Whether the type is a future.
  bool get isFuture => rawType.startsWith(futureType);

  /// Whether the type is a stream.
  bool get isStream => rawType.startsWith(streamType);

  /// Whether the type is asynchronous (either a future or a stream).
  bool get isAsync => isFuture || isStream;

  /// Whether the parameter has a default value.
  bool get hasDefaultValue => !isRequired || isNullable;

  /// Whether this [Param] matches the given [value] type.
  /// A type mismatch returns false.
  bool matches(Object? value) {
    if (value == null) return isNullable;

    final valueType = value.runtimeType.toString();
    return valueType == type || valueType == rawType;
  }

  // minified types
  static final futureType = '$Future'.split('<').first;
  static final streamType = '$Stream'.split('<').first;
  static final genericTypes = ['$dynamic', '$Object'];
}

/// Represents a named parameter in an instance constructor.
final class NamedParam extends Param {
  const NamedParam(
    super.rawType, {
    required this.name,
    required super.isRequired,
    required super.owner,
  });

  @override
  final String name;

  Symbol get symbol => Symbol(name);

  @override
  String toString() {
    final param = isRequired ? 'required $rawType' : rawType;
    return 'NamedParam: ${owner.type}({$param $name})';
  }
}

/// Represents a positional parameter in an instance constructor.
final class PositionalParam extends Param {
  const PositionalParam(
    super.rawType, {
    required this.index,
    required super.isRequired,
    required super.owner,
  });

  @override
  final int index;

  @override
  String toString() {
    final param = isRequired ? rawType : '[$rawType]';
    return 'PositionalParam: ${owner.type}($param p$index)';
  }
}

/// Extension on List of Params to provide various filtered iterables.
extension ParamsExtension<T extends Param> on List<T> {
  /// Returns an iterable of named parameters.
  Iterable<NamedParam> get named => whereType();

  /// Returns an iterable of positional parameters.
  Iterable<PositionalParam> get positional => whereType();

  /// Returns an iterable of nullable parameters.
  Iterable<T> get nullable => where((e) => e.isNullable);

  /// Returns an iterable of required parameters.
  Iterable<T> get required => where((e) => e.isRequired);

  /// Returns an iterable of optional parameters.
  Iterable<T> get optional => where((e) => !e.isRequired);

  /// Returns an iterable of non-nullable parameters.
  Iterable<T> get nonNullable => where((e) => !e.isNullable);
}
