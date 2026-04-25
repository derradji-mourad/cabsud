import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cabsudapp/reuse/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────────────────────────────────────

enum ReservationType { quickTrip, service }

class UserReservation {
  final String id;
  final ReservationType type;
  final String pickupAddress;
  final String? dropoffAddress;
  /// Primary date used for sorting — services.datetime, falls back to created_at.
  final DateTime sortDate;
  final DateTime? scheduledDate;
  final String status;
  final String? vehicleType;
  final double? price;
  final double? distanceKm;
  final double? durationMin;
  final String? serviceType;
  final bool? isCash;
  final String? passengerName;

  const UserReservation({
    required this.id,
    required this.type,
    required this.pickupAddress,
    this.dropoffAddress,
    required this.sortDate,
    this.scheduledDate,
    required this.status,
    this.vehicleType,
    this.price,
    this.distanceKm,
    this.durationMin,
    this.serviceType,
    this.isCash,
    this.passengerName,
  });

  factory UserReservation._fromServicesRow(Map<String, dynamic> row) {
    final isQuickTrip = row['is_quick_trip'] == true;

    DateTime? scheduledDate;
    final rawDt = row['datetime'];
    if (rawDt is String) scheduledDate = DateTime.tryParse(rawDt);

    DateTime? createdAt;
    final rawCa = row['created_at'];
    if (rawCa is String) createdAt = DateTime.tryParse(rawCa);

    final firstName = (row['firstname'] as String? ?? '').trim();
    final lastName = (row['lastname'] as String? ?? '').trim();
    final name = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

    return UserReservation(
      id: row['id'].toString(),
      type: isQuickTrip ? ReservationType.quickTrip : ReservationType.service,
      pickupAddress: row['pickuplocation'] as String? ?? '',
      dropoffAddress: row['dropofflocation'] as String?,
      sortDate: scheduledDate ?? createdAt ?? DateTime.now(),
      scheduledDate: scheduledDate,
      // services table has no status column — every persisted record is confirmed
      status: 'confirmed',
      vehicleType: row['vehicle_type'] as String?,
      price: (row['total_fare'] as num?)?.toDouble(),
      distanceKm: (row['distance_km'] as num?)?.toDouble(),
      durationMin: (row['duration_min'] as num?)?.toDouble(),
      serviceType: row['servicetype'] as String?,
      isCash: row['is_cash'] as bool?,
      passengerName: name.isEmpty ? null : name,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REPOSITORY
//
//  SCHEMA NOTE — quick_trips has no user_id column:
//  The quick_service edge function sends a JWT but never stores auth.uid() in
//  the quick_trips row.  There is no safe way to filter quick_trips by user
//  from the client side.
//
//  Two safe options exist:
//   A) Add a column:
//        ALTER TABLE quick_trips ADD COLUMN user_id uuid REFERENCES auth.users(id);
//      Then update the quick_service edge function to set
//        user_id = (select auth.uid())
//      before the INSERT.
//
//   B) If the quick_service edge function also writes to the services table
//      (with is_quick_trip = true), those records already appear here because
//      services.user_id is populated. Use that column as the indicator.
//
//  Until option A or B is confirmed, only services records are shown.
// ─────────────────────────────────────────────────────────────────────────────

List<UserReservation> _parseRows(List<dynamic> rows) {
  final list = rows
      .map((row) =>
          UserReservation._fromServicesRow(Map<String, dynamic>.from(row as Map)))
      .toList()
    ..sort((a, b) => b.sortDate.compareTo(a.sortDate));
  return list;
}

class _ReservationRepository {
  final _client = Supabase.instance.client;

  Future<List<UserReservation>> fetchForCurrentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('services')
        .select(
          'id, pickuplocation, dropofflocation, datetime, created_at, '
          'servicetype, vehicle_type, is_cash, total_fare, '
          'distance_km, duration_min, is_quick_trip, firstname, lastname',
        )
        .eq('user_id', userId)
        .order('datetime', ascending: false) as List<dynamic>;

    return compute(_parseRows, rows);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────────────────────────────────────

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage>
    with SingleTickerProviderStateMixin {
  final _repo = _ReservationRepository();
  List<UserReservation> _reservations = [];
  bool _loading = true;
  String? _error;
  late final AnimationController _enter;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _repo.fetchForCurrentUser();
      if (!mounted) return;
      setState(() {
        _reservations = results;
        _loading = false;
      });
      _enter.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.luxuryBackgroundGradient,
        child: SafeArea(child: _buildBody()),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              color: AppTheme.primaryGold, size: 18),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
      ),
      title: ShaderMask(
        shaderCallback: (b) => AppTheme.subtleGoldGradient.createShader(b),
        child: const Text(
          'MES RÉSERVATIONS',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: AppTheme.primaryGold.withValues(alpha: 0.7), size: 22),
            onPressed: _loading ? null : _load,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent,
              AppTheme.primaryGold.withValues(alpha: 0.2),
              Colors.transparent,
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_reservations.isEmpty) return _buildEmpty();
    return _buildList();
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(AppTheme.primaryGold),
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                color: AppTheme.primaryGold.withValues(alpha: 0.35), size: 60),
            const SizedBox(height: 20),
            Text(
              'Unable to load reservations',
              style: TextStyle(
                color: AppTheme.softWhite.withValues(alpha: 0.85),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.offWhite.withValues(alpha: 0.4),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
                decoration: BoxDecoration(
                  gradient: AppTheme.subtleGoldGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGold.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  'RETRY',
                  style: TextStyle(
                    color: AppTheme.richBlack,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return FadeTransition(
      opacity: _fade,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryGold.withValues(alpha: 0.06),
                  border: Border.all(
                    color: AppTheme.primaryGold.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: AppTheme.primaryGold.withValues(alpha: 0.45),
                  size: 40,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'No reservations yet',
                style: TextStyle(
                  color: AppTheme.softWhite.withValues(alpha: 0.9),
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your upcoming and past chauffeur\nreservations will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.offWhite.withValues(alpha: 0.4),
                  fontSize: 14,
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return FadeTransition(
      opacity: _fade,
      child: RefreshIndicator(
        color: AppTheme.primaryGold,
        backgroundColor: AppTheme.card,
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          physics: const BouncingScrollPhysics(),
          itemCount: _reservations.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ReservationCard(reservation: _reservations[i]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  RESERVATION CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ReservationCard extends StatelessWidget {
  final UserReservation reservation;
  const _ReservationCard({required this.reservation});

  static final _dateFmt = DateFormat('dd MMM yyyy  •  HH:mm');

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final dateStr = _dateFmt.format(r.scheduledDate ?? r.sortDate);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryGold.withValues(alpha: 0.11),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(reservation: r),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateRow(dateStr: dateStr),
                const SizedBox(height: 14),
                _RouteSection(
                    pickup: r.pickupAddress, dropoff: r.dropoffAddress),
                if (_hasStats(r)) ...[
                  const SizedBox(height: 14),
                  Container(
                      height: 1,
                      color: AppTheme.primaryGold.withValues(alpha: 0.08)),
                  const SizedBox(height: 12),
                  _StatsRow(reservation: r),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasStats(UserReservation r) =>
      r.vehicleType != null ||
      r.price != null ||
      r.distanceKm != null ||
      r.durationMin != null ||
      r.isCash != null;
}

// ─── Card Header ─────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final UserReservation reservation;
  const _CardHeader({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final isQuick = reservation.type == ReservationType.quickTrip;
    final accent =
        isQuick ? const Color(0xFF3B82F6) : AppTheme.primaryGold;
    final icon =
        isQuick ? Icons.bolt_rounded : Icons.calendar_month_rounded;
    final label = isQuick
        ? 'QUICK TRIP'
        : _serviceLabel(reservation.serviceType);

    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
        border: Border(
          bottom: BorderSide(
            color: accent.withValues(alpha: 0.16),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 14),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const Spacer(),
          _StatusBadge(status: reservation.status),
        ],
      ),
    );
  }

  String _serviceLabel(String? type) {
    switch (type?.toLowerCase()) {
      case 'transfer':
        return 'TRANSFER SERVICE';
      case 'custom':
        return 'CUSTOM SERVICE';
      default:
        return 'SERVICE RESERVATION';
    }
  }
}

// ─── Date Row ────────────────────────────────────────────────────────────────

class _DateRow extends StatelessWidget {
  final String dateStr;
  const _DateRow({required this.dateStr});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.access_time_rounded,
            size: 14,
            color: AppTheme.primaryGold.withValues(alpha: 0.65)),
        const SizedBox(width: 7),
        Text(
          dateStr,
          style: TextStyle(
            color: AppTheme.softWhite.withValues(alpha: 0.88),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─── Route Section ───────────────────────────────────────────────────────────

class _RouteSection extends StatelessWidget {
  final String pickup;
  final String? dropoff;
  const _RouteSection({required this.pickup, this.dropoff});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RoutePoint(
          icon: Icons.trip_origin_rounded,
          color: AppTheme.primaryGold,
          label: 'FROM',
          address: pickup,
        ),
        if (dropoff != null && dropoff!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Container(
              width: 1,
              height: 14,
              color: AppTheme.primaryGold.withValues(alpha: 0.2),
            ),
          ),
          _RoutePoint(
            icon: Icons.location_on_rounded,
            color: const Color(0xFF10B981),
            label: 'TO',
            address: dropoff!,
          ),
        ],
      ],
    );
  }
}

class _RoutePoint extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;
  const _RoutePoint({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.softWhite.withValues(alpha: 0.82),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Stats Row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final UserReservation reservation;
  const _StatsRow({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        if (r.vehicleType != null)
          _StatChip(icon: Icons.directions_car_rounded, value: r.vehicleType!),
        if (r.price != null)
          _StatChip(
              icon: Icons.euro_rounded,
              value: r.price!.toStringAsFixed(2),
              highlight: true),
        if (r.distanceKm != null)
          _StatChip(
              icon: Icons.straighten_rounded,
              value: '${r.distanceKm!.toStringAsFixed(1)} km'),
        if (r.durationMin != null)
          _StatChip(
              icon: Icons.timer_outlined,
              value: '${r.durationMin!.toStringAsFixed(0)} min'),
        if (r.isCash != null)
          _StatChip(
            icon: r.isCash!
                ? Icons.payments_outlined
                : Icons.credit_card_rounded,
            value: r.isCash! ? 'Cash' : 'Card',
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool highlight;
  const _StatChip(
      {required this.icon, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? AppTheme.primaryGold
        : AppTheme.offWhite.withValues(alpha: 0.55);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            color: highlight
                ? AppTheme.primaryGold
                : AppTheme.offWhite.withValues(alpha: 0.65),
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve(status.toLowerCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static (String, Color) _resolve(String s) => switch (s) {
        'confirmed' => ('Confirmed', const Color(0xFF10B981)),
        'pending' => ('Pending', const Color(0xFFF59E0B)),
        'completed' => ('Completed', const Color(0xFF3B82F6)),
        'cancelled' || 'canceled' => ('Cancelled', const Color(0xFFEF4444)),
        'in_progress' || 'active' => ('Active', const Color(0xFF8B5CF6)),
        _ => (s, const Color(0xFF9CA3AF)),
      };
}
