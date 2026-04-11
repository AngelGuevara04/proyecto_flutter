import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

// 1. Importamos las Vistas (Las pantallas)
import 'funcionalidades/autenticacion/vistas/pantalla_login.dart';
import 'funcionalidades/autenticacion/vistas/pantalla_registro.dart';
import 'funcionalidades/cliente/vistas/pantalla_inicio_cliente.dart';
import 'funcionalidades/negocio/vistas/pantalla_inicio_negocio.dart';
import 'funcionalidades/perfil/vistas/pantalla_perfil.dart';

// 2. Importamos los ViewModels (Los cerebros)
import 'funcionalidades/autenticacion/vista_modelos/login_view_model.dart';
import 'funcionalidades/autenticacion/vista_modelos/registro_view_model.dart';
import 'funcionalidades/cliente/vista_modelos/inicio_cliente_view_model.dart';
import 'funcionalidades/negocio/vista_modelos/inicio_negocio_view_model.dart';
import 'funcionalidades/perfil/vista_modelos/perfil_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mantenemos tu conexión intacta
  await Supabase.initialize(
    url: 'https://qrzbpuzkcoenjxdheeus.supabase.co',
    anonKey: 'sb_publishable_PsgT7XI44o5qftL8Pp4J3Q_bVlovTXX',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Lógica para mantener la sesión iniciada
    final sesion = Supabase.instance.client.auth.currentSession;
    String rutaInicial = '/';

    if (sesion != null) {
      final esNegocio = sesion.user.userMetadata?['is_business'] ?? false;
      rutaInicial = esNegocio ? '/home_negocio' : '/home';
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TacoHub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      initialRoute: rutaInicial,
      routes: {
        // 3. Enlazamos cada Vista con su ViewModel usando Provider
        '/': (context) => ChangeNotifierProvider(
              create: (_) => LoginViewModel(),
              child: const PantallaLogin(),
            ),
        '/registro': (context) => ChangeNotifierProvider(
              create: (_) => RegistroViewModel(),
              child: const PantallaRegistro(),
            ),
        '/home': (context) => ChangeNotifierProvider(
              create: (_) => InicioClienteViewModel(),
              child: const PantallaInicioCliente(),
            ),
        '/home_negocio': (context) => ChangeNotifierProvider(
              create: (_) => InicioNegocioViewModel(),
              child: const PantallaInicioNegocio(),
            ),
        '/perfil': (context) => ChangeNotifierProvider(
              create: (_) => PerfilViewModel(),
              child: const PantallaPerfil(),
            ),
      },
    );
  }
}