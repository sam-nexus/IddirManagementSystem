
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Chapa checkout inside the app (no external browser).
///
/// Flow:
///  1. Loads [url] (the Chapa checkout_url from the backend).
///  2. Watches every navigation. When Chapa redirects to [returnUrl]
///     (or to any URL that carries `trx_ref` / `tx_ref`), it extracts the
///     reference, stops the navigation and calls [onTxRefCaptured] ONCE.
///  3. The next screen must call the backend verify endpoint with that
///     reference. Never trust a `status` value found in the URL.
///
/// If the redirect is missed, the "I paid" button hands over
/// [expectedTxRef] (the reference of the payment we started).
class PayWebView extends StatefulWidget {
  const PayWebView({
    required this.url,
    required this.expectedTxRef,
    required this.onTxRefCaptured,
    required this.onCancelled,
    this.returnUrl,
    super.key,
  });

  /// Chapa checkout URL.
  final String url;

  /// tx_ref returned by the backend when the payment was initiated.
  final String expectedTxRef;

  /// Same value as CHAPA_RETURN_URL on the backend (optional but recommended).
  final String? returnUrl;

  final ValueChanged<String> onTxRefCaptured;
  final VoidCallback onCancelled;

  @override
  State<PayWebView> createState() => _PayWebViewState();
}

class _PayWebViewState extends State<PayWebView> {
  // Matches our references: "oda-..." / "odaa-..." (any case)
  static final RegExp _refPattern = RegExp(r'^oda{1,2}-', caseSensitive: false);

  // Only normal web pages may load inside the WebView.
  static const Set<String> _webSchemes = {'http', 'https', 'about', 'data', 'blob'};

  late final WebViewController _controller;

  bool _finished = false; // true once the reference was handed to the app
  bool _hasError = false;
  bool _warnedExternal = false;
  int _progress = 0;

  void _log(String message) {
    if (kDebugMode) debugPrint('[pay] $message');
  }

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _progress = 100);
          },

          // Catches redirects done by JavaScript inside the page.
          onUrlChange: (change) {
            final uri = Uri.tryParse(change.url ?? '');
            if (uri == null) return;
            final ref = _captureFrom(uri);
            if (ref != null) _finish(ref);
          },

          onNavigationRequest: (request) {
            _log('navigate -> ${request.url}');
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;

            // 1) Payment finished: Chapa sent us to the return URL.
            final ref = _captureFrom(uri);
            if (ref != null) {
              _finish(ref);
              return NavigationDecision.prevent;
            }

            // 2) Stay inside the app: block intent://, tel:, telebirr:// ...
            if (!_webSchemes.contains(uri.scheme.toLowerCase())) {
              _warnExternalOnce();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },

          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return; // ignore images, ads...
            _log('load error: ${error.description}');
            if (mounted) {
              setState(() {
                _hasError = true;
                _progress = 100;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  // --------------------------------------------------------------------------
  // tx_ref extraction
  // --------------------------------------------------------------------------

  /// True if [uri] is the return URL we gave to Chapa.
  bool _isReturnUrl(Uri uri) {
    final r = widget.returnUrl;
    if (r == null || r.isEmpty) return false;
    final base = Uri.tryParse(r);
    if (base == null) return false;
    return uri.scheme == base.scheme &&
        uri.host == base.host &&
        uri.path.startsWith(base.path);
  }

  /// Returns the tx_ref if this navigation means "payment page is done",
  /// otherwise null.
  String? _captureFrom(Uri uri) {
    // Chapa appends trx_ref (sometimes tx_ref) to the return URL.
    final q = uri.queryParameters;
    var ref = q['trx_ref'] ?? q['tx_ref'];

    // Fallback: the reference placed inside the URL path.
    if (ref == null || ref.isEmpty) {
      final segment = uri.pathSegments.firstWhere(
        (s) => _refPattern.hasMatch(s),
        orElse: () => '',
      );
      ref = segment.isEmpty ? null : segment;
    }

    // The return URL is the reliable signal. If the reference is missing
    // from it, use the one we started the payment with.
    if (_isReturnUrl(uri)) return ref ?? widget.expectedTxRef;

    // No return URL configured: any URL carrying our reference counts.
    final noReturnUrl = widget.returnUrl == null || widget.returnUrl!.isEmpty;
    if (noReturnUrl && ref != null) return ref;

    return null;
  }

  /// Hands the reference to the app exactly once.
  void _finish(String ref) {
    if (_finished) return;
    _finished = true;
    _log('tx_ref captured: $ref');

    if (mounted) setState(() {});

    // Run after the current navigation callback has returned.
    scheduleMicrotask(() {
      if (mounted) widget.onTxRefCaptured(ref);
    });
  }

  void _warnExternalOnce() {
    if (_warnedExternal || !mounted) return;
    _warnedExternal = true;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(context.l10n.payExternalBlocked)),
    );
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _progress = 0;
    });
    _controller.reload();
  }

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Column(
      children: [
        // Top bar: Cancel and "I paid"
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: tokens.background,
            border: Border(bottom: BorderSide(color: tokens.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.payTitle,
                  style: AppTypography.titleS.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: _finished ? null : widget.onCancelled,
                child: Text(
                  l10n.actionCancel,
                  style: AppTypography.label.copyWith(color: tokens.primary),
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                // Member says they paid: verify using the reference we started with.
                onPressed:
                    _finished ? null : () => _finish(widget.expectedTxRef),
                child: Text(
                  l10n.payIPaid,
                  style: AppTypography.label.copyWith(
                    color: tokens.primaryAction,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Thin progress line instead of a spinner on top of the page
        SizedBox(
          height: 2,
          child: (_progress < 100 && !_hasError)
              ? LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 2,
                  color: tokens.primary,
                  backgroundColor: Colors.transparent,
                )
              : null,
        ),

        // Page or error view
        Expanded(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_hasError)
                Positioned.fill(
                  child: Container(
                    color: tokens.background,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.errorNetwork,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyS.copyWith(
                            color: tokens.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextButton(
                          onPressed: _retry,
                          child: Text(
                            l10n.actionRetry,
                            style: AppTypography.label.copyWith(
                              color: tokens.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}