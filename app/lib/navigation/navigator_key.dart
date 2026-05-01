import 'package:flutter/material.dart';

/// Global navigator key for context-independent navigation.
/// Used by authentication provider and other services to navigate
/// without requiring a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
