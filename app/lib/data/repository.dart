import 'dart:typed_data';

import 'api_client.dart';
import 'models.dart';

String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Every call the app makes to the Purnara API.
class PurnaraRepository {
  PurnaraRepository(this.api);

  final ApiClient api;

  Json _j(Object? data) => Json.from(data as Map);
  List<Json> _l(Object? data) => (data as List).map((e) => Json.from(e as Map)).toList();

  // --- system and profile -------------------------------------------------------------

  Future<Json> serverHealth() async => _j(await api.get<dynamic>('/health'));

  Future<Profile> me() async => Profile.fromJson(_j(await api.get<dynamic>('/me')));

  Future<Profile> updateMe({String? locale, String? name}) async =>
      Profile.fromJson(_j(await api.patch<dynamic>('/me', data: {'locale': ?locale, 'name': ?name})));

  Future<Json> exportData() async => _j(await api.get<dynamic>('/me/export'));

  Future<void> deleteAccount() => api.delete('/me');

  Future<TodayView> today() async => TodayView.fromJson(_j(await api.get<dynamic>('/me/today')));

  Future<List<NotificationItem>> notifications() async =>
      _l(await api.get<dynamic>('/notifications')).map(NotificationItem.fromJson).toList();

  Future<void> markNotificationRead(String id) => api.post<dynamic>('/notifications/$id/read');

  Future<List<ModeInfo>> modes() async => _l(await api.get<dynamic>('/modes')).map(ModeInfo.fromJson).toList();

  // --- projects -------------------------------------------------------------------------

  Future<List<Project>> projects() async => _l(await api.get<dynamic>('/projects')).map(Project.fromJson).toList();

  /// A complete example project in [locale] ('id' or 'en'), made from the app's own rules.
  Future<Project> createSampleProject({required String locale}) async =>
      Project.fromJson(_j(await api.post<dynamic>('/projects/sample', data: {'locale': locale})));

  Future<Project> createProject({
    required String template,
    required String title,
    required String description,
    required String target,
    required DateTime deadline,
    required List<double> hoursByWeekday,
  }) async => Project.fromJson(
    _j(
      await api.post<dynamic>(
        '/projects',
        data: {
          'template': template,
          'title': title,
          'description': description,
          'target': target,
          'deadline': _iso(deadline),
          'hours_by_weekday': hoursByWeekday,
        },
      ),
    ),
  );

  Future<Project> updateProject(
    String id, {
    String? title,
    String? description,
    DateTime? deadline,
    List<double>? hoursByWeekday,
    List<DateTime>? blockedDates,
    double? bufferPct,
  }) async => Project.fromJson(
    _j(
      await api.patch<dynamic>(
        '/projects/$id',
        data: {
          'title': ?title,
          'description': ?description,
          if (deadline != null) 'deadline': _iso(deadline),
          'hours_by_weekday': ?hoursByWeekday,
          if (blockedDates != null) 'blocked_dates': blockedDates.map(_iso).toList(),
          'buffer_pct': ?bufferPct,
        },
      ),
    ),
  );

  Future<void> deleteProject(String id) => api.delete('/projects/$id');

  Future<Brief> brief(String projectId) async => Brief.fromJson(_j(await api.get<dynamic>('/projects/$projectId/brief')));

  Future<BriefDraft> extractBrief(String projectId) async =>
      BriefDraft.fromJson(_j(await api.post<dynamic>('/projects/$projectId/brief/extract')));

  Future<Brief> saveBrief(String projectId, BriefContent content, {String source = 'user'}) async =>
      Brief.fromJson(_j(await api.put<dynamic>('/projects/$projectId/brief', data: {'content': content.toJson(), 'source': source})));

  Future<List<RequirementStatus>> requirements(String projectId) async =>
      _l(await api.get<dynamic>('/projects/$projectId/requirements')).map(RequirementStatus.fromJson).toList();

  // --- plan ------------------------------------------------------------------------------

  Future<PlanData> plan(String projectId) async => PlanData.fromJson(_j(await api.get<dynamic>('/projects/$projectId/plan')));

  Future<Suggestion> generatePlan(String projectId) async =>
      Suggestion.fromJson(_j(await api.post<dynamic>('/projects/$projectId/plan/generate')));

  Future<List<Suggestion>> replan(String projectId) async =>
      _l(await api.post<dynamic>('/projects/$projectId/replan')).map(Suggestion.fromJson).toList();

