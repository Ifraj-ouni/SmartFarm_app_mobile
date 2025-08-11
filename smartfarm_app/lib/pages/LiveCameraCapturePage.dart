import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:smartfarm_app/pages/DiseaseDetailsPage.dart';

class LiveCameraCapturePage extends StatefulWidget {
  const LiveCameraCapturePage({super.key});

  @override
  State<LiveCameraCapturePage> createState() => _LiveCameraCapturePageState();
}

class _LiveCameraCapturePageState extends State<LiveCameraCapturePage>
    with TickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final ImagePicker _picker = ImagePicker();
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _initializeControllerFuture = _controller.initialize();
    await _initializeControllerFuture;

    await _controller.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);

    if (mounted) {
      setState(() => _isCameraInitialized = true);
    }
  }

  void _toggleFlash() async {
    _flashOn = !_flashOn;
    await _controller.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide'),
        content: const Text(
          "📸 Prendre photo : utilisez la caméra pour détecter une maladie sur une plante.\n\n"
          "🖼️ Télécharger une image : choisissez une image depuis la galerie.\n\n"
          "🔍 L'IA analyse l'image et vous affiche le nom de la maladie et le taux de confiance.\n\n"
          "⚠️ Vous devez être connecté au même réseau Wi-Fi que le serveur Python.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized || _isProcessing) return;

    try {
      final image = await _controller.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final savedPath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(image.path).copy(savedPath);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PreviewImagePage(imageFile: savedImage),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur prise de photo : $e')));
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PreviewImagePage(imageFile: file)),
      );
    }
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color background,
    required Color foreground,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: foreground, size: 28),
      ),
    );
  }

  Widget _buildCornerIndicators() {
    const double size = 260;
    const double cornerSize = 32;
    const double strokeWidth = 4;
    const color = Colors.white;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: SizedBox(
                width: cornerSize,
                height: cornerSize,
                child: CustomPaint(
                  painter: _CornerPainter(
                    topLeft: true,
                    color: color,
                    strokeWidth: strokeWidth,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: SizedBox(
                width: cornerSize,
                height: cornerSize,
                child: CustomPaint(
                  painter: _CornerPainter(
                    topRight: true,
                    color: color,
                    strokeWidth: strokeWidth,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: SizedBox(
                width: cornerSize,
                height: cornerSize,
                child: CustomPaint(
                  painter: _CornerPainter(
                    bottomLeft: true,
                    color: color,
                    strokeWidth: strokeWidth,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: SizedBox(
                width: cornerSize,
                height: cornerSize,
                child: CustomPaint(
                  painter: _CornerPainter(
                    bottomRight: true,
                    color: color,
                    strokeWidth: strokeWidth,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isCameraInitialized
          ? Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller)),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                            context,
                            '/accueil',
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.arrow_back_ios, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                "Retour",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleFlash,
                          icon: Icon(
                            _flashOn ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildCornerIndicators(),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 24,
                      left: 20,
                      right: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCircleButton(
                          icon: Icons.photo_library,
                          onPressed: _pickFromGallery,
                          background: Colors.white,
                          foreground: Colors.green,
                        ),
                        GestureDetector(
                          onTap: _takePicture,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        _buildCircleButton(
                          icon: Icons.help_outline,
                          onPressed: _showHelpDialog,
                          background: Colors.green.shade700,
                          foreground: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool topLeft, topRight, bottomLeft, bottomRight;
  final Color color;
  final double strokeWidth;

  _CornerPainter({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    final radius = 20.0;

    if (topLeft) {
      path.moveTo(0, radius + 4);
      path.quadraticBezierTo(0, 0, radius + 4, 0);
    }

    if (topRight) {
      path.moveTo(size.width - radius - 4, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius + 4);
    }

    if (bottomLeft) {
      path.moveTo(0, size.height - radius - 4);
      path.quadraticBezierTo(0, size.height, radius + 4, size.height);
    }

    if (bottomRight) {
      path.moveTo(size.width - radius - 4, size.height);
      path.quadraticBezierTo(
        size.width,
        size.height,
        size.width,
        size.height - radius - 4,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PreviewImagePage extends StatefulWidget {
  final File imageFile;
  const PreviewImagePage({super.key, required this.imageFile});

  @override
  State<PreviewImagePage> createState() => _PreviewImagePageState();
}

class _PreviewImagePageState extends State<PreviewImagePage> {
  bool isLoading = false;
  bool confirmed = false;

  final List<String> maladiesConnues = [
    'Apple___Apple_scab',
    'Apple___Black_rot',
    'Apple___Cedar_apple_rust',
    'Apple___healthy',
    'Blueberry___healthy',
    'Cherry___Powdery_mildew',
    'Cherry___healthy',
    'Corn___Cercospora_leaf_spot Gray_leaf_spot',
    'Corn___Common_rust',
    'Corn___Northern_Leaf_Blight',
    'Corn___healthy',
    'Grape___Black_rot',
    'Grape___Esca_(Black_Measles)',
    'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)',
    'Grape___healthy',
    'Orange___Haunglongbing_(Citrus_greening)',
    'Peach___Bacterial_spot',
    'Peach___healthy',
    'Pepper,_bell___Bacterial_spot',
    'Pepper,_bell___healthy',
    'Potato___Early_blight',
    'Potato___Late_blight',
    'Potato___healthy',
    'Raspberry___healthy',
    'Soybean___healthy',
    'Squash___Powdery_mildew',
    'Strawberry___Leaf_scorch',
    'Strawberry___healthy',
    'Tomato___Bacterial_spot',
    'Tomato___Early_blight',
    'Tomato___Late_blight',
    'Tomato___Leaf_Mold',
    'Tomato___Septoria_leaf_spot',
    'Tomato___Spider_mites Two-spotted_spider_mite',
    'Tomato___Target_Spot',
    'Tomato___Tomato_Yellow_Leaf_Curl_Virus',
    'Tomato___Tomato_mosaic_virus',
    'Tomato___healthy',
  ];


  Future<String?> _uploadToCloudinary(File imageFile) async {
  const String cloudName = 'dx1zihwal'; // 👉 modifie ici
  const String uploadPreset = 'fe3mrlpw'; // 👉 ton preset non signé

  final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

  final request = http.MultipartRequest('POST', url)
    ..fields['upload_preset'] = uploadPreset
    ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

  final response = await request.send();

  if (response.statusCode == 200) {
    final resStr = await response.stream.bytesToString();
    final data = json.decode(resStr);
    return data['secure_url'];
  } else {
    print("Erreur Cloudinary: ${response.statusCode}");
    return null;
  }
}


  Future<void> _analyzeImage() async {
    setState(() => isLoading = true);
    try {
      final uri = Uri.parse("https://dp9kkbdk-5050.uks1.devtunnels.ms/predict");
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('file', widget.imageFile.path),
      );
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final decoded = jsonDecode(respStr);

      final String diseaseRaw = decoded['result'];
      final double confidence = decoded['confidence'] * 100;

      if (!mounted) return;

      // Maladie inconnue ou image non détectée
      if (diseaseRaw == 'Background_without_leaves' ||
          !maladiesConnues.contains(diseaseRaw)) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Aucune maladie détectée"),
            content: const Text(
              "📷 L'image ne contient pas de feuilles détectables ou n'est pas reconnue.\n\n"
              "Veuillez réessayer avec une photo claire d'une plante contenant des feuilles bien visibles.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fermer alerte
                  Navigator.of(context).pop(); // Retour à la caméra
                },
                child: const Text("Revenir à la caméra"),
              ),
            ],
          ),
        );
        return;
      }

      final displayName = diseaseRaw
          .replaceAll('___', ' - ')
          .replaceAll('_', ' ');

      final imageUrlCloudinary = await _uploadToCloudinary(widget.imageFile);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DiseaseDetailsPage(
            diseaseName: displayName,
            diseaseKey: diseaseRaw,
            confidence: confidence,
            imageUrl: imageUrlCloudinary ?? '',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Erreur"),
          content: Text("Erreur lors de l'analyse : $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Fermer"),
            ),
          ],
        ),
      );
      Navigator.of(context).pop(); // Retour à la caméra
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Retour", style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          Center(child: Image.file(widget.imageFile)),

          if (!confirmed)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.all(20),
                    shape: const CircleBorder(),
                  ),
                  onPressed: () {
                    setState(() => confirmed = true);
                    _analyzeImage();
                  },
                  child: const Icon(Icons.check, size: 32, color: Colors.white),
                ),
              ),
            ),

          if (isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}
