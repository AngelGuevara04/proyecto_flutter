import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaMisPedidosCliente extends StatefulWidget {
  const PantallaMisPedidosCliente({super.key});

  @override
  State<PantallaMisPedidosCliente> createState() =>
      _PantallaMisPedidosClienteState();
}

class _PantallaMisPedidosClienteState
    extends State<PantallaMisPedidosCliente> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _pedidos = [];
  bool _cargando = true;
  RealtimeChannel? _canal;

  @override
  void initState() {
    super.initState();
    _cargar();
    _escucharCambios();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final uid = _supabase.auth.currentUser!.id;
      final datos = await _supabase
          .from('pedidos')
          .select()
          .eq('cliente_id', uid)
          .eq('oculto_cliente', false)
          .order('creado_el', ascending: false)
          .limit(50);
      setState(() {
        _pedidos = datos;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  void _escucharCambios() {
    final uid = _supabase.auth.currentUser!.id;
    _canal = _supabase
        .channel('mis_pedidos_$uid')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'pedidos',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'cliente_id',
        value: uid,
      ),
      callback: (payload) => _cargar(),
    )
        .subscribe();
  }

  // Oculta un pedido individual
  Future<void> _ocultarPedido(String pedidoId) async {
    try {
      await _supabase
          .from('pedidos')
          .update({'oculto_cliente': true})
          .eq('id', pedidoId);
      setState(() {
        _pedidos.removeWhere((p) => p['id'].toString() == pedidoId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar el pedido')),
        );
      }
    }
  }

  // Oculta todo el historial de una vez
  Future<void> _limpiarTodoElHistorial() async {
    try {
      final uid = _supabase.auth.currentUser!.id;
      await _supabase
          .from('pedidos')
          .update({'oculto_cliente': true})
          .eq('cliente_id', uid)
          .inFilter('estado', ['entregado', 'cancelado']);
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Historial limpiado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al limpiar el historial')),
        );
      }
    }
  }

  // Diálogo de confirmación para borrar todo
  void _confirmarLimpiarTodo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Limpiar historial?'),
        content: const Text(
            'Se eliminarán de tu vista todos los pedidos entregados y cancelados. El negocio seguirá teniendo acceso al registro.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _limpiarTodoElHistorial();
            },
            child: const Text('Limpiar todo'),
          ),
        ],
      ),
    );
  }

  // Diálogo de confirmación para borrar uno
  void _confirmarOcultarPedido(String pedidoId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar este pedido?'),
        content: const Text('Se quitará de tu historial pero el negocio seguirá viéndolo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _ocultarPedido(pedidoId);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _canal?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hayHistorial = _pedidos.any((p) =>
        ['entregado', 'cancelado'].contains(p['estado']));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          // Botón limpiar todo — solo aparece si hay pedidos finalizados
          if (hayHistorial)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Limpiar historial',
              onPressed: _confirmarLimpiarTodo,
            ),
        ],
      ),
      body: _cargando
          ? const Center(
          child: CircularProgressIndicator(color: Colors.orange))
          : _pedidos.isEmpty
          ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 70, color: Colors.grey),
              SizedBox(height: 16),
              Text('Aún no has realizado pedidos',
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ))
          : RefreshIndicator(
        onRefresh: _cargar,
        color: Colors.orange,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _pedidos.length,
          itemBuilder: (context, i) {
            final p = _pedidos[i];
            final estado = p['estado'];
            final fecha =
            DateTime.parse(p['creado_el']).toLocal();
            final estaFinalizado =
            ['entregado', 'cancelado'].contains(estado);
            final activo = !estaFinalizado;

            return Dismissible(
              // Deslizar para eliminar — solo en pedidos finalizados
              key: Key(p['id'].toString()),
              direction: estaFinalizado
                  ? DismissDirection.endToStart
                  : DismissDirection.none,
              confirmDismiss: (_) async {
                _confirmarOcultarPedido(p['id'].toString());
                return false; // Lo manejamos manualmente
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete, color: Colors.white, size: 28),
                    Text('Eliminar',
                        style: TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: activo
                        ? Colors.orange.shade100
                        : Colors.grey.shade200,
                    child: Icon(
                        activo
                            ? Icons.delivery_dining
                            : Icons.check_circle,
                        color: activo
                            ? Colors.orange
                            : Colors.grey),
                  ),
                  title: Text(
                      'Pedido #${p['id'].toString().substring(0, 5).toUpperCase()}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('dd/MM/yyyy HH:mm')
                          .format(fecha)),
                      Text(
                          '\$${p['total']} • ${_etiqueta(estado)}',
                          style: TextStyle(
                              color: _colorEstado(estado),
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  isThreeLine: true,
                  // Botón de eliminar individual en pedidos finalizados
                  trailing: estaFinalizado
                      ? IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red),
                    onPressed: () => _confirmarOcultarPedido(
                        p['id'].toString()),
                  )
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _etiqueta(String estado) {
    switch (estado) {
      case 'pendiente': return 'Esperando';
      case 'aceptado': return 'Aceptado';
      case 'preparacion': return 'Preparando';
      case 'reparto': return 'En camino';
      case 'entregado': return 'Entregado';
      case 'cancelado': return 'Cancelado';
      default: return estado;
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'entregado': return Colors.green;
      case 'cancelado': return Colors.red;
      case 'reparto': return Colors.teal;
      default: return Colors.orange;
    }
  }
}