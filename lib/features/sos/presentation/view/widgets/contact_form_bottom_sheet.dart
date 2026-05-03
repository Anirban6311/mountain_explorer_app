import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../../domain/entities/emergency_contact.dart';
import '../../../domain/utils/phone_normalizer.dart';

/// Modal bottom-sheet form for adding or editing an emergency contact.
///
/// Returns the resulting [EmergencyContact] (with empty id when adding,
/// existing id when editing) or null on cancel.
class ContactFormBottomSheet extends StatefulWidget {
  const ContactFormBottomSheet({super.key, this.initial});

  final EmergencyContact? initial;

  static Future<EmergencyContact?> show(
    BuildContext context, {
    EmergencyContact? initial,
  }) {
    return showModalBottomSheet<EmergencyContact>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ContactFormBottomSheet(initial: initial),
      ),
    );
  }

  @override
  State<ContactFormBottomSheet> createState() => _ContactFormBottomSheetState();
}

class _ContactFormBottomSheetState extends State<ContactFormBottomSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _relationship;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _name = TextEditingController(text: i?.name ?? '');
    _phone = TextEditingController(text: i?.phone ?? '');
    _relationship = TextEditingController(text: i?.relationship ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relationship.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _name.text.trim().isNotEmpty &&
      PhoneNormalizer.isValid(_phone.text);

  void _submit() {
    final normalized = PhoneNormalizer.normalize(_phone.text);
    if (normalized == null) return;
    final relationship = _relationship.text.trim();
    final contact = EmergencyContact(
      id: widget.initial?.id ?? '',
      name: _name.text.trim(),
      phone: normalized,
      relationship: relationship.isEmpty ? null : relationship,
      isPrimary: widget.initial?.isPrimary ?? false,
    );
    Navigator.of(context).pop(contact);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initial == null ? 'Add contact' : 'Edit contact',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _name,
            label: 'Name',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _phone,
            label: 'Phone (e.g. +91 9876543210)',
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _relationship,
            label: 'Relationship (optional)',
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Save',
            onPressed: _canSubmit ? _submit : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.tertiary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
