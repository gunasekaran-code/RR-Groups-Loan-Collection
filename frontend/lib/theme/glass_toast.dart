import 'dart:ui';
import 'package:flutter/material.dart';

enum ToastType { success, warning, info, error }

class _ToastStyle {
  final Color color;
  final IconData icon;
  const _ToastStyle(this.color, this.icon);
}

const Map<ToastType, _ToastStyle> _styles = {
  ToastType.success: _ToastStyle(Color(0xFF34C759), Icons.check_circle_rounded), // iOS System Green
  ToastType.warning: _ToastStyle(Color(0xFFFF9500), Icons.warning_rounded),      // iOS System Orange
  ToastType.info: _ToastStyle(Color(0xFF007AFF), Icons.info_rounded),            // iOS System Blue
  ToastType.error: _ToastStyle(Color(0xFFFF3B30), Icons.error_rounded),          // iOS System Red
};

class ToastService {
  ToastService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static OverlayEntry? _current;
  static _iOSToastOverlayState? _currentState;

  static void show({
    required String title,
    String? message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _currentState?.dismissImmediately();
    _current?.remove();
    _current = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _iOSToastOverlay(
        title: title,
        message: message,
        type: type,
        duration: duration,
        onAttach: (state) => _currentState = state,
        onDismiss: () {
          entry.remove();
          if (_current == entry) {
            _current = null;
            _currentState = null;
          }
        },
      ),
    );

    _current = entry;
    overlayState.insert(entry);
  }

  static void dismiss() {
    _currentState?.dismissImmediately();
  }
}

class _iOSToastOverlay extends StatefulWidget {
  final String title;
  final String? message;
  final ToastType type;
  final Duration duration;
  final ValueChanged<_iOSToastOverlayState> onAttach;
  final VoidCallback onDismiss;

  const _iOSToastOverlay({
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
    required this.onAttach,
    required this.onDismiss,
  });

  @override
  State<_iOSToastOverlay> createState() => _iOSToastOverlayState();
}

class _iOSToastOverlayState extends State<_iOSToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    widget.onAttach(this);
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240), // Snappy iOS transition speed
    );
    
    // Left-to-right animation transition
    _slide = Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) _dismiss();
    });
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  void dismissImmediately() => _dismiss();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _styles[widget.type]!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: bottomPadding + 85, // Perfectly balanced above standard bottom navigation bars
      left: 16,
      right: 16,
      child: SafeArea(
        top: false,
        bottom: false,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Material(
              color: Colors.transparent,
              child: Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.horizontal,
                onDismissed: (_) => widget.onDismiss(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14), // Classic iOS squircle radius
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Subtle iOS backdrop transparency blur
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.96), // Premium crisp white with faint transparency
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.06), // Ultra-fine iOS border definition
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08), // Soft, high-dispersion Apple-style shadow
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Left indicator bar matching iOS notification designs
                          Container(
                            width: 4,
                            height: 32,
                            decoration: BoxDecoration(
                              color: style.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            style.icon,
                            color: style.color,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600, // Semi-bold matching San Francisco typography
                                    fontSize: 15,
                                    color: Color(0xFF1C1C1E), // Apple System Dark Text
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                if (widget.message != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.message!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF8E8E93), // Apple System Gray description text
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _dismiss,
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Color(0xFFAEAEB2), // Muted secondary close option
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}