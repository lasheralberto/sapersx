import 'package:flutter/material.dart';

class ExpandableMetadataRow extends StatefulWidget {
  final IconData icon;
  final String text;
  final bool light;
  final int maxLinesCollapsed;
  final int maxLinesExpanded;

  ExpandableMetadataRow({
    required this.icon,
    required this.text,
    required this.light,
    this.maxLinesCollapsed = 2,
    this.maxLinesExpanded = 100,
  });

  @override
  _ExpandableMetadataRowState createState() => _ExpandableMetadataRowState();
}

class _ExpandableMetadataRowState extends State<ExpandableMetadataRow> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.light
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.icon, size: 16, color: color.withOpacity(0.8)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isExpanded)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: widget.maxLinesExpanded *
                              Theme.of(context).textTheme.bodyMedium!.height! *
                              Theme.of(context).textTheme.bodyMedium!.fontSize!,
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            widget.text,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: color.withOpacity(0.8),
                                ),
                            softWrap: true,
                          ),
                        ),
                      )
                    else
                      Text(
                        widget.text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: color.withOpacity(0.8),
                            ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: widget.maxLinesCollapsed,
                      ),
                    if (!isExpanded &&
                        _hasTextOverflow(
                            widget.text, widget.maxLinesCollapsed, context))
                      Text(
                        '... más',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasTextOverflow(String text, int maxLines, BuildContext context) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
      ),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width);

    return textPainter.didExceedMaxLines;
  }
}
