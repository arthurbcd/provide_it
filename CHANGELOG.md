# Changelog

## 0.21.1

- Fix missing `dependOnBind` on `Bind.activate`.

## 0.21.0

- Added `Param.matches`.
- Added `Param.isStream` & `Param.isAsync`.
- Fix `Param` to handle minified types.
- Revert `BuildContext.read/watch` deprecations.

## 0.20.0

- Added `BuildContext.of({bool? listen})`.
- Deprecated `BuildContext.read`.
- Deprecated `BuildContext.watch`.
- Added `Loading/Error/Null` exceptions for bind providers.

## 0.19.2

- Improved error handling for missing parameters in `Injector`.

## 0.19.1

- Now returns `null` when `Injector.locator` throws, debug prints error.

## 0.19.0

- Added `ProvideIt.restart` to restart app subtree and it's bind dependencies.
- Added `ProvideIt.override` & `context.override`.
- Now handles `ProvideIt.provide` errors in `ProvideIt.errorBuilder`.
- Removes `Ref` top level binding to focus solely on `Type` bindings.
- Fixed `Ref.didUpdateRef` to callback `oldRef` correctly.
- Improved exceptions.

## 0.18.7

- Further improvements to `AsyncBind`.

## 0.18.6

- Fixed `AsyncBind` to prevent notifying during build.

## 0.18.5

- Fixed `Stream.empty` throwing `TypeError` instead of setting `AsyncSnapshot.error`.

## 0.18.4

- Fixed `Watcher` resolution order.

## 0.18.3

- Fixed `Bind` replacement order when `Ref.key` changes.

## 0.18.2

- Added `Bind.deactivated` to check if a bind called deactivate.
- Now duplicate binds asserts checks only non-deactivated binds.

## 0.18.1

- Fixed error when reading minified types in web release mode.

## 0.18.0

- `RefState` is now simply `Bind`.
- Fixed `Injector` throwing `ArgumentError` in web release mode.

## 0.17.1

- `AsyncRef` now resolves early stream/future creation errors.

## 0.17.0

- Removed `ReadItMixin`. Use `ReadIt` only.
- Removed `ReadIt.bind`. Use `Ref.bind` only.
- Removed `ReadIt.I` & `get_it` deprecations.
- Improved `RefWidget.dispose` to callback an inactive context instead of an unmounted.
- Improved setup errors/asserts.
- Added tests.

## 0.16.1

- Fixed `Injector.isAsync` to resolve abstractions correctly.
- Changed `InjectorError` to throw exclusively on `Param` injection errors.
- Fixed missing `listen<T>` type.
- Updated example.
- Added tests.

## 0.16.0

- Added `Injector.returnType`.
- Injector now throws `InjectorError`.
- Improved `context.provide` injection asserts.
- Improved `provide` to ignore notifications before first read.
- Updated example.

## 0.15.0

- `Injector.parameters` is now simply `Map<String, dynamic>`.
- Added assertion to prevent async marked `ProvideIt.provide`.
- Added `ReadIt.mounted`.
- Fix `ProvideIt` to correctly disposes on test.
- Fix duplicate scopes when using nested `ProvideIt`.
- Updated `README.md`.
- Added tests.

## 0.14.0

- Now `Injector` is fully scoped.
- Replaced `ProvideIt.namedLocator` for `ProvideIt.locator`.
- Added `ProvideIt.parameters`.
- Improved `Injector.parameters` to locate by `String` (named), `int` (positional) or `Type` (either).
- Improved `ReadIt.reload` assertions.
- Updated `README.md`.

## 0.13.0

- Removed `provideLazy`. Use `provide(lazy: true)`.
- Removed `provideFactory`. Use `provide` in context scopes.
- Removed `shouldNotifySelf`. Use `watch` explicitly.
- Removed `RefState.bind`. Use `ReadIt.bind` new signature.
- Moved `RefState.create` to `AsyncRefState.create`.
- Moved `BuildContext.vsync` to `CreateContext.vsync`.
- Updated `CreateRef.create` to use `CreateContext` extension type.
- Added `ProvideRef.lazyPredicate` fallback behavior when `lazy=null`. Defaults to `lazy=true`, unless the provider is async.
- Added `ValueListenableProvider` migration.
- Improved hot-reload experience when removing single binds.
- Updated `README.md`.

Thanks to `almeidajuan`.

## 0.12.0

