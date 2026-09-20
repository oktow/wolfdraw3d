# Tahapan WolfDraw3D

Pengerjaan dilakukan bertahap. Tahap 1–2 dan 3A selesai di Windows. Tahap 3B sudah memiliki Draw profil bebas dan Bend awal; penyempurnaan deformasi serta validasi Android masih tersisa.

## 1. Prototipe inti — selesai di Windows

- [x] Proyek Godot, scene 3D, kamera, dan UI dasar.
- [x] Goresan mesh tabung dengan warna dan ukuran brush.
- [x] Bidang XY/YZ/XZ dan perpindahan kedalaman.
- [x] Orbit, pan, zoom; kontrol mouse dan dasar multitouch.
- [x] Undo/redo per goresan.
- [x] Uji otomatis alur utama dan pemeriksaan gambar hasil render.
- [x] Eksperimen Ikuti viewport; kini digantikan alur guide eksplisit di tahap 3A.

Kriteria: buat goresan pada dua kedalaman berbeda, putar kamera, dan pastikan keduanya terpisah di ruang 3D. Godot 4.7.2 Windows berhasil menjalankan pengujian ini. Validasi rasa menggambar dengan pengguna masih perlu dilakukan.

## 2. Pengeditan dan penyimpanan — selesai di Windows

- [x] Seleksi dan hapus satu goresan penuh.
- [x] Eraser parsial dengan radius layar, pemotongan kontinu, metadata potongan, satu Undo per sapuan, dan pembatalan saat beralih ke dua jari; diuji pada Perspektif/Ortografis di PC.
- [x] Grup goresan, visibilitas, dan transformasi dasar.
- [x] Format proyek berversi: titik, warna, radius, dan grup.
- [x] Simpan/buka, autosave, dan pemulihan kegagalan tulis.
- [x] Penghalusan goresan serta tampilan ukuran/warna aktif yang lebih jelas.

Validasi: simpan-buka mempertahankan geometri dalam toleransi floating-point; pengeditan, grup, dan transformasi dapat dibatalkan. Uji file rusak, kegagalan menulis, cadangan, dan pemulihan autosave lulus di Godot 4.7.2. Tampilan diperiksa melalui hasil render. Pengujian Android fisik belum dilakukan.

## 3A. Fondasi 3D Guide — selesai di Windows

- [x] Pisahkan membuat permukaan dan menggambar tinta.
- [x] Guide datar dari area yang ditarik atau ukuran otomatis, menghadap kamera saat dibuat.
- [x] Permukaan transparan dengan grid dan sisi penanda oranye; raycast pada segitiga mesh.
- [x] Menggambar pada kedua sisi dan di dalam batas permukaan aktif.
- [x] Guide/tinta tetap saat kamera mengorbit; navigasi membatalkan preview yang belum selesai.
- [x] Close, save sebagai resource, reactivate, opacity, visibilitas, dan hapus resource.
- [x] Undo/redo guide serta penyimpanan format v2; file v1 tetap dapat dibuka.
- [x] Uji regresi pengeditan/penyimpanan, lifecycle guide, migrasi, dan hasil render.

Kriteria: buat dua guide dari sudut berbeda, gambar di masing-masing, tutup/simpan/aktifkan kembali, lalu simpan-buka tanpa mengubah posisi tinta atau permukaan. Lulus pada Godot 4.7.2 Windows. Tahap ini belum meniru operasi Draw/Bend bebas Feather.

## 3B. Draw dan Bend

- [x] Profil bebas dari gerakan mouse/jari dengan pratinjau selama drag; pelepasan menerapkan hasil.
- [x] Permukaan mesh dari profil dan bentangan menjauhi kamera; FOV mengatur proyeksi profil, kedalaman dan panjang bentangan tersedia.
- [x] Bend awal dari garis kedua: sweep translasi dengan tepi oranye tetap; jalur bisa diganti berulang kali.
- [ ] Bend lanjutan dengan rotasi penampang/deformasi bertumpuk.
- [ ] Normal goresan dan penghalusan yang mengikuti permukaan melengkung.
- [ ] Transformasi guide serta isolasi seleksi/penghapusan sesuai guide.
- [x] Uji bentuk melengkung/bersudut, ray dua sisi, tinta pada mesh, undo/redo, format v3, migrasi v1/v2, dan pembatalan multitouch.

Penghalusan dunia dinonaktifkan untuk tinta pada guide custom agar sampelnya tetap di permukaan. Geometri tabung diperbaiki untuk arah goresan 3D. Penghalusan yang mengikuti permukaan dan optimasi ray pada mesh besar masih perlu dikerjakan.

Kriteria: goresan menempel pada guide melengkung; orbit tidak mengubah geometri. Algoritma implementasi merupakan rancangan WolfDraw3D yang perlu diuji, bukan klaim menyalin algoritma internal Feather.

## 3C. Loft dan Primitives

- [ ] Seleksi kurva terurut untuk Loft dan pengaturan tension.
- [ ] Cube, Pyramid, Sphere, Tube dengan segmen dan pratinjau.
- [ ] Done/Cancel konsisten, resource lifecycle dan undo/redo.

Kriteria: guide hasil Loft/Primitives dapat digambar, disimpan, dan diaktifkan kembali seperti guide lain.

## 4. Android dan stylus

- [x] Fondasi gestur: satu jari orbit atau gambar melalui toggle, dua jari pan dan pinch dengan pusat zoom mengikuti sentuhan; tersedia saat menu disembunyikan.
- [x] Uji event sentuh sintetis di Godot 4.7.2 Windows: transisi jumlah jari, pembatalan tinta, pan, zoom in/out, dan orbit.
- [x] Konfigurasi Android SDK/JDK dan export template Godot 4.7.2; APK debug ARM 32/64-bit dengan signature terverifikasi.
- [ ] UI adaptif landscape untuk tablet dan layar kecil.
- [ ] Pengujian gesture pada perangkat nyata.
- [ ] Uji pressure/tilt, pemisahan stylus dan jari, serta palm rejection pada perangkat sasaran.
- [ ] Uji pause/resume dan penyimpanan aplikasi.
- [x] Build APK uji 0.1.0, landscape, penyimpanan internal aplikasi.
- [ ] Uji instalasi APK pada perangkat nyata dan pengukuran respons menggambar.

Kriteria: APK berjalan di perangkat sasaran, input tidak saling mengganggu, dan proyek tetap aman setelah aplikasi dilanjutkan kembali.

## 5. Optimasi dan ekspor

- [x] Draw Shape awal: garis, kurva, lingkaran/elips, hold-adjust, koreksi profil guide/Bend, undo dan simpan; diuji di PC.
- [x] Mirror assistance on global X/Y/Z axes.
- [ ] Sampel adaptif, pembaruan mesh bertahap, dan pengurangan draw call.
- [ ] Benchmark gambar besar serta pengaturan kualitas.
- [ ] Ekspor geometri ke format pertukaran 3D.

Kriteria performa dan format ekspor ditentukan berdasarkan hasil uji perangkat dan kebutuhan pengguna.
