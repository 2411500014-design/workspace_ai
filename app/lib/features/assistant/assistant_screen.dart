import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

/// Project chat: answers grounded in the project's documents, with page
/// citations; says so plainly when the documents do not contain the answer
/// (master plan §7).
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key, this.initialQuestion});

  final String? initialQuestion;

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  String? _threadId;
  bool _newConversation = false;
  String? _pendingQuestion;

  /// A question handed over by another screen, asked once the project is known.
  String? _queued;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuestion;
    if (q != null && q.trim().isNotEmpty) {
      _newConversation = true;
      _queued = q;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Drop the question from the address so returning to this tab does not ask again.
        context.go('/assistant');
        _sendQueued();
      });
    }
    ref.listenManual(currentProjectProvider.select((p) => p?.id), (previous, next) {
      if (previous != null && previous != next) {
        // Another project: its conversations are not this one's.
        setState(() {
          _threadId = null;
          _newConversation = false;
        });
      }
      _sendQueued();
    });
  }

  void _sendQueued() {
    final q = _queued;
    if (q == null || !mounted || ref.read(currentProjectProvider) == null) return;
    _queued = null;
    _send(q);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String? _activeThread(List<ChatThread> threads) {
    if (_newConversation) return _threadId;
    return _threadId ?? (threads.isEmpty ? null : threads.first.id);
  }

  Future<void> _send(String text) async {
    final question = text.trim();
    final project = ref.read(currentProjectProvider);
    if (question.isEmpty || project == null || _pendingQuestion != null) return;
    final container = containerOf(ref);
    final threads = ref.read(threadsProvider(project.id)).value ?? const <ChatThread>[];
    final threadId = _activeThread(threads);
    setState(() => _pendingQuestion = question);
    _input.clear();
    _scrollToEnd();
    try {
      final exchange = await container.read(repositoryProvider).ask(project.id, question, threadId: threadId);
      container.invalidate(threadsProvider(project.id));
      container.invalidate(messagesProvider(exchange.thread.id));
      await container.read(messagesProvider(exchange.thread.id).future);
      if (!mounted) return;
      setState(() {
        _threadId = exchange.thread.id;
        _newConversation = false;
      });
    } catch (e) {
      if (mounted) {
        _input.text = question;
        showMessage(context, errorMessage(context, e));
      }
    } finally {
      if (mounted) setState(() => _pendingQuestion = null);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: Motion.normal, curve: Motion.enter);
      }
    });
  }

  void _startNew() => setState(() {
    _threadId = null;
    _newConversation = true;
  });

  void _open(String id) {
    setState(() {
      _threadId = id;
      _newConversation = false;
    });
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(currentProjectProvider);
    if (project == null) return const PageSkeleton();
    final threadList = ref.watch(threadsProvider(project.id));
    final threads = threadList.value ?? const <ChatThread>[];
    final active = _activeThread(threads);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        final conversation = _Conversation(
          threadId: active,
          // Until the list arrives, "no conversation yet" is not known to be true.
          threads: _newConversation ? const AsyncValue.data(null) : threadList,
          onRetryThreads: () => ref.invalidate(threadsProvider(project.id)),
          pendingQuestion: _pendingQuestion,
          scroll: _scroll,
          input: _input,
          onSend: _send,
          header: wide ? null : _ThreadPicker(threads: threads, active: active, onOpen: _open, onNew: _startNew),
        );
        if (!wide) return conversation;
        return Row(
          children: [
            SizedBox(
              width: 280,
              child: _ThreadList(threads: threads, active: active, onOpen: _open, onNew: _startNew),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: conversation),
          ],
        );
      },
    );
  }
}

class _ThreadList extends StatelessWidget {
  const _ThreadList({required this.threads, required this.active, required this.onOpen, required this.onNew});

  final List<ChatThread> threads;
  final String? active;
  final ValueChanged<String> onOpen;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Space.md),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          child: OutlinedButton.icon(onPressed: onNew, icon: const Icon(Icons.add_comment_outlined), label: Text(l.newConversation)),
        ),
        const SizedBox(height: Space.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.xs),
          child: Text(l.conversations, style: Theme.of(context).textTheme.labelLarge),
        ),
        for (final t in threads)
          ListTile(
            selected: t.id == active,
            title: Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            onTap: () => onOpen(t.id),
          ),
      ],
    );
  }
}

