import '../framework.dart';

extension ContextUsePageController on BuildContext {
  /// Creates a [PageController] that is automatically disposed.
  PageController usePageController({
    int initialPage = 0,
    bool keepPage = true,
    double viewportFraction = 1.0,
    ScrollControllerCallback? onAttach,
    ScrollControllerCallback? onDetach,
    Object? key,
  }) {
    return bind(
      _UsePageController(
        initialPage: initialPage,
        keepPage: keepPage,
        viewportFraction: viewportFraction,
        onAttach: onAttach,
        onDetach: onDetach,
        key: key,
      ),
    );
  }
}

class _UsePageController extends HookProvider<PageController> {
  const _UsePageController({
    required this.initialPage,
    required this.keepPage,
    required this.viewportFraction,
    this.onAttach,
    this.onDetach,
    super.key,
  });

  final int initialPage;
  final bool keepPage;
  final double viewportFraction;
  final ScrollControllerCallback? onAttach;
  final ScrollControllerCallback? onDetach;

  @override
  _UsePageControllerState createState() => _UsePageControllerState();
}

class _UsePageControllerState
    extends HookState<PageController, _UsePageController> {
  @override
  String get debugLabel => 'usePageController';

  late final PageController controller = PageController(
    initialPage: provider.initialPage,
    keepPage: provider.keepPage,
    viewportFraction: provider.viewportFraction,
    onAttach: provider.onAttach,
    onDetach: provider.onDetach,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  PageController build(BuildContext context) {
    return controller;
  }
}
