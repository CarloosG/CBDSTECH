import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AdminAddProductPage extends StatefulWidget {
  const AdminAddProductPage({super.key});

  @override
  State<AdminAddProductPage> createState() => _AdminAddProductPageState();
}

class _AdminAddProductPageState extends State<AdminAddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _especificacionesCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  bool _submitting = false;
  XFile? _pickedImage;
  Uint8List? _imageBytes;
  String? _imageError;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _especificacionesCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final nombre = _nombreCtrl.text.trim();
      final especificaciones = _especificacionesCtrl.text.trim();
      final precio = double.parse(_precioCtrl.text.replaceAll(',', '.'));
      String? imagenUrl;
      if (_imageBytes != null) {
        final ext = _pickedImage!.name.split('.').last.toLowerCase();
        final sanitizedName = nombre.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName.$ext';
        try {
          await Supabase.instance.client.storage
              .from('productos')
              .uploadBinary(
                'images/$fileName',
                _imageBytes!,
                fileOptions: const FileOptions(contentType: 'image/*'),
              );
          imagenUrl = Supabase.instance.client.storage
              .from('productos')
              .getPublicUrl('images/$fileName');
        } catch (e) {
          // Si falla la subida, continuamos sin URL
          _imageError = 'No se pudo subir la imagen: $e';
        }
      }

      // Intento 1: insertar con imagen_url si existe la columna
      try {
        await Supabase.instance.client.from('productos').insert({
          'nombre': nombre,
          'especificaciones': especificaciones,
          'precio': precio,
          if (imagenUrl != null) 'imagen_url': imagenUrl,
        });
      } on PostgrestException catch (pg) {
        if (pg.code == '42703') {
          // imagen_url columna no existe -> insertar sin ella
          await Supabase.instance.client.from('productos').insert({
            'nombre': nombre,
            'especificaciones': especificaciones,
            'precio': precio,
          });
        } else if (pg.code == '42501') {
          // RLS: sin permisos
          throw Exception('No tienes permisos para crear productos (RLS).');
        } else {
          rethrow;
        }
      }

      if (mounted) {
        final msg =
            _imageError == null
                ? 'Producto añadido correctamente'
                : 'Producto añadido. ${_imageError!}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir producto'), elevation: 0.5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector de imagen y preview
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child:
                      _imageBytes == null
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Toca para seleccionar una imagen',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          )
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _imageBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej. iPhone 15 Pro',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _especificacionesCtrl,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Especificaciones',
                  hintText: 'Descripción corta del producto',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Las especificaciones son obligatorias';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _precioCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  prefixText: '\$ ',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El precio es obligatorio';
                  }
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null) return 'Precio inválido';
                  if (parsed < 0) return 'El precio no puede ser negativo';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon:
                      _submitting
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.check),
                  label: Text(
                    _submitting ? 'Guardando...' : 'Guardar producto',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedImage = file;
        _imageBytes = bytes;
        _imageError = null;
      });
    }
  }
}
