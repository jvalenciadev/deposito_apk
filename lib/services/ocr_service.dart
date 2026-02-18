import '../models/deposit.dart';

class OCRService {
  static Deposit? parseDeposit(String text) {
    if (text.isEmpty) return null;
    final cleanText = text.toUpperCase();

    final nroRegex = RegExp(r'NRO[\.\s:]*(\d{7,10})');
    final bsRegex = RegExp(r'(?:BS|BOLIVIANOS)[\.\s:]*([\d\.,]{2,})');
    final fechaRegex = RegExp(r'(\d{2}/\d{2}/\d{4})');

    String findValue(String key, String text) {
      final match = RegExp(key + r'[:\s]+([A-Z\s]{4,})').firstMatch(text);
      if (match == null) return '';
      String val = match.group(1) ?? '';
      return val
          .split('\n')
          .first
          .split(' CI ')
          .first
          .split(' AGENCIA')
          .first
          .trim();
    }

    final nro = nroRegex.firstMatch(cleanText)?.group(1) ?? '';
    final bs = bsRegex.firstMatch(cleanText)?.group(1) ?? '';
    final fecha = fechaRegex.firstMatch(cleanText)?.group(1) ?? '';

    if (nro.isNotEmpty || bs.isNotEmpty) {
      return Deposit(
        nro: nro,
        de: findValue('DE', cleanText),
        a: "MINISTERIO DE EDUCACION - RECURSOS PROPIOS", // Valor fijo solicitado
        deposita: findValue('DEPOSITA', cleanText),
        bs: bs,
        fecha: fecha,
      );
    }
    return null;
  }
}
