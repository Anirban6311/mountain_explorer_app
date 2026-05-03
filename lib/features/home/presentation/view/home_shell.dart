import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../community/presentation/cubit/feed_cubit.dart';
import '../../../community/presentation/view/feed_page.dart';
import '../../../mountains/presentation/cubit/mountains_cubit.dart';
import '../../../mountains/presentation/view/mountains_page.dart';
import '../../../offline_maps/presentation/cubit/offline_maps_cubit.dart';
import '../../../offline_maps/presentation/view/offline_maps_page.dart';
import '../../../sos/presentation/cubit/sos_cubit.dart';
import '../../../sos/presentation/view/widgets/sos_fab.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import 'home_tab.dart';
import 'profile_page.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthCubit>();
    final mountains = getIt<MountainsCubit>();
    final uid = switch (auth.state) {
      Authenticated(:final user) => user.uid,
      NeedsVerification(:final user) => user.uid,
      _ => '',
    };
    // H5 guard: skip load on cold-start deep links where the AuthCubit
    // hasn't resolved yet. AuthCubit stream emissions will trigger loading
    // when a real uid arrives.
    if (uid.isNotEmpty) mountains.load(uid: uid);
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeCubit>(create: (_) => HomeCubit()),
        BlocProvider<MountainsCubit>.value(value: mountains),
        BlocProvider<FeedCubit>.value(value: getIt<FeedCubit>()),
        BlocProvider<OfflineMapsCubit>(
          create: (_) => getIt<OfflineMapsCubit>(),
        ),
        BlocProvider<SosCubit>.value(value: getIt<SosCubit>()),
      ],
      child: const _ShellView(),
    );
  }
}

class _ShellView extends StatelessWidget {
  const _ShellView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final label = switch (state.tabIndex) {
          1 => 'Mountains',
          2 => 'Map',
          3 => 'Community',
          4 => 'Profile',
          _ => 'Mountain Explorer',
        };
        // Android back button: on a non-Home tab, land on Home first;
        // only exit the app when already on Home. iOS has no system back
        // here — the shell is the root auth destination.
        return PopScope(
          canPop: state.tabIndex == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            context.read<HomeCubit>().selectTab(0);
          },
          child: Scaffold(
            appBar: state.tabIndex == 0 ? ThemedAppBar(title: label) : null,
            drawer: const _HomeDrawer(),
            floatingActionButton:
                state.tabIndex < 3 ? const SosFab() : null,
            body: IndexedStack(
              index: state.tabIndex,
              children: const [
                HomeTab(),
                MountainsPage(),
                OfflineMapsPage(),
                FeedPage(),
                ProfilePage(),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: state.tabIndex,
              onDestinationSelected: context.read<HomeCubit>().selectTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.landscape_outlined),
                  selectedIcon: Icon(Icons.landscape),
                  label: 'Mountains',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Map',
                ),
                NavigationDestination(
                  icon: Icon(Icons.forum_outlined),
                  selectedIcon: Icon(Icons.forum),
                  label: 'Community',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Forest-canopy header band — same green as the AppBar so the
          // drawer feels like a continuation of the chrome above it.
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              MediaQuery.of(context).padding.top + AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.terrain,
                  color: AppColors.onPrimary,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Mountain Explorer',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.of(context).pop();
                context.read<HomeCubit>().selectTab(4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('Liked mountains'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.likedMountains);
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist_outlined),
              title: const Text('Checklist'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.checklist);
              },
            ),
            ListTile(
              leading: const Icon(Icons.layers_outlined),
              title: const Text('Offline regions'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.offlineRegions);
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_emergency_outlined),
              title: const Text('Emergency contacts'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.emergencyContacts);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.settings);
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Log out'),
              onTap: () {
                Navigator.of(context).pop();
                context.read<AuthCubit>().signOut();
              },
            ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

