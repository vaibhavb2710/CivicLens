import 'package:flutter/material.dart';

class DashboardPerformanceOverview extends StatelessWidget {
  const DashboardPerformanceOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E6E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weekly Performance Overview',
                  style: TextStyle(
                    color: Color(0xFF2D2D2D),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      color: Color(0xFF8B7355),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(child: _buildPerformanceMetric('Tasks Completed', '47/52', '+8% from last week', Colors.green, Icons.trending_up)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildPerformanceMetric('Citizen Satisfaction', '4.8/5', 'Based on 23 ratings', Colors.blue, Icons.people)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildPerformanceMetric('Avg Response Time', '2.4h', '-15min from target', Colors.orange, Icons.schedule)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildPerformanceMetric('Tasks Completed', '47/52', '+8% from last week', Colors.green, Icons.trending_up),
                      const SizedBox(height: 16),
                      _buildPerformanceMetric('Citizen Satisfaction', '4.8/5', 'Based on 23 ratings', Colors.blue, Icons.people),
                      const SizedBox(height: 16),
                      _buildPerformanceMetric('Avg Response Time', '2.4h', '-15min from target', Colors.orange, Icons.schedule),
                    ],
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B6B6B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B6B6B),
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
