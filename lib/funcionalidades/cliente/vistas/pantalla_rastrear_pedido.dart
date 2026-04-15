import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vista_modelos/pedido_cliente_view_model.dart';

class PantallaRastrearPedido extends StatefulWidget {
  final String pedidoId;
  const PantallaRastrearPedido({super.key, required this.pedidoId});

  @override
  State<PantallaRastrearPedido> createState() => _PantallaRastrearPedidoState();
}

class _PantallaRastrearPedidoState extends State<PantallaRastrearPedido> {
  @override
  void initState() {
    super.initState();
    final vm = context.read<PedidoClienteViewModel>();
    vm.cargarPedidoActivo(widget.pedidoId);
    vm.escucharPedido(widget.pedidoId);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PedidoClienteViewModel>();
    final pedido = vm.pedidoActivo;
    final estado = pedido?['estado'] ?? 'pendiente';

    final pasos = ['pendiente', 'aceptado', 'preparacion', 'reparto', 'entregado'];
    final indiceActual = pasos.indexOf(estado);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastreando pedido'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: pedido == null
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.delivery_dining, size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              _textoEstado(estado),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(_subtextoEstado(estado),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),

            // Timeline de estados
            ..._construirTimeline(pasos, indiceActual),

            const Spacer(),

            if (estado == 'reparto')
              ElevatedButton.icon(
                onPressed: () async {
                  final error =
                  await vm.confirmarEntrega(widget.pedidoId);
                  if (!mounted) return;
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)));
                  }
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Confirmar que recibí mi pedido'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),

            if (estado == 'entregado') ...[
              const Icon(Icons.check_circle, size: 60, color: Colors.green),
              const SizedBox(height: 10),
              const Text('¡Pedido entregado!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/', (r) => false),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50)),
                child: const Text('Volver al inicio'),
              ),
            ]
          ],
        ),
      ),
    );
  }

  List<Widget> _construirTimeline(List<String> pasos, int indiceActual) {
    final etiquetas = [
      'Pedido enviado',
      'Aceptado',
      'En preparación',
      'En camino',
      'Entregado'
    ];
    return List.generate(pasos.length, (i) {
      final completado = i <= indiceActual;
      final esActual = i == indiceActual;
      return Row(
        children: [
          Column(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                    color: completado ? Colors.orange : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: esActual ? Colors.deepOrange : Colors.transparent,
                        width: 2)),
                child: Icon(
                    completado ? Icons.check : Icons.circle,
                    size: 14,
                    color: completado ? Colors.white : Colors.grey),
              ),
              if (i < pasos.length - 1)
                Container(
                    width: 2, height: 24,
                    color: i < indiceActual
                        ? Colors.orange
                        : Colors.grey.shade300),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(etiquetas[i],
                style: TextStyle(
                    fontWeight:
                    esActual ? FontWeight.bold : FontWeight.normal,
                    color: completado ? Colors.black87 : Colors.grey,
                    fontSize: 15)),
          ),
        ],
      );
    });
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'pendiente': return '⏳ Esperando confirmación';
      case 'aceptado': return '✅ Pedido aceptado';
      case 'preparacion': return '👨‍🍳 Preparando tu orden';
      case 'reparto': return '🛵 ¡En camino!';
      case 'entregado': return '🎉 ¡Entregado!';
      default: return estado;
    }
  }

  String _subtextoEstado(String estado) {
    switch (estado) {
      case 'pendiente': return 'La taquería está revisando tu pedido';
      case 'aceptado': return 'Tu pedido fue aceptado, pronto comenzarán';
      case 'preparacion': return 'Están preparando tus tacos con cariño 🌮';
      case 'reparto': return 'El repartidor ya salió con tu pedido';
      case 'entregado': return '¡Buen provecho!';
      default: return '';
    }
  }
}