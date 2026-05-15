import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notas Firebase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const NotasPage(),
    );
  }
}

class NotasPage extends StatefulWidget {
  const NotasPage({super.key});

  @override
  State<NotasPage> createState() => _NotasPageState();
}

class _NotasPageState extends State<NotasPage> {
  final TextEditingController tituloController = TextEditingController();
  final TextEditingController notaController = TextEditingController();

  final CollectionReference notas =
  FirebaseFirestore.instance.collection('notas');

  Future<void> guardarNota() async {
    final String titulo = tituloController.text.trim();
    final String contenido = notaController.text.trim();

    if (titulo.isEmpty || contenido.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe título y nota')),
      );
      return;
    }

    await notas.add({
      'titulo': titulo,
      'contenido': contenido,
      'fecha': FieldValue.serverTimestamp(),
    });

    tituloController.clear();
    notaController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nota guardada en Firebase')),
    );
  }

  @override
  void dispose() {
    tituloController.dispose();
    notaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis notas'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: tituloController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notaController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nota',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: guardarNota,
                child: const Text('Guardar en Firebase'),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Notas guardadas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: notas.orderBy('fecha', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Error al cargar las notas'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final documentos = snapshot.data!.docs;

                  if (documentos.isEmpty) {
                    return const Center(
                      child: Text('Todavía no hay notas guardadas'),
                    );
                  }

                  return ListView.builder(
                    itemCount: documentos.length,
                    itemBuilder: (context, index) {
                      final nota =
                      documentos[index].data() as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          title: Text(nota['titulo'] ?? 'Sin título'),
                          subtitle: Text(nota['contenido'] ?? ''),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}