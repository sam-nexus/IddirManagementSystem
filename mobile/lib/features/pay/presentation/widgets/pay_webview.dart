import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// On web, Chapa checkout opens in a new tab.
class PayWebView extends StatelessWidget {
  const PayWebView({
    required this.url,
    required this.onClosed,
    super.key,
  });

  final String url;
  final VoidCallback onClosed;

  @override
  Widget build(BuildContext context) {
    // Auto-open and immediately show a waiting UI.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    });

    return _WaitingPanel(onClosed: onClosed);
  }
}

class _WaitingPanel extends StatelessWidget {
  const _WaitingPanel({required this.onClosed});

  final VoidCallback onClosed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Complete the payment in the new tab, then come back here.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onClosed,
              child: const Text('I have paid'),
            ),
          ],
        ),
      ),
    );
  }
}