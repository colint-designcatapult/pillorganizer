class ProvisionningProgress {
  final int step;
  final int stage;

  ProvisionningProgress(
    this.step,
    this.stage,
  );

  String getTitle() {
    switch (step) {
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
    if (step == 1) {
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
