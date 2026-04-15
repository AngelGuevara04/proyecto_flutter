import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vista_modelos/pedido_cliente_view_model.dart';

class PantallaRastrearPedido extends StatefulWidget {
  final String pedidoId;
  const PantallaRastrearPedido({super.key, required this.pedidoId});

  @override
  State<PantallaRastrearPedido> createState() =>
      _PantallaRastrearPedidoState();
}

class _PantallaRastrearPedidoState extends State<PantallaRastrearPedido> {
  @override
  void initState() {
    super.initState();
    final vm = context.read<PedidoClienteViewModel>();
    vm.cargarPedidoActivo(widget.pedidoId);
    vm.escucharPedido(widget.pedidoId);
  }

  void _confirmarCancelar(BuildContext context, PedidoClienteViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar pedido?'),
        content: const Text(
            'El pedido aún no ha sido tomado por ninguna taquería. ¿Deseas cancelarlo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('No, esperar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await vm.cancelarPedido(widget.pedidoId);
              if (!mounted) return;
              if (error != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error)));
              } else {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (r) => false);
              }
            },
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PedidoClienteViewModel>();
    final pedido = vm.pedidoActivo;
    final estado = pedido?['estado'] ?? 'buscando';
    final esExpres = pedido?['tipo'] == 'expres';

    final pasos = esExpres
        ? ['buscando', 'pendiente', 'aceptado', 'preparacion', 'reparto', 'entregado']
        : ['pendiente', 'aceptado', 'preparacion', 'reparto', 'entregado'];

    final etiquetas = esExpres
        ? ['Buscando taquería', 'Pedido recibido', 'Aceptado', 'En preparación', 'En camino', 'Entregado']
        : ['Pedido enviado', 'Aceptado', 'En preparación', 'En camino', 'Entregado'];

    final indiceActual = pasos.indexOf(estado);

    return Scaffold(
      appBar: AppBar(
        title: Text(esExpres ? 'Pedido Exprés ⚡' : 'Rastreando pedido'),
        backgroundColor: esExpres ? Colors.deepOrange : Colors.orange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: pedido == null
          ? const Center(
          child: CircularProgressIndicator(color: Colors.orange))
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              estado == 'buscando'
                  ? Icons.search
                  : estado == 'entregado'
                  ? Icons.check_circle
                  : Icons.delivery_dining,
              size: 80,
              color: estado == 'buscando'
                  ? Colors.deepOrange
                  : estado == 'entregado'
                  ? Colors.green
                  : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              _textoEstado(estado),
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(_subtextoEstado(estado),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),

            // Timeline
            Expanded(
              child: ListView(
                children: List.generate(pasos.length, (i) {
                  final completado = i <= indiceActual;
                  final esActual = i == indiceActual;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                                color: completado
                                    ? (esExpres
                                    ? Colors.deepOrange
                                    : Colors.orange)
                                    : Colors.grey.shade200,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: esActual
                                        ? Colors.deepOrange
                                        : Colors.transparent,
                                    width: 2)),
                            child: Icon(
                                completado
                                    ? Icons.check
                                    : Icons.circle,
                                size: 14,
                                color: completado
                                    ? Colors.white
                                    : Colors.grey),
                          ),
                          if (i < pasos.length - 1)
                            Container(
                                width: 2,
                                height: 30,
                                color: i < indiceActual
                                    ? (esExpres
                                    ? Colors.deepOrange
                                    : Colors.orange)
                                    : Colors.grey.shade300),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Text(
                          etiquetas[i],
                          style: TextStyle(
                              fontWeight: esActual
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: completado
                                  ? Colors.black87
                                  : Colors.grey,
                              fontSize: 15),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

            // Confirmar entrega
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

            // Pedido entregado
            if (estado == 'entregado') ...[
              const Icon(Icons.check_circle,
                  size: 60, color: Colors.green),
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
            ],

            // ── Buscando taquería (exprés) ──
            if (estado == 'buscando') ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(
                  color: Colors.deepOrange),
              const SizedBox(height: 8),
              const Text(
                  'Esperando que una taquería tome tu pedido...',
                  style:
                  TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              // ── BOTÓN CANCELAR ──
              OutlinedButton.icon(
                onPressed: () => _confirmarCancelar(context, vm),
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text('Cancelar pedido',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(46),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'buscando':   return '🔍 Buscando taquería...';
      case 'pendiente':  return '⏳ Esperando confirmación';
      case 'aceptado':   return '✅ Pedido aceptado';
      case 'preparacion':return '👨‍🍳 Preparando tu orden';
      case 'reparto':    return '🛵 ¡En camino!';
      case 'entregado':  return '🎉 ¡Entregado!';
      default:           return estado;
    }
  }

  String _subtextoEstado(String estado) {
    switch (estado) {
      case 'buscando':    return 'Estamos encontrando la taquería más cercana para ti';
      case 'pendiente':   return 'La taquería está revisando tu pedido';
      case 'aceptado':    return 'Tu pedido fue aceptado, pronto comenzarán';
      case 'preparacion': return 'Están preparando tus tacos con cariño 🌮';
      case 'reparto':     return 'El repartidor ya salió con tu pedido';
      case 'entregado':   return '¡Buen provecho!';
      default:            return '';
    }
  }
}