import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PanelAdminViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // 1. BANDERA DE SEGURIDAD (Evita el error 'Used after being disposed')
  bool _isDisposed = false;

  int _indiceTab = 0;
  int get indiceTab => _indiceTab;

  // Estado del sub-menú de apelaciones (0: Pendientes, 1: Historial)
  int _indiceSubTabApelacion = 0;
  int get indiceSubTabApelacion => _indiceSubTabApelacion;

  List<Map<String, dynamic>> _solicitudesPendientes = [];
  List<Map<String, dynamic>> get solicitudesPendientes => _solicitudesPendientes;

  List<dynamic> _todosLosUsuarios = [];
  List<dynamic> get soloUsuarios => _todosLosUsuarios.where((u) => u['rol'] == 'usuario').toList();
  List<dynamic> get soloNegocios => _todosLosUsuarios.where((u) => u['rol'] == 'negocio').toList();

  List<Map<String, dynamic>> _reportes = [];
  List<Map<String, dynamic>> get reportes => _reportes;

  // APELACIONES FILTRADAS
  List<dynamic> _apelaciones = [];
  List<dynamic> get apelacionesPendientes => _apelaciones.where((a) => a['estatus'] == 'pendiente').toList();
  List<dynamic> get apelacionesHistorico => _apelaciones.where((a) => a['estatus'] != 'pendiente').toList();

  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  // 2. CONSTRUCTOR: Faltaba esto para que cargue los datos apenas se abre la pantalla
  PanelAdminViewModel() {
    cargarDatosTabActual();
  }

  // 3. FUNCIÓN DE NOTIFICACIÓN SEGURA
  void _notificar() {
    if (!_isDisposed) notifyListeners();
  }

  void cambiarTab(int indice) {
    _indiceTab = indice;
    cargarDatosTabActual();
    _notificar();
  }

  void cambiarSubTabApelacion(int indice) {
    _indiceSubTabApelacion = indice;
    _notificar();
  }

  Future<void> cargarDatosTabActual() async {
    _estaCargando = true;
    _notificar();

    try {
      if (_indiceTab == 0) {
        final datos = await _supabase.from('solicitudes_registro').select().eq('estatus', 'pendiente');
        if (_isDisposed) return;
        _solicitudesPendientes = List<Map<String, dynamic>>.from(datos);
      }
      else if (_indiceTab == 1 || _indiceTab == 2) {
        final respuestaRpc = await _supabase.rpc('admin_obtener_usuarios');
        if (_isDisposed) return;
        if (respuestaRpc != null) {
          _todosLosUsuarios = List<dynamic>.from(respuestaRpc);
        } else {
          _todosLosUsuarios = [];
        }
      }
      else if (_indiceTab == 3) {
        final respuestaRpc = await _supabase.rpc('admin_obtener_reportes');
        if (_isDisposed) return;
        if (respuestaRpc != null) {
          _reportes = List<Map<String, dynamic>>.from(respuestaRpc is String ? jsonDecode(respuestaRpc) : respuestaRpc);
        } else { _reportes = []; }
      }
      else if (_indiceTab == 4) {
        final respuestaRpc = await _supabase.rpc('admin_obtener_apelaciones');
        if (_isDisposed) return;
        if (respuestaRpc != null) {
          _apelaciones = List<dynamic>.from(respuestaRpc is String ? jsonDecode(respuestaRpc) : respuestaRpc);
        } else { _apelaciones = []; }
      }
    } catch (e) {
      debugPrint('🚨 ERROR EN ADMIN CARGANDO TAB $_indiceTab: $e');
    } finally {
      _estaCargando = false;
      _notificar();
    }
  }

  Future<String?> gestionarSolicitud(String idSolicitud, String usuarioId, String nuevoEstatus, [String motivo = '']) async {
    try {
      await _supabase.from('solicitudes_registro').update({
        'estatus': nuevoEstatus,
        'motivo_rechazo': motivo.isEmpty ? null : motivo
      }).eq('id', idSolicitud);

      await _supabase.rpc('admin_actualizar_estatus_negocio', params: {
        'uid': usuarioId,
        'nuevo_estatus': nuevoEstatus
      });

      _solicitudesPendientes.removeWhere((s) => s['id'] == idSolicitud);
      _notificar();
      return null;
    } catch (e) {
      return 'Error al procesar: $e';
    }
  }

  Future<String?> suspenderCuenta(String usuarioId) async {
    try {
      await _supabase.rpc('admin_suspender_usuario', params: {'uid': usuarioId});
      await cargarDatosTabActual();
      return null;
    } catch (e) { return 'Error al suspender: $e'; }
  }

  Future<String?> resolverApelacion(String idApelacion, String usuarioId, bool aprobada) async {
    try {
      await _supabase.from('apelaciones')
          .update({'estatus': aprobada ? 'aprobada' : 'rechazada'})
          .eq('id', idApelacion);

      if (aprobada) {
        await _supabase.rpc('admin_desbanear_usuario', params: {'uid': usuarioId});
      }

      await cargarDatosTabActual();
      return aprobada ? 'Usuario Desbaneado' : 'Apelación rechazada definitivamente';
    } catch (e) {
      return 'Error al procesar: $e';
    }
  }

  // 4. LIMPIEZA AL CERRAR PANTALLA
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}