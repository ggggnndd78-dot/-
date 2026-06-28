import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/network/api_client.dart';

final walletLoyaltyRepositoryProvider =
    Provider<WalletLoyaltyRepository>((ref) {
  return WalletLoyaltyRepository(ref.watch(apiClientProvider));
});

class WalletLoyaltyRepository {
  WalletLoyaltyRepository(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> _map(Future<dynamic> future) async {
    final response = await future;
    final data = response.data;
    return data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> myWallet() async => _map(_api.get('/wallet/me'));
  Future<Map<String, dynamic>> walletLedger() async =>
      _map(_api.get('/wallet/me/ledger'));
  Future<Map<String, dynamic>> topUpWallet(double amount) async => _map(_api
      .post('/wallet/me/topups', data: {'amount': amount, 'currency': 'YER'}));
  Future<Map<String, dynamic>> payOrderWithWallet(int orderId) async =>
      _map(_api.post('/wallet/orders/$orderId/pay'));

  Future<Map<String, dynamic>> myLoyalty() async =>
      _map(_api.get('/loyalty/me'));
  Future<Map<String, dynamic>> loyaltyTransactions() async =>
      _map(_api.get('/loyalty/me/transactions'));
  Future<Map<String, dynamic>> redeemPoints(int points) async =>
      _map(_api.post('/loyalty/redeem-to-wallet', data: {'points': points}));
  Future<Map<String, dynamic>> coupons() async =>
      _map(_api.get('/loyalty/coupons'));
  Future<Map<String, dynamic>> validateCoupon(
          String code, double amount) async =>
      _map(_api.post('/loyalty/coupons/validate',
          data: {'code': code, 'amount': amount, 'scope': 'ALL'}));

  Future<Map<String, dynamic>> referralDashboard() async =>
      _map(_api.get('/referrals/me'));
  Future<Map<String, dynamic>> createReferralCode() async =>
      _map(_api.post('/referrals/me/code'));
  Future<Map<String, dynamic>> applyReferralCode(String code) async =>
      _map(_api.post('/referrals/apply', data: {'code': code}));
  Future<Map<String, dynamic>> adminCoupons() async =>
      _map(_api.get('/loyalty/coupons/manage'));
  Future<Map<String, dynamic>> createCoupon(
      {required String code,
      required String titleAr,
      required String discountType,
      required double discountValue,
      String scope = 'ALL'}) async {
    return _map(_api.post('/loyalty/coupons', data: {
      'code': code,
      'titleAr': titleAr,
      'discountType': discountType,
      'discountValue': discountValue,
      'scope': scope,
      'status': 'ACTIVE',
    }));
  }

  Future<Map<String, dynamic>> campaigns() async =>
      _map(_api.get('/retention/campaigns/manage'));
  Future<Map<String, dynamic>> createCampaign(
      {required String title,
      required String messageTitle,
      required String messageBody,
      String audienceType = 'ALL_CUSTOMERS'}) async {
    return _map(_api.post('/retention/campaigns', data: {
      'title': title,
      'audienceType': audienceType,
      'messageTitle': messageTitle,
      'messageBody': messageBody,
    }));
  }
}
