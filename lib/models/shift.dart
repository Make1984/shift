import 'package:flutter/material.dart';

enum ShiftStatus {
  submitted, // 提出中
  adjusting, // 調整中
  confirmed, // 確定
  canceled, // 取り消し
}

class Shift {
  final String id;
  final String userId;
  final String userName;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final ShiftStatus status;
  final int breakDurationMinutes;
  final TimeOfDay? breakStartTime;
  final TimeOfDay? breakEndTime;

  Shift({
    required this.id,
    required this.userId,
    required this.userName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.breakDurationMinutes = 0,
    this.breakStartTime,
    this.breakEndTime,
  });

  Shift copyWith({
    ShiftStatus? status,
    int? breakDurationMinutes,
    TimeOfDay? breakStartTime,
    TimeOfDay? breakEndTime,
  }) {
    return Shift(
      id: id,
      userId: userId,
      userName: userName,
      date: date,
      startTime: startTime,
      endTime: endTime,
      status: status ?? this.status,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      breakEndTime: breakEndTime ?? this.breakEndTime,
    );
  }

  double get workHours {
    final start = startTime.hour + startTime.minute / 60.0;
    final end = endTime.hour + endTime.minute / 60.0;
    return end - start;
  }

  static Shift autoAllocateBreak(Shift shift) {
    final hours = shift.workHours;
    int breakMin = 0;
    if (hours >= 8) {
      breakMin = 60;
    } else if (hours >= 6) {
      breakMin = 45;
    }

    if (breakMin == 0) {
      return shift.copyWith(breakDurationMinutes: 0);
    }

    // 休憩時間をシフトの真ん中に配置
    final startMinutes = shift.startTime.hour * 60 + shift.startTime.minute;
    final endMinutes = shift.endTime.hour * 60 + shift.endTime.minute;
    final midPoint = (startMinutes + endMinutes) ~/ 2;

    final bStartTotal = midPoint - (breakMin ~/ 2);
    final bEndTotal = bStartTotal + breakMin;

    return shift.copyWith(
      breakDurationMinutes: breakMin,
      breakStartTime: TimeOfDay(
        hour: bStartTotal ~/ 60,
        minute: bStartTotal % 60,
      ),
      breakEndTime: TimeOfDay(hour: bEndTotal ~/ 60, minute: bEndTotal % 60),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'date': date.toIso8601String(),
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'status': status.index,
      'breakDurationMinutes': breakDurationMinutes,
      'breakStartTime':
          breakStartTime != null
              ? '${breakStartTime!.hour}:${breakStartTime!.minute}'
              : null,
      'breakEndTime':
          breakEndTime != null
              ? '${breakEndTime!.hour}:${breakEndTime!.minute}'
              : null,
    };
  }

  factory Shift.fromJson(Map<String, dynamic> json) {
    TimeOfDay parseTime(String timeStr) {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return Shift(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      date: DateTime.parse(json['date']),
      startTime: parseTime(json['startTime']),
      endTime: parseTime(json['endTime']),
      status: ShiftStatus.values[json['status']],
      breakDurationMinutes: json['breakDurationMinutes'] ?? 0,
      breakStartTime:
          json['breakStartTime'] != null
              ? parseTime(json['breakStartTime'])
              : null,
      breakEndTime:
          json['breakEndTime'] != null ? parseTime(json['breakEndTime']) : null,
    );
  }
}
