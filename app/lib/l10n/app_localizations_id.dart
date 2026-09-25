// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Purnara';

  @override
  String get navToday => 'Hari Ini';

  @override
  String get navProject => 'Project';

  @override
  String get navPlan => 'Rencana';

  @override
  String get navDocuments => 'Dokumen';

  @override
  String get navAssistant => 'Asisten';

  @override
  String get actionRetry => 'Coba lagi';

  @override
  String get actionCancel => 'Batal';

  @override
  String get actionSave => 'Simpan';

  @override
  String get actionDelete => 'Hapus';

  @override
  String get actionClose => 'Tutup';

  @override
  String get actionNext => 'Lanjut';

  @override
  String get actionBack => 'Kembali';

  @override
  String get actionSkip => 'Lewati';

  @override
  String get actionAdd => 'Tambah';

  @override
  String get actionRefresh => 'Muat ulang';

  @override
  String get actionUndo => 'Batalkan';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get notificationsTitle => 'Notifikasi';

  @override
  String get loading => 'Memuat…';

  @override
  String get errorGeneric => 'Terjadi kesalahan. Coba lagi sebentar lagi.';

  @override
  String errorNetwork(String url) {
    return 'Tidak bisa terhubung ke server Purnara di $url. Pastikan backend sedang berjalan.';
  }

  @override
  String get errorNotFound => 'Data tidak ditemukan. Mungkin sudah dihapus.';

  @override
  String get errorValidation => 'Ada isian yang belum valid. Periksa lagi.';

  @override
  String get errorDeadlinePast => 'Deadline harus setelah hari ini.';

  @override
  String get errorDependencyCycle => 'Dependensi ini membuat lingkaran: task-task akan saling menunggu.';

  @override
  String get errorPlanExists => 'Project ini sudah punya rencana. Gunakan \"Sesuaikan rencana\".';

  @override
  String get errorNoPlan => 'Buat rencana dulu.';

  @override
  String get errorSuggestionDecided => 'Usulan ini sudah diputuskan sebelumnya.';

  @override
  String get errorUnsupportedFile => 'Format belum didukung. Gunakan PDF, DOCX, TXT, atau MD.';

  @override
  String get errorFileTooLarge => 'File terlalu besar (maksimal 20 MB).';

  @override
  String get errorTooManyPages => 'Dokumen terlalu panjang (maksimal 300 halaman).';

  @override
  String get errorDuplicate => 'Dokumen ini sudah ada di library.';

  @override
  String get errorUnreadable => 'File tidak bisa dibaca. Mungkin rusak atau terkunci kata sandi.';

  @override
  String get errorNoText => 'Tidak ada teks yang bisa dibaca. Kemungkinan hasil scan; dukungan dokumen scan menyusul.';

  @override
  String get errorInvalidCapacity => 'Isi 0 sampai 16 jam per hari, dengan minimal satu hari lebih dari 0.';

  @override
  String errorQuota(String date) {
    return 'Kuota AI bulan ini habis. Pulih pada $date.';
  }

  @override
  String get errorUnauthenticated => 'Sesi berakhir. Silakan masuk lagi.';

  @override
  String get errorEmptyFile => 'File kosong.';

  @override
  String get aiNotActive => 'AI belum aktif di server ini. Semua fitur tetap berjalan dengan versi dasar tanpa AI.';

  @override
  String get aiLabel => 'Usulan AI';

  @override
  String get templateLabel => 'Dari template';

  @override
  String get schedulerLabel => 'Dari penjadwal';

  @override
  String get basicLabel => 'Tanpa AI';

  @override
  String get aiErrorUnavailable => 'AI belum aktif, jadi dipakai versi dasar.';

  @override
  String get aiErrorQuota => 'Kuota AI habis, jadi dipakai versi dasar.';

  @override
  String get aiErrorFailed => 'AI sedang bermasalah, jadi dipakai versi dasar.';

  @override
  String get aiErrorInvalidPlan => 'Rencana dari AI tidak lolos pemeriksaan, jadi dipakai template.';

  @override
  String get healthOnTrack => 'Sesuai jadwal';

  @override
  String get healthAtRisk => 'Perlu perhatian';

  @override
  String get healthOffTrack => 'Tertinggal';

  @override
  String get healthNoPlan => 'Belum ada rencana';

  @override
  String get healthReasonInfeasible => 'Jam yang tersedia tidak cukup sampai deadline.';

  @override
  String healthReasonCriticalLate(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: 'Task di jalur kritis terlambat $days hari.');
    return '$_temp0';
  }

  @override
  String get healthReasonSpiLow => 'Progress jauh di bawah rencana.';

  @override
  String get healthReasonSpiModerate => 'Progress sedikit di bawah rencana.';

  @override
  String get healthAllGood => 'Progress sesuai rencana.';

  @override
  String progressPlanned(String pct) {
    return 'Rencana $pct%';
  }

  @override
  String progressActual(String pct) {
    return 'Tercapai $pct%';
  }

  @override
  String get feasibilityFeasible => 'Rencana muat sebelum deadline';

  @override
  String get feasibilityTight => 'Muat, tapi cadangan waktu terpakai';

  @override
  String feasibilityInfeasible(String hours) {
    return 'Kurang $hours jam sebelum deadline';
  }

  @override
  String projectedFinish(String date) {
    return 'Perkiraan selesai $date';
  }

  @override
  String daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days hari lagi', zero: 'Deadline hari ini');
    return '$_temp0';
  }

  @override
  String get deadlinePassed => 'Deadline sudah lewat';

  @override
  String deadlineOn(String date) {
    return 'Deadline $date';
  }

  @override
  String hoursValue(String hours) {
    return '$hours jam';
  }

  @override
  String get todayTitle => 'Fokus hari ini';

  @override
  String todayMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '+$count task lain juga dijadwalkan hari ini');
    return '$_temp0';
  }

  @override
  String get todayUpcoming => 'Minggu ini';

  @override
  String get todayEmpty => 'Tidak ada task terjadwal hari ini.';

  @override
  String get todayNoPlan => 'Project ini belum punya rencana.';

  @override
  String get todayMakePlan => 'Susun rencana';

  @override
  String get markDone => 'Tandai selesai';

  @override
  String get markedDone => 'Task ditandai selesai.';

  @override
  String get helpMeStart => 'Bantu saya mulai';

  @override
  String lateBadge(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: 'Terlambat $days hari');
    return '$_temp0';
  }

  @override
  String get criticalBadge => 'Jalur kritis';

  @override
  String pendingSuggestions(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count usulan menunggu keputusanmu');
    return '$_temp0';
  }

  @override
  String get reviewAction => 'Tinjau';

  @override
  String get needsReschedule => 'Ada perubahan yang belum masuk jadwal.';

  @override
  String get adjustPlan => 'Sesuaikan rencana';

  @override
  String capacityToday(String hours) {
    return 'Kapasitas hari ini $hours';
  }

  @override
  String nextMilestone(String title) {
    return 'Berikutnya: $title';
  }

  @override
  String get planTabList => 'Daftar';

  @override
  String get planTabBoard => 'Papan';

  @override
  String get planTabTimeline => 'Linimasa';

  @override
  String get statusTodo => 'Belum';

  @override
  String get statusInProgress => 'Dikerjakan';

  @override
  String get statusDone => 'Selesai';

  @override
  String get taskAdd => 'Tambah task';

  @override
  String get taskTitle => 'Judul task';

  @override
  String get taskEstimate => 'Estimasi (jam)';

  @override
  String get taskActual => 'Jam aktual';

  @override
  String get taskMilestone => 'Milestone';

  @override
  String get taskNoMilestone => 'Tanpa milestone';

  @override
  String get taskOptional => 'Opsional (boleh dilepas saat waktu mepet)';

  @override
  String get taskDeferred => 'Ditunda, di luar scope';

  @override
  String get taskImportance => 'Tingkat penting';

  @override
  String get importanceNormal => 'Biasa';

  @override
  String get importanceHigh => 'Penting';

  @override
  String get importanceTop => 'Sangat penting';

  @override
  String taskScheduled(String start, String end) {
    return '$start – $end';
  }

  @override
  String get taskUnscheduled => 'Belum dijadwalkan';

  @override
  String taskLatestFinish(String date) {
    return 'Paling lambat selesai $date';
  }

  @override
  String get taskDependsOn => 'Menunggu task';

  @override
  String get taskRequirements => 'Memenuhi syarat';

  @override
  String get taskDefinitionOfDone => 'Kriteria selesai';

  @override
  String get taskNotes => 'Catatan';

  @override
  String get taskSchedule => 'Jadwal';

  @override
  String get taskBreakDown => 'Pecah task ini';

  @override
  String get taskExplain => 'Jelaskan dari referensi';

  @override
  String get taskPostpone => 'Tunda';

  @override
  String get taskPostponed => 'Task ditunda. Jadwal akan disesuaikan saat kamu menerima penyesuaian.';

  @override
  String taskPostponedTwice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Task ini sudah ditunda $count kali. Coba pecah jadi langkah kecil 25 menit.',
    );
    return '$_temp0';
  }

  @override
  String get taskDeleteConfirm => 'Hapus task ini beserta subtask-nya?';

  @override
  String get taskSaved => 'Tersimpan.';

  @override
  String get firstStepTitle => 'Langkah pertama, sekitar 25 menit';

  @override
  String get planEmpty => 'Belum ada task di rencana.';

  @override
  String get subtasksTitle => 'Subtask';

  @override
  String explainPrompt(String title) {
    return 'Jelaskan cara mengerjakan \"$title\" berdasarkan referensi di project ini.';
  }

  @override
  String get timelineToday => 'Hari ini';

  @override
  String get timelineDeadline => 'Deadline';

  @override
  String get suggestionKindPlan => 'Rencana baru';

  @override
  String get suggestionKindReplan => 'Penyesuaian rencana';

  @override
  String get suggestionKindTaskChange => 'Perubahan task';

  @override
  String get suggestionKindBriefUpdate => 'Pembaruan brief';

  @override
  String get suggestionAcceptAll => 'Terima semua';

  @override
  String suggestionAcceptSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Terima $count yang dipilih');
    return '$_temp0';
  }

  @override
  String get suggestionReject => 'Tolak';

  @override
  String get suggestionApplied => 'Usulan diterapkan. Jadwal sudah diperbarui.';

  @override
  String get suggestionRejected => 'Usulan ditolak. Rencana tidak berubah.';

  @override
  String get suggestionNothingChanges => 'Tidak ada yang berubah sebelum kamu menerimanya.';

  @override
  String get suggestionPick => 'Pilih perubahan yang mau diterima';

  @override
  String opAddTask(String title) {
    return 'Tambah task: $title';
  }

  @override
  String opAddSubtask(String title) {
    return 'Tambah subtask: $title';
  }

  @override
  String opAddMilestone(String title) {
    return 'Tambah milestone: $title';
  }

  @override
  String opDeferTask(String title) {
    return 'Tunda di luar scope: $title';
  }

  @override
  String opUpdateTask(String title) {
    return 'Ubah task: $title';
  }

  @override
  String opDeleteTask(String title) {
    return 'Hapus task: $title';
  }

  @override
  String opAddRequirement(String text) {
    return 'Tambah syarat: $text';
  }

  @override
  String opAddMemory(String text) {
    return 'Ingat untuk project: $text';
  }

  @override
  String get opReschedule => 'Susun ulang jadwal mulai hari ini';

  @override
  String opExtraHours(String hours, String date) {
    return 'Tambah total $hours jam kerja sampai $date';
  }

  @override
  String opDeadline(String date) {
    return 'Pindahkan target ke $date';
  }

  @override
  String changedTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count task berubah jadwal',
      zero: 'Tidak ada task yang berubah jadwal',
    );
    return '$_temp0';
  }

  @override
  String get planQuestions => 'Pertanyaan yang perlu kamu jawab';

  @override
  String get planAssumptions => 'Asumsi';

  @override
  String get hoursUnit => 'jam';

  @override
  String get replanTitle => 'Sesuaikan rencana';

  @override
  String get replanIntro =>
      'Penjadwal sudah menghitung beberapa pilihan. Pilih yang paling cocok; tidak ada yang berubah sebelum kamu menerimanya.';

  @override
  String get replanComputing => 'Menghitung pilihan…';

  @override
  String get optionReschedule => 'Susun ulang dari hari ini';

  @override
  String get optionRescheduleDesc => 'Task yang belum selesai dijadwalkan ulang mulai hari ini, yang paling mendesak lebih dulu.';

  @override
  String get optionAddCapacity => 'Tambah jam kerja';

  @override
  String optionAddCapacityDesc(String hours, String weeks) {
    return 'Tambah $hours jam per minggu selama $weeks minggu.';
  }

  @override
  String get optionReduceScope => 'Kurangi scope';

  @override
  String optionReduceScopeDesc(String tasks) {
    return 'Tunda task opsional: $tasks.';
  }

  @override
  String get optionExtendDeadline => 'Mundurkan target';

  @override
  String optionExtendDeadlineDesc(String date, String days) {
    return 'Target baru $date, $days hari lebih lambat. Hanya jika aturan kampus mengizinkan.';
  }

  @override
  String get chooseOption => 'Pilih opsi ini';

  @override
  String get documentsTitle => 'Library dokumen';

  @override
  String get documentsUpload => 'Unggah dokumen';

  @override
  String get documentsEmpty =>
      'Belum ada dokumen. Unggah proposal, instruksi dosen, atau jurnal. Isinya dipakai untuk brief, rencana, dan tanya-jawab bersumber.';

  @override
  String get documentsHint => 'PDF, DOCX, TXT, atau MD · maksimal 20 MB';

  @override
  String get docStatusProcessing => 'Sedang diproses…';

  @override
  String get docStatusReady => 'Siap';

  @override
  String get docStatusFailed => 'Gagal diproses';

  @override
  String docPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count halaman');
    return '$_temp0';
  }

  @override
  String get docKindProposal => 'Proposal';

  @override
  String get docKindInstruction => 'Instruksi atau panduan';

  @override
  String get docKindJournal => 'Jurnal atau referensi';

  @override
  String get docKindSupervision => 'Catatan bimbingan';

  @override
  String get docKindDraft => 'Draf naskah';

  @override
  String get docKindOther => 'Lainnya';

  @override
  String get docSummaryBasic => 'Ringkasan otomatis tanpa AI';

  @override
  String docDeleteConfirm(String title) {
    return 'Hapus \"$title\"? Semua potongan yang sudah terindeks ikut terhapus.';
  }

  @override
  String docUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count dokumen diunggah dan sedang diproses.');
    return '$_temp0';
  }

  @override
  String get assistantTitle => 'Asisten project';

  @override
  String get assistantHint => 'Tanya tentang project atau dokumenmu…';

  @override
  String get assistantEmpty => 'Tanya apa saja tentang project ini. Jawaban merujuk dokumenmu beserta halamannya.';

  @override
  String get assistantSuggestion1 => 'Apa saja syarat dari dosen?';

  @override
  String get assistantSuggestion2 => 'Metode apa yang paling sering dipakai di jurnal saya?';

  @override
  String get assistantSuggestion3 => 'Apa yang sebaiknya saya kerjakan minggu ini?';

  @override
  String get assistantThinking => 'Mencari di dokumen…';

  @override
  String get assistantSend => 'Kirim';

  @override
  String get answerExtractiveHeader => 'AI belum aktif. Ini bagian dokumen yang paling relevan:';

  @override
  String get answerNotFound => 'Informasi ini tidak ditemukan di dokumen project.';

  @override
  String get answerGeneral => 'Jawaban dari pengetahuan umum, bukan dari dokumen project.';

  @override
  String citationPages(String start, String end) {
    return 'hlm. $start–$end';
  }

  @override
  String citationPage(String page) {
    return 'hlm. $page';
  }

  @override
  String get newConversation => 'Percakapan baru';

  @override
  String get conversations => 'Percakapan';

  @override
  String get feedbackUp => 'Jawaban membantu';

  @override
  String get feedbackDown => 'Jawaban kurang membantu';

  @override
  String get projectOverview => 'Ringkasan project';

  @override
  String get milestonesTitle => 'Milestone';

  @override
  String milestoneProgress(String done, String total) {
    return '$done dari $total task';
  }

  @override
  String get requirementsTitle => 'Syarat dosen';

  @override
  String get requirementUncovered => 'Belum ada task untuk syarat ini';

  @override
  String get requirementMet => 'Terpenuhi';

  @override
  String get requirementCovered => 'Sedang dikerjakan';

  @override
  String get requirementsEmpty => 'Belum ada syarat di brief.';

  @override
  String get openBrief => 'Brief project';

  @override
  String get openSupervision => 'Log bimbingan';

  @override
  String get openReview => 'Review mingguan';

  @override
  String get projectSettings => 'Pengaturan project';

  @override
  String get newProject => 'Project baru';

  @override
  String get switchProject => 'Ganti project';

  @override
  String get deleteProject => 'Hapus project';

  @override
  String get deleteProjectConfirm => 'Project ini dipindahkan ke tempat sampah dan terhapus permanen setelah 30 hari.';

  @override
  String get pendingTitle => 'Usulan menunggu';

  @override
  String get briefTitle => 'Brief project';

  @override
  String get briefGoal => 'Tujuan';

  @override
  String get briefDeliverables => 'Hasil akhir';

  @override
  String get briefRequirements => 'Syarat dosen';

  @override
  String get briefDates => 'Tanggal penting';

  @override
  String get briefConstraints => 'Batasan';

  @override
  String get briefQuestions => 'Pertanyaan terbuka';

  @override
  String get briefAnswerHint => 'Jawabanmu';

  @override
  String get briefItemHint => 'Tulis di sini';

  @override
  String get briefDateLabelHint => 'Nama acara';

  @override
  String briefVersion(String version) {
    return 'Versi $version';
  }

  @override
  String get briefSaved => 'Brief disimpan sebagai versi baru.';

  @override
  String get briefExtracting => 'Menyusun brief dari dokumen… biasanya 30–60 detik.';

  @override
  String get briefExtractAgain => 'Susun ulang dari dokumen';

  @override
  String get briefEmpty => 'Brief belum diisi.';

  @override
  String get supervisionTitle => 'Log bimbingan';

  @override
  String get supervisionIntro =>
      'Catat hasil bimbingan. Revisi dari dosen diubah jadi usulan task; tidak ada yang masuk rencana sebelum kamu setujui.';

  @override
  String get supervisionDate => 'Tanggal bimbingan';

  @override
  String get supervisionNotes => 'Catatan bimbingan';

  @override
  String get supervisionNotesHint => 'Satu revisi per baris, misalnya: - Tambah 5 referensi terbaru di Bab 2';

  @override
  String get supervisionSave => 'Simpan dan buat usulan';

  @override
  String get supervisionNoProposal => 'Catatan disimpan. Tidak ada revisi yang terdeteksi.';

  @override
  String get supervisionHistory => 'Riwayat bimbingan';

  @override
  String get supervisionEmpty => 'Belum ada catatan bimbingan.';

  @override
  String get reviewTitle => 'Review mingguan';

  @override
  String reviewDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count task selesai minggu ini');
    return '$_temp0';
  }

  @override
  String get reviewSlipped => 'Tertinggal';

  @override
  String get reviewNextFocus => 'Fokus minggu depan';

  @override
  String get reviewRecommendReplan => 'Rencana perlu disesuaikan agar tetap realistis.';

  @override
  String get reviewNothingDone => 'Belum ada task selesai minggu ini. Tidak apa-apa; mulai lagi dari satu langkah kecil.';

  @override
  String get reviewHealthNow => 'Status sekarang';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsTheme => 'Tampilan';

  @override
  String get themeSystem => 'Ikuti sistem';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get settingsServer => 'Alamat server';

  @override
  String get settingsServerHint => 'Contoh: http://localhost:8000';

  @override
  String get settingsServerTest => 'Tes koneksi';

  @override
  String get settingsServerOk => 'Terhubung ke server.';

  @override
  String get settingsAi => 'AI';

  @override
  String get settingsAiActive => 'Aktif';

  @override
  String get settingsAiInactive => 'Belum aktif. Server berjalan tanpa API key.';

  @override
  String settingsQuota(String used, String limit) {
    return '$used dari $limit token bulan ini';
  }

  @override
  String settingsQuotaReset(String date) {
    return 'Kuota pulih $date';
  }

  @override
  String get settingsAccount => 'Akun dan data';

  @override
  String get settingsLocalMode => 'Mode lokal: satu pengguna, tanpa login.';

  @override
  String get settingsExport => 'Ekspor semua data';

  @override
  String get settingsExported => 'Data diekspor.';

  @override
  String get settingsDeleteAccount => 'Hapus akun';

  @override
  String get settingsDeleteConfirm => 'Semua project, dokumen, dan catatan akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.';

  @override
  String get settingsDeleteButton => 'Hapus permanen';

  @override
  String get settingsAbout => 'Tentang';

  @override
  String settingsVersion(String version) {
    return 'Versi $version';
  }

  @override
  String get settingsPrivacy =>
      'Dokumen dan catatanmu tersimpan di server Purnara. Saat AI aktif, bagian yang relevan dikirim ke penyedia AI (Claude) untuk diproses dan tidak dipakai untuk melatih model.';

  @override
  String get settingsFontLicense => 'Font Plus Jakarta Sans, lisensi SIL Open Font License 1.1.';

  @override
  String get onboardingWelcomeTitle => 'Selesaikan project besarmu, satu langkah sehari.';

  @override
  String get onboardingWelcomeBody =>
      'Purnara menyusun rencana dari dokumenmu, memberi tahu apa yang dikerjakan hari ini, dan menyesuaikan jadwal saat keadaan berubah. Kamu selalu yang memutuskan.';

  @override
  String get onboardingStart => 'Mulai';

  @override
  String onboardingStep(String current, String total) {
    return 'Langkah $current dari $total';
  }

  @override
  String get stepTemplate => 'Pilih jenis project';

  @override
  String get stepDetails => 'Judul dan deadline';

  @override
  String get stepDocuments => 'Unggah dokumen';

  @override
  String get stepBrief => 'Periksa brief';

  @override
  String get stepCapacity => 'Waktu yang tersedia';

  @override
  String get stepPreview => 'Pratinjau rencana';

  @override
  String templateSummary(String tasks, String hours) {
    return '$tasks task · sekitar $hours jam';
  }

  @override
  String get fieldTitle => 'Judul project';

  @override
  String get fieldTitleHint => 'Misalnya: Decision-making NPC untuk game RTS';

  @override
  String get fieldDescription => 'Deskripsi singkat';

  @override
  String get fieldTarget => 'Target (opsional)';

  @override
  String get fieldTargetHint => 'Misalnya: sidang sebelum Maret';

  @override
  String get fieldDeadline => 'Deadline (misalnya tanggal sidang)';

  @override
  String get fieldRequired => 'Wajib diisi';

  @override
  String get pickDate => 'Pilih tanggal';

  @override
  String get documentsStepHint => 'Unggah proposal dan instruksi dosen. Boleh dilewati dan ditambah nanti.';

  @override
  String get capacityIntro => 'Berapa jam per hari yang realistis untuk project ini?';

  @override
  String capacityWeekly(String hours) {
    return '$hours jam per minggu';
  }

  @override
  String get blockedDates => 'Hari tanpa kerja (UTS, UAS, libur)';

  @override
  String get addBlockedDate => 'Tambah tanggal';

  @override
  String bufferLabel(String pct) {
    return 'Cadangan waktu $pct%';
  }

  @override
  String get previewGenerating => 'Menyusun rencana…';

  @override
  String get previewAccept => 'Terima rencana';

  @override
  String get previewRegenerate => 'Susun ulang';

  @override
  String previewSummary(String tasks, String hours) {
    return '$tasks task · $hours jam total';
  }

  @override
  String get previewReady => 'Rencana siap. Kamu bisa mengubahnya kapan saja.';

  @override
  String get creatingProject => 'Membuat project…';

  @override
  String get notificationsEmpty => 'Belum ada notifikasi.';

  @override
  String notifHealthDrop(String status) {
    return 'Status project berubah menjadi: $status.';
  }

  @override
  String notifDeadline(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: 'Deadline tinggal $days hari lagi.');
    return '$_temp0';
  }

  @override
  String get documentsWaitProcessing => 'Menunggu dokumen selesai diproses…';

  @override
  String get previewReviewDetails => 'Tinjau detail';

  @override
  String previewUncovered(String codes) {
    return 'Syarat yang belum punya task: $codes';
  }

  @override
  String milestoneSummary(String tasks, String hours) {
    return '$tasks task · $hours jam';
  }

  @override
  String get optionalTag => 'Opsional';

  @override
  String get recommendedTag => 'Disarankan';

  @override
  String get deferredSection => 'Ditunda, di luar scope';

  @override
  String get boardMoveTo => 'Pindahkan ke';

  @override
  String get estimateRange => 'Isi 0,5 sampai 40 jam.';

  @override
  String opsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count perubahan');
    return '$_temp0';
  }

  @override
  String hoursDone(String done, String total) {
    return '$done dari $total jam selesai';
  }

  @override
  String get chartPlanned => 'Rencana';

  @override
  String get chartActual => 'Tercapai';

  @override
  String get briefDraftUnsaved => 'Draf baru dari dokumen. Periksa, lalu simpan.';

  @override
  String get copyText => 'Salin';

  @override
  String get copied => 'Disalin.';

  @override
  String get settingsLicenses => 'Lisensi open source';

  @override
  String get settingsServerInvalid => 'Alamat tidak valid. Contoh: http://localhost:8000';

  @override
  String get settingsServerReset => 'Pakai alamat bawaan';

  @override
  String get welcomePreviewProject => 'Skripsi: NPC untuk game RTS';

  @override
  String get welcomePreviewMilestone => 'Studi literatur';

  @override
  String get welcomePreviewTask1 => 'Rumuskan masalah penelitian';

  @override
  String get welcomePreviewTask2 => 'Baca dan rangkum 10 jurnal utama';

  @override
  String get breakingDown => 'Memecah task menjadi langkah kecil…';

  @override
  String get discardChangesMessage => 'Perubahan belum disimpan. Tinggalkan halaman ini?';

  @override
  String get discardChangesAction => 'Tinggalkan';

  @override
  String get sampleProjectTry => 'Coba dengan contoh project';

  @override
  String get sampleProjectHint =>
      'Contoh berisi dokumen, brief, rencana, dan satu usulan untuk dicoba. Bisa dihapus kapan saja dari Pengaturan Project.';

  @override
  String get sampleProjectCreating => 'Menyiapkan contoh project…';

  @override
  String get sampleProjectReady => 'Contoh project siap. Silakan dicoba.';

  @override
  String get settingsPhoneTitle => 'Buka di HP';

  @override
  String get settingsPhoneNoNetwork => 'Laptop ini belum terhubung ke Wi-Fi. Sambungkan laptop dan HP ke Wi-Fi yang sama.';

  @override
  String get settingsPhoneStartServer =>
      'Server hanya bisa dibuka dari laptop ini. Di VS Code, jalankan \"Backend: API for phones on the same Wi-Fi\", lalu muat ulang kartu ini.';

  @override
  String get settingsPhoneOpen => 'Sambungkan HP ke Wi-Fi yang sama, lalu buka alamat ini di browser HP:';

  @override
  String get settingsPhoneBuildFirst =>
      'Build aplikasi web dulu (Terminal → Run Task → App: build web), lalu buka alamat ini di browser HP pada Wi-Fi yang sama:';

  @override
  String get answerClosestHeader =>
      'AI belum aktif dan tidak ada bagian yang cocok persis. Ini yang paling mendekati, periksa apakah menjawab pertanyaanmu:';

  @override
  String get answerNotFoundNoAi =>
      'Tanpa AI, asisten mencari kata yang sama di dokumen. Coba kata kunci yang dipakai dokumenmu, misalnya \"referensi\" atau nama metode.';
}
