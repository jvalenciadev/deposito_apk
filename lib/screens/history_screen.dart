import 'package:flutter/material.dart';
import '../models/deposit.dart';
import '../services/excel_service.dart';

import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends StatefulWidget {
  final List<Deposit> deposits;
  final VoidCallback onClear;
  const HistoryScreen({
    super.key,
    required this.deposits,
    required this.onClear,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  void _showExportDialog() {
    final controller = TextEditingController(
      text:
          "Reporte_Union_${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().year}",
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Exportar Excel",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ingresa el nombre del archivo:"),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                suffixText: ".xlsx",
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003399),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              ExcelService.exportToExcel(
                widget.deposits,
                fileName: controller.text,
              );
            },
            child: const Text("EXPORTAR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "HISTORIAL",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF003399),
        foregroundColor: Colors.white,
        actions: [
          if (widget.deposits.isNotEmpty) ...[
            IconButton(
              tooltip: "Eliminar Todo",
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Limpiar historial"),
                    content: const Text(
                      "¿Estás seguro de que quieres borrar todos los registros?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("NO"),
                      ),
                      TextButton(
                        onPressed: () {
                          widget.onClear();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "SÍ, BORRAR",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              tooltip: "Exportar a Excel",
              icon: const Icon(Icons.file_download_outlined),
              onPressed: _showExportDialog,
            ),
          ],
        ],
      ),
      body: widget.deposits.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 80,
                    color: Colors.blueGrey.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No hay depósitos guardados",
                    style: TextStyle(
                      color: Colors.blueGrey.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: widget.deposits.length,
              itemBuilder: (context, index) {
                final d = widget.deposits[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Container(width: 6, color: const Color(0xFF003399)),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "NRO: ${d.nro}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        "BS. ${d.bs}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                          color: Color(0xFF003399),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _infoRow(Icons.person_outline, d.de),
                                  _infoRow(
                                    Icons.calendar_today_outlined,
                                    d.fecha,
                                  ),
                                  const Divider(height: 20),
                                  Text(
                                    "DEPOSITA: ${d.deposita}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Icon(icon, size: 14, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
