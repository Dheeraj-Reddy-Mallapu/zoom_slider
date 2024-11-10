<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# Zoom Slider

A customizable Flutter slider widget that mimics the behavior of camera app sliders, with support for both bounded and unbounded values.

## Features

- Smooth, infinite-feeling scrolling
- Optional minimum and maximum values
- Customizable sensitivity and appearance
- Visual feedback with vertical lines
- Center indicator
- Bounce-back animation when reaching bounds
- Value display with custom formatting
- Haptic feedback support

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  zoom_slider: ^1.0.0
```

## Usage

```dart
// Basic usage with bounds
ZoomSlider(
  minValue: -100,
  maxValue: 100,
  initialValue: 0,
  onChanged: (update) {
    print('Current value: ${update.value}');
  },
)

// Unbounded usage
ZoomSlider(
  onChanged: (update) {
    print('Current value: ${update.value}');
  },
)

// Customized appearance
ZoomSlider(
  minValue: 0,
  maxValue: 1000,
  initialValue: 500,
  sensitivity: 0.8,
  numberOfLines: 30,
  lineColor: Colors.grey,
  centerLineColor: Colors.blue,
  height: 120,
  valueFormatter: (value) => '${value.round()}°',
  onChanged: (update) {
    print('Current value: ${update.value}');
  },
)
```
