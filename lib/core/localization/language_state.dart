part of 'language_cubit.dart';

class LanguageState extends Equatable {
  const LanguageState({required this.locale});

  factory LanguageState.initial() {
    return const LanguageState(locale: Locale('en'));
  }

  final Locale locale;

  @override
  List<Object> get props => [locale];
}

