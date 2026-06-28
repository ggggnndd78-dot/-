import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_organization_model.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_settings_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantStoreProfilePage extends ConsumerStatefulWidget {
  const MerchantStoreProfilePage({super.key});

  @override
  ConsumerState<MerchantStoreProfilePage> createState() =>
      _MerchantStoreProfilePageState();
}

class _MerchantStoreProfilePageState
    extends ConsumerState<MerchantStoreProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _legalName = TextEditingController();
  final _commercialRegistration = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _whatsapp = TextEditingController();
  final _logo = TextEditingController();
  final _cover = TextEditingController();
  final _vacationMessage = TextEditingController();

  final _bankName = TextEditingController();
  final _accountName = TextEditingController();
  final _accountNumber = TextEditingController();
  final _iban = TextEditingController();
  bool _bankPrimary = false;

  late Future<_StoreProfileBundle> _future;
  bool _saving = false;
  bool _savingBank = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _displayName,
      _legalName,
      _commercialRegistration,
      _phone,
      _email,
      _whatsapp,
      _logo,
      _cover,
      _vacationMessage,
      _bankName,
      _accountName,
      _accountNumber,
      _iban,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<_StoreProfileBundle> _load() async {
    final repo = ref.read(merchantMarketRepositoryProvider);
    final organization = await repo.getMerchantOrganization();
    _displayName.text = organization.name;
    _legalName.text = organization.legalName ?? '';
    _commercialRegistration.text = organization.commercialRegistration ?? '';
    _phone.text = organization.phone ?? '';
    _email.text = organization.contactEmail ?? '';
    _whatsapp.text = organization.whatsappPhone ?? '';
    _logo.text = organization.logoUrl ?? '';
    _cover.text = organization.coverUrl ?? '';
    _vacationMessage.text = organization.vacationMessage ?? '';
    final bankAccounts = await repo.getBankAccounts();
    final readiness = await repo.getMerchantReadiness();
    return _StoreProfileBundle(
      organization: organization,
      bankAccounts: bankAccounts,
      readiness: readiness,
    );
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _save(MerchantOrganizationModel organization) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(merchantMarketRepositoryProvider)
          .updateMerchantOrganization(
            organizationId: organization.id,
            displayName: _displayName.text,
            legalName: _legalName.text,
            commercialRegistration: _commercialRegistration.text,
            primaryPhone: _phone.text,
            contactEmail: _email.text,
            whatsappPhone: _whatsapp.text,
            logoUrl: _logo.text,
            coverUrl: _cover.text,
            vacationMessage: _vacationMessage.text,
          );
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم تحديث ملف المتجر')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addBankAccount() async {
    if (_bankName.text.trim().isEmpty ||
        _accountName.text.trim().isEmpty ||
        _accountNumber.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('أدخل اسم البنك واسم الحساب ورقم الحساب')));
      return;
    }
    setState(() => _savingBank = true);
    try {
      await ref.read(merchantMarketRepositoryProvider).createBankAccount(
            bankName: _bankName.text,
            accountName: _accountName.text,
            accountNumber: _accountNumber.text,
            iban: _iban.text,
            isPrimary: _bankPrimary,
          );
      _bankName.clear();
      _accountName.clear();
      _accountNumber.clear();
      _iban.clear();
      _bankPrimary = false;
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة الحساب البنكي')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _savingBank = false);
    }
  }

  Future<void> _deleteBank(String id) async {
    try {
      await ref.read(merchantMarketRepositoryProvider).deleteBankAccount(id);
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حذف الحساب البنكي')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StoreProfileBundle>(
      future: _future,
      builder: (context, snapshot) {
        return MerchantManagementScaffold(
          title: 'ملف المتجر',
          subtitle: 'بيانات الهوية، الحسابات البنكية، وجاهزية الإطلاق',
          onRefresh: _reload,
          children: [
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              MerchantStateCard(
                icon: Icons.error_outline,
                title: 'تعذر تحميل ملف المتجر',
                message: snapshot.error.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: () => setState(() => _future = _load()),
              )
            else ...[
              _ReadinessCard(readiness: snapshot.requireData.readiness),
              const SizedBox(height: 14),
              _IdentityForm(
                formKey: _formKey,
                organization: snapshot.requireData.organization,
                displayName: _displayName,
                legalName: _legalName,
                commercialRegistration: _commercialRegistration,
                phone: _phone,
                email: _email,
                whatsapp: _whatsapp,
                logo: _logo,
                cover: _cover,
                vacationMessage: _vacationMessage,
                saving: _saving,
                onSave: () => _save(snapshot.requireData.organization),
              ),
              const SizedBox(height: 14),
              _BankAccountsPanel(
                accounts: snapshot.requireData.bankAccounts,
                bankName: _bankName,
                accountName: _accountName,
                accountNumber: _accountNumber,
                iban: _iban,
                isPrimary: _bankPrimary,
                saving: _savingBank,
                onPrimaryChanged: (value) =>
                    setState(() => _bankPrimary = value),
                onAdd: _addBankAccount,
                onDelete: _deleteBank,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StoreProfileBundle {
  const _StoreProfileBundle(
      {required this.organization,
      required this.bankAccounts,
      required this.readiness});
  final MerchantOrganizationModel organization;
  final List<MerchantBankAccountModel> bankAccounts;
  final MerchantReadinessModel readiness;
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.readiness});
  final MerchantReadinessModel readiness;

  @override
  Widget build(BuildContext context) {
    return MerchantPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('جاهزية المتجر للإطلاق: ${readiness.percent}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.textPrimary)),
              ),
              CircleAvatar(child: Text('${readiness.percent}%')),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: readiness.percent / 100),
          const SizedBox(height: 12),
          ...readiness.items.map((item) => Material(
                type: MaterialType.transparency,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    item.done
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: item.done ? AppColors.success : AppColors.warning,
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle:
                      item.description == null ? null : Text(item.description!),
                ),
              )),
        ],
      ),
    );
  }
}

