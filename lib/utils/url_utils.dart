import 'package:url_launcher/url_launcher.dart';

class UrlUtils {
  static Future<bool> openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openPolygonTx(String txHash) {
    final cleanTx = txHash.startsWith('0x') ? txHash : '0x$txHash';
    return openUrl('https://amoy.polygonscan.com/tx/$cleanTx');
  }

  static Future<bool> openPolygonAddress(String address) {
    final cleanAddr = address.startsWith('0x') ? address : '0x$address';
    return openUrl('https://amoy.polygonscan.com/address/$cleanAddr');
  }

  static Future<bool> openIpfsCid(String cid) {
    return openUrl('https://gateway.pinata.cloud/ipfs/$cid');
  }
}
