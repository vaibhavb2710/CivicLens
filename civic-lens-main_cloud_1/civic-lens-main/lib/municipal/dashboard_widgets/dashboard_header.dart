import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final String officerName;
  final int pendingCount;
  final int activeCount;
  final VoidCallback onViewTasks;

  const DashboardHeader({
    super.key,
    required this.officerName,
    required this.pendingCount,
    required this.activeCount,
    required this.onViewTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Area 5A',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E6E1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Color(0xFF6B6B6B),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '6h 23m left',
                    style: TextStyle(
                      color: Color(0xFF6B6B6B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Good evening, $officerName',
          style: const TextStyle(
            color: Color(0xFF2D2D2D),
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You have $pendingCount pending tasks and $activeCount active tasks across Districts 5A-5C today.',
          style: const TextStyle(
            color: Color(0xFF6B6B6B),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E6E1)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Color(0xFF8B7355),
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'Tuesday, September 9, 2025',
                style: TextStyle(
                  color: Color(0xFF2D2D2D),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 24),
              const Icon(
                Icons.schedule,
                color: Color(0xFF8B7355),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Shift: 8:00 AM - 4:00 PM',
                style: TextStyle(
                  color: Color(0xFF2D2D2D),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onViewTasks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B7355),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Tasks',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
