import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In id, this message translates to:
  /// **'Purnara'**
  String get appTitle;

  /// No description provided for @navToday.
  ///
  /// In id, this message translates to:
  /// **'Hari Ini'**
  String get navToday;

  /// No description provided for @navProject.
  ///
  /// In id, this message translates to:
  /// **'Project'**
  String get navProject;

  /// No description provided for @navPlan.
  ///
  /// In id, this message translates to:
  /// **'Rencana'**
  String get navPlan;

  /// No description provided for @navDocuments.
  ///
  /// In id, this message translates to:
  /// **'Dokumen'**
  String get navDocuments;

  /// No description provided for @navAssistant.
  ///
  /// In id, this message translates to:
  /// **'Asisten'**
  String get navAssistant;

  /// No description provided for @actionRetry.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get actionRetry;

  /// No description provided for @actionCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get actionSave;

  /// No description provided for @actionDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get actionDelete;

  /// No description provided for @actionClose.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get actionClose;

  /// No description provided for @actionNext.
  ///
  /// In id, this message translates to:
  /// **'Lanjut'**
  String get actionNext;

  /// No description provided for @actionBack.
  ///
  /// In id, this message translates to:
  /// **'Kembali'**
  String get actionBack;

  /// No description provided for @actionSkip.
  ///
  /// In id, this message translates to:
  /// **'Lewati'**
  String get actionSkip;

  /// No description provided for @actionAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get actionAdd;

  /// No description provided for @actionRefresh.
  ///
  /// In id, this message translates to:
  /// **'Muat ulang'**
  String get actionRefresh;

  /// No description provided for @actionUndo.
  ///
  /// In id, this message translates to:
  /// **'Batalkan'**
  String get actionUndo;

  /// No description provided for @settingsTitle.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settingsTitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi'**
  String get notificationsTitle;

  /// No description provided for @loading.
  ///
  /// In id, this message translates to:
  /// **'Memuat…'**
  String get loading;

  /// No description provided for @errorGeneric.
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan. Coba lagi sebentar lagi.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In id, this message translates to:
  /// **'Tidak bisa terhubung ke server Purnara di {url}. Pastikan backend sedang berjalan.'**
  String errorNetwork(String url);

  /// No description provided for @errorNotFound.
  ///
  /// In id, this message translates to:
  /// **'Data tidak ditemukan. Mungkin sudah dihapus.'**
  String get errorNotFound;

  /// No description provided for @errorValidation.
  ///
  /// In id, this message translates to:
  /// **'Ada isian yang belum valid. Periksa lagi.'**
  String get errorValidation;

  /// No description provided for @errorDeadlinePast.
  ///
  /// In id, this message translates to:
  /// **'Deadline harus setelah hari ini.'**
  String get errorDeadlinePast;

  /// No description provided for @errorDependencyCycle.
  ///
  /// In id, this message translates to:
  /// **'Dependensi ini membuat lingkaran: task-task akan saling menunggu.'**
  String get errorDependencyCycle;

  /// No description provided for @errorPlanExists.
  ///
  /// In id, this message translates to:
  /// **'Project ini sudah punya rencana. Gunakan \"Sesuaikan rencana\".'**
  String get errorPlanExists;

  /// No description provided for @errorNoPlan.
  ///
  /// In id, this message translates to:
  /// **'Buat rencana dulu.'**
  String get errorNoPlan;

  /// No description provided for @errorSuggestionDecided.
  ///
  /// In id, this message translates to:
  /// **'Usulan ini sudah diputuskan sebelumnya.'**
  String get errorSuggestionDecided;

  /// No description provided for @errorUnsupportedFile.
  ///
  /// In id, this message translates to:
  /// **'Format belum didukung. Gunakan PDF, DOCX, TXT, atau MD.'**
  String get errorUnsupportedFile;

  /// No description provided for @errorFileTooLarge.
  ///
  /// In id, this message translates to:
  /// **'File terlalu besar (maksimal 20 MB).'**
  String get errorFileTooLarge;

  /// No description provided for @errorTooManyPages.
  ///
  /// In id, this message translates to:
  /// **'Dokumen terlalu panjang (maksimal 300 halaman).'**
  String get errorTooManyPages;

  /// No description provided for @errorDuplicate.
  ///
  /// In id, this message translates to:
  /// **'Dokumen ini sudah ada di library.'**
  String get errorDuplicate;

  /// No description provided for @errorUnreadable.
  ///
  /// In id, this message translates to:
  /// **'File tidak bisa dibaca. Mungkin rusak atau terkunci kata sandi.'**
  String get errorUnreadable;

  /// No description provided for @errorNoText.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada teks yang bisa dibaca. Kemungkinan hasil scan; dukungan dokumen scan menyusul.'**
  String get errorNoText;

  /// No description provided for @errorInvalidCapacity.
  ///
  /// In id, this message translates to:
  /// **'Isi 0 sampai 16 jam per hari, dengan minimal satu hari lebih dari 0.'**
  String get errorInvalidCapacity;

  /// No description provided for @errorQuota.
  ///
  /// In id, this message translates to:
  /// **'Kuota AI bulan ini habis. Pulih pada {date}.'**
  String errorQuota(String date);

  /// No description provided for @errorUnauthenticated.
  ///
  /// In id, this message translates to:
  /// **'Sesi berakhir. Silakan masuk lagi.'**
  String get errorUnauthenticated;

  /// No description provided for @errorEmptyFile.
  ///
  /// In id, this message translates to:
  /// **'File kosong.'**
  String get errorEmptyFile;

  /// No description provided for @aiNotActive.
  ///
  /// In id, this message translates to:
  /// **'AI belum aktif di server ini. Semua fitur tetap berjalan dengan versi dasar tanpa AI.'**
  String get aiNotActive;

  /// No description provided for @aiLabel.
  ///
  /// In id, this message translates to:
  /// **'Usulan AI'**
  String get aiLabel;

  /// No description provided for @templateLabel.
  ///
  /// In id, this message translates to:
  /// **'Dari template'**
  String get templateLabel;

  /// No description provided for @schedulerLabel.
  ///
  /// In id, this message translates to:
  /// **'Dari penjadwal'**
  String get schedulerLabel;

  /// No description provided for @basicLabel.
  ///
  /// In id, this message translates to:
  /// **'Tanpa AI'**
  String get basicLabel;

  /// No description provided for @aiErrorUnavailable.
  ///
  /// In id, this message translates to:
  /// **'AI belum aktif, jadi dipakai versi dasar.'**
  String get aiErrorUnavailable;

  /// No description provided for @aiErrorQuota.
  ///
  /// In id, this message translates to:
  /// **'Kuota AI habis, jadi dipakai versi dasar.'**
  String get aiErrorQuota;

  /// No description provided for @aiErrorFailed.
  ///
  /// In id, this message translates to:
  /// **'AI sedang bermasalah, jadi dipakai versi dasar.'**
  String get aiErrorFailed;

  /// No description provided for @aiErrorInvalidPlan.
  ///
  /// In id, this message translates to:
  /// **'Rencana dari AI tidak lolos pemeriksaan, jadi dipakai template.'**
  String get aiErrorInvalidPlan;

  /// No description provided for @healthOnTrack.
  ///
  /// In id, this message translates to:
  /// **'Sesuai jadwal'**
  String get healthOnTrack;

  /// No description provided for @healthAtRisk.
  ///
  /// In id, this message translates to:
  /// **'Perlu perhatian'**
  String get healthAtRisk;

  /// No description provided for @healthOffTrack.
  ///
  /// In id, this message translates to:
  /// **'Tertinggal'**
  String get healthOffTrack;

  /// No description provided for @healthNoPlan.
  ///
  /// In id, this message translates to:
  /// **'Belum ada rencana'**
  String get healthNoPlan;

  /// No description provided for @healthReasonInfeasible.
  ///
  /// In id, this message translates to:
  /// **'Jam yang tersedia tidak cukup sampai deadline.'**
  String get healthReasonInfeasible;

  /// No description provided for @healthReasonCriticalLate.
  ///
  /// In id, this message translates to:
  /// **'{days, plural, other{Task di jalur kritis terlambat {days} hari.}}'**
  String healthReasonCriticalLate(int days);

  /// No description provided for @healthReasonSpiLow.
  ///
  /// In id, this message translates to:
  /// **'Progress jauh di bawah rencana.'**
  String get healthReasonSpiLow;

  /// No description provided for @healthReasonSpiModerate.
  ///
  /// In id, this message translates to:
  /// **'Progress sedikit di bawah rencana.'**
  String get healthReasonSpiModerate;

  /// No description provided for @healthAllGood.
  ///
  /// In id, this message translates to:
  /// **'Progress sesuai rencana.'**
  String get healthAllGood;

  /// No description provided for @progressPlanned.
  ///
  /// In id, this message translates to:
  /// **'Rencana {pct}%'**
  String progressPlanned(String pct);

  /// No description provided for @progressActual.
  ///
  /// In id, this message translates to:
  /// **'Tercapai {pct}%'**
  String progressActual(String pct);

  /// No description provided for @feasibilityFeasible.
  ///
  /// In id, this message translates to:
  /// **'Rencana muat sebelum deadline'**
  String get feasibilityFeasible;

  /// No description provided for @feasibilityTight.
  ///
  /// In id, this message translates to:
  /// **'Muat, tapi cadangan waktu terpakai'**
  String get feasibilityTight;

  /// No description provided for @feasibilityInfeasible.
  ///
  /// In id, this message translates to:
  /// **'Kurang {hours} jam sebelum deadline'**
  String feasibilityInfeasible(String hours);

  /// No description provided for @projectedFinish.
  ///
  /// In id, this message translates to:
  /// **'Perkiraan selesai {date}'**
  String projectedFinish(String date);

  /// No description provided for @daysLeft.
  ///
  /// In id, this message translates to:
  /// **'{days, plural, =0{Deadline hari ini} other{{days} hari lagi}}'**
  String daysLeft(int days);

  /// No description provided for @deadlinePassed.
  ///
  /// In id, this message translates to:
  /// **'Deadline sudah lewat'**
  String get deadlinePassed;

  /// No description provided for @deadlineOn.
  ///
  /// In id, this message translates to:
  /// **'Deadline {date}'**
  String deadlineOn(String date);

  /// No description provided for @hoursValue.
  ///
  /// In id, this message translates to:
  /// **'{hours} jam'**
  String hoursValue(String hours);

  /// No description provided for @todayTitle.
  ///
  /// In id, this message translates to:
  /// **'Fokus hari ini'**
  String get todayTitle;

  /// No description provided for @todayMore.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{+{count} task lain juga dijadwalkan hari ini}}'**
  String todayMore(int count);

  /// No description provided for @todayUpcoming.
  ///
  /// In id, this message translates to:
  /// **'Minggu ini'**
  String get todayUpcoming;

  /// No description provided for @todayEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada task terjadwal hari ini.'**
  String get todayEmpty;

  /// No description provided for @todayNoPlan.
  ///
  /// In id, this message translates to:
  /// **'Project ini belum punya rencana.'**
  String get todayNoPlan;

  /// No description provided for @todayMakePlan.
  ///
  /// In id, this message translates to:
  /// **'Susun rencana'**
  String get todayMakePlan;

  /// No description provided for @markDone.
  ///
  /// In id, this message translates to:
  /// **'Tandai selesai'**
  String get markDone;

  /// No description provided for @markedDone.
  ///
  /// In id, this message translates to:
  /// **'Task ditandai selesai.'**
  String get markedDone;

  /// No description provided for @helpMeStart.
  ///
  /// In id, this message translates to:
  /// **'Bantu saya mulai'**
  String get helpMeStart;

  /// No description provided for @lateBadge.
  ///
  /// In id, this message translates to:
  /// **'{days, plural, other{Terlambat {days} hari}}'**
  String lateBadge(int days);

  /// No description provided for @criticalBadge.
  ///
  /// In id, this message translates to:
  /// **'Jalur kritis'**
  String get criticalBadge;

  /// No description provided for @pendingSuggestions.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} usulan menunggu keputusanmu}}'**
  String pendingSuggestions(int count);

  /// No description provided for @reviewAction.
  ///
  /// In id, this message translates to:
  /// **'Tinjau'**
  String get reviewAction;

  /// No description provided for @needsReschedule.
  ///
  /// In id, this message translates to:
  /// **'Ada perubahan yang belum masuk jadwal.'**
  String get needsReschedule;

  /// No description provided for @adjustPlan.
  ///
  /// In id, this message translates to:
  /// **'Sesuaikan rencana'**
  String get adjustPlan;

  /// No description provided for @capacityToday.
  ///
  /// In id, this message translates to:
  /// **'Kapasitas hari ini {hours}'**
  String capacityToday(String hours);

  /// No description provided for @nextMilestone.
  ///
  /// In id, this message translates to:
  /// **'Berikutnya: {title}'**
  String nextMilestone(String title);

  /// No description provided for @planTabList.
  ///
  /// In id, this message translates to:
  /// **'Daftar'**
  String get planTabList;

  /// No description provided for @planTabBoard.
  ///
  /// In id, this message translates to:
  /// **'Papan'**
  String get planTabBoard;

  /// No description provided for @planTabTimeline.
  ///
  /// In id, this message translates to:
  /// **'Linimasa'**
  String get planTabTimeline;

  /// No description provided for @statusTodo.
  ///
  /// In id, this message translates to:
  /// **'Belum'**
  String get statusTodo;

  /// No description provided for @statusInProgress.
  ///
  /// In id, this message translates to:
  /// **'Dikerjakan'**
  String get statusInProgress;

  /// No description provided for @statusDone.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get statusDone;

  /// No description provided for @taskAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah task'**
  String get taskAdd;

  /// No description provided for @taskTitle.
  ///
  /// In id, this message translates to:
  /// **'Judul task'**
  String get taskTitle;

  /// No description provided for @taskEstimate.
  ///
  /// In id, this message translates to:
  /// **'Estimasi (jam)'**
  String get taskEstimate;

  /// No description provided for @taskActual.
  ///
  /// In id, this message translates to:
  /// **'Jam aktual'**
  String get taskActual;

  /// No description provided for @taskMilestone.
  ///
  /// In id, this message translates to:
  /// **'Milestone'**
  String get taskMilestone;

  /// No description provided for @taskNoMilestone.
  ///
  /// In id, this message translates to:
  /// **'Tanpa milestone'**
  String get taskNoMilestone;

  /// No description provided for @taskOptional.
  ///
  /// In id, this message translates to:
  /// **'Opsional (boleh dilepas saat waktu mepet)'**
  String get taskOptional;

  /// No description provided for @taskDeferred.
  ///
  /// In id, this message translates to:
  /// **'Ditunda, di luar scope'**
  String get taskDeferred;

  /// No description provided for @taskImportance.
  ///
  /// In id, this message translates to:
  /// **'Tingkat penting'**
  String get taskImportance;

  /// No description provided for @importanceNormal.
  ///
  /// In id, this message translates to:
  /// **'Biasa'**
  String get importanceNormal;

  /// No description provided for @importanceHigh.
  ///
  /// In id, this message translates to:
  /// **'Penting'**
  String get importanceHigh;

  /// No description provided for @importanceTop.
  ///
  /// In id, this message translates to:
  /// **'Sangat penting'**
  String get importanceTop;

  /// No description provided for @taskScheduled.
  ///
  /// In id, this message translates to:
  /// **'{start} – {end}'**
  String taskScheduled(String start, String end);

  /// No description provided for @taskUnscheduled.
  ///
  /// In id, this message translates to:
  /// **'Belum dijadwalkan'**
  String get taskUnscheduled;

  /// No description provided for @taskLatestFinish.
  ///
  /// In id, this message translates to:
  /// **'Paling lambat selesai {date}'**
  String taskLatestFinish(String date);

  /// No description provided for @taskDependsOn.
  ///
  /// In id, this message translates to:
  /// **'Menunggu task'**
  String get taskDependsOn;

  /// No description provided for @taskRequirements.
  ///
  /// In id, this message translates to:
  /// **'Memenuhi syarat'**
  String get taskRequirements;

  /// No description provided for @taskDefinitionOfDone.
  ///
  /// In id, this message translates to:
  /// **'Kriteria selesai'**
  String get taskDefinitionOfDone;

  /// No description provided for @taskNotes.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get taskNotes;

  /// No description provided for @taskSchedule.
  ///
  /// In id, this message translates to:
  /// **'Jadwal'**
  String get taskSchedule;

  /// No description provided for @taskBreakDown.
  ///
  /// In id, this message translates to:
  /// **'Pecah task ini'**
  String get taskBreakDown;

  /// No description provided for @taskExplain.
  ///
  /// In id, this message translates to:
  /// **'Jelaskan dari referensi'**
  String get taskExplain;

  /// No description provided for @taskPostpone.
  ///
  /// In id, this message translates to:
  /// **'Tunda'**
  String get taskPostpone;

  /// No description provided for @taskPostponed.
  ///
  /// In id, this message translates to:
  /// **'Task ditunda. Jadwal akan disesuaikan saat kamu menerima penyesuaian.'**
  String get taskPostponed;

  /// No description provided for @taskPostponedTwice.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{Task ini sudah ditunda {count} kali. Coba pecah jadi langkah kecil 25 menit.}}'**
  String taskPostponedTwice(int count);

  /// No description provided for @taskDeleteConfirm.
  ///
  /// In id, this message translates to:
  /// **'Hapus task ini beserta subtask-nya?'**
  String get taskDeleteConfirm;

  /// No description provided for @taskSaved.
  ///
  /// In id, this message translates to:
  /// **'Tersimpan.'**
  String get taskSaved;

  /// No description provided for @firstStepTitle.
  ///
  /// In id, this message translates to:
  /// **'Langkah pertama, sekitar 25 menit'**
  String get firstStepTitle;

  /// No description provided for @planEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada task di rencana.'**
  String get planEmpty;

  /// No description provided for @subtasksTitle.
  ///
  /// In id, this message translates to:
  /// **'Subtask'**
  String get subtasksTitle;

  /// No description provided for @explainPrompt.
  ///
  /// In id, this message translates to:
  /// **'Jelaskan cara mengerjakan \"{title}\" berdasarkan referensi di project ini.'**
  String explainPrompt(String title);

  /// No description provided for @timelineToday.
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get timelineToday;

  /// No description provided for @timelineDeadline.
  ///
  /// In id, this message translates to:
  /// **'Deadline'**
  String get timelineDeadline;

  /// No description provided for @suggestionKindPlan.
  ///
  /// In id, this message translates to:
  /// **'Rencana baru'**
  String get suggestionKindPlan;

  /// No description provided for @suggestionKindReplan.
  ///
  /// In id, this message translates to:
  /// **'Penyesuaian rencana'**
  String get suggestionKindReplan;

  /// No description provided for @suggestionKindTaskChange.
  ///
  /// In id, this message translates to:
  /// **'Perubahan task'**
  String get suggestionKindTaskChange;

  /// No description provided for @suggestionKindBriefUpdate.
  ///
  /// In id, this message translates to:
  /// **'Pembaruan brief'**
  String get suggestionKindBriefUpdate;

  /// No description provided for @suggestionAcceptAll.
  ///
  /// In id, this message translates to:
  /// **'Terima semua'**
  String get suggestionAcceptAll;

  /// No description provided for @suggestionAcceptSelected.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{Terima {count} yang dipilih}}'**
  String suggestionAcceptSelected(int count);

  /// No description provided for @suggestionReject.
  ///
  /// In id, this message translates to:
  /// **'Tolak'**
  String get suggestionReject;

  /// No description provided for @suggestionApplied.
  ///
  /// In id, this message translates to:
  /// **'Usulan diterapkan. Jadwal sudah diperbarui.'**
  String get suggestionApplied;

  /// No description provided for @suggestionRejected.
  ///
  /// In id, this message translates to:
  /// **'Usulan ditolak. Rencana tidak berubah.'**
  String get suggestionRejected;

  /// No description provided for @suggestionNothingChanges.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada yang berubah sebelum kamu menerimanya.'**
  String get suggestionNothingChanges;

  /// No description provided for @suggestionPick.
  ///
  /// In id, this message translates to:
  /// **'Pilih perubahan yang mau diterima'**
  String get suggestionPick;

  /// No description provided for @opAddTask.
  ///
  /// In id, this message translates to:
  /// **'Tambah task: {title}'**
  String opAddTask(String title);

  /// No description provided for @opAddSubtask.
  ///
  /// In id, this message translates to:
  /// **'Tambah subtask: {title}'**
  String opAddSubtask(String title);

  /// No description provided for @opAddMilestone.
  ///
  /// In id, this message translates to:
  /// **'Tambah milestone: {title}'**
  String opAddMilestone(String title);

  /// No description provided for @opDeferTask.
  ///
  /// In id, this message translates to:
  /// **'Tunda di luar scope: {title}'**
  String opDeferTask(String title);

  /// No description provided for @opUpdateTask.
  ///
  /// In id, this message translates to:
  /// **'Ubah task: {title}'**
  String opUpdateTask(String title);

  /// No description provided for @opDeleteTask.
  ///
  /// In id, this message translates to:
  /// **'Hapus task: {title}'**
  String opDeleteTask(String title);

  /// No description provided for @opAddRequirement.
  ///
  /// In id, this message translates to:
  /// **'Tambah syarat: {text}'**
  String opAddRequirement(String text);

  /// No description provided for @opAddMemory.
  ///
  /// In id, this message translates to:
  /// **'Ingat untuk project: {text}'**
  String opAddMemory(String text);

  /// No description provided for @opReschedule.
  ///
  /// In id, this message translates to:
  /// **'Susun ulang jadwal mulai hari ini'**
  String get opReschedule;

  /// No description provided for @opExtraHours.
  ///
  /// In id, this message translates to:
  /// **'Tambah total {hours} jam kerja sampai {date}'**
  String opExtraHours(String hours, String date);

  /// No description provided for @opDeadline.
  ///
  /// In id, this message translates to:
  /// **'Pindahkan target ke {date}'**
  String opDeadline(String date);

  /// No description provided for @changedTasks.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, =0{Tidak ada task yang berubah jadwal} other{{count} task berubah jadwal}}'**
  String changedTasks(int count);

  /// No description provided for @planQuestions.
  ///
  /// In id, this message translates to:
  /// **'Pertanyaan yang perlu kamu jawab'**
  String get planQuestions;

  /// No description provided for @planAssumptions.
  ///
  /// In id, this message translates to:
  /// **'Asumsi'**
  String get planAssumptions;

  /// No description provided for @hoursUnit.
  ///
  /// In id, this message translates to:
  /// **'jam'**
  String get hoursUnit;

  /// No description provided for @replanTitle.
  ///
  /// In id, this message translates to:
  /// **'Sesuaikan rencana'**
  String get replanTitle;

  /// No description provided for @replanIntro.
  ///
  /// In id, this message translates to:
  /// **'Penjadwal sudah menghitung beberapa pilihan. Pilih yang paling cocok; tidak ada yang berubah sebelum kamu menerimanya.'**
  String get replanIntro;

  /// No description provided for @replanComputing.
  ///
  /// In id, this message translates to:
  /// **'Menghitung pilihan…'**
  String get replanComputing;

  /// No description provided for @optionReschedule.
  ///
  /// In id, this message translates to:
  /// **'Susun ulang dari hari ini'**
  String get optionReschedule;

  /// No description provided for @optionRescheduleDesc.
  ///
  /// In id, this message translates to:
  /// **'Task yang belum selesai dijadwalkan ulang mulai hari ini, yang paling mendesak lebih dulu.'**
  String get optionRescheduleDesc;

  /// No description provided for @optionAddCapacity.
  ///
  /// In id, this message translates to:
  /// **'Tambah jam kerja'**
  String get optionAddCapacity;

  /// No description provided for @optionAddCapacityDesc.
  ///
  /// In id, this message translates to:
  /// **'Tambah {hours} jam per minggu selama {weeks} minggu.'**
  String optionAddCapacityDesc(String hours, String weeks);

  /// No description provided for @optionReduceScope.
  ///
  /// In id, this message translates to:
  /// **'Kurangi scope'**
  String get optionReduceScope;

  /// No description provided for @optionReduceScopeDesc.
  ///
  /// In id, this message translates to:
  /// **'Tunda task opsional: {tasks}.'**
  String optionReduceScopeDesc(String tasks);

  /// No description provided for @optionExtendDeadline.
  ///
  /// In id, this message translates to:
  /// **'Mundurkan target'**
  String get optionExtendDeadline;

  /// No description provided for @optionExtendDeadlineDesc.
  ///
  /// In id, this message translates to:
  /// **'Target baru {date}, {days} hari lebih lambat. Hanya jika aturan kampus mengizinkan.'**
  String optionExtendDeadlineDesc(String date, String days);

  /// No description provided for @chooseOption.
  ///
  /// In id, this message translates to:
  /// **'Pilih opsi ini'**
  String get chooseOption;

  /// No description provided for @documentsTitle.
  ///
  /// In id, this message translates to:
  /// **'Library dokumen'**
  String get documentsTitle;

  /// No description provided for @documentsUpload.
  ///
  /// In id, this message translates to:
  /// **'Unggah dokumen'**
  String get documentsUpload;

  /// No description provided for @documentsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada dokumen. Unggah proposal, instruksi dosen, atau jurnal. Isinya dipakai untuk brief, rencana, dan tanya-jawab bersumber.'**
  String get documentsEmpty;

  /// No description provided for @documentsHint.
  ///
  /// In id, this message translates to:
  /// **'PDF, DOCX, TXT, atau MD · maksimal 20 MB'**
  String get documentsHint;

  /// No description provided for @docStatusProcessing.
  ///
  /// In id, this message translates to:
  /// **'Sedang diproses…'**
  String get docStatusProcessing;

  /// No description provided for @docStatusReady.
  ///
  /// In id, this message translates to:
  /// **'Siap'**
  String get docStatusReady;

  /// No description provided for @docStatusFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal diproses'**
  String get docStatusFailed;

  /// No description provided for @docPages.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} halaman}}'**
  String docPages(int count);

  /// No description provided for @docKindProposal.
  ///
  /// In id, this message translates to:
  /// **'Proposal'**
  String get docKindProposal;

  /// No description provided for @docKindInstruction.
  ///
  /// In id, this message translates to:
  /// **'Instruksi atau panduan'**
  String get docKindInstruction;

  /// No description provided for @docKindJournal.
  ///
  /// In id, this message translates to:
  /// **'Jurnal atau referensi'**
  String get docKindJournal;

  /// No description provided for @docKindSupervision.
  ///
  /// In id, this message translates to:
  /// **'Catatan bimbingan'**
  String get docKindSupervision;

  /// No description provided for @docKindDraft.
  ///
  /// In id, this message translates to:
  /// **'Draf naskah'**
  String get docKindDraft;

  /// No description provided for @docKindOther.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get docKindOther;

  /// No description provided for @docSummaryBasic.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan otomatis tanpa AI'**
  String get docSummaryBasic;

  /// No description provided for @docDeleteConfirm.
  ///
  /// In id, this message translates to:
  /// **'Hapus \"{title}\"? Semua potongan yang sudah terindeks ikut terhapus.'**
  String docDeleteConfirm(String title);

  /// No description provided for @docUploaded.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} dokumen diunggah dan sedang diproses.}}'**
  String docUploaded(int count);

  /// No description provided for @assistantTitle.
  ///
  /// In id, this message translates to:
  /// **'Asisten project'**
  String get assistantTitle;

  /// No description provided for @assistantHint.
  ///
  /// In id, this message translates to:
  /// **'Tanya tentang project atau dokumenmu…'**
  String get assistantHint;

  /// No description provided for @assistantEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tanya apa saja tentang project ini. Jawaban merujuk dokumenmu beserta halamannya.'**
  String get assistantEmpty;

  /// No description provided for @assistantSuggestion1.
  ///
  /// In id, this message translates to:
  /// **'Apa saja syarat dari dosen?'**
  String get assistantSuggestion1;

  /// No description provided for @assistantSuggestion2.
  ///
  /// In id, this message translates to:
  /// **'Metode apa yang paling sering dipakai di jurnal saya?'**
  String get assistantSuggestion2;

  /// No description provided for @assistantSuggestion3.
  ///
  /// In id, this message translates to:
  /// **'Apa yang sebaiknya saya kerjakan minggu ini?'**
  String get assistantSuggestion3;

  /// No description provided for @assistantThinking.
  ///
  /// In id, this message translates to:
  /// **'Mencari di dokumen…'**
  String get assistantThinking;

  /// No description provided for @assistantSend.
  ///
  /// In id, this message translates to:
  /// **'Kirim'**
  String get assistantSend;

  /// No description provided for @answerExtractiveHeader.
  ///
  /// In id, this message translates to:
  /// **'AI belum aktif. Ini bagian dokumen yang paling relevan:'**
  String get answerExtractiveHeader;

  /// No description provided for @answerNotFound.
  ///
  /// In id, this message translates to:
  /// **'Informasi ini tidak ditemukan di dokumen project.'**
  String get answerNotFound;

  /// No description provided for @answerGeneral.
  ///
  /// In id, this message translates to:
  /// **'Jawaban dari pengetahuan umum, bukan dari dokumen project.'**
  String get answerGeneral;

  /// No description provided for @citationPages.
  ///
  /// In id, this message translates to:
  /// **'hlm. {start}–{end}'**
  String citationPages(String start, String end);

  /// No description provided for @citationPage.
  ///
  /// In id, this message translates to:
  /// **'hlm. {page}'**
  String citationPage(String page);

  /// No description provided for @newConversation.
  ///
  /// In id, this message translates to:
  /// **'Percakapan baru'**
  String get newConversation;

  /// No description provided for @conversations.
  ///
  /// In id, this message translates to:
  /// **'Percakapan'**
  String get conversations;

  /// No description provided for @feedbackUp.
  ///
  /// In id, this message translates to:
  /// **'Jawaban membantu'**
  String get feedbackUp;

  /// No description provided for @feedbackDown.
  ///
  /// In id, this message translates to:
  /// **'Jawaban kurang membantu'**
  String get feedbackDown;

  /// No description provided for @projectOverview.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan project'**
  String get projectOverview;

  /// No description provided for @milestonesTitle.
  ///
  /// In id, this message translates to:
  /// **'Milestone'**
  String get milestonesTitle;

  /// No description provided for @milestoneProgress.
  ///
  /// In id, this message translates to:
  /// **'{done} dari {total} task'**
  String milestoneProgress(String done, String total);

  /// No description provided for @requirementsTitle.
  ///
  /// In id, this message translates to:
  /// **'Syarat dosen'**
  String get requirementsTitle;

  /// No description provided for @requirementUncovered.
  ///
  /// In id, this message translates to:
  /// **'Belum ada task untuk syarat ini'**
  String get requirementUncovered;

  /// No description provided for @requirementMet.
  ///
  /// In id, this message translates to:
  /// **'Terpenuhi'**
  String get requirementMet;

  /// No description provided for @requirementCovered.
  ///
  /// In id, this message translates to:
  /// **'Sedang dikerjakan'**
  String get requirementCovered;

  /// No description provided for @requirementsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada syarat di brief.'**
  String get requirementsEmpty;

  /// No description provided for @openBrief.
  ///
  /// In id, this message translates to:
  /// **'Brief project'**
  String get openBrief;

  /// No description provided for @openSupervision.
  ///
  /// In id, this message translates to:
  /// **'Log bimbingan'**
  String get openSupervision;

  /// No description provided for @openReview.
  ///
  /// In id, this message translates to:
  /// **'Review mingguan'**
  String get openReview;

  /// No description provided for @projectSettings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan project'**
  String get projectSettings;

  /// No description provided for @newProject.
  ///
  /// In id, this message translates to:
  /// **'Project baru'**
  String get newProject;

  /// No description provided for @switchProject.
  ///
  /// In id, this message translates to:
  /// **'Ganti project'**
  String get switchProject;

  /// No description provided for @deleteProject.
  ///
  /// In id, this message translates to:
  /// **'Hapus project'**
  String get deleteProject;

  /// No description provided for @deleteProjectConfirm.
  ///
  /// In id, this message translates to:
  /// **'Project ini dipindahkan ke tempat sampah dan terhapus permanen setelah 30 hari.'**
  String get deleteProjectConfirm;

  /// No description provided for @pendingTitle.
  ///
  /// In id, this message translates to:
  /// **'Usulan menunggu'**
  String get pendingTitle;

  /// No description provided for @briefTitle.
  ///
  /// In id, this message translates to:
  /// **'Brief project'**
  String get briefTitle;

  /// No description provided for @briefGoal.
  ///
  /// In id, this message translates to:
  /// **'Tujuan'**
  String get briefGoal;

  /// No description provided for @briefDeliverables.
  ///
  /// In id, this message translates to:
  /// **'Hasil akhir'**
  String get briefDeliverables;

  /// No description provided for @briefRequirements.
  ///
  /// In id, this message translates to:
  /// **'Syarat dosen'**
  String get briefRequirements;

  /// No description provided for @briefDates.
  ///
  /// In id, this message translates to:
  /// **'Tanggal penting'**
  String get briefDates;

  /// No description provided for @briefConstraints.
  ///
  /// In id, this message translates to:
  /// **'Batasan'**
  String get briefConstraints;

  /// No description provided for @briefQuestions.
  ///
  /// In id, this message translates to:
  /// **'Pertanyaan terbuka'**
  String get briefQuestions;

  /// No description provided for @briefAnswerHint.
  ///
  /// In id, this message translates to:
  /// **'Jawabanmu'**
  String get briefAnswerHint;

  /// No description provided for @briefItemHint.
  ///
  /// In id, this message translates to:
  /// **'Tulis di sini'**
  String get briefItemHint;

  /// No description provided for @briefDateLabelHint.
  ///
  /// In id, this message translates to:
  /// **'Nama acara'**
  String get briefDateLabelHint;

  /// No description provided for @briefVersion.
  ///
  /// In id, this message translates to:
  /// **'Versi {version}'**
  String briefVersion(String version);

  /// No description provided for @briefSaved.
  ///
  /// In id, this message translates to:
  /// **'Brief disimpan sebagai versi baru.'**
  String get briefSaved;

  /// No description provided for @briefExtracting.
  ///
  /// In id, this message translates to:
  /// **'Menyusun brief dari dokumen… biasanya 30–60 detik.'**
  String get briefExtracting;

  /// No description provided for @briefExtractAgain.
  ///
  /// In id, this message translates to:
  /// **'Susun ulang dari dokumen'**
  String get briefExtractAgain;

  /// No description provided for @briefEmpty.
  ///
  /// In id, this message translates to:
  /// **'Brief belum diisi.'**
  String get briefEmpty;

  /// No description provided for @supervisionTitle.
  ///
  /// In id, this message translates to:
  /// **'Log bimbingan'**
  String get supervisionTitle;

  /// No description provided for @supervisionIntro.
  ///
  /// In id, this message translates to:
  /// **'Catat hasil bimbingan. Revisi dari dosen diubah jadi usulan task; tidak ada yang masuk rencana sebelum kamu setujui.'**
  String get supervisionIntro;

  /// No description provided for @supervisionDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal bimbingan'**
  String get supervisionDate;

  /// No description provided for @supervisionNotes.
  ///
  /// In id, this message translates to:
  /// **'Catatan bimbingan'**
  String get supervisionNotes;

  /// No description provided for @supervisionNotesHint.
  ///
  /// In id, this message translates to:
  /// **'Satu revisi per baris, misalnya: - Tambah 5 referensi terbaru di Bab 2'**
  String get supervisionNotesHint;

  /// No description provided for @supervisionSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan dan buat usulan'**
  String get supervisionSave;

  /// No description provided for @supervisionNoProposal.
  ///
  /// In id, this message translates to:
  /// **'Catatan disimpan. Tidak ada revisi yang terdeteksi.'**
  String get supervisionNoProposal;

  /// No description provided for @supervisionHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat bimbingan'**
  String get supervisionHistory;

  /// No description provided for @supervisionEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada catatan bimbingan.'**
  String get supervisionEmpty;

  /// No description provided for @reviewTitle.
  ///
  /// In id, this message translates to:
  /// **'Review mingguan'**
  String get reviewTitle;

  /// No description provided for @reviewDone.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} task selesai minggu ini}}'**
  String reviewDone(int count);

  /// No description provided for @reviewSlipped.
  ///
  /// In id, this message translates to:
  /// **'Tertinggal'**
  String get reviewSlipped;

  /// No description provided for @reviewNextFocus.
  ///
  /// In id, this message translates to:
  /// **'Fokus minggu depan'**
  String get reviewNextFocus;

  /// No description provided for @reviewRecommendReplan.
  ///
  /// In id, this message translates to:
  /// **'Rencana perlu disesuaikan agar tetap realistis.'**
  String get reviewRecommendReplan;

  /// No description provided for @reviewNothingDone.
  ///
  /// In id, this message translates to:
  /// **'Belum ada task selesai minggu ini. Tidak apa-apa; mulai lagi dari satu langkah kecil.'**
  String get reviewNothingDone;

  /// No description provided for @reviewHealthNow.
  ///
  /// In id, this message translates to:
  /// **'Status sekarang'**
  String get reviewHealthNow;

  /// No description provided for @settingsLanguage.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get settingsLanguage;

  /// No description provided for @languageIndonesian.
  ///
  /// In id, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageIndonesian;

  /// No description provided for @languageEnglish.
  ///
  /// In id, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsTheme.
  ///
  /// In id, this message translates to:
  /// **'Tampilan'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In id, this message translates to:
  /// **'Ikuti sistem'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In id, this message translates to:
  /// **'Terang'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In id, this message translates to:
  /// **'Gelap'**
  String get themeDark;

  /// No description provided for @settingsServer.
  ///
  /// In id, this message translates to:
  /// **'Alamat server'**
  String get settingsServer;

  /// No description provided for @settingsServerHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: http://localhost:8000'**
  String get settingsServerHint;

  /// No description provided for @settingsServerTest.
  ///
  /// In id, this message translates to:
  /// **'Tes koneksi'**
  String get settingsServerTest;

  /// No description provided for @settingsServerOk.
  ///
  /// In id, this message translates to:
  /// **'Terhubung ke server.'**
  String get settingsServerOk;

  /// No description provided for @settingsAi.
  ///
  /// In id, this message translates to:
  /// **'AI'**
  String get settingsAi;

  /// No description provided for @settingsAiActive.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get settingsAiActive;

  /// No description provided for @settingsAiInactive.
  ///
  /// In id, this message translates to:
  /// **'Belum aktif. Server berjalan tanpa API key.'**
  String get settingsAiInactive;

  /// No description provided for @settingsQuota.
  ///
  /// In id, this message translates to:
  /// **'{used} dari {limit} token bulan ini'**
  String settingsQuota(String used, String limit);

  /// No description provided for @settingsQuotaReset.
  ///
  /// In id, this message translates to:
  /// **'Kuota pulih {date}'**
  String settingsQuotaReset(String date);

  /// No description provided for @settingsAccount.
  ///
  /// In id, this message translates to:
  /// **'Akun dan data'**
  String get settingsAccount;

  /// No description provided for @settingsLocalMode.
  ///
  /// In id, this message translates to:
  /// **'Mode lokal: satu pengguna, tanpa login.'**
  String get settingsLocalMode;

  /// No description provided for @settingsExport.
  ///
  /// In id, this message translates to:
  /// **'Ekspor semua data'**
  String get settingsExport;

  /// No description provided for @settingsExported.
  ///
  /// In id, this message translates to:
  /// **'Data diekspor.'**
  String get settingsExported;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In id, this message translates to:
  /// **'Hapus akun'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteConfirm.
  ///
  /// In id, this message translates to:
  /// **'Semua project, dokumen, dan catatan akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.'**
  String get settingsDeleteConfirm;

  /// No description provided for @settingsDeleteButton.
  ///
  /// In id, this message translates to:
  /// **'Hapus permanen'**
  String get settingsDeleteButton;

  /// No description provided for @settingsAbout.
  ///
  /// In id, this message translates to:
  /// **'Tentang'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In id, this message translates to:
  /// **'Versi {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsPrivacy.
  ///
  /// In id, this message translates to:
  /// **'Dokumen dan catatanmu tersimpan di server Purnara. Saat AI aktif, bagian yang relevan dikirim ke penyedia AI (Claude) untuk diproses dan tidak dipakai untuk melatih model.'**
  String get settingsPrivacy;

  /// No description provided for @settingsFontLicense.
  ///
  /// In id, this message translates to:
  /// **'Font Plus Jakarta Sans, lisensi SIL Open Font License 1.1.'**
  String get settingsFontLicense;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In id, this message translates to:
  /// **'Selesaikan project besarmu, satu langkah sehari.'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In id, this message translates to:
  /// **'Purnara menyusun rencana dari dokumenmu, memberi tahu apa yang dikerjakan hari ini, dan menyesuaikan jadwal saat keadaan berubah. Kamu selalu yang memutuskan.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingStart.
  ///
  /// In id, this message translates to:
  /// **'Mulai'**
  String get onboardingStart;

  /// No description provided for @onboardingStep.
  ///
  /// In id, this message translates to:
  /// **'Langkah {current} dari {total}'**
  String onboardingStep(String current, String total);

  /// No description provided for @stepTemplate.
  ///
  /// In id, this message translates to:
  /// **'Pilih jenis project'**
  String get stepTemplate;

  /// No description provided for @stepDetails.
  ///
  /// In id, this message translates to:
  /// **'Judul dan deadline'**
  String get stepDetails;

  /// No description provided for @stepDocuments.
  ///
  /// In id, this message translates to:
  /// **'Unggah dokumen'**
  String get stepDocuments;

  /// No description provided for @stepBrief.
  ///
  /// In id, this message translates to:
  /// **'Periksa brief'**
  String get stepBrief;

  /// No description provided for @stepCapacity.
  ///
  /// In id, this message translates to:
  /// **'Waktu yang tersedia'**
  String get stepCapacity;

  /// No description provided for @stepPreview.
  ///
  /// In id, this message translates to:
  /// **'Pratinjau rencana'**
  String get stepPreview;

  /// No description provided for @templateSummary.
  ///
  /// In id, this message translates to:
  /// **'{tasks} task · sekitar {hours} jam'**
  String templateSummary(String tasks, String hours);

  /// No description provided for @fieldTitle.
  ///
  /// In id, this message translates to:
  /// **'Judul project'**
  String get fieldTitle;

  /// No description provided for @fieldTitleHint.
  ///
  /// In id, this message translates to:
  /// **'Misalnya: Decision-making NPC untuk game RTS'**
  String get fieldTitleHint;

  /// No description provided for @fieldDescription.
  ///
  /// In id, this message translates to:
  /// **'Deskripsi singkat'**
  String get fieldDescription;

  /// No description provided for @fieldTarget.
  ///
  /// In id, this message translates to:
  /// **'Target (opsional)'**
  String get fieldTarget;

  /// No description provided for @fieldTargetHint.
  ///
  /// In id, this message translates to:
  /// **'Misalnya: sidang sebelum Maret'**
  String get fieldTargetHint;

  /// No description provided for @fieldDeadline.
  ///
  /// In id, this message translates to:
  /// **'Deadline (misalnya tanggal sidang)'**
  String get fieldDeadline;

  /// No description provided for @fieldRequired.
  ///
  /// In id, this message translates to:
  /// **'Wajib diisi'**
  String get fieldRequired;

  /// No description provided for @pickDate.
  ///
  /// In id, this message translates to:
  /// **'Pilih tanggal'**
  String get pickDate;

  /// No description provided for @documentsStepHint.
  ///
  /// In id, this message translates to:
  /// **'Unggah proposal dan instruksi dosen. Boleh dilewati dan ditambah nanti.'**
  String get documentsStepHint;

  /// No description provided for @capacityIntro.
  ///
  /// In id, this message translates to:
  /// **'Berapa jam per hari yang realistis untuk project ini?'**
  String get capacityIntro;

  /// No description provided for @capacityWeekly.
  ///
  /// In id, this message translates to:
  /// **'{hours} jam per minggu'**
  String capacityWeekly(String hours);

  /// No description provided for @blockedDates.
  ///
  /// In id, this message translates to:
  /// **'Hari tanpa kerja (UTS, UAS, libur)'**
  String get blockedDates;

  /// No description provided for @addBlockedDate.
  ///
  /// In id, this message translates to:
  /// **'Tambah tanggal'**
  String get addBlockedDate;

  /// No description provided for @bufferLabel.
  ///
  /// In id, this message translates to:
  /// **'Cadangan waktu {pct}%'**
  String bufferLabel(String pct);

  /// No description provided for @previewGenerating.
  ///
  /// In id, this message translates to:
  /// **'Menyusun rencana…'**
  String get previewGenerating;

  /// No description provided for @previewAccept.
  ///
  /// In id, this message translates to:
  /// **'Terima rencana'**
  String get previewAccept;

  /// No description provided for @previewRegenerate.
  ///
  /// In id, this message translates to:
  /// **'Susun ulang'**
  String get previewRegenerate;

  /// No description provided for @previewSummary.
  ///
  /// In id, this message translates to:
  /// **'{tasks} task · {hours} jam total'**
  String previewSummary(String tasks, String hours);

  /// No description provided for @previewReady.
  ///
  /// In id, this message translates to:
  /// **'Rencana siap. Kamu bisa mengubahnya kapan saja.'**
  String get previewReady;

  /// No description provided for @creatingProject.
  ///
  /// In id, this message translates to:
  /// **'Membuat project…'**
  String get creatingProject;

  /// No description provided for @notificationsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada notifikasi.'**
  String get notificationsEmpty;

  /// No description provided for @notifHealthDrop.
  ///
  /// In id, this message translates to:
  /// **'Status project berubah menjadi: {status}.'**
  String notifHealthDrop(String status);

  /// No description provided for @notifDeadline.
  ///
  /// In id, this message translates to:
  /// **'{days, plural, other{Deadline tinggal {days} hari lagi.}}'**
  String notifDeadline(int days);

  /// No description provided for @documentsWaitProcessing.
  ///
  /// In id, this message translates to:
  /// **'Menunggu dokumen selesai diproses…'**
  String get documentsWaitProcessing;

  /// No description provided for @previewReviewDetails.
  ///
  /// In id, this message translates to:
  /// **'Tinjau detail'**
  String get previewReviewDetails;

  /// No description provided for @previewUncovered.
  ///
  /// In id, this message translates to:
  /// **'Syarat yang belum punya task: {codes}'**
  String previewUncovered(String codes);

  /// No description provided for @milestoneSummary.
  ///
  /// In id, this message translates to:
  /// **'{tasks} task · {hours} jam'**
  String milestoneSummary(String tasks, String hours);

  /// No description provided for @optionalTag.
  ///
  /// In id, this message translates to:
  /// **'Opsional'**
  String get optionalTag;

  /// No description provided for @recommendedTag.
  ///
  /// In id, this message translates to:
  /// **'Disarankan'**
  String get recommendedTag;

  /// No description provided for @deferredSection.
  ///
  /// In id, this message translates to:
  /// **'Ditunda, di luar scope'**
  String get deferredSection;

  /// No description provided for @boardMoveTo.
  ///
  /// In id, this message translates to:
  /// **'Pindahkan ke'**
  String get boardMoveTo;

  /// No description provided for @estimateRange.
  ///
  /// In id, this message translates to:
  /// **'Isi 0,5 sampai 40 jam.'**
  String get estimateRange;

  /// No description provided for @opsCount.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} perubahan}}'**
  String opsCount(int count);

  /// No description provided for @hoursDone.
  ///
  /// In id, this message translates to:
  /// **'{done} dari {total} jam selesai'**
  String hoursDone(String done, String total);

  /// No description provided for @chartPlanned.
  ///
  /// In id, this message translates to:
  /// **'Rencana'**
  String get chartPlanned;

  /// No description provided for @chartActual.
  ///
  /// In id, this message translates to:
  /// **'Tercapai'**
  String get chartActual;

  /// No description provided for @briefDraftUnsaved.
  ///
  /// In id, this message translates to:
  /// **'Draf baru dari dokumen. Periksa, lalu simpan.'**
  String get briefDraftUnsaved;

  /// No description provided for @copyText.
  ///
  /// In id, this message translates to:
  /// **'Salin'**
  String get copyText;

  /// No description provided for @copied.
  ///
  /// In id, this message translates to:
  /// **'Disalin.'**
  String get copied;

  /// No description provided for @settingsLicenses.
  ///
  /// In id, this message translates to:
  /// **'Lisensi open source'**
  String get settingsLicenses;

  /// No description provided for @settingsServerInvalid.
  ///
  /// In id, this message translates to:
  /// **'Alamat tidak valid. Contoh: http://localhost:8000'**
  String get settingsServerInvalid;

  /// No description provided for @settingsServerReset.
  ///
  /// In id, this message translates to:
  /// **'Pakai alamat bawaan'**
  String get settingsServerReset;

  /// No description provided for @welcomePreviewProject.
  ///
  /// In id, this message translates to:
  /// **'Skripsi: NPC untuk game RTS'**
  String get welcomePreviewProject;

  /// No description provided for @welcomePreviewMilestone.
  ///
  /// In id, this message translates to:
  /// **'Studi literatur'**
  String get welcomePreviewMilestone;

  /// No description provided for @welcomePreviewTask1.
  ///
  /// In id, this message translates to:
  /// **'Rumuskan masalah penelitian'**
  String get welcomePreviewTask1;

  /// No description provided for @welcomePreviewTask2.
  ///
  /// In id, this message translates to:
  /// **'Baca dan rangkum 10 jurnal utama'**
  String get welcomePreviewTask2;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
