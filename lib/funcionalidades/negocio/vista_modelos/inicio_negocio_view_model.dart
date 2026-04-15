import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class InicioNegocioViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // ── Bandera de seguridad para evitar errores al destruir la pantalla ──
  bool _isDisposed = false;

  int _indiceTab = 0;
  int get indiceTab => _indiceTab;

  int _indiceSubTabPedidos = 0;
  int get indiceSubTabPedidos => _indiceSubTabPedidos;

  bool _estaCargando = true;
  bool get estaCargando => _estaCargando;

  String _nombreComercial = 'Mi Taquería';
  String get nombreComercial => _nombreComercial;

  List<dynamic> _productos = [];
  List<dynamic> get productos => _productos;

  Map<String, dynamic>? _perfil;
  Map<String, dynamic>? get perfil => _perfil;

  int _pedidosHoy = 0;
  int get pedidosHoy => _pedidosHoy;

  double _gananciasHoy = 0.0;
  double get gananciasHoy => _gananciasHoy;

  String _tiempoPromedioHoy = "-- min";
  String get tiempoPromedioHoy => _tiempoPromedioHoy;

  List<dynamic> _pedidosActivos = [];
  List<dynamic> get pedidosActivos => _pedidosActivos;

  List<dynamic> _historialPedidos = [];
  List<dynamic> get historialPedidos => _historialPedidos;

  List<Map<String, dynamic>> _pedidosExpresDisponibles = [];
  List<Map<String, dynamic>> get pedidosExpresDisponibles =>
      _pedidosExpresDisponibles;

  List<String> get galeriaFotos {
    if (_perfil == null || _perfil!['galeria_fotos'] == null) return [];
    var data = _perfil!['galeria_fotos'];
    List<dynamic> lista =
    data is String ? jsonDecode(data) : List.from(data);
    return lista.map((e) => e.toString()).toList();
  }

  RealtimeChannel? _canalMisPedidos;
  RealtimeChannel? _canalExpres;

  InicioNegocioViewModel() {
    cargarDatosPerfil();
  }

  // ── FUNCIÓN SEGURA PARA NOTIFICAR (Evita el error 'Used after disposed') ──
  void _notificar() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void cambiarTab(int indice) {
    _indiceTab = indice;
    _notificar();
  }

  void cambiarSubTabPedidos(int indice) {
    _indiceSubTabPedidos = indice;
    if (indice == 1) cargarPedidosExpresDisponibles();
    _notificar();
  }

  Future<void> cargarDatosPerfil() async {
    _estaCargando = true;
    _notificar();
    try {
      final uid = _supabase.auth.currentUser!.id;

      final datosPerfil = await _supabase
          .from('perfiles_negocios')
          .select()
          .eq('usuario_id', uid)
          .maybeSingle();
      _perfil = datosPerfil;

      if (datosPerfil != null &&
          datosPerfil['nombre_comercial'] != null &&
          datosPerfil['nombre_comercial'].toString().isNotEmpty) {
        _nombreComercial = datosPerfil['nombre_comercial'];
      } else {
        final solicitud = await _supabase
            .from('solicitudes_registro')
            .select('nombre_comercial')
            .eq('usuario_id', uid)
            .maybeSingle();
        if (solicitud != null && solicitud['nombre_comercial'] != null) {
          _nombreComercial = solicitud['nombre_comercial'];
        }
      }

      await cargarProductos();
      await cargarEstadisticasHoy();
      await cargarPedidosActivos();
      await cargarHistorial();

      _inicializarTiempoReal(uid);

    } catch (e) {
      debugPrint('Error crítico cargando perfil: $e');
    } finally {
      _estaCargando = false;
      _notificar();
    }
  }

  // ══════════════════════════════════════════
  // LÓGICA DE TIEMPO REAL
  // ══════════════════════════════════════════

  void _inicializarTiempoReal(String uid) {
    if (_canalMisPedidos != null) _supabase.removeChannel(_canalMisPedidos!);
    if (_canalExpres != null) _supabase.removeChannel(_canalExpres!);

    _canalMisPedidos = _supabase
        .channel('mis_pedidos_negocio_$uid')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'pedidos',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'negocio_id',
        value: uid,
      ),
      callback: (payload) {
        // Detenemos la ejecución si la pantalla ya se cerró
        if (_isDisposed) return;

        debugPrint('Actualización en tiempo real: Mis Pedidos');
        cargarPedidosActivos();
        cargarEstadisticasHoy();
      },
    ).subscribe();

    _canalExpres = _supabase
        .channel('pedidos_expres_global_$uid')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'pedidos',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'tipo',
        value: 'expres',
      ),
      callback: (payload) {
        if (_isDisposed) return;

        final nuevoEstado = payload.newRecord['estado'];
        final viejoEstado = payload.oldRecord['estado'];

        if (nuevoEstado == 'buscando' || viejoEstado == 'buscando') {
          debugPrint('Actualización en tiempo real: Red Exprés');
          cargarPedidosExpresDisponibles();
        }
      },
    ).subscribe();
  }

  Future<void> recargarPantalla() async {
    await cargarEstadisticasHoy();
    await cargarPedidosActivos();
    await cargarProductos();
    await cargarHistorial();
    if (_indiceSubTabPedidos == 1) await cargarPedidosExpresDisponibles();
  }

  // ══════════════════════════════════════════
  // PEDIDOS ACTIVOS E HISTORIAL
  // ══════════════════════════════════════════

  Future<void> cargarPedidosActivos() async {
    try {
      final uid = _supabase.auth.currentUser!.id;
      final datos = await _supabase
          .from('pedidos')
          .select()
          .eq('negocio_id', uid)
          .neq('estado', 'entregado')
          .neq('estado', 'cancelado')
          .order('creado_el', ascending: false);

      if (_isDisposed) return; // Evitar que actualice si ya se cerró la app
      _pedidosActivos = datos;
      _notificar();
    } catch (e) {
      debugPrint('Error cargando pedidos activos: $e');
    }
  }

  Future<void> cargarHistorial() async {
    try {
      final uid = _supabase.auth.currentUser!.id;
      final datos = await _supabase
          .from('pedidos')
          .select()
          .eq('negocio_id', uid)
          .or('estado.eq.entregado,estado.eq.cancelado')
          .order('creado_el', ascending: false)
          .limit(50);

      if (_isDisposed) return;
      _historialPedidos = datos;
      _notificar();
    } catch (e) {
      debugPrint('Error cargando historial: $e');
    }
  }

  Future<void> actualizarEstadoPedido(
      String idPedido, String nuevoEstado) async {
    try {
      _estaCargando = true;
      _notificar();
      Map<String, dynamic> datosActualizar = {'estado': nuevoEstado};
      if (nuevoEstado == 'entregado') {
        datosActualizar['entregado_el'] =
            DateTime.now().toUtc().toIso8601String();
      }
      await _supabase
          .from('pedidos')
          .update(datosActualizar)
          .eq('id', idPedido);
    } catch (e) {
      debugPrint('Error actualizando pedido: $e');
    } finally {
      _estaCargando = false;
      _notificar();
    }
  }

  // ══════════════════════════════════════════
  // MODO EXPRÉS — LADO TAQUERÍA
  // ══════════════════════════════════════════

  Future<void> cargarPedidosExpresDisponibles() async {
    try {
      final pedidos = await _supabase
          .from('pedidos')
          .select()
          .eq('tipo', 'expres')
          .eq('estado', 'buscando');

      final lat = (_perfil?['latitud'] ?? 0).toDouble();
      final lng = (_perfil?['longitud'] ?? 0).toDouble();
      final saturado = _pedidosActivos.length >= 5;

      List<Map<String, dynamic>> filtrados = [];

      for (var pedido in pedidos) {
        if (saturado) break;

        final latP = (pedido['lat_cliente'] ?? 0).toDouble();
        final lngP = (pedido['lng_cliente'] ?? 0).toDouble();

        if (lat != 0 && lng != 0 && latP != 0 && lngP != 0) {
          final distancia = _calcularDistanciaKm(lat, lng, latP, lngP);
          if (distancia <= 5.0) {
            filtrados.add({
              ...Map<String, dynamic>.from(pedido),
              'distancia_km': distancia.toStringAsFixed(1),
            });
          }
        } else {
          filtrados.add({
            ...Map<String, dynamic>.from(pedido),
            'distancia_km': '?',
          });
        }
      }

      if (_isDisposed) return;
      _pedidosExpresDisponibles = filtrados;
      _notificar();
    } catch (e) {
      debugPrint('Error cargando exprés disponibles: $e');
    }
  }

  Future<String?> reclamarPedidoExpres(String pedidoId) async {
    try {
      _estaCargando = true;
      _notificar();

      final uid = _supabase.auth.currentUser!.id;
      final actual = await _supabase
          .from('pedidos')
          .select('estado')
          .eq('id', pedidoId)
          .single();

      if (actual['estado'] != 'buscando') {
        return 'Este pedido ya fue tomado por otra taquería ⚡';
      }

      await _supabase.from('pedidos').update({
        'negocio_id': uid,
        'estado': 'pendiente',
      }).eq('id', pedidoId);

      return null;
    } catch (e) {
      return 'Error al reclamar el pedido: $e';
    } finally {
      _estaCargando = false;
      _notificar();
    }
  }

  double _calcularDistanciaKm(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  // ══════════════════════════════════════════
  // ESTADÍSTICAS DEL DÍA
  // ══════════════════════════════════════════

  Future<void> cargarEstadisticasHoy() async {
    try {
      final uid = _supabase.auth.currentUser!.id;
      final hoy = DateTime.now();
      final inicioDia =
      DateTime(hoy.year, hoy.month, hoy.day).toUtc().toIso8601String();

      final pedidos = await _supabase
          .from('pedidos')
          .select()
          .eq('negocio_id', uid)
          .gte('creado_el', inicioDia);

      int totalPedidos = 0;
      double sumaGanancias = 0.0;
      int sumaMinutos = 0;
      int pedidosEntregados = 0;

      for (var pedido in pedidos) {
        if (pedido['estado'] != 'cancelado') totalPedidos++;
        if (pedido['estado'] == 'entregado') {
          sumaGanancias += (pedido['total'] ?? 0).toDouble();
          if (pedido['entregado_el'] != null &&
              pedido['creado_el'] != null) {
            final creado =
            DateTime.parse(pedido['creado_el']).toLocal();
            final entregado =
            DateTime.parse(pedido['entregado_el']).toLocal();
            sumaMinutos += entregado.difference(creado).inMinutes;
            pedidosEntregados++;
          }
        }
      }

      if (_isDisposed) return;
      _pedidosHoy = totalPedidos;
      _gananciasHoy = sumaGanancias;
      _tiempoPromedioHoy = pedidosEntregados > 0
          ? "${(sumaMinutos / pedidosEntregados).round()} min"
          : "-- min";

      _notificar();
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
    }
  }

  // ══════════════════════════════════════════
  // PRODUCTOS Y PERFIL
  // ══════════════════════════════════════════

  Future<void> cargarProductos() async {
    try {
      final uid = _supabase.auth.currentUser!.id;
      final datos = await _supabase
          .from('productos')
          .select()
          .eq('negocio_id', uid)
          .order('creado_el');

      if (_isDisposed) return;
      _productos = datos;
      _notificar();
    } catch (e) {}
  }

  Future<String?> agregarProducto({
    required String nombre,
    required String descripcion,
    required double precio,
    required String categoria,
    required bool permitePersonalizacion,
    required String palabrasClave,
    File? imagen,
  }) async {
    _estaCargando = true;
    _notificar();
    try {
      final uid = _supabase.auth.currentUser!.id;
      String? urlImagen;
      if (imagen != null) {
        final ext = imagen.path.split('.').last;
        final nombreArchivo =
            'producto_${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final ruta = 'productos/$nombreArchivo';
        await _supabase.storage
            .from('documentos_negocios')
            .upload(ruta, imagen);
        urlImagen = _supabase.storage
            .from('documentos_negocios')
            .getPublicUrl(ruta);
      }
      await _supabase.from('productos').insert({
        'negocio_id': uid,
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'categoria': categoria,
        'permite_personalizacion': permitePersonalizacion,
        'palabras_clave': palabrasClave.toLowerCase(),
        'url_imagen': urlImagen,
      });
      await cargarProductos();
      return null;
    } catch (e) {
      return 'Error: $e';
    } finally {
      _estaCargando = false;
      _notificar();
    }
  }

  Future<String?> editarProducto({
    required String idProducto,
    required String nombre,
    required String descripcion,
    required double precio,
    required String categoria,
    required bool permitePersonalizacion,
    required String palabrasClave,
    File? nuevaImagen,
  }) async {
    _estaCargando = true;
    _notificar();
    try {
      final uid = _supabase.auth.currentUser!.id;
      String? urlImagen;

      if (nuevaImagen != null) {
        final ext = nuevaImagen.path.split('.').last;
        final nombreArchivo =
            'producto_${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final ruta = 'productos/$nombreArchivo';
        await _supabase.storage
            .from('documentos_negocios')
            .upload(ruta, nuevaImagen);
        urlImagen = _supabase.storage
            .from('documentos_negocios')
            .getPublicUrl(ruta);
      }

      final Map<String, dynamic> datos = {
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'categoria': categoria,
        'permite_personalizacion': permitePersonalizacion,
        'palabras_clave': palabrasClave.toLowerCase(),
      };
      if (urlImagen != null) datos['url_imagen'] = urlImagen;

      await _supabase
          .from('productos')
          .update(datos)
          .eq('id', idProducto);
      await cargarProductos();
      return null;
    } catch (e) {
      return 'Error: $e';
    } finally {
      _estaCargando = false;
      _notificar();
    }
  }

  Future<void> cambiarDisponibilidadProducto(
      String idProducto, bool estaDisponible) async {
    try {
      await _supabase
          .from('productos')
          .update({'disponible': estaDisponible})
          .eq('id', idProducto);
      await cargarProductos();
    } catch (e) {}
  }

  Future<void> eliminarProducto(String idProducto) async {
    try {
      _estaCargando = true;
      _notificar();
      await _supabase.from('productos').delete().eq('id', idProducto);
      await cargarProductos();
    } catch (e) {} finally {
      _estaCargando = false;
      _notificar();
    }
  }

  Future<String?> actualizarInformacionBasica({
    required String nombre,
    required String telefono,
    required String tiempo,
    required String direccion,
    required double lat,
    required double lng,
    required String tipoEnvio,
    required double costoEnvio,
    required double envioGratisDesde,
  }) async {
    try {
      final uid = _supabase.auth.currentUser!.id;
      await _supabase.from('perfiles_negocios').update({
        'nombre_comercial': nombre,
        'telefono_movil': telefono,
        'tiempo_entrega': tiempo,
        'direccion_texto': direccion,
        'latitud': lat,
        'longitud': lng,
        'tipo_envio': tipoEnvio,
        'costo_envio': costoEnvio,
        'envio_gratis_desde': envioGratisDesde,
      }).eq('usuario_id', uid);
      await cargarDatosPerfil();
      return null;
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> agregarFotoGaleria() async {
    if (galeriaFotos.length >= 10) return 'Límite de 10 fotos alcanzado.';
    try {
      final resultado = await FilePicker.pickFiles(type: FileType.image);
      if (resultado == null) return null;
      _estaCargando = true;
      _notificar();
      final archivo = File(resultado.files.single.path!);
      final uid = _supabase.auth.currentUser!.id;
      final ext = archivo.path.split('.').last;
      final nombreArchivo =
          '${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ruta = 'galeria/$nombreArchivo';
      await _supabase.storage
          .from('documentos_negocios')
          .upload(ruta, archivo);
      final urlPublica = _supabase.storage
          .from('documentos_negocios')
          .getPublicUrl(ruta);
      List<String> fotosActualizadas = List.from(galeriaFotos)
        ..add(urlPublica);
      await _supabase
          .from('perfiles_negocios')
          .update({'galeria_fotos': jsonEncode(fotosActualizadas)})
          .eq('usuario_id', uid);
      await cargarDatosPerfil();
      return null;
    } catch (e) {
      return 'Error: $e';
    } finally {
      _estaCargando = false;
      _notificar();
    }
  }

  Future<String?> eliminarFotoGaleria(int index) async {
    try {
      _estaCargando = true;
      _notificar();
      final uid = _supabase.auth.currentUser!.id;
      List<String> fotosActualizadas = List.from(galeriaFotos);
      fotosActualizadas.removeAt(index);
      await _supabase
          .from('perfiles_negocios')
          .update({'galeria_fotos': jsonEncode(fotosActualizadas)})
          .eq('usuario_id', uid);
      await cargarDatosPerfil();
      return null;
    } catch (e) {
      return 'Error: $e';
    } finally {
      _estaCargando = false;
      _notificar();
    }
  }

  Future<String?> levantarReporte({
    required String pedidoId,
    required String clienteEmail,
    required String motivo,
    required String detalles,
  }) async {
    _estaCargando = true;
    _notificar();
    try {
      final uid = _supabase.auth.currentUser!.id;
      await _supabase.from('reportes').insert({
        'negocio_id': uid,
        'pedido_id': pedidoId,
        'cliente_email': clienteEmail,
        'referencia_cliente': 'Reporte Automático desde Pedido',
        'motivo': motivo,
        'detalles': detalles,
      });
      return null;
    } catch (e) {
      return 'Ocurrió un error al enviar el reporte.';
    } finally {
      _estaCargando = false;
      _notificar();
    }
  }

  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }

  @override
  void dispose() {
    _isDisposed = true; // Levantamos la bandera para que nadie intente actualizar

    if (_canalMisPedidos != null) {
      _supabase.removeChannel(_canalMisPedidos!);
    }
    if (_canalExpres != null) {
      _supabase.removeChannel(_canalExpres!);
    }
    super.dispose();
  }
}