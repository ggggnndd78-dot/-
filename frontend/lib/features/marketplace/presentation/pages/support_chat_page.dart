import 'package:flutter/material.dart';
import 'package:ghiyarak/features/chat/presentation/customer_chat_page.dart';

class SupportChatPage extends StatelessWidget {
  const SupportChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomerChatPage(
      listingId: 'support',
      listingTitle: 'دعم العميل',
      providerName: 'خدمة العملاء',
      providerTypeLabel: 'دعم',
      serviceLabel: 'مساعدة مباشرة',
    );
  }
}
