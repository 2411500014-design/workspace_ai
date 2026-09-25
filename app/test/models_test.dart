import 'package:flutter_test/flutter_test.dart';
import 'package:purnara/core/format.dart';
import 'package:purnara/data/models.dart';

void main() {
  group('formatting', () {
    test('hours never show a trailing .0', () {
      expect(formatHours(2), '2');
      expect(formatHours(1.5), '1.5');
      expect(formatHours(0.25), '0.25');
      expect(formatHours(2.0000001), '2');
    });

    test('percentages and ISO dates', () {
      expect(formatPct(0.156), '16');
      expect(isoDate(DateTime(2026, 3, 7)), '2026-03-07');
      expect(dateOnly(DateTime(2026, 3, 7, 18, 30)), DateTime(2026, 3, 7));
    });
  });

  group('models', () {
    test('LocalizedText falls back to Indonesian, then to any value', () {
      final text = LocalizedText.fromJson({'id': 'Skripsi', 'en': 'Thesis'});
      expect(text.of('en'), 'Thesis');
      expect(text.of('fr'), 'Skripsi');
      expect(LocalizedText.fromJson({'en': 'Only English'}).of('id'), 'Only English');
      expect(LocalizedText.fromJson('plain').of('en'), 'plain');
    });

    test('a plan knows its leaf tasks', () {
      final plan = PlanData.fromJson({
        'project': {'id': 'p1', 'deadline': '2027-01-01', 'hours_by_weekday': [1, 1, 1, 1, 1, 0, 0]},
        'milestones': [],
        'tasks': [
          {'id': 'a', 'project_id': 'p1', 'key': 'T1'},
          {'id': 'b', 'project_id': 'p1', 'key': 'T2', 'parent_task_id': 'a'},
          {'id': 'c', 'project_id': 'p1', 'key': 'T3'},
        ],
      });
      expect(plan.leafTasks.map((t) => t.id), ['b', 'c']);
      expect(plan.taskById('b')?.parentTaskId, 'a');
      expect(plan.project.weeklyHours, 5);
    });

    test('suggestions expose preview and meta fields', () {
      final s = Suggestion.fromJson({
        'id': 's1',
        'project_id': 'p1',
        'kind': 'replan',
        'ops': [
          {'op': 'update', 'entity': 'task', 'id': 't1', 'fields': {'deferred': true}, 'label': 'Bab 5'},
          {'op': 'reschedule', 'entity': 'project'},
        ],
        'preview': {'feasibility': 'tight', 'projected_finish': '2027-01-20', 'changed_count': 4, 'changes': []},
        'meta': {'option': 'reduce_scope', 'params': {'deferred_titles': ['Bab 5']}, 'ai_error': 'ai_unavailable'},
      });
      expect(s.isPending, isTrue);
      expect(s.option, 'reduce_scope');
      expect(s.ops.first.label, 'Bab 5');
      expect(s.projectedFinish, DateTime(2027, 1, 20));
      expect(s.changedCount, 4);
      expect(s.aiError, 'ai_unavailable');
    });

    test('a brief survives a round trip to JSON', () {
      const brief = BriefContent(
        goal: 'Membandingkan MCTS dan Utility AI',
        deliverables: ['Naskah skripsi'],
        requirements: [Requirement(code: 'R1', text: 'Minimal 20 referensi')],
        importantDates: [ImportantDate(label: 'Seminar proposal', date: '2026-11-20')],
        openQuestions: [OpenQuestion(question: 'Metode?', answer: 'MCTS')],
      );
      final again = BriefContent.fromJson(brief.toJson());
      expect(again.goal, brief.goal);
      expect(again.requirements.single.code, 'R1');
      expect(again.importantDates.single.date, '2026-11-20');
      expect(again.openQuestions.single.answer, 'MCTS');
      expect(again.isEmpty, isFalse);
    });
  });
}