  Future<Health> health(String projectId) async => Health.fromJson(_j(await api.get<dynamic>('/projects/$projectId/health')));

  Future<WeeklyReview> weeklyReview(String projectId) async =>
      WeeklyReview.fromJson(_j(await api.get<dynamic>('/projects/$projectId/weekly-review')));

  Future<Task> createTask(String projectId, {required String title, required double estimateHours, String? milestoneId}) async =>
      Task.fromJson(
        _j(
          await api.post<dynamic>(
            '/projects/$projectId/tasks',
            data: {'title': title, 'estimate_hours': estimateHours, 'milestone_id': ?milestoneId},
          ),
        ),
      );

  Future<Task> task(String taskId) async => Task.fromJson(_j(await api.get<dynamic>('/tasks/$taskId')));

  Future<Task> updateTask(String taskId, Json changes) async =>
      Task.fromJson(_j(await api.patch<dynamic>('/tasks/$taskId', data: changes)));

  Future<void> deleteTask(String taskId) => api.delete('/tasks/$taskId');

  Future<Suggestion> breakdownTask(String taskId) async => Suggestion.fromJson(_j(await api.post<dynamic>('/tasks/$taskId/breakdown')));

  Future<StartHelp> startHelp(String taskId) async => StartHelp.fromJson(_j(await api.post<dynamic>('/tasks/$taskId/start-help')));

  // --- suggestions ---------------------------------------------------------------------------

  Future<List<Suggestion>> suggestions(String projectId) async =>
      _l(await api.get<dynamic>('/projects/$projectId/suggestions')).map(Suggestion.fromJson).toList();

  Future<Suggestion> suggestion(String id) async => Suggestion.fromJson(_j(await api.get<dynamic>('/suggestions/$id')));

  Future<Suggestion> applySuggestion(String id, {List<int>? opIndices}) async =>
      Suggestion.fromJson(_j(await api.post<dynamic>('/suggestions/$id/apply', data: {'op_indices': opIndices})));

  Future<Suggestion> rejectSuggestion(String id) async => Suggestion.fromJson(_j(await api.post<dynamic>('/suggestions/$id/reject')));

  // --- documents -------------------------------------------------------------------------------

  Future<List<DocumentItem>> documents(String projectId) async =>
      _l(await api.get<dynamic>('/projects/$projectId/documents')).map(DocumentItem.fromJson).toList();

  Future<DocumentItem> uploadDocument(String projectId, String fileName, Uint8List bytes) async =>
      DocumentItem.fromJson(_j(await api.upload<dynamic>('/projects/$projectId/documents', fileName: fileName, bytes: bytes)));

  Future<DocumentItem> retryDocument(String id) async => DocumentItem.fromJson(_j(await api.post<dynamic>('/documents/$id/retry')));

  Future<void> deleteDocument(String id) => api.delete('/documents/$id');

  // --- chat and notes ------------------------------------------------------------------------------

  Future<List<ChatThread>> threads(String projectId) async =>
      _l(await api.get<dynamic>('/projects/$projectId/threads')).map(ChatThread.fromJson).toList();

  Future<List<ChatMessage>> messages(String threadId) async =>
      _l(await api.get<dynamic>('/threads/$threadId/messages')).map(ChatMessage.fromJson).toList();

  Future<ChatExchange> ask(String projectId, String question, {String? threadId}) async =>
      ChatExchange.fromJson(_j(await api.post<dynamic>('/projects/$projectId/chat', data: {'question': question, 'thread_id': ?threadId})));

  Future<ChatMessage> feedback(String messageId, String? value) async =>
      ChatMessage.fromJson(_j(await api.patch<dynamic>('/messages/$messageId', data: {'feedback': value})));

  Future<List<NoteItem>> notes(String projectId, {String? kind}) async =>
      _l(await api.get<dynamic>('/projects/$projectId/notes', query: {'kind': ?kind})).map(NoteItem.fromJson).toList();

  Future<Suggestion?> addSupervisionNote(String projectId, String content, DateTime meetingDate) async {
    final data = _j(
      await api.post<dynamic>(
        '/projects/$projectId/notes',
        data: {'kind': 'supervision', 'content': content, 'meeting_date': _iso(meetingDate)},
      ),
    );
    final suggestion = data['suggestion'];
    return suggestion is Map ? Suggestion.fromJson(Json.from(suggestion)) : null;
  }
}
