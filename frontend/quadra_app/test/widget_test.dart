import 'package:flutter_test/flutter_test.dart';

import 'package:quadra_app/api_client.dart';

void main() {
  test('ApiException carrega mensagem', () {
    final e = ApiException(400, 'erro teste');
    expect(e.statusCode, 400);
    expect(e.toString(), 'erro teste');
  });
}
