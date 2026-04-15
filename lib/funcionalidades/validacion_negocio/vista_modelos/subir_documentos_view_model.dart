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

  File? _archivoIdentificacion;
  File? get archivoIdentificacion => _archivoIdentificacion;

  File? _archivoComprobante;
  File? get archivoComprobante => _archivoComprobante;

  Future<void> cargarSolicitudPrevia() async {
    _estaCargando = true;
    notifyListeners();

    try {
      final usuarioId = _supabase.auth.currentUser!.id;
      final datos = await _supabase
          .from('solicitudes_registro')
          .select()
          .eq('usuario_id', usuarioId)
          .order('id', ascending: false)
          .limit(1);

      if (datos.isNotEmpty) {
        final solicitud = datos.first;
        _solicitudPrevia = solicitud;

        if (solicitud['estatus'] == 'rechazado') {
          _esRechazado = true;
          _motivoRechazo =
              solicitud['motivo_rechazo'] ?? 'Revisa tus documentos.';
        } else {
          _esRechazado = false;
          _motivoRechazo = '';
        }
      } else {
        _solicitudPrevia = null;
        _esRechazado = false;
      }
    } catch (e) {
      debugPrint('Error cargando solicitud: $e');
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  Future<void> seleccionarArchivo(bool esIdentificacion) async {
    try {
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

  Future<String> _subirArchivo(
      File archivo, String nombreCarpeta, String usuarioId) async {
    final extension = archivo.path.split('.').last;
    final ruta =
        '$nombreCarpeta/${usuarioId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _supabase.storage
        .from('documentos_negocios')
        .upload(ruta, archivo);
    return _supabase.storage
        .from('documentos_negocios')
        .getPublicUrl(ruta);
  }

  Future<String?> enviarSolicitudFase1(
      String nombreComercial,
      String propietario,
      String rfc,
      String direccion,
      ) async {
    if (nombreComercial.isEmpty ||
        propietario.isEmpty ||
        rfc.isEmpty ||
        direccion.isEmpty) {
      return 'Llenar todos los campos de texto es obligatorio';
    }

    final tieneIdVieja = _solicitudPrevia?['url_identificacion'] != null;
    final tieneCompViejo =
        _solicitudPrevia?['url_comprobante_domicilio'] != null;

    if (_archivoIdentificacion == null && !tieneIdVieja) {
      return 'Falta la Identificación Oficial';
    }
    if (_archivoComprobante == null && !tieneCompViejo) {
      return 'Falta el Comprobante de Domicilio';
    }

    _estaCargando = true;
    notifyListeners();

    try {
      final usuarioId = _supabase.auth.currentUser!.id;

      String urlIdentificacion =
          _solicitudPrevia?['url_identificacion'] ?? '';
      String urlComprobante =
          _solicitudPrevia?['url_comprobante_domicilio'] ?? '';

      if (_archivoIdentificacion != null) {
        urlIdentificacion = await _subirArchivo(
            _archivoIdentificacion!, 'identificaciones', usuarioId);
      }
      if (_archivoComprobante != null) {
        urlComprobante = await _subirArchivo(
            _archivoComprobante!, 'comprobantes', usuarioId);
      }

      final datosNuevos = {
        'usuario_id': usuarioId,
        'nombre_comercial': nombreComercial,
        'propietario': propietario,
        'rfc': rfc,
        'direccion': direccion,
        'url_identificacion': urlIdentificacion,
        'url_comprobante_domicilio': urlComprobante,
        'estatus': 'pendiente',
        'motivo_rechazo': null,
      };

      if (_solicitudPrevia != null) {
        await _supabase
            .from('solicitudes_registro')
            .update(datosNuevos)
            .eq('id', _solicitudPrevia!['id']);
      } else {
        await _supabase
            .from('solicitudes_registro')
            .insert(datosNuevos);
      }

      // ── CLAVE: Cambiar estatus a 'pendiente' para que el semáforo
      // muestre PantallaEnRevision ──
      await _supabase.auth.updateUser(
        UserAttributes(data: {'estatus_aprobacion': 'pendiente'}),
      );

      return null;
    } catch (e) {
      return 'Error al enviar la solicitud: $e';
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }
}