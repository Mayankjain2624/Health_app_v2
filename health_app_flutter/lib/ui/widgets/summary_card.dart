import 'package:flutter/material.dart';
import '../../models/step_summary.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatelessWidget {
  final StepSummary? summary;
  final DateTime lastSynced;
  final VoidCallback onRefresh;

  const SummaryCard({
    super.key,
    required this.summary,
    required this.lastSynced,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, y');
    final tf = DateFormat('hh:mm a');
    final steps = summary?.steps ?? 0;
    final goalSteps = 10000;
    final progress = (steps / goalSteps).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.all(16),
      color: const Color(0xFF1E1E1E),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E1E1E),
              const Color(0xFF1E1E1E).withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daily Summary',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: const Color(
                          0xFF1976D2,
                        ).withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00BCD4),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$steps',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64B5F6),
                          ),
                        ),
                        const Text(
                          'Steps',
                          style: TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.1)),
                    bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      label: 'Goal',
                      value: '$goalSteps',
                      icon: Icons.adjust,
                    ),
                    _buildStatItem(
                      label: 'Progress',
                      value: '${(progress * 100).toStringAsFixed(0)}%',
                      icon: Icons.trending_up,
                    ),
                    _buildStatItem(
                      label: 'Date',
                      value: summary != null
                          ? DateFormat('M/d').format(summary!.date)
                          : '-',
                      icon: Icons.calendar_today,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Last synced: ${tf.format(lastSynced)}',
                style: const TextStyle(
                  color: Color(0xFF80D8FF),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text(
                    'Refresh Data',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00BCD4), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFFB0B0B0),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
