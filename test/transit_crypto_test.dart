import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pragatix/core/crypto/transit_crypto.dart';
import 'package:pragatix/core/exceptions/api_exception.dart';

void main() {
  group('TransitCrypto Tests', () {
    test('Encrypt and decrypt single field', () async {
      const email = 'teacher.discipline@jjcet.ac.in';
      final encrypted = await TransitCrypto.encryptField(email);

      expect(encrypted, startsWith(TransitCrypto.prefix));
      expect(encrypted, isNot(equals(email)));

      final decrypted = await TransitCrypto.decryptField(encrypted);
      expect(decrypted, equals(email));
    });

    test('Unencrypted plain text returns unchanged', () async {
      const plain = 'regular.text@example.com';
      final result = await TransitCrypto.decryptField(plain);
      expect(result, equals(plain));
    });

    test('Null and empty handled safely', () async {
      expect(await TransitCrypto.decryptField(null), equals(''));
      expect(await TransitCrypto.decryptField(''), equals(''));
      expect(await TransitCrypto.encryptField(null), equals(''));
      expect(await TransitCrypto.encryptField(''), equals(''));
    });

    test('Recursive payload decryption on nested maps and lists', () async {
      final encryptedEmail = await TransitCrypto.encryptField('student123@jjcet.ac.in');
      final encryptedPhone = await TransitCrypto.encryptField('9876543210');
      final encryptedGuardianPhone = await TransitCrypto.encryptField('9123456789');

      final payload = {
        'id': 101,
        'fullName': 'John Doe',
        'email': encryptedEmail,
        'phone': encryptedPhone,
        'guardian': {
          'guardianName': 'Robert Doe',
          'phoneNo': encryptedGuardianPhone,
        },
        'activities': [
          {'id': 1, 'contact': encryptedPhone}
        ]
      };

      final decrypted = await TransitCrypto.decryptPayload(payload) as Map<String, dynamic>;

      expect(decrypted['email'], equals('student123@jjcet.ac.in'));
      expect(decrypted['phone'], equals('9876543210'));
      expect(decrypted['fullName'], equals('John Doe'));
      expect(decrypted['guardian']['phoneNo'], equals('9123456789'));
      expect(decrypted['activities'][0]['contact'], equals('9876543210'));
    });

    test('Recursive payload encryption on sensitive keys', () async {
      final rawData = {
        'fullName': 'Jane Smith',
        'email': 'jane@pragatix.in',
        'phone': '9876543210',
        'guardianPhone': '9123456789',
        'department': 'CSE',
      };

      final encrypted = await TransitCrypto.encryptPayload(rawData) as Map<String, dynamic>;

      expect(encrypted['fullName'], equals('Jane Smith'));
      expect(encrypted['department'], equals('CSE'));
      expect(encrypted['email'], startsWith(TransitCrypto.prefix));
      expect(encrypted['phone'], startsWith(TransitCrypto.prefix));
      expect(encrypted['guardianPhone'], startsWith(TransitCrypto.prefix));

      final decrypted = await TransitCrypto.decryptPayload(encrypted) as Map<String, dynamic>;
      expect(decrypted, equals(rawData));
    });

    test('processResponse transparently decrypts response body', () async {
      final encEmail = await TransitCrypto.encryptField('hod@pragatix.in');
      final encPhone = await TransitCrypto.encryptField('9843210987');
      final rawJson = jsonEncode({
        'success': true,
        'data': {
          'email': encEmail,
          'phone': encPhone,
          'name': 'HOD User',
        }
      });

      final originalResponse = http.Response(rawJson, 200, headers: {'content-type': 'application/json'});
      final processed = await processResponse(originalResponse);

      final decoded = jsonDecode(processed.body);
      expect(decoded['data']['email'], equals('hod@pragatix.in'));
      expect(decoded['data']['phone'], equals('9843210987'));
      expect(decoded['data']['name'], equals('HOD User'));
    });
  });
}
