import 'package:flutter/material.dart';

class DemoRegionPromptDialog extends StatelessWidget {
  const DemoRegionPromptDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Download Kangchenjunga demo region?'),
      content: const Text(
        'Mountain Explorer can cache tiles around Kangchenjunga '
        '(zoom 10–14, roughly 40 MB) so the map works without internet on '
        'your next trek. You can delete the region from settings anytime.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop<bool>(false),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop<bool>(true),
          child: const Text('Allow'),
        ),
      ],
    );
  }
}
