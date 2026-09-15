import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

/// Enterprise AES-256-GCM Transit Crypto utility for PragatiX Flutter app.
/// Byte-for-byte compatible with Spring Boot's AesGcmEncryptionUtil and Web Frontend transitCrypto.ts.
class TransitCrypto {
  TransitCrypto._();

  static const String prefix = 'ENC:';
  static const String _defaultSecret = 'PragatiXAES256GCMDatabaseEncryptionSecretKey2026!';
  static String _secret = _defaultSecret;

  static final AesGcm _aesGcm = AesGcm.with256bits();
  static final Sha256 _sha256 = Sha256();
  static SecretKey? _cachedKey;

  static final Set<String> sensitiveKeys = {
    'email',
    'phone',
    'phoneno',
    'phonenumber',
    'mobilenumber',
    'mobileno',
    'guardianphone',
    'guardianphoneno',
    'guardianemail',
    'parentphone',
    'parentphoneno',
    'parentemail',
    'fatherphone',
    'motherphone',
  };

  /// Set or override encryption secret key if provided by environment/remote config.
  static void setSecret(String secret) {
    if (secret.trim().isNotEmpty && secret != _secret) {
      _secret = secret.trim();
      _cachedKey = null;
    }
  }

  /// Derives the 32-byte AES-256 key from SHA-256 digest of secret.
  static Future<SecretKey> _getKey() async {
    if (_cachedKey != null) return _cachedKey!;
    final secretBytes = utf8.encode(_secret);
    final hash = await _sha256.hash(secretBytes);
    _cachedKey = SecretKey(hash.bytes);
    return _cachedKey!;
  }

  /// Fast check if a value starts with the encryption prefix 'ENC:'.
  static bool isEncrypted(dynamic value) {
    if (value == null) return false;
    final str = value.toString().trim();
    return str.startsWith(prefix);
  }

  /// Fast check if a raw string (e.g. JSON response body) contains any encrypted payload.
  static bool containsEncryptedData(String? text) {
    if (text == null || text.isEmpty) return false;
    return text.contains(prefix);
  }

  /// Decrypts a single "ENC:<Base64(12-byte IV + CipherText + 16-byte Tag)>" string to plaintext.
  /// If value is unencrypted (legacy plain text) or null, returns as-is.
  static Future<String> decryptField(dynamic encryptedText) async {
    if (encryptedText == null) return '';
    final str = encryptedText.toString().trim();
    if (!str.startsWith(prefix)) {
      return str;
    }

    try {
      final base64Payload = str.substring(prefix.length).replaceAll(RegExp(r'\s+'), '');
      // Handle standard and URL-safe Base64, plus missing padding
      String clean = base64Payload.replaceAll('-', '+').replaceAll('_', '/');
      while (clean.length % 4 != 0) {
        clean += '=';
      }

      final combined = base64.decode(clean);

      // IV (12 bytes) + Tag (16 bytes) = minimum 28 bytes
      if (combined.length < 28) {
        debugPrint('TransitCrypto: Payload too short for AES-GCM (${combined.length} bytes)');
        return str;
      }

      final iv = combined.sublist(0, 12);
      final cipherAndTag = combined.sublist(12);

      final cipherText = cipherAndTag.sublist(0, cipherAndTag.length - 16);
      final macBytes = cipherAndTag.sublist(cipherAndTag.length - 16);

      final key = await _getKey();
      final secretBox = SecretBox(
        cipherText,
        nonce: iv,
        mac: Mac(macBytes),
      );

      final clearBytes = await _aesGcm.decrypt(
        secretBox,
        secretKey: key,
      );

      return utf8.decode(clearBytes);
    } catch (e) {
      debugPrint('TransitCrypto: Failed to decrypt field: $e');
      return str;
    }
  }

  /// Encrypts plain text into "ENC:<Base64(12-byte IV + CipherText + 16-byte Tag)>".
  static Future<String> encryptField(dynamic plainText) async {
    if (plainText == null) return '';
    final str = plainText.toString();
    if (str.isEmpty || str.startsWith(prefix)) {
      return str;
    }

    try {
      final key = await _getKey();
      final secretBox = await _aesGcm.encrypt(
        utf8.encode(str),
        secretKey: key,
      );

      final combined = <int>[
        ...secretBox.nonce,
        ...secretBox.cipherText,
        ...secretBox.mac.bytes,
      ];

      return prefix + base64.encode(combined);
    } catch (e) {
      debugPrint('TransitCrypto: Failed to encrypt field: $e');
      return str;
    }
  }

  /// Recursively walks any incoming Map, List, or primitive and decrypts any values starting with "ENC:".
  static Future<dynamic> decryptPayload(dynamic data) async {
    if (data == null) return null;

    if (data is String) {
      if (data.trim().startsWith(prefix)) {
        return await decryptField(data);
      }
      return data;
    }

    if (data is List) {
      final List<dynamic> list = [];
      for (final item in data) {
        list.add(await decryptPayload(item));
      }
      return list;
    }

    if (data is Map) {
      final Map<String, dynamic> map = {};
      for (final entry in data.entries) {
        final key = entry.key.toString();
        final val = entry.value;

        if (val is String && val.trim().startsWith(prefix)) {
          map[key] = await decryptField(val);
        } else if (val is Map || val is List) {
          map[key] = await decryptPayload(val);
        } else {
          map[key] = val;
        }
      }
      return map;
    }

    return data;
  }

  /// Recursively encrypts sensitive fields in an outgoing request Map or List.
  static Future<dynamic> encryptPayload(dynamic data) async {
    if (data == null) return null;

    if (data is List) {
      final List<dynamic> list = [];
      for (final item in data) {
        list.add(await encryptPayload(item));
      }
      return list;
    }

    if (data is Map) {
      final Map<String, dynamic> map = {};
      for (final entry in data.entries) {
        final key = entry.key.toString();
        final normalizedKey = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        final val = entry.value;

        if (val is String && sensitiveKeys.contains(normalizedKey)) {
          map[key] = await encryptField(val);
        } else if (val is Map || val is List) {
          map[key] = await encryptPayload(val);
        } else {
          map[key] = val;
        }
      }
      return map;
    }

    return data;
  }
}
