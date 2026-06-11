import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'db_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}

class Catatan {
  final int? id;
  final String judul;
  final String isi;
  final String kategori;
  final String emailPengirim;
  final DateTime dibuatPada;

  Catatan({
    this.id,
    required this.judul,
    required this.isi,
    required this.kategori,
    required this.emailPengirim,
    required this.dibuatPada,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'judul': judul,
        'isi': isi,
        'kategori': kategori,
        'email_pengirim': emailPengirim,
        'dibuat_pada': dibuatPada.millisecondsSinceEpoch,
      };

  static Catatan fromMap(Map<String, Object?> m) => Catatan(
        id: m['id'] as int?,
        judul: m['judul'] as String,
        isi: m['isi'] as String,
        kategori: m['kategori'] as String,
        emailPengirim: m['email_pengirim'] as String,
        dibuatPada: DateTime.fromMillisecondsSinceEpoch(m['dibuat_pada'] as int),
      );

  Catatan copyWith({
    String? judul,
    String? isi,
    String? kategori,
    String? emailPengirim,
  }) =>
      Catatan(
        id: id,
        judul: judul ?? this.judul,
        isi: isi ?? this.isi,
        kategori: kategori ?? this.kategori,
        emailPengirim: emailPengirim ?? this.emailPengirim,
        dibuatPada: dibuatPada,
      );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catatan Mahasiswa Super App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/tambah-edit':
          // Menerima argument opsional berupa objek Catatan untuk mode Edit
            final argumen = settings.arguments as Catatan?;
            return MaterialPageRoute(
              builder: (_) => TambahCatatanPage(catatanDiubah: argumen),
            );
          case '/detail':
            final catatan = settings.arguments as Catatan;
            return MaterialPageRoute(
              builder: (_) => DetailCatatanPage(catatan: catatan),
            );
        }
        return null;
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Catatan>> _futureCatatan;
  String _kategoriTerpilih = 'Semua';
  final List<String> _filterOpsi = ['Semua', 'Kuliah', 'Tugas', 'Pribadi', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _muatUlang();
  }

  void _muatUlang() {
    setState(() {
      _futureCatatan = DbHelper.instance.getAll();
    });
  }

  Future<void> _bukaTambahCatatan() async {
    await Navigator.pushNamed(context, '/tambah-edit');
    _muatUlang();
  }

  Future<void> _bukaDetailCatatan(Catatan catatanTarget) async {
    await Navigator.pushNamed(context, '/detail', arguments: catatanTarget);
    _muatUlang();
  }

