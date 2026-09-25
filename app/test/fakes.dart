import 'package:purnara/data/api_client.dart';
import 'package:purnara/data/models.dart';
import 'package:purnara/data/repository.dart';

/// A repository that answers from memory, so widget tests need no server.
class FakeRepository extends PurnaraRepository {
  FakeRepository({this.projectList = const [], this.todayView, this.failWith}) : super(ApiClient('http://fake'));

  final List<Json> projectList;
  final Json? todayView;
  final Object? failWith;
  final updates = <String, Json>{};

  Future<T> _answer<T>(T Function() value) async {
    if (failWith != null) throw failWith!;
    return value();
  }

  @override
  Future<Profile> me() => _answer(
    () => Profile.fromJson({
      'id': 'u1',
      'name': 'Tester',
      'locale': 'id',
      'ai_enabled': false,
      'quota': {'used': 0, 'limit': 0},
      'auth_mode': 'local',
    }),
  );

  @override
  Future<List<Project>> projects() => _answer(() => projectList.map(Project.fromJson).toList());

  @override
  Future<TodayView> today() => _answer(() => TodayView.fromJson(todayView ?? emptyToday));

  @override
  Future<List<NotificationItem>> notifications() => _answer(() => <NotificationItem>[]);

  @override
  Future<List<ModeInfo>> modes() => _answer(
    () => [
      ModeInfo.fromJson({
        'id': 'academic',
        'name': {'id': 'Akademik', 'en': 'Academic'},
        'templates': [
          {
            'id': 'skripsi',
            'name': {'id': 'Skripsi', 'en': 'Undergraduate thesis'},
            'description': {'id': 'Penelitian S1', 'en': 'Bachelor research'},
            'task_count': 21,
            'total_hours': 180,
          },
        ],
      }),
    ],
  );

  @override
  Future<Task> updateTask(String taskId, Json changes) async {
    updates[taskId] = changes;
    return Task.fromJson({'id': taskId, 'project_id': 'p1', 'key': 'T1', ...changes});
  }
}

const emptyToday = <String, dynamic>{'date': '2026-10-05', 'focus': [], 'more_today': [], 'upcoming': [], 'projects': []};

Json projectJson({bool hasPlan = true}) => {
  'id': 'p1',
  'mode': 'academic',
  'template': 'skripsi',
  'title': 'NPC untuk game RTS',
  'description': '',
  'target': '',
  'deadline': '2027-02-26',
  'hours_by_weekday': [2, 2, 2, 2, 2, 0, 0],
  'blocked_dates': <String>[],
  'buffer_pct': 0.15,
  'health': hasPlan ? 'on_track' : null,
  'feasibility': 'feasible',
  'has_plan': hasPlan,
  'needs_reschedule': false,
  'task_count': 21,
};

Json todayJson() => {
  'date': '2026-10-05',
  'focus': [
    {
      'id': 't1',
      'key': 'T1',
      'title': 'Baca 10 jurnal utama',
      'status': 'todo',
      'project_id': 'p1',
      'project_title': 'NPC untuk game RTS',
      'milestone_title': 'Studi literatur',
      'scheduled_start': '2026-10-05',
      'scheduled_end': '2026-10-08',
      'estimate_hours': 8,
      'is_critical': true,
      'late_days': 0,
      'postpone_count': 0,
    },
  ],
  'more_today': [],
  'upcoming': [],
  'projects': [
    {
      'id': 'p1',
      'title': 'NPC untuk game RTS',
      'health': 'on_track',
      'feasibility': 'feasible',
      'deadline': '2027-02-26',
      'days_left': 144,
      'has_plan': true,
      'needs_reschedule': false,
      'pending_suggestions': 0,
      'next_milestone': {'title': 'Studi literatur'},
      'hours_today': 2,
    },
  ],
};

const networkError = ApiException('network_error');
