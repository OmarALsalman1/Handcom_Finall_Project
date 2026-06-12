import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart'; // استيراد الـ Provider للاستماع للثيم
import 'package:handcom/shared/widgets/theme_provider.dart'; // تأكد من صحة مسار ملف الثيم بمشروعك
import 'package:handcom/core/l10n/app_strings.dart';

class SelectDateTimePage extends StatefulWidget {
  const SelectDateTimePage({super.key});

  @override
  State<SelectDateTimePage> createState() => _SelectDateTimePageState();
}

class _SelectDateTimePageState extends State<SelectDateTimePage> {
  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  final DateTime _today = DateTime.now();

  late String selectedPeriod;
  late String selectedHourMinute;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ar_SA', null);

    final TimeOfDay currentTime = TimeOfDay.now();
    selectedPeriod = currentTime.period == DayPeriod.am ? "am" : "pm";

    int hourInt = currentTime.hourOfPeriod == 0 ? 12 : currentTime.hourOfPeriod;
    selectedHourMinute =
        "${hourInt.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}";
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;

    if (month.year == _today.year && month.month == _today.month) {
      return List.generate(
        lastDay - _today.day + 1,
        (index) => DateTime(month.year, month.month, _today.day + index),
      );
    }

    return List.generate(
      lastDay,
      (index) => DateTime(month.year, month.month, index + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _getDaysInMonth(_focusedMonth);
    String monthName = DateFormat.yMMMM('ar_SA').format(_focusedMonth);

    // استخدام Consumer للمراقبة الديناميكية لوضع الثيم العالمي
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;

        // تهيئة مصفوفة الألوان المتغيرة لتدعم الدارك مود واللايت مود بسلاسة
        final Color scaffoldBg =
            isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB);
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color textColor = isDark ? Colors.white : Colors.black;
        final Color subTextColor = isDark ? Colors.white60 : Colors.black87;
        final Color timeContainerBg =
            isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);
        final Color arrowBg =
            isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: isDark
                    ? Border.all(color: Colors.white10, width: 0.5)
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // الهيدر العلوي للصندوق: دمج زر الرجوع والعنوان متناسقين في سطر واحد
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: arrowBg,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new,
                                color: primaryBlue, size: 16),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      Text(
                        context.l10n.chooseDayDate,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(color: isDark ? Colors.white12 : Colors.black12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.chevron_left, color: primaryBlue),
                        onPressed: () {
                          if (_focusedMonth.year > _today.year ||
                              (_focusedMonth.year == _today.year &&
                                  _focusedMonth.month > _today.month)) {
                            setState(
                              () => _focusedMonth = DateTime(
                                _focusedMonth.year,
                                _focusedMonth.month - 1,
                              ),
                            );
                          }
                        },
                      ),
                      Text(
                        monthName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.chevron_right, color: primaryBlue),
                        onPressed: () {
                          setState(
                            () => _focusedMonth = DateTime(
                              _focusedMonth.year,
                              _focusedMonth.month + 1,
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 95,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: daysInMonth.length,
                      itemBuilder: (context, index) {
                        DateTime dayDate = daysInMonth[index];

                        bool isSelected = dayDate.day == _selectedDate.day &&
                            dayDate.month == _selectedDate.month &&
                            dayDate.year == _selectedDate.year;

                        String dayName =
                            DateFormat.EEEE('ar_SA').format(dayDate);

                        return _buildDayItem(
                            dayDate, dayName, isSelected, cardBg, isDark);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                  Divider(color: isDark ? Colors.white12 : Colors.black12),
                  Text(
                    context.l10n.chooseTime,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                  const SizedBox(height: 15),

                  // اختيار الوقت المطور والذكير المحمي من اختيار ساعات سابقة في نفس اليوم
                  GestureDetector(
                    onTap: () async {
                      final TimeOfDay nowTime = TimeOfDay.now();
                      final pastTimeError = context.l10n.pastTimeError;
                      final amFull = context.l10n.amFull;
                      final pmFull = context.l10n.pmFull;
                      final messenger = ScaffoldMessenger.of(context);

                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: nowTime,
                        builder: (context, child) {
                          return Directionality(
                            textDirection: ui.TextDirection.ltr,
                            child: child!,
                          );
                        },
                      );

                      if (picked != null) {
                        bool isTodaySelected =
                            _selectedDate.day == _today.day &&
                                _selectedDate.month == _today.month &&
                                _selectedDate.year == _today.year;

                        if (isTodaySelected) {
                          int pickedMinutes = picked.hour * 60 + picked.minute;
                          int currentMinutes =
                              nowTime.hour * 60 + nowTime.minute;

                          if (pickedMinutes < currentMinutes) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    pastTimeError,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                            return;
                          }
                        }

                        setState(() {
                          selectedPeriod = picked.period == DayPeriod.am
                              ? amFull
                              : pmFull;

                          int hourInt = picked.hourOfPeriod == 0
                              ? 12
                              : picked.hourOfPeriod;

                          selectedHourMinute =
                              "${hourInt.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                        });
                      }
                    },
                    child: Container(
                      width: 240,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: timeContainerBg,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            selectedPeriod == 'am' ? context.l10n.amFull : context.l10n.pmFull,
                            style: TextStyle(fontSize: 18, color: subTextColor),
                          ),
                          Text(" - ",
                              style:
                                  TextStyle(fontSize: 18, color: subTextColor)),
                          Text(
                            selectedHourMinute,
                            style: TextStyle(fontSize: 18, color: subTextColor),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.access_time_filled,
                            size: 24,
                            color: primaryBlue,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: () {
                      final dateLabel = DateFormat('EEE، d MMM', 'ar_SA').format(_selectedDate);
                      final timeLabel = '$selectedHourMinute ${selectedPeriod == "am" ? "ص" : "م"}';
                      Navigator.pop(context, {'date': dateLabel, 'time': timeLabel});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentOrange,
                      minimumSize: const Size(180, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      context.l10n.confirm,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
    );
  }

  // ميثود منفصل لبناء كروت الأيام لتسهيل التحكم البرمجي بالألوان
  Widget _buildDayItem(DateTime dayDate, String dayName, bool isSelected,
      Color cardBg, bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _selectedDate = dayDate),
      child: Container(
        width: 75,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : cardBg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? primaryBlue
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white60 : Colors.black),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "${dayDate.day}",
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
