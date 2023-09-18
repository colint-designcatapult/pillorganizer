import 'package:flutter/widgets.dart';

class ExpansionPanelProvider<T> extends ChangeNotifier {
  Map<T, bool> _value = Map();
  int _prevHashCode = 0;

  ExpansionPanelProvider<T> update(Set<T>? keyList) {
    if (keyList != null) {
      if (_prevHashCode != keyList.hashCode) {
        _value.removeWhere((key, value) => !keyList.contains(key));
        _value.addAll({
          for (var e in keyList)
            if (!_value.containsKey(e)) e: false
        });

        _prevHashCode = keyList.hashCode;
      }
    }
    return this;
  }

  void open(T id) {
    set(id, true);
  }

  void close(T id) {
    set(id, true);
  }

  void set(T id, bool open) {
    _value[id] = open;
    notifyListeners();
  }

  bool get(T id) {
    return _value[id] ?? false;
  }
}
