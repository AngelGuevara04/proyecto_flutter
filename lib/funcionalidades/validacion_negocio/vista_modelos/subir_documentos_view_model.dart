import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class SubirDocumentosViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  bool _esRechazado = false;
  bool get esRechazado => _esRechazado;

  String _motivoRechazo = '';
  String get motivoRechazo => _motivoRechazo;

  Map<String, dynamic>? _solicitudPrevia;
  Map<String, dynamic>? get solicitudPrevia => _solicitudPrevia;

  // Variables para guardar los archivos físicos seleccionados
  File? _archivoIdentificacion;
  File? get archivoIdentificacion => _archivoIdentificacion;

  File? _archivoComprobante;
  File? get archivoComprobante => _archivoComprobante;

  Future<void> cargarSolicitudPrevia() async {
    _estaCargando = true;
    notifyListeners();

    try {
      final usuarioId = _supabase.auth.currentUser!.id;
      final datos = await _supabase.from('solicitudes_registro').select().eq('usuario_id', usuarioId).order('id', ascending: false).limit(1);

      if (datos.isNotEmpty) {
        final solicitud = datos.first;
        if (solicitud['estatus'] == 'rechazado') {
          _esRechazado = true;
          _motivoRechazo = solicitud['motivo_rechazo'] ?? 'Revisa tus documentos.';
          _solicitudPrevia = solicitud;
        }
      }
    } catch (e) {
      debugPrint('Error cargando solicitud: $e');
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  // --- CORRECCIÓN AQUÍ ---
  // Función para abrir el selector de archivos del celular
  Future<void> seleccionarArchivo(bool esIdentificacion) async {
    try {
      // Usamos la nueva sintaxis directa sin el ".platform"
      FilePickerResult? resultado = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (resultado != null && resultado.files.single.path != null) {
        if (esIdentificacion) {
          _archivoIdentificacion = File(resultado.files.single.path!);
        } else {
          _archivoComprobante = File(resultado.files.single.path!);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error seleccionando archivo: $e');
    }
  }

  // Función interna para subir un archivo al Storage y obtener su URL pública
  Future<String> _subirArchivo(File archivo, String nombreCarpeta, String usuarioId) async {
    final extension = archivo.path.split('.').last;
    final ruta = '$nombreCarpeta/${usuarioId}_${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _supabase.storage.from('documentos_negocios').upload(ruta, archivo);
    return _supabase.storage.from('documentos_negocios').getPublicUrl(ruta);
  }

  Future<String?> enviarSolicitudFase1(
      String nombreComercial, String propietario, String rfc, String direccion,
      ) async {
    if (nombreComercial.isEmpty || propietario.isEmpty || rfc.isEmpty || direccion.isEmpty) {
      return 'Llenar todos los campos de texto es obligatorio';
    }

    // Validamos que haya archivos (ya sea nuevos o de la solicitud previa)
    final tieneIdVieja = _solicitudPrevia?['url_identificacion'] != null;
    final tieneCompViejo = _solicitudPrevia?['url_comprobante_domicilio'] != null;

    if (_archivoIdentificacion == null && !tieneIdVieja) return 'Falta la Identificación Oficial';
    if (_archivoComprobante == null && !tieneCompViejo) return 'Falta el Comprobante de Domicilio';

    _estaCargando = true;
    notifyListeners();

    try {
      final usuarioId = _supabase.auth.currentUser!.id;

      // Mantenemos las URLs viejas por defecto
      String urlIdentificacion = _solicitudPrevia?['url_identificacion'] ?? '';
      String urlComprobante = _solicitudPrevia?['url_comprobante_domicilio'] ?? '';

      // Si seleccionó un archivo NUEVO, lo subimos a Supabase Storage y reemplazamos la URL
      if (_archivoIdentificacion != null) {
        urlIdentificacion = await _subirArchivo(_archivoIdentificacion!, 'identificaciones', usuarioId);
      }
      if (_archivoComprobante != null) {
        urlComprobante = await _subirArchivo(_archivoComprobante!, 'comprobantes', usuarioId);
      }

      final datosNuevos = {
        'usuario_id': usuarioId,
        'nombre_comercial': nombreComercial,
        'propietario': propietario,
        'rfc': rfc,
        'direccion': direccion,
        'url_identificacion': urlIdentificacion, // AHORA ES UNA URL REAL
        'url_comprobante_domicilio': urlComprobante, // AHORA ES UNA URL REAL
        'estatus': 'pendiente',
        'motivo_rechazo': null,
      };

      if (_solicitudPrevia != null) {
        await _supabase.from('solicitudes_registro').update(datosNuevos).eq('id', _solicitudPrevia!['id']);
      } else {
        await _supabase.from('solicitudes_registro').insert(datosNuevos);
      }

      await _supabase.auth.updateUser(UserAttributes(data: {'estatus_aprobacion': 'pendiente'}));
      return null;
    } catch (e) {
      return 'Error al enviar la solicitud: $e';
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }
}