import 'package:app/provider/scroll_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class NightScaffold extends StatelessWidget {
  const NightScaffold({
    super.key,
    required this.child
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent
      ),
      child: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Selector<ScrollProvider, double>(
                  selector: (_, p) => p.value,
                  builder: (_, data, __) {
                    double off = data / 1000.0;
                    return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: const [Color(0xFF043244), Color(0xFF032028)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0 - off, 0.75 - off]
                          ),
                        )
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: Selector<ScrollProvider, double>(
                  selector: (_, p) => p.value,
                  builder: (_, data, __) {
                    double off = data / 750.0;
                    return ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          colors: const [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0 - off, 0.75 - off]
                        ).createShader(bounds);
                      },
                      child: Image.asset(
                        'lib/assets/star_bg.png',
                        repeat: ImageRepeat.repeat,
                        alignment: FractionalOffset(0, -off),
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme: Theme.of(context).iconTheme.copyWith(
                      color: Colors.white
                    )
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(color: Colors.white),
                    child: child
                  ),
                )
              )
            ],
          ),
      ),
    );
  }

}

class DayScaffold extends StatelessWidget {
  const DayScaffold({
    super.key,
    required this.child
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent
      ),
      child: Scaffold(
        body: Stack(
          children: [
            child
          ],
        ),
      ),
    );
  }

}


class TimeOfDayScaffold extends StatelessWidget {
  const TimeOfDayScaffold({
    super.key,
    required this.child
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    
    return isDarkMode ? NightScaffold(child: child) : DayScaffold(child: child);
  }

}