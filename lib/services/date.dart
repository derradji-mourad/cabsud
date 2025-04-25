import 'package:flutter/material.dart';
import '../commande/commande.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/string.dart'; // Assuming you have this import for localization

class AppointmentScreen extends StatefulWidget {
  final String origin;

  const AppointmentScreen({Key? key, required this.origin}) : super(key: key);

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  DateTime selectedMonth = DateTime.now();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  List<TimeOfDay> availableTimes = List.generate(
    16,
        (index) => TimeOfDay(hour: 8 + index, minute: 0), // 8:00 to 23:00
  );

  bool _isLanguageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String? selectedLanguage = prefs.getString('language');

    if (selectedLanguage == null) {
      // Default to French if no language was selected yet
      selectedLanguage = 'fr';
      await prefs.setString('language', 'fr');
    }

    Strings.load(selectedLanguage);

    setState(() {
      _isLanguageLoaded = true;
    });
  }

  void _confirmAppointment() {
    if (selectedDate != null && selectedTime != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommandePage(
            origin: widget.origin,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.of(context)!.dateRequired)),
      );
    }
  }

  Widget _buildGradientText(String text,
      {double fontSize = 16, FontWeight fontWeight = FontWeight.bold}) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          Color(0xFFAE8625),
          Color(0xFFF7EF8A),
          Color(0xFFD2AC47),
          Color(0xFFEDC967)
        ],
      ).createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }

  String _getWeekday(DateTime date) {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return weekdays[date.weekday % 7];
  }

  int _daysInMonth(DateTime date) {
    final beginningNextMonth = (date.month < 12)
        ? DateTime(date.year, date.month + 1, 1)
        : DateTime(date.year + 1, 1, 1);
    return beginningNextMonth.subtract(Duration(days: 1)).day;
  }

  void _changeMonth(int increment) {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + increment,
      );
      selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLanguageLoaded) {
      return Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();
    final isCurrentMonth = selectedMonth.year == now.year && selectedMonth.month == now.month;
    final daysInSelectedMonth = _daysInMonth(selectedMonth);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: _buildGradientText(Strings.of(context)!.appointmentTitle, fontSize: 20),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Flexible(
                  child: _buildGradientText(
                    Strings.of(context)!.appointmentSubtitle,
                    fontSize: 16,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Text(
                      "${selectedMonth.month}/${selectedMonth.year}",
                      style: TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: daysInSelectedMonth,
                itemBuilder: (context, index) {
                  DateTime date = DateTime(selectedMonth.year, selectedMonth.month, index + 1);
                  bool isBeforeToday = date.isBefore(DateTime(now.year, now.month, now.day));
                  bool isSelected = selectedDate != null &&
                      selectedDate!.day == date.day &&
                      selectedDate!.month == date.month &&
                      selectedDate!.year == date.year;

                  return GestureDetector(
                    onTap: isBeforeToday
                        ? null
                        : () {
                      setState(() => selectedDate = date);
                    },
                    child: Opacity(
                      opacity: isBeforeToday ? 0.3 : 1,
                      child: Container(
                        width: 60,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        padding: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(colors: [
                            Color(0xFFAE8625),
                            Color(0xFFF7EF8A),
                            Color(0xFFD2AC47),
                            Color(0xFFEDC967)
                          ])
                              : null,
                          color: isSelected ? null : Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            width: 1.5,
                            color: Colors.transparent,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getWeekday(date),
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  Color(0xFFAE8625),
                                  Color(0xFFF7EF8A),
                                  Color(0xFFD2AC47),
                                  Color(0xFFEDC967)
                                ],
                              ).createShader(bounds),
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            _buildGradientText(Strings.of(context)!.selectTime),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: availableTimes.map((time) {
                final nowTime = TimeOfDay.now();
                final isToday = selectedDate != null &&
                    selectedDate!.year == now.year &&
                    selectedDate!.month == now.month &&
                    selectedDate!.day == now.day;
                final isPastTime = isToday &&
                    (time.hour < nowTime.hour ||
                        (time.hour == nowTime.hour && time.minute <= nowTime.minute));

                bool isSelected = selectedTime == time;
                return GestureDetector(
                  onTap: isPastTime || selectedDate == null
                      ? null
                      : () => setState(() => selectedTime = time),
                  child: Opacity(
                    opacity: isPastTime ? 0.3 : 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(colors: [
                          Color(0xFFAE8625),
                          Color(0xFFF7EF8A),
                          Color(0xFFD2AC47),
                          Color(0xFFEDC967)
                        ])
                            : null,
                        color: isSelected ? null : Colors.black,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          width: 1.5,
                          color: Colors.transparent,
                        ),
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            Color(0xFFAE8625),
                            Color(0xFFF7EF8A),
                            Color(0xFFD2AC47),
                            Color(0xFFEDC967)
                          ],
                        ).createShader(bounds),
                        child: Text(
                          time.format(context),
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 30),
            Center(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFAE8625),
                      Color(0xFFF7EF8A),
                      Color(0xFFD2AC47),
                      Color(0xFFEDC967)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _confirmAppointment,
                  child: Text(
                    Strings.of(context)!.confirmAppointment,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