- Removed `RefState.tryDispose`.
- Renamed `context.findRefStateOfType` to `context.getRefStateOfType` (as it's O(1)).
- Renamed `notifyDependents` to `notifyObservers` (reflects `Watcher` api).
- Limited `write` to `ValueRef.write`.
- Improved `Injector` type resolution.
- Added `ValueRef.debounce`.
- Added `ValueRef.throttle`.

## 0.11.0

- Improved `Watcher` api & docs.
- Improved hot-reload experience when changing binds.
- Updated `README.md`.

## 0.10.0

- Added `context.write(T)`.
- Added support to use `Ref` as top-level member.
- Improved `RefState`, now overrides `T? value`.
- Improved `RefState.dispose(T)` to not be called when a lazy was not yet used.
- Improved errors/asserts.

## 0.9.0

- Improved `AsyncRefState.load` to unsubscribe old futures/streams.
- Removed the need for `BuildContext` in `RefState.bind`. Simply use `Ref.context`, instead.
- Now it's possible to read using T?, if not found, returns null instead of throwing.
- Exposed `RefState.dependents` api.
- Exposed `BuildContext.findRefStateOfType` api.
- Improved asserts.
- Added tests.

## 0.8.2

- Improved [RefState.removeDependent]. Now O(1).
- Added internal [BuildContext.dependOnRefState].

## 0.8.1

- Removed unnecessary `read` dependency on `ProvideIt`.
- Improved context dependency asserts.

## 0.8.0

- Changed [Injector.parameters] to use [Symbol] instead of [String].
- Improved [ReadIt] type resolution.
- Improved [Injector.toString]
- Improved [Param.toString].
- Improved async injections.
- Updated example.
- Updated `README.md`.
- Bump min constraints to Dart 3.3.0 / Flutter 3.19.0.

## 0.7.0

- Improved lookup: O(1) for uniques binds, and O(n) for duplicates.
- Removed the need for `BuildContext` in `RefState.read`.
- Added `ReadIt` for dependency injection outside of widgets.
- Added `GetIt` migrations.
- Added `Benchmark` example.
- Added unit-tests & widget-tests.

## 0.6.0

- Added `context.init`.
- Added `context.dispose`.
- Added `AsyncRef.allReady`.
- Added `AsyncRef.allReadySync`.
- Added `AsyncRef.isReady`.
- Added `AsyncRef.isReadySync`.

## 0.5.0

- Added `MultiProvider` migration.
- Added `Consumer` migration.
- Added `ChangeNotifierProvider` migration.
- Added `ListenableProvider` migration.
- Added `ChangeNotifierWatcher`.
- Improved abstractions injection.
- Updated `README.md`.

## 0.4.0

- Added `AsyncRefState.ready()`.
- Added `context.readAsync()`.
- Added `AsyncSnapshotExtension`: when/maybeWhen & getters.
- Added `Param.isFuture`.
- Improved `FutureRef` to resolve immediately.
- Improved `Injector.call` to handle futures.
- Improved `ProvideIt.provide` initialization.

## 0.3.0

- Added `AsyncRef` & `context.reload()`.
- Added `errorBuilder` to `ProvideIt`.
- Added `loadingBuilder` to `ProvideIt`.
- Added `context.provideFactory()`.
- Added `context.provideValue()`.
- Added `FutureRef` & `context.future()`.
- Added `StreamRef` & `context.stream()`.
- Added `ProvideIt.allowedDuplicates` for duplicate rules.
- Added `Watcher.canUpdate`.
- Improved `Injector` for efficient parsing.
- Improved `ContextReaders` for efficient lookup.

## 0.2.0

- Changed `ProvideIt.root` to `ProvideIt`.
- Added `provide_it/injector.dart` library.
- Added `Injector` & `Param` for auto-injection.
- Improved all `provide` methods with auto-injection.
- Added `ProvideLazyRef` & `context.provideLazy`.
- Added `Watcher` for custom watching.
- Added `ProvideIt.watchers` with `DefaultWatchers`.
- Added `ProvideIt.namedLocator`. for injecting parameters.
- Added `CreateRef` & `context.create`.

## 0.1.0

- Changed `Provider` to `ProvideIt.root`.
- Improved ref dispose/removal on hot-reload.
- Improved several `toString` for debugging.
- Added several `asserts` for debugging.
- Added `readIt` locator.
- Added `Ref.debugValue` for debugging.
- Added `ProvideIt.log` for debugging.
- Added `RefState.removeDependent`.
- Added `dependOnInheritedElement` for bind accessors.
- Removed the need for `RefState._garbageCollector`.

## 0.0.1

- Initial release.
</file>
