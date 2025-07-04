// Amtrak real-time train location data decryptor for Flutter
// Dependencies: http ^1.1.0, crypto ^3.0.3, pointycastle ^3.7.3

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';

class AmtrakDecrypt {
  static const trainsUrl =
      "https://maps.amtrak.com/services/MapDataService/trains/getTrainsData";
  static const stationsUrl =
      "https://maps.amtrak.com/services/MapDataService/stations/trainStations";
  static const routesUrl = "https://maps.amtrak.com/rttl/js/RoutesList.json";
  static const routesVUrl = "https://maps.amtrak.com/rttl/js/RoutesList.v.json";
  static const masterSegment = 88;

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  static Future<Map<String, dynamic>> getTrainData() async {
    final encryptionParams = await _fetchEncryptionParameters();
    final response = await http.get(Uri.parse(trainsUrl));
    return _parseEncryptedResponse(response.body, encryptionParams);
  }

  static Future<Map<String, dynamic>> getStationData() async {
    final encryptionParams = await _fetchEncryptionParameters();
    final response = await http.get(Uri.parse(stationsUrl));
    return _parseEncryptedResponse(response.body, encryptionParams);
  }

  static Future<Map<String, String>> _fetchEncryptionParameters() async {
    final routesResponse = await http.get(Uri.parse(routesUrl));
    final routesData = json.decode(routesResponse.body) as List;

    int zoomLevelSum = 0;
    for (var route in routesData) {
      if (route is Map && route.containsKey('ZoomLevel')) {
        zoomLevelSum += (route['ZoomLevel'] as num).toInt();
      }
    }

    final dataResponse = await http.get(Uri.parse(routesVUrl));
    final data = json.decode(dataResponse.body) as Map<String, dynamic>;

    return {
      'salt': data['s'][8],
      'iv': data['v'][32],
      'public_key': data['arr'][zoomLevelSum],
    };
  }

  static String _decryptContent(
    String content,
    String key,
    String salt,
    String iv,
  ) {
    final ciphertext = base64.decode(content);
    final saltBytes = _hexToBytes(salt);
    final ivBytes = _hexToBytes(iv);

    // Derive key using PBKDF2
    final hmac = HMac(SHA1Digest(), 64);
    final pbkdf2 = PBKDF2KeyDerivator(hmac);
    pbkdf2.init(Pbkdf2Parameters(saltBytes, 1000, 16));
    final derivedKey = pbkdf2.process(Uint8List.fromList(utf8.encode(key)));

    // Decrypt with AES-CBC
    final cipher = CBCBlockCipher(AESEngine());
    cipher.init(false, ParametersWithIV(KeyParameter(derivedKey), ivBytes));

    final decrypted = Uint8List(ciphertext.length);
    int offset = 0;
    while (offset < ciphertext.length) {
      final bytesProcessed = cipher.processBlock(
        ciphertext,
        offset,
        decrypted,
        offset,
      );
      offset += bytesProcessed;
    }

    // Remove PKCS7 padding and decode
    final paddingLength = decrypted.last;
    final unpaddedData = decrypted.sublist(0, decrypted.length - paddingLength);
    return utf8.decode(unpaddedData);
  }

  static Map<String, dynamic> _parseEncryptedResponse(
    String encryptedData,
    Map<String, String> encryptionParams,
  ) {
    final contentHashLength = encryptedData.length - masterSegment;
    final contentHash = encryptedData.substring(0, contentHashLength);
    final privateKeyHash = encryptedData.substring(contentHashLength);

    // Decrypt private key and extract the key before "|"
    final decryptedPrivateKey = _decryptContent(
      privateKeyHash,
      encryptionParams['public_key']!,
      encryptionParams['salt']!,
      encryptionParams['iv']!,
    );
    final privateKey = decryptedPrivateKey.split('|')[0];

    // Decrypt content using the private key
    final decryptedContent = _decryptContent(
      contentHash,
      privateKey,
      encryptionParams['salt']!,
      encryptionParams['iv']!,
    );
    return json.decode(decryptedContent);
  }
}

// void main() async {
//   final data = await AmtrakDecrypt.getTrainData();
//   print(json.encode(data));
// }
