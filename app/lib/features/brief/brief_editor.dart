import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../data/models.dart';

/// Edits a project brief. The brief is the single source of truth (master plan §4);
/// every save becomes a new version on the server.
class BriefEditor extends StatefulWidget {
  const BriefEditor({super.key, required this.initial, required this.onChanged});

  final BriefContent initial;
  final ValueChanged<BriefContent> onChanged;

  @override
  State<BriefEditor> createState() => _BriefEditorState();
}

class _BriefEditorState extends State<BriefEditor> {
  late final TextEditingController _goal = TextEditingController(text: widget.initial.goal);
  late List<TextEditingController> _deliverables = _controllers(widget.initial.deliverables);
  late List<TextEditingController> _requirements = _controllers(widget.initial.requirements.map((r) => r.text));
  late List<String?> _requirementCodes = widget.initial.requirements.map((r) => r.code).toList();
  late List<TextEditingController> _dateLabels = _controllers(widget.initial.importantDates.map((d) => d.label));
  late List<String?> _dateValues = widget.initial.importantDates.map((d) => d.date).toList();
  late List<TextEditingController> _constraints = _controllers(widget.initial.constraints);
  late final List<String> _questions = widget.initial.openQuestions.map((q) => q.question).toList();
  late final List<TextEditingController> _answers = _controllers(widget.initial.openQuestions.map((q) => q.answer));

  static List<TextEditingController> _controllers(Iterable<String> values) => [for (final v in values) TextEditingController(text: v)];

  @override
  void dispose() {
    for (final c in [_goal, ..._deliverables, ..._requirements, ..._dateLabels, ..._constraints, ..._answers]) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      BriefContent(
        goal: _goal.text.trim(),
        deliverables: _deliverables.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
        requirements: [
          for (var i = 0; i < _requirements.length; i++)
            if (_requirements[i].text.trim().isNotEmpty) Requirement(code: _requirementCodes[i], text: _requirements[i].text.trim()),
        ],
        importantDates: [
          for (var i = 0; i < _dateLabels.length; i++)
            if (_dateLabels[i].text.trim().isNotEmpty) ImportantDate(label: _dateLabels[i].text.trim(), date: _dateValues[i]),
        ],
        constraints: _constraints.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
        openQuestions: [for (var i = 0; i < _questions.length; i++) OpenQuestion(question: _questions[i], answer: _answers[i].text.trim())],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          title: l.briefGoal,
          child: TextField(
            controller: _goal,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(hintText: l.briefItemHint),
            onChanged: (_) => _emit(),
          ),
        ),
        _ListSection(
          title: l.briefDeliverables,
          controllers: _deliverables,
          onAdd: () => setState(() => _deliverables = [..._deliverables, TextEditingController()]),
          onRemove: (i) => setState(() {
            _deliverables[i].dispose();
            _deliverables = [..._deliverables]..removeAt(i);
            _emit();
          }),
          onChanged: _emit,
        ),
        _ListSection(
          title: l.briefRequirements,
          controllers: _requirements,
          prefixes: [for (final code in _requirementCodes) code],
          onAdd: () => setState(() {
            _requirements = [..._requirements, TextEditingController()];
            _requirementCodes = [..._requirementCodes, null];
          }),
          onRemove: (i) => setState(() {
            _requirements[i].dispose();
            _requirements = [..._requirements]..removeAt(i);
            _requirementCodes = [..._requirementCodes]..removeAt(i);
            _emit();
          }),
          onChanged: _emit,
        ),
        _Section(
          title: l.briefDates,
          child: Column(
            children: [
              for (var i = 0; i < _dateLabels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dateLabels[i],
                          decoration: InputDecoration(hintText: l.briefDateLabelHint),
                          onChanged: (_) => _emit(),
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.event_outlined, size: 18),
                        label: Text(switch (DateTime.tryParse(_dateValues[i] ?? '')) {
                          final date? => formatDate(context, date, alwaysYear: true),
                          null => l.pickDate,
                        }),
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await pickDate(
                            context,
                            initial: DateTime.tryParse(_dateValues[i] ?? ''),
                            first: DateTime(now.year - 1),
                            last: DateTime(now.year + 5),
                          );
                          if (picked != null) {
                            setState(() => _dateValues[i] = isoDate(picked));
                            _emit();
                          }
                        },
                      ),
                      IconButton(
                        tooltip: l.actionDelete,
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _dateLabels[i].dispose();
                          _dateLabels = [..._dateLabels]..removeAt(i);
                          _dateValues = [..._dateValues]..removeAt(i);
                          _emit();
                        }),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _dateLabels = [..._dateLabels, TextEditingController()];
                    _dateValues = [..._dateValues, null];
                  }),
                  icon: const Icon(Icons.add),
                  label: Text(l.actionAdd),
                ),
              ),
            ],
          ),
        ),
        _ListSection(
          title: l.briefConstraints,
          controllers: _constraints,
          onAdd: () => setState(() => _constraints = [..._constraints, TextEditingController()]),
          onRemove: (i) => setState(() {
            _constraints[i].dispose();
            _constraints = [..._constraints]..removeAt(i);
            _emit();
          }),
          onChanged: _emit,
        ),
        if (_questions.isNotEmpty)
          _Section(
            title: l.briefQuestions,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _questions.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.md),
                    child: TextField(
                      controller: _answers[i],
                      decoration: InputDecoration(labelText: _questions[i], hintText: l.briefAnswerHint),
                      onChanged: (_) => _emit(),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          const SizedBox(height: Space.sm),
          child,
        ],
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.title,
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
    this.prefixes,
  });

  final String title;
  final List<TextEditingController> controllers;
  final List<String?>? prefixes;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Section(
      title: title,
      child: Column(
        children: [
          for (var i = 0; i < controllers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controllers[i],
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(hintText: l.briefItemHint, prefixText: prefixes?[i] == null ? null : '${prefixes![i]}  '),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                  IconButton(tooltip: l.actionDelete, icon: const Icon(Icons.close), onPressed: () => onRemove(i)),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: Text(l.actionAdd)),
          ),
        ],
      ),
    );
  }
}
