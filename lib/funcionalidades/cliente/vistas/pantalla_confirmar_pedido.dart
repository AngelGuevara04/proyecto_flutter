import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../vista_modelos/pedido_cliente_view_model.dart';
import 'pantalla_rastrear_pedido.dart';

class PantallaConfirmarPedido extends StatefulWidget {
  final Map<String, dynamic> taqueria;
  const PantallaConfirmarPedido({super.key, required this.taqueria});

  @override
  State<PantallaConfirmarPedido> createState() =>
      _PantallaConfirmarPedidoState();
}

class _PantallaConfirmarPedidoState
    extends State<PantallaConfirmarPedido> {
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
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total a pagar en efectivo:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text('\$${vm.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ],
            ),
            const SizedBox(height: 24),

            // Datos de entrega
            const Text('Datos de entrega',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _direccionCtrl,
              decoration: const InputDecoration(
                labelText: 'Dirección de entrega',
                border: OutlineInputBorder(),
                prefixIcon:
                Icon(Icons.location_on, color: Colors.orange),
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
                // Validar teléfono
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
                );
                if (!mounted) return;

                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red));
                } else {
                  // Mostrar el mensaje de éxito
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '🌮 Tu pedido ha sido solicitado con éxito, en espera de confirmación de la taquería. Por favor sea paciente.',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 4), // Le damos 4 segundos para que lo lea bien
                    ),
                  );

                  // Volver a la pantalla de inicio del cliente (cierra esta ventana y la lista de taquerías)
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
                  : const Text('Enviar pedido',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}