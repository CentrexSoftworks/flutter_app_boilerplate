import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_app_boilerplate/common/constant/gitter_constants.dart';

import 'package:flutter_app_boilerplate/common/utils/logger_util.dart';
import 'package:flutter_app_boilerplate/common/utils/navigator_util.dart';
import 'package:flutter_gen/gen_l10n/gitter_localizations.dart';
import 'package:flutter_app_boilerplate/ui/pages/notifications/message.dart';
import 'package:flutter_app_boilerplate/ui/pages/tab_navigator.dart';
import 'package:flutter_app_boilerplate/ui/blocs/me/dark_mode/dark_mode_bloc.dart';
import 'package:flutter_app_boilerplate/ui/blocs/me/theme/theme_bloc.dart';
import 'package:flutter_app_boilerplate/ui/widgets/loader.dart';
import 'package:flutter_app_boilerplate/ui/widgets/splash_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SplashPage extends StatefulWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotifications;
  final AndroidNotificationChannel channel;
  final BannerAd bannerAd;

  const SplashPage({
    Key? key,
    required this.flutterLocalNotifications,
    required this.channel,
    required this.bannerAd,
  }) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DarkModeBloc, DarkModeState>(
      builder: (context, state) => BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) => _default(themeState),
      ),
    );
  }

  Widget _default(ThemeState themeState) {
    var _theme = Theme.of(context);
    return Stack(
      children: [
        SplashScreen(
          seconds: 6,
          title: Text(
            GitterLocalizations.of(context)!.welcome,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
          ),
          navigateAfterSeconds: const TabNavigator(),
          image: Image.network('https://cdn.gitterapp.com/logo/gitter.png'),
          styleTextUnderTheLoader: const TextStyle(),
          backgroundColor: _theme.colorScheme.background,
          photoSize: 100.0,
          onClick: () => printInfoLog(GitterConstants.appName),
          useLoader: true,
          customLoader: const Loader(
            size: 40,
          ),
          loadingText: Text(GitterLocalizations.of(context)!.loading),
          loadingTextPadding: const EdgeInsets.only(bottom: 80),
          loaderColor: Color(themeState.color!),
        ),
        Positioned(
          bottom: (Platform.isIOS && MediaQuery.of(context).padding.bottom > 0)
              ? 34
              : 10,
          child: Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            height: widget.bannerAd.size.height.toDouble(),
            child: AdWidget(ad: widget.bannerAd),
          ),
        )
      ],
    );
  }

  void _initFirebaseMessaging() {
    FirebaseMessaging.instance.getInitialMessage().then((message) => {
          if (message != null)
            {
              /// todo
            }
        });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      var notification = message.notification;
      var android = message.notification?.android;
      if (notification != null && android != null) {
        widget.flutterLocalNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              widget.channel.id,
              widget.channel.name,
              widget.channel.description,
              icon: 'ic_launcher',
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      printInfoLog('A new onMessageOpenedApp event was published!');
      try {
        await FlutterDynamicIcon.setApplicationIconBadgeNumber(0);
      } catch (_) {}
      NavigatorUtil.push(context, const MessageView(),
          settings: RouteSettings(arguments: MessageArguments(message, true)));
    });
  }
}