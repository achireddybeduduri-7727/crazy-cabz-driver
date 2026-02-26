import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwipeButton extends StatefulWidget {
  final String text;
  final VoidCallback onConfirm;
  final Color backgroundColor;
  final Color thumbColor;
  final Color textColor;
  final IconData icon;
  final bool isEnabled;
  final double height;
  final String confirmText;

  const SwipeButton({
    super.key,
    required this.text,
    required this.onConfirm,
    this.backgroundColor = Colors.blue,
    this.thumbColor = Colors.white,
    this.textColor = Colors.white,
    this.icon = Icons.arrow_forward,
    this.isEnabled = true,
    this.height = 60,
    this.confirmText = 'Swipe to confirm',
  });

  @override
  State<SwipeButton> createState() => _SwipeButtonState();
}

class _SwipeButtonState extends State<SwipeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _dragPosition = 0;
  bool _isConfirmed = false;
  bool _isDragging = false;

  static const double _thumbSize = 50;
  static const double _threshold = 0.8; // 80% swipe to confirm

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isEnabled || _isConfirmed) return;
    _isDragging = true;
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isEnabled || _isConfirmed) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final double maxDrag = renderBox.size.width - _thumbSize - 8;

    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });

    // Provide haptic feedback when approaching threshold
    final progress = _dragPosition / maxDrag;
    if (progress > _threshold && progress < _threshold + 0.1) {
      HapticFeedback.lightImpact();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isEnabled || _isConfirmed) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final double maxDrag = renderBox.size.width - _thumbSize - 8;
    final double progress = _dragPosition / maxDrag;

    if (progress >= _threshold) {
      // Confirmed - animate to end and trigger callback
      _confirmAction();
    } else {
      // Not confirmed - animate back to start
      _resetPosition();
    }

    _isDragging = false;
  }

  void _confirmAction() {
    setState(() {
      _isConfirmed = true;
    });

    // Haptic feedback for confirmation
    HapticFeedback.mediumImpact();

    // Animate to full width
    _animationController.forward().then((_) {
      // Trigger the callback after animation
      widget.onConfirm();

      // Reset after a short delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _resetButton();
        }
      });
    });
  }

  void _resetPosition() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _dragPosition = 0;
        });
      }
    });
  }

  void _resetButton() {
    setState(() {
      _isConfirmed = false;
      _dragPosition = 0;
    });
    _animationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.isEnabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.backgroundColor,
              widget.backgroundColor.withOpacity(0.8),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(widget.height / 2),
          boxShadow: [
            BoxShadow(
              color: widget.backgroundColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background text
            Positioned.fill(
              child: Center(
                child: AnimatedOpacity(
                  opacity: _isConfirmed ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _isDragging ? widget.confirmText : widget.text,
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Success text
            if (_isConfirmed)
              Positioned.fill(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Confirmed!',
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Progress indicator
            Positioned(
              left: 4,
              top: 4,
              bottom: 4,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final RenderBox? renderBox =
                      context.findRenderObject() as RenderBox?;
                  final double maxWidth = renderBox?.size.width ?? 0;
                  final double progressWidth = _isConfirmed
                      ? maxWidth * _animation.value
                      : _dragPosition;

                  return Container(
                    width: progressWidth,
                    decoration: BoxDecoration(
                      color: widget.backgroundColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(
                        (widget.height - 8) / 2,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Draggable thumb
            Positioned(
              left: _isConfirmed ? null : _dragPosition + 4,
              right: _isConfirmed ? 4 : null,
              top: 4,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: AnimatedContainer(
                  duration: _isDragging
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
                  width: _thumbSize,
                  height: _thumbSize,
                  decoration: BoxDecoration(
                    color: widget.thumbColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isConfirmed ? Icons.check : widget.icon,
                    color: widget.backgroundColor,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
