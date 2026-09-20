# Draw Shape: video dan klarifikasi interaksi

Sumber: https://www.youtube.com/watch?v=cys8KhKqMuc — “How to Draw Shape in Feather”, Feather 3D, 87 detik.

Pemeriksaan video memakai storyboard resmi sekitar satu frame per detik sepanjang video, bukan pemutaran penuh dengan audio. Caption Inggris terdaftar tetapi endpoint mengembalikan isi kosong. Storyboard lokal berada di build/drawshape-reference. Pengamatan: garis pada badan objek sekitar 18–26 detik, perubahan ukuran lingkaran sekitar 36–46 detik, oval sekitar 54–62 detik, serta kurva pegangan sekitar 64–77 detik. Sampel tidak cukup untuk memastikan waktu kontak/angkat pena atau durasi tahan.

Klarifikasi pengguna menjadi patokan implementasi: goresan mengikuti tangan saat ditarik; menahan di ujung memicu koreksi; garis dengan belokan menjadi lurus, loop agak oval menjadi lingkaran; tanpa mengangkat ujung pena, radius bisa diperbesar/diperkecil. Melepas tanpa menahan tidak boleh otomatis mengoreksi bentuk.

Penyesuaian WolfDraw3D: koreksi hanya setelah jeda gerak 0,9 detik; toleransi jitter 5 piksel viewport; deteksi garis lebih toleran terhadap belokan ringan; loop hampir bulat (rasio sumbu <1,5) menjadi lingkaran dalam mode otomatis. Radius disesuaikan dari perubahan jarak pena ke pusat, bukan pergeseran horizontal. Ambang dan algoritma merupakan pilihan aplikasi ini, bukan angka yang diklaim berasal dari video.

Pengujian mencakup early-release tetap bebas, timer melalui frame aplikasi, garis goyah, loop sedikit oval, perubahan radius dari atas/kiri/bawah dan mengecil, dua proyeksi, pembatalan dua jari, guide Draw/Bend, serta undo dan penyimpanan. Tidak membuat APK.
