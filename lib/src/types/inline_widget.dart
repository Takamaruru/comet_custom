import 'package:flutter/material.dart';

typedef CometInlineWidgetBuilder = Widget Function(
  BuildContext context,
  Map<String, String> attributes,
);

typedef CometInlineWidgets = Map<String, CometInlineWidgetBuilder>;
