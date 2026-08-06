/// `£1,234.56` — thousands-separated GBP, using a true minus sign so it reads
/// the same as the rest of the design's figures. Kept hand-rolled rather than
/// pulling in `intl` for one function.
String formatMoney(double amount) {
  final negative = amount < 0;
  final parts = amount.abs().toStringAsFixed(2).split('.');
  final digits = parts[0];

  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }

  return '${negative ? '−' : ''}£$buffer.${parts[1]}';
}
