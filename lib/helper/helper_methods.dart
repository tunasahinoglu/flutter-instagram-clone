import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

String formatDate(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate();
  String year = dateTime.year.toString();
  String month = dateTime.month.toString();
  String day = dateTime.day.toString();
  String formattedDate = '$day.$month.$year';
  return formattedDate;
}

String formatTime(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate();
  String formattedTime = DateFormat.Hm().format(dateTime);
  return formattedTime;
}

class CustomMessages implements timeago.LookupMessages {
  final Map<String, String> messages;

  CustomMessages(this.messages);

  @override
  String prefixAgo() => messages['prefixAgo']!;
  @override
  String prefixFromNow() => messages['prefixFromNow']!;
  @override
  String suffixAgo() => messages['suffixAgo']!;
  @override
  String suffixFromNow() => messages['suffixFromNow']!;
  @override
  String lessThanOneMinute(int seconds) => messages['seconds_ago']!;
  @override
  String aboutAMinute(int minutes) => messages['minute']!;
  @override
  String minutes(int minutes) =>
      messages['minutes_ago']!.replaceAll('%d', minutes.toString());
  @override
  String aboutAnHour(int minutes) => messages['hour']!;
  @override
  String hours(int hours) =>
      messages['hours_ago']!.replaceAll('%d', hours.toString());
  @override
  String aDay(int hours) => messages['day']!;
  @override
  String days(int days) =>
      messages['days_ago']!.replaceAll('%d', days.toString());
  @override
  String aboutAMonth(int days) => messages['month']!;
  @override
  String months(int months) =>
      messages['months_ago']!.replaceAll('%d', months.toString());
  @override
  String aboutAYear(int year) => messages['year']!;
  @override
  String years(int years) =>
      messages['years']!.replaceAll('%d', years.toString());
  @override
  String wordSeparator() => messages['wordSeparator']!;
}

Future<void> loadTimeAgoMessages() async {
  final String jsonString =
      await rootBundle.loadString('assets/timeago_messages.json');
  final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

  final Map<String, String> enMessages = _convertMapToString(jsonMap['en']);
  final Map<String, String> trMessages = _convertMapToString(jsonMap['tr']);

  timeago.setLocaleMessages('en', CustomMessages(enMessages));
  timeago.setLocaleMessages('tr', CustomMessages(trMessages));
}

Map<String, String> _convertMapToString(Map<String, dynamic> map) {
  Map<String, String> result = {};
  map.forEach((key, value) {
    result[key] = value.toString();
  });
  return result;
}
