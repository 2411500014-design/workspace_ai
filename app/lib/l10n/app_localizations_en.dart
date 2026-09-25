// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Purnara';

  @override
  String get navToday => 'Today';

  @override
  String get navProject => 'Project';

  @override
  String get navPlan => 'Plan';

  @override
  String get navDocuments => 'Documents';

  @override
  String get navAssistant => 'Assistant';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionClose => 'Close';

  @override
  String get actionNext => 'Next';

  @override
  String get actionBack => 'Back';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionUndo => 'Undo';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get loading => 'Loading…';

  @override
  String get errorGeneric => 'Something went wrong. Please try again shortly.';

  @override
  String errorNetwork(String url) {
    return 'Can\'t reach the Purnara server at $url. Make sure the backend is running.';
  }

  @override
  String get errorNotFound => 'Not found. It may have been deleted.';

  @override
  String get errorValidation => 'Some fields aren\'t valid yet. Please check them.';

  @override
  String get errorDeadlinePast => 'The deadline must be after today.';

  @override
  String get errorDependencyCycle => 'This dependency creates a loop: the tasks would wait on each other.';

  @override
  String get errorPlanExists => 'This project already has a plan. Use \"Adjust plan\" instead.';

  @override
  String get errorNoPlan => 'Create a plan first.';

  @override
  String get errorSuggestionDecided => 'This suggestion has already been decided.';

  @override
  String get errorUnsupportedFile => 'This format isn\'t supported yet. Use PDF, DOCX, TXT or MD.';

  @override
  String get errorFileTooLarge => 'The file is too large (20 MB maximum).';

  @override
  String get errorTooManyPages => 'The document is too long (300 pages maximum).';

  @override
  String get errorDuplicate => 'This document is already in the library.';

  @override
  String get errorUnreadable => 'The file can\'t be read. It may be damaged or password-protected.';

  @override
  String get errorNoText => 'No readable text found. It may be a scan; support for scanned documents comes later.';

  @override
  String get errorInvalidCapacity => 'Enter 0 to 16 hours per day, with at least one day above 0.';

  @override
  String errorQuota(String date) {
    return 'This month\'s AI quota is used up. It resets on $date.';
  }

  @override
  String get errorUnauthenticated => 'Your session has ended. Please sign in again.';

  @override
  String get errorEmptyFile => 'The file is empty.';

  @override
  String get aiNotActive => 'AI isn\'t active on this server. Every feature still works in a basic version without AI.';

  @override
  String get aiLabel => 'AI suggestion';

  @override
  String get templateLabel => 'From template';

  @override
  String get schedulerLabel => 'From the scheduler';

  @override
  String get basicLabel => 'Without AI';

  @override
  String get aiErrorUnavailable => 'AI isn\'t active, so the basic version was used.';

  @override
  String get aiErrorQuota => 'The AI quota is used up, so the basic version was used.';

  @override
  String get aiErrorFailed => 'AI had a problem, so the basic version was used.';

  @override
  String get aiErrorInvalidPlan => 'The AI plan didn\'t pass the checks, so the template was used.';

  @override
  String get healthOnTrack => 'On track';

  @override
  String get healthAtRisk => 'Needs attention';

  @override
  String get healthOffTrack => 'Behind';

  @override
  String get healthNoPlan => 'No plan yet';

  @override
  String get healthReasonInfeasible => 'The available hours aren\'t enough before the deadline.';

  @override
  String healthReasonCriticalLate(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'A critical-path task is $days days late.',
      one: 'A critical-path task is 1 day late.',
    );
    return '$_temp0';
  }

  @override
  String get healthReasonSpiLow => 'Progress is well below the plan.';

  @override
  String get healthReasonSpiModerate => 'Progress is a little below the plan.';

  @override
  String get healthAllGood => 'Progress matches the plan.';

  @override
  String progressPlanned(String pct) {
    return 'Planned $pct%';
  }

  @override
  String progressActual(String pct) {
    return 'Done $pct%';
  }

  @override
  String get feasibilityFeasible => 'The plan fits before the deadline';

  @override
  String get feasibilityTight => 'It fits, but uses the time buffer';

  @override
  String feasibilityInfeasible(String hours) {
    return '$hours hours short before the deadline';
  }

  @override
  String projectedFinish(String date) {
    return 'Projected finish $date';
  }

  @override
  String daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days left', one: '1 day left', zero: 'Deadline is today');
    return '$_temp0';
  }

  @override
  String get deadlinePassed => 'The deadline has passed';

  @override
  String deadlineOn(String date) {
    return 'Deadline $date';
  }

  @override
  String hoursValue(String hours) {
    return '$hours h';
  }

  @override
  String get todayTitle => 'Today\'s focus';

  @override
  String todayMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count more tasks are also scheduled today',
      one: '+1 more task is also scheduled today',
    );
    return '$_temp0';
  }

  @override
  String get todayUpcoming => 'This week';

  @override
  String get todayEmpty => 'Nothing is scheduled for today.';

  @override
  String get todayNoPlan => 'This project doesn\'t have a plan yet.';

  @override
  String get todayMakePlan => 'Build the plan';

  @override
  String get markDone => 'Mark done';

  @override
  String get markedDone => 'Task marked as done.';

  @override
  String get helpMeStart => 'Help me start';

  @override
  String lateBadge(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days late', one: '1 day late');
    return '$_temp0';
  }

  @override
  String get criticalBadge => 'Critical path';

  @override
  String pendingSuggestions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count suggestions are waiting for you',
      one: '1 suggestion is waiting for you',
    );
    return '$_temp0';
  }

  @override
  String get reviewAction => 'Review';

  @override
  String get needsReschedule => 'Some changes aren\'t in the schedule yet.';

  @override
  String get adjustPlan => 'Adjust plan';

  @override
  String capacityToday(String hours) {
    return 'Today\'s capacity $hours';
  }

  @override
  String nextMilestone(String title) {
    return 'Next: $title';
  }

  @override
  String get planTabList => 'List';

  @override
  String get planTabBoard => 'Board';

  @override
  String get planTabTimeline => 'Timeline';

  @override
  String get statusTodo => 'To do';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusDone => 'Done';

  @override
  String get taskAdd => 'Add task';

  @override
  String get taskTitle => 'Task title';

  @override
  String get taskEstimate => 'Estimate (hours)';

  @override
  String get taskActual => 'Actual hours';

  @override
  String get taskMilestone => 'Milestone';

  @override
  String get taskNoMilestone => 'No milestone';

  @override
  String get taskOptional => 'Optional (can be dropped when time is short)';

  @override
  String get taskDeferred => 'Deferred, out of scope';

  @override
  String get taskImportance => 'Importance';

  @override
  String get importanceNormal => 'Normal';

  @override
  String get importanceHigh => 'Important';

  @override
  String get importanceTop => 'Very important';

  @override
  String taskScheduled(String start, String end) {
    return '$start – $end';
  }

  @override
  String get taskUnscheduled => 'Not scheduled yet';

  @override
  String taskLatestFinish(String date) {
    return 'Must finish by $date';
  }

  @override
  String get taskDependsOn => 'Waits for';

  @override
  String get taskRequirements => 'Covers requirements';

  @override
  String get taskDefinitionOfDone => 'Definition of done';

  @override
  String get taskNotes => 'Notes';

  @override
  String get taskSchedule => 'Schedule';

  @override
  String get taskBreakDown => 'Break this task down';

  @override
  String get taskExplain => 'Explain from references';

  @override
  String get taskPostpone => 'Postpone';

  @override
  String get taskPostponed => 'Task postponed. The schedule changes when you accept an adjustment.';

  @override
  String taskPostponedTwice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This task has been postponed $count times. Try breaking it into small 25-minute steps.',
    );
    return '$_temp0';
  }

  @override
  String get taskDeleteConfirm => 'Delete this task and its subtasks?';

  @override
  String get taskSaved => 'Saved.';

  @override
  String get firstStepTitle => 'First step, about 25 minutes';

  @override
  String get planEmpty => 'The plan has no tasks yet.';

  @override
  String get subtasksTitle => 'Subtasks';

  @override
  String explainPrompt(String title) {
    return 'Explain how to do \"$title\" based on the references in this project.';
  }

  @override
  String get timelineToday => 'Today';

  @override
  String get timelineDeadline => 'Deadline';

  @override
  String get suggestionKindPlan => 'New plan';

  @override
  String get suggestionKindReplan => 'Plan adjustment';

  @override
  String get suggestionKindTaskChange => 'Task changes';

  @override
  String get suggestionKindBriefUpdate => 'Brief update';

  @override
  String get suggestionAcceptAll => 'Accept all';

  @override
  String suggestionAcceptSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Accept $count selected', one: 'Accept 1 selected');
    return '$_temp0';
  }

  @override
  String get suggestionReject => 'Reject';

  @override
  String get suggestionApplied => 'Suggestion applied. The schedule is updated.';

  @override
  String get suggestionRejected => 'Suggestion rejected. The plan is unchanged.';

  @override
  String get suggestionNothingChanges => 'Nothing changes until you accept it.';

  @override
  String get suggestionPick => 'Choose the changes to accept';

  @override
  String opAddTask(String title) {
    return 'Add task: $title';
  }

  @override
  String opAddSubtask(String title) {
    return 'Add subtask: $title';
  }

  @override
  String opAddMilestone(String title) {
    return 'Add milestone: $title';
  }

  @override
  String opDeferTask(String title) {
    return 'Defer, out of scope: $title';
  }

  @override
  String opUpdateTask(String title) {
    return 'Change task: $title';
  }

  @override
  String opDeleteTask(String title) {
    return 'Delete task: $title';
  }

  @override
  String opAddRequirement(String text) {
    return 'Add requirement: $text';
  }

  @override
  String opAddMemory(String text) {
    return 'Remember for this project: $text';
  }

  @override
  String get opReschedule => 'Reschedule from today';

  @override
  String opExtraHours(String hours, String date) {
    return 'Add $hours working hours in total until $date';
  }

  @override
  String opDeadline(String date) {
    return 'Move the target to $date';
  }

  @override
  String changedTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks change dates',
      one: '1 task changes dates',
      zero: 'No task changes dates',
    );
    return '$_temp0';
  }

  @override
  String get planQuestions => 'Questions for you to answer';

  @override
  String get planAssumptions => 'Assumptions';

  @override
  String get hoursUnit => 'hours';

  @override
  String get replanTitle => 'Adjust the plan';

  @override
  String get replanIntro => 'The scheduler has worked out a few options. Pick the one that fits; nothing changes until you accept it.';

  @override
  String get replanComputing => 'Working out the options…';

  @override
  String get optionReschedule => 'Reschedule from today';

  @override
  String get optionRescheduleDesc => 'Unfinished tasks are rescheduled from today, the most urgent first.';

  @override
  String get optionAddCapacity => 'Add working hours';

  @override
  String optionAddCapacityDesc(String hours, String weeks) {
    return 'Add $hours hours a week for $weeks weeks.';
  }

  @override
  String get optionReduceScope => 'Reduce the scope';

  @override
  String optionReduceScopeDesc(String tasks) {
    return 'Defer optional tasks: $tasks.';
  }

  @override
  String get optionExtendDeadline => 'Move the target';

  @override
  String optionExtendDeadlineDesc(String date, String days) {
    return 'New target $date, $days days later. Only if your campus rules allow it.';
  }

  @override
  String get chooseOption => 'Choose this option';

  @override
  String get documentsTitle => 'Document library';

  @override
  String get documentsUpload => 'Upload documents';

  @override
  String get documentsEmpty =>
      'No documents yet. Upload your proposal, your supervisor\'s instructions or papers. They are used for the brief, the plan and answers with sources.';

  @override
  String get documentsHint => 'PDF, DOCX, TXT or MD · up to 20 MB';

  @override
  String get docStatusProcessing => 'Processing…';

  @override
  String get docStatusReady => 'Ready';

  @override
  String get docStatusFailed => 'Processing failed';

  @override
  String docPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count pages', one: '1 page');
    return '$_temp0';
  }

  @override
  String get docKindProposal => 'Proposal';

  @override
  String get docKindInstruction => 'Instructions or guidelines';

  @override
  String get docKindJournal => 'Paper or reference';

  @override
  String get docKindSupervision => 'Supervision notes';

  @override
  String get docKindDraft => 'Manuscript draft';

  @override
  String get docKindOther => 'Other';

  @override
  String get docSummaryBasic => 'Automatic summary without AI';

  @override
  String docDeleteConfirm(String title) {
    return 'Delete \"$title\"? Its indexed passages are deleted too.';
  }

  @override
  String docUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents uploaded and being processed.',
      one: '1 document uploaded and being processed.',
    );
    return '$_temp0';
  }

  @override
  String get assistantTitle => 'Project assistant';

  @override
  String get assistantHint => 'Ask about your project or documents…';

  @override
  String get assistantEmpty => 'Ask anything about this project. Answers cite your documents and their pages.';

  @override
  String get assistantSuggestion1 => 'What did my supervisor require?';

  @override
  String get assistantSuggestion2 => 'Which method appears most often in my papers?';

  @override
  String get assistantSuggestion3 => 'What should I work on this week?';

  @override
  String get assistantThinking => 'Searching your documents…';

  @override
  String get assistantSend => 'Send';

  @override
  String get answerExtractiveHeader => 'AI isn\'t active. These are the most relevant passages:';

  @override
  String get answerNotFound => 'This isn\'t in your project documents.';

  @override
  String get answerGeneral => 'Answer from general knowledge, not from your project documents.';

  @override
  String citationPages(String start, String end) {
    return 'pp. $start–$end';
  }

  @override
  String citationPage(String page) {
    return 'p. $page';
  }

  @override
  String get newConversation => 'New conversation';

  @override
  String get conversations => 'Conversations';

  @override
  String get feedbackUp => 'Helpful answer';

  @override
  String get feedbackDown => 'Not helpful';

  @override
  String get projectOverview => 'Project overview';

  @override
  String get milestonesTitle => 'Milestones';

  @override
  String milestoneProgress(String done, String total) {
    return '$done of $total tasks';
  }

  @override
  String get requirementsTitle => 'Requirements';

  @override
  String get requirementUncovered => 'No task covers this yet';

  @override
  String get requirementMet => 'Met';

  @override
  String get requirementCovered => 'In progress';

  @override
  String get requirementsEmpty => 'The brief has no requirements yet.';

  @override
  String get openBrief => 'Project brief';

  @override
  String get openSupervision => 'Supervision log';

  @override
  String get openReview => 'Weekly review';

  @override
  String get projectSettings => 'Project settings';

  @override
  String get newProject => 'New project';

  @override
  String get switchProject => 'Switch project';

  @override
  String get deleteProject => 'Delete project';

  @override
  String get deleteProjectConfirm => 'This project moves to the trash and is permanently deleted after 30 days.';

  @override
  String get pendingTitle => 'Waiting suggestions';

  @override
  String get briefTitle => 'Project brief';

  @override
  String get briefGoal => 'Goal';

  @override
  String get briefDeliverables => 'Deliverables';

  @override
  String get briefRequirements => 'Requirements';

  @override
  String get briefDates => 'Important dates';

  @override
  String get briefConstraints => 'Constraints';

  @override
  String get briefQuestions => 'Open questions';

  @override
  String get briefAnswerHint => 'Your answer';

  @override
  String get briefItemHint => 'Write here';

  @override
  String get briefDateLabelHint => 'Event name';

  @override
  String briefVersion(String version) {
    return 'Version $version';
  }

  @override
  String get briefSaved => 'Brief saved as a new version.';

  @override
  String get briefExtracting => 'Drafting the brief from your documents… usually 30–60 seconds.';

  @override
  String get briefExtractAgain => 'Redraft from documents';

  @override
  String get briefEmpty => 'The brief is empty.';

  @override
  String get supervisionTitle => 'Supervision log';

  @override
  String get supervisionIntro =>
      'Record what your supervisor said. Revisions become suggested tasks; nothing enters the plan until you approve it.';

  @override
  String get supervisionDate => 'Meeting date';

  @override
  String get supervisionNotes => 'Meeting notes';

  @override
  String get supervisionNotesHint => 'One revision per line, e.g.: - Add 5 recent references to chapter 2';

  @override
  String get supervisionSave => 'Save and suggest tasks';

  @override
  String get supervisionNoProposal => 'Notes saved. No revisions were detected.';

  @override
  String get supervisionHistory => 'Past meetings';

  @override
  String get supervisionEmpty => 'No meetings logged yet.';

  @override
  String get reviewTitle => 'Weekly review';

  @override
  String reviewDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks finished this week',
      one: '1 task finished this week',
    );
    return '$_temp0';
  }

  @override
  String get reviewSlipped => 'Slipped';

  @override
  String get reviewNextFocus => 'Focus for next week';

  @override
  String get reviewRecommendReplan => 'The plan needs adjusting to stay realistic.';

  @override
  String get reviewNothingDone => 'No tasks finished this week. That\'s okay; start again with one small step.';

  @override
  String get reviewHealthNow => 'Current status';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get themeSystem => 'Follow system';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsServer => 'Server address';

  @override
  String get settingsServerHint => 'e.g. http://localhost:8000';

  @override
  String get settingsServerTest => 'Test connection';

  @override
  String get settingsServerOk => 'Connected to the server.';

  @override
  String get settingsAi => 'AI';

  @override
  String get settingsAiActive => 'Active';

  @override
  String get settingsAiInactive => 'Not active. The server runs without an API key.';

  @override
  String settingsQuota(String used, String limit) {
    return '$used of $limit tokens this month';
  }

  @override
  String settingsQuotaReset(String date) {
    return 'Quota resets $date';
  }

  @override
  String get settingsAccount => 'Account and data';

  @override
  String get settingsLocalMode => 'Local mode: a single user, no sign-in.';

  @override
  String get settingsExport => 'Export all data';

  @override
  String get settingsExported => 'Data exported.';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteConfirm => 'Every project, document and note will be permanently deleted. This can\'t be undone.';

  @override
  String get settingsDeleteButton => 'Delete permanently';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsPrivacy =>
      'Your documents and notes are stored on the Purnara server. When AI is active, the relevant parts are sent to the AI provider (Claude) for processing and are not used to train models.';

  @override
  String get settingsFontLicense => 'Plus Jakarta Sans font, SIL Open Font License 1.1.';

  @override
  String get onboardingWelcomeTitle => 'Finish your big project, one step a day.';

  @override
  String get onboardingWelcomeBody =>
      'Purnara builds a plan from your documents, tells you what to work on today, and adjusts the schedule when things change. You always decide.';

  @override
  String get onboardingStart => 'Get started';

  @override
  String onboardingStep(String current, String total) {
    return 'Step $current of $total';
  }

  @override
  String get stepTemplate => 'Choose a project type';

  @override
  String get stepDetails => 'Title and deadline';

  @override
  String get stepDocuments => 'Upload documents';

  @override
  String get stepBrief => 'Review the brief';

  @override
  String get stepCapacity => 'Your available time';

  @override
  String get stepPreview => 'Plan preview';

  @override
  String templateSummary(String tasks, String hours) {
    return '$tasks tasks · about $hours hours';
  }

  @override
  String get fieldTitle => 'Project title';

  @override
  String get fieldTitleHint => 'e.g. Decision-making for NPCs in an RTS game';

  @override
  String get fieldDescription => 'Short description';

  @override
  String get fieldTarget => 'Target (optional)';

  @override
  String get fieldTargetHint => 'e.g. defend before March';

  @override
  String get fieldDeadline => 'Deadline (e.g. the defense date)';

  @override
  String get fieldRequired => 'Required';

  @override
  String get pickDate => 'Pick a date';

  @override
  String get documentsStepHint => 'Upload your proposal and your supervisor\'s instructions. You can skip this and add them later.';

  @override
  String get capacityIntro => 'How many hours a day can you realistically give this project?';

  @override
  String capacityWeekly(String hours) {
    return '$hours hours a week';
  }

  @override
  String get blockedDates => 'Days off (exams, holidays)';

  @override
  String get addBlockedDate => 'Add a date';

  @override
  String bufferLabel(String pct) {
    return 'Time buffer $pct%';
  }

  @override
  String get previewGenerating => 'Building the plan…';

  @override
  String get previewAccept => 'Accept the plan';

  @override
  String get previewRegenerate => 'Rebuild';

  @override
  String previewSummary(String tasks, String hours) {
    return '$tasks tasks · $hours hours in total';
  }

  @override
  String get previewReady => 'Your plan is ready. You can change it any time.';

  @override
  String get creatingProject => 'Creating the project…';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String notifHealthDrop(String status) {
    return 'The project status changed to: $status.';
  }

  @override
  String notifDeadline(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'The deadline is $days days away.',
      one: 'The deadline is tomorrow.',
    );
    return '$_temp0';
  }

  @override
  String get documentsWaitProcessing => 'Waiting for documents to finish…';

  @override
  String get previewReviewDetails => 'Review details';

  @override
  String previewUncovered(String codes) {
    return 'Requirements with no task yet: $codes';
  }

  @override
  String milestoneSummary(String tasks, String hours) {
    return '$tasks tasks · $hours h';
  }

  @override
  String get optionalTag => 'Optional';

  @override
  String get recommendedTag => 'Recommended';

  @override
  String get deferredSection => 'Deferred, out of scope';

  @override
  String get boardMoveTo => 'Move to';

  @override
  String get estimateRange => 'Enter 0.5 to 40 hours.';

  @override
  String opsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count changes', one: '1 change');
    return '$_temp0';
  }

  @override
  String hoursDone(String done, String total) {
    return '$done of $total hours done';
  }

  @override
  String get chartPlanned => 'Planned';

  @override
  String get chartActual => 'Actual';

  @override
  String get briefDraftUnsaved => 'New draft from your documents. Check it, then save.';

  @override
  String get copyText => 'Copy';

  @override
  String get copied => 'Copied.';

  @override
  String get settingsLicenses => 'Open source licences';

  @override
  String get settingsServerInvalid => 'Not a valid address. Example: http://localhost:8000';

  @override
  String get settingsServerReset => 'Use the default address';

  @override
  String get welcomePreviewProject => 'Thesis: NPCs for an RTS game';

  @override
  String get welcomePreviewMilestone => 'Literature review';

  @override
  String get welcomePreviewTask1 => 'Define the research problem';

  @override
  String get welcomePreviewTask2 => 'Read and summarise 10 key papers';

  @override
  String get breakingDown => 'Breaking the task into small steps…';

  @override
  String get discardChangesMessage => 'Your changes are not saved. Leave this page?';

  @override
  String get discardChangesAction => 'Leave';

  @override
  String get sampleProjectTry => 'Try a sample project';

  @override
  String get sampleProjectHint =>
      'The sample has documents, a brief, a plan and one proposal to try. Delete it any time from Project settings.';

  @override
  String get sampleProjectCreating => 'Setting up the sample project…';

  @override
  String get sampleProjectReady => 'The sample project is ready. Have a look around.';

  @override
  String get settingsPhoneTitle => 'Open on your phone';

  @override
  String get settingsPhoneNoNetwork => 'This computer is not on a Wi-Fi network. Connect it and your phone to the same Wi-Fi.';

  @override
  String get settingsPhoneStartServer =>
      'The server only answers this computer. In VS Code, run \"Backend: API for phones on the same Wi-Fi\", then refresh this card.';

  @override
  String get settingsPhoneOpen => 'Connect your phone to the same Wi-Fi, then open this address in its browser:';

  @override
  String get settingsPhoneBuildFirst =>
      'Build the web app first (Terminal → Run Task → App: build web), then open this address in your phone\'s browser on the same Wi-Fi:';

  @override
  String get answerClosestHeader =>
      'AI isn\'t active and no passage matches exactly. These come closest; check whether they answer your question:';

  @override
  String get answerNotFoundNoAi =>
      'Without AI, the assistant looks for the same words in your documents. Try terms your documents use, such as \"references\" or a method\'s name.';
}
