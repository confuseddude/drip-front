import 'theme_bar.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/drip_skin.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/drip_image.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/tap.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/settings.dart';
import '../../routing/main_shell.dart';
import '../session/reset_app_state.dart';
import '../session/session_controller.dart';
import '../social/social_controller.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _userRe = RegExp(r'^[a-z0-9_.]{3,20}$');

  Future<String?> _textSheet(
    BuildContext context, {
    required String title,
    required String initial,
    required String? Function(String) validate,
    String hint = '',
    TextInputType? keyboard,
    String prefix = '',
  }) {
    final c = TextEditingController(text: initial);
    String? error;
    return showDripSheet<String>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          void submit() {
            final v = c.text.trim();
            final e = validate(v);
            if (e != null) {
              setSheet(() => error = e);
              return;
            }
            Navigator.of(ctx).pop(v);
          }

          return SheetContent(
            title: title,
            children: [
              DripField(
                controller: c,
                hint: hint,
                radius: 14,
                autofocus: true,
                keyboardType: keyboard,
                errorText: error,
                onSubmitted: (_) => submit(),
                leading: prefix.isEmpty
                    ? null
                    : Text(
                        prefix,
                        style: AppText.mono(13, color: AppColors.cyan),
                      ),
              ),
              const SizedBox(height: 14),
              AppButton(label: 'SAVE', height: 44, onPressed: submit),
            ],
          );
        },
      ),
    ).whenComplete(c.dispose);
  }

  Future<T?> _pick<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required T current,
    required String Function(T) label,
  }) {
    return showDripSheet<T>(
      context,
      builder: (ctx) => SheetContent(
        title: title,
        children: [
          for (final o in options)
            Tap(
              onTap: () => Navigator.of(ctx).pop(o),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.elevated)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label(o),
                        style: AppText.manrope(14, weight: FontWeight.w500),
                      ),
                    ),
                    if (o == current)
                      Text(
                        '✓',
                        style: AppText.mono(14, color: ctx.palette.accent),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    String? error;
    final ok = await showDripSheet<bool>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SheetContent(
          title: 'CHANGE PASSWORD',
          children: [
            DripField(
              controller: current,
              hint: 'Current password',
              radius: 14,
              obscureText: true,
            ),
            const SizedBox(height: 10),
            DripField(
              controller: next,
              hint: 'New password (8+ characters)',
              radius: 14,
              obscureText: true,
            ),
            const SizedBox(height: 10),
            DripField(
              controller: confirm,
              hint: 'Confirm new password',
              radius: 14,
              obscureText: true,
              errorText: error,
            ),
            const SizedBox(height: 14),
            AppButton(
              label: 'UPDATE PASSWORD',
              height: 44,
              onPressed: () {
                String? e;
                if (current.text.isEmpty) {
                  e = 'Enter your current password';
                } else if (next.text.length < 8) {
                  e = 'New password needs at least 8 characters';
                } else if (next.text != confirm.text) {
                  e = 'Passwords don\'t match';
                } else if (next.text == current.text) {
                  e = 'Choose a different password';
                }
                if (e != null) {
                  setSheet(() => error = e);
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
            ),
          ],
        ),
      ),
    );
    current.dispose();
    next.dispose();
    confirm.dispose();
    if (ok == true && context.mounted) {
      showDripToast(context, 'Password saved — applies once accounts go live');
    }
  }

  Future<void> _connected(BuildContext context) {
    return showDripSheet<void>(
      context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final connected = ref.watch(connectedAccountsProvider);
          return SheetContent(
            title: 'CONNECTED ACCOUNTS',
            children: [
              for (final name in const ['Discord', 'Spotify', 'Instagram'])
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.elevated),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppText.manrope(14, weight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        connected.contains(name) ? 'LINKED' : 'NOT LINKED',
                        style: AppText.mono(
                          9,
                          color: connected.contains(name)
                              ? AppColors.cyan
                              : AppColors.muted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      DripSwitch(
                        value: connected.contains(name),
                        onChanged: (_) => ref
                            .read(connectedAccountsProvider.notifier)
                            .toggle(name),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final me = ref.watch(myProfileProvider).value;
    final connected = ref.watch(connectedAccountsProvider).toList()..sort();

    Widget row(
      String label, {
      String? value,
      Widget? trailing,
      VoidCallback? onTap,
      bool last = false,
    }) => _Row(
      label: label,
      value: value,
      trailing: trailing,
      onTap: onTap,
      last: last,
    );

    return ShellPage(
      child: Column(
        children: [
          DripTopBar(
            title: 'SETTINGS',
            height: 56,
            leading: BackGlyph(
              onTap: () => context.canPop() ? context.pop() : context.go('/me'),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const _Section('01 · ACCOUNT'),
                _Group(
                  children: [
                    Tap(
                      onTap: () => context.go('/me'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.cream.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.cyan,
                                  width: 1.5,
                                ),
                              ),
                              child: ClipOval(
                                child: me == null
                                    ? ColoredBox(color: AppColors.elevated)
                                    : DripImage(me.avatar),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    me?.name ?? 'Taylor Vance',
                                    style: AppText.display(14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Verified AI Stylist',
                                    style: AppText.mono(
                                      11,
                                      color: AppColors.cyan,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    row(
                      'Username',
                      value: '@${s.username}',
                      onTap: () async {
                        final v = await _textSheet(
                          context,
                          title: 'USERNAME',
                          initial: s.username,
                          hint: 'taylor_drip',
                          prefix: '@',
                          validate: (v) => _userRe.hasMatch(v) ? null : '3–20 characters: lowercase letters, numbers, . or _',
                        );
                        if (v != null) {
                          await notifier.setUsername(v);
                          await ref
                              .read(myProfileProvider.notifier)
                              .saveProfile(handle: v);
                          if (context.mounted) {
                            showDripToast(context, 'Username updated');
                          }
                        }
                      },
                    ),
                    row(
                      'Email',
                      value: s.email,
                      onTap: () async {
                        final v = await _textSheet(
                          context,
                          title: 'EMAIL',
                          initial: s.email,
                          hint: 'you@drip.design',
                          keyboard: TextInputType.emailAddress,
                          validate: (v) => _emailRe.hasMatch(v)
                              ? null
                              : 'Enter a valid email address',
                        );
                        if (v != null) {
                          await notifier.setEmail(v);
                          if (context.mounted) {
                            showDripToast(context, 'Email updated');
                          }
                        }
                      },
                    ),
                    row(
                      'Change Password',
                      last: true,
                      onTap: () => _changePassword(context),
                    ),
                  ],
                ),
                const _Section('02 · PRIVACY'),
                _Group(
                  children: [
                    row(
                      'Private Account',
                      trailing: DripSwitch(
                        value: s.privateAccount,
                        onChanged: notifier.setPrivate,
                      ),
                    ),
                    row(
                      'Who Can Interact',
                      value: s.whoCanInteract.label,
                      onTap: () async {
                        final v = await _pick(
                          context,
                          title: 'WHO CAN INTERACT',
                          options: InteractAudience.values,
                          current: s.whoCanInteract,
                          label: (o) => o.label,
                        );
                        if (v != null) await notifier.setWhoCanInteract(v);
                      },
                    ),
                    row(
                      'OOTD Visibility',
                      value: s.ootdVisibility.label,
                      last: true,
                      onTap: () async {
                        final v = await _pick(
                          context,
                          title: 'OOTD VISIBILITY',
                          options: OotdVisibility.values,
                          current: s.ootdVisibility,
                          label: (o) => o.label,
                        );
                        if (v != null) await notifier.setOotdVisibility(v);
                      },
                    ),
                  ],
                ),
                const _Section('03 · APPEARANCE'),
                _Group(
                  children: [
                    row(
                      'Themes',
                      value: s.skin.label,
                      onTap: () => context.push('/themes'),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: ThemeBar(),
                    ),
                    row(
                      'Match App Icon to Theme',
                      trailing: DripSwitch(
                        value: s.matchAppIcon,
                        onChanged: notifier.setMatchAppIcon,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        'Your home-screen icon updates the next time you leave the app.',
                        style: AppText.manrope(11, color: AppColors.muted),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SKIN COLOR DNA',
                            style: AppText.mono(11, color: AppColors.muted),
                          ),
                          _Swatches(skin: s.skin, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
                const _Section('04 · NOTIFICATIONS & DEV'),
                _Group(
                  children: [
                    row(
                      'Push Notifications',
                      trailing: DripSwitch(
                        value: s.pushNotifications,
                        onChanged: notifier.setPush,
                      ),
                    ),
                    row(
                      'Style Match Alerts',
                      trailing: DripSwitch(
                        value: s.styleMatchAlerts,
                        onChanged: notifier.setStyleAlerts,
                      ),
                    ),
                    row(
                      'Connected Accounts',
                      value: connected.isEmpty ? 'None' : connected.join(', '),
                      last: true,
                      onTap: () => _connected(context),
                    ),
                  ],
                ),
                const _Section('05 · INFO'),
                _Group(
                  children: [
                    row(
                      'About DRIP',
                      value: 'v1.0.77',
                      onTap: () {
                        showDripSheet<void>(
                          context,
                          builder: (_) => SheetContent(
                            title: 'ABOUT DRIP',
                            subtitle: 'v1.0.77 · ESTD 2077',
                            children: [
                              Text(
                                'Drip is the outfit-of-the-day network: scroll editorial looks, save them to your vault, build fits in the Studio and let Taylor style you for any occasion.',
                                style: AppText.manrope(
                                  13,
                                  color: AppColors.muted,
                                  lineHeight: 19,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    row(
                      'Privacy & Terms',
                      last: true,
                      onTap: () {
                        showDripSheet<void>(
                          context,
                          builder: (_) => SheetContent(
                            title: 'PRIVACY & TERMS',
                            children: [
                              Text(
                                'Your fits, wardrobe and searches stay on your account. Private accounts only share content with approved followers. You can delete your data at any time from this screen.',
                                style: AppText.manrope(
                                  13,
                                  color: AppColors.muted,
                                  lineHeight: 19,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: AppButton(
                    label: 'LOG OUT OF DRIP',
                    style: AppButtonStyle.danger,
                    height: 52,
                    onPressed: () async {
                      final ok = await showDripConfirm(
                        context,
                        title: 'LOG OUT?',
                        message: 'You\'ll need to sign in again to see your feed and wardrobe.',
                        confirmLabel: 'LOG OUT',
                        destructive: true,
                      );
                      if (!ok) return;
                      await ref.read(sessionProvider.notifier).logout();
                      resetAppState(ref);
                      if (context.mounted) context.go('/welcome');
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
    child: SectionLabel(text),
  );
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 2),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20 * context.palette.roundness),
        border: Border.all(color: AppColors.cream.withValues(alpha: 0.08)),
      ),
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.last = false,
  });
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      scale: 1,
      child: Container(
        margin: const EdgeInsets.only(left: 16),
        padding: const EdgeInsets.fromLTRB(0, 12, 14, 12),
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(
                  bottom: BorderSide(
                    color: AppColors.cream.withValues(alpha: 0.07),
                  ),
                ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppText.manrope(14, weight: FontWeight.w500),
              ),
            ),
            if (value != null) ...[
              Flexible(
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.mono(12, color: AppColors.muted),
                ),
              ),
            ],
            if (trailing != null)
              trailing!
            else if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.dim,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches({required this.skin, required this.size});
  final DripSkin skin;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.base,
      AppColors.surface,
      skin.accent,
      skin.secondary,
      AppColors.cream,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, c) in colors.indexed)
          Container(
            width: size,
            height: size,
            margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: i == 0 ? Border.all(color: AppColors.elevated) : null,
            ),
          ),
      ],
    );
  }
}
