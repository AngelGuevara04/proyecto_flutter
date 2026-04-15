import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../vista_modelos/inicio_negocio_view_model.dart';

class PantallaEditarProducto extends StatefulWidget {
  final Map<String, dynamic> producto;
  const PantallaEditarProducto({super.key, required this.producto});

  @override
  State<PantallaEditarProducto> createState() =>
      _PantallaEditarProductoState();
}

class _PantallaEditarProductoState extends State<PantallaEditarProducto> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _precioCtrl;
  late TextEditingController _palabrasClaveCtrl;

  late String _categoria;
  late bool _permitePersonalizacion;
  File? _nuevaImagen;
  String? _urlImagenActual;

  @override
  void initState() {
    super.initState();
    _nombreCtrl =
        TextEditingController(text: widget.producto['nombre'] ?? '');
    _descCtrl =
        TextEditingController(text: widget.producto['descripcion'] ?? '');
    _precioCtrl = TextEditingController(
        text: widget.producto['precio']?.toString() ?? '');
    _palabrasClaveCtrl =
        TextEditingController(text: widget.producto['palabras_clave'] ?? '');
    _categoria = widget.producto['categoria'] ?? 'Tacos';
    _permitePersonalizacion =
        widget.producto['permite_personalizacion'] ?? true;
    _urlImagenActual = widget.producto['url_imagen'];
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _precioCtrl.dispose();
    _palabrasClaveCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final resultado = await FilePicker.pickFiles(type: FileType.image);
    if (resultado != null) {
      setState(() => _nuevaImagen = File(resultado.files.single.path!));
    }
  }

  void _guardar() async {
    if (_formKey.currentState!.validate()) {
      final vm = context.read<InicioNegocioViewModel>();
      final error = await vm.editarProducto(
        idProducto: widget.producto['id'].toString(),
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descCtrl.text.trim(),
        precio: double.parse(_precioCtrl.text),
        categoria: _categoria,
        permitePersonalizacion: _permitePersonalizacion,
        palabrasClave: _palabrasClaveCtrl.text.trim(),
        nuevaImagen: _nuevaImagen,
      );
      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Platillo actualizado ✅')));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InicioNegocioViewModel>();

    return Scaffold(
      appBar: AppBar(
          title: const Text('Editar Platillo'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white),
      body: vm.estaCargando
          ? const Center(
          child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen
              Center(
                child: GestureDetector(
                  onTap: _seleccionarImagen,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border:
                      Border.all(color: Colors.grey.shade400),
                    ),
                    child: _nuevaImagen != null
                        ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_nuevaImagen!,
                            fit: BoxFit.cover))
                        : _urlImagenActual != null
                        ? ClipRRect(
                        borderRadius:
                        BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(_urlImagenActual!,
                                fit: BoxFit.cover),
                            Container(
                              color: Colors.black26,
                              child: const Column(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit,
                                      color: Colors.white,
                                      size: 30),
                                  Text('Cambiar foto',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ))
                        : const Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo,
                            size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Agregar foto',
                            style: TextStyle(
                                color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nombre del platillo',
                    border: OutlineInputBorder()),
                validator: (v) =>
                v!.isEmpty ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _precioCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Precio (\$)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money)),
                validator: (v) =>
                v!.isEmpty ? 'Ingresa el precio' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _categoria,
                decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                      value: 'Tacos', child: Text('Tacos')),
                  DropdownMenuItem(
                      value: 'Tortas', child: Text('Tortas')),
                  DropdownMenuItem(
                      value: 'Bebidas', child: Text('Bebidas')),
                  DropdownMenuItem(
                      value: 'Postres', child: Text('Postres')),
                  DropdownMenuItem(
                      value: 'Otros', child: Text('Otros')),
                ],
                onChanged: (val) =>
                    setState(() => _categoria = val!),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Descripción (Opcional)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              const Text('Palabras clave de búsqueda',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _palabrasClaveCtrl,
                decoration: const InputDecoration(
                  labelText: 'Separadas por coma',
                  hintText: 'Ej: pastor, cerdo, trompo',
                  border: OutlineInputBorder(),
                  prefixIcon:
                  Icon(Icons.search, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: Colors.orange.shade200)),
                child: SwitchListTile(
                  title:
                  const Text('¿Permite elegir salsas/verduras?'),
                  subtitle:
                  const Text('Se preguntará al cliente al pedir.'),
                  value: _permitePersonalizacion,
                  activeColor: Colors.orange,
                  onChanged: (val) => setState(
                          () => _permitePersonalizacion = val),
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _guardar,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.orange),
                child: const Text('Guardar Cambios',
                    style: TextStyle(
                        color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}