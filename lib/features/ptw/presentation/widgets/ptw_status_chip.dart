import 'package:flutter/material.dart';
import '../../domain/enums/ptw_status.dart';
import '../../domain/enums/high_risk_type.dart';

/// Colored status badge chip for Permit to Work lifecycle state
class PtwStatusChip extends StatelessWidget {
  final PtwStatus status;
  final bool isCompact;
  final bool showIcon;
  final double fontSize;

  const PtwStatusChip({
    super.key,
    required this.status,
    this.isCompact = false,
    this.showIcon = true,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: status.badgeBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: status.badgeColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(status.icon, size: fontSize + 3, color: status.badgeColor),
            SizedBox(width: isCompact ? 4 : 6),
          ],
          Text(
            isCompact ? status.shortLabelTh : status.labelTh,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: status.badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Colored badge chip for High-Risk Operation Work Types
class HighRiskTypeChip extends StatelessWidget {
  final HighRiskType riskType;
  final bool isCompact;
  final bool showIcon;
  final double fontSize;

  const HighRiskTypeChip({
    super.key,
    required this.riskType,
    this.isCompact = false,
    this.showIcon = true,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: riskType.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: riskType.color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(riskType.icon, size: fontSize + 3, color: riskType.color),
            SizedBox(width: isCompact ? 4 : 6),
          ],
          Text(
            isCompact ? riskType.shortLabelTh : riskType.labelTh,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: riskType.color,
            ),
          ),
        ],
      ),
    );
  }
}
