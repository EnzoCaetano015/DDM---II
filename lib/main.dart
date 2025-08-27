import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: MyPokedex(),
    );
  }
}

class MyPokedex extends StatefulWidget {
  const MyPokedex({super.key});

  @override
  State<MyPokedex> createState() => _MyPokedexState();
}

class _MyPokedexState extends State<MyPokedex> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _pokemon;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _buscarPokemon() async {
    final input = _controller.text.trim().toLowerCase();
    if (input.isEmpty) {
      _showSnack('Digite um ID ou nome de Pokémon.');
      return;
    }

    setState(() {
      _loading = true;
      _pokemon = null;
    });

    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon/$input');

    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() => _pokemon = data);
      } else if (resp.statusCode == 404) {
        _showSnack('Pokémon não encontrado.');
      } else {
        _showSnack('Erro ${resp.statusCode} ao buscar Pokémon.');
      }
    } catch (e) {
      _showSnack('Falha na conexão. Verifique sua internet.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          'Pokédex',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Column(
            children: [
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/PokémonLogo.png", width: 180),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      controller: _controller,
                      onSubmitted: (_) => _buscarPokemon(),
                      decoration: const InputDecoration(
                        hintText: "Digite o ID do Pokémon...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _loading ? null : _buscarPokemon,
                    style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.black87),
                      foregroundColor: WidgetStatePropertyAll(Colors.white),
                    ),
                    icon: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_pokemon != null) _PokemonCard(data: _pokemon!)
            ],
          ),
        ],
      ),
    );
  }
}

class _PokemonCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PokemonCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] as String?)?.toUpperCase() ?? 'DESCONHECIDO';
    final id = data['id']?.toString() ?? '-';
    final sprites = data['sprites'] as Map<String, dynamic>?;
    final img = sprites?['front_default'] as String?;
    final types = (data['types'] as List?)
            ?.map((t) => t['type']?['name'])
            .whereType<String>()
            .toList() ??
        [];

    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (img != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(img, width: 96, height: 96),
              )
            else
              const Icon(Icons.image_not_supported, size: 64),
            const SizedBox(width: 16),
            Expanded(
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.black),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$name  #$id',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Tipos: ${types.join(', ').toUpperCase()}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
