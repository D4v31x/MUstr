import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_strings.dart';
import '../widgets/app_update_dialog.dart';

const _repositoryUri = 'https://github.com/D4v31x/MUstr';
const _authorUri = 'https://github.com/D4v31x';
const _issueUri =
    'https://github.com/D4v31x/MUstr/issues/new?labels=bug&title=Bug%3A%20';
const _feedbackUri =
    'https://github.com/D4v31x/MUstr/issues/new?labels=feedback&title=Feedback%3A%20';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int _logoTaps = 0;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(strings.about)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Semantics(
                button: true,
                label: 'MUstr',
                child: GestureDetector(
                  key: const ValueKey('about-logo'),
                  onTap: _tapLogo,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/MUNI_Time_icon.png',
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MUstr',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontFamily: 'MuniBold',
                            color: scheme.primary,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.aboutSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) => Text(
                        strings.version(snapshot.data?.version ?? '...'),
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: scheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _AboutInfo(
            icon: Icons.school_outlined,
            title: strings.aboutPurposeTitle,
            body: strings.aboutPurposeBody,
          ),
          const SizedBox(height: 16),
          Material(
            color: scheme.secondaryContainer.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: scheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strings.aboutIndependent,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _AboutActions(
            children: [
              _AboutAction(
                icon: Icons.system_update_alt_rounded,
                title: strings.checkForUpdates,
                onTap: () => appUpdateController.check(),
              ),
              _AboutAction(
                icon: Icons.person_outline_rounded,
                title: strings.madeBy,
                onTap: () => _openLink(_authorUri),
              ),
              _AboutAction(
                icon: Icons.code_rounded,
                title: strings.projectSource,
                subtitle: strings.projectSourceSubtitle,
                onTap: () => _openLink(_repositoryUri),
              ),
              _AboutAction(
                icon: Icons.bug_report_outlined,
                title: strings.reportIssue,
                subtitle: strings.reportIssueSubtitle,
                onTap: () => _openLink(_issueUri),
              ),
              _AboutAction(
                icon: Icons.chat_bubble_outline_rounded,
                title: strings.sendFeedback,
                subtitle: strings.sendFeedbackSubtitle,
                onTap: () => _openLink(_feedbackUri),
              ),
              _AboutAction(
                icon: Icons.description_outlined,
                title: strings.openSourceLicenses,
                subtitle: strings.openSourceLicensesSubtitle,
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'MUstr',
                  applicationIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'assets/MUNI_Time_icon.png',
                      width: 64,
                      height: 64,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(String rawUri) async {
    final opened = await launchUrl(
      Uri.parse(rawUri),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.strings.linkOpenFailed)));
    }
  }

  Future<void> _tapLogo() async {
    _logoTaps += 1;
    if (_logoTaps < 7) return;
    _logoTaps = 0;
    await showDialog<void>(
      context: context,
      builder: (_) => const _FridayRecoveryDialog(),
    );
  }
}

class _FridayRecoveryDialog extends StatefulWidget {
  const _FridayRecoveryDialog();

  @override
  State<_FridayRecoveryDialog> createState() => _FridayRecoveryDialogState();
}

class _FridayRecoveryDialogState extends State<_FridayRecoveryDialog> {
  var _step = 0;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final message = switch (_step) {
      0 => strings.easterEggBody,
      1 => strings.easterEggResult,
      _ => strings.easterEggComplete,
    };
    final actionLabel = _step == 0
        ? strings.easterEggScan
        : _step == 1
        ? strings.easterEggRescue
        : strings.continueLabel;
    return AlertDialog(
      icon: Icon(
        _step < 2 ? Icons.travel_explore_rounded : Icons.coffee_rounded,
      ),
      title: Text(strings.easterEggTitle),
      content: Text(message),
      actions: [
        if (_step > 0)
          TextButton(
            onPressed: () => setState(() => _step = 0),
            child: Text(strings.easterEggScan),
          ),
        FilledButton(
          onPressed: () {
            if (_step == 2) {
              Navigator.of(context).pop();
            } else {
              setState(() => _step += 1);
            }
          },
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _AboutInfo extends StatelessWidget {
  const _AboutInfo({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutActions extends StatelessWidget {
  const _AboutActions({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1) const Divider(height: 1),
        ],
      ],
    ),
  );
}

class _AboutAction extends StatelessWidget {
  const _AboutAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}
