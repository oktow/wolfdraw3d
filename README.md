# WolfDraw3D

Prototipe aplikasi menggambar 3D untuk target Android, dibuat dengan Godot 4 dan GDScript. Tahap 1–2, fondasi guide, serta Draw profil bebas dan Bend awal tersedia dan diuji pada Godot 4.7.2 di Windows. APK debug Android 0.1.0 sudah dibuat; pengujian instalasi dan gestur pada perangkat fisik belum dilakukan.

## APK Android uji

**Pembaruan 0.2.0 (code 3):** `build/WolfDraw3D-0.2.0-debug.apk` menambahkan brush Pena, Pensil tekstur, dan Kuas tekstur, opacity dan taper, format proyek v4, serta pemotongan eraser yang mempertahankan pola tekstur. Tetap memakai paket dan keystore yang sama untuk pembaruan tanpa uninstall. Brush sudah diuji di Godot 4.7.2 PC; rasa/performa brush baru pada Android perlu diuji pengguna.

**Pembaruan 0.2.1 (code 4):** `build/WolfDraw3D-0.2.1-debug.apk` menambahkan icon toolbar atas untuk Radius, Opacity, Draw Shape, dan Duplicate. Kontrol tetap icon-only, berukuran seragam, dan menu lengkap tetap tersedia.

**Pembaruan 0.2.2 (code 5):** `build/WolfDraw3D-0.2.2-debug.apk` menambahkan Loft untuk menghubungkan minimal dua stroke terpilih menjadi Guide surface baru, kontrol Loft tension, icon Loft di toolbar, serta optimasi resampling dan batas vertex.

**Pembaruan 0.2.3 (code 6):** `build/WolfDraw3D-0.2.3-debug.apk` menambahkan primitif Cube/Tube/Line (Cube drag-ukuran, Tube sentuh-pusat + tarik radius), rail vertikal kiri kontekstual (Simpan/Tutup/Hadap/Hapus/Transformasi guide), transformasi guide via gizmo viewport, 3D cursor crosshair + angka depth dan koordinat target, 4 gestur Feather, serta orbit tanpa toggle di Draw/Pilih/Eraser. Versi aplikasi tampil di header (`GUIDE / DRAW • v0.2.3`) sebagai tanda update.

**Pembaruan 0.2.4 (code 7):** `build/WolfDraw3D-0.2.4-debug.apk` menambahkan brush Spidol datar (nib kaligrafi) dan Pena pipih solid (format proyek v7), seksi rail per tool (Draw/Pilih/Erase + tombol pilih grup/semua/kosongkan + mode gizmo Geser/Putar/Skala tanpa tahan), popup 9 tipe guide satu ikon, guide Poligonal klik-titik dan Kurva bebas, optimasi ray grid spasial 36×, dan perbaikan geometri/visibilitas rail.

**Pembaruan 0.2.5 (code 8):** `build/WolfDraw3D-0.2.5-debug.apk` — daftar perubahan:
- Rail kiri: tombol Selesai poligonal (sebelumnya hanya di panel), orbit-di-kosong untuk Lasso/Rectangle Fill.
- Joystick 2D ala Feather: ikon toggle di toolbar atas + rail kanan (stick geser, cincin putar, titik skala; mouse + sentuh; satu Undo per drag).
- Duplikat tetap di tempat asal dan langsung terseleksi (offset lama dihapus).
- Ikon popup tipe guide 24px seragam; bersih-bersih 13 warning GDScript.
- Optimasi: autosave revisi-counter (tanpa encode tiap 8 detik).

**Pembaruan 0.2.6 (code 9):** `build/WolfDraw3D-0.2.6-debug.apk` — daftar perubahan:
- Kursor 3D independen: tool penempatan (ketuk/seret), guide lahir di tengah kursor, transform geser via gizmo/pad, anti-bingung (gizmo redup, label target, rotate/scale nonaktif).
- Joystick 2D: toggle toolbar atas + rail kanan (stick, cincin, titik skala).
- Rail Pilih: pilih grup aktif, pilih semua visible, kosongkan; mode gizmo Geser/Putar/Skala ketuk langsung.
- Duplikat di tempat + langsung terseleksi; warnai seleksi via color pick; radius brush 0,005–0,5; orbit fill di luar guide.
- Ikon sumbu global di toolbar atas; popup guide satu ikon; ikon 24px seragam.

**Pembaruan 0.2.7 (code 10):** `build/WolfDraw3D-0.2.7-debug.apk` — daftar perubahan:
- Kursor menjadi titik tengah semua guide (profil/poligonal/kurva terpusat, Cube/Tube terpusat).
- Bidang ketuk-2-titik; hold profil menjadi auto (garis/kurva/lingkaran).
- Poligonal minimal 3 titik + commit otomatis 2 detik idle (tombol Selesai dihapus).
- Bersih-bersih 13 warning GDScript; rubber persegi drag mode ketuk.

**Pembaruan 0.1.1 (code 2):** `build/WolfDraw3D-0.1.1-debug.apk` memperbaiki pilihan dropdown yang tidak merespons sentuhan. Emulasi mouse untuk GUI diaktifkan, sementara event mouse emulasi disaring dari alat kanvas. Popup membersihkan state sentuhan sebelum dibuka. Paket dan debug keystore tetap sama agar dapat dipasang sebagai pembaruan 0.1.0 tanpa uninstall. Pengguna telah menjalankan 0.1.0 di Android; 0.1.1 masih perlu diuji ulang pada perangkat tersebut.

