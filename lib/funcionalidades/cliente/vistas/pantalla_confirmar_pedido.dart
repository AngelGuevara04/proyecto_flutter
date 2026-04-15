import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../vista_modelos/pedido_cliente_view_model.dart';

class PantallaConfirmarPedido extends StatefulWidget {
  final Map<String, dynamic> taqueria;
  const PantallaConfirmarPedido({super.key, required this.taqueria});

  @override
  State<PantallaConfirmarPedido> createState() =>
      _PantallaConfirmarPedidoState();
}

class _PantallaConfirmarPedidoState extends State<PantallaConfirmarPedido> {
  final _direccionCtrl = TextEditingController();
  final _referenciasCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final meta =
        Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
    final calle = meta['calle'] ?? '';
    final colonia = meta['colonia'] ?? '';
    final ciudad = meta['ciudad'] ?? '';
    if (calle.isNotEmpty) {
      _direccionCtrl.text = '$calle, $colonia, $ciudad'.trim();
    }
  }

  @override
  void dispose() {
    _direccionCtrl.dispose();
    _referenciasCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  // Calcular costo de envío
  double _calcularCostoEnvio(double totalProductos) {
    final tipo = widget.taqueria['tipo_envio'] ?? 'gratis';
    final costo = (widget.taqueria['costo_envio'] ?? 0).toDouble();
    final gratisDesde =
    (widget.taqueria['envio_gratis_desde'] ?? 0).toDouble();

    if (tipo == 'gratis') return 0;
    if (tipo == 'fijo') return costo;
    if (tipo == 'umbral') {
      return totalProductos >= gratisDesde ? 0 : costo;
    }
    return 0;
  }

  String? _validarTelefono(String tel) {
    if (tel.isEmpty) return 'Ingresa tu número de contacto';
    if (tel.length != 10) return 'El número debe tener exactamente 10 dígitos';
    if (!RegExp(r'^[0-9]+$').hasMatch(tel)) {
      return 'El número solo debe contener dígitos';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PedidoClienteViewModel>();
    final meta =
        Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
    final nombreCliente = meta['full_name'] ?? 'Cliente';

    final costoEnvio = _calcularCostoEnvio(vm.total);
    final totalConEnvio = vm.total + costoEnvio;
    final tipo = widget.taqueria['tipo_envio'] ?? 'gratis';
    final gratisDesde =
    (widget.taqueria['envio_gratis_desde'] ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar pedido'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen del carrito
            const Text('Tu pedido',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...vm.carrito.map((item) => ListTile(
              dense: true,
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade50,
                child: Text('${item['cantidad']}',
                    style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold)),
              ),
              title: Text(item['nombre']),
              trailing: Text(
                  '\$${(item['precio'] * item['cantidad']).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
            const Divider(),

            // Desglose de costos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:',
                    style: TextStyle(color: Colors.grey)),
                Text('\$${vm.total.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.delivery_dining,
                        size: 16,
                        color: costoEnvio == 0 ? Colors.green : Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      costoEnvio == 0
                          ? 'Envío gratis'
                          : 'Costo de envío:',
                      style: TextStyle(
                          color:
                          costoEnvio == 0 ? Colors.green : Colors.blue),
                    ),
                  ],
                ),
                Text(
                  costoEnvio == 0
                      ? 'Gratis ✅'
                      : '+\$${costoEnvio.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: costoEnvio == 0 ? Colors.green : Colors.blue,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),

            // Mensaje de umbral si aplica
            if (tipo == 'umbral' && costoEnvio > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Agrega \$${(gratisDesde - vm.total).toStringAsFixed(0)} más para envío gratis',
                style: const TextStyle(
                    color: Colors.deepPurple,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            ],

            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total a pagar en efectivo:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text('\$${totalConEnvio.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ],
            ),
            const SizedBox(height: 24),

            // ── Datos de entrega ──
            const Text('Datos de entrega',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _direccionCtrl,
              decoration: const InputDecoration(
                labelText: 'Dirección de entrega',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referenciasCtrl,
              decoration: const InputDecoration(
                labelText: 'Referencias (color de casa, entre calles...)',
                border: OutlineInputBorder(),
                prefixIcon:
                Icon(Icons.info_outline, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Número de contacto (10 dígitos)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone, color: Colors.orange),
                counterText: '',
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200)),
              child: const Row(
                children: [
                  Icon(Icons.payments, color: Colors.green),
                  SizedBox(width: 8),
                  Text('El pago se realiza en efectivo al recibir.',
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: vm.estaCargando
                  ? null
                  : () async {
                final errorTel =
                _validarTelefono(_telefonoCtrl.text.trim());
                if (errorTel != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(errorTel),
                      backgroundColor: Colors.red));
                  return;
                }

                if (_direccionCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                          Text('Ingresa tu dirección de entrega'),
                          backgroundColor: Colors.red));
                  return;
                }

                final error = await vm.crearPedidoLibre(
                  negocioId: widget.taqueria['usuario_id'],
                  nombreCliente: nombreCliente,
                  direccionEntrega: _direccionCtrl.text.trim(),
                  referencias: _referenciasCtrl.text.trim(),
                  telefonoContacto: _telefonoCtrl.text.trim(),
                  costoEnvio: costoEnvio,
                  totalConEnvio: totalConEnvio,
                );
                if (!mounted) return;

                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '🌮 Tu pedido ha sido solicitado con éxito, en espera de confirmación de la taquería. Por favor sea paciente.',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 4),
                    ),
                  );
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
              child: vm.estaCargando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                  'Enviar pedido — \$${totalConEnvio.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}