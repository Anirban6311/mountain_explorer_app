import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/create_post_cubit.dart';

class CreatePostPage extends StatelessWidget {
  const CreatePostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreatePostCubit>(
      create: (_) => getIt<CreatePostCubit>(),
      child: const _CreatePostView(),
    );
  }
}

class _CreatePostView extends StatelessWidget {
  const _CreatePostView();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = switch (authState) {
      Authenticated(:final user) => user,
      _ => null,
    };
    return Scaffold(
      appBar: const ThemedAppBar(title: 'New post'),
      body: BlocConsumer<CreatePostCubit, CreatePostState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) {
          if (state.status == CreatePostStatus.success) {
            ScaffoldMessenger.of(context)
              ..showSnackBar(const SnackBar(content: Text('Post published!')));
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.feed);
            }
          } else if (state.status == CreatePostStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          final cubit = context.read<CreatePostCubit>();
          return LoadingOverlay(
            isLoading: state.status == CreatePostStatus.submitting,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ImagePreview(
                      imagePath: state.draft.imagePath,
                      onPick: () => _pickImage(cubit),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Title',
                      onChanged: cubit.titleChanged,
                      maxLength: 80,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Description',
                      onChanged: cubit.descriptionChanged,
                      maxLines: 6,
                      maxLength: 2000,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Publish',
                      onPressed: user == null
                          ? null
                          : () => cubit.submit(
                                uid: user.uid,
                                uEmail: user.email ?? '',
                                uName: user.displayName ?? 'Explorer',
                              ),
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

  Future<void> _pickImage(CreatePostCubit cubit) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (picked == null) return;
    cubit.imageChanged(picked.path);
  }
}

class _ImagePreview extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onPick;
  const _ImagePreview({this.imagePath, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: imagePath == null
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo, size: 36),
                        SizedBox(height: 8),
                        Text('Tap to pick an image'),
                      ],
                    ),
                  ),
                )
              : Image.file(File(imagePath!), fit: BoxFit.cover),
        ),
      ),
    );
  }
}
