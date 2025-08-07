import 'package:flutter/material.dart';
import '../../../core/models/fleet_owner.dart';

class FleetInfoCard extends StatelessWidget {
  final FleetOwner fleet;
  final bool showJoinButton;
  final VoidCallback? onJoin;

  const FleetInfoCard({
    super.key,
    required this.fleet,
    this.showJoinButton = false,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildBasicInfo(),
            const SizedBox(height: 16),
            _buildStatsRow(),
            const SizedBox(height: 16),
            _buildFleetDetails(),
            if (showJoinButton && onJoin != null) ...[
              const SizedBox(height: 20),
              _buildJoinButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.business,
            color: Colors.blue[700],
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fleet.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                fleet.companyName,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final isAccepting = fleet.isAcceptingRiders;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAccepting ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isAccepting ? Colors.green[600] : Colors.red[600],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isAccepting ? 'Open' : 'Closed',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isAccepting ? Colors.green[800] : Colors.red[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      children: [
        _buildInfoRow(
          Icons.location_on,
          'Location',
          fleet.locationDisplay,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.business_center,
          'Business Type',
          fleet.businessType,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.schedule,
          'Experience',
          '${fleet.yearsInOperation} years',
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Fleet Size',
            fleet.fleetSize.toString(),
            Icons.groups,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Active Riders',
            fleet.activeRiders.toString(),
            Icons.person,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Commission',
            fleet.commissionRateDisplay,
            Icons.percent,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color[600],
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFleetDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fleet Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Fleet Type',
                  fleet.fleetTypeDisplay,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Fleet Code',
                  fleet.fleetCode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (fleet.hasCapacity)
            _buildDetailItem(
              'Available Spots',
              fleet.availableSlots > 0 
                  ? '${fleet.availableSlots} spots'
                  : 'Unlimited',
            )
          else
            _buildDetailItem(
              'Status',
              'Currently Full',
              isWarning: true,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isWarning ? Colors.orange[800] : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton() {
    final canJoin = fleet.isAcceptingRiders && fleet.hasCapacity;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canJoin ? onJoin : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: canJoin ? Colors.green[600] : Colors.grey[400],
          foregroundColor: Colors.white,
        ),
        child: Text(
          canJoin ? 'Join This Fleet' : 'Cannot Join Fleet',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}