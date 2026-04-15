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

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final uid = _supabase.auth.currentUser!.id;
      final datos = await _supabase
          .from('pedidos')
          .select()
          .eq('cliente_id', uid)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
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
            final fecha = DateTime.parse(p['creado_el']).toLocal();
            final activo = !['entregado', 'cancelado']
                .contains(estado);

            return Card(
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
                      color:
                      activo ? Colors.orange : Colors.grey),
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