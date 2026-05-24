import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class Catatan {
  String judul;
  String isi;
  String kategori;
  String emailPengirim;
  final DateTime dibuatPada;

  Catatan({
    required this.judul,
    required this.isi,
    required this.kategori,
    required this.emailPengirim,
    required this.dibuatPada,
  });
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
  final List<Catatan> _catatan = [
    Catatan(
      judul: 'Belajar Flutter Dasar',
      isi: 'Mempelajari State Management, Form Validasi, dan Multi-Page Navigasi.',
      kategori: 'Kuliah',
      emailPengirim: 'mhs@kampus.ac.id',
      dibuatPada: DateTime.now(),
    ),
  ];

  String _kategoriTerpilih = 'Semua';
  final List<String> _filterOpsi = ['Semua', 'Kuliah', 'Tugas', 'Pribadi', 'Lainnya'];

  // Membuka form dalam mode Tambah Data Baru
  Future<void> _bukaTambahCatatan() async {
    final hasil = await Navigator.pushNamed(context, '/tambah-edit');

    if (hasil is Catatan) {
      setState(() {
        _catatan.add(hasil);
      });
      _tampilkanSnackbar('Catatan "${hasil.judul}" berhasil ditambahkan');
    }
  }

  // Membuka detail dan mendengarkan jika ada perubahan data dari halaman detail
  Future<void> _bukaDetailCatatan(Catatan catatanTarget, int indeksAsli) async {
    await Navigator.pushNamed(context, '/detail', arguments: catatanTarget);
    // Refresh UI utama jika ada perubahan data di halaman detail saat user kembali
    setState(() {});
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
    final listTersaring = _kategoriTerpilih == 'Semua'
        ? _catatan
        : _catatan.where((c) => c.kategori == _kategoriTerpilih).toList();

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
      body: listTersaring.isEmpty
          ? Center(
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
      )
          : ListView.builder(
        itemCount: listTersaring.length,
        itemBuilder: (context, i) {
          final c = listTersaring[i];
          final indeksDiListUtama = _catatan.indexOf(c);

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
                onPressed: () {
                  setState(() {
                    _catatan.removeAt(indeksDiListUtama);
                  });
                  _tampilkanSnackbar('Catatan dihapus');
                },
              ),
              onTap: () => _bukaDetailCatatan(c, indeksDiListUtama),
            ),
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

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;

    if (_isEditMode) {
      // Mengubah objek referensi secara langsung
      widget.catatanDiubah!.judul = _judulCtrl.text.trim();
      widget.catatanDiubah!.isi = _isiCtrl.text.trim();
      widget.catatanDiubah!.kategori = _kategori;
      widget.catatanDiubah!.emailPengirim = _emailCtrl.text.trim();

      Navigator.pop(context, true); // Kembalikan indikator sukses edit
    } else {
      // Membuat objek catatan baru
      final catatanBaru = Catatan(
        judul: _judulCtrl.text.trim(),
        isi: _isiCtrl.text.trim(),
        kategori: _kategori,
        emailPengirim: _emailCtrl.text.trim(),
        dibuatPada: DateTime.now(),
      );
      Navigator.pop(context, catatanBaru);
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
              value: _kategori,
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