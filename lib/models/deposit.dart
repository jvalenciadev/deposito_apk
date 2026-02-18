class Deposit {
  String nro;
  String de;
  String a;
  String deposita;
  String bs;
  String fecha;

  Deposit({
    required this.nro,
    required this.de,
    required this.a,
    required this.deposita,
    required this.bs,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'nro': nro,
      'de': de,
      'a': a,
      'deposita': deposita,
      'bs': bs,
      'fecha': fecha,
    };
  }

  Deposit copyWith({
    String? nro,
    String? de,
    String? a,
    String? deposita,
    String? bs,
    String? fecha,
  }) {
    return Deposit(
      nro: nro ?? this.nro,
      de: de ?? this.de,
      a: a ?? this.a,
      deposita: deposita ?? this.deposita,
      bs: bs ?? this.bs,
      fecha: fecha ?? this.fecha,
    );
  }
}
