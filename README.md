# Sistem Keuangan APK (Flutter Mobile App)

Aplikasi mobile pencatatan dan pelaporan keuangan donasi & operasional pos lapangan berbasis **Flutter** dengan desain antarmuka modern (Fintech / Superapp style).

Aplikasi ini terhubung langsung dengan Backend REST API (Laravel) untuk sinkronisasi data donasi, mutasi kas pos, inventaris material fisik, dan tracking hutang piutang.

---

## 📱 Fitur Utama

- **Dashboard Modern & Luxury Wallet Card**:
  - Tampilan saldo kas lapangan realtime dengan fitur hide/show saldo (*eye toggle*).
  - Ringkasan pemasukan & pengeluaran pos program aktif.
  - Shortcut aksi cepat: *Catat Masuk*, *Catat Belanja*, *Stok Material*, dan *Hutang Piutang*.
  - Pemilih Pos Program (*Pill Selector*) dengan modal bottom sheet interaktif.
- **Jurnal Kas Pos & Transaksi**:
  - Filter transaksi: *Semua*, *Pemasukan (Donasi)*, dan *Pengeluaran (Belanja)*.
  - Modal detail transaksi lengkap dengan pratinjau bukti nota/foto struk dan ID referensi QRIS.
  - Tombol cepat catat transaksi masuk dan keluar langsung dari tab Kas Pos.
- **Form Pencatatan Transaksi**:
  - Segmented switch tipe transaksi (Pemasukan vs Pengeluaran).
  - Pilihan tanggal dengan kalender lokal Indonesia.
  - Pemilihan pos program dan metode akun pembayaran (Kas Tunai, Rekening Bank, Piutang).
  - Lampiran foto struk/nota langsung dari Kamera atau Galeri ponsel.
- **Logistik Material Fisik**:
  - Manajemen katalog material lapangan (semen, pasir, besi, bata, dll.).
  - Indikator peringatan stok menipis (*low stock warning*).
  - Pencatatan mutasi pemakaian material di lapangan.
- **Tracking Hutang & Piutang**:
  - Rekapitulasi total hutang ke pihak luar & piutang dari pihak lain.
  - Riwayat pelunasan dan pencatatan transaksi hutang/piutang baru.
- **Profil & Konfigurasi Server**:
  - Informasi petugas dan hak akses.
  - Pengaturan fleksibel URL server backend (mendukung localhost, IP jaringan lokal, maupun domain VPS/Cloud).

---

## 🛠️ Tech Stack & Dependencies

- **Framework**: Flutter 3.50+ / Dart 3.14+
- **Typography**: Google Fonts (*Plus Jakarta Sans*)
- **HTTP Client**: `http` & `http_parser`
- **Date & Number Format**: `intl` (locale `id_ID`)
- **Media**: `image_picker`
- **Storage**: `shared_preferences`

---

## 🚀 Cara Menjalankan

### 1. Prasyarat
- Flutter SDK telah terinstal di perangkat Anda (`flutter --version`).
- Backend API aktif (default di `http://localhost:8000`).

### 2. Jalankan Aplikasi
```bash
# Clone repository
git clone https://github.com/amishbahulkhair1-afk/sistem-keuangan-apk.git
cd sistem-keuangan-apk

# Unduh dependensi
flutter pub get

# Jalankan di Android Emulator / Device fisik
flutter run

# Atau jalankan di Chrome / Web Server
flutter run -d chrome
# atau
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
```

### 3. Build APK Android
```bash
# Build APK rilis
flutter build apk --release

# Lokasi output APK:
# build/app/outputs/flutter-apk/app-release.apk
```
