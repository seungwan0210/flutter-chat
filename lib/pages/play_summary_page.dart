import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'Play_summary_detail_Page.dart';
import 'Play_summary_history_Page.dart';

class PlaySummaryPage extends StatefulWidget {
  const PlaySummaryPage({super.key});

  @override
  State<PlaySummaryPage> createState() => _PlaySummaryPageState();
}

class _PlaySummaryPageState extends State<PlaySummaryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, Map<String, dynamic>> _playSummaries = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadPlaySummaries();
  }

  /// Firestore에서 플레이 요약 데이터 로드
  Future<void> _loadPlaySummaries() async {
    String userId = _auth.currentUser!.uid;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("daily_play_summary")
        .get();

    setState(() {
      _playSummaries = {};
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime date = DateTime.parse(data['date']);
        _playSummaries[DateTime(date.year, date.month, date.day)] = data;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "오늘의 플레이 요약",
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: _buildCalendar(),
        ),
      ),
    );
  }

  /// 달력 UI
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });

        // 선택된 날짜의 플레이 요약 정보 확인
        DateTime selectedDate = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
        if (_playSummaries.containsKey(selectedDate)) {
          // 요약 정보가 있으면 PlaySummaryHistoryPage로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaySummaryHistoryPage(selectedDate: selectedDay),
            ),
          ).then((_) {
            // 페이지에서 돌아올 때 요약 데이터 갱신
            _loadPlaySummaries();
          });
        } else {
          // 요약 정보가 없으면 PlaySummaryDetailPage로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaySummaryDetailPage(selectedDate: selectedDay),
            ),
          ).then((_) {
            // 페이지에서 돌아올 때 요약 데이터 갱신
            _loadPlaySummaries();
          });
        }
      },
      calendarFormat: CalendarFormat.month,
      rowHeight: 70,
      daysOfWeekHeight: 40,
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        defaultTextStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 16,
        ),
        weekendTextStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 16,
        ),
        cellMargin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        cellPadding: const EdgeInsets.all(4),
        cellAlignment: Alignment.topCenter,
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).textTheme.bodyLarge?.color),
        rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 14,
        ),
        weekendStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 14,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          DateTime day = DateTime(date.year, date.month, date.day);
          if (_playSummaries.containsKey(day)) {
            String emoji = _playSummaries[day]!['emoji'] ?? "😊";
            return Positioned(
              bottom: -10,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}