import 'package:flutter/material.dart';

class DashboardAreaCoverageHeatmap extends StatelessWidget {
  const DashboardAreaCoverageHeatmap({super.key});

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
                  'Area Coverage Heatmap',
                  style: TextStyle(
                    color: Color(0xFF2D2D2D),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View Full Map',
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
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_pin,
                    color: Color(0xFF8B7355),
                    size: 40,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Interactive heatmap showing\nissue density in your area',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6B6B6B),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDistrictProgress('District 5A', 0.93),
                const SizedBox(height: 8),
                _buildDistrictProgress('District 5B', 0.92),
                const SizedBox(height: 8),
                _buildDistrictProgress('District 5C', 0.76),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictProgress(String district, double progress) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            district,
            style: const TextStyle(
              color: Color(0xFF2D2D2D),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFE8E6E1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B7355)),
            minHeight: 6,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(progress * 100).toInt()}%',
          style: const TextStyle(
            color: Color(0xFF6B6B6B),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
