import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'inicioDeSesion/login_screen.dart';
import 'menuInicialClientes/inicio_clientes_screen.dart';
import 'menuInicialNegocios/inicio_negocios_screen.dart';
import 'registro/registro_screen.dart';
import 'perfil/perfil_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TacoHub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/registro': (context) => const RegisterScreen(),
        '/home': (context) => const InicioScreen(),
        '/home_negocio': (context) => const InicioNegocioScreen(),
        '/perfil': (context) => const PerfilScreen(),
      },
    );
  }
}
