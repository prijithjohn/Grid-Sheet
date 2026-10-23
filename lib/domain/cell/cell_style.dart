/// Horizontal text alignment within a cell.
enum CellHorizontalAlignment {
  /// Default spreadsheet alignment: Left for text, Right for numbers, Center for booleans/errors.
  general,
  left,
  center,
  right,
}

/// Vertical text alignment within a cell.
enum CellVerticalAlignment { top, middle, bottom }

/// Cell border line styles.
enum CellBorderStyle { none, thin, medium, thick, dashed, doubleBorder }

/// Specification of a single cell border side (style and ARGB color).
class CellBorderSide {
  final CellBorderStyle style;
  final int color; // ARGB integer (e.g. 0xFFE3E7E4)

  const CellBorderSide({
    this.style = CellBorderStyle.none,
    this.color = 0xFFE3E7E4,
  });

  static const none = CellBorderSide(style: CellBorderStyle.none);

  CellBorderSide copyWith({CellBorderStyle? style, int? color}) {
    return CellBorderSide(
      style: style ?? this.style,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellBorderSide &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          color == other.color;

  @override
  int get hashCode => Object.hash(style, color);
}

/// Compound borders enclosing a cell.
class CellBorders {
  final CellBorderSide top;
  final CellBorderSide bottom;
  final CellBorderSide left;
  final CellBorderSide right;

  const CellBorders({
    this.top = CellBorderSide.none,
    this.bottom = CellBorderSide.none,
    this.left = CellBorderSide.none,
    this.right = CellBorderSide.none,
  });

  static const none = CellBorders();

  CellBorders copyWith({
    CellBorderSide? top,
    CellBorderSide? bottom,
    CellBorderSide? left,
    CellBorderSide? right,
  }) {
    return CellBorders(
      top: top ?? this.top,
      bottom: bottom ?? this.bottom,
      left: left ?? this.left,
      right: right ?? this.right,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellBorders &&
          runtimeType == other.runtimeType &&
          top == other.top &&
          bottom == other.bottom &&
          left == other.left &&
          right == other.right;

  @override
  int get hashCode => Object.hash(top, bottom, left, right);
}

/// Number formatting categories.
enum NumberFormatType {
  general,
  number,
  currency,
  percentage,
  accounting,
  dateShort,
  text,
}

/// Number formatting specification.
class CellNumberFormat {
  final NumberFormatType type;
  final int decimalPlaces;
  final String currencySymbol;
  final bool useThousandsSeparator;

  const CellNumberFormat({
    this.type = NumberFormatType.general,
    this.decimalPlaces = 2,
    this.currencySymbol = '\$',
    this.useThousandsSeparator = true,
  });

  static const general = CellNumberFormat(type: NumberFormatType.general);
  static const currency = CellNumberFormat(type: NumberFormatType.currency);
  static const percentage = CellNumberFormat(type: NumberFormatType.percentage);
  static const standardNumber = CellNumberFormat(type: NumberFormatType.number);

  CellNumberFormat copyWith({
    NumberFormatType? type,
    int? decimalPlaces,
    String? currencySymbol,
    bool? useThousandsSeparator,
  }) {
    return CellNumberFormat(
      type: type ?? this.type,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      useThousandsSeparator:
          useThousandsSeparator ?? this.useThousandsSeparator,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellNumberFormat &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          decimalPlaces == other.decimalPlaces &&
          currencySymbol == other.currencySymbol &&
          useThousandsSeparator == other.useThousandsSeparator;

  @override
  int get hashCode =>
      Object.hash(type, decimalPlaces, currencySymbol, useThousandsSeparator);
}

/// Pure Dart immutable representation of cell typography, alignment, borders, and visual styles.
///
/// Colors are stored as 32-bit ARGB integers (e.g. `0xFF217346`) to avoid Flutter UI framework dependencies.
class CellStyle {
  final String? fontFamily;
  final double fontSize;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrikethrough;

  /// Text foreground color in 32-bit ARGB (default `0xFF202124`).
  final int textColor;

  /// Background fill color in 32-bit ARGB (null represents transparent / canvas default).
  final int? fillColor;

  final CellHorizontalAlignment horizontalAlignment;
  final CellVerticalAlignment verticalAlignment;
  final bool isWrapped;

  final CellBorders borders;
  final CellNumberFormat numberFormat;

  const CellStyle({
    this.fontFamily = 'JetBrains Mono',
    this.fontSize = 11.0,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.textColor = 0xFF202124,
    this.fillColor,
    this.horizontalAlignment = CellHorizontalAlignment.general,
    this.verticalAlignment = CellVerticalAlignment.bottom,
    this.isWrapped = false,
    this.borders = CellBorders.none,
    this.numberFormat = CellNumberFormat.general,
  });

  static const defaultStyle = CellStyle();

  CellStyle copyWith({
    String? fontFamily,
    double? fontSize,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? isStrikethrough,
    int? textColor,
    int? fillColor,
    bool clearFillColor = false,
    CellHorizontalAlignment? horizontalAlignment,
    CellVerticalAlignment? verticalAlignment,
    bool? isWrapped,
    CellBorders? borders,
    CellNumberFormat? numberFormat,
  }) {
    return CellStyle(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      isStrikethrough: isStrikethrough ?? this.isStrikethrough,
      textColor: textColor ?? this.textColor,
      fillColor: clearFillColor ? null : (fillColor ?? this.fillColor),
      horizontalAlignment: horizontalAlignment ?? this.horizontalAlignment,
      verticalAlignment: verticalAlignment ?? this.verticalAlignment,
      isWrapped: isWrapped ?? this.isWrapped,
      borders: borders ?? this.borders,
      numberFormat: numberFormat ?? this.numberFormat,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellStyle &&
          runtimeType == other.runtimeType &&
          fontFamily == other.fontFamily &&
          fontSize == other.fontSize &&
          isBold == other.isBold &&
          isItalic == other.isItalic &&
          isUnderline == other.isUnderline &&
          isStrikethrough == other.isStrikethrough &&
          textColor == other.textColor &&
          fillColor == other.fillColor &&
          horizontalAlignment == other.horizontalAlignment &&
          verticalAlignment == other.verticalAlignment &&
          isWrapped == other.isWrapped &&
          borders == other.borders &&
          numberFormat == other.numberFormat;

  @override
  int get hashCode => Object.hash(
    fontFamily,
    fontSize,
    isBold,
    isItalic,
    isUnderline,
    isStrikethrough,
    textColor,
    fillColor,
    horizontalAlignment,
    verticalAlignment,
    isWrapped,
    borders,
    numberFormat,
  );
}
