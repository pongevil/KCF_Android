/// Central endpoint registry for APIs hosted below the configured gateway.
class ApiEndpoints {
  ApiEndpoints._();

  static const securityLogin = 'WM3_Security/Secure/Login';
  static const securityLogout = 'WM3_Security/Secure/Logout';
  static const securityMenu = 'WM3_Security/Secure/GetMenu';
  static const securityResource = 'WM3_Security/resource';

  static const mobileConfigDecimal = 'WM3_API_Mobile/api/ConfigApp/GetDecimal';
  static const mobileBarcodeFormat =
      'WM3_API_Mobile/api/ConfigApp/GetBarcodeFormat';
  static const mobileGoodsReceiveSetup =
      'WM3_API_Mobile/api/GoodsReceiveWeightScale/Setup';
  static const mobileGoodsReceiveReceive =
      'WM3_API_Mobile/api/GoodsReceiveWeightScale/Receive';
  static const mobileGoodsReceiveLabels =
      'WM3_API_Mobile/api/GoodsReceiveWeightScale/Labels';
  static const mobileGoodsReceiveClose =
      'WM3_API_Mobile/api/GoodsReceiveWeightScale/CloseLatestOrder';
  static const mobileWeightScaleMappings =
      'WM3_API_Mobile/api/WeightScaleMapping/GetMappings';
  static const mobileSessionLogout = 'WM3_API_Mobile/api/MobileSession/Logout';
}
