import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/shared/widgets/pin_dots.dart';

/// A custom 3×4 numeric pad for entering a 4-digit PIN.
class PinPad extends StatefulWidget {
  const PinPad({
    required this.length,
    required this.onCompleted,
    this.onChanged,
    this.initialValue = '',
    this.enabled = true,
    this.controller,
    super.key,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final String initialValue;
  final bool enabled;

  /// Optional external controller for clearing/reading the current value.
  final PinPadController? controller;

  @override
  State<PinPad> createState() => _PinPadState();
}

/// Lets the parent clear or read the current entry (e.g. after a wrong PIN).
class PinPadController {
  _PinPadState? _state;

  String get value => _state?._value ?? '';

  void clear() => _state?.clear();
}

class _PinPadState extends State<PinPad> {
  late String _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    widget.controller?._state = this;
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) {
      widget.controller?._state = null;
    }
    super.dispose();
  }

  void _append(String digit) {
    if (!widget.enabled) return;
    if (_value.length >= widget.length) return;
    setState(() => _value += digit);
    HapticFeedback.selectionClick();
    widget.onChanged?.call(_value);
    if (_value.length == widget.length) {
      widget.onCompleted(_value);
    }
  }

  void _backspace() {
    if (!widget.enabled || _value.isEmpty) return;
    setState(() => _value = _value.substring(0, _value.length - 1));
    HapticFeedback.selectionClick();
    widget.onChanged?.call(_value);
  }

  void clear() {
    if (_value.isEmpty) return;
    setState(() => _value = '');
    widget.onChanged?.call(_value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
                PinDots(length: widget.length, filled: _value.length),
        const SizedBox(height: 32),
        _NumericGrid(
          enabled: widget.enabled,
          onDigit: _append,
          onBackspace: _backspace,
        ),
      ],
    );
  }
}



class _NumericGrid extends StatelessWidget {
  const _NumericGrid({
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
  });

  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(context, ['1', '2', '3']),
        _row(context, ['4', '5', '6']),
        _row(context, ['7', '8', '9']),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80, height: 64),
            _DigitKey(label: '0', enabled: enabled, onTap: onDigit),
            _BackspaceKey(enabled: enabled, onTap: onBackspace),
          ],
        ),
      ],
    );
  }

  Widget _row(BuildContext context, List<String> digits) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: digits
            .map((d) => _DigitKey(label: d, enabled: enabled, onTap: onDigit))
            .toList(),
      ),
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      width: 80,
      height: 64,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadii.sm,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => onTap(label) : null,
          child: Center(
            child: Text(
              label,
              style: AppTypography.titleL.copyWith(
                color: enabled ? tokens.textPrimary : tokens.textMuted,
                fontSize: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackspaceKey extends StatelessWidget {
  const _BackspaceKey({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      width: 80,
      height: 64,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadii.sm,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 24,
              color: enabled ? tokens.textPrimary : tokens.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}