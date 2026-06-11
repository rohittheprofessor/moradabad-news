import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final languageControllerProvider =
    NotifierProvider<LanguageController, Locale>(LanguageController.new);

class LanguageController extends Notifier<Locale> {
  @override
  Locale build() => const Locale('hi');

  void toggle() {
    state = state.languageCode == 'hi' ? const Locale('en') : const Locale('hi');
  }
}
