import 'package:flutter/widgets.dart';

abstract class SingleChildWidget extends StatelessWidget {
  final Widget? child;
  const SingleChildWidget({super.key, this.child});

  Widget buildWithChild(BuildContext context, Widget? child);

  @override
  Widget build(BuildContext context) => buildWithChild(context, child);
}

class MultiProvider extends StatelessWidget {
  final List<dynamic> providers;
  final Widget child;

  const MultiProvider({
    super.key,
    required this.providers,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Widget tree = child;
    for (final provider in providers.reversed) {
      if (provider is SingleChildWidget) {
        tree = provider.buildWithChild(context, tree);
      } else if (provider is Widget Function(Widget child)) {
        tree = provider(tree);
      }
    }
    return tree;
  }
}

class ChangeNotifierProvider<T extends ChangeNotifier> extends SingleChildWidget {
  final T Function(BuildContext context)? create;
  final T? value;

  const ChangeNotifierProvider({
    super.key,
    required this.create,
    super.child,
  }) : value = null;

  const ChangeNotifierProvider.value({
    super.key,
    required this.value,
    super.child,
  }) : create = null;

  static T of<T extends ChangeNotifier>(
    BuildContext context, {
    bool listen = true,
  }) {
    if (listen) {
      final scope = context
          .dependOnInheritedWidgetOfExactType<_InheritedNotifierScope<T>>();
      if (scope == null || scope.notifier == null) {
        throw FlutterError('ChangeNotifierProvider<$T> not found in context.');
      }
      return scope.notifier!;
    } else {
      final element = context
          .getElementForInheritedWidgetOfExactType<_InheritedNotifierScope<T>>();
      final widget = element?.widget as _InheritedNotifierScope<T>?;
      if (widget == null || widget.notifier == null) {
        throw FlutterError('ChangeNotifierProvider<$T> not found in context.');
      }
      return widget.notifier!;
    }
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return _ChangeNotifierProviderInternal<T>(
      create: create,
      value: value,
      child: child ?? const SizedBox.shrink(),
    );
  }
}

class _ChangeNotifierProviderInternal<T extends ChangeNotifier> extends StatefulWidget {
  final T Function(BuildContext context)? create;
  final T? value;
  final Widget child;

  const _ChangeNotifierProviderInternal({
    super.key,
    this.create,
    this.value,
    required this.child,
  });

  @override
  State<_ChangeNotifierProviderInternal<T>> createState() =>
      _ChangeNotifierProviderInternalState<T>();
}

class _ChangeNotifierProviderInternalState<T extends ChangeNotifier>
    extends State<_ChangeNotifierProviderInternal<T>> {
  T? _notifier;
  bool _ownsNotifier = false;

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      _notifier = widget.value;
      _ownsNotifier = false;
    } else if (widget.create != null) {
      _notifier = widget.create!(context);
      _ownsNotifier = true;
    }
  }

  @override
  void dispose() {
    if (_ownsNotifier) {
      _notifier?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = widget.value ?? _notifier!;
    return _InheritedNotifierScope<T>(notifier: notifier, child: widget.child);
  }
}

class _InheritedNotifierScope<T extends ChangeNotifier>
    extends InheritedNotifier<T> {
  const _InheritedNotifierScope({
    required T super.notifier,
    required super.child,
  });
}

class Consumer<T extends ChangeNotifier> extends StatelessWidget {
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;

  const Consumer({super.key, required this.builder, this.child});

  @override
  Widget build(BuildContext context) {
    final value = ChangeNotifierProvider.of<T>(context, listen: true);
    return builder(context, value, child);
  }
}

extension ProviderContextExtension on BuildContext {
  T watch<T extends ChangeNotifier>() =>
      ChangeNotifierProvider.of<T>(this, listen: true);

  T read<T extends ChangeNotifier>() =>
      ChangeNotifierProvider.of<T>(this, listen: false);
}
