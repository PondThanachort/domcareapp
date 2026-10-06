import 'dart:math';

import 'package:flutter/material.dart';

import 'create_request_page.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Map<int, String> _greetings = {
    0: 'สวัสดีครับ',
    1: 'ยินดีต้อนรับกลับ',
    2: 'วันนี้เป็นอย่างไรบ้าง',
    3: 'ขอให้เป็นวันที่ดี',
    4: 'พร้อมให้เราช่วยดูแล',
  };

  late final String _greeting;

  @override
  void initState() {
    super.initState();
    _greeting = _greetings[Random().nextInt(_greetings.length)]!;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        Row(
          children: [
            const CircleAvatar(radius: 24, child: Icon(Icons.person_rounded)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AuthScope.userOf(context)?.displayName ?? 'สมชาย ใจดี',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'ห้อง ${AuthScope.userOf(context)?.room ?? '305'}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _NewRequestCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CreateRequestPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NewRequestCard extends StatelessWidget {
  const _NewRequestCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_request_room.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              excludeFromSemantics: true,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: dark
                      ? [
                          const Color(0xF21C1C1F),
                          const Color(0x991C1C1F),
                          const Color(0x331C1C1F),
                        ]
                      : [
                          const Color(0xF2F7F5F0),
                          const Color(0xCCF7F5F0),
                          const Color(0x00F7F5F0),
                        ],
                  stops: const [0, 0.55, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ต้องการแจ้งเรื่อง?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                FractionallySizedBox(
                  widthFactor: 0.72,
                  child: Text(
                    'แจ้งซ่อม ทำความสะอาด ย้ายออก หรือเหตุฉุกเฉินได้ที่นี่',
                    style: TextStyle(
                      color: dark
                          ? const Color(0xFFF0F0F2)
                          : const Color(0xFF38383D),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text('แจ้งปัญหาใหม่'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    backgroundColor: dark
                        ? const Color(0xFFB7DDCA)
                        : const Color(0xFF246450),
                    foregroundColor: dark
                        ? const Color(0xFF153C2F)
                        : Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
