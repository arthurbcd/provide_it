/// An abstract class representing a parameter of an instance constructor.
///
/// The [Param] class is used to define a parameter with a given type and
/// whether it is required or optional.
///
/// [rawType] - The type of the parameter.
/// [isRequired] - A boolean indicating if the parameter is required. Defaults to true.
///
/// See: [NamedParam], [PositionalParam].
sealed class Param {
  /// Creates a new instance of the [Param] class.
  const Param(
    this.rawType, {
    this.isRequired = true,
  });

  /// The raw type of the parameter, may contain the nullable operator.
  final String rawType;

  /// Whether the parameter is required.
  final bool isRequired;

  /// Whether the type is nullable.
  bool get isNullable => rawType.endsWith('?');

  /// Whether the type is private.
  bool get isPrivate => rawType.startsWith('_');

  /// The name of the parameter.
  String? get name => null;

  /// The type name without the nullable operator.
  String get type {
    if (isNullable) return rawType.substring(0, rawType.length - 1);
    return rawType;
  }
}

/// Represents a named parameter in an instance constructor.
final class NamedParam extends Param {
  const NamedParam(
    super.rawType, {
    required this.name,
    super.isRequired = false,
  });

  @override
  final String name;

  Symbol get symbol => Symbol(name);
}

/// Represents a positional parameter in an instance constructor.
final class PositionalParam extends Param {
  const PositionalParam(
    super.rawType, {
    required super.isRequired,
  });
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
