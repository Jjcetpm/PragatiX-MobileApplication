import 'dart:async';
import 'dart:io';

/// Accurately checks whether the physical device has active Internet connectivity.
/// Probes public DNS servers via TCP socket (1.1.1.1:53, 8.8.8.8:53) and DNS lookups.
/// NOTE: Never relies on NetworkInterface.list alone, because mobile devices and emulators
/// maintain loopback/virtual interfaces even when Wi-Fi and Cellular data are completely off.
Future<bool> checkDeviceInternetConnectivity() async {
  // Test 1: Direct TCP socket probe to Cloudflare DNS 1.1.1.1:53 (very fast and reliable)
  try {
    final socket = await Socket.connect('1.1.1.1', 53,
        timeout: const Duration(milliseconds: 1200));
    socket.destroy();
    return true;
  } catch (_) {}

  // Test 2: Secondary TCP socket probe to Google DNS 8.8.8.8:53
  try {
    final socket = await Socket.connect('8.8.8.8', 53,
        timeout: const Duration(milliseconds: 1200));
    socket.destroy();
    return true;
  } catch (_) {}

  // Test 3: DNS query probe to public DNS (dns.google)
  try {
    final lookup = await InternetAddress.lookup('dns.google')
        .timeout(const Duration(milliseconds: 1200));
    if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
      return true;
    }
  } catch (_) {}

  // Test 4: Secondary DNS lookup probe to cloudflare.com
  try {
    final lookup = await InternetAddress.lookup('cloudflare.com')
        .timeout(const Duration(milliseconds: 1200));
    if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
      return true;
    }
  } catch (_) {}

  return false;
}

/// Helper alias for backwards compatibility
Future<bool> isDeviceConnectedToNetwork() => checkDeviceInternetConnectivity();