class _ThreadPicker extends StatelessWidget {
  const _ThreadPicker({required this.threads, required this.active, required this.onOpen, required this.onNew});

  final List<ChatThread> threads;
  final String? active;
  final ValueChanged<String> onOpen;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final current = threads.where((t) => t.id == active).firstOrNull;
    return Row(
      children: [
        Expanded(
          child: threads.isEmpty
              ? const SizedBox.shrink()
              : PopupMenuButton<String>(
                  tooltip: l.conversations,
                  position: PopupMenuPosition.under,
                  onSelected: onOpen,
                  itemBuilder: (context) => [
                    for (final t in threads)
                      CheckedPopupMenuItem(
                        value: t.id,
                        checked: t.id == active,
                        child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.sm),
                    child: Row(
                      children: [
                        const Icon(Icons.forum_outlined, size: 20),
                        const SizedBox(width: Space.sm),
                        Flexible(child: Text(current?.title ?? l.newConversation, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                  ),
                ),
        ),
        IconButton(tooltip: l.newConversation, onPressed: onNew, icon: const Icon(Icons.add_comment_outlined)),
      ],
    );
  }
}

class _Conversation extends ConsumerWidget {
  const _Conversation({
    required this.threadId,
    required this.threads,
    required this.onRetryThreads,
    required this.pendingQuestion,
    required this.scroll,
    required this.input,
    required this.onSend,
    this.header,
  });

  final String? threadId;
  final AsyncValue<Object?> threads;
  final VoidCallback onRetryThreads;
  final String? pendingQuestion;
  final ScrollController scroll;
  final TextEditingController input;
  final ValueChanged<String> onSend;
  final Widget? header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final messages = threadId == null ? threads.whenData((_) => const <ChatMessage>[]) : ref.watch(messagesProvider(threadId!));
    final list = messages.value ?? const <ChatMessage>[];
    final empty = list.isEmpty && pendingQuestion == null;
    return Column(
      children: [
        if (header != null) Padding(padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.sm, 0), child: header),
        Expanded(
          child: messages.hasError && !messages.hasValue
              ? ErrorView(
                  error: messages.error!,
                  onRetry: threadId == null ? onRetryThreads : () => ref.invalidate(messagesProvider(threadId!)),
                )
              : !messages.hasValue
              ? const LoadingView()
              : empty
              ? _EmptyChat(onAsk: onSend)
              : ListView(
                  controller: scroll,
                  padding: const EdgeInsets.all(Space.lg),
                  children: [
                    for (final m in list) _centered(_MessageBubble(message: m)),
                    if (pendingQuestion != null) ...[
                      _centered(_UserBubble(text: pendingQuestion!)),
                      _centered(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: Space.md),
                          child: Row(
                            children: [
                              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                              const SizedBox(width: Space.md),
                              Text(l.assistantThinking),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
        _Composer(controller: input, busy: pendingQuestion != null, onSend: onSend),
      ],
    );
  }

  Widget _centered(Widget child) => Center(
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: child),
  );
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onAsk});

  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(Space.xl),
      children: [
        EmptyState(icon: Icons.forum_outlined, message: l.assistantEmpty),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final q in [l.assistantSuggestion1, l.assistantSuggestion2, l.assistantSuggestion3])
              ActionChip(label: Text(q), onPressed: () => onAsk(q)),
          ],
        ),
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: Space.xxxl, bottom: Space.md),
        padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(Radii.lg).copyWith(bottomRight: const Radius.circular(Radii.sm)),
        ),
        child: SelectableText(text, style: TextStyle(color: scheme.onPrimaryContainer)),
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (message.isUser) return _UserBubble(text: message.content);
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final body = <Widget>[];
    switch (message.kind) {
      case 'not_found':
        body.add(
          Row(
            children: [
              Icon(Icons.search_off, color: scheme.onSurfaceVariant),
              const SizedBox(width: Space.sm),
              Expanded(child: Text(l.answerNotFound, style: theme.textTheme.bodyLarge)),
            ],
          ),
        );
        // Without AI the search needs the documents' own words; say so, with a way forward.
        if (message.model == null) {
          body
            ..add(const SizedBox(height: Space.sm))
            ..add(Text(l.answerNotFoundNoAi, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)));
        }
      case 'extractive' || 'closest':
        body
          ..add(
            Text(
              message.kind == 'closest' ? l.answerClosestHeader : l.answerExtractiveHeader,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          )
          ..add(const SizedBox(height: Space.md));
        for (final c in message.citations) {
          body.add(_Quote(citation: c));
        }
      default:
        body.add(SelectableText(message.content, style: theme.textTheme.bodyLarge));
        if (message.kind == 'general') {
          body
            ..add(const SizedBox(height: Space.md))
            ..add(InfoBanner(icon: Icons.public, message: l.answerGeneral));
        }
        if (message.citations.isNotEmpty) {
          body
            ..add(const SizedBox(height: Space.md))
            ..add(
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [for (final c in message.citations) _CitationChip(citation: c)],
              ),
            );
        }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg, right: Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(Radii.lg).copyWith(bottomLeft: const Radius.circular(Radii.sm)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: body),
          ),
          Row(
            children: [
              if (message.kind == 'ai' || message.kind == 'general') ...[const SourceLabel(aiUsed: true), const SizedBox(width: Space.xs)],
              IconButton(
                tooltip: l.copyText,
                icon: const Icon(Icons.copy_outlined, size: 18),
                onPressed: () {
                  final text = message.kind == 'extractive' || message.kind == 'closest'
                      ? message.citations.map((c) => '${c.citedText}\n(${c.title}, ${_pages(l, c)})').join('\n\n')
                      : message.content;
                  Clipboard.setData(ClipboardData(text: text));
                  showMessage(context, l.copied);
                },
              ),
              _FeedbackButton(message: message, value: 'up'),
              _FeedbackButton(message: message, value: 'down'),
            ],
          ),
        ],
      ),
    );
  }
}

String _pages(AppLocalizations l, Citation c) =>
    c.pageStart == c.pageEnd ? l.citationPage('${c.pageStart}') : l.citationPages('${c.pageStart}', '${c.pageEnd}');

class _FeedbackButton extends ConsumerWidget {
  const _FeedbackButton({required this.message, required this.value});

  final ChatMessage message;
  final String value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final selected = message.feedback == value;
    final up = value == 'up';
    return IconButton(
      tooltip: up ? l.feedbackUp : l.feedbackDown,
      isSelected: selected,
      icon: Icon(up ? Icons.thumb_up_outlined : Icons.thumb_down_outlined, size: 18),
      selectedIcon: Icon(up ? Icons.thumb_up : Icons.thumb_down, size: 18),
      onPressed: () async {
        final container = containerOf(ref);
        try {
          await container.read(repositoryProvider).feedback(message.id, selected ? null : value);
          container.invalidate(messagesProvider(message.threadId));
        } catch (e) {
          if (context.mounted) showMessage(context, errorMessage(context, e));
        }
      },
    );
  }
}

class _CitationChip extends StatelessWidget {
  const _CitationChip({required this.citation});

  final Citation citation;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ActionChip(
      avatar: CircleAvatar(child: Text('${citation.number}', style: const TextStyle(fontSize: 11))),
      label: Text('${citation.title}, ${_pages(l, citation)}', overflow: TextOverflow.ellipsis),
      onPressed: () => showModalBottomSheet<void>(
        useRootNavigator: true,
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
            child: _Quote(citation: citation),
          ),
        ),
      ),
    );
  }
}

/// A passage from a document with its title and pages.
class _Quote extends StatelessWidget {
  const _Quote({required this.citation});

  final Citation citation;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    // The first heading is often the document title itself; do not say it twice.
    var heading = citation.headingPath;
    if (heading.startsWith(citation.title)) heading = heading.substring(citation.title.length).replaceFirst(RegExp(r'^\s*>\s*'), '');
    return Container(
      margin: const EdgeInsets.only(bottom: Space.md),
      padding: const EdgeInsets.only(left: Space.md),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(citation.citedText, style: theme.textTheme.bodyMedium),
          const SizedBox(height: Space.xs),
          Text(
            ['[${citation.number}] ${citation.title}', if (heading.isNotEmpty) heading, _pages(l, citation)].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.busy, required this.onSend});

  final TextEditingController controller;
  final bool busy;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.enter): () {
                          if (!busy) onSend(controller.text);
                        },
                      },
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 4000,
                        textInputAction: TextInputAction.send,
                        onSubmitted: busy ? null : onSend,
                        decoration: InputDecoration(hintText: l.assistantHint, counterText: ''),
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  IconButton.filled(
                    tooltip: l.assistantSend,
                    onPressed: busy ? null : () => onSend(controller.text),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
