import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as m;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:flutter_highlighting/themes/a11y-dark.dart';
import 'package:comet/src/widgets/markdown_widget.dart';
import 'package:comet/src/html_support.dart/html_support.dart';
import 'package:comet/src/types/state.dart';
import 'package:comet/src/types/inline_widget.dart';

// {{WIDGET_NAME}}
const _inlineWidgetBegin = '{{';
const _inlineWidgetEnd = '}}';
// {{WidgetName key=value key2="value"}}
const _inlineWidgetPattern = r'\{\{\s*([A-Za-z0-9_]+)([^}]*)\}\}';

class HtmlNode extends ElementNode {
  HtmlNode(
    this.text,
    this.visitor,
  );
  final String text;
  final WidgetVisitor visitor;

  @override
  void onAccepted(SpanNode parent) {
    children.clear();
    final spanNodes = parseHtml(
      m.Text(text),
      visitor: visitor,
      parentStyle: parentStyle,
    );
    for (final spanNode in spanNodes) {
      accept(spanNode);
    }
  }
}

class WidgetNode extends TextNode {
  WidgetNode({
    super.text,
    super.style,
    required this.inlineWidgets,
    required this.widgetName,
    required this.attributes,
  });

  final CometInlineWidgets inlineWidgets;
  final String widgetName;
  final Map<String, String> attributes;

  @override
  InlineSpan build() {
    final builder = inlineWidgets[widgetName];

    final widget = Builder(
      builder: (context) {
        if (builder == null) {
          return Text('Widget not found for name: $widgetName');
        }
        return builder(context, attributes);
      },
    );

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: widget,
    );
  }
}

MarkdownGenerator createGenerator(CometInlineWidgets inlineWidgets) {
  return MarkdownGenerator(
    textGenerator: (node, config, visitor) {
      final text = node.textContent;

      // HTML ?
      final hasHtml = text.contains(htmlRep);
      if (hasHtml) {
        return HtmlNode(
          text,
          visitor,
        );
      }

      // Widget ?
      final widgetRegExp = RegExp(_inlineWidgetPattern);
      final widgetMatch = widgetRegExp.firstMatch(text);

      if (widgetMatch != null) {
        final widgetName = widgetMatch.group(1)!;
        final rawArgs = widgetMatch.group(2) ?? '';

        final attributes = <String, String>{};
        final argRegExp = RegExp(
            r'([A-Za-z0-9_]+)\s*=\s*"([^"]*)"|([A-Za-z0-9_]+)\s*=\s*([^"\s]+)');

        for (final match in argRegExp.allMatches(rawArgs)) {
          if (match.group(1) != null) {
            attributes[match.group(1)!] = match.group(2)!;
          } else if (match.group(3) != null) {
            attributes[match.group(3)!] = match.group(4)!;
          }
        }

        return WidgetNode(
          inlineWidgets: inlineWidgets,
          widgetName: widgetName,
          attributes: attributes,
        );
      }

      // Text
      return TextNode(
        text: text,
        style: config.p.textStyle,
      );
    },
  );
}

class MdBodyView extends StatelessWidget {
  const MdBodyView({
    super.key,
    required this.tocController,
    required this.state,
    required this.inlineWidgets,
  });

  final TocController? tocController;
  final UiState state;
  final CometInlineWidgets inlineWidgets;

  @override
  Widget build(BuildContext context) {
    return CustomMarkdownWidget(
      padding: const EdgeInsets.all(12),
      tocController: tocController,
      data: state.selectedPage?.content ?? '',
      markdownGenerator: createGenerator(inlineWidgets),
      config: MarkdownConfig(
        configs: [
          CodeConfig(
            style: TextStyle(
              color: Colors.green[600],
              fontWeight: FontWeight.bold,
              fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
              background: Paint()
                ..color = const Color.fromARGB(255, 248, 255, 240)
                ..strokeWidth = 5
                ..strokeJoin = StrokeJoin.round
                ..strokeCap = StrokeCap.round
                ..style = PaintingStyle.stroke,
            ),
          ),
          TableConfig(
            border: TableBorder.all(
              borderRadius: const BorderRadius.all(Radius.circular(2)),
              width: 1.5,
              color: Colors.grey,
            ),
          ),
          // code block
          PreConfig(
            theme: a11yDarkTheme,
            textStyle: GoogleFonts.jetBrainsMono(),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            styleNotMatched: const TextStyle(color: Colors.white),
            language: 'dart',
          ),
        ],
      ),
    );
  }
}
