import 'package:flutter/material.dart';
import 'inicioDeSesion/login_screen.dart';
import 'menuInicialClientes/inicio_clientes_screen.dart';
import 'menuInicialNegocios/inicio_negocios_screen.dart';
import 'registro/registro_screen.dart';

void main() {
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
      },
    );
  }
}