class _IdentityForm extends StatelessWidget {
  const _IdentityForm({
    required this.formKey,
    required this.organization,
    required this.displayName,
    required this.legalName,
    required this.commercialRegistration,
    required this.phone,
    required this.email,
    required this.whatsapp,
    required this.logo,
    required this.cover,
    required this.vacationMessage,
    required this.saving,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final MerchantOrganizationModel organization;
  final TextEditingController displayName;
  final TextEditingController legalName;
  final TextEditingController commercialRegistration;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController whatsapp;
  final TextEditingController logo;
  final TextEditingController cover;
  final TextEditingController vacationMessage;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return MerchantPanel(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('هوية المتجر',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF082B51))),
            const SizedBox(height: 12),
            TextFormField(
                controller: displayName,
                decoration: const InputDecoration(labelText: 'اسم المتجر'),
                validator: (v) =>
                    (v ?? '').trim().length < 2 ? 'اسم المتجر مطلوب' : null),
            const SizedBox(height: 10),
            TextFormField(
                controller: legalName,
                decoration: const InputDecoration(labelText: 'الاسم القانوني')),
            const SizedBox(height: 10),
            TextFormField(
                controller: commercialRegistration,
                decoration: const InputDecoration(
                    labelText: 'رقم السجل التجاري / الترخيص')),
            const SizedBox(height: 10),
            TextFormField(
                controller: phone,
                decoration:
                    const InputDecoration(labelText: 'رقم الهاتف الرئيسي'),
                keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            TextFormField(
                controller: whatsapp,
                decoration:
                    const InputDecoration(labelText: 'رقم واتساب الخدمة'),
                keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            TextFormField(
                controller: email,
                decoration: const InputDecoration(labelText: 'بريد التواصل'),
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 10),
            TextFormField(
                controller: logo,
                decoration:
                    const InputDecoration(labelText: 'رابط شعار المتجر')),
            const SizedBox(height: 10),
            TextFormField(
                controller: cover,
                decoration:
                    const InputDecoration(labelText: 'رابط صورة الغلاف')),
            const SizedBox(height: 10),
            TextFormField(
                controller: vacationMessage,
                decoration:
                    const InputDecoration(labelText: 'رسالة وضع الإجازة'),
                maxLines: 2),
            const SizedBox(height: 14),
            FilledButton.icon(
                onPressed: saving ? null : onSave,
                icon: const Icon(Icons.save_outlined),
                label: Text(saving ? 'جارٍ الحفظ...' : 'حفظ بيانات المتجر')),
          ],
        ),
      ),
    );
  }
}

class _BankAccountsPanel extends StatelessWidget {
  const _BankAccountsPanel({
    required this.accounts,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.iban,
    required this.isPrimary,
    required this.saving,
    required this.onPrimaryChanged,
    required this.onAdd,
    required this.onDelete,
  });

  final List<MerchantBankAccountModel> accounts;
  final TextEditingController bankName;
  final TextEditingController accountName;
  final TextEditingController accountNumber;
  final TextEditingController iban;
  final bool isPrimary;
  final bool saving;
  final ValueChanged<bool> onPrimaryChanged;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return MerchantPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('الحسابات البنكية',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF082B51))),
          const SizedBox(height: 8),
          if (accounts.isEmpty)
            const Text(
                'لا يوجد حساب بنكي بعد. أضف حسابًا لتفعيل السحوبات والتسويات.',
                style: TextStyle(color: Color(0xFF687686)))
          else
            ...accounts.map((account) => Card(
                  child: ListTile(
                    title: Text('${account.bankName} - ${account.accountName}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                        'رقم الحساب: ${account.accountNumber}${account.iban == null ? '' : '\nIBAN: ${account.iban}'}'),
                    leading: Icon(
                        account.isPrimary
                            ? Icons.star_rounded
                            : Icons.account_balance_outlined,
                        color: account.isPrimary ? Colors.orange : null),
                    trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => onDelete(account.id)),
                  ),
                )),
          const Divider(height: 28),
          TextField(
              controller: bankName,
              decoration: const InputDecoration(labelText: 'اسم البنك')),
          const SizedBox(height: 10),
          TextField(
              controller: accountName,
              decoration: const InputDecoration(labelText: 'اسم صاحب الحساب')),
          const SizedBox(height: 10),
          TextField(
              controller: accountNumber,
              decoration: const InputDecoration(labelText: 'رقم الحساب'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          const SizedBox(height: 10),
          TextField(
              controller: iban,
              decoration: const InputDecoration(labelText: 'IBAN اختياري')),
          SwitchListTile(
              value: isPrimary,
              onChanged: onPrimaryChanged,
              title: const Text('تعيينه كحساب رئيسي')),
          FilledButton.icon(
              onPressed: saving ? null : onAdd,
              icon: const Icon(Icons.add_card_outlined),
              label: Text(saving ? 'جارٍ الإضافة...' : 'إضافة الحساب البنكي')),
        ],
      ),
    );
  }
}
