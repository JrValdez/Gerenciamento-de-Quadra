import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Formata telefone brasileiro no padrão (XX) XXXXX-XXXX enquanto digita.
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));
    }

    final buf = StringBuffer();
    int sel = 0;

    if (text.length <= 2) {
      // Apenas DDD
      buf.write(text);
      sel = text.length;
    } else if (text.length <= 7) {
      // (XX) XXXXX
      buf.write('(${text.substring(0, 2)}) ${text.substring(2)}');
      sel = text.length + 4;
    } else {
      // (XX) XXXXX-XXXX
      buf.write('(${text.substring(0, 2)}) ${text.substring(2, 7)}-${text.substring(7, text.length > 11 ? 11 : text.length)}');
      sel = text.length > 11 ? 16 : text.length + 5;
    }

    return newValue.copyWith(
      text: buf.toString(),
      selection: TextSelection.collapsed(offset: sel),
    );
  }
}

/// Formata um telefone já digitado (p/ exibição) no padrão (XX) XXXXX-XXXX.
/// Aceita string com ou sem formatação prévia (só extrai os dígitos).
String formatPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty) return raw;
  if (digits.length <= 2) return digits;
  if (digits.length <= 7) return '(${digits.substring(0, 2)}) ${digits.substring(2)}';
  return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7, digits.length > 11 ? 11 : digits.length)}';
}

/// Remove a formatação e retorna apenas dígitos.
String unformatPhone(String formatted) =>
    formatted.replaceAll(RegExp(r'[^\d]'), '');
