import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class CompletarPerfilViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  // --- ESTADO: FOTOS ---
  List<File> _fotosInterior = [];
  List<File> get fotosInterior => _fotosInterior;

  File? _fotoExterior;
  File? get fotoExterior => _fotoExterior;

  // --- ESTADO: REDES SOCIALES ---
  List<Map<String, String>> _redesSociales = [];
  List<Map<String, String>> get redesSociales => _redesSociales;

  // --- MÉTODOS DE FOTOS ---
  Future<void> seleccionarFotosInterior() async {
    try {
      FilePickerResult? resultado = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (resultado != null) {
        _fotosInterior.addAll(resultado.paths.where((p) => p != null).map((p) => File(p!)));
        notifyListeners();
      }
    } catch (e) { debugPrint('Error fotos interior: $e'); }
  }

  void eliminarFotoInterior(int index) {
    _fotosInterior.removeAt(index);
    notifyListeners();
  }

  Future<void> seleccionarFotoExterior() async {
    try {
      FilePickerResult? resultado = await FilePicker.pickFiles(type: FileType.image);
      if (resultado != null && resultado.files.single.path != null) {
        _fotoExterior = File(resultado.files.single.path!);
        notifyListeners();
      }
    } catch (e) { debugPrint('Error foto exterior: $e'); }
  }

  // --- MÉTODOS DE REDES SOCIALES ---
  void agregarRedSocial(String plataforma, String usuario) {
    if (usuario.trim().isNotEmpty) {
      _redesSociales.add({'plataforma': plataforma, 'usuario': usuario.trim()});
      notifyListeners();
    }
  }

  void eliminarRedSocial(int index) {
    _redesSociales.removeAt(index);
    notifyListeners();
  }

  // --- GUARDADO FINAL ---
  Future<String> _subirArchivo(File archivo, String carpeta, String uid) async {
    final ext = archivo.path.split('.').last;
    final ruta = '$carpeta/${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _supabase.storage.from('documentos_negocios').upload(ruta, archivo);
    return _supabase.storage.from('documentos_negocios').getPublicUrl(ruta);
  }

  Future<String?> guardarPerfil(
      String telefono, String correo, String tiempoEntrega, bool confirmoPagoEfectivo,
      ) async {
    // 1. Validaciones básicas
    if (_fotosInterior.length < 2) return 'Debes subir al menos 2 fotos del interior';
    if (_fotoExterior == null) return 'Debes subir 1 foto del exterior';
    if (telefono.isEmpty || tiempoEntrega.isEmpty) return 'El teléfono y tiempo de entrega son obligatorios';
    if (!confirmoPagoEfectivo) return 'Debes confirmar el pago en efectivo';

    _estaCargando = true;
    notifyListeners();

    try {
      final uid = _supabase.auth.currentUser!.id;

      // 2. Subir Fotos al Storage
      List<String> urlsInterior = [];
      for (var foto in _fotosInterior) {
        String url = await _subirArchivo(foto, 'fotos_interior', uid);
        urlsInterior.add(url);
      }
      String urlExterior = await _subirArchivo(_fotoExterior!, 'fotos_exterior', uid);

      // 3. Guardar en Base de Datos (perfiles_negocios)
      await _supabase.from('perfiles_negocios').insert({
        'usuario_id': uid,
        'urls_fotos_interior': jsonEncode(urlsInterior),
        'url_foto_exterior': urlExterior,
        'telefono_movil': telefono,
        'telefono_verificado': false, // Se guarda como false por ahora
        'correo_contacto': correo.isEmpty ? null : correo,
        'redes_sociales': jsonEncode(_redesSociales),
        'tiempo_entrega': tiempoEntrega,
        'pago_efectivo_confirmado': true,
      });

      // 4. Actualizar metadatos para liberar el acceso a la App
      await _supabase.auth.updateUser(UserAttributes(data: {'perfil_completado': true}));
      return null;
    } catch (e) {
      return 'Error al guardar el perfil: $e';
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }
}