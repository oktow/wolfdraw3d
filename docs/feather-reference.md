# Referensi interaksi Feather

## Sumber dan batas pengamatan

- Dokumentasi: https://support.feather.art/docs/3dguide beserta Interface, Draw, Loft, Primitives, Draw and Erase, dan Resource Tab.
- Video: https://www.youtube.com/watch?v=hGHF0NsXTYY — “3D DRAW with Feather 3D app - Step by step easy tutorial”, Sketch Design Craft, durasi 19:29.
- Video diperiksa melalui storyboard resmi YouTube: sampel visual sekitar setiap 10 detik sepanjang video. Transkrip Inggris/Indonesia terdaftar tetapi respons pengambilannya kosong; pemutaran interaktif tidak tersedia. Belum menyimak audio atau memeriksa setiap gerakan antarframe. Jangan menyebut pengamatan ini sebagai menonton video lengkap.

## Pengamatan visual video

Tutorial membangun sketsa rumah kecil: kerangka, atap, teras/pagar, tangga, detail dinding, pohon, serta bidang tanah. Pengguna berulang kali berpindah antara tampilan frontal/samping/atas dan perspektif untuk menggambar serta memeriksa hasil. Bagian yang dipilih tampak hijau dan kontrol transformasi muncul. Menjelang akhir tampak kontrol presentasi/rekaman dan perubahan tampilan warna.

Sampel visual memperlihatkan pergantian antara menggambar, navigasi, dan pengeditan dalam satu pekerjaan. Sampel tidak cukup untuk memastikan tombol atau gestur yang digunakan pada setiap transisi, maupun algoritma pembentukan guide.

## Perilaku yang dinyatakan dokumentasi

- Interface: guide adalah permukaan transparan datar atau melengkung, dapat digambar di kedua sisinya. Ada kontrol opacity, close, save, seleksi, dan transformasi.
- Draw: pengguna menggambar untuk menghasilkan guide berdasarkan sudut pandang dan FOV. Bend mengubah guide mengikuti garis baru, dimulai dari sisi oranye; dapat diulang.
- Brushes / Draw and Erase: jika guide tersedia, Draw menghasilkan kurva pada permukaan guide. Membuat guide dan menggambar kurva merupakan dua tindakan berbeda.
- Loft: dua atau lebih kurva terurut menghasilkan pratinjau guide; tension mengatur kelengkungan sebelum Done.
- Primitives: Cube, Pyramid, Sphere, Tube, dengan pengaturan segmen dan transformasi sebelum Done.
- Resource Tab: guide tersimpan menjadi Surface. Resource dapat aktif untuk menggambar, terlihat tetapi tidak aktif, atau tersembunyi. Resource aktif mencegah pembuatan guide baru melalui Draw/Loft.

Sumber rinci:
- https://support.feather.art/docs/3dguide/interface
- https://support.feather.art/docs/3dguide/draw
- https://support.feather.art/docs/3dguide/loft
- https://support.feather.art/docs/3dguide/primitives
- https://support.feather.art/docs/brushes/drawanderase
- https://support.feather.art/docs/stagepanel/resourcetab

## Implikasi untuk WolfDraw3D — rancangan, bukan klaim implementasi internal Feather

Mode Ikuti viewport lama hanya memutar bidang datar bersama kamera; sudah diganti guide yang menetap di dunia. Implementasi Draw berikutnya memakai profil bebas yang diproyeksikan ke bidang acuan kamera lalu diekstrusi menjauhi kamera. Bend awal memakai sweep translasi tepi oranye sepanjang garis kedua, mengganti jalur lama. Ini rancangan aplikasi ini, bukan detail algoritma Feather yang terverifikasi.

Prioritas sebelum melanjutkan Android:
1. Pisahkan state membuat guide, menggambar pada guide aktif, dan tidak ada guide aktif.
2. Representasikan guide sebagai permukaan 3D tersendiri; kamera dapat mengorbit tanpa mengubah permukaan yang sudah dibuat.
3. Proyeksikan goresan ke permukaan aktif, termasuk pada guide melengkung, bukan selalu ke satu Plane kamera.
4. Tambahkan close/save/reactivate guide, opacity, serta penyimpanan dan undo/redo untuk guide.
5. Rancang Draw/Bend, kemudian Loft dan Primitives secara bertahap dengan pengujian visual.

Algoritma matematis Draw/Bend, posisi kedalaman awal, dan detail gestur perlu diverifikasi lebih lanjut. Jangan menganggap detail yang tidak disebutkan dokumentasi sebagai fakta.
