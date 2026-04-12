import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class InicioNegocioViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  int _indiceTab = 0;
  int get indiceTab => _indiceTab;

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

  List<String> get galeriaFotos {
    if (_perfil == null || _perfil!['galeria_fotos'] == null) return [];
    var data = _perfil!['galeria_fotos'];
    List<dynamic> lista = data is String ? jsonDecode(data) : List.from(data);
    return lista.map((e) => e.toString()).toList();
  }

  InicioNegocioViewModel() {
    cargarDatosPerfil();
  }

  void cambiarTab(int indice) {
    _indiceTab = indice;
    notifyListeners();
  }

  Future<void> cargarDatosPerfil() async {
    _estaCargando = true;
    notifyListeners();
    try {
      final uid = _supabase.auth.currentUser!.id;

      final datosPerfil = await _supabase.from('perfiles_negocios').select().eq('usuario_id', uid).maybeSingle();
      _perfil = datosPerfil;

      if (datosPerfil != null && datosPerfil['nombre_comercial'] != null && datosPerfil['nombre_comercial'].toString().isNotEmpty) {
        _nombreComercial = datosPerfil['nombre_comercial'];
      } else {
        final solicitud = await _supabase.from('solicitudes_registro').select('nombre_comercial').eq('usuario_id', uid).maybeSingle();
        if (solicitud != null && solicitud['nombre_comercial'] != null) {
          _nombreComercial = solicitud['nombre_comercial'];
        }
      }

      await cargarProductos();
      await cargarEstadisticasHoy();
      await cargarPedidosActivos();
      await cargarHistorial();

    } catch (e) {
      debugPrint('Error crítico cargando perfil: $e');
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  Future<void> recargarPantalla() async {
    await cargarEstadisticasHoy();
    await cargarPedidosActivos();
    await cargarProductos();
    await cargarHistorial();
  }

  // ==========================================
  // GESTIÓN DE PEDIDOS Y HISTORIAL
  // ==========================================

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

      _pedidosActivos = datos;
      notifyListeners();
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

      _historialPedidos = datos;
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando historial: $e');
    }
  }

  Future<void> actualizarEstadoPedido(String idPedido, String nuevoEstado) async {
    try {
      _estaCargando = true;
      notifyListeners();

      Map<String, dynamic> datosActualizar = {'estado': nuevoEstado};

      if (nuevoEstado == 'entregado') {
        datosActualizar['entregado_el'] = DateTime.now().toUtc().toIso8601String();
      }

      await _supabase.from('pedidos').update(datosActualizar).eq('id', idPedido);

      await cargarPedidosActivos();
      await cargarHistorial();
      await cargarEstadisticasHoy();
    } catch (e) {
      debugPrint('Error actualizando pedido: $e');
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  // AHORA EL PEDIDO DE PRUEBA INCLUYE UN CORREO FALSO
  /*Future<void> generarPedidoDePrueba() async {
    try {
      _estaCargando = true;
      notifyListeners();
      final uid = _supabase.auth.currentUser!.id;

      await _supabase.from('pedidos').insert({
        'negocio_id': uid,
        'nombre_cliente': 'Cliente de Prueba',
        'cliente_email': 'cliente.broma@gmail.com', // <--- CORREO SIMULADO
        'direccion_entrega': 'Calle de los Tacos #10, Misantla',
        'productos': [
          {'cantidad': 5, 'nombre': 'Tacos de Bistec', 'detalles': 'Con mucha salsa'},
          {'cantidad': 2, 'nombre': 'Agua de Horchata', 'detalles': ''},
        ],
        'total': 130.00,
        'estado': 'pendiente'
      });

      await cargarPedidosActivos();
      await cargarEstadisticasHoy();
    } catch (e) {
      debugPrint('Error generando pedido de prueba: $e');
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }*/

  // ==========================================
  // ESTADÍSTICAS DEL DÍA
  // ==========================================

  Future<void> cargarEstadisticasHoy() async {
    try {
      final uid = _supabase.auth.currentUser!.id;
      final hoy = DateTime.now();
      final inicioDia = DateTime(hoy.year, hoy.month, hoy.day).toUtc().toIso8601String();

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
        if (pedido['estado'] != 'cancelado') {
          totalPedidos++;
        }

        if (pedido['estado'] == 'entregado') {
          sumaGanancias += (pedido['total'] ?? 0).toDouble();

          if (pedido['entregado_el'] != null && pedido['creado_el'] != null) {
            final creado = DateTime.parse(pedido['creado_el']).toLocal();
            final entregado = DateTime.parse(pedido['entregado_el']).toLocal();
            final diferencia = entregado.difference(creado).inMinutes;
            sumaMinutos += diferencia;
            pedidosEntregados++;
          }
        }
      }

      _pedidosHoy = totalPedidos;
      _gananciasHoy = sumaGanancias;

      if (pedidosEntregados > 0) {
        int promedio = (sumaMinutos / pedidosEntregados).round();
        _tiempoPromedioHoy = "$promedio min";
      } else {
        _tiempoPromedioHoy = "-- min";
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
    }
  }

  // ==========================================
  // PRODUCTOS Y PERFIL
  // ==========================================

  Future<void> cargarProductos() async {
    try {
      final uid = _supabase.auth.currentUser!.id;
      final datosProductos = await _supabase.from('productos').select().eq('negocio_id', uid).order('creado_el');
      _productos = datosProductos;
      notifyListeners();
    } catch (e) {}
  }

  Future<String?> agregarProducto({
    required String nombre, required String descripcion, required double precio, required String categoria, required bool permitePersonalizacion, required String palabrasClave, File? imagen,
  }) async {
    _estaCargando = true;
    notifyListeners();
    try {
      final uid = _supabase.auth.currentUser!.id;
      String? urlImagen;
      if (imagen != null) {
        final ext = imagen.path.split('.').last;
        final nombreArchivo = 'producto_${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final ruta = 'productos/$nombreArchivo';
        await _supabase.storage.from('documentos_negocios').upload(ruta, imagen);
        urlImagen = _supabase.storage.from('documentos_negocios').getPublicUrl(ruta);
      }
      await _supabase.from('productos').insert({
        'negocio_id': uid, 'nombre': nombre, 'descripcion': descripcion, 'precio': precio, 'categoria': categoria, 'permite_personalizacion': permitePersonalizacion, 'palabras_clave': palabrasClave.toLowerCase(), 'url_imagen': urlImagen,
      });
      await cargarProductos();
      return null;
    } catch (e) { return 'Error: $e'; } finally { _estaCargando = false; notifyListeners(); }
  }

  Future<void> cambiarDisponibilidadProducto(String idProducto, bool estaDisponible) async {
    try { await _supabase.from('productos').update({'disponible': estaDisponible}).eq('id', idProducto); await cargarProductos(); } catch (e) {}
  }

  Future<void> eliminarProducto(String idProducto) async {
    try { _estaCargando = true; notifyListeners(); await _supabase.from('productos').delete().eq('id', idProducto); await cargarProductos(); } catch (e) {} finally { _estaCargando = false; notifyListeners(); }
  }

  Future<String?> actualizarInformacionBasica({
    required String nombre, required String telefono, required String tiempo, required String direccion, required double lat, required double lng, required String tipoEnvio, required double costoEnvio, required double envioGratisDesde,
  }) async {
    try {
      final uid = _supabase.auth.currentUser!.id;
      await _supabase.from('perfiles_negocios').update({
        'nombre_comercial': nombre, 'telefono_movil': telefono, 'tiempo_entrega': tiempo, 'direccion_texto': direccion, 'latitud': lat, 'longitud': lng, 'tipo_envio': tipoEnvio, 'costo_envio': costoEnvio, 'envio_gratis_desde': envioGratisDesde,
      }).eq('usuario_id', uid);
      await cargarDatosPerfil();
      return null;
    } catch (e) { return 'Error: $e'; }
  }

  Future<String?> agregarFotoGaleria() async {
    if (galeriaFotos.length >= 10) return 'Límite de 10 fotos alcanzado.';
    try {
      final resultado = await FilePicker.pickFiles(type: FileType.image);
      if (resultado == null) return null;
      _estaCargando = true;
      notifyListeners();
      final archivo = File(resultado.files.single.path!);
      final uid = _supabase.auth.currentUser!.id;
      final ext = archivo.path.split('.').last;
      final nombreArchivo = '${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ruta = 'galeria/$nombreArchivo';
      await _supabase.storage.from('documentos_negocios').upload(ruta, archivo);
      final urlPublica = _supabase.storage.from('documentos_negocios').getPublicUrl(ruta);
      List<String> fotosActualizadas = List.from(galeriaFotos)..add(urlPublica);
      await _supabase.from('perfiles_negocios').update({'galeria_fotos': jsonEncode(fotosActualizadas)}).eq('usuario_id', uid);
      await cargarDatosPerfil();
      return null;
    } catch (e) { return 'Error: $e'; } finally { _estaCargando = false; notifyListeners(); }
  }

  Future<String?> eliminarFotoGaleria(int index) async {
    try {
      _estaCargando = true;
      notifyListeners();
      final uid = _supabase.auth.currentUser!.id;
      List<String> fotosActualizadas = List.from(galeriaFotos);
      fotosActualizadas.removeAt(index);
      await _supabase.from('perfiles_negocios').update({'galeria_fotos': jsonEncode(fotosActualizadas)}).eq('usuario_id', uid);
      await cargarDatosPerfil();
      return null;
    } catch (e) { return 'Error: $e'; } finally { _estaCargando = false; notifyListeners(); }
  }

  // LÓGICA DE REPORTE ACTUALIZADA PARA RECIBIR IDs EXACTOS Y EL CORREO DEL CLIENTE
  Future<String?> levantarReporte({
    required String pedidoId,
    required String clienteEmail,
    required String motivo,
    required String detalles
  }) async {
    _estaCargando = true;
    notifyListeners();
    try {
      final uid = _supabase.auth.currentUser!.id;

      await _supabase.from('reportes').insert({
        'negocio_id': uid,
        'pedido_id': pedidoId,
        'cliente_email': clienteEmail,
        'referencia_cliente': 'Reporte Automático desde Pedido', // Valor legacy de respaldo
        'motivo': motivo,
        'detalles': detalles,
      });

      return null;
    } catch (e) {
      debugPrint('Error al enviar reporte: $e');
      return 'Ocurrió un error al enviar el reporte. Intenta de nuevo.';
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  Future<void> cerrarSesion() async => await _supabase.auth.signOut();
}