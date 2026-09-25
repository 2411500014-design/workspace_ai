import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../data/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final locale = settings.locale?.languageCode ?? context.localeCode;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: PageBody(
        maxWidth: kReadingWidth,
        children: [
          SectionCard(
            title: l.settingsLanguage,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 'id', label: Text(l.languageIndonesian)),
                ButtonSegment(value: 'en', label: Text(l.languageEnglish)),
              ],
              selected: {locale},
              onSelectionChanged: (s) async {
                await ref.read(settingsProvider.notifier).setLocale(Locale(s.first));
                // The server writes AI text in the user's language; keep it in step.
                try {
                  await ref.read(repositoryProvider).updateMe(locale: s.first);
                  ref.invalidate(meProvider);
                } catch (_) {
                  // Offline: the app language still changes; the server catches up later.
                }
              },
            ),
          ),
          SectionCard(
            title: l.settingsTheme,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto_outlined), label: Text(l.themeSystem)),
                ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode_outlined), label: Text(l.themeLight)),
                ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode_outlined), label: Text(l.themeDark)),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => ref.read(settingsProvider.notifier).setThemeMode(s.first),
            ),
          ),
          const _ServerCard(),
          const _PhoneCard(),
          const _AiCard(),
          const _AccountCard(),
          SectionCard(
            title: l.settingsAbout,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.settingsVersion(AppConfig.version), style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: Space.md),
                Text(l.settingsPrivacy, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: Space.md),
                Text(l.settingsFontLicense, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: Space.sm),
                TextButton(
                  onPressed: () => showLicensePage(context: context, applicationName: l.appTitle, applicationVersion: AppConfig.version),
                  child: Text(l.settingsLicenses),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerCard extends ConsumerStatefulWidget {
  const _ServerCard();

  @override
  ConsumerState<_ServerCard> createState() => _ServerCardState();
}

class _ServerCardState extends ConsumerState<_ServerCard> {
  late final _url = TextEditingController(text: ref.read(apiBaseUrlProvider));
  bool _testing = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final url = _url.text.trim();
    final parsed = Uri.tryParse(url);
    if (parsed == null || !(parsed.isScheme('http') || parsed.isScheme('https')) || parsed.host.isEmpty) {
      showMessage(context, context.l10n.settingsServerInvalid);
      return;
    }
    await ref.read(settingsProvider.notifier).setServerUrl(url);
    if (!mounted) return;
    _url.text = ref.read(apiBaseUrlProvider);
    await _test();
  }

  Future<void> _test() async {
    final l = context.l10n;
    setState(() => _testing = true);
    try {
      await ref.read(repositoryProvider).serverHealth();
      ref.invalidate(serverHealthProvider);
      if (mounted) showMessage(context, l.settingsServerOk);
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(context, e, serverUrl: ref.read(apiBaseUrlProvider)));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final custom = ref.watch(settingsProvider.select((s) => s.serverUrl)) != null;
    return SectionCard(
      title: l.settingsServer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(hintText: l.settingsServerHint),
            onSubmitted: (_) => _apply(),
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              FilledButton(onPressed: _testing ? null : _apply, child: Text(l.actionSave)),
              OutlinedButton(
                onPressed: _testing ? null : _test,
                child: _testing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l.settingsServerTest),
              ),
              if (custom)
                TextButton(
                  onPressed: _testing
                      ? null
                      : () async {
                          await ref.read(settingsProvider.notifier).setServerUrl(null);
                          if (!mounted) return;
                          _url.text = ref.read(apiBaseUrlProvider);
                          await _test();
                        },
                  child: Text(l.settingsServerReset),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Local mode only: the address a phone on the same Wi-Fi opens, or what to do first.
class _PhoneCard extends ConsumerWidget {
  const _PhoneCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final health = ref.watch(serverHealthProvider).value;
    if (health == null || health['auth_mode'] != 'local') return const SizedBox.shrink();
    final urls = [for (final u in (health['lan_urls'] as List? ?? const [])) '$u'];
    final listening = health['lan_listening'] == true;
    final webApp = health['web_app'] == true;
    return SectionCard(
      title: l.settingsPhoneTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (urls.isEmpty)
            Text(l.settingsPhoneNoNetwork, style: theme.textTheme.bodyMedium)
          else if (!listening)
            Text(l.settingsPhoneStartServer, style: theme.textTheme.bodyMedium)
          else ...[
            Text(webApp ? l.settingsPhoneOpen : l.settingsPhoneBuildFirst, style: theme.textTheme.bodyMedium),
            const SizedBox(height: Space.md),
            for (final url in urls)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.xs),
                child: Row(
                  children: [
                    Icon(Icons.smartphone_outlined, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: Space.sm),
                    Expanded(child: SelectableText(url, style: theme.textTheme.titleSmall)),
                    IconButton(
                      tooltip: l.copyText,
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: url));
                        if (context.mounted) showMessage(context, l.copied);
                      },
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: Space.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => ref.invalidate(serverHealthProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l.actionRefresh),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiCard extends ConsumerWidget {
  const _AiCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final me = ref.watch(meProvider);
    return SectionCard(
      title: l.settingsAi,
      child: switch (me) {
        AsyncValue(hasValue: true, :final value?) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  value.aiEnabled ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                  color: value.aiEnabled ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Space.md),
                Expanded(child: Text(value.aiEnabled ? l.settingsAiActive : l.settingsAiInactive, style: theme.textTheme.bodyLarge)),
              ],
            ),
            if (value.aiEnabled && value.quota.limit > 0) ...[
              const SizedBox(height: Space.lg),
              Text(
                l.settingsQuota(formatNumber(context, value.quota.used), formatNumber(context, value.quota.limit)),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: Space.xs),
              LinearProgressIndicator(
                value: (value.quota.used / value.quota.limit).clamp(0, 1),
                minHeight: 8,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              if (value.quota.resetsAt != null) ...[
                const SizedBox(height: Space.xs),
                Text(
                  l.settingsQuotaReset(formatDate(context, value.quota.resetsAt!.toLocal(), alwaysYear: true)),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
        AsyncValue(:final error?) => Text(errorMessage(context, error, serverUrl: ref.watch(apiBaseUrlProvider))),
        _ => const LinearProgressIndicator(),
      },
    );
  }
}

class _AccountCard extends ConsumerStatefulWidget {
  const _AccountCard();

  @override
  ConsumerState<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends ConsumerState<_AccountCard> {
  bool _busy = false;

  Future<void> _export() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final data = await ref.read(repositoryProvider).exportData();
      final bytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(data));
      final saved = await FilePicker.saveFile(
        dialogTitle: l.settingsExport,
        fileName: 'purnara-export-${isoDate(DateTime.now())}.json',
        mimeType: 'application/json',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );
      // On web the download starts without a path; elsewhere null means "cancelled".
      if (mounted && (saved != null || kIsWeb)) showMessage(context, l.settingsExported);
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final l = context.l10n;
    final ok = await confirm(context, message: l.settingsDeleteConfirm, confirmLabel: l.settingsDeleteButton, destructive: true);
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(repositoryProvider).deleteAccount();
      ref.invalidate(projectsProvider);
      ref.invalidate(meProvider);
      ref.invalidate(todayProvider);
      ref.invalidate(notificationsProvider);
      if (mounted) context.go('/today');
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final me = ref.watch(meProvider).value;
    return SectionCard(
      title: l.settingsAccount,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (me?.authMode == 'local') ...[Text(l.settingsLocalMode, style: theme.textTheme.bodyMedium), const SizedBox(height: Space.md)],
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _export,
                icon: const Icon(Icons.download_outlined),
                label: Text(l.settingsExport),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                onPressed: _busy ? null : _deleteAccount,
                icon: const Icon(Icons.delete_forever_outlined),
                label: Text(l.settingsDeleteAccount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
