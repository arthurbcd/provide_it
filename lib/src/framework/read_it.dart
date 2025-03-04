part of '../framework.dart';

@Deprecated('Use `ReadIt` instead.')
typedef GetIt = ReadIt;

sealed class ReadIt {
  /// Creates a fresh instance of [ReadIt].
  ///
  /// Useful for [ProvideIt.scope]. Isolating it from the global [instance] scope.
  factory ReadIt.asNewInstance() => ProvideItScope();
  static final ReadIt instance = ProvideItScope();
  static final I = instance;

  /// Binds a [ProvideRef] without context.
  R bind<R, T>(ProvideRef<T> ref);

  /// Reads the value of a [Ref].
  T read<T>({Object? key});

  /// Writes the value of a [Ref].
  void write<T>(T value, {Object? key});

  /// Async reads the value of a [AsyncRef].
  FutureOr<T> readAsync<T>({Object? key});

  /// The future when all [AsyncRefState.isReady] are completed.
  FutureOr<void> allReady();

  /// The future when [T] is ready.
  FutureOr<void> isReady<T>({Object? key});
}

extension ReadItProviders on ReadIt {
  /// Sintatic sugar for [ReadIt.read].
  T call<T>({Object? key}) => read<T>(key: key);

  /// Immediately calls [create] and provides its value. See [ProvideRef].
  void provide<T>(
    Function create, {
    void dispose(T value)?,
    Map<Symbol, dynamic>? parameters,
    Object? key,
  }) {
    bind(ProvideRef<T>(
      key: key,
      create,
      dispose: dispose,
      parameters: parameters,
      lazy: false,
    ));
  }

  /// Calls [create] on first read and then provides its value. See [ProvideRef].
  void provideLazy<T>(
    Function create, {
    void dispose(T value)?,
    Map<Symbol, dynamic>? parameters,
    Object? key,
  }) {
    bind(ProvideRef(
      key: key,
      create,
      dispose: dispose,
      parameters: parameters,
      lazy: true,
    ));
  }

  /// Calls [create] on every read and returns its value. See [ProvideRef].
  void provideFactory<T>(
    Function create, {
    void dispose(T value)?,
    Map<Symbol, dynamic>? parameters,
    Object? key,
  }) {
    bind(ProvideRef(
      key: key,
      create,
      dispose: dispose,
      parameters: parameters,
      factory: true,
    ));
  }

  /// Directly provides a value. See [ProvideRef.value].
  T provideValue<T>(
    T value, {
    Object? key,
  }) {
    return bind(ProvideRef.value(
      value,
      key: key,
    ));
  }
}

@Deprecated('Use `ReadIt` instead.')
extension GetItProviders on GetIt {
  @Deprecated('Use `ReadIt.read` instead.')
  T get<T>({Object? key}) => read<T>(key: key);

  @Deprecated('Use `ReadIt.readAsync` instead.')
  FutureOr<T> getAsync<T>({Object? key}) => readAsync<T>(key: key);

  @Deprecated('Use `ReadIt.provide` instead.')
  void registerSingleton<T>(
    T create(), {
    void dispose(T value)?,
    Object? instanceName,
  }) =>
      provide<T>(create, dispose: dispose, key: instanceName);

  @Deprecated('Use `ReadIt.provide` instead.')
  void registerSingletonAsync<T>(
    Future<T> create(), {
    void dispose(T value)?,
    Object? instanceName,
  }) =>
      provide<T>(create, dispose: dispose, key: instanceName);

  @Deprecated('Use `ReadIt.provideLazy` instead.')
  void registerLazySingleton<T>(
    T create(), {
    void dispose(T value)?,
    Object? instanceName,
  }) =>
      provideLazy<T>(create, dispose: dispose, key: instanceName);

  @Deprecated('Use `ReadIt.provideLazy` instead.')
  void registerLazySingletonAsync<T>(
    Future<T> Function() create, {
    void dispose(T value)?,
    Object? instanceName,
  }) =>
      provideLazy<T>(create, dispose: dispose, key: instanceName);

  @Deprecated('Use `ReadIt.provideFactory` instead.')
  void registerFactory<T>(
    T create(), {
    void dispose(T value)?,
    Object? instanceName,
  }) =>
      provideFactory<T>(create, dispose: dispose, key: instanceName);

  @Deprecated('Use `ReadIt.provideFactory` instead.')
  void registerFactoryAsync<T>(
    Future<T> create(), {
    void dispose(T value)?,
    Object? instanceName,
  }) =>
      provideFactory<T>(create, dispose: dispose, key: instanceName);
}
