import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EngineCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isMobile;

  const EngineCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isMobile = false,
  });

  @override
  State<EngineCard> createState() => _EngineCardState();
}

class _EngineCardState extends State<EngineCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    if (widget.isMobile) return;
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.isMobile ? double.infinity : 220.0;
    final height = widget.isMobile ? 120.0 : 260.0;
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.isMobile) _controller.forward();
        },
        onTapUp: (_) {
          if (widget.isMobile) _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () {
          if (widget.isMobile) _controller.reverse();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: width,
            height: height,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: _isHovered ? 0.4 : 0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.color.withValues(alpha: _isHovered ? 0.6 : 0.2),
                width: _isHovered ? 2.5 : 1.5,
              ),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
              ],
            ),
            child: widget.isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIcon(),
        const SizedBox(height: 20),
        _buildTexts(),
        const Spacer(),
        _buildClickIndicator(),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Row(
      children: [
        _buildIcon(),
        const SizedBox(width: 20),
        Expanded(child: _buildTexts()),
        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white24),
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        boxShadow: _isHovered
            ? [BoxShadow(color: widget.color.withValues(alpha: 0.2), blurRadius: 10)]
            : null,
      ),
      child: Icon(widget.icon, color: widget.color, size: widget.isMobile ? 36 : 50),
    );
  }

  Widget _buildTexts() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge!.color,
            fontWeight: FontWeight.w900,
            fontSize: widget.isMobile ? 20 : 24,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: widget.isMobile ? 4 : 8),
        Text(
          widget.subtitle,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5),
            fontSize: 13,
            letterSpacing: 1,
          ),
          textAlign: widget.isMobile ? TextAlign.left : TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildClickIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: _isHovered ? 0.15 : 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.color.withValues(alpha: _isHovered ? 0.3 : 0.1)),
      ),
      child: Text(
        'click_to_start'.tr,
        style: TextStyle(color: widget.color.withValues(alpha: _isHovered ? 1.0 : 0.7), fontSize: 11),
      ),
    );
  }
}
