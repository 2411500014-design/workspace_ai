/// Plain data classes for the Purnara API (snake_case JSON, ISO dates).
library;

typedef Json = Map<String, dynamic>;

DateTime? _date(Object? value) => value is String && value.isNotEmpty ? DateTime.parse(value) : null;
double _double(Object? value) => value is num ? value.toDouble() : 0;
double? _doubleOrNull(Object? value) => value is num ? value.toDouble() : null;
List<Json> _list(Object? value) => value is List ? value.whereType<Map>().map((e) => Json.from(e)).toList() : <Json>[];
List<String> _strings(Object? value) => value is List ? value.map((e) => e.toString()).toList() : <String>[];

/// A text stored in both languages, e.g. template names from the mode preset.
class LocalizedText {
  const LocalizedText(this.values);

  factory LocalizedText.fromJson(Object? json) =>
      LocalizedText(json is Map ? json.map((k, v) => MapEntry(k.toString(), v.toString())) : {'id': json?.toString() ?? ''});

  final Map<String, String> values;

  String of(String locale) => values[locale] ?? values['id'] ?? (values.isEmpty ? '' : values.values.first);
}

class QuotaInfo {
  const QuotaInfo({required this.used, required this.limit, required this.resetsAt});

  factory QuotaInfo.fromJson(Json j) =>
      QuotaInfo(used: (j['used'] as num?)?.toInt() ?? 0, limit: (j['limit'] as num?)?.toInt() ?? 0, resetsAt: _date(j['resets_at']));

  final int used;
  final int limit;
  final DateTime? resetsAt;
}

class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.email,
    required this.locale,
    required this.timezone,
    required this.aiEnabled,
    required this.quota,
    required this.authMode,
  });

  factory Profile.fromJson(Json j) => Profile(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    email: j['email'] as String?,
    locale: j['locale'] as String? ?? 'id',
    timezone: j['timezone'] as String? ?? 'Asia/Jakarta',
    aiEnabled: j['ai_enabled'] as bool? ?? false,
    quota: QuotaInfo.fromJson(Json.from(j['quota'] as Map? ?? {})),
    authMode: j['auth_mode'] as String? ?? 'local',
  );

  final String id;
  final String name;
  final String? email;
  final String locale;
  final String timezone;
  final bool aiEnabled;
  final QuotaInfo quota;
  final String authMode;
}

class TemplateInfo {
  const TemplateInfo({required this.id, required this.name, required this.description, required this.taskCount, required this.totalHours});

  factory TemplateInfo.fromJson(Json j) => TemplateInfo(
    id: j['id'] as String,
    name: LocalizedText.fromJson(j['name']),
    description: LocalizedText.fromJson(j['description']),
    taskCount: (j['task_count'] as num?)?.toInt() ?? 0,
    totalHours: _double(j['total_hours']),
  );

  final String id;
  final LocalizedText name;
  final LocalizedText description;
  final int taskCount;
  final double totalHours;
}

class ModeInfo {
  const ModeInfo({required this.id, required this.name, required this.templates});

  factory ModeInfo.fromJson(Json j) => ModeInfo(
    id: j['id'] as String,
    name: LocalizedText.fromJson(j['name']),
    templates: _list(j['templates']).map(TemplateInfo.fromJson).toList(),
  );

  final String id;
  final LocalizedText name;
  final List<TemplateInfo> templates;
}

class Project {
  const Project({
    required this.id,
    required this.mode,
    required this.template,
    required this.title,
    required this.description,
    required this.target,
    required this.deadline,
    required this.hoursByWeekday,
    required this.blockedDates,
    required this.bufferPct,
    required this.health,
    required this.feasibility,
    required this.hasPlan,
    required this.needsReschedule,
    required this.taskCount,
  });

  factory Project.fromJson(Json j) => Project(
    id: j['id'] as String,
    mode: j['mode'] as String? ?? 'academic',
    template: j['template'] as String? ?? '',
    title: j['title'] as String? ?? '',
    description: j['description'] as String? ?? '',
    target: j['target'] as String? ?? '',
    deadline: _date(j['deadline'])!,
    hoursByWeekday: (j['hours_by_weekday'] as List? ?? const []).map(_double).toList(),
    blockedDates: _strings(j['blocked_dates']).map(DateTime.parse).toList(),
    bufferPct: _double(j['buffer_pct']),
    health: j['health'] as String?,
    feasibility: j['feasibility'] as String?,
    hasPlan: j['has_plan'] as bool? ?? false,
    needsReschedule: j['needs_reschedule'] as bool? ?? false,
    taskCount: (j['task_count'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String mode;
  final String template;
  final String title;
  final String description;
  final String target;
  final DateTime deadline;
  final List<double> hoursByWeekday;
  final List<DateTime> blockedDates;
  final double bufferPct;
  final String? health;
  final String? feasibility;
  final bool hasPlan;
  final bool needsReschedule;
  final int taskCount;

  double get weeklyHours => hoursByWeekday.fold(0, (a, b) => a + b);
}

class Milestone {
  const Milestone({required this.id, required this.key, required this.title, required this.position});

  factory Milestone.fromJson(Json j) => Milestone(
    id: j['id'] as String,
    key: j['key'] as String? ?? '',
    title: j['title'] as String? ?? '',
    position: (j['position'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String key;
  final String title;
  final int position;
}

class Task {
  const Task({
    required this.id,
    required this.projectId,
    required this.key,
    required this.milestoneId,
    required this.parentTaskId,
    required this.title,
    required this.description,
    required this.definitionOfDone,
    required this.status,
    required this.estimateHours,
    required this.actualHours,
    required this.priorityScore,
    required this.isCritical,
    required this.optional,
    required this.deferred,
    required this.importance,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.latestFinish,
    required this.postponeCount,
    required this.source,
    required this.dependsOn,
    required this.requirementIds,
    required this.lateDays,
  });

  factory Task.fromJson(Json j) => Task(
    id: j['id'] as String,
    projectId: j['project_id'] as String? ?? '',
    key: j['key'] as String? ?? '',
    milestoneId: j['milestone_id'] as String?,
    parentTaskId: j['parent_task_id'] as String?,
    title: j['title'] as String? ?? '',
    description: j['description'] as String? ?? '',
    definitionOfDone: j['definition_of_done'] as String? ?? '',
    status: j['status'] as String? ?? 'todo',
    estimateHours: _double(j['estimate_hours']),
    actualHours: _doubleOrNull(j['actual_hours']),
    priorityScore: _double(j['priority_score']),
    isCritical: j['is_critical'] as bool? ?? false,
    optional: j['optional'] as bool? ?? false,
    deferred: j['deferred'] as bool? ?? false,
    importance: _double(j['importance']),
    scheduledStart: _date(j['scheduled_start']),
    scheduledEnd: _date(j['scheduled_end']),
    latestFinish: _date(j['latest_finish']),
    postponeCount: (j['postpone_count'] as num?)?.toInt() ?? 0,
    source: j['source'] as String? ?? 'user',
    dependsOn: _strings(j['depends_on']),
    requirementIds: _strings(j['requirement_ids']),
    lateDays: (j['late_days'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String projectId;
  final String key;
  final String? milestoneId;
  final String? parentTaskId;
  final String title;
  final String description;
  final String definitionOfDone;
  final String status;
  final double estimateHours;
  final double? actualHours;
  final double priorityScore;
  final bool isCritical;
  final bool optional;
  final bool deferred;
  final double importance;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final DateTime? latestFinish;
  final int postponeCount;
  final String source;
  final List<String> dependsOn;
  final List<String> requirementIds;
  final int lateDays;

  bool get isDone => status == 'done';
}

class PlanData {
  const PlanData({required this.project, required this.milestones, required this.tasks});

  factory PlanData.fromJson(Json j) => PlanData(
    project: Project.fromJson(Json.from(j['project'] as Map)),
    milestones: _list(j['milestones']).map(Milestone.fromJson).toList(),
    tasks: _list(j['tasks']).map(Task.fromJson).toList(),
  );

  final Project project;
  final List<Milestone> milestones;
  final List<Task> tasks;

  Set<String> get parentIds => {
    for (final t in tasks)
      if (t.parentTaskId != null) t.parentTaskId!,
  };

  /// Tasks that carry the actual work (parents only group their subtasks).
  List<Task> get leafTasks {
    final parents = parentIds;
    return tasks.where((t) => !parents.contains(t.id)).toList();
  }

  Task? taskById(String id) {
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }
}

class HealthPoint {
  const HealthPoint({required this.day, required this.plannedPct, required this.actualPct, required this.health});

  factory HealthPoint.fromJson(Json j) => HealthPoint(
    day: _date(j['day'])!,
    plannedPct: _double(j['planned_pct']),
    actualPct: _double(j['actual_pct']),
    health: j['health'] as String? ?? 'on_track',
  );

  final DateTime day;
  final double plannedPct;
  final double actualPct;
  final String health;
}

class Health {
  const Health({
    required this.hasPlan,
    required this.status,
    required this.spi,
    required this.spiStable,
    required this.plannedPct,
    required this.actualPct,
    required this.criticalLateDays,
    required this.reasons,
    required this.feasibility,
    required this.needsReschedule,
    required this.doneHours,
    required this.totalHours,
    required this.lateTasks,
    required this.history,
  });

  factory Health.fromJson(Json j) => Health(
    hasPlan: j['has_plan'] as bool? ?? false,
    status: j['status'] as String?,
    spi: _doubleOrNull(j['spi']),
    spiStable: j['spi_stable'] as bool? ?? false,
    plannedPct: _double(j['planned_pct']),
    actualPct: _double(j['actual_pct']),
    criticalLateDays: (j['critical_late_days'] as num?)?.toInt() ?? 0,
    reasons: _strings(j['reasons']),
    feasibility: j['feasibility'] as String?,
    needsReschedule: j['needs_reschedule'] as bool? ?? false,
    doneHours: _double(j['done_hours']),
    totalHours: _double(j['total_hours']),
    lateTasks: (j['late_tasks'] as num?)?.toInt() ?? 0,
    history: _list(j['history']).map(HealthPoint.fromJson).toList(),
  );

  final bool hasPlan;
  final String? status;
  final double? spi;
  final bool spiStable;
  final double plannedPct;
  final double actualPct;
  final int criticalLateDays;
  final List<String> reasons;
  final String? feasibility;
  final bool needsReschedule;
  final double doneHours;
  final double totalHours;
  final int lateTasks;
  final List<HealthPoint> history;
}

class TaskBrief {
  const TaskBrief({
    required this.id,
    required this.key,
    required this.title,
    required this.status,
    required this.projectId,
    required this.projectTitle,
    required this.milestoneTitle,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.estimateHours,
    required this.isCritical,
    required this.lateDays,
    required this.postponeCount,
  });

  factory TaskBrief.fromJson(Json j) => TaskBrief(
    id: j['id'] as String,
    key: j['key'] as String? ?? '',
    title: j['title'] as String? ?? '',
    status: j['status'] as String? ?? 'todo',
    projectId: j['project_id'] as String,
    projectTitle: j['project_title'] as String? ?? '',
    milestoneTitle: j['milestone_title'] as String? ?? '',
    scheduledStart: _date(j['scheduled_start']),
    scheduledEnd: _date(j['scheduled_end']),
    estimateHours: _double(j['estimate_hours']),
    isCritical: j['is_critical'] as bool? ?? false,
    lateDays: (j['late_days'] as num?)?.toInt() ?? 0,
    postponeCount: (j['postpone_count'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String key;
  final String title;
  final String status;
  final String projectId;
  final String projectTitle;
  final String milestoneTitle;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final double estimateHours;
  final bool isCritical;
  final int lateDays;
  final int postponeCount;
}

class ProjectSummary {
  const ProjectSummary({
    required this.id,
    required this.title,
    required this.health,
    required this.feasibility,
    required this.deadline,
    required this.daysLeft,
    required this.hasPlan,
    required this.needsReschedule,
    required this.pendingSuggestions,
    required this.nextMilestoneTitle,
    required this.hoursToday,
  });

  factory ProjectSummary.fromJson(Json j) => ProjectSummary(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    health: j['health'] as String?,
    feasibility: j['feasibility'] as String?,
    deadline: _date(j['deadline'])!,
    daysLeft: (j['days_left'] as num?)?.toInt() ?? 0,
    hasPlan: j['has_plan'] as bool? ?? false,
    needsReschedule: j['needs_reschedule'] as bool? ?? false,
    pendingSuggestions: (j['pending_suggestions'] as num?)?.toInt() ?? 0,
    nextMilestoneTitle: (j['next_milestone'] as Map?)?['title'] as String?,
    hoursToday: _double(j['hours_today']),
  );

  final String id;
  final String title;
  final String? health;
  final String? feasibility;
  final DateTime deadline;
  final int daysLeft;
  final bool hasPlan;
  final bool needsReschedule;
  final int pendingSuggestions;
  final String? nextMilestoneTitle;
  final double hoursToday;
}

class TodayView {
  const TodayView({required this.date, required this.focus, required this.moreToday, required this.upcoming, required this.projects});

  factory TodayView.fromJson(Json j) => TodayView(
    date: _date(j['date'])!,
    focus: _list(j['focus']).map(TaskBrief.fromJson).toList(),
    moreToday: _list(j['more_today']).map(TaskBrief.fromJson).toList(),
    upcoming: _list(j['upcoming']).map(TaskBrief.fromJson).toList(),
    projects: _list(j['projects']).map(ProjectSummary.fromJson).toList(),
  );

  final DateTime date;
  final List<TaskBrief> focus;
  final List<TaskBrief> moreToday;
  final List<TaskBrief> upcoming;
  final List<ProjectSummary> projects;
}

class SuggestionOp {
  const SuggestionOp(this.raw);

  final Json raw;

  String get op => raw['op'] as String? ?? '';
  String get entity => raw['entity'] as String? ?? '';
  String? get id => raw['id'] as String?;
  String? get key => raw['key'] as String?;
  Json get fields => Json.from(raw['fields'] as Map? ?? {});
  String? get label => raw['label'] as String?;
}

class Suggestion {
  const Suggestion({
    required this.id,
    required this.projectId,
    required this.kind,
    required this.status,
    required this.aiUsed,
    required this.rationale,
    required this.ops,
    required this.preview,
    required this.meta,
  });

  factory Suggestion.fromJson(Json j) => Suggestion(
    id: j['id'] as String,
    projectId: j['project_id'] as String,
    kind: j['kind'] as String? ?? '',
    status: j['status'] as String? ?? 'pending',
    aiUsed: j['ai_used'] as bool? ?? false,
    rationale: j['rationale'] as String? ?? '',
    ops: _list(j['ops']).map(SuggestionOp.new).toList(),
    preview: Json.from(j['preview'] as Map? ?? {}),
    meta: Json.from(j['meta'] as Map? ?? {}),
  );

  final String id;
  final String projectId;
  final String kind;
  final String status;
  final bool aiUsed;
  final String rationale;
  final List<SuggestionOp> ops;
  final Json preview;
  final Json meta;

  bool get isPending => status == 'pending';
  String? get aiError => meta['ai_error'] as String?;
  String? get option => meta['option'] as String?;
  Json get params => Json.from(meta['params'] as Map? ?? {});
  String? get feasibility => preview['feasibility'] as String?;
  DateTime? get projectedFinish => _date(preview['projected_finish']);
  double get totalHours => _double(preview['total_hours']);
  double get shortfallHours => _double(preview['shortfall_hours']);
  int get changedCount => (preview['changed_count'] as num?)?.toInt() ?? 0;
  List<Json> get changes => _list(preview['changes']);
  List<String> get questions => _strings(meta['questions']);
  List<String> get assumptions => _strings(meta['assumptions']);
}

class DocumentItem {
  const DocumentItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.filename,
    required this.pages,
    required this.status,
    required this.errorCode,
    required this.summary,
    required this.summaryAi,
    required this.metadata,
    required this.sizeBytes,
  });

  factory DocumentItem.fromJson(Json j) => DocumentItem(
    id: j['id'] as String,
    kind: j['kind'] as String? ?? 'other',
    title: j['title'] as String? ?? '',
    filename: j['filename'] as String? ?? '',
    pages: (j['pages'] as num?)?.toInt(),
    status: j['status'] as String? ?? 'processing',
    errorCode: j['error_code'] as String?,
    summary: j['summary'] as String? ?? '',
    summaryAi: j['summary_ai'] as bool? ?? false,
    metadata: Json.from(j['metadata'] as Map? ?? {}),
    sizeBytes: (j['size_bytes'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String kind;
  final String title;
  final String filename;
  final int? pages;
  final String status;
  final String? errorCode;
  final String summary;
  final bool summaryAi;
  final Json metadata;
  final int sizeBytes;
}

class Requirement {
  const Requirement({this.code, required this.text});

  factory Requirement.fromJson(Json j) => Requirement(code: j['code'] as String?, text: j['text'] as String? ?? '');

  final String? code;
  final String text;

  Json toJson() => {if (code != null) 'code': code, 'text': text};
}

class ImportantDate {
  const ImportantDate({required this.label, this.date});

  factory ImportantDate.fromJson(Json j) => ImportantDate(label: j['label'] as String? ?? '', date: j['date'] as String?);

  final String label;
  final String? date;

  Json toJson() => {'label': label, 'date': date};
}

class OpenQuestion {
  const OpenQuestion({required this.question, this.answer = ''});

  factory OpenQuestion.fromJson(Json j) => OpenQuestion(question: j['question'] as String? ?? '', answer: j['answer'] as String? ?? '');

  final String question;
  final String answer;

  Json toJson() => {'question': question, 'answer': answer};
}

class BriefContent {
  const BriefContent({
    this.goal = '',
    this.deliverables = const [],
    this.requirements = const [],
    this.importantDates = const [],
    this.constraints = const [],
    this.openQuestions = const [],
  });

  factory BriefContent.fromJson(Json j) => BriefContent(
    goal: j['goal'] as String? ?? '',
    deliverables: _strings(j['deliverables']),
    requirements: _list(j['requirements']).map(Requirement.fromJson).toList(),
    importantDates: _list(j['important_dates']).map(ImportantDate.fromJson).toList(),
    constraints: _strings(j['constraints']),
    openQuestions: _list(j['open_questions']).map(OpenQuestion.fromJson).toList(),
  );

  final String goal;
  final List<String> deliverables;
  final List<Requirement> requirements;
  final List<ImportantDate> importantDates;
  final List<String> constraints;
  final List<OpenQuestion> openQuestions;

  bool get isEmpty => goal.isEmpty && deliverables.isEmpty && requirements.isEmpty && importantDates.isEmpty;

  Json toJson() => {
    'goal': goal,
    'deliverables': deliverables,
    'requirements': requirements.map((r) => r.toJson()).toList(),
    'important_dates': importantDates.map((d) => d.toJson()).toList(),
    'constraints': constraints,
    'open_questions': openQuestions.map((q) => q.toJson()).toList(),
  };
}

class Brief {
  const Brief({required this.version, required this.source, required this.content});

  factory Brief.fromJson(Json j) => Brief(
    version: (j['version'] as num?)?.toInt() ?? 0,
    source: j['source'] as String?,
    content: BriefContent.fromJson(Json.from(j['content'] as Map? ?? {})),
  );

  final int version;
  final String? source;
  final BriefContent content;
}

class BriefDraft {
  const BriefDraft({required this.content, required this.aiUsed, required this.aiError});

  factory BriefDraft.fromJson(Json j) => BriefDraft(
    content: BriefContent.fromJson(Json.from(j['content'] as Map? ?? {})),
    aiUsed: j['ai_used'] as bool? ?? false,
    aiError: j['ai_error'] as String?,
  );

  final BriefContent content;
  final bool aiUsed;
  final String? aiError;
}

class RequirementStatus {
  const RequirementStatus({
    required this.id,
    required this.code,
    required this.text,
    required this.covered,
    required this.met,
    required this.taskTitles,
  });

  factory RequirementStatus.fromJson(Json j) => RequirementStatus(
    id: j['id'] as String,
    code: j['code'] as String? ?? '',
    text: j['text'] as String? ?? '',
    covered: j['covered'] as bool? ?? false,
    met: j['met'] as bool? ?? false,
    taskTitles: _list(j['tasks']).map((t) => '${t['key']} ${t['title']}').toList(),
  );

  final String id;
  final String code;
  final String text;
  final bool covered;
  final bool met;
  final List<String> taskTitles;
}

class Citation {
  const Citation({
    required this.number,
    required this.documentId,
    required this.title,
    required this.pageStart,
    required this.pageEnd,
    required this.headingPath,
    required this.citedText,
  });

  factory Citation.fromJson(Json j) => Citation(
    number: (j['number'] as num?)?.toInt() ?? 0,
    documentId: j['document_id'] as String? ?? '',
    title: j['title'] as String? ?? '',
    pageStart: (j['page_start'] as num?)?.toInt() ?? 1,
    pageEnd: (j['page_end'] as num?)?.toInt() ?? 1,
    headingPath: j['heading_path'] as String? ?? '',
    citedText: j['cited_text'] as String? ?? '',
  );

  final int number;
  final String documentId;
  final String title;
  final int pageStart;
  final int pageEnd;
  final String headingPath;
  final String citedText;
}

class ChatThread {
  const ChatThread({required this.id, required this.title});

  factory ChatThread.fromJson(Json j) => ChatThread(id: j['id'] as String, title: j['title'] as String? ?? '');

  final String id;
  final String title;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    required this.kind,
    required this.citations,
    required this.feedback,
    this.model,
  });

  factory ChatMessage.fromJson(Json j) => ChatMessage(
    id: j['id'] as String,
    threadId: j['thread_id'] as String,
    role: j['role'] as String? ?? 'assistant',
    content: j['content'] as String? ?? '',
    kind: j['kind'] as String? ?? 'ai',
    citations: _list(j['citations']).map(Citation.fromJson).toList(),
    feedback: j['feedback'] as String?,
    model: j['model'] as String?,
  );

  final String id;
  final String threadId;
  final String role;
  final String content;
  final String kind;
  final List<Citation> citations;
  final String? feedback;

  /// The model that wrote the answer; null when it came from the non-AI fallback.
  final String? model;

  bool get isUser => role == 'user';
}

class ChatExchange {
  const ChatExchange({required this.thread, required this.question, required this.answer, required this.aiError});

  factory ChatExchange.fromJson(Json j) => ChatExchange(
    thread: ChatThread.fromJson(Json.from(j['thread'] as Map)),
    question: ChatMessage.fromJson(Json.from(j['question'] as Map)),
    answer: ChatMessage.fromJson(Json.from(j['answer'] as Map)),
    aiError: j['ai_error'] as String?,
  );

  final ChatThread thread;
  final ChatMessage question;
  final ChatMessage answer;
  final String? aiError;
}

class NoteItem {
  const NoteItem({required this.id, required this.kind, required this.content, required this.meetingDate});

  factory NoteItem.fromJson(Json j) => NoteItem(
    id: j['id'] as String,
    kind: j['kind'] as String? ?? 'general',
    content: j['content'] as String? ?? '',
    meetingDate: _date(j['meeting_date']),
  );

  final String id;
  final String kind;
  final String content;
  final DateTime? meetingDate;
}

class WeeklyReview {
  const WeeklyReview({
    required this.done,
    required this.doneHours,
    required this.slipped,
    required this.healthNow,
    required this.focusNext,
    required this.recommendReplan,
    required this.summary,
    required this.aiUsed,
  });

  factory WeeklyReview.fromJson(Json j) => WeeklyReview(
    done: _list(j['done']).map(TaskBrief.fromJson).toList(),
    doneHours: _double(j['done_hours']),
    slipped: _list(j['slipped']).map(TaskBrief.fromJson).toList(),
    healthNow: j['health_now'] as String?,
    focusNext: _list(j['focus_next']).map(TaskBrief.fromJson).toList(),
    recommendReplan: j['recommend_replan'] as bool? ?? false,
    summary: j['summary'] as String?,
    aiUsed: j['ai_used'] as bool? ?? false,
  );

  final List<TaskBrief> done;
  final double doneHours;
  final List<TaskBrief> slipped;
  final String? healthNow;
  final List<TaskBrief> focusNext;
  final bool recommendReplan;
  final String? summary;
  final bool aiUsed;
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.projectId,
    required this.type,
    required this.payload,
    required this.read,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Json j) => NotificationItem(
    id: j['id'] as String,
    projectId: j['project_id'] as String?,
    type: j['type'] as String? ?? '',
    payload: Json.from(j['payload'] as Map? ?? {}),
    read: j['read'] as bool? ?? false,
    createdAt: _date(j['created_at']),
  );

  final String id;

  /// The project the notice is about; null for account-wide notices.
  final String? projectId;
  final String type;
  final Json payload;
  final bool read;
  final DateTime? createdAt;
}

class StartHelp {
  const StartHelp({required this.firstStep, required this.subtasks, required this.aiUsed, required this.aiError});

  factory StartHelp.fromJson(Json j) => StartHelp(
    firstStep: j['first_step'] as String? ?? '',
    subtasks: _list(j['subtasks']).map((s) => s['title'].toString()).toList(),
    aiUsed: j['ai_used'] as bool? ?? false,
    aiError: j['ai_error'] as String?,
  );

  final String firstStep;
  final List<String> subtasks;
  final bool aiUsed;
  final String? aiError;
}
