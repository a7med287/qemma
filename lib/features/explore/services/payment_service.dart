import 'api_service.dart';

class PaymentService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getItemDetails(String itemId, String itemType) async {
    final res = await _api.get('/payments/item/$itemType/$itemId');
    return res['data'];
  }

  Future<Map<String, dynamic>> validatePromoCode(String code) async {
    final res = await _api.post('/payments/validate-promo', body: {'code': code});
    return res['data'];
  }

  Future<Map<String, dynamic>> processPayment({
    required String itemId,
    required String itemType,
    required String paymentMethod,
    String? promoCode,
    required double totalAmount,
  }) async {
    final res = await _api.post('/payments/process', body: {
      'itemId': itemId,
      'itemType': itemType,
      'paymentMethod': paymentMethod,
      'promoCode': promoCode,
      'totalAmount': totalAmount,
    });
    return res['data'];
  }
}
