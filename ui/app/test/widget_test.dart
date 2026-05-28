import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_app/core/locale/locale_cubit.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/main.dart';

/// Fail network immediately so LoginScreen's background Image.network uses errorBuilder.
class _NoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _NoNetworkHttpClient();
}

class _NoNetworkHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    throw const SocketException('No network in widget tests');
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _NoNetworkHttpOverrides();
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
    await configureDependencies();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('Login screen shows SYNC branding and form', (tester) async {
    final localeCubit = getIt<LocaleCubit>()..emit(const Locale('en'));

    await tester.pumpWidget(SyncApp(localeCubit: localeCubit));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('SYNC'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Register Now'), findsOneWidget);
  });

  testWidgets('Login requires email and password', (tester) async {
    final localeCubit = getIt<LocaleCubit>()..emit(const Locale('en'));

    await tester.pumpWidget(SyncApp(localeCubit: localeCubit));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Please enter both email and password.'),
      findsOneWidget,
    );
  });
}
