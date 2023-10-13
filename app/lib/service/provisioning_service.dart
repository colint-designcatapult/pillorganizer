class ProvisionningProgress {
  final int stage;
  final int step;

  ProvisionningProgress(
    this.stage,
    this.step,
  );

  String getTitle() {
    switch (stage) {
      case 1:
        return 'Device Setup';
      case 2:
        return 'Preferences';
      case 3:
        return 'Create an account';
      default:
        return '';
    }
  }

  List<String> getIconList() {
    if (stage == 1) {
      return [
        'lib/assets/SVG/Bluetooth.svg',
        'lib/assets/SVG/WifiHigh.svg',
        'lib/assets/SVG/PlugsConnected.svg'
      ];
    } else {
      return [
        'lib/assets/SVG/Timer.svg',
        'lib/assets/SVG/BellSimpleRinging.svg',
        'lib/assets/SVG/Pill.svg'
      ];
    }
  }
}