  Future<void> _konfirmasiHapus(Catatan c) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text('"${c.judul}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (yakin == true) {
      await DbHelper.instance.delete(c.id!);
      if (!mounted) return;
      _muatUlang();
      _tampilkanSnackbar('Catatan "${c.judul}" dihapus');
    }
  }

  void _tampilkanSnackbar(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan)),
    );
  }

  String _formatTanggal(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Mahasiswa'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          DropdownButton<String>(
            value: _kategoriTerpilih,
            icon: const Icon(Icons.filter_alt, color: Colors.indigo),
            underline: const SizedBox(),
            items: _filterOpsi.map((String kat) {
              return DropdownMenuItem<String>(
                value: kat,
                child: Text(kat),
              );
            }).toList(),
            onChanged: (String? nilaiBaru) {
              if (nilaiBaru != null) {
                setState(() => _kategoriTerpilih = nilaiBaru);
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<List<Catatan>>(
        future: _futureCatatan,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final allData = snapshot.data ?? const [];
          final listTersaring = _kategoriTerpilih == 'Semua'
              ? allData
              : allData.where((c) => c.kategori == _kategoriTerpilih).toList();

          if (listTersaring.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _kategoriTerpilih == 'Semua'
                        ? 'Belum ada catatan.\nSilakan tambah catatan baru!'
                        : 'Tidak ada catatan di kategori "$_kategoriTerpilih".',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: listTersaring.length,
            itemBuilder: (context, i) {
              final c = listTersaring[i];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    c.judul,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${c.kategori} • ${_formatTanggal(c.dibuatPada)}'),
                      Text('Oleh: ${c.emailPengirim}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _konfirmasiHapus(c),
                  ),
                  onTap: () => _bukaDetailCatatan(c),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _bukaTambahCatatan,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TambahCatatanPage extends StatefulWidget {
  final Catatan? catatanDiubah; // Null = Tambah Baru, Not Null = Edit Data

  const TambahCatatanPage({super.key, this.catatanDiubah});

  @override
  State<TambahCatatanPage> createState() => _TambahCatatanPageState();
}

class _TambahCatatanPageState extends State<TambahCatatanPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulCtrl;
  late TextEditingController _isiCtrl;
  late TextEditingController _emailCtrl;

  String _kategori = 'Kuliah';
  final _kategoriOpsi = const ['Kuliah', 'Tugas', 'Pribadi', 'Lainnya'];

  bool get _isEditMode => widget.catatanDiubah != null;

  @override
  void initState() {
    super.initState();
    // Jika mode edit, isi controller langsung dengan data lama
    _judulCtrl = TextEditingController(text: _isEditMode ? widget.catatanDiubah!.judul : '');
    _isiCtrl = TextEditingController(text: _isEditMode ? widget.catatanDiubah!.isi : '');
    _emailCtrl = TextEditingController(text: _isEditMode ? widget.catatanDiubah!.emailPengirim : '');
    if (_isEditMode) {
      _kategori = widget.catatanDiubah!.kategori;
    }
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (_isEditMode) {
        final updated = widget.catatanDiubah!.copyWith(
          judul: _judulCtrl.text.trim(),
          isi: _isiCtrl.text.trim(),
          kategori: _kategori,
          emailPengirim: _emailCtrl.text.trim(),
        );
        await DbHelper.instance.update(updated);
      } else {
        final catatanBaru = Catatan(
          judul: _judulCtrl.text.trim(),
          isi: _isiCtrl.text.trim(),
          kategori: _kategori,
          emailPengirim: _emailCtrl.text.trim(),
          dibuatPada: DateTime.now(),
        );
        await DbHelper.instance.insert(catatanBaru);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Catatan' : 'Tambah Catatan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Field Judul
            TextFormField(
              controller: _judulCtrl,
              decoration: const InputDecoration(
                labelText: 'Judul',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Judul wajib diisi';
                if (v.trim().length < 3) return 'Minimal 3 karakter';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Field Validasi Email Pengirim dengan Regex
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Pengirim',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                hintText: 'contoh@domain.com',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                // Pattern standard RFC 2822 untuk validasi email struktur tepat
                final regexEmail = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                if (!regexEmail.hasMatch(v.trim())) {
                  return 'Format email tidak valid (ex: nama@email.com)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Field Dropdown Kategori
            DropdownButtonFormField<String>(
              initialValue: _kategori,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: _kategoriOpsi
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (v) => setState(() => _kategori = v!),
            ),
            const SizedBox(height: 16),

            // Field Isi Catatan
            TextFormField(
              controller: _isiCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Isi Catatan',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Isi wajib diisi' : null,
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _simpan,
              icon: Icon(_isEditMode ? Icons.edit : Icons.save),
              label: Text(_isEditMode ? 'Simpan Perubahan' : 'Simpan Catatan'),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailCatatanPage extends StatefulWidget {
  final Catatan catatan;

  const DetailCatatanPage({super.key, required this.catatan});

  @override
  State<DetailCatatanPage> createState() => _DetailCatatanPageState();
}

class _DetailCatatanPageState extends State<DetailCatatanPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
        actions: [
          // KODE EDIT: Menambahkan tombol edit di pojok kanan atas halaman detail
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Catatan',
            onPressed: () async {
              // Buka halaman tambah-edit dengan menyertakan object referensi data lama
              final statusTerubah = await Navigator.pushNamed(
                context,
                '/tambah-edit',
                arguments: widget.catatan,
              );

              // Jika data berhasil disimpan kembali, render ulang halaman detail ini
              if (statusTerubah == true) {
                setState(() {});
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.catatan.judul,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(widget.catatan.kategori),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
                const SizedBox(width: 12),
                Text(
                  'Oleh: ${widget.catatan.emailPengirim}',
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              widget.catatan.isi,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 40),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali ke Daftar'),
              ),
            )
          ],
        ),
      ),
    );
  }
}