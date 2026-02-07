import 'dart:io';

void main() {
  var files = [
    r'd:\spelcabs\spelcabs driver\lib\model\service_model.dart',
    r'd:\spelcabs\spelcabs driver\lib\ui\home_screens\new_orders_screen.dart'
  ];

  for (var path in files) {
    print('\n--- $path ---\n');
    try {
      print(File(path).readAsStringSync());
    } catch (e) {
      print('Error reading $path: $e');
    }
  }
}