Uji popup dijalankan dengan jendela Godot (bukan `--headless`): `--path . -- --smoke-test --ui-touch-test`. Input sentuh dikirim melalui `Input.parse_input_event`, lalu memilih Ortografis, Perspektif, dan snap dari popup sebenarnya, serta memverifikasi orbit tidak diproses dua kali. Dasar pengaturan: [Godot TouchScreenButton](https://docs.godotengine.org/en/4.7/classes/class_touchscreenbutton.html) dan [identitas event emulasi](https://docs.godotengine.org/en/4.7/classes/class_inputevent.html).

File: `build/WolfDraw3D-0.1.0-debug.apk` (57.756.438 byte, sekitar 58 MB). Android minimum API 24, ARM 32-bit/64-bit, OpenGL ES 3.0, orientasi landscape. Paket `art.wolfdraw.wolfdraw3d`, versi 0.1.0/code 1. APK ditandatangani dengan debug keystore lokal; verifikasi tanda tangan v2/v3 lulus. Ini build uji, belum rilis Play Store.

Salin APK ke perangkat, buka file, lalu izinkan pemasangan dari aplikasi pengelola file tersebut bila diminta. Proyek Android disimpan di folder internal aplikasi melalui dialog Simpan/Buka. Belum ada ekspor berbagi file ke folder Downloads; uninstall atau hapus data aplikasi akan menghapus proyek internal dan autosave.

Build ulang dengan preset yang sudah tersedia, Java/SDK pada Editor Settings, dan template ekspor Godot 4.7.2:

```powershell
& 'D:\Godot_v4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --export-debug Android build/WolfDraw3D-0.2.7-debug.apk
```

Referensi setup: [dokumentasi ekspor Android Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html). Uji perangkat berikutnya: buka aplikasi, orbit/pan/pinch, Draw/Bend, eraser, simpan/buka, sembunyikan menu, dan pause/resume. Tampilan masih berorientasi tablet landscape; kenyamanan layar ponsel belum tervalidasi.

## Menjalankan

1. Buka Godot, pilih **Import**, lalu pilih `project.godot` di folder ini.
2. Tekan **F6** untuk scene aktif atau **F5** untuk menjalankan proyek.

Atau jalankan dari PowerShell di folder proyek:

```powershell
& 'D:\Godot_v4.7.2\Godot_v4.7.2-stable_win64.exe' --path .
```

Lokasi executable yang ditemukan adalah `D:\Godot_v4.7.2`, bukan `D:\Godot\_v4.7.2`.

## Mencoba gambar 3D

1. Ketuk ikon **Guide** di toolbar atas untuk langsung membuat (default profil bebas; ketuk lagi untuk batal) — ikon hanya toggle, tanpa popup dan tanpa tahan. Pilihan tipe ada di tombol **+** rail kiri (popup 5 tipe: profil, poligonal, Bend, Cube, Tube; ketuk-sekali); tipe yang dipilih dari rail menjadi default baru untuk ikon atas. Tarik persegi panjang pada kanvas untuk Cube, sentuh-tarik untuk Tube, satu garis untuk profil bebas, atau klik titik-titik untuk poligonal (minimal 3 titik; guide muncul sendiri 2 detik setelah titik terakhir, atau ketuk dua kali). Gerakan ini membuat permukaan transparan, bukan tinta. Tipe yang tak sesuai state dinonaktifkan (Bend butuh guide aktif, sisanya butuh slot kosong). Tombol **G** tetap membuat bidang tarik klasik.
2. Setelah guide terbentuk, tarik mouse kiri pada permukaannya untuk menggambar. Tidak ada tinta yang dibuat di luar batas guide atau ketika tidak ada guide aktif.
3. Tarik mouse kanan untuk memutar kamera. Guide dan tinta yang sudah dibuat tetap di ruang 3D. Anda dapat menggambar pada kedua sisi guide yang sama.
4. Tekan **Simpan guide** untuk menjadikannya resource dan menonaktifkannya. Guide masih terlihat, tetapi tidak menerima tinta. Putar kamera dan buat guide berikutnya untuk menggambar bagian lain pada arah berbeda.
5. Pilih guide di daftar **Guide tersimpan**, lalu tekan **Aktifkan guide** untuk melanjutkan gambar di permukaannya. Tutup guide aktif terlebih dahulu sebelum beralih ke guide lain.

**Simpan guide tidak menulis file ke disk.** Gunakan **Simpan** di panel Proyek atau Ctrl+S untuk menyimpan seluruh proyek beserta guide.

Guide dapat berupa permukaan profil bebas, poligonal klik-titik (minimal 3 titik), Loft, atau primitif Cube/Tube/Line (bidang tarik, ukuran otomatis, ketuk 2 titik, dan kurva tersedia lewat tombol G/fungsi internal, tidak lagi di menu). Permukaan yang sudah dibuat tetap di ruang dunia ketika kamera bergerak. Pyramid dan Sphere belum tersedia.

## Draw profil bebas dan Bend

1. Tutup atau simpan guide aktif, lalu tekan **Draw: profil bebas** pada panel 3D Guide (gulir panel kiri). Mode **Jari: gambar** otomatis aktif.
2. Atur **Bentangan profil** untuk panjang permukaan dan **Kedalaman guide baru** untuk posisi tepi awal.
3. Gambar satu garis bebas dengan mouse kiri atau satu jari. Garis dapat menggabungkan lengkung, sudut, dan bagian lurus; tidak terbatas pada preset bentuk tertentu. Tahan diam ~1 detik tanpa melepas untuk koreksi otomatis — garis lurus tetap lurus, lengkungan jelas dipertahankan sebagai kurva — lalu geser untuk mengatur atau lepas untuk membuat. Permukaan diperbarui selama tarikan dan dibuat ketika dilepas.
4. Profil digambar tepat di titik kursor lalu dibentangkan simetris ke dua sisi (kursor = tengah bentangan). Perspektif/FOV menentukan ukuran profil di dunia. Sisi oranye menandai tepi awal. Dari sudut pembuatan permukaannya bisa tampak tipis; ubah ke **Jari: putar**, orbit, atau gunakan snap X/Y/Z untuk melihat dan menggambar pada bentangannya.
5. Kembali ke **Jari: gambar**, lalu gambar tinta pada guide aktif seperti biasa. Ray memilih permukaan terdekat kamera pada kedua sisinya.
6. Untuk mengubah arah bentangan, orbit ke sudut yang sesuai, tekan **Bend: gambar arah baru**, dan tarik satu garis. Garis baru dipindahkan sehingga awalnya berada pada tepi oranye, lalu tepi itu dibentangkan mengikuti garis. Lepaskan untuk menerapkan; gunakan Undo jika perlu. Bend dapat diulang untuk mengganti jalur bentangan.

Bend versi awal memakai sweep translasi: orientasi profil awal dipertahankan, jalur bentangan sebelumnya diganti. Ini belum berupa deformasi bertumpuk atau rotasi penampang sepanjang jalur. Tinta lama tetap di tempat ketika guide berubah. Draw/Bend adalah algoritma WolfDraw3D, bukan salinan algoritma internal Feather. Garis Bend yang sejajar dengan seluruh profil bisa tidak menghasilkan luas permukaan dan akan ditolak.

Dua jari atau navigasi membatalkan pratinjau yang belum selesai. **Batal membuat guide** keluar dari operasi Draw/Bend. Undo/redo, opacity, simpan resource, dan simpan proyek juga mendukung guide custom. Profil disampling hingga 256 titik dan jalur Bend hingga 64 titik; jika melebihi batas, titik dengan pengaruh bentuk terkecil disederhanakan sambil mempertahankan kedua ujung.

## Mengelola guide

- **Tutup / Esc:** guide sementara dihapus; guide tersimpan disembunyikan dan dinonaktifkan. Tinta tetap ada. Tindakan ini bisa di-undo.
- **Simpan guide:** simpan sebagai resource dalam dokumen, tetap tampil, dan lepaskan target menggambar agar guide lain dapat dibuat.
- **Tampil / sembunyi:** atur visibilitas guide tersimpan yang dipilih. Menyembunyikan guide aktif juga menonaktifkannya.
- **Transformasi guide:** tombol **Transformasi guide** di rail kiri (muncul saat guide aktif) beralih ke tool Pilih dengan gizmo viewport pada guide aktif — seret handle merah/hijau/biru untuk geser, cincin untuk putar, lingkaran tengah untuk skala, sama seperti gizmo tinta. Putar/skala berporos pada kursor 3D.
- **Objek 3D bernama + vertex:** guide baru lahir sebagai objek bernama (ubah via kolom **Ubah nama** di panel; ikut Undo dan tersimpan). Toggle **Vertex objek** di rail + tool Pilih: ketuk vertex untuk seleksi (kuning), seret gizmo/pad untuk geser/putar/skala subset-nya — tetap dalam topologi grid sehingga format file tidak berubah. Mode edge/face dan extrude menyusul tahap berikutnya. Tombol **Putar 90°** membuka popup sumbu X/Y/Z dunia dan memutar guide aktif tepat 90 derajat (mis. bidang sejajar layar menjadi tegak masuk ke dalam). Berlaku untuk guide baru maupun hasil load dari daftar tersimpan. Tinta yang sudah ada **tetap di tempat** (tidak ikut pindah). Semua langkah masuk Undo/redo; skala yang mengecilkan guide di bawah batas validasi ditolak.
- **Rail kontekstual (menu disembunyikan):** rail kiri hanya tampil saat panel disembunyikan. Satu tombol **+** selalu siap membuka popup 5 tipe guide — profil, poligonal, Bend, Cube, Tube — (dengan ikon; tipe yang tak sesuai state dinonaktifkan — Bend butuh guide aktif, sisanya butuh slot kosong); ikon **Guide** atas hanya toggle default/terakhir tanpa popup. Guide aktif selalu memiliki rail (Simpan/Tutup/Hadap/Hapus/Transformasi guide) di tool apa pun; saat tool Draw + guide aktif, seksi Draw menumpuk di bawahnya (tipe brush, warna, Radius, Opacity brush, toggle Ujung meruncing, Draw Shape) dan rail meninggi otomatis. Tanpa guide aktif: tool Draw → tipe brush, **Properti** (satu ikon membuka popup warna + Radius + Opacity), toggle Ujung meruncing, Draw Shape; tool Pilih → mode Tap/Rectangle/Lasso (bercentang), Pilih grup aktif, Pilih semua (yang terlihat), Kosongkan pilihan, mode gizmo Geser/Putar/Skala (ketuk langsung, tanpa tahan), Duplikat, Mirror seleksi (di tempat terhadap bidang kursor), Hapus pilihan; tool Erase → Radius eraser (sinkron dua arah dengan panel). Menu dibuka ketuk-sekali dengan centang pada pilihan aktif; ikon tombol selalu cerminan state dan pilihan persisten dalam sesi. Kontrol yang sama tidak diduplikasi di toolbar atas.
- **Hapus guide tersimpan:** hapus resource tanpa menghapus tinta; dapat di-undo.
- **Opacity guide:** tersedia untuk guide aktif. Opacity nol membuat guide tidak terlihat tetapi tetap bisa digambar.
- **Kursor 3D:** tool **Kursor 3D** (ikon atas + panel) menaruh kursor independen — ketuk di goresan/guide/lantai untuk menaruhnya, seret untuk menggeser, atau orbit/pan dulu lalu ketuk. **Guide baru selalu lahir di kursor** (bukan di pusat orbit); crosshair selalu terlihat sebagai acuan. Kursor hanya sesi (tidak tersimpan di file).
- **Transformasi kursor:** dengan tool Pilih dan tanpa seleksi/guide aktif, gizmo viewport menempel di kursor (geser per sumbu saja; putar/skala tidak berlaku untuk titik) dan pad joystick 2D ikut menggesernya. Tanpa entri Undo, tanpa mengubah dokumen. Agar tak tertukar dengan seleksi: handle kursor tampil redup berinti kuning (vs putih untuk tinta/guide), label panel menulis **Gizmo: kursor 3D** / **Gizmo: guide aktif**, dan tombol Putar/Skala nonaktif saat targetnya kursor.
- **Kedalaman guide baru:** offset terhadap kursor sepanjang arah menuju kamera saat membuat guide (label menampilkan angka live, mis. +1.25). Tidak memindahkan guide lama.
- **Hadap guide:** sejajarkan kamera ke sisi guide aktif yang sedang dilihat.
- Gulir panel kiri untuk kontrol guide/resource dan panel kanan untuk kontrol grup. Joystick **Transformasi Grup** berada compact di kanan bawah kanvas dan tetap tersedia saat menu disembunyikan.

| Kontrol | Fungsi |
| --- | --- |
| Mouse kiri, mode Gambar | Menggambar pada guide aktif; menarik area saat membuat guide |
| G / Esc | Mulai membuat bidang / tutup guide atau batalkan pembuatan |
| U | Sembunyikan / tampilkan seluruh panel menu |
| Mouse kanan | Orbit |
| Mouse tengah | Pan |
| Scroll | Zoom |
| B / N | Mode Gambar / Navigasi |
| V / E | Mode Pilih / Eraser sebagian goresan |
| Delete / Backspace | Hapus goresan yang dipilih |
| Ctrl+Z / Ctrl+Shift+Z | Undo / redo |
| Ctrl+S / Ctrl+Shift+S | Simpan / Simpan sebagai |
| Ctrl+O | Buka proyek |
| Satu jari, Jari: putar (default) | Rotate / orbit kamera |
| Satu jari, Jari: gambar | Menggambar / membuat guide; ketuk untuk Pilih atau Hapus sesuai alat aktif |
| Satu jari, mode Navigasi | Orbit, termasuk ketika Jari: gambar aktif |
| Dua jari | Pan dan pinch zoom |

Untuk sentuhan, mulai dengan **Jari: putar**: geser satu jari untuk rotate, geser dua jari bersama untuk pan, renggangkan dua jari untuk zoom in, dan cubit untuk zoom out. Tekan **Jari: gambar** sebelum menggambar atau menarik area guide. Dalam mode Draw + Jari gambar, tarikan yang dimulai **di luar guide** langsung memutar kamera (tanpa toggle), sedangkan tarikan di atas guide tetap menggambar — berlaku untuk semua jenis brush termasuk Lasso/Rectangle Fill (di dalam guide: fill, di luar: putar). Prinsip yang sama di tool lain: mode Pilih (tap) — ketuk untuk seleksi, seret untuk putar; Eraser — sentuh dekat tinta untuk menghapus, sentuh jauh dari tinta untuk putar. Rectangle/Lasso tetap memakai seretan untuk area seleksi. Dua jari tetap menavigasi dalam kedua pengaturan. Tombol pengaturan jari juga tersedia di sebelah **Menu U** ketika panel disembunyikan. Ala Feather: **ketuk 2x satu jari** untuk snap ke tampak standar (atau double-click mouse dalam mode Navigasi), **tahan satu jari** pada goresan/guide/lantai untuk memindah pusat orbit dan tahan di ruang kosong untuk reset tampilan, **ketuk 2x tiga jari** untuk ganti Perspektif/Ortografis, dan **geser vertikal tiga jari** untuk atur FOV (15–100).

Gestur dua jari membatalkan goresan atau pratinjau guide yang sedang dibuat agar tidak meninggalkan hasil tidak sengaja. Setelah navigasi dua jari, angkat semua jari sebelum menggambar atau rotate satu jari lagi. Navigasi dan kehilangan fokus membatalkan pratinjau guide yang belum diselesaikan. Saat aplikasi masuk latar belakang, state sentuhan direset sebelum autosave. Input sentuh telah diperiksa melalui event sintetis; pengujian perangkat Android belum dilakukan.

## Pengeditan dan grup

- **Draw Shape (pembaruan proyek PC):** dropdown pada panel brush menyediakan Mati dan Otomatis (garis/lingkaran/elips/kurva dikenali otomatis). Koreksi hanya dipicu dengan menahan ujung; melepas tanpa menahan mempertahankan goresan bebas (penghalusan brush biasa tetap mengikuti checkbox). Nonaktif secara default agar gambar bebas tidak berubah tanpa pilihan pengguna.
- Setelah menarik goresan, tahan diam sekitar **1 detik** (ambang 0,9 detik) dengan mouse kiri atau satu jari tetap menekan. Garis dengan belokan ringan dikoreksi menjadi lurus; lingkaran yang goyah/agak oval — termasuk yang tidak tertutup rapat — dikoreksi menjadi bulatan sempurna pada mode Otomatis/Lingkaran. Setelah koreksi, geser tanpa melepas untuk mengubah ujung garis atau kelengkungan kurva. Pada lingkaran, menjauh dari pusat memperbesar radius, mendekat memperkecil, dan bergerak mengelilingi pusat pada jarak tetap tidak mengubah radius. Elips yang jelas lonjong dipertahankan sebagai elips pada mode Otomatis; gunakan pilihan Lingkaran/Garis bila deteksi maksud berbeda. Pilihan Elips mempertahankan oval meskipun hampir bulat. Lepaskan untuk menyimpan sebagai satu langkah Undo.
- Draw Shape juga bekerja pada **Draw profil bebas** dan **Bend**, bukan pada mode tarik persegi panjang. Koreksi dihitung dari tampilan layar lalu diproyeksikan ke guide; lingkaran/garis layar pada guide melengkung bukan jaminan lingkaran/garis geometris datar di dunia. Jika hasil keluar batas guide atau menjadi degenerat, pratinjau sebelumnya dipertahankan. Dua jari membatalkan tinta/pratinjau sementara sebelum navigasi. Bentuk adalah sampel poligon (64 titik), belum kurva analitik yang bisa diedit kembali setelah dilepas.
- Hasil bentuk memakai format proyek v4 yang sama, termasuk atribut brush dan eraser. Pilihan Draw Shape adalah state sesi. Perilaku mengacu pada [dokumentasi Feather Draw Shape](https://support.feather.art/docs/assistance/drawshape); algoritma fitting dan elips adalah implementasi WolfDraw3D, bukan klaim menyalin algoritma Feather. Pembaruan ini **belum dibuat menjadi APK**; ekspor Android hanya dilakukan atas perintah pengguna.
- **Brush:** dropdown di panel kiri memilih **Pena**, **Pensil tekstur**, **Kuas tekstur**, **Spidol datar**, **Pena pipih**, atau **Tube 3D (lama)**. Pena menjadi default untuk goresan baru. Spidol datar bermata pipih kaligrafi: atur **Sudut nib** (0–180°, default 45°), gerak menyilang mata menghasilkan garis tebal, gerak searah mata menghasilkan garis tipis; bentuk terpanggang dalam geometri sehingga orbit tidak mengubahnya. Pena pipih selalu solid: lebar konstan dan opak penuh apa pun posisi slider opacity/taper. Tiga brush pertama memakai strip pipih dua sisi dengan normal lokal guide, tanpa pencahayaan volume tabung. Radius, opacity, dan **Ujung meruncing** memengaruhi goresan berikutnya. Opacity/taper dinonaktifkan saat memilih Tube.
- Pensil dan kuas menggunakan tekstur prosedural pada shader (butiran/serat), belum memakai berkas gambar brush eksternal atau cap Dots/Squares. Ini gaya terinspirasi Grease Pencil, bukan impor brush atau shader Blender. Pressure stylus belum dipakai. Strip pipih terlihat menipis dari samping; sapuan transparan bertumpuk dan sudut guide tajam masih memerlukan penyempurnaan visual/performa Android.
- Koordinat tekstur dan normal tersimpan per titik. Eraser menginterpolasi atribut di titik potong dan mempertahankan panjang asli untuk taper, sehingga pola tidak dimulai ulang atau muncul taper baru di setiap potongan. Stroke lama tanpa atribut brush tetap dirender sebagai tabung.
- **Snap tampilan:** dropdown **Tampak** di atas viewport memuat **X+ Kanan / X- Kiri**, **Y+ Atas / Y- Bawah**, dan **Z+ Depan / Z- Belakang**. Pilihan langsung menyejajarkan kamera dengan sumbu dunia sambil mempertahankan pusat orbit dan jarak zoom. Dropdown tetap tersedia ketika menu disembunyikan; sesudah snap, navigasi sentuh tetap bisa digunakan.
- **Proyeksi:** dropdown di sebelah Tampak memilih **Perspektif** atau **Ortografis**. Ortografis menjaga ukuran tampilan objek pada kedalaman berbeda; Perspektif memberi kesan dekat-jauh. Peralihan mempertahankan skala pada pusat orbit, posisi kamera, dan geometri. Pan, scroll/pinch zoom, Draw/Bend, serta seleksi bekerja pada kedua proyeksi. Pilihan proyeksi adalah pengaturan sesi, belum disimpan dalam file proyek.
- Klik **Sembunyikan U** di bar atas atau tekan **U** untuk memperluas area kanvas. Semua panel disembunyikan; toolbar ikon di kiri atas tetap menyediakan **Gambar**, **Guide**, **Navigasi**, **Pilih**, **Hapus**, **Undo**, dan **Redo**, sementara tombol **Menu U** tetap tersedia di kiri bawah untuk mengembalikan panel. Ikon Guide memulai pembuatan bidang dengan tarik area. Menggambar dan navigasi tetap berfungsi, dengan kamera serta guide pada posisi yang sama.
- Kanvas dunia berwarna putih. Klik kotak di bawah **Pilih warna brush** untuk membuka color picker, termasuk input HEX. Pilihan cepat dan kode warna tersinkron; warna baru berlaku untuk goresan berikutnya. **Bila ada goresan terseleksi, warna pilihan langsung mengecat seleksi** sebagai satu langkah Undo (checkpoint digabung tiap 1,5 detik agar drag picker tidak membanjiri riwayat). Brush awal berwarna gelap agar terlihat pada kanvas putih.
- Klik **Pilih V**, lalu klik goresan. Goresan terpilih mendapat sorotan; ketika bertumpuk, goresan terdekat kamera diprioritaskan.
- Dengan goresan terpilih, tekan **Duplikat** pada panel grup atau **Ctrl+D** untuk membuat salinan dengan geometri dan metadata brush yang sama. Salinan tetap tepat di tempat asal dan langsung terseleksi (siap digeser memakai joystick/gizmo); salinan tetap berada pada grup asal.
- **Mirror:** tekan ikon Mirror di toolbar, lalu aktifkan satu atau beberapa sumbu X/Y/Z. Sapuan baru akan dibuat juga pada pantulan terhadap bidang global yang melalui **kursor 3D** (bukan origin) — jadi taruh kursor dulu, lalu gambar/duplikat untuk mendapat pantulan di sebelahnya. Pilihan sumbu tetap tersimpan saat Mirror dimatikan; seluruh hasil satu sapuan menjadi satu langkah Undo.
- **Seleksi multi-objek:** pada mode Pilih, ketuk goresan untuk menambahkannya ke seleksi atau ketuk lagi untuk menghapusnya; ketuk area kosong untuk mengosongkan seleksi. Tekan-tahan ikon Pilih untuk memilih mode **Tap**, **Rectangle**, atau **Lasso**. Rectangle/Lasso memakai satu jari dan hasilnya ditambahkan ke seleksi yang sudah ada, sehingga tidak memerlukan Ctrl di Android. Transformasi, Duplikat, dan Hapus berlaku pada seluruh seleksi.
- **Brush Fill:** pilih **Lasso Fill** atau **Rectangle Fill** pada daftar tipe brush, lalu gambar area di dalam guide aktif. Saat gesture selesai, area otomatis diisi warna aktif sebagai satu objek stroke yang dapat dipilih, ditransformasi, diduplikasi, disimpan, dan di-Undo.
- **Grup:** panel grup menampilkan daftar grup aktif. Klik nama grup akan menjadikannya grup aktif sekaligus memilih seluruh goresan di dalamnya, sehingga gizmo Move/Rotate/Scale siap memanipulasi grup. Tombol `+` pada setiap baris memilih grup untuk operasi multi-grup. Tombol visibility menyembunyikan/menampilkan grup, tombol `I` mengisolasi grup, dan tombol panel menyediakan hapus, duplikat, serta gabung grup. Perubahan grup tetap tercakup dalam Undo/Redo dan penyimpanan proyek.
- **Liquify:** pilih satu atau beberapa stroke, buka bagian Liquify di panel grup, lalu tekan **Mulai Liquify**. Pilih Push, Pinch, atau Comb; atur Ukuran, Range, dan Strength; kemudian drag di viewport. **Undo All** mengembalikan kondisi sebelum sesi, **Compare** menampilkan kondisi awal sementara, dan **Apply** menerapkan seluruh sesi sebagai satu langkah Undo. Mengubah tool lain saat sesi aktif membatalkan Liquify tanpa checkpoint.
- **Bahasa:** default aplikasi adalah **English (US)**. Gunakan pilihan **Language** di panel Project untuk beralih ke **Bahasa Indonesia**. Teks kontrol, label, tombol, menu, dan dialog yang dibuat oleh UI akan diperbarui tanpa me-reload proyek atau menghapus pekerjaan.
- **Hapus E** menjadi eraser parsial: klik/ketuk atau sapu untuk memotong bagian goresan dalam lingkaran eraser. Bagian di luar sapuan tetap menjadi potongan goresan terpisah dengan warna, ketebalan, dan grup asli. Atur **Radius eraser** pada panel kiri (4–100 piksel viewport); ukuran brush gambar tetap terpisah. Eraser dapat digunakan tanpa guide aktif.
- Eraser memakai area layar dan memotong semua goresan dari grup yang ditampilkan pada area tersebut, termasuk yang bertumpuk pada kedalaman berbeda. Sembunyikan grup yang ingin dilindungi. Segmen di belakang atau melintasi near plane kamera tidak dipotong. Ini belum berupa eraser volume 3D atau isolasi berdasarkan guide.
- Pada sentuhan, aktifkan **Jari: gambar** untuk memakai eraser dengan satu jari. Perubahan terlihat selama sapuan; satu sapuan menjadi satu langkah Undo saat dilepas. Jari kedua, pembatalan sentuhan, atau kehilangan fokus membatalkan sapuan sementara. Dua jari tetap pan/zoom. Untuk menghapus satu goresan penuh, gunakan **Pilih V**, lalu **Delete** atau tombol **Hapus pilihan**.
- Tombol **+** membuat grup dan menjadikannya grup aktif untuk goresan baru. Nama dapat diubah dengan Enter atau **Ubah nama**.
- Untuk memindahkan goresan: pilih goresan, pilih grup tujuan dari daftar, lalu **Pindah ke grup aktif**.
- **Tampilkan grup** menyembunyikan/menampilkan seluruh anggota. Grup tersembunyi tidak bisa digambar atau dipilih dari kanvas.
- Saat goresan dipilih dalam mode **Pilih**, gizmo transformasi muncul langsung di viewport pada pusat goresan (setara 3D joystick Feather: handle sumbu untuk geser/putar/skala global). Titik putar/skalanya adalah **kursor 3D** (seperti Mirror) — geser tidak terpengaruh pivot. Gizmo hanya merespons saat terlihat di tool Pilih — sentuhan di area handle yang tak terlihat tidak akan menggerakkan apa pun, dan pad yang disembunyikan di tengah drag menyelesaikan gesturenya dengan aman. Mode gizmo dipilih dari rail kiri (**Geser/Putar/Skala**, ketuk langsung tanpa tahan). **Joystick 2D** ala Feather tersedia lewat ikon toggle di toolbar atas: rail kanan berisi pad — seret stick tengah untuk geser pada bidang pandang, cincin luar untuk putar terhadap arah pandang, titik sudut untuk skala seragam; stick kembali ke tengah saat dilepas. Pad mendukung mouse dan sentuhan, satu langkah Undo per drag. Drag handle merah/hijau/biru memindahkan atau mengubah skala pada sumbu yang dipilih, sedangkan arc berwarna pada mode Rotate memutar sekitar sumbu tersebut. Transformasi dicatat sebagai satu langkah Undo per drag dan hanya memindahkan tinta terpilih, bukan guide. Gizmo praktis ini belum memiliki proyeksi cone/arc 3D yang berubah mengikuti kamera seperti Feather.
- Undo/redo menyimpan hingga 40 langkah perubahan dokumen, termasuk hapus, grup, dan transformasi. Riwayat direset ketika membuka proyek.
- **Haluskan goresan** melakukan satu lintasan ringan pada guide datar. Pada guide custom, penghalusan ini dilewati agar tidak menarik titik keluar dari permukaan. Tinta disampling sepanjang gerakan layar; mesh tabung tetap merupakan pendekatan diskret terhadap permukaan.

## Lingkungan (Environment)

Panel kiri bagian **ENVIRONMENT** mengatur tampilan panggung ala Feather, tersimpan di proyek dan ikut Undo:

- **Overlay:** **Sumbu global** menampilkan salib sumbu XYZ di origin (toggle di panel ENVIRONMENT dan ikon toolbar atas, sinkron dua arah); **Grid** menampilkan/menyembunyikan lantai referensi.
- **World:** **Warna background** (fog mengikuti warna ini bila Fog aktif), **Gambar latar...** mengimpor PNG/JPG (otomatis dikecilkan ≤1024px dan disematkan di file proyek, diam saat kamera bergerak), dan toggle **Fog**.
- **Cahaya:** slider **Ketinggian/ Arah cahaya**, tombol **Sejajarkan tampilan** (cahaya mengikuti kamera), **Warna** dan **Kekuatan cahaya**, serta toggle **Bayangan**.
- **Efek:** **Glow** + kekuatan (untuk tinta terang), **Grain** + kekuatan, dan **Pixelasi** + skala (render 3D diperkecil lalu dibentangkan).

Batasan jujur: tinta ribbon/pensil/kuas dan guide memakai material unshaded sehingga tidak merespons cahaya/bayangan — efek cahaya dan bayangan tanah terutama terlihat pada brush Tube 3D. Tidak ada Toon shading, eyedropper background, atau Depth of Field bawaan (tidak tersedia di renderer GL Compatibility); fokus orbit tetap menjadi acuan jarak pandang.

## Simpan, buka, dan pemulihan

- **Simpan** menulis file `.wolf3d`; **Simpan sebagai...** memilih lokasi baru. Tanda `*` di bawah berarti ada perubahan sejak penyimpanan terakhir.
- Format JSON versi 7 menambahkan sudut nib untuk brush Spidol datar. Grup, guide, sequence, environment, dan state resource tetap disimpan. Pilihan brush aktif dan kamera adalah pengaturan sesi.
- File versi 1–6 tetap dapat dibuka (environment dan nib diisi default). Stroke tanpa atribut brush tetap menjadi tabung. Penyimpanan berikutnya menggunakan versi 7, dengan file sebelumnya sebagai `.bak` jika lokasi sama. Versi aplikasi lama belum dapat membaca file v7.
- Penulisan menggunakan file `.tmp`, lalu merotasi file sebelumnya ke `.bak`. Jika penulisan atau rotasi gagal, file sebelumnya dipertahankan. Ini bukan jaminan terhadap semua kegagalan perangkat penyimpanan atau mati listrik.
- File diperiksa sebelum scene diganti. Jika file utama rusak tetapi `.bak` valid, aplikasi memulihkan cadangan dan meminta hasil disimpan sebagai file baru.
- Autosave dilakukan setiap 8 detik saat ada perubahan dan tidak sedang menarik goresan, serta saat aplikasi ditutup normal. Saat aplikasi dibuka lagi, pilih **Pulihkan** untuk melanjutkan autosave, atau **Mulai kosong** untuk membuangnya.
- Autosave berada di `user://autosave.wolf3d`. Di Windows biasanya `%APPDATA%\Godot\app_userdata\WolfDraw3D\autosave.wolf3d`. Autosave adalah satu slot pemulihan sesi, bukan arsip semua proyek. Simpan proyek sebelum memilih membuka proyek lain tanpa menyimpan.
- Jika autosave gagal saat menutup, aplikasi tetap terbuka agar proyek bisa disimpan ke lokasi lain.

## Batas saat ini

- Brush baru berupa strip dengan taper; mode tabung lama tetap tersedia. Titik tunggal tanpa tarikan belum menghasilkan goresan. Belum ada pressure, import tekstur, atau cap kuas terpisah.
- Guide baru menghadap kamera saat dibuat. Permukaan datar memiliki batas nyata; grid lantai hanya referensi visual dan bukan target tinta.
- Transformasi guide, primitif Pyramid/Sphere, dan isolasi seleksi/penghapusan oleh guide belum tersedia. Pemilihan tinta saat ini tidak memakai guide sebagai penghalang. Profil yang berpotongan dengan dirinya sendiri dapat menghasilkan permukaan bertumpuk; belum ada perbaikan topologi otomatis.
- Batas file: 32 MB, 200.000 titik tinta, 200.000 vertex guide, 10.000 goresan, 1.000 grup, dan 100 guide. Satu mesh guide maksimal 256 × 64 vertex. Ini batas validasi, bukan jaminan performa pada ukuran tersebut.
- Mesh goresan aktif dibangun ulang maksimal sekali per ~33 ms saat menggambar (hasil akhir selalu penuh saat dilepas). Riwayat menggunakan salinan dokumen; gambar besar dapat membutuhkan banyak RAM. Ray guide memakai culling AABB plus indeks grid spasial untuk mesh padat (>1500 segitiga) dan eraser melewati goresan di luar sapuan. Status dirty dan slot autosave memakai counter revisi O(1), bukan encode dokumen — encode 90k titik (~7 MB) hanya saat simpan/autosave menulis. Benchmark PC: 2000 sampel tube 10,5 dtk → 0,01 dtk; 500 ray miss pada mesh 16k vertex ~1 ms; 64 ray hit pada mesh 16k vertex 289 ms → 8 ms; encode 90k titik 232 ms. Benchmark Android fisik belum dilakukan.
- UI awal ditujukan untuk tampilan landscape 1280 × 800. Adaptasi layar kecil, stylus pressure, dan palm rejection belum termasuk. APK debug tersedia untuk pengujian.

## Pemeriksaan

```powershell
& 'D:\Godot_v4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . -- --smoke-test
```

Pengujian mengulang regresi pengeditan, grup, transformasi, undo/redo, file tidak valid, kegagalan tulis/rotasi cadangan, pemulihan `.bak`, dan autosave. Suite guide menguji pembuatan eksplisit, batas mesh, menggambar dari sisi belakang, guide/tinta tetap saat orbit, close/save/reactivate, opacity, resource visibility/deletion, simpan-buka versi 2, migrasi versi 1, serta pembatalan pratinjau saat multitouch/navigasi/fokus berubah. Pengujian memakai folder sementara khusus, bukan autosave pengguna. Perbandingan angka dari JSON menggunakan toleransi floating-point.

Untuk menangkap tampilan uji, buat folder `build`, lalu jalankan tanpa `--headless` dan tambahkan `--capture` setelah `--smoke-test`. Hasil: `build/guide-3a.png`.

Lihat [ROADMAP.md](ROADMAP.md) untuk tahapan selanjutnya.

Suite profil juga menguji Draw melalui event sentuh, sudut dan kurva dalam satu guide, tinta pada mesh, perpotongan terdekat dari kedua sisi, Bend dengan tepi awal tetap, undo/redo, simpan-buka v3, migrasi v2, pembatalan multitouch, dan penolakan data mesh tidak valid. Dengan `--capture`, hasil render tambahan tersedia di `build/profile-draw.png` dan `build/profile-bend.png`.
