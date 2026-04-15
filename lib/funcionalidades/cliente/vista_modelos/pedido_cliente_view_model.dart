import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PedidoClienteViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // ── Carrito ──
  final List<Map<String, dynamic>> _carrito = [];
  List<Map<String, dynamic>> get carrito => _carrito;

  double get total => _carrito.fold(
      0, (suma, item) => suma + (item['precio'] * item['cantidad']));

  int get totalItems =>
      _carrito.fold(0, (suma, item) => suma + (item['cantidad'] as int));

  // ── Estado ──
  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  String? _pedidoActivoId;
  String? get pedidoActivoId => _pedidoActivoId;

  Map<String, dynamic>? _pedidoActivo;
  Map<String, dynamic>? get pedidoActivo => _pedidoActivo;

  // ── Carrito ──
  void agregarAlCarrito(Map<String, dynamic> producto) {
    final index = _carrito.indexWhere((p) => p['id'] == producto['id']);
    if (index >= 0) {
      _carrito[index]['cantidad']++;
    } else {
      _carrito.add({...producto, 'cantidad': 1});
    }
    notifyListeners();
  }

  void quitarDelCarrito(String idProducto) {
    final index = _carrito.indexWhere((p) => p['id'] == idProducto);
    if (index >= 0) {
      if (_carrito[index]['cantidad'] > 1) {
        _carrito[index]['cantidad']--;
      } else {
        _carrito.removeAt(index);
      }
    }
    notifyListeners();
  }

  void limpiarCarrito() {
    _carrito.clear();
    notifyListeners();
  }

  int cantidadEnCarrito(String idProducto) {
    final item = _carrito.firstWhere(
          (p) => p['id'] == idProducto,
      orElse: () => {'cantidad': 0},
    );
    return item['cantidad'] as int;
  }

  // ── Crear pedido Modo Libre ──
  Future<String?> crearPedidoLibre({
    required String negocioId,
    required String nombreCliente,
    required String direccionEntrega,
    required String referencias,
    required String telefonoContacto,
  }) async {
    if (_carrito.isEmpty) return 'El carrito está vacío';
    if (direccionEntrega.isEmpty) return 'Ingresa tu dirección de entrega';
    if (telefonoContacto.isEmpty) return 'Ingresa tu número de contacto';

    _estaCargando = true;
    notifyListeners();

    try {
      final uid = _supabase.auth.currentUser!.id;
      final email = _supabase.auth.currentUser!.email ?? '';

      final productosParaGuardar = _carrito
          .map((p) => {
        'id': p['id'],
        'nombre': p['nombre'],
        'precio': p['precio'],
        'cantidad': p['cantidad'],
        'detalles': p['detalles'] ?? '',
      })
          .toList();

      final respuesta = await _supabase.from('pedidos').insert({
        'negocio_id': negocioId,
        'cliente_id': uid,
        'cliente_email': email,
        'nombre_cliente': nombreCliente,
        'direccion_entrega': direccionEntrega,
        'referencias': referencias,
        'telefono_contacto': telefonoContacto,
        'productos': jsonEncode(productosParaGuardar),
        'total': total,
        'estado': 'pendiente',
        'tipo': 'libre',
      }).select().single();

      _pedidoActivoId = respuesta['id'].toString();
      limpiarCarrito();
      return null;
    } catch (e) {
      debugPrint('Error creando pedido: $e');
      return 'Error al enviar el pedido: $e';
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  // ── Rastrear pedido activo en tiempo real ──
  RealtimeChannel? _canal;

  void escucharPedido(String pedidoId) {
    _canal = _supabase
        .channel('pedido_$pedidoId')
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'pedidos',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: pedidoId,
      ),
      callback: (payload) {
        _pedidoActivo = payload.newRecord;
        notifyListeners();
      },
    )
        .subscribe();
  }

  Future<void> cargarPedidoActivo(String pedidoId) async {
    try {
      final datos = await _supabase
          .from('pedidos')
          .select()
          .eq('id', pedidoId)
          .single();
      _pedidoActivo = datos;
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando pedido: $e');
    }
  }

  Future<String?> confirmarEntrega(String pedidoId) async {
    try {
      await _supabase.from('pedidos').update({
        'estado': 'entregado',
        'entregado_el': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', pedidoId);
      _pedidoActivo?['estado'] = 'entregado';
      notifyListeners();
      return null;
    } catch (e) {
      return 'Error al confirmar: $e';
    }
  }

  @override
  void dispose() {
    _canal?.unsubscribe();
    super.dispose();
  }
}