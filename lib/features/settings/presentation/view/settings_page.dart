import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SettingsCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThemedAppBar(title: 'Settings'),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _SectionTitle('Storage'),
              const SizedBox(height: AppSpacing.sm),
              _StorageSection(state: state),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle('Safety'),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: ListTile(
                  leading: const Icon(Icons.contact_emergency_outlined),
                  title: const Text('Emergency contacts'),
                  subtitle: const Text(
                    'Manage who gets notified when you trigger SOS.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.emergencyContacts),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.slate700,
          ),
    );
  }
}

class _StorageSection extends StatelessWidget {
  final SettingsState state;
  const _StorageSection({required this.state});

  String _formatMb(int bytes) {
    final mb = bytes / 1024 / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final usedMb = state.totalUsedBytes / 1024 / 1024;
    final pctUsed = state.quotaMb == 0
        ? 0.0
        : (usedMb / state.quotaMb).clamp(0.0, 1.0);
    final overQuota = usedMb > state.quotaMb;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tile cache quota'),
                Text(
                  '${state.quotaMb} MB',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            Slider(
              min: SettingsCubit.minQuotaMb.toDouble(),
              max: SettingsCubit.maxQuotaMb.toDouble(),
              divisions:
                  (SettingsCubit.maxQuotaMb - SettingsCubit.minQuotaMb) ~/ 50,
              value: state.quotaMb
                  .clamp(SettingsCubit.minQuotaMb, SettingsCubit.maxQuotaMb)
                  .toDouble(),
              label: '${state.quotaMb} MB',
              onChanged: (v) =>
                  context.read<SettingsCubit>().previewQuota(v.round()),
              onChangeEnd: (v) =>
                  context.read<SettingsCubit>().setQuota(v.round()),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Currently using'),
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(
              value: pctUsed,
              backgroundColor: AppColors.slate100,
              valueColor: AlwaysStoppedAnimation<Color>(
                overQuota ? AppColors.error : AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${_formatMb(state.totalUsedBytes)} of ${state.quotaMb} MB',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: overQuota ? AppColors.error : AppColors.slate600,
                  ),
            ),
            if (overQuota) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Cache exceeds the configured quota. Free space by '
                'managing offline regions.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Manage offline regions',
              variant: AppButtonVariant.secondary,
              icon: Icons.layers_outlined,
              onPressed: () => context.push(Routes.offlineRegions),
            ),
          ],
        ),
      ),
    );
  }
}
