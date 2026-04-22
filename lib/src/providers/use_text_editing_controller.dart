import '../framework.dart';

extension ContextUseTextEditingController on BuildContext {
  /// Creates a [TextEditingController] that is automatically disposed.
  TextEditingController useTextEditingController({String? text, Object? key}) {
    return bind(
      text == null && key == null
          ? const _UseTextEditingController()
          : _UseTextEditingController(text: text, key: key),
    );
  }

  /// Creates a [TextEditingController.fromValue] that is automatically disposed.
  TextEditingController useTextEditingControllerFromValue(
    TextEditingValue value, {
    Object? key,
  }) {
    return bind(_UseTextEditingController.fromValue(value, key: key));
  }
}

class _UseTextEditingController extends HookProvider<TextEditingController> {
  const _UseTextEditingController({this.text, super.key}) : value = null;
  const _UseTextEditingController.fromValue(this.value, {super.key})
    : text = null;
  final String? text;
  final TextEditingValue? value;

  @override
  _UseTextEditingControllerState createState() =>
      _UseTextEditingControllerState();
}

class _UseTextEditingControllerState
    extends HookState<TextEditingController, _UseTextEditingController> {
  _UseTextEditingControllerState();
  @override
  String get debugLabel => 'useTextEditingController';

  late final controller = provider.value != null
      ? TextEditingController.fromValue(provider.value!)
      : TextEditingController(text: provider.text);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  TextEditingController build(BuildContext context) {
    return controller;
  }
}
