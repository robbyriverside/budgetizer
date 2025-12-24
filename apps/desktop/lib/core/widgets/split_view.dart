import 'package:flutter/material.dart';

import 'dart:math';

enum SplitViewMode { proportional, fixedFirst, fixedSecond }

class SplitView extends StatefulWidget {
  final Widget child1;
  final Widget child2;
  final Axis axis;
  final double initialRatio;
  final double minRatio;
  final double maxRatio;
  final double? minExtentFirst;
  final double? minExtentSecond;
  final SplitViewMode mode;
  final double? initialExtent;

  const SplitView({
    super.key,
    required this.child1,
    required this.child2,
    this.axis = Axis.horizontal,
    this.initialRatio = 0.5,
    this.minRatio = 0.1,
    this.maxRatio = 0.9,
    this.minExtentFirst,
    this.minExtentSecond,
    this.mode = SplitViewMode.proportional,
    this.initialExtent,
  });

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  late double _ratio;
  double? _fixedExtent;

  @override
  void initState() {
    super.initState();
    _ratio = widget.initialRatio;
    _fixedExtent = widget.initialExtent ?? 300.0;
  }

  @override
  Widget build(BuildContext context) {
    _fixedExtent ??= widget.initialExtent ?? 300.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSize = widget.axis == Axis.horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;

        // Calculate ratio limits based on pixel constraints
        double effectiveMinRatio = widget.minRatio;
        double effectiveMaxRatio = widget.maxRatio;

        if (widget.minExtentFirst != null) {
          effectiveMinRatio = max(
            effectiveMinRatio,
            widget.minExtentFirst! / totalSize,
          );
        }

        if (widget.minExtentSecond != null) {
          effectiveMaxRatio = min(
            effectiveMaxRatio,
            1.0 - (widget.minExtentSecond! / totalSize),
          );
        }

        // Ensure ratio stays within bounds
        _ratio = _ratio.clamp(effectiveMinRatio, effectiveMaxRatio);

        final dividerSize = 8.0;
        final availableSize = totalSize - dividerSize;

        double size1;
        double size2;

        if (widget.mode == SplitViewMode.fixedFirst) {
          size1 = _fixedExtent!.clamp(
            widget.minExtentFirst ?? 0.0,
            totalSize - (widget.minExtentSecond ?? 0.0) - dividerSize,
          );
          size2 = availableSize - size1;
        } else if (widget.mode == SplitViewMode.fixedSecond) {
          size2 = _fixedExtent!.clamp(
            widget.minExtentSecond ?? 0.0,
            totalSize - (widget.minExtentFirst ?? 0.0) - dividerSize,
          );
          size1 = availableSize - size2;
        } else {
          // Proportional
          final size1_calc = availableSize * _ratio;
          size1 = size1_calc;
          size2 = availableSize - size1;
        }

        return widget.axis == Axis.horizontal
            ? Row(
                children: [
                  SizedBox(
                    width: size1,
                    height: constraints.maxHeight,
                    child: widget.child1,
                  ),
                  _buildDivider(Axis.horizontal, constraints.maxHeight, null),
                  SizedBox(
                    width: size2,
                    height: constraints.maxHeight,
                    child: widget.child2,
                  ),
                ],
              )
            : Column(
                children: [
                  SizedBox(
                    height: size1,
                    width: constraints.maxWidth,
                    child: widget.child1,
                  ),
                  _buildDivider(Axis.vertical, null, constraints.maxWidth),
                  SizedBox(
                    height: size2,
                    width: constraints.maxWidth,
                    child: widget.child2,
                  ),
                ],
              );
      },
    );
  }

  Widget _buildDivider(Axis axis, double? height, double? width) {
    return MouseRegion(
      cursor: axis == Axis.horizontal
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (details) {
          setState(() {
            final totalSize = axis == Axis.horizontal
                ? context.size!.width
                : context.size!.height;

            // Subtract divider from total to get accurate ratio calculation base
            // or just use raw delta against total size (ratio is % of total)
            final delta = axis == Axis.horizontal
                ? details.delta.dx
                : details.delta.dy;

            if (widget.mode == SplitViewMode.fixedFirst) {
              setState(() {
                _fixedExtent = _fixedExtent! + delta;
              });
            } else if (widget.mode == SplitViewMode.fixedSecond) {
              setState(() {
                _fixedExtent = _fixedExtent! - delta;
              });
            } else {
              setState(() {
                _ratio += delta / totalSize;
                _ratio = _ratio.clamp(widget.minRatio, widget.maxRatio);
              });
            }
          });
        },
        child: Container(
          color: Colors.transparent, // Ensure hit test works fully
          width: axis == Axis.horizontal ? 8 : width,
          height: axis == Axis.vertical ? 8 : height,
          alignment: Alignment.center,
          child: Container(
            // Visual indicator line
            color: Colors.white12,
            width: axis == Axis.horizontal ? 1 : double.infinity,
            height: axis == Axis.vertical ? 1 : double.infinity,
          ),
        ),
      ),
    );
  }
}
