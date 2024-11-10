import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enum representing the direction of the slider.
enum SlideDirection { left, right, none }

/// Class to store the updated slider value and direction of change.
class SliderUpdate {
  final double value;
  final SlideDirection direction;

  SliderUpdate(this.value, this.direction);

  @override
  String toString() => 'SliderUpdate(value: $value, direction: $direction)';
}

/// Theme configuration for customizing the look of the ZoomSlider.
class ZoomSliderTheme {
  /// The color of the slider's line.
  final Color lineColor;

  /// The color of the center line of the slider.
  final Color centerLineColor;

  /// The background color of the slider.
  final Color backgroundColor;

  /// The text style used for the value displayed on the slider.
  final TextStyle valueTextStyle;

  const ZoomSliderTheme({
    this.lineColor = Colors.grey,
    this.centerLineColor = Colors.blue,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.valueTextStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  });

  /// Returns a copy of the current theme with specified properties overridden.
  ZoomSliderTheme copyWith({
    Color? lineColor,
    Color? centerLineColor,
    Color? backgroundColor,
    TextStyle? valueTextStyle,
  }) {
    return ZoomSliderTheme(
      lineColor: lineColor ?? this.lineColor,
      centerLineColor: centerLineColor ?? this.centerLineColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      valueTextStyle: valueTextStyle ?? this.valueTextStyle,
    );
  }
}

/// A custom slider widget that mimics the behavior of camera app sliders, with support for both bounded and unbounded values and smooth inertial scrolling.
class ZoomSlider extends StatefulWidget {
  /// The minimum value of the slider.
  final double minValue;

  /// The maximum value of the slider.
  final double maxValue;

  /// The initial value of the slider when it is first rendered.
  final double initialValue;

  /// The callback function called when the slider's value changes.
  /// It receives the updated value and the direction of change.
  final void Function(SliderUpdate)? onChanged;

  /// The sensitivity of the slider. Higher values make the slider more sensitive to user input.
  final double sensitivity;

  /// The number of visible lines on the slider.
  final int numberOfLines;

  /// The height of the slider.
  final double height;

  /// Whether to show the value displayed on the slider.
  final bool showValue;

  /// A function to format the value displayed on the slider.
  /// If not provided, the value will be displayed as a string with one decimal place.
  final String Function(double)? valueFormatter;

  /// Whether to enable haptic feedback when the slider value changes.
  final bool enableHaptics;

  /// Whether to enable inertial scrolling when the user stops dragging.
  final bool enableInertialScroll;

  /// The duration of the inertial scrolling animation.
  final Duration inertialScrollDuration;

  /// The theme of the slider that controls its appearance.
  final ZoomSliderTheme theme;

  const ZoomSlider({
    super.key,
    this.minValue = double.negativeInfinity,
    this.maxValue = double.infinity,
    this.initialValue = 0.0,
    this.onChanged,
    this.sensitivity = 0.1,
    this.numberOfLines = 20,
    this.height = 100,
    this.showValue = true,
    this.valueFormatter,
    this.enableHaptics = true,
    this.enableInertialScroll = true,
    this.inertialScrollDuration = const Duration(milliseconds: 500),
    this.theme = const ZoomSliderTheme(),
  }) : assert(initialValue >= minValue && initialValue <= maxValue,
            'Initial value must be between minValue and maxValue');

  @override
  State<ZoomSlider> createState() => _ZoomSliderState();
}

