import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/deposit.dart';

class ExcelService {
  static Future<void> exportToExcel(
    List<Deposit> deposits, {
    String? fileName,
  }) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Depositos'];
    excel.delete('Sheet1');

    // Headers with basic styling
    sheetObject.appendRow([
      TextCellValue('NRO'),
      TextCellValue('DE'),
      TextCellValue('A'),
      TextCellValue('DEPOSITA'),
      TextCellValue('BOLIVIANOS'),
      TextCellValue('FECHA'),
    ]);

    // Data
    for (var d in deposits) {
      sheetObject.appendRow([
        TextCellValue(d.nro),
        TextCellValue(d.de),
        TextCellValue(d.a),
        TextCellValue(d.deposita),
        TextCellValue(d.bs),
        TextCellValue(d.fecha),
      ]);
    }

    // Save file
    final directory = await getTemporaryDirectory();
    final name =
        fileName ?? "depositos_${DateTime.now().millisecondsSinceEpoch}";
    final stringPath = "${directory.path}/$name.xlsx";

    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final file = File(stringPath);
      await file.writeAsBytes(fileBytes);

      // Share file
      await Share.shareXFiles([
        XFile(stringPath, name: "$name.xlsx"),
      ], text: 'Resumen de Depósitos');
    }
  }
}
