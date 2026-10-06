import 'package:flutter/material.dart';

class FloatingPillNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<(IconData, String)> items;

  const FloatingPillNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = const [
      (Icons.home_rounded, 'หน้าแรก'),
      (Icons.receipt_long_rounded, 'คำร้อง'),
      (Icons.person_rounded, 'โปรไฟล์'),
    ],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white : const Color(0xFF111113),
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.16),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = i == currentIndex;
            final fg = isDark ? const Color(0xFF111113) : Colors.white;
            final muted = isDark
                ? const Color(0xFF7D7D82)
                : const Color(0xFFA8A8AF);

            return Expanded(
              flex: items.length > 3 && selected ? 2 : 1,
              child: Semantics(
                label: items[i].$2,
                selected: selected,
                button: true,
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(26),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? (isDark
                                ? const Color(0xFFE9E9EB)
                                : const Color(0xFF2A2A2D))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[i].$1,
                          size: 23,
                          color: selected ? fg : muted,
                        ),
                        Flexible(
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: selected
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      items[i].$2,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: fg,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
