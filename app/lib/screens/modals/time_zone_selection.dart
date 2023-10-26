import 'package:app/provider/filterable_timezone_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:timezone/standalone.dart' as tz;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../service/time_service.dart';

class TimeZoneOption extends StatelessWidget {
  TimeZoneOption({super.key, required this.location}) {}

  final tz.Location location;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(location.name),
      subtitle: Text(location.currentTimeZone.abbreviation),
      style: ListTileStyle.drawer,
    );
  }
}

class TimeZoneSelectionModal extends StatelessWidget {
  const TimeZoneSelectionModal({super.key});

  static Route<TimeZoneLocation> route(context) {
    return platformPageRoute(
        context: context, builder: (_) => const TimeZoneSelectionModal());
  }

  Widget _buildZoneItem(BuildContext context, tz.Location location) {
    return ListTile(
      title: Text(location.name),
      subtitle: Text(location.currentTimeZone.abbreviation),
      onTap: () {
        Navigator.of(context).pop(location);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (BuildContext context) => FilterableTimeZoneProvider(),
        builder: (BuildContext context, Widget? v) {
          return Scaffold(
              appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.genericTimezone),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: PlatformWidget(
                      cupertino: (context, _) {
                        return CupertinoSearchTextField(
                          onChanged: (val) {
                            Provider.of<FilterableTimeZoneProvider>(context,
                                    listen: false)
                                .filter(val);
                          },
                          placeholder:
                              AppLocalizations.of(context)!.searchTimezones,
                          autofocus: true,
                        );
                      },
                      material: (context, _) {
                        return TextField(
                          onChanged: (val) {
                            Provider.of<FilterableTimeZoneProvider>(context,
                                    listen: false)
                                .filter(val);
                          },
                          decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              filled: true,
                              prefixIcon: const Icon(Icons.search),
                              hintText: AppLocalizations.of(context)!
                                  .searchTimezones),
                          autofocus: true,
                        );
                      },
                    ),
                    /*child: PlatformTextField(
                 onChanged: (val) {
                   Provider.of<FilterableTimeZoneProvider>(context, listen: false)
                       .filter(val);
                 },
                 material: (_, __) => MaterialTextFieldData(
                   decoration: InputDecoration(
                     border: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(10.0),
                     ),
                     filled: true,
                     prefixIcon: const Icon(Icons.search),
                   ),
                 ),
                 cupertino: (_, __) => CupertinoTextFieldData(
                   prefix: Icon(PlatformIcons(context).search),
                 ),
                 hintText: 'Search time zones',
                 autofocus: true,
               ),*/
                  ),
                  const Divider(),
                  Expanded(
                    child: Consumer<FilterableTimeZoneProvider>(
                      builder: (context, val, _) {
                        return ListView.builder(
                            itemBuilder: (context, index) {
                              return _buildZoneItem(
                                  context, val.filteredZones[index]);
                            },
                            itemCount: val.filteredZones.length);
                      },
                    ),
                  )
                ],
              ));
        });
  }
}
