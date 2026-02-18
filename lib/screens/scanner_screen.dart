import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../models/deposit.dart';
import '../services/ocr_service.dart';

class ScannerScreen extends StatefulWidget {
  final Function(Deposit) onConfirm;
  const ScannerScreen({super.key, required this.onConfirm});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isBusy = false;
  bool _isPaused = false; // BOTÓN DE PAUSA
  DateTime _lastUpdateTime = DateTime.now();
  Deposit? _currentData;
  bool _initialized = false;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Permission.camera.request();
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _controller?.initialize();
    if (mounted) {
      _controller?.startImageStream(_processImage);
      setState(() {
        _initialized = true;
        _isCameraInitialized = true;
      });
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _controller?.stopImageStream();
      } else {
        _controller?.startImageStream(_processImage);
      }
    });
  }

  void _resetScanner() {
    setState(() {
      _currentData = null;
      _lastUpdateTime = DateTime.now();
    });
  }

  void _processImage(CameraImage image) async {
    // SENIOR OPTIMIZATION: Solo procesamos cada 2 segundos para estabilidad visual
    final now = DateTime.now();
    if (_isBusy ||
        !mounted ||
        _isPaused ||
        now.difference(_lastUpdateTime).inSeconds < 1.5)
      return;

    _isBusy = true;

    try {
      final inputImage = _getInputImage(image);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isNotEmpty) {
        final data = OCRService.parseDeposit(recognizedText.text);
        if (mounted && data != null) {
          setState(() {
            _currentData = data;
            _lastUpdateTime = now; // Actualizamos el reloj de estabilidad
          });
        }
      }
    } catch (e) {
      debugPrint("OCR Error: $e");
    } finally {
      _isBusy = false;
    }
  }

  InputImage _getInputImage(CameraImage image) {
    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation:
          InputImageRotationValue.fromRawValue(
            _controller!.description.sensorOrientation,
          ) ??
          InputImageRotation.rotation90deg,
      format:
          InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.nv21,
      bytesPerRow: image.planes[0].bytesPerRow,
    );
    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: metadata,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "LECTOR BANCO UNIÓN",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF003399),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isCameraInitialized) CameraPreview(_controller!),

                // Overlay de escaneo profesional
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isPaused
                          ? Colors.red
                          : (_currentData != null
                                ? Colors.green
                                : Colors.yellow),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      if (!_isPaused)
                        _ScanningLine(), // Línea animada de escaneo
                    ],
                  ),
                ),

                // Indicador de Pausa
                if (_isPaused)
                  Container(
                    color: Colors.black45,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pause_circle_filled,
                            color: Colors.white,
                            size: 80,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "ESCÁNER PAUSADO",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Botones flotantes laterales
                Positioned(
                  right: 20,
                  top: 20,
                  child: Column(
                    children: [
                      _actionFab(
                        icon: _isPaused ? Icons.play_arrow : Icons.pause,
                        color: _isPaused ? Colors.green : Colors.orange,
                        onTap: _togglePause,
                        label: _isPaused ? "Reanudar" : "Pausar",
                      ),
                      const SizedBox(height: 15),
                      _actionFab(
                        icon: Icons.refresh,
                        color: Colors.redAccent,
                        onTap: _resetScanner,
                        label: "Reset",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "DATOS DETECTADOS",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    if (_isBusy)
                      const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 15),
                _visualRow(
                  "OPERACIÓN:",
                  _currentData?.nro,
                  true,
                  Icons.numbers,
                ),
                _visualRow(
                  "DESTINO:",
                  "MINISTERIO EDUCACION",
                  false,
                  Icons.account_balance,
                ),
                _visualRow("DE:", _currentData?.de, false, Icons.person),
                _visualRow(
                  "DEPOSITA:",
                  _currentData?.deposita,
                  false,
                  Icons.person_outline,
                ),
                _visualRow(
                  "MONTO:",
                  _currentData?.bs != null ? "BS. ${_currentData!.bs}" : null,
                  true,
                  Icons.payments,
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003399),
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _currentData != null
                        ? () {
                            if (!_isPaused) _togglePause();
                            _showConfirm();
                          }
                        : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      "PROCESAR DEPÓSITO",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionFab({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _visualRow(String label, String? val, bool bold, IconData icon) {
    bool ok = val != null && val.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: ok ? const Color(0xFF003399) : Colors.grey,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ok ? val : "...",
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w900 : FontWeight.normal,
                color: ok ? Colors.black : Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Revisión Estática",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xFF003399),
                ),
              ),
              const Divider(),
              _e("NRO", _currentData?.nro),
              _e("DE (Remitente)", _currentData?.de),
              _e("DEPOSITA", _currentData?.deposita),
              Row(
                children: [
                  Expanded(child: _e("MONTO", _currentData?.bs)),
                  const SizedBox(width: 10),
                  Expanded(child: _e("FECHA", _currentData?.fecha)),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                "A: MINISTERIO DE EDUCACION - RECURSOS PROPIOS",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                ),
                onPressed: () {
                  widget.onConfirm(_currentData!);
                  Navigator.pop(context);
                  _togglePause(); // Reanudamos después de guardar
                },
                child: const Text(
                  "GUARDAR EN HISTORIAL",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _e(String l, String? v) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: TextEditingController(text: v),
      onChanged: (newVal) {
        // Permitir edición manual si el OCR falló ligeramente
        if (_currentData != null) {
          if (l == "NRO") _currentData = _currentData!.copyWith(nro: newVal);
          if (l == "MONTO") _currentData = _currentData!.copyWith(bs: newVal);
        }
      },
      decoration: InputDecoration(
        labelText: l,
        prefixIcon: Icon(_getIconForLabel(l), size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    ),
  );

  IconData _getIconForLabel(String l) {
    if (l.contains("NRO")) return Icons.numbers;
    if (l.contains("DE")) return Icons.person;
    if (l.contains("MONTO")) return Icons.payments;
    return Icons.text_fields;
  }
}

class _ScanningLine extends StatefulWidget {
  @override
  _ScanningLineState createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: _controller.value * 200,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
              color: Colors.yellow,
            ),
          ),
        );
      },
    );
  }
}
