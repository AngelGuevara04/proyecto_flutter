import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PanelAdminViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  int _indiceTab = 0;
  int get indiceTab => _indiceTab;

  List<Map<String, dynamic>> _solicitudesPendientes = [];
  List<Map<String, dynamic>> get solicitudesPendientes => _solicitudesPendientes;

  List<dynamic> _todosLosUsuarios = [];
  List<dynamic> get soloUsuarios => _todosLosUsuarios.where((u) => u['rol'] == 'usuario').toList();
  List<dynamic> get soloNegocios => _todosLosUsuarios.where((u) => u['rol'] == 'negocio').toList();

  List<Map<String, dynamic>> _reportes = [];
  List<Map<String, dynamic>> get reportes => _reportes;

  List<dynamic> _apelaciones = [];
  List<dynamic> get apelaciones => _apelaciones;

  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  void cambiarTab(int indice) {
    _indiceTab = indice;
    cargarDatosTabActual();
    notifyListeners();
  }

  Future<void> cargarDatosTabActual() async {
    _estaCargando = true;
    notifyListeners();

    try {
      if (_indiceTab == 0) {
        final datos = await _supabase.from('solicitudes_registro').select().eq('estatus', 'pendiente');
        _solicitudesPendientes = List<Map<String, dynamic>>.from(datos);
      }
      else if (_indiceTab == 1 || _indiceTab == 2) {
        final respuestaRpc = await _supabase.rpc('admin_obtener_usuarios');
        _todosLosUsuarios = List<dynamic>.from(respuestaRpc);
      }
      else if (_indiceTab == 3) {
        // TAB 3: REPORTES (Ahora usa RPC)
        final respuestaRpc = await _supabase.rpc('admin_obtener_reportes');
        if (respuestaRpc != null) {
          if (respuestaRpc is String) {
            _reportes = List<Map<String, dynamic>>.from(jsonDecode(respuestaRpc));
          } else {
            _reportes = List<Map<String, dynamic>>.from(respuestaRpc);
          }
        } else {
          _reportes = [];
        }
      }
      else if (_indiceTab == 4) {
        // TAB 4: APELACIONES
        final respuestaRpc = await _supabase.rpc('admin_obtener_apelaciones');
        if (respuestaRpc != null) {
          if (respuestaRpc is String) {
            _apelaciones = List<dynamic>.from(jsonDecode(respuestaRpc));
          } else {
            _apelaciones = List<dynamic>.from(respuestaRpc);
          }
        } else {
          _apelaciones = [];
        }
      }
    } catch (e) {
      debugPrint('🚨 ERROR CRÍTICO EN ADMIN: $e');
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  Future<void> gestionarSolicitud(String idSolicitud, String usuarioId, String nuevoEstatus) async {
    try {
      await _supabase.from('solicitudes_registro').update({'estatus': nuevoEstatus}).eq('id', idSolicitud);
      _solicitudesPendientes.removeWhere((s) => s['id'] == idSolicitud);
      notifyListeners();
    } catch (e) {
      debugPrint('Error al gestionar solicitud: $e');
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
      return aprobada ? 'Usuario Desbaneado con éxito' : 'Apelación rechazada';
    } catch (e) {
      return 'Error al procesar: $e';
    }
  }
}