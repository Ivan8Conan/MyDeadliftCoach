# MyDeadliftCoach

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

**MyDeadliftCoach** adalah aplikasi mobile berbasis *Edge Computing* yang dirancang untuk memberikan koreksi teknik gerakan *deadlift* secara *real-time*. Menggunakan teknologi *Computer Vision* (MediaPipe Pose) dan *Machine Learning* (Gradient Boosting), aplikasi ini beroperasi 100% secara lokal (*offline*) di perangkat *smartphone* Android kelas menengah tanpa memerlukan pemrosesan di sisi server (*cloud*).

Aplikasi ini dikembangkan sebagai purwarupa (*prototype*) penelitian akademis untuk mengoptimalkan inferensi *Artificial Intelligence* (AI) pada perangkat dengan sumber daya komputasi dan memori yang terbatas.

---

## Fitur Utama

*  **Real-Time Pose Estimation:** Melacak 33 titik sendi tubuh manusia menggunakan *Google ML Kit* (BlazePose) secara langsung dari aliran video kamera perangkat.
*  **Native Edge Machine Learning:** Model *Gradient Boosting* dieksekusi secara *native* menggunakan instruksi `if-else` Dart murni di dalam utas latar belakang (*Isolate/Multithreading*), menghasilkan latensi mendekati nol tanpa *UI freezing*.
*  **Adaptive Frame Throttling & FSM Gatekeeper:** Sistem secara dinamis mengatur laju *frame* kamera (6 FPS saat *idle*, 20 FPS saat *active*) untuk menghemat baterai dan mencegah *thermal throttling* (panas berlebih).
*  **O(1) Memory Complexity:** Mengekstrak metrik statistik biomekanika (*Mean*, *Standard Deviation*) secara dinamis menggunakan **Algoritma Welford** guna mencegah kebocoran memori (*Memory Leak*).
*  **Inclusive Terminal Feedback:** Memberikan umpan balik evaluasi postur (Teks Visual & *Text-to-Speech* Bahasa Indonesia) tepat setelah satu repetisi selesai, memprioritaskan keamanan tulang belakang (*cervical spine*) pengguna.
*  **Serverless Local Database:** Seluruh histori sesi latihan, repetisi, skor efektivitas, dan log kesalahan disimpan secara persisten di dalam perangkat menggunakan **SQLite**.

---

##  Arsitektur Sistem (Under the Hood)

Aplikasi ini mendeteksi 2 jenis kesalahan fatal berdasarkan prinsip biomekanika *National Strength and Conditioning Association* (NSCA):
1.  **Punggung Bungkuk** (*Rounding Back*)
2.  **Lutut Melebihi Jari Kaki** (*Knees Forward*)

**Alur Pemrosesan:**
1.  **Kamera (NV21):** Mengakuisisi *frame* dan melakukan *alignment padding bytes* untuk mencegah distorsi aspek rasio (*skewing*).
2.  **Gatekeeper (FSM):** Mengkalkulasi *Adaptive Threshold* dari postur berdiri pengguna dan mendeteksi awal/akhir repetisi.
3.  **MediaPipe:** Mengekstrak titik bahu, pinggul, lutut, dan pergelangan kaki.
4.  **Welford Algorithm:** Menghitung deviasi sudut secara *real-time*.
5.  **Dart ML Classifier:** Mengevaluasi metrik melalui ratusan *decision tree* untuk menghasilkan probabilitas kelas (*Softmax*).

---

##  Tech Stack

* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **Computer Vision:** [Google ML Kit Pose Detection](https://developers.google.com/ml-kit/vision/pose-detection)
* **Database:** `sqflite` (SQLite)
* **Audio/Accessibility:** `flutter_tts` (Text-to-Speech)
* **Permissions:** `camera`, `permission_handler`

---

##  Getting Started

### Prasyarat
* Flutter SDK (Versi 3.0.0 atau lebih baru)
* Android Studio / VS Code
* Perangkat fisik Android (Direkomendasikan ARM64, Android 10+).
