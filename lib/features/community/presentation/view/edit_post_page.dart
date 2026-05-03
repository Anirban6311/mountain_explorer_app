import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/usecases/community_usecases.dart';
import '../cubit/edit_post_cubit.dart';

class EditPostPage extends StatelessWidget {
  final String postId;
  const EditPostPage({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EditPostCubit>(
      create: (_) {
        final cubit = EditPostCubit(
          pId: postId,
          updatePost: getIt<UpdatePost>(),
        );
        getIt<GetPost>()(postId).then((result) {
          if (result case Success(:final value)) cubit.seedFrom(value);
        });
        return cubit;
      },
      child: const _EditPostView(),
    );
  }
}

class _EditPostView extends StatefulWidget {
  const _EditPostView();

  @override
  State<_EditPostView> createState() => _EditPostViewState();
}

class _EditPostViewState extends State<_EditPostView> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final uid = switch (authState) {
      Authenticated(:final user) => user.uid,
      _ => '',
    };
    return Scaffold(
      appBar: const ThemedAppBar(title: 'Edit post'),
      body: BlocConsumer<EditPostCubit, EditPostState>(
        listenWhen: (p, c) =>
            p.status != c.status ||
            (!_seeded && (c.title.isNotEmpty || c.description.isNotEmpty)),
        listener: (context, state) {
          if (!_seeded &&
              (state.title.isNotEmpty || state.description.isNotEmpty)) {
            _titleCtrl.text = state.title;
            _descCtrl.text = state.description;
            _seeded = true;
          }
          if (state.status == EditPostStatus.success) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text('Post updated.')));
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.feed);
            }
          } else if (state.status == EditPostStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          final cubit = context.read<EditPostCubit>();
          return LoadingOverlay(
            isLoading: state.status == EditPostStatus.submitting,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: 'Title',
                      controller: _titleCtrl,
                      onChanged: cubit.titleChanged,
                      maxLength: 80,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Description',
                      controller: _descCtrl,
                      onChanged: cubit.descriptionChanged,
                      maxLines: 6,
                      maxLength: 2000,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Save changes',
                      onPressed:
                          uid.isEmpty ? null : () => cubit.submit(uid),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