class _ZoomSliderState extends State<ZoomSlider>
    with SingleTickerProviderStateMixin {
  late double _value;
  double _lastValue = 0;
  double _offset = 0;
  double _startX = 0;
  double _lastMarkCrossed = 0;
  double _velocity = 0;
  DateTime? _lastDragTime;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final double _baseSpacing = 20.0;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _lastValue = _value;

    // Initialize animation controller for inertial scrolling
    _animationController = AnimationController(
      vsync: this,
      duration: widget.inertialScrollDuration,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.decelerate,
    );

    _animationController.addListener(_handleAnimation);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Handles the inertial scrolling animation update.
  void _handleAnimation() {
    final distance = _velocity * _animation.value;
    _updateOffset(_offset + distance);
  }

  /// Handles the start of a drag gesture.
  ///
  /// The [details] parameter provides information about the drag start event.
  void _handleDragStart(DragStartDetails details) {
    _startX = details.localPosition.dx;
    _animationController.stop();
    _lastDragTime = DateTime.now();
    _lastMarkCrossed = _offset;
    _velocity = 0;
  }

  /// Handles the drag update and calculates velocity for inertial scrolling.
  ///
  /// The [details] parameter provides information about the ongoing drag event.
  void _handleDragUpdate(DragUpdateDetails details) {
    final currentTime = DateTime.now();
    final deltaTime =
        currentTime.difference(_lastDragTime!).inMilliseconds / 1000;
    final delta = details.localPosition.dx - _startX;

    if (deltaTime > 0) {
      _velocity = -delta / deltaTime;
    }

    _lastDragTime = currentTime;
    _updateOffset(_offset - delta); // Update offset based on drag direction
    _startX = details.localPosition.dx;
  }

  /// Updates the offset of the slider and triggers the value change callback.
  ///
  /// The [newOffset] parameter is the new offset position of the slider.
  void _updateOffset(double newOffset) {
    final marksCrossed =
        ((newOffset - _lastMarkCrossed) / _baseSpacing).round();

    if (marksCrossed != 0) {
      if (widget.enableHaptics) {
        HapticFeedback.lightImpact(); // Provide haptic feedback
      }

      final proposedValue = _value + (marksCrossed * widget.sensitivity);

      setState(() {
        if (proposedValue >= widget.minValue &&
            proposedValue <= widget.maxValue) {
          _value = proposedValue;
          _offset = newOffset;

          SlideDirection direction;
          if (_value > _lastValue) {
            direction = SlideDirection.right;
          } else if (_value < _lastValue) {
            direction = SlideDirection.left;
          } else {
            direction = SlideDirection.none;
          }

          if (widget.onChanged != null) {
            widget.onChanged!(SliderUpdate(_value, direction));
          }

          _lastValue = _value;
        } else {
          final overscroll = proposedValue < widget.minValue
              ? widget.minValue - proposedValue
              : proposedValue - widget.maxValue;
          _offset = newOffset / (1 + overscroll.abs());
        }
      });

      _lastMarkCrossed = newOffset;
    } else {
      setState(() {
        _offset = newOffset;
      });
    }
  }

  /// Handles the end of a drag gesture and triggers inertial scrolling if necessary.
  ///
  /// The [details] parameter provides information about the drag end event.
  void _handleDragEnd(DragEndDetails details) {
    if (widget.enableInertialScroll && _velocity.abs() > 100) {
      _animationController.duration = Duration(
        milliseconds: (_velocity.abs() * 0.7).round().clamp(
              500,
              widget.inertialScrollDuration.inMilliseconds,
            ),
      );

      _animationController.forward(from: 0.0);
    } else {
      // Snap to min or max value if necessary
      if (_value < widget.minValue) {
        _animateToValue(widget.minValue);
      } else if (_value > widget.maxValue) {
        _animateToValue(widget.maxValue);
      }
    }

    if (widget.onChanged != null) {
      widget.onChanged!(SliderUpdate(_value, SlideDirection.none));
    }
  }

  /// Animates the slider to the target value (min or max) with smooth scrolling.
  ///
  /// The [targetValue] parameter is the value to which the slider should animate.
  void _animateToValue(double targetValue) {
    final startOffset = _offset;
    final endOffset = _offset + (_value - targetValue) / widget.sensitivity;

    _animationController.reset();
    _animation = Tween<double>(
      begin: startOffset,
      end: endOffset,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    _value = targetValue;
    if (widget.onChanged != null) {
      widget.onChanged!(SliderUpdate(targetValue, SlideDirection.none));
    }
  }

  /// Formats the slider value using the provided formatter or default formatting.
  ///
  /// The [value] parameter is the value to be formatted.
  String _formatValue(double value) {
    if (widget.valueFormatter != null) {
      return widget.valueFormatter!(value);
    }
    return value.toStringAsFixed(1); // Default formatting
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: GestureDetector(
        onHorizontalDragStart: _handleDragStart,
        onHorizontalDragUpdate: _handleDragUpdate,
        onHorizontalDragEnd: _handleDragEnd,
        child: CustomPaint(
          painter: _SliderPainter(
            offset: _offset,
            numberOfLines: widget.numberOfLines,
            lineColor: widget.theme.lineColor,
            centerLineColor: widget.theme.centerLineColor,
            minValue: widget.minValue,
            maxValue: widget.maxValue,
            currentValue: _value,
            baseSpacing: _baseSpacing,
            viewportWidth: MediaQuery.of(context).size.width,
          ),
          child: Center(
            child: Text(
              _formatValue(_value),
              style: widget.showValue
                  ? widget.theme.valueTextStyle
                  : widget.theme.valueTextStyle.copyWith(
                      color: Colors.transparent,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter to render the slider's lines and value.
class _SliderPainter extends CustomPainter {
  final double offset;
  final int numberOfLines;
  final Color lineColor;
  final Color centerLineColor;
  final double minValue;
  final double maxValue;
  final double currentValue;
  final double baseSpacing;
  final double viewportWidth;

  _SliderPainter({
    required this.offset,
    required this.numberOfLines,
    required this.lineColor,
    required this.centerLineColor,
    required this.minValue,
    required this.maxValue,
    required this.currentValue,
    required this.baseSpacing,
    required this.viewportWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    final centerPaint = Paint()
      ..color = centerLineColor
      ..strokeWidth = 2.0;

    // Draw vertical lines with extended range
    final extendedNumberOfLines = numberOfLines * 2;
    final visibleStart = (offset / baseSpacing).floor() - extendedNumberOfLines;
    final visibleEnd =
        ((offset + size.width) / baseSpacing).ceil() + extendedNumberOfLines;

    for (var i = visibleStart; i <= visibleEnd; i++) {
      final x = (i * baseSpacing) - offset;

      if (x >= -baseSpacing && x <= size.width + baseSpacing) {
        final isLongLine = i % 5 == 0;
        final lineHeight = isLongLine ? size.height * 0.4 : size.height * 0.3;
        final startY = (size.height - lineHeight) / 2;

        canvas.drawLine(
          Offset(x, startY),
          Offset(x, startY + lineHeight),
          paint,
        );
      }
    }

    // Draw center indicator line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(_SliderPainter oldDelegate) {
    return oldDelegate.offset != offset ||
        oldDelegate.viewportWidth != viewportWidth;
  }
}
