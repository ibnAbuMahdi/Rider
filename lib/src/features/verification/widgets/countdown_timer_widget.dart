import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CountdownTimerWidget extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onTimeout;
  final TextStyle? textStyle;

  const CountdownTimerWidget({
    super.key,
    required this.duration,
    this.onTimeout,
    this.textStyle,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds <= 0) {
        timer.cancel();
        widget.onTimeout?.call();
      } else {
        setState(() {
          _remaining = Duration(seconds: _remaining.inSeconds - 1);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    final isUrgent = _remaining.inMinutes < 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.error : AppColors.warning,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: widget.textStyle ?? const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}