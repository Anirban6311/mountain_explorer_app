import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../cubit/mountain_search_cubit.dart';
import '../cubit/mountain_search_state.dart';
import '../cubit/mountains_cubit.dart';
import '../cubit/mountains_state.dart';

class MountainSearchPage extends StatelessWidget {
  const MountainSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MountainSearchCubit>(
      create: (_) => getIt<MountainSearchCubit>(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatelessWidget {
  const _SearchView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThemedAppBar(title: 'Search mountains'),
      body: BlocListener<MountainsCubit, MountainsState>(
        listenWhen: (prev, curr) => curr is MountainsLoaded,
        listener: (context, state) {
          if (state is MountainsLoaded) {
            context.read<MountainSearchCubit>().setSource(state.mountains);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              AppTextField(
                label: 'Search',
                hint: 'Try "Shimla" or "adventure"',
                prefixIcon: const Icon(Icons.search),
                onChanged: (v) =>
                    context.read<MountainSearchCubit>().updateQuery(v),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: BlocBuilder<MountainSearchCubit, MountainSearchState>(
                  builder: (context, state) {
                    if (state.source.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (state.results.isEmpty) {
                      return const EmptyState(
                        message: 'No mountains match your search.',
                        icon: Icons.search_off,
                      );
                    }
                    return ListView.separated(
                      itemCount: state.results.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final m = state.results[index];
                        return AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(m.name),
                            subtitle: Text(
                              m.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
