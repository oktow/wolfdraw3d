# Studi brush Grease Pencil

Tanggal: 2026-09-19. Tujuan: mengganti kesan tabung pada brush utama WolfDraw3D dengan sapuan seperti aplikasi gambar, tetap berada di ruang 3D.

## Bukti dan batas pemeriksaan

- Blender lokal ditemukan di `C:/Program Files/Blender Foundation/Blender 5.1/blender.exe`; executable melaporkan 5.1.2.
- Diperiksa melalui `--background --factory-startup` dan Python API: membuat data material/Grease Pencil sementara dalam memori, tanpa menyimpan atau mengubah file Blender pengguna. Ini pemeriksaan API, bukan uji rasa menggambar interaktif atau pembacaan implementasi renderer Blender.
- Material Grease Pencil memiliki `mode`: LINE, DOTS, BOX; `stroke_style`: SOLID, TEXTURE; `alignment_mode`: PATH, OBJECT, FIXED. Properti tekstur meliputi stroke_image, texture_scale, texture_offset, texture_angle, texture_clamp, serta use_overlap_strokes.
- Titik stroke memiliki position, radius, opacity, rotation, vertex_color, dan delta_time. Radius/opacity dapat bervariasi per titik; tidak terbatas pada ketebalan tetap untuk seluruh goresan.
- Dokumentasi resmi menjelaskan material khusus Grease Pencil mengatur stroke dan fill secara terpisah; brush dan material bersama-sama menentukan tampilannya. Ini bukan material BSDF mesh biasa.

Sumber resmi:
- https://docs.blender.org/manual/en/latest/grease_pencil/materials/index.html (halaman yang terbaca melaporkan manual 5.2; jangan menyamakannya dengan versi lokal 5.1.2).
- https://docs.blender.org/manual/id/4.4/grease_pencil/materials/properties.html (referensi mode Line/Dots/Squares dan Solid/Texture; mode terkait juga dikonfirmasi langsung pada API lokal).

## Perbedaan dengan WolfDraw3D sekarang

WolfDraw3D menyimpan posisi titik, satu radius, satu warna, dan satu normal untuk seluruh stroke. Renderer membangun tabung delapan sisi. Belum ada UV tekstur, opacity/radius per titik, jenis brush, atau orientasi permukaan per titik. Eraser menyimpan metadata tabung ketika memecah stroke; metadata brush baru juga harus ikut dipertahankan/interpolasi pada titik potong.

## Rancangan untuk Godot, bukan klaim teknik internal Blender

1. Simpan data stroke terpisah dari cara merendernya: posisi, radius, opacity, orientasi/normal per titik, identitas brush, dan koordinat tekstur sepanjang goresan. Ambil normal lokal dari segitiga guide yang terkena ray, bukan satu normal untuk seluruh guide melengkung.
2. Sediakan dua cara merender sapuan: strip bertekstur untuk garis tinta kontinu; cap gambar ber-alpha dengan jarak teratur untuk pensil/kuas bertekstur. Gunakan panjang jalur untuk UV/spacing agar tekstur tidak berubah ketika kecepatan sampling berbeda.
3. Brush awal: pena solid, pensil bertekstur, dan kuas bertekstur. Pengaturan dasar: ukuran, opacity, taper, spacing. Tekanan stylus dapat mengatur radius/opacity jika perangkat mengirim pressure; pada jari gunakan nilai tetap atau taper sintetis yang jelas dibedakan dari pressure.
4. Sapuan yang mengikuti guide membutuhkan orientasi lokal yang stabil ketika kamera diputar. Strip pipih memang akan menipis jika dilihat dari samping; billboard selalu menghadap kamera memiliki perilaku berbeda dan tidak boleh dipilih tanpa mempertimbangkan tujuan menggambar pada guide.
5. Periksa alpha overlap, depth sorting, z-fighting, dan overdraw pada Android. Cap/pita lebih sedikit geometri daripada tabung belum tentu lebih cepat bila banyak piksel transparan bertumpuk.
6. Migrasikan format proyek secara kompatibel: stroke lama tetap dapat dibuka sebagai tube. Undo/redo, pemotongan eraser, transformasi grup, simpan/buka, dan ekspor APK harus mempertahankan atribut baru. Eraser tidak boleh mereset UV pada setiap potongan karena pola akan bergeser.

## Urutan implementasi yang disarankan

- Tahap A: struktur stroke/normal lokal, brush pena berbentuk strip, lebar/opacity/taper, kompatibilitas file dan eraser.
- Tahap B: tekstur alpha dan cap berjarak, preset pensil/kuas, kontrol spacing, serta uji overlap/depth.
- Tahap C: pressure stylus dan pengukuran respons/performa pada perangkat Android sasaran.

Implementasi awal 0.2.0: strip pena dan strip tekstur prosedural pensil/kuas, normal lokal guide, opacity, taper, UV stabil, format v4, serta eraser yang mempertahankan atribut potongan. Cap terpisah, impor gambar tekstur, dan pressure tetap tahap lanjutan. Tidak mengimpor brush/shader Grease Pencil langsung ke Godot.
