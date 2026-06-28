import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function seedLocations() {
  const country = await prisma.country.upsert({
    where: { isoCode: 'YE' },
    update: { nameAr: 'اليمن', nameEn: 'Yemen', phoneCode: '+967', isActive: true },
    create: { isoCode: 'YE', nameAr: 'اليمن', nameEn: 'Yemen', phoneCode: '+967' },
  });

  const governorates: Array<{ nameAr: string; nameEn: string; code: string; fee: number; capital: string; districts: string[] }> = [
    { nameAr: 'أمانة العاصمة', nameEn: 'Sana\'a City', code: 'YE-SA-CITY', fee: 1500, capital: 'صنعاء', districts: ['أزال', 'الوحدة', 'الثورة', 'السبعين', 'شعوب', 'معين', 'التحرير', 'الصافية', 'بني الحارث', 'صنعاء القديمة'] },
    { nameAr: 'صنعاء', nameEn: 'Sana\'a Governorate', code: 'YE-SN', fee: 1800, capital: 'صنعاء', districts: ['أرحب', 'نهم', 'بني حشيش', 'همدان', 'سنحان وبني بهلول', 'بلاد الروس', 'خولان', 'جحانة', 'الحيمة الداخلية', 'الحيمة الخارجية', 'مناخة', 'صعفان'] },
    { nameAr: 'عدن', nameEn: 'Aden', code: 'YE-AD', fee: 2200, capital: 'عدن', districts: ['صيرة', 'خور مكسر', 'المعلا', 'التواهي', 'الشيخ عثمان', 'المنصورة', 'دار سعد', 'البريقة'] },
    { nameAr: 'تعز', nameEn: 'Taiz', code: 'YE-TA', fee: 2500, capital: 'تعز', districts: ['القاهرة', 'المظفر', 'صالة', 'التعزية', 'جبل حبشي', 'شرعب الرونة', 'شرعب السلام', 'ماوية', 'المخا', 'موزع', 'الوازعية', 'الشمايتين', 'المسراخ', 'صبر الموادم', 'خدير', 'حيفان'] },
    { nameAr: 'إب', nameEn: 'Ibb', code: 'YE-IB', fee: 2300, capital: 'إب', districts: ['الظهار', 'المشنة', 'ريف إب', 'جبلة', 'العدين', 'فرع العدين', 'حزم العدين', 'القفر', 'يريم', 'الرضمة', 'السدة', 'النادرة', 'بعدان', 'السياني', 'ذي السفال'] },
    { nameAr: 'الحديدة', nameEn: 'Al Hudaydah', code: 'YE-HU', fee: 2400, capital: 'الحديدة', districts: ['الحالي', 'الحوك', 'الميناء', 'باجل', 'بيت الفقيه', 'زبيد', 'التحيتا', 'الجراحي', 'المنصورية', 'القناوص', 'الزيدية', 'اللحية', 'الدريهمي', 'الخوخة'] },
    { nameAr: 'حضرموت', nameEn: 'Hadramout', code: 'YE-HD', fee: 3400, capital: 'المكلا', districts: ['المكلا', 'الشحر', 'غيل باوزير', 'بروم ميفع', 'دوعن', 'سيئون', 'تريم', 'شبام', 'القطن', 'وادي العين وحورة', 'حريضة', 'عمد', 'ثمود'] },
    { nameAr: 'ذمار', nameEn: 'Dhamar', code: 'YE-DH', fee: 2000, capital: 'ذمار', districts: ['مدينة ذمار', 'عنس', 'جهران', 'الحداء', 'جبل الشرق', 'مغرب عنس', 'وصاب العالي', 'وصاب السافل', 'عتمة', 'ميفعة عنس'] },
    { nameAr: 'حجة', nameEn: 'Hajjah', code: 'YE-HJ', fee: 2600, capital: 'حجة', districts: ['حجة', 'مبين', 'كحلان الشرف', 'الشغادرة', 'أفلح اليمن', 'أفلح الشام', 'قفل شمر', 'خيران المحرق', 'عبس', 'حرض', 'ميدي', 'أسلم', 'كشر', 'وشحة', 'بكيل المير'] },
    { nameAr: 'عمران', nameEn: 'Amran', code: 'YE-AM', fee: 2100, capital: 'عمران', districts: ['عمران', 'خمر', 'ريدة', 'حوث', 'حرف سفيان', 'شهارة', 'عيال سريح', 'جبل عيال يزيد', 'بني صريم', 'السودة', 'المدان', 'ذيبين', 'مسور'] },
    { nameAr: 'صعدة', nameEn: 'Saada', code: 'YE-SD', fee: 2800, capital: 'صعدة', districts: ['صعدة', 'سحار', 'الصفراء', 'كتاف والبقع', 'باقم', 'رازح', 'غمر', 'حيدان', 'ساقين', 'مجز', 'شدا', 'منبه'] },
    { nameAr: 'المحويت', nameEn: 'Al Mahwit', code: 'YE-MW', fee: 2200, capital: 'المحويت', districts: ['المحويت', 'الرجم', 'الطويلة', 'شبام كوكبان', 'الخبت', 'حفاش', 'ملحان', 'بني سعد'] },
    { nameAr: 'ريمة', nameEn: 'Raymah', code: 'YE-RA', fee: 2500, capital: 'الجبين', districts: ['الجبين', 'كسمة', 'السلفية', 'مزهر', 'بلاد الطعام', 'الجعفرية'] },
    { nameAr: 'البيضاء', nameEn: 'Al Bayda', code: 'YE-BA', fee: 2700, capital: 'البيضاء', districts: ['البيضاء', 'رداع', 'مكيراس', 'ذي ناعم', 'نعمان', 'ناطع', 'السوادية', 'الطفة', 'الزاهر', 'الشرية', 'العرش', 'القريشية', 'ولد ربيع'] },
    { nameAr: 'مأرب', nameEn: 'Marib', code: 'YE-MA', fee: 3000, capital: 'مأرب', districts: ['مأرب المدينة', 'مأرب الوادي', 'حريب', 'الجوبة', 'رحبة', 'ماهلية', 'العبدية', 'رغوان', 'مدغل', 'صرواح'] },
    { nameAr: 'الجوف', nameEn: 'Al Jawf', code: 'YE-JA', fee: 3000, capital: 'الحزم', districts: ['الحزم', 'خب والشعف', 'برط العنان', 'الحميدات', 'المتون', 'المصلوب', 'الزاهر', 'الغيل', 'المطمة', 'خراب المراشي', 'رجوزة'] },
    { nameAr: 'شبوة', nameEn: 'Shabwah', code: 'YE-SH', fee: 3200, capital: 'عتق', districts: ['عتق', 'بيحان', 'عسيلان', 'عين', 'مرخة العليا', 'مرخة السفلى', 'نصاب', 'حبان', 'رضوم', 'الروضة', 'ميفعة', 'الصعيد', 'جردان'] },
    { nameAr: 'أبين', nameEn: 'Abyan', code: 'YE-AB', fee: 3000, capital: 'زنجبار', districts: ['زنجبار', 'خنفر', 'لودر', 'مودية', 'الوضيع', 'المحفد', 'أحور', 'جيشان', 'رصد', 'سرار', 'سباح'] },
    { nameAr: 'لحج', nameEn: 'Lahj', code: 'YE-LA', fee: 2800, capital: 'الحوطة', districts: ['الحوطة', 'تبن', 'طور الباحة', 'المقاطرة', 'ردفان', 'حبيل جبر', 'يافع', 'المفلحي', 'الحد', 'المسيمير', 'القبيطة', 'الملاح'] },
    { nameAr: 'الضالع', nameEn: 'Ad Dali', code: 'YE-DA', fee: 2900, capital: 'الضالع', districts: ['الضالع', 'قعطبة', 'الحشاء', 'دمت', 'جبن', 'الأزارق', 'الشعيب'] },
    { nameAr: 'المهرة', nameEn: 'Al Mahrah', code: 'YE-MR', fee: 3800, capital: 'الغيضة', districts: ['الغيضة', 'سيحوت', 'قشن', 'حوف', 'شحن', 'حصوين', 'المسيلة', 'منعر'] },
    { nameAr: 'سقطرى', nameEn: 'Socotra', code: 'YE-SU', fee: 4500, capital: 'حديبو', districts: ['حديبو', 'قلنسية وعبد الكوري'] },
  ];

  for (const item of governorates) {
    const state = await prisma.state.upsert({
      where: { id: await (async () => {
        const existing = await prisma.state.findFirst({ where: { countryId: country.id, code: item.code } });
        if (existing) return existing.id;
        const created = await prisma.state.create({ data: { countryId: country.id, nameAr: item.nameAr, nameEn: item.nameEn, code: item.code, isActive: true } });
        return created.id;
      })() },
      update: { countryId: country.id, nameAr: item.nameAr, nameEn: item.nameEn, code: item.code, isActive: true },
      create: { countryId: country.id, nameAr: item.nameAr, nameEn: item.nameEn, code: item.code, isActive: true },
    });

    const cityCode = `${item.code}-CAPITAL`;
    const existingCity = await prisma.city.findFirst({ where: { stateId: state.id, code: cityCode } });
    const city = existingCity
      ? await prisma.city.update({ where: { id: existingCity.id }, data: { nameAr: item.capital, nameEn: item.capital, isActive: true } })
      : await prisma.city.create({ data: { stateId: state.id, nameAr: item.capital, nameEn: item.capital, code: cityCode, isActive: true } });

    await prisma.cityDeliveryFee.upsert({
      where: { cityId: city.id },
      update: { deliveryFee: item.fee, currency: 'YER', isDeliveryAvailable: true, estimatedMinDays: 1, estimatedMaxDays: 3 },
      create: { cityId: city.id, deliveryFee: item.fee, currency: 'YER', isDeliveryAvailable: true, estimatedMinDays: 1, estimatedMaxDays: 3 },
    }).catch(() => null);

    for (const districtName of item.districts) {
      const existingDistrict = await prisma.district.findFirst({ where: { cityId: city.id, nameAr: districtName } });
      const district = existingDistrict
        ? await prisma.district.update({ where: { id: existingDistrict.id }, data: { isActive: true, nameEn: districtName } })
        : await prisma.district.create({ data: { cityId: city.id, nameAr: districtName, nameEn: districtName, isActive: true } });

      const existingArea = await prisma.area.findFirst({ where: { districtId: district.id, nameAr: 'عام' } });
      if (!existingArea) {
        await prisma.area.create({ data: { districtId: district.id, nameAr: 'عام', nameEn: 'General', isActive: true } });
      }

      const existingZone = await prisma.deliveryZone.findFirst({ where: { cityId: city.id, districtId: district.id, nameAr: districtName } }).catch(() => null);
      if (existingZone) {
        await prisma.deliveryZone.update({ where: { id: existingZone.id }, data: { deliveryFee: item.fee, currency: 'YER', isActive: true } }).catch(() => null);
      } else {
        await prisma.deliveryZone.create({ data: { cityId: city.id, districtId: district.id, nameAr: districtName, nameEn: districtName, code: `${item.code}-${district.id}`, deliveryFee: item.fee, currency: 'YER', estimatedMinDays: 1, estimatedMaxDays: 3 } }).catch(() => null);
      }
    }
  }
}

async function seedRolesAndPermissions() {
  const roles = [
    ['customer', 'Customer'],
    ['merchant_owner', 'Merchant Owner'],
    ['merchant_employee', 'Merchant Employee'],
    ['workshop_owner', 'Workshop Owner'],
    ['workshop_employee', 'Workshop Employee'],
    ['warehouse_owner', 'Warehouse Owner'],
    ['warehouse_employee', 'Warehouse Employee'],
    ['driver', 'Delivery Driver'],
    ['support_agent', 'Support Agent'],
    ['finance_manager', 'Finance Manager'],
    ['content_manager', 'Content Manager'],
    ['admin_super', 'Super Admin'],
    ['admin_operations', 'Operations Admin'],
  ] as const;

  for (const [code, name] of roles) {
    await prisma.role.upsert({ where: { code }, update: { name }, create: { code, name } });
  }

  const permissions = [
    ['manage_profile', 'Manage profile', 'users'],
    ['manage_location', 'Manage location', 'locations'],
    ['manage_vehicles', 'Manage vehicles', 'vehicles'],
    ['auth.sessions.manage', 'Manage own authentication sessions', 'auth'],
    ['auth.devices.manage', 'Manage own trusted devices', 'auth'],
    ['memberships.apply', 'Submit membership applications', 'organizations'],
    ['memberships.review', 'Review membership applications', 'admin'],
    ['memberships.documents.view', 'View membership application documents', 'admin'],
    ['cart.manage', 'Manage customer cart', 'orders'],
    ['orders.create', 'Create marketplace orders', 'orders'],
    ['orders.view_own', 'View own orders', 'orders'],
    ['workshop.bookings.create', 'Create workshop bookings as customer', 'workshops'],
    ['admin.orders.view', 'View all orders as admin', 'admin'],
    ['manage_organization', 'Manage organization', 'organizations'],
    ['manage_branches', 'Manage branches', 'organizations'],
    ['manage_employees', 'Manage organization employees', 'employees'],
    ['employee.activity.view', 'View organization employee activity', 'employees'],
    ['manage_bank_accounts', 'Manage bank accounts', 'organizations'],
    ['manage_business_hours', 'Manage business hours', 'organizations'],
    ['submit_verification', 'Submit verification', 'verification'],
    ['review_verifications', 'Review verifications', 'verification'],
    ['view_admin_panel', 'View admin panel', 'admin'],
    ['manage_system', 'Manage system', 'admin'],
    ['view_reports', 'View reports and analytics', 'admin'],
    ['manage_users', 'Manage users', 'admin'],
    ['manage_roles', 'Manage roles and permissions', 'admin'],
    ['view_audit_logs', 'View audit logs', 'admin'],
    ['manage_settings', 'Manage system settings', 'admin'],
    ['merchant.products.manage', 'Manage merchant products', 'merchant'],
    ['merchant.inventory.manage', 'Manage merchant inventory', 'merchant'],
    ['product_imports.manage', 'Manage product Excel imports', 'imports'],
    ['merchant.orders.manage', 'Manage merchant orders', 'merchant'],
    ['merchant.branches.manage', 'Manage merchant branches', 'merchant'],
    ['merchant.employees.manage', 'Manage merchant employees', 'merchant'],
    ['workshop.services.manage', 'Manage workshop services', 'workshops'],
    ['workshop.bookings.manage', 'Manage workshop bookings', 'workshops'],
    ['workshop.service_orders.manage', 'Manage service orders', 'workshops'],
    ['workshop.branches.manage', 'Manage workshop branches', 'workshops'],
    ['workshop.employees.manage', 'Manage workshop employees', 'workshops'],
    ['warehouse.inventory.manage', 'Manage warehouse inventory', 'warehouse'],
    ['warehouse.employees.manage', 'Manage warehouse employees', 'warehouse'],
    ['finance.payments.review', 'Review payments', 'finance'],
    ['finance.accounting.manage', 'Manage accounting', 'finance'],
    ['content.banners.manage', 'Manage banners and content', 'content'],
    ['support.tickets.manage', 'Manage support tickets', 'support'],
    ['support.content.manage', 'Manage help center, FAQs and support content', 'support'],
    ['support.whatsapp.manage', 'Manage WhatsApp support links', 'support'],
    ['delivery.shipments.manage', 'Manage shipments', 'delivery'],
    ['delivery.drivers.manage', 'Manage delivery drivers', 'delivery'],
    ['delivery.fees.manage', 'Manage delivery fees', 'delivery'],
    ['delivery.companies.manage', 'Manage local shipping companies', 'delivery'],
    ['manage_workshop_services', 'Manage workshop services legacy', 'workshops'],
    ['manage_workshop_bookings', 'Manage workshop bookings legacy', 'workshops'],
    ['manage_service_orders', 'Manage service orders legacy', 'workshops'],
    ['manage_payments', 'Manage payments legacy', 'payments'],
    ['manage_delivery', 'Manage delivery operations legacy', 'delivery'],
    ['manage_notifications', 'Manage notifications', 'notifications'],
    ['manage_support', 'Manage support tickets legacy', 'support'],
    ['manage_complaints', 'Manage complaints', 'support'],
    ['manage_reviews', 'Manage reviews moderation', 'reviews'],
    ['reviews.create', 'Create verified reviews', 'reviews'],
    ['reviews.reply.manage', 'Manage organization review replies', 'reviews'],
    ['reviews.moderate', 'Moderate reviews', 'reviews'],
    ['reviews.analytics.view', 'View review analytics', 'reviews'],
    ['manage_wallets', 'Manage wallet operations', 'wallet'],
    ['manage_loyalty', 'Manage loyalty and coupons', 'loyalty'],
    ['manage_retention', 'Manage retention campaigns', 'retention'],
    ['finance.wallets.manage', 'Manage wallets and wallet adjustments', 'wallet'],
    ['loyalty.manage', 'Manage loyalty rules and adjustments', 'loyalty'],
    ['coupons.manage', 'Manage coupon campaigns', 'loyalty'],
    ['referrals.manage', 'Manage referral rewards', 'loyalty'],
    ['quality.readiness.view', 'View QA and release readiness', 'quality'],
    ['quality.runs.view', 'View QA test runs', 'quality'],
    ['quality.runs.manage', 'Manage QA test runs', 'quality'],
    ['release.manage', 'Manage release checklist and deployments', 'release'],
  ] as const;

  for (const [code, name, moduleCode] of permissions) {
    await prisma.permission.upsert({
      where: { code },
      update: { name, moduleCode },
      create: { code, name, moduleCode },
    });
  }

  const grants: Record<string, string[]> = {
    customer: ['manage_profile', 'manage_location', 'manage_vehicles', 'auth.sessions.manage', 'auth.devices.manage', 'memberships.apply', 'cart.manage', 'orders.create', 'orders.view_own', 'workshop.bookings.create', 'reviews.create'],
    merchant_owner: [
      'manage_profile', 'manage_organization', 'manage_branches', 'manage_employees',
      'manage_bank_accounts', 'manage_business_hours', 'employee.activity.view', 'submit_verification',
      'merchant.products.manage', 'merchant.inventory.manage', 'product_imports.manage', 'merchant.orders.manage',
      'merchant.branches.manage', 'merchant.employees.manage', 'delivery.shipments.manage', 'delivery.drivers.manage', 'delivery.fees.manage', 'reviews.reply.manage', 'reviews.analytics.view', 'view_reports',
    ],
    merchant_employee: ['merchant.products.manage', 'merchant.inventory.manage', 'merchant.orders.manage', 'delivery.shipments.manage', 'reviews.reply.manage'],
    workshop_owner: [
      'manage_profile', 'manage_organization', 'manage_branches', 'manage_employees',
      'manage_bank_accounts', 'manage_business_hours', 'employee.activity.view', 'submit_verification',
      'product_imports.manage', 'workshop.services.manage', 'workshop.bookings.manage', 'workshop.service_orders.manage',
      'workshop.branches.manage', 'workshop.employees.manage', 'manage_workshop_services', 'manage_workshop_bookings', 'manage_service_orders', 'manage_payments',
      'delivery.shipments.manage', 'delivery.drivers.manage', 'delivery.fees.manage', 'manage_delivery', 'manage_notifications', 'reviews.reply.manage', 'reviews.analytics.view',
    ],
    workshop_employee: ['workshop.services.manage', 'workshop.bookings.manage', 'workshop.service_orders.manage', 'delivery.shipments.manage', 'manage_workshop_services', 'manage_workshop_bookings', 'manage_service_orders', 'reviews.reply.manage'],
    warehouse_owner: ['manage_profile', 'auth.sessions.manage', 'auth.devices.manage', 'memberships.apply', 'manage_organization', 'manage_branches', 'manage_employees', 'submit_verification', 'warehouse.inventory.manage', 'product_imports.manage', 'warehouse.employees.manage'],
    warehouse_employee: ['warehouse.inventory.manage', 'product_imports.manage'],
    driver: ['delivery.shipments.manage'],
    finance_manager: ['auth.sessions.manage', 'auth.devices.manage', 'finance.payments.review', 'finance.accounting.manage', 'manage_payments', 'view_reports', 'finance.wallets.manage', 'loyalty.manage', 'coupons.manage', 'referrals.manage', 'quality.readiness.view', 'quality.runs.view'],
    content_manager: ['content.banners.manage', 'manage_notifications'],
    support_agent: ['auth.sessions.manage', 'auth.devices.manage', 'support.tickets.manage', 'support.content.manage', 'support.whatsapp.manage', 'manage_support', 'manage_complaints', 'manage_reviews', 'reviews.moderate', 'reviews.analytics.view', 'reviews.moderate', 'reviews.analytics.view', 'manage_notifications'],
    admin_operations: ['auth.sessions.manage', 'auth.devices.manage', 'memberships.review', 'memberships.documents.view', 'review_verifications', 'view_admin_panel', 'admin.orders.view', 'workshop.bookings.create', 'workshop.services.manage', 'workshop.bookings.manage', 'workshop.service_orders.manage', 'manage_workshop_services', 'manage_service_orders', 'manage_location', 'view_reports', 'manage_users', 'view_audit_logs', 'manage_workshop_bookings', 'manage_payments', 'delivery.shipments.manage', 'delivery.drivers.manage', 'delivery.fees.manage', 'delivery.shipments.manage', 'delivery.drivers.manage', 'delivery.fees.manage', 'delivery.companies.manage', 'manage_delivery', 'manage_notifications', 'reviews.reply.manage', 'reviews.analytics.view', 'support.content.manage', 'support.whatsapp.manage', 'manage_support', 'manage_complaints', 'manage_reviews', 'reviews.moderate', 'reviews.analytics.view', 'manage_wallets', 'manage_loyalty', 'manage_retention', 'finance.wallets.manage', 'loyalty.manage', 'coupons.manage', 'referrals.manage', 'quality.readiness.view', 'quality.runs.view', 'quality.runs.manage', 'release.manage', 'manage_roles', 'finance.payments.review', 'finance.accounting.manage', 'merchant.products.manage', 'merchant.inventory.manage', 'merchant.orders.manage', 'merchant.branches.manage', 'merchant.employees.manage', 'workshop.branches.manage', 'workshop.employees.manage', 'manage_settings'],
    admin_super: permissions.map(([code]) => code),
  };

  for (const [roleCode, permissionCodes] of Object.entries(grants)) {
    const role = await prisma.role.findUniqueOrThrow({ where: { code: roleCode } });
    for (const permissionCode of permissionCodes) {
      const permission = await prisma.permission.findUniqueOrThrow({ where: { code: permissionCode } });
      await prisma.rolePermission.upsert({
        where: { roleId_permissionId: { roleId: role.id, permissionId: permission.id } },
        update: {},
        create: { roleId: role.id, permissionId: permission.id },
      });
    }
  }
}

async function seedVehicles() {
  const makes = [
    ['toyota', 'تويوتا', 'Toyota'],
    ['hyundai', 'هيونداي', 'Hyundai'],
    ['kia', 'كيا', 'Kia'],
    ['nissan', 'نيسان', 'Nissan'],
    ['isuzu', 'ايسوزو', 'Isuzu'],
    ['mitsubishi', 'ميتسوبيشي', 'Mitsubishi'],
    ['ford', 'فورد', 'Ford'],
    ['chevrolet', 'شيفروليه', 'Chevrolet'],
    ['gmc', 'جي ام سي', 'GMC'],
    ['lexus', 'لكزس', 'Lexus'],
    ['honda', 'هوندا', 'Honda'],
    ['mercedes-benz', 'مرسيدس', 'Mercedes-Benz'],
    ['bmw', 'بي إم دبليو', 'BMW'],
    ['changan', 'شانجان', 'Changan'],
    ['geely', 'جيلي', 'Geely'],
    ['mg', 'إم جي', 'MG'],
  ] as const;

  const models: Record<string, string[]> = {
    toyota: ['Camry', 'Corolla', 'Land Cruiser', 'Hilux'],
    hyundai: ['Elantra', 'Sonata', 'Tucson'],
    kia: ['Cerato', 'Sportage', 'Sorento'],
    nissan: ['Sunny', 'Altima', 'Patrol'],
    isuzu: ['D-Max'],
    mitsubishi: ['Lancer', 'Pajero'],
    ford: ['Explorer', 'F-150'],
    chevrolet: ['Tahoe', 'Captiva'],
    gmc: ['Yukon', 'Sierra'],
    lexus: ['ES', 'LX'],
    honda: ['Accord', 'Civic', 'CR-V'],
    'mercedes-benz': ['C-Class', 'E-Class'],
    bmw: ['3 Series', '5 Series'],
    changan: ['CS35', 'CS75'],
    geely: ['Coolray', 'Emgrand'],
    mg: ['MG5', 'ZS'],
  };

  for (const [slug, nameAr, nameEn] of makes) {
    const make = await prisma.vehicleMake.upsert({
      where: { slug },
      update: { nameAr, nameEn, isActive: true },
      create: { slug, nameAr, nameEn },
    });

    for (const modelName of models[slug] ?? []) {
      const model = await prisma.vehicleModel.create({
        data: {
          makeId: make.id,
          nameAr: modelName,
          nameEn: modelName,
          slug: `${slug.toLowerCase()}-${modelName.toLowerCase()}`,
        },
      }).catch(async () => prisma.vehicleModel.findFirstOrThrow({ where: { makeId: make.id, nameAr: modelName } }));

      const generation = await prisma.vehicleGeneration.create({
        data: {
          modelId: model.id,
          generationName: 'الجيل الحديث',
          yearFrom: 2018,
          yearTo: 2025,
        },
      }).catch(async () => prisma.vehicleGeneration.findFirstOrThrow({ where: { modelId: model.id } }));

      await prisma.vehicleVariant.create({
        data: {
          modelId: model.id,
          generationId: generation.id,
          trimName: 'Standard',
          yearFrom: 2018,
          yearTo: 2025,
          transmissionType: 'automatic',
          fuelType: 'gasoline',
        },
      }).catch(() => null);
    }
  }
}


function e164(localPhone: string) {
  return `+967${localPhone}`;
}

function assertSeedYemeniMobile(localPhone: string) {
  if (!/^(70|71|73|77|78)\d{7}$/.test(localPhone)) {
    throw new Error(`Invalid seeded Yemeni mobile number: ${localPhone}`);
  }
}

async function upsertDemoUser(localPhone: string, displayName: string, roleCode: string, email?: string) {
  assertSeedYemeniMobile(localPhone);
  const user = await prisma.user.upsert({
    where: { phoneNormalized: localPhone },
    update: {
      phoneE164: e164(localPhone),
      displayName,
      email: email ?? undefined,
      isPhoneVerified: true,
      status: 'ACTIVE' as any,
      locale: 'ar',
    },
    create: {
      phoneE164: e164(localPhone),
      phoneNormalized: localPhone,
      email,
      displayName,
      isPhoneVerified: true,
      status: 'ACTIVE' as any,
      locale: 'ar',
      customerProfile: { create: { displayName } },
    },
  });
  const role = await prisma.role.findUniqueOrThrow({ where: { code: roleCode } });
  await prisma.userRole.upsert({
    where: { userId_roleId: { userId: user.id, roleId: role.id } },
    update: {},
    create: { userId: user.id, roleId: role.id },
  });
  return user;
}

async function ensureOrganizationMembership(organizationId: number, userId: number, memberRole: string) {
  await prisma.organizationMember.upsert({
    where: { organizationId_userId: { organizationId, userId } },
    update: { memberRole, status: 'ACTIVE' as any, allBranches: true },
    create: { organizationId, userId, memberRole, status: 'ACTIVE' as any, allBranches: true },
  });
}

async function seedAdminAndSamples() {
  const adminPhone = '781699203';
  const admin = await prisma.user.upsert({
    where: { phoneNormalized: adminPhone },
    update: { displayName: 'Super Admin' },
    create: {
      phoneE164: `+967${adminPhone}`,
      phoneNormalized: adminPhone,
      displayName: 'Super Admin',
      isPhoneVerified: true,
      customerProfile: { create: { displayName: 'Super Admin' } },
    },
  });

  const adminRole = await prisma.role.findUniqueOrThrow({ where: { code: 'admin_super' } });
  await prisma.userRole.upsert({
    where: { userId_roleId: { userId: admin.id, roleId: adminRole.id } },
    update: {},
    create: { userId: admin.id, roleId: adminRole.id },
  });

  const merchantOwnerPhone = '711111111';
  const merchantOwner = await prisma.user.upsert({
    where: { phoneNormalized: merchantOwnerPhone },
    update: { displayName: 'مالك التاجر' },
    create: {
      phoneE164: `+967${merchantOwnerPhone}`,
      phoneNormalized: merchantOwnerPhone,
      displayName: 'مالك التاجر',
      isPhoneVerified: true,
      customerProfile: { create: { displayName: 'مالك التاجر' } },
    },
  });
  const merchantRole = await prisma.role.findUniqueOrThrow({ where: { code: 'merchant_owner' } });
  await prisma.userRole.upsert({
    where: { userId_roleId: { userId: merchantOwner.id, roleId: merchantRole.id } },
    update: {},
    create: { userId: merchantOwner.id, roleId: merchantRole.id },
  });

  const workshopOwnerPhone = '733333333';
  const workshopOwner = await prisma.user.upsert({
    where: { phoneNormalized: workshopOwnerPhone },
    update: { displayName: 'مالك الورشة' },
    create: {
      phoneE164: `+967${workshopOwnerPhone}`,
      phoneNormalized: workshopOwnerPhone,
      displayName: 'مالك الورشة',
      isPhoneVerified: true,
      customerProfile: { create: { displayName: 'مالك الورشة' } },
    },
  });
  const workshopRole = await prisma.role.findUniqueOrThrow({ where: { code: 'workshop_owner' } });
  await prisma.userRole.upsert({
    where: { userId_roleId: { userId: workshopOwner.id, roleId: workshopRole.id } },
    update: {},
    create: { userId: workshopOwner.id, roleId: workshopRole.id },
  });

  const district = await prisma.district.findFirstOrThrow({ where: { nameAr: 'التحرير' }, include: { city: true } });
  const city = district.city;
  const area = await prisma.area.findFirstOrThrow({ where: { districtId: district.id } });

  const merchantOrg = await prisma.organization.create({
    data: {
      organizationType: 'MERCHANT' as any,
      displayName: 'مؤسسة غيارك التجارية',
      legalName: 'Ghiyarak Trading',
      primaryPhone: merchantOwnerPhone,
      status: 'APPROVED' as any,
      submittedAt: new Date(),
      approvedAt: new Date(),
      isVerified: true,
      members: {
        create: { userId: merchantOwner.id, memberRole: 'owner' },
      },
      merchantProfile: {
        create: {
          businessCategoryCode: 'auto-parts',
          averagePreparationMinutes: 45,
          warrantyPolicyText: 'ضمان حسب نوع القطعة',
          returnPolicyText: 'الاسترجاع خلال 3 أيام بشرط سلامة المنتج',
          deliveryPolicyText: 'التوصيل خلال 24 ساعة داخل المدينة',
          minOrderAmount: 0,
        },
      },
    },
  }).catch(async () => prisma.organization.findFirstOrThrow({ where: { displayName: 'مؤسسة غيارك التجارية' } }));

  const merchantBranch = await prisma.organizationBranch.create({
    data: {
      organizationId: merchantOrg.id,
      branchName: 'الفرع الرئيسي',
      phone: merchantOwnerPhone,
      cityId: city.id,
      districtId: district.id,
      areaId: area.id,
      addressLine1: 'شارع التحرير',
      isHeadOffice: true,
      supportsPickup: true,
      supportsDelivery: true,
    },
  }).catch(async () => prisma.organizationBranch.findFirstOrThrow({ where: { organizationId: merchantOrg.id, branchName: 'الفرع الرئيسي' } }));

  for (let day = 0; day < 7; day += 1) {
    await prisma.branchBusinessHour.upsert({
      where: { branchId_dayOfWeek: { branchId: merchantBranch.id, dayOfWeek: day } },
      update: {},
      create: {
        branchId: merchantBranch.id,
        dayOfWeek: day,
        isClosed: day === 5,
        openTime: day === 5 ? null : '09:00',
        closeTime: day === 5 ? null : '21:00',
      },
    });
  }

  await prisma.bankAccount.create({
    data: {
      organizationId: merchantOrg.id,
      bankName: 'بنك اليمن والكويت',
      accountName: 'مؤسسة غيارك التجارية',
      accountNumber: '123456789',
      iban: 'YE00123456789',
      isPrimary: true,
    },
  }).catch(() => null);

  const workshopOrg = await prisma.organization.create({
    data: {
      organizationType: 'WORKSHOP' as any,
      displayName: 'ورشة النخبة',
      legalName: 'Elite Workshop',
      primaryPhone: workshopOwnerPhone,
      status: 'APPROVED' as any,
      submittedAt: new Date(),
      approvedAt: new Date(),
      isVerified: true,
      members: {
        create: { userId: workshopOwner.id, memberRole: 'owner' },
      },
      workshopProfile: {
        create: {
          serviceModeCode: 'in_shop',
          acceptsDiagnosis: true,
          acceptsInstallation: true,
          capacityPerDay: 8,
          supportsEmergencyService: false,
          defaultDiagnosisFee: 2000,
        },
      },
    },
  }).catch(async () => prisma.organization.findFirstOrThrow({ where: { displayName: 'ورشة النخبة' } }));

  const workshopBranch = await prisma.organizationBranch.create({
    data: {
      organizationId: workshopOrg.id,
      branchName: 'فرع الورشة الرئيسي',
      phone: workshopOwnerPhone,
      cityId: city.id,
      districtId: district.id,
      areaId: area.id,
      addressLine1: 'شارع الزبيري',
      isHeadOffice: true,
      supportsPickup: false,
      supportsDelivery: false,
      supportsInstallation: true,
      supportsMobileService: false,
    },
  }).catch(async () => prisma.organizationBranch.findFirstOrThrow({ where: { organizationId: workshopOrg.id, branchName: 'فرع الورشة الرئيسي' } }));

  for (let day = 0; day < 7; day += 1) {
    await prisma.branchBusinessHour.upsert({
      where: { branchId_dayOfWeek: { branchId: workshopBranch.id, dayOfWeek: day } },
      update: {},
      create: {
        branchId: workshopBranch.id,
        dayOfWeek: day,
        isClosed: day === 5,
        openTime: day === 5 ? null : '08:00',
        closeTime: day === 5 ? null : '18:00',
      },
    });
  }

  await prisma.bankAccount.create({
    data: {
      organizationId: workshopOrg.id,
      bankName: 'بنك التضامن',
      accountName: 'ورشة النخبة',
      accountNumber: '987654321',
      iban: 'YE00987654321',
      isPrimary: true,
    },
  }).catch(() => null);

  const verificationRequest = await prisma.verificationRequest.create({
    data: {
      organizationId: workshopOrg.id,
      submittedByUserId: workshopOwner.id,
      status: 'APPROVED' as any,
      notes: 'تم اعتماد الورشة لاختبار مرحلة الورش والصيانة.',
      submittedAt: new Date(),
      reviewedAt: new Date(),
      reviewedByUserId: admin.id,
      reviewNotes: 'تم اعتماد مستندات الورشة لعينة التطوير.',
      documents: {
        create: [
          {
            documentType: 'SHOP_GUARANTEE' as any,
            fileName: 'shop_guarantee.pdf',
            fileUrl: 'https://example.com/docs/shop_guarantee.pdf',
            mimeType: 'application/pdf',
          },
          {
            documentType: 'NATIONAL_ID' as any,
            fileName: 'owner_id.pdf',
            fileUrl: 'https://example.com/docs/owner_id.pdf',
            mimeType: 'application/pdf',
          },
        ],
      },
    },
  }).catch(async () => prisma.verificationRequest.findFirstOrThrow({ where: { organizationId: workshopOrg.id } }));

  await prisma.approvalAction.create({
    data: {
      organizationId: workshopOrg.id,
      verificationRequestId: verificationRequest.id,
      actedByUserId: admin.id,
      actionCode: 'approved',
      notes: 'تم اعتماد الورشة لعينة مرحلة الورش والصيانة.',
    },
  }).catch(() => null);
}



async function seedDemoAccessAccounts() {
  const district = await prisma.district.findFirstOrThrow({ where: { nameAr: 'التحرير' }, include: { city: true } });
  const city = district.city;
  const area = await prisma.area.findFirst({ where: { districtId: district.id } });

  const customer = await upsertDemoUser('710000001', 'عميل تجريبي', 'customer', 'customer@ghiyarak.dev');
  await prisma.customerProfile.upsert({
    where: { userId: customer.id },
    update: { displayName: 'عميل تجريبي', cityId: city.id, districtId: district.id, areaId: area?.id ?? undefined },
    create: { userId: customer.id, displayName: 'عميل تجريبي', cityId: city.id, districtId: district.id, areaId: area?.id ?? undefined },
  });

  await upsertDemoUser('700000002', 'مدير عمليات', 'admin_operations', 'operations@ghiyarak.dev');
  await upsertDemoUser('700000003', 'مدير مالي', 'finance_manager', 'finance@ghiyarak.dev');
  await upsertDemoUser('700000004', 'موظف دعم', 'support_agent', 'support@ghiyarak.dev');

  const merchantOrg = await prisma.organization.findFirstOrThrow({ where: { displayName: 'مؤسسة غيارك التجارية' } });
  const merchantEmployee = await upsertDemoUser('711111112', 'موظف تاجر', 'merchant_employee', 'merchant.employee@ghiyarak.dev');
  await ensureOrganizationMembership(merchantOrg.id, merchantEmployee.id, 'employee');

  const workshopOrg = await prisma.organization.findFirstOrThrow({ where: { displayName: 'ورشة النخبة' } });
  const workshopEmployee = await upsertDemoUser('733333334', 'موظف ورشة', 'workshop_employee', 'workshop.employee@ghiyarak.dev');
  await ensureOrganizationMembership(workshopOrg.id, workshopEmployee.id, 'employee');

  const warehouseOwner = await upsertDemoUser('770000001', 'مالك مستودع', 'warehouse_owner', 'warehouse.owner@ghiyarak.dev');
  const warehouseEmployee = await upsertDemoUser('770000002', 'موظف مستودع', 'warehouse_employee', 'warehouse.employee@ghiyarak.dev');
  const warehouseOrg = await prisma.organization.create({
    data: {
      organizationType: 'WAREHOUSE' as any,
      displayName: 'مستودع غيارك المركزي',
      legalName: 'Ghiyarak Central Warehouse',
      primaryPhone: '770000001',
      status: 'APPROVED' as any,
      submittedAt: new Date(),
      approvedAt: new Date(),
      isVerified: true,
      members: { create: { userId: warehouseOwner.id, memberRole: 'owner', status: 'ACTIVE' as any } },
      branches: {
        create: {
          branchName: 'مستودع صنعاء',
          phone: '770000001',
          cityId: city.id,
          districtId: district.id,
          areaId: area?.id ?? undefined,
          addressLine1: 'منطقة التخزين المركزية',
          isHeadOffice: true,
          supportsPickup: true,
          supportsDelivery: true,
        },
      },
    },
  }).catch(async () => prisma.organization.findFirstOrThrow({ where: { displayName: 'مستودع غيارك المركزي' } }));
  await ensureOrganizationMembership(warehouseOrg.id, warehouseEmployee.id, 'employee');

  const driverUser = await upsertDemoUser('780000001', 'سائق توصيل', 'driver', 'driver@ghiyarak.dev');
  await prisma.driver.upsert({
    where: { userId: driverUser.id },
    update: { fullName: 'سائق توصيل', phone: '780000001', status: 'ACTIVE' as any, isAvailable: true, currentCityId: city.id },
    create: {
      userId: driverUser.id,
      fullName: 'سائق توصيل',
      phone: '780000001',
      driverType: 'INTERNAL' as any,
      status: 'ACTIVE' as any,
      isAvailable: true,
      vehicleType: 'دراجة نارية',
      vehiclePlate: 'GH-1001',
      currentCityId: city.id,
    },
  });
}

async function seedMarketplaceCore() {
  const merchantOrg = await prisma.organization.findFirstOrThrow({
    where: { displayName: 'مؤسسة غيارك التجارية' },
  });
  const merchantOwner = await prisma.user.findFirstOrThrow({
    where: { phoneNormalized: '711111111' },
  });
  const merchantBranch = await prisma.organizationBranch.findFirstOrThrow({
    where: { organizationId: merchantOrg.id, branchName: 'الفرع الرئيسي' },
  });

  const filtersCategory = await prisma.catalogCategory.upsert({
    where: { slug: 'filters' },
    update: { nameAr: 'فلاتر', nameEn: 'Filters', isActive: true },
    create: { nameAr: 'فلاتر', nameEn: 'Filters', slug: 'filters', sortOrder: 1 },
  });

  const oilsCategory = await prisma.catalogCategory.upsert({
    where: { slug: 'oils' },
    update: { nameAr: 'زيوت وسوائل', nameEn: 'Oils & Fluids', isActive: true },
    create: { nameAr: 'زيوت وسوائل', nameEn: 'Oils & Fluids', slug: 'oils', sortOrder: 2 },
  });

  const brakesCategory = await prisma.catalogCategory.upsert({
    where: { slug: 'brakes' },
    update: { nameAr: 'فرامل', nameEn: 'Brakes', isActive: true },
    create: { nameAr: 'فرامل', nameEn: 'Brakes', slug: 'brakes', sortOrder: 3 },
  });

  const toyota = await prisma.partBrand.upsert({
    where: { slug: 'toyota-genuine' },
    update: { nameAr: 'تويوتا أصلي', nameEn: 'Toyota Genuine', isActive: true },
    create: { nameAr: 'تويوتا أصلي', nameEn: 'Toyota Genuine', slug: 'toyota-genuine', countryCode: 'JP' },
  });

  const acdelco = await prisma.partBrand.upsert({
    where: { slug: 'acdelco' },
    update: { nameAr: 'ACDelco', nameEn: 'ACDelco', isActive: true },
    create: { nameAr: 'ACDelco', nameEn: 'ACDelco', slug: 'acdelco', countryCode: 'US' },
  });

  const oilFilter = await prisma.catalogProduct.upsert({
    where: { slug: 'toyota-oil-filter' },
    update: { nameAr: 'فلتر زيت تويوتا', isActive: true },
    create: {
      categoryId: filtersCategory.id,
      partBrandId: toyota.id,
      nameAr: 'فلتر زيت تويوتا',
      nameEn: 'Toyota Oil Filter',
      slug: 'toyota-oil-filter',
      sku: 'GH-FLT-TOY-001',
      oemNumber: '90915-YZZE1',
      description: 'فلتر زيت مناسب لعدة سيارات تويوتا.',
      isUniversal: false,
    },
  });

  const engineOil = await prisma.catalogProduct.upsert({
    where: { slug: 'engine-oil-5w30' },
    update: { nameAr: 'زيت محرك 5W-30', isActive: true },
    create: {
      categoryId: oilsCategory.id,
      partBrandId: acdelco.id,
      nameAr: 'زيت محرك 5W-30',
      nameEn: 'Engine Oil 5W-30',
      slug: 'engine-oil-5w30',
      sku: 'GH-OIL-5W30',
      description: 'زيت محرك عالي الجودة مناسب للعديد من السيارات.',
      isUniversal: true,
    },
  });

  const brakePads = await prisma.catalogProduct.upsert({
    where: { slug: 'front-brake-pads-camry' },
    update: { nameAr: 'فحمات فرامل أمامية كامري', isActive: true },
    create: {
      categoryId: brakesCategory.id,
      partBrandId: toyota.id,
      nameAr: 'فحمات فرامل أمامية كامري',
      nameEn: 'Camry Front Brake Pads',
      slug: 'front-brake-pads-camry',
      sku: 'GH-BRK-CAM-001',
      description: 'فحمات فرامل أمامية مناسبة لتويوتا كامري موديلات حديثة.',
      isUniversal: false,
    },
  });

  const camry = await prisma.vehicleModel.findFirst({ where: { nameAr: 'Camry' } });
  const toyotaMake = await prisma.vehicleMake.findFirst({ where: { slug: 'toyota' } });
  if (toyotaMake && camry) {
    await prisma.productCompatibility.create({
      data: { productId: oilFilter.id, makeId: toyotaMake.id, modelId: camry.id, yearFrom: 2018, yearTo: 2025 },
    }).catch(() => null);
    await prisma.productCompatibility.create({
      data: { productId: brakePads.id, makeId: toyotaMake.id, modelId: camry.id, yearFrom: 2018, yearTo: 2025 },
    }).catch(() => null);
  }

  for (const product of [oilFilter, engineOil, brakePads]) {
    await prisma.productMedia.create({
      data: {
        productId: product.id,
        mediaUrl: 'https://placehold.co/800x600?text=Ghiyarak',
        mediaType: 'image',
        altText: product.nameAr,
        sortOrder: 1,
      },
    }).catch(() => null);
  }

  const sampleListings = [
    { product: oilFilter, title: 'فلتر زيت تويوتا أصلي', unitPrice: 4500, salePrice: 4200, quantity: 25 },
    { product: engineOil, title: 'زيت محرك 5W-30 عبوة 4 لتر', unitPrice: 18000, salePrice: 16900, quantity: 16 },
    { product: brakePads, title: 'فحمات فرامل أمامية كامري', unitPrice: 32000, salePrice: null, quantity: 12 },
  ];

  for (const item of sampleListings) {
    const exists = await prisma.listing.findFirst({
      where: { organizationId: merchantOrg.id, productId: item.product.id, title: item.title },
    });
    if (exists) continue;
    const listing = await prisma.listing.create({
      data: {
        productId: item.product.id,
        organizationId: merchantOrg.id,
        branchId: merchantBranch.id,
        cityId: merchantBranch.cityId,
        createdByUserId: merchantOwner.id,
        title: item.title,
        description: item.product.description,
        condition: 'NEW' as any,
        qualityType: item.title.includes('أصلي') ? 'ORIGINAL' : 'AFTERMARKET',
        status: 'ACTIVE' as any,
        approvalStatus: 'APPROVED' as any,
        unitPrice: item.unitPrice,
        salePrice: item.salePrice,
        currency: 'YER',
        availableQuantity: item.quantity,
        reservedQuantity: 0,
        minOrderQuantity: 1,
        supportsPickup: true,
        supportsDelivery: true,
        publishedAt: new Date(),
      },
    });
    await prisma.listingInventory.create({ data: { listingId: listing.id, availableQuantity: item.quantity, reservedQuantity: 0 } }).catch(() => null);
    await prisma.listingPrice.create({ data: { listingId: listing.id, unitPrice: item.unitPrice, salePrice: item.salePrice, currency: 'YER', isActive: true } }).catch(() => null);
    await prisma.stockMovement.create({ data: { listingId: listing.id, movementType: 'INITIAL_STOCK', quantity: item.quantity, quantityBefore: 0, quantityAfter: item.quantity, reason: 'Seed stock' } }).catch(() => null);
  }
}


async function seedWorkshopOperations() {
  const workshopOrg = await prisma.organization.findFirstOrThrow({ where: { displayName: 'ورشة النخبة' } });
  const workshopOwner = await prisma.user.findFirstOrThrow({ where: { phoneNormalized: '733333333' } });
  const workshopBranch = await prisma.organizationBranch.findFirstOrThrow({ where: { organizationId: workshopOrg.id, branchName: 'فرع الورشة الرئيسي' } });

  await (prisma as any).workshopBranch.upsert({
    where: { organizationBranchId: workshopBranch.id },
    update: { isBookingEnabled: true, defaultSlotCapacity: 2, slotDurationMinutes: 60 },
    create: { organizationId: workshopOrg.id, organizationBranchId: workshopBranch.id, isBookingEnabled: true, defaultSlotCapacity: 2, slotDurationMinutes: 60 },
  }).catch(() => null);

  const categories = [
    { code: 'diagnostics', nameAr: 'الفحص والتشخيص', nameEn: 'Diagnostics', sortOrder: 1 },
    { code: 'maintenance', nameAr: 'الصيانة الدورية', nameEn: 'Periodic Maintenance', sortOrder: 2 },
    { code: 'body', nameAr: 'الهيكل والدهان', nameEn: 'Body & Paint', sortOrder: 3 },
    { code: 'cleaning', nameAr: 'الغسيل والتلميع', nameEn: 'Cleaning & Detailing', sortOrder: 4 },
    { code: 'mechanical', nameAr: 'الميكانيكا والكهرباء', nameEn: 'Mechanical & Electrical', sortOrder: 5 },
  ];

  const categoryByCode: Record<string, any> = {};
  for (const category of categories) {
    const saved = await (prisma as any).serviceCategory.upsert({
      where: { organizationId_code: { organizationId: null, code: category.code } },
      update: { nameAr: category.nameAr, nameEn: category.nameEn, status: 'ACTIVE' as any, sortOrder: category.sortOrder },
      create: { code: category.code, nameAr: category.nameAr, nameEn: category.nameEn, status: 'ACTIVE' as any, sortOrder: category.sortOrder },
    }).catch(async () => {
      const existing = await (prisma as any).serviceCategory.findFirst({ where: { organizationId: null, code: category.code } });
      if (existing) return existing;
      return (prisma as any).serviceCategory.create({ data: { code: category.code, nameAr: category.nameAr, nameEn: category.nameEn, status: 'ACTIVE' as any, sortOrder: category.sortOrder } });
    });
    categoryByCode[category.code] = saved;
  }

  const serviceSamples = [
    { code: 'computer-diagnostics', nameAr: 'فحص كمبيوتر', nameEn: 'Computer Diagnostics', categoryCode: 'diagnostics', description: 'فحص إلكتروني شامل وقراءة أخطاء السيارة.', estimatedDurationMinutes: 45, basePrice: 2500, requiresDiagnosis: true },
    { code: 'brake-replacement', nameAr: 'تغيير الفحمات', nameEn: 'Brake Replacement', categoryCode: 'maintenance', description: 'فحص وتغيير الفحمات حسب حالة المركبة.', estimatedDurationMinutes: 60, basePrice: 4500, requiresDiagnosis: false },
    { code: 'oil-change', nameAr: 'تغيير الزيوت', nameEn: 'Oil Change', categoryCode: 'maintenance', description: 'تغيير زيت وفلتر مع فحص سريع.', estimatedDurationMinutes: 35, basePrice: 3500, requiresDiagnosis: false },
    { code: 'air-conditioning', nameAr: 'التكييف', nameEn: 'Air Conditioning', categoryCode: 'mechanical', description: 'فحص وصيانة نظام التكييف.', estimatedDurationMinutes: 75, basePrice: 5000, requiresDiagnosis: true },
    { code: 'tires', nameAr: 'الإطارات', nameEn: 'Tires', categoryCode: 'maintenance', description: 'فحص وتركيب الإطارات والوزن.', estimatedDurationMinutes: 45, basePrice: 3000, requiresDiagnosis: false },
    { code: 'polishing', nameAr: 'التلميع', nameEn: 'Polishing', categoryCode: 'cleaning', description: 'تلميع داخلي وخارجي حسب الباقة.', estimatedDurationMinutes: 120, basePrice: 8000, requiresDiagnosis: false },
    { code: 'car-wash', nameAr: 'الغسيل', nameEn: 'Car Wash', categoryCode: 'cleaning', description: 'غسيل خارجي وداخلي.', estimatedDurationMinutes: 30, basePrice: 2000, requiresDiagnosis: false },
    { code: 'body-repair', nameAr: 'السمكرة', nameEn: 'Body Repair', categoryCode: 'body', description: 'إصلاح الصدمات والهيكل.', estimatedDurationMinutes: 180, basePrice: 15000, requiresDiagnosis: true },
    { code: 'painting', nameAr: 'الدهان', nameEn: 'Painting', categoryCode: 'body', description: 'دهان جزئي أو كامل بعد المعاينة.', estimatedDurationMinutes: 240, basePrice: 20000, requiresDiagnosis: true },
    { code: 'electrical-services', nameAr: 'الكهرباء', nameEn: 'Electrical Services', categoryCode: 'mechanical', description: 'فحص وإصلاح الأعطال الكهربائية.', estimatedDurationMinutes: 90, basePrice: 6000, requiresDiagnosis: true },
    { code: 'mechanical-services', nameAr: 'الميكانيكا', nameEn: 'Mechanical Services', categoryCode: 'mechanical', description: 'صيانة وإصلاح ميكانيكي عام.', estimatedDurationMinutes: 120, basePrice: 7000, requiresDiagnosis: true },
    { code: 'general-inspection', nameAr: 'الفحص العام', nameEn: 'General Inspection', categoryCode: 'diagnostics', description: 'فحص عام لحالة المركبة.', estimatedDurationMinutes: 60, basePrice: 3000, requiresDiagnosis: true },
  ];

  const workshopServiceIds: number[] = [];
  for (const item of serviceSamples) {
    const category = categoryByCode[item.categoryCode];
    const catalog = await (prisma as any).serviceCatalog.upsert({
      where: { organizationId_code: { organizationId: null, code: item.code } },
      update: {
        categoryId: category.id,
        nameAr: item.nameAr,
        nameEn: item.nameEn,
        description: item.description,
        estimatedDurationMinutes: item.estimatedDurationMinutes,
        basePrice: item.basePrice,
        currency: 'YER',
        status: 'ACTIVE' as any,
      },
      create: {
        categoryId: category.id,
        code: item.code,
        nameAr: item.nameAr,
        nameEn: item.nameEn,
        description: item.description,
        estimatedDurationMinutes: item.estimatedDurationMinutes,
        basePrice: item.basePrice,
        currency: 'YER',
        status: 'ACTIVE' as any,
      },
    }).catch(async () => {
      const existing = await (prisma as any).serviceCatalog.findFirst({ where: { organizationId: null, code: item.code } });
      if (existing) return existing;
      return (prisma as any).serviceCatalog.create({ data: { categoryId: category.id, code: item.code, nameAr: item.nameAr, nameEn: item.nameEn, description: item.description, estimatedDurationMinutes: item.estimatedDurationMinutes, basePrice: item.basePrice, currency: 'YER', status: 'ACTIVE' as any } });
    });

    const existing = await prisma.workshopService.findFirst({ where: { organizationId: workshopOrg.id, nameAr: item.nameAr } });
    const workshopService = existing
      ? await (prisma as any).workshopService.update({ where: { id: existing.id }, data: { serviceId: catalog.id, categoryCode: item.categoryCode, status: 'ACTIVE' as any } })
      : await prisma.workshopService.create({
          data: {
            organizationId: workshopOrg.id,
            branchId: workshopBranch.id,
            cityId: workshopBranch.cityId,
            serviceId: catalog.id,
            createdByUserId: workshopOwner.id,
            nameAr: item.nameAr,
            nameEn: item.nameEn,
            categoryCode: item.categoryCode,
            description: item.description,
            estimatedDurationMinutes: item.estimatedDurationMinutes,
            basePrice: item.basePrice,
            currency: 'YER',
            requiresDiagnosis: item.requiresDiagnosis,
            supportsMobileService: false,
            status: 'ACTIVE' as any,
          },
        });
    workshopServiceIds.push(workshopService.id);
  }

  const existingTechnician = await prisma.workshopTechnician.findFirst({ where: { organizationId: workshopOrg.id, fullName: 'أحمد الفني' } });
  const technician = existingTechnician ?? await prisma.workshopTechnician.create({
    data: {
      organizationId: workshopOrg.id,
      branchId: workshopBranch.id,
      fullName: 'أحمد الفني',
      phone: '733333333',
      specializations: ['diagnostics', 'maintenance'],
      status: 'ACTIVE' as any,
      maxJobsPerDay: 6,
    },
  });

  const now = new Date();
  const firstServices = workshopServiceIds.slice(0, 4);
  for (let dayOffset = 1; dayOffset <= 5; dayOffset += 1) {
    const day = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + dayOffset));
    const date = day.toISOString().slice(0, 10);
    for (const serviceId of firstServices) {
      for (const hour of [9, 11, 15]) {
        const startAt = new Date(`${date}T${String(hour).padStart(2, '0')}:00:00.000Z`);
        const endAt = new Date(`${date}T${String(hour + 1).padStart(2, '0')}:00:00.000Z`);
        const exists = await (prisma as any).bookingSlot.findFirst({ where: { workshopServiceId: serviceId, branchId: workshopBranch.id, startAt } }).catch(() => null);
        if (!exists) {
          await (prisma as any).bookingSlot.create({
            data: {
              organizationId: workshopOrg.id,
              branchId: workshopBranch.id,
              workshopServiceId: serviceId,
              technicianId: technician.id,
              slotDate: day,
              startAt,
              endAt,
              capacity: 2,
              bookedCount: 0,
              status: 'AVAILABLE' as any,
            },
          }).catch(() => null);
        }
      }
    }
  }
}


async function seedPhase7Operations() {
  const methods = [
    {
      code: 'standard_city_delivery',
      kind: 'DRIVER_DELIVERY' as any,
      nameAr: 'توصيل داخل المدينة',
      nameEn: 'City Delivery',
      description: 'توصيل الطلبات داخل المدينة خلال 24 إلى 48 ساعة.',
      baseFee: 1500,
      estimatedDurationText: '24-48 ساعة',
      supportsCashOnDelivery: true,
    },
    {
      code: 'store_pickup',
      kind: 'STORE_PICKUP' as any,
      nameAr: 'استلام من الفرع',
      nameEn: 'Store Pickup',
      description: 'استلام الطلب من فرع التاجر أو الورشة.',
      baseFee: 0,
      estimatedDurationText: 'حسب جاهزية الفرع',
      supportsCashOnDelivery: false,
    },
    {
      code: 'local_shipping_company',
      kind: 'LOCAL_SHIPPING_COMPANY' as any,
      nameAr: 'شركة شحن محلية',
      nameEn: 'Local Shipping Company',
      description: 'شحن عبر شركة محلية مع رقم تتبع خارجي.',
      baseFee: 2500,
      estimatedDurationText: '1-3 أيام',
      supportsCashOnDelivery: false,
    },
    {
      code: 'merchant_pickup_delivery',
      kind: 'DRIVER_DELIVERY' as any,
      nameAr: 'استلام من التاجر عبر مندوب',
      nameEn: 'Merchant Pickup Courier',
      description: 'مندوب يستلم الطلب من فرع التاجر ثم يوصله للعميل.',
      baseFee: 2500,
      estimatedDurationText: 'نفس اليوم حسب التوفر',
      supportsCashOnDelivery: true,
    },
  ];

  for (const method of methods) {
    await prisma.deliveryMethod.upsert({
      where: { code: method.code },
      update: {
        nameAr: method.nameAr,
        nameEn: method.nameEn,
        kind: (method as any).kind ?? 'DRIVER_DELIVERY',
        description: method.description,
        baseFee: method.baseFee,
        estimatedDurationText: method.estimatedDurationText,
        supportsCashOnDelivery: method.supportsCashOnDelivery,
        status: 'ACTIVE' as any,
      },
      create: {
        ...method,
        kind: (method as any).kind ?? 'DRIVER_DELIVERY',
        currency: 'YER',
        status: 'ACTIVE' as any,
      },
    });
  }

  const sanaa = await prisma.city.findFirst({ where: { OR: [{ nameAr: 'صنعاء' }, { nameEn: 'Sana’a' }, { nameEn: 'Sanaa' }] } }).catch(() => null);
  await prisma.localShippingCompany.upsert({
    where: { code: 'YEMEN_LOCAL_COURIER' },
    update: { nameAr: 'شركة شحن محلية', nameEn: 'Local Courier', cityId: sanaa?.id ?? null, status: 'ACTIVE' as any },
    create: { code: 'YEMEN_LOCAL_COURIER', nameAr: 'شركة شحن محلية', nameEn: 'Local Courier', cityId: sanaa?.id ?? null, supportsCod: false, status: 'ACTIVE' as any },
  }).catch(() => null);

  const cityDelivery = await prisma.deliveryMethod.findUnique({ where: { code: 'standard_city_delivery' } }).catch(() => null);
  if (sanaa && cityDelivery) {
    await prisma.deliveryFee.create({
      data: { scope: 'CITY' as any, cityId: sanaa.id, deliveryMethodId: cityDelivery.id, label: 'رسوم توصيل صنعاء', baseFee: 1500, currency: 'YER', estimatedMinDays: 1, estimatedMaxDays: 2 },
    }).catch(() => null);
  }
}


async function seedPhase9Retention() {
  const admin = await prisma.user.findFirstOrThrow({ where: { phoneNormalized: '781699203' } });
  const users = await prisma.user.findMany({ take: 20 });
  for (const user of users) {
    await prisma.loyaltyAccount.upsert({
      where: { userId: user.id },
      update: {},
      create: { userId: user.id, pointsBalance: 0, lifetimeEarned: 0, lifetimeRedeemed: 0, tier: 'BRONZE' as any },
    });
    const existingWallet = await prisma.walletAccount.findFirst({ where: { ownerType: 'USER' as any, userId: user.id, currency: 'YER' } });
    if (!existingWallet) {
      await prisma.walletAccount.create({ data: { ownerType: 'USER' as any, userId: user.id, currency: 'YER', balance: 0, lockedBalance: 0, status: 'ACTIVE' as any } });
    }
  }

  await prisma.coupon.upsert({
    where: { code: 'WELCOME10' },
    update: { status: 'ACTIVE' as any },
    create: {
      code: 'WELCOME10',
      titleAr: 'خصم ترحيبي 10%',
      titleEn: 'Welcome 10% Off',
      description: 'كوبون ترحيبي لاختبار مرحلة الولاء والاحتفاظ.',
      discountType: 'PERCENTAGE' as any,
      discountValue: 10,
      maxDiscountAmount: 3000,
      minOrderAmount: 5000,
      currency: 'YER',
      scope: 'ALL' as any,
      usageLimit: 1000,
      perUserLimit: 1,
      status: 'ACTIVE' as any,
      createdByUserId: admin.id,
    },
  });
}


async function seedProductImportTemplates() {
  const requiredColumns = [
    'product_name',
    'part_number',
    'category',
    'brand',
    'vehicle_brand',
    'vehicle_model',
    'year_from',
    'year_to',
    'condition_type',
    'quality_type',
    'price_yer',
    'stock_quantity',
    'city',
    'branch',
    'description',
  ];

  const sampleRows = [
    {
      product_name: 'فلتر زيت تويوتا كورولا',
      part_number: '04152-YZZA6',
      category: 'فلاتر',
      brand: 'تويوتا أصلي',
      vehicle_brand: 'تويوتا',
      vehicle_model: 'كورولا',
      year_from: 2014,
      year_to: 2022,
      condition_type: 'NEW',
      quality_type: 'ORIGINAL',
      price_yer: 7500,
      stock_quantity: 10,
      city: 'صنعاء',
      branch: 'Main Branch',
      description: 'فلتر زيت أصلي مناسب للموديلات المحددة',
    },
  ];

  await (prisma as any).productImportTemplate.upsert({
    where: { publicId: 'product-import-default-template' },
    update: {
      name: 'Default Product Import Template',
      organizationType: null,
      requiredColumns,
      optionalColumns: [],
      sampleRows,
      isDefault: true,
      isActive: true,
    },
    create: {
      publicId: 'product-import-default-template',
      name: 'Default Product Import Template',
      organizationType: null,
      requiredColumns,
      optionalColumns: [],
      sampleRows,
      isDefault: true,
      isActive: true,
    },
  });
}

async function seedPaymentFinanceFoundation() {
  const methods = [
    { code: 'CASH_ON_PICKUP', nameAr: 'الدفع عند الاستلام من الفرع', nameEn: 'Cash on Pickup', kind: 'COD', providerCode: 'CASH', instructionsAr: 'يدفع العميل عند استلام الطلب من الفرع.', requiresProof: false, requiresWebhook: false, sortOrder: 1 },
    { code: 'CASH_ON_DELIVERY', nameAr: 'الدفع عند التوصيل', nameEn: 'Cash on Delivery', kind: 'COD', providerCode: 'CASH', instructionsAr: 'يتم تأكيد الدفع بعد التسليم الناجح.', requiresProof: false, requiresWebhook: false, sortOrder: 2 },
    { code: 'BANK_TRANSFER', nameAr: 'تحويل بنكي', nameEn: 'Bank Transfer', kind: 'BANK_TRANSFER', providerCode: 'BANK_TRANSFER', instructionsAr: 'حوّل المبلغ إلى الحساب البنكي ثم ارفع إثبات التحويل للمراجعة المالية.', requiresProof: true, requiresWebhook: false, sortOrder: 3 },
    { code: 'LOCAL_WALLET', nameAr: 'محفظة محلية', nameEn: 'Local Wallet', kind: 'LOCAL_WALLET', providerCode: 'LOCAL_WALLET', instructionsAr: 'استخدم محفظة محلية وارفع مرجع العملية للمراجعة.', requiresProof: true, requiresWebhook: false, sortOrder: 4 },
    { code: 'PAYMENT_GATEWAY', nameAr: 'بوابة دفع مستقبلية', nameEn: 'Payment Gateway', kind: 'PAYMENT_GATEWAY', providerCode: 'PAYMENT_GATEWAY', instructionsAr: 'جاهزة للربط مع بوابات دفع مستقبلية عبر Webhook موثق.', requiresProof: false, requiresWebhook: true, sortOrder: 5 },
  ];

  for (const method of methods) {
    await (prisma as any).paymentMethodConfig.upsert({
      where: { code: method.code },
      update: {
        nameAr: method.nameAr,
        nameEn: method.nameEn,
        kind: method.kind,
        providerCode: method.providerCode,
        instructionsAr: method.instructionsAr,
        requiresProof: method.requiresProof,
        requiresWebhook: method.requiresWebhook,
        status: 'ACTIVE',
        sortOrder: method.sortOrder,
      },
      create: {
        code: method.code,
        nameAr: method.nameAr,
        nameEn: method.nameEn,
        kind: method.kind,
        providerCode: method.providerCode,
        instructionsAr: method.instructionsAr,
        requiresProof: method.requiresProof,
        requiresWebhook: method.requiresWebhook,
        status: 'ACTIVE',
        sortOrder: method.sortOrder,
      },
    });
  }
}

async function seedAccountingFoundation() {
  const accounts = [
    { code: '1000', nameAr: 'النقدية', nameEn: 'Cash', accountType: 'ASSET', normalBalance: 'DEBIT' },
    { code: '1010', nameAr: 'الحسابات البنكية', nameEn: 'Bank Accounts', accountType: 'ASSET', normalBalance: 'DEBIT' },
    { code: '1100', nameAr: 'الذمم المدينة', nameEn: 'Accounts Receivable', accountType: 'ASSET', normalBalance: 'DEBIT' },
    { code: '1200', nameAr: 'أصول المحافظ', nameEn: 'Wallet Assets', accountType: 'ASSET', normalBalance: 'DEBIT' },
    { code: '2000', nameAr: 'مستحقات التجار والورش', nameEn: 'Merchant and Workshop Payables', accountType: 'LIABILITY', normalBalance: 'CREDIT' },
    { code: '2100', nameAr: 'التزامات محافظ العملاء', nameEn: 'Customer Wallet Liabilities', accountType: 'LIABILITY', normalBalance: 'CREDIT' },
    { code: '2200', nameAr: 'التزامات الاسترداد', nameEn: 'Refunds Payable', accountType: 'LIABILITY', normalBalance: 'CREDIT' },
    { code: '4000', nameAr: 'إيرادات السوق', nameEn: 'Marketplace Revenue', accountType: 'REVENUE', normalBalance: 'CREDIT' },
    { code: '4100', nameAr: 'إيرادات الخدمات', nameEn: 'Service Revenue', accountType: 'REVENUE', normalBalance: 'CREDIT' },
    { code: '4200', nameAr: 'إيرادات التوصيل', nameEn: 'Delivery Revenue', accountType: 'REVENUE', normalBalance: 'CREDIT' },
    { code: '5000', nameAr: 'مصروفات الاسترداد', nameEn: 'Refund Expenses', accountType: 'EXPENSE', normalBalance: 'DEBIT' },
    { code: '5100', nameAr: 'مصروفات تشغيلية', nameEn: 'Operational Expenses', accountType: 'EXPENSE', normalBalance: 'DEBIT' },
  ];

  for (const account of accounts) {
    await (prisma as any).ledgerAccount.upsert({
      where: { code: account.code },
      update: {
        nameAr: account.nameAr,
        nameEn: account.nameEn,
        accountType: account.accountType,
        normalBalance: account.normalBalance,
        isSystem: true,
        isActive: true,
      },
      create: { ...account, isSystem: true, isActive: true },
    });
  }
}


async function seedReleaseReadiness() {
  const items = [
    ['auth_otp_security', 'security', 'أمان OTP والجلسات', 'OTP and session security', 'OTP hashing, refresh rotation, rate limits and audit logs are required.'],
    ['rbac_endpoint_coverage', 'security', 'تغطية صلاحيات API', 'RBAC endpoint coverage', 'Every sensitive endpoint must use authentication and permissions.'],
    ['database_migrations_clean', 'database', 'نظافة ترحيلات قاعدة البيانات', 'Clean database migrations', 'Prisma migrations must apply successfully on a local MySQL database.'],
    ['order_checkout_flow', 'orders', 'اختبار الطلب والسلة', 'Cart and checkout flow', 'Cart, checkout, invoices and stock movements must pass QA.'],
    ['payment_accounting_flow', 'finance', 'اختبار الدفع والمحاسبة', 'Payment and accounting flow', 'Confirmed payments must create balanced journal entries.'],
    ['delivery_cod_flow', 'delivery', 'اختبار التوصيل والدفع عند التسليم', 'Delivery and COD flow', 'Delivered COD shipments must trigger financial confirmation when configured.'],
    ['flutter_analyze_clean', 'frontend', 'فحص Flutter analyze', 'Flutter analyze clean', 'Flutter analyze must complete without blocking errors.'],
    ['backend_typecheck_clean', 'backend', 'فحص TypeScript', 'TypeScript typecheck clean', 'Backend typecheck must complete without blocking errors.'],
    ['smoke_health_check', 'operations', 'فحص الصحة', 'Health smoke check', 'The /health endpoint must respond successfully.'],
    ['production_env_review', 'operations', 'مراجعة بيئة الإنتاج', 'Production environment review', 'Secrets and production env variables must be configured before release.'],
  ] as const;
  for (const [itemKey, moduleCode, titleAr, titleEn, description] of items) {
    await (prisma as any).releaseChecklistItem.upsert({
      where: { itemKey },
      update: { moduleCode, titleAr, titleEn, description, isRequired: true },
      create: { itemKey, moduleCode, titleAr, titleEn, description, isRequired: true },
    }).catch(() => null);
  }
}


async function seedFullPlatformTranslations() {
  const translations: Array<{ key: string; namespace: string; ar: string; en: string; description?: string }> = [
    { key: 'app.name', namespace: 'app', ar: 'غيارك', en: 'Ghiyarak' },
    { key: 'common.loading', namespace: 'common', ar: 'جاري التحميل...', en: 'Loading...' },
    { key: 'common.saving', namespace: 'common', ar: 'جاري الحفظ...', en: 'Saving...' },
    { key: 'common.empty', namespace: 'common', ar: 'لا توجد بيانات حالياً', en: 'No data available' },
    { key: 'common.error.unexpected', namespace: 'common', ar: 'حدث خطأ غير متوقع', en: 'Something went wrong' },
    { key: 'common.validation', namespace: 'common', ar: 'البيانات المدخلة غير صحيحة', en: 'The submitted data is invalid' },
    { key: 'common.success', namespace: 'common', ar: 'تمت العملية بنجاح', en: 'Operation completed successfully' },
    { key: 'common.not_found', namespace: 'common', ar: 'العنصر المطلوب غير موجود', en: 'The requested resource was not found' },
    { key: 'common.forbidden', namespace: 'common', ar: 'لا تملك صلاحية تنفيذ هذه العملية', en: 'You are not allowed to perform this action' },
    { key: 'common.unauthorized', namespace: 'common', ar: 'يرجى تسجيل الدخول أولاً', en: 'Please sign in first' },
    { key: 'common.save', namespace: 'common', ar: 'حفظ', en: 'Save' },
    { key: 'common.cancel', namespace: 'common', ar: 'إلغاء', en: 'Cancel' },
    { key: 'common.confirm', namespace: 'common', ar: 'تأكيد', en: 'Confirm' },
    { key: 'common.close', namespace: 'common', ar: 'إغلاق', en: 'Close' },
    { key: 'common.retry', namespace: 'common', ar: 'إعادة المحاولة', en: 'Retry' },
    { key: 'common.search', namespace: 'common', ar: 'بحث', en: 'Search' },
    { key: 'common.details', namespace: 'common', ar: 'التفاصيل', en: 'Details' },
    { key: 'common.status', namespace: 'common', ar: 'الحالة', en: 'Status' },
    { key: 'common.actions', namespace: 'common', ar: 'الإجراءات', en: 'Actions' },
    { key: 'common.amount', namespace: 'common', ar: 'المبلغ', en: 'Amount' },
    { key: 'common.total', namespace: 'common', ar: 'الإجمالي', en: 'Total' },
    { key: 'common.date', namespace: 'common', ar: 'التاريخ', en: 'Date' },
    { key: 'common.reason', namespace: 'common', ar: 'السبب', en: 'Reason' },
    { key: 'auth.login', namespace: 'auth', ar: 'تسجيل الدخول', en: 'Login' },
    { key: 'auth.register', namespace: 'auth', ar: 'إنشاء حساب', en: 'Register' },
    { key: 'auth.phone', namespace: 'auth', ar: 'رقم الجوال', en: 'Phone number' },
    { key: 'auth.phone_hint_yemen', namespace: 'auth', ar: 'مثال: 781699203 أو +967781699203', en: 'Example: 781699203 or +967781699203' },
    { key: 'auth.phone.carriers_yemen', namespace: 'auth', ar: 'الشركات المسموحة: سبأفون 71، يمن موبايل 77/78، يو 73، واي 70.', en: 'Allowed carriers: Sabafon 71, Yemen Mobile 77/78, YOU 73, Y 70.' },
    { key: 'auth.validation.yemeni_phone_companies', namespace: 'auth', ar: 'أدخل رقم جوال يمني صحيح تابع لإحدى الشركات: سبأفون 71، يمن موبايل 77 أو 78، يو 73، واي 70.', en: 'Enter a valid Yemeni mobile number for Sabafon 71, Yemen Mobile 77/78, YOU 73, or Y 70.' },
    { key: 'auth.email', namespace: 'auth', ar: 'البريد الإلكتروني', en: 'Email' },
    { key: 'auth.display_name', namespace: 'auth', ar: 'الاسم', en: 'Display name' },
    { key: 'auth.otp', namespace: 'auth', ar: 'رمز التحقق', en: 'Verification code' },
    { key: 'auth.request_otp', namespace: 'auth', ar: 'إرسال رمز التحقق', en: 'Send verification code' },
    { key: 'auth.verify_otp', namespace: 'auth', ar: 'تحقق من الرمز', en: 'Verify code' },
    { key: 'auth.logout', namespace: 'auth', ar: 'تسجيل الخروج', en: 'Logout' },
    { key: 'auth.invalid_token', namespace: 'auth', ar: 'رمز الدخول غير صالح أو منتهي', en: 'The access token is invalid or expired' },
    { key: 'auth.otp_rate_limited', namespace: 'auth', ar: 'تم تجاوز عدد محاولات طلب الرمز. حاول لاحقاً', en: 'Too many verification code requests. Please try again later' },
    { key: 'auth.otp_not_found', namespace: 'auth', ar: 'لم يتم العثور على طلب رمز صالح', en: 'No valid verification code request was found' },
    { key: 'auth.otp_expired', namespace: 'auth', ar: 'انتهت صلاحية رمز التحقق', en: 'The verification code has expired' },
    { key: 'auth.otp_max_attempts', namespace: 'auth', ar: 'تم تجاوز عدد محاولات التحقق', en: 'Maximum verification attempts reached' },
    { key: 'auth.invalid_otp', namespace: 'auth', ar: 'رمز التحقق غير صحيح', en: 'The verification code is invalid' },
    { key: 'auth.refresh_required', namespace: 'auth', ar: 'رمز التحديث مطلوب', en: 'Refresh token is required' },

    { key: 'auth.phone_not_registered', namespace: 'auth', ar: 'رقم الجوال غير مسجل. يرجى إنشاء حساب جديد أولاً.', en: 'This phone number is not registered. Please create an account first.' },
    { key: 'auth.phone_already_registered', namespace: 'auth', ar: 'رقم الجوال مسجل مسبقًا ولا يمكن إنشاء حساب آخر بنفس الرقم.', en: 'This phone number is already registered and cannot be used for another account.' },
    { key: 'auth.send_otp', namespace: 'auth', ar: 'إرسال رمز التحقق', en: 'Send verification code' },
    { key: 'auth.documents.title', namespace: 'auth', ar: 'وثائق التحقق', en: 'Verification documents' },
    { key: 'auth.documents.subtitle', namespace: 'auth', ar: 'اختر وثيقة إثبات واحدة وارفع الملفات المطلوبة بوضوح.', en: 'Choose one verification document and upload the required clear files.' },
    { key: 'auth.document.choose', namespace: 'auth', ar: 'اختر وثيقة إثبات متوفرة لديك', en: 'Choose verification document' },
    { key: 'auth.document.national_id', namespace: 'auth', ar: 'الهوية الشخصية', en: 'National ID' },
    { key: 'auth.document.passport', namespace: 'auth', ar: 'جواز السفر', en: 'Passport' },
    { key: 'auth.document.bank_statement', namespace: 'auth', ar: 'كشف حساب بنكي', en: 'Bank statement' },
    { key: 'auth.document.commercial_registration', namespace: 'auth', ar: 'سجل تجاري', en: 'Commercial registration' },
    { key: 'auth.document.storage_notice', namespace: 'auth', ar: 'يتم حفظ الملفات داخل قاعدة البيانات بصيغة Base64 لتسهيل المعاينة والمراجعة.', en: 'Files are stored in the database as Base64 for preview and review.' },
    { key: 'auth.governorate', namespace: 'auth', ar: 'المحافظة', en: 'Governorate' },
    { key: 'auth.district', namespace: 'auth', ar: 'المديرية', en: 'District' },
    { key: 'auth.area_optional', namespace: 'auth', ar: 'المنطقة / الحي', en: 'Area / neighborhood' },
    { key: 'auth.branch_name', namespace: 'auth', ar: 'اسم الفرع', en: 'Branch name' },
    { key: 'auth.submit_application', namespace: 'auth', ar: 'إرسال طلب الانضمام', en: 'Submit application' },
    { key: 'membership.application_submitted_title', namespace: 'membership', ar: 'تم إرسال طلبك بنجاح', en: 'Application submitted' },
    { key: 'membership.application_submitted_message', namespace: 'membership', ar: 'تم إنشاء حسابك وسيتم مراجعة طلب الانضمام والرد عليك في أقرب وقت ممكن.', en: 'Your account was created and your membership application will be reviewed soon.' },
    { key: 'validation.documents_required', namespace: 'validation', ar: 'يرجى رفع وثائق التحقق المطلوبة', en: 'Please upload required verification documents' },
    { key: 'validation.one_document_type_required', namespace: 'validation', ar: 'اختر نوع وثيقة واحد فقط في الطلب الواحد', en: 'Choose only one document type per application' },
    { key: 'validation.national_id_front_back_required', namespace: 'validation', ar: 'يجب رفع صورة الوجه الأمامي والخلفي للهوية الشخصية', en: 'National ID requires front and back images' },
    { key: 'validation.passport_image_required', namespace: 'validation', ar: 'يجب رفع صورة جواز السفر', en: 'Passport image is required' },
    { key: 'validation.bank_statement_pdf_required', namespace: 'validation', ar: 'كشف الحساب البنكي يجب أن يكون PDF', en: 'Bank statement must be a PDF file' },
    { key: 'validation.commercial_registration_required', namespace: 'validation', ar: 'يجب رفع السجل التجاري', en: 'Commercial registration document is required' },
    { key: 'validation.city_required', namespace: 'validation', ar: 'المدينة مطلوبة ويجب اختيارها من القائمة', en: 'City is required and must be selected from the list' },
    { key: 'validation.district_required', namespace: 'validation', ar: 'المديرية مطلوبة ويجب اختيارها من القائمة', en: 'District is required and must be selected from the list' },
    { key: 'validation.area_required', namespace: 'validation', ar: 'المنطقة المختارة غير صحيحة', en: 'Selected area is invalid' },
    { key: 'vehicles.title', namespace: 'vehicles', ar: 'مركباتي', en: 'My Vehicles' },

    { key: 'nav.home', namespace: 'navigation', ar: 'الرئيسية', en: 'Home' },
    { key: 'nav.marketplace', namespace: 'navigation', ar: 'السوق', en: 'Marketplace' },
    { key: 'nav.cart', namespace: 'navigation', ar: 'السلة', en: 'Cart' },
    { key: 'nav.orders', namespace: 'navigation', ar: 'الطلبات', en: 'Orders' },
    { key: 'nav.bookings', namespace: 'navigation', ar: 'الحجوزات', en: 'Bookings' },
    { key: 'nav.payments', namespace: 'navigation', ar: 'المدفوعات', en: 'Payments' },
    { key: 'nav.wallet', namespace: 'navigation', ar: 'المحفظة', en: 'Wallet' },
    { key: 'nav.loyalty', namespace: 'navigation', ar: 'الولاء', en: 'Loyalty' },
    { key: 'nav.support', namespace: 'navigation', ar: 'الدعم', en: 'Support' },
    { key: 'nav.reviews', namespace: 'navigation', ar: 'التقييمات', en: 'Reviews' },
    { key: 'nav.delivery', namespace: 'navigation', ar: 'التوصيل', en: 'Delivery' },
    { key: 'nav.admin', namespace: 'navigation', ar: 'الإدارة', en: 'Admin' },
    { key: 'nav.settings', namespace: 'navigation', ar: 'الإعدادات', en: 'Settings' },
    { key: 'marketplace.title', namespace: 'marketplace', ar: 'سوق قطع الغيار', en: 'Spare Parts Marketplace' },
    { key: 'marketplace.products', namespace: 'marketplace', ar: 'المنتجات', en: 'Products' },
    { key: 'marketplace.listings', namespace: 'marketplace', ar: 'العروض', en: 'Listings' },
    { key: 'marketplace.categories', namespace: 'marketplace', ar: 'الفئات', en: 'Categories' },
    { key: 'marketplace.add_to_cart', namespace: 'marketplace', ar: 'إضافة للسلة', en: 'Add to cart' },
    { key: 'inventory.title', namespace: 'inventory', ar: 'المخزون', en: 'Inventory' },
    { key: 'inventory.stock', namespace: 'inventory', ar: 'الكمية المتاحة', en: 'Available stock' },
    { key: 'cart.title', namespace: 'cart', ar: 'السلة', en: 'Cart' },
    { key: 'cart.empty', namespace: 'cart', ar: 'السلة فارغة', en: 'Your cart is empty' },
    { key: 'cart.checkout', namespace: 'cart', ar: 'إتمام الطلب', en: 'Checkout' },
    { key: 'checkout.title', namespace: 'orders', ar: 'مراجعة الطلب', en: 'Checkout preview' },
    { key: 'orders.title', namespace: 'orders', ar: 'طلباتي', en: 'My Orders' },
    { key: 'orders.create', namespace: 'orders', ar: 'إنشاء الطلب', en: 'Create order' },
    { key: 'orders.cancel', namespace: 'orders', ar: 'إلغاء الطلب', en: 'Cancel order' },
    { key: 'orders.invalid_transition', namespace: 'orders', ar: 'لا يمكن تغيير حالة الطلب إلى الحالة المطلوبة', en: 'The order cannot move to the requested status' },
    { key: 'payments.title', namespace: 'payments', ar: 'المدفوعات', en: 'Payments' },
    { key: 'payments.method', namespace: 'payments', ar: 'طريقة الدفع', en: 'Payment method' },
    { key: 'payments.upload_proof', namespace: 'payments', ar: 'رفع إثبات الدفع', en: 'Upload payment proof' },
    { key: 'payments.review', namespace: 'payments', ar: 'مراجعة المدفوعات', en: 'Payments review' },
    { key: 'accounting.title', namespace: 'accounting', ar: 'المحاسبة', en: 'Accounting' },
    { key: 'accounting.journals', namespace: 'accounting', ar: 'القيود المحاسبية', en: 'Journal entries' },
    { key: 'workshops.title', namespace: 'workshops', ar: 'الورش', en: 'Workshops' },
    { key: 'workshops.services', namespace: 'workshops', ar: 'الخدمات', en: 'Services' },
    { key: 'bookings.title', namespace: 'bookings', ar: 'الحجوزات', en: 'Bookings' },
    { key: 'bookings.create', namespace: 'bookings', ar: 'حجز موعد', en: 'Book appointment' },
    { key: 'delivery.title', namespace: 'delivery', ar: 'الشحن والتوصيل', en: 'Delivery' },
    { key: 'delivery.shipments', namespace: 'delivery', ar: 'الشحنات', en: 'Shipments' },
    { key: 'delivery.tracking', namespace: 'delivery', ar: 'تتبع الشحنة', en: 'Shipment tracking' },
    { key: 'support.title', namespace: 'support', ar: 'الدعم والشكاوى', en: 'Support & Complaints' },
    { key: 'support.tickets', namespace: 'support', ar: 'تذاكر الدعم', en: 'Support tickets' },
    { key: 'support.complaints', namespace: 'support', ar: 'الشكاوى', en: 'Complaints' },
    { key: 'support.help_center', namespace: 'support', ar: 'مركز المساعدة', en: 'Help Center' },
    { key: 'reviews.title', namespace: 'reviews', ar: 'التقييمات', en: 'Reviews' },
    { key: 'reviews.reputation', namespace: 'reviews', ar: 'السمعة', en: 'Reputation' },
    { key: 'reviews.submit', namespace: 'reviews', ar: 'إرسال تقييم', en: 'Submit review' },
    { key: 'wallet.title', namespace: 'wallet', ar: 'محفظتي', en: 'My Wallet' },
    { key: 'wallet.balance', namespace: 'wallet', ar: 'الرصيد', en: 'Balance' },
    { key: 'wallet.transactions', namespace: 'wallet', ar: 'حركات المحفظة', en: 'Wallet transactions' },
    { key: 'wallet.insufficient_balance', namespace: 'wallet', ar: 'رصيد المحفظة غير كافٍ', en: 'Wallet balance is insufficient' },
    { key: 'loyalty.title', namespace: 'loyalty', ar: 'نقاط الولاء', en: 'Loyalty Points' },
    { key: 'loyalty.points', namespace: 'loyalty', ar: 'النقاط', en: 'Points' },
    { key: 'loyalty.coupons', namespace: 'loyalty', ar: 'الكوبونات', en: 'Coupons' },
    { key: 'loyalty.referrals', namespace: 'loyalty', ar: 'الإحالات', en: 'Referrals' },
    { key: 'notifications.title', namespace: 'notifications', ar: 'الإشعارات', en: 'Notifications' },
    { key: 'notifications.unread', namespace: 'notifications', ar: 'غير مقروء', en: 'Unread' },
    { key: 'employees.title', namespace: 'employees', ar: 'الموظفون', en: 'Employees' },
    { key: 'branches.title', namespace: 'branches', ar: 'الفروع', en: 'Branches' },
    { key: 'organizations.title', namespace: 'organizations', ar: 'المؤسسات', en: 'Organizations' },
    { key: 'merchant.dashboard', namespace: 'merchant', ar: 'لوحة التاجر', en: 'Merchant Dashboard' },
    { key: 'workshop.dashboard', namespace: 'workshop', ar: 'لوحة الورشة', en: 'Workshop Dashboard' },
    { key: 'warehouse.dashboard', namespace: 'warehouse', ar: 'لوحة المستودع', en: 'Warehouse Dashboard' },
    { key: 'driver.dashboard', namespace: 'driver', ar: 'لوحة السائق', en: 'Driver Dashboard' },
    { key: 'finance.dashboard', namespace: 'finance', ar: 'لوحة المالية', en: 'Finance Dashboard' },
    { key: 'admin.title', namespace: 'admin', ar: 'مركز التحكم', en: 'Control Center' },
    { key: 'admin.analytics', namespace: 'admin', ar: 'التقارير والتحليلات', en: 'Reports & Analytics' },
    { key: 'admin.users', namespace: 'admin', ar: 'المستخدمون', en: 'Users' },
    { key: 'admin.locations', namespace: 'admin', ar: 'إدارة المواقع', en: 'Location Management' },
    { key: 'admin.settings', namespace: 'admin', ar: 'إعدادات النظام', en: 'System Settings' },
    { key: 'admin.i18n_catalog', namespace: 'admin', ar: 'كتالوج الترجمة', en: 'Translation Catalog' },
    { key: 'admin.quality_release', namespace: 'admin', ar: 'الجودة والإصدار', en: 'Quality & Release' },
    { key: 'settings.title', namespace: 'settings', ar: 'الإعدادات', en: 'Settings' },
    { key: 'settings.language', namespace: 'settings', ar: 'اللغة', en: 'Language' },
    { key: 'settings.arabic', namespace: 'settings', ar: 'العربية', en: 'Arabic' },
    { key: 'settings.english', namespace: 'settings', ar: 'الإنجليزية', en: 'English' },
    { key: 'settings.language_changed', namespace: 'settings', ar: 'تم تغيير اللغة', en: 'Language changed' },
    { key: 'status.pending', namespace: 'status', ar: 'قيد الانتظار', en: 'Pending' },
    { key: 'status.approved', namespace: 'status', ar: 'معتمد', en: 'Approved' },
    { key: 'status.rejected', namespace: 'status', ar: 'مرفوض', en: 'Rejected' },
    { key: 'status.cancelled', namespace: 'status', ar: 'ملغي', en: 'Cancelled' },
    { key: 'status.completed', namespace: 'status', ar: 'مكتمل', en: 'Completed' },
    { key: 'status.delivered', namespace: 'status', ar: 'تم التسليم', en: 'Delivered' },
    { key: 'status.paid', namespace: 'status', ar: 'مدفوع', en: 'Paid' },
    { key: 'status.failed', namespace: 'status', ar: 'فشل', en: 'Failed' },
    { key: 'validation.required', namespace: 'validation', ar: 'هذا الحقل مطلوب', en: 'This field is required' },
    { key: 'validation.phone', namespace: 'validation', ar: 'رقم الجوال غير صحيح', en: 'Invalid phone number' },
    { key: 'validation.email', namespace: 'validation', ar: 'البريد الإلكتروني غير صحيح', en: 'Invalid email address' },
    { key: 'validation.min_length', namespace: 'validation', ar: 'القيمة قصيرة جدًا', en: 'Value is too short' },
    { key: 'validation.max_length', namespace: 'validation', ar: 'القيمة طويلة جدًا', en: 'Value is too long' },
    { key: 'email.otp.subject', namespace: 'email', ar: 'رمز التحقق من غيارك', en: 'Ghiyarak verification code' },
    { key: 'email.otp.body', namespace: 'email', ar: 'رمز التحقق الخاص بك هو {code}', en: 'Your verification code is {code}' },
    { key: 'sms.otp.body', namespace: 'sms', ar: '{code} هو رمز التحقق الخاص بك في غيارك.', en: '{code} is your Ghiyarak verification code.' },
    { key: 'audit.action.created', namespace: 'audit', ar: 'تم الإنشاء', en: 'Created' },
    { key: 'audit.action.updated', namespace: 'audit', ar: 'تم التحديث', en: 'Updated' },
    { key: 'audit.action.deleted', namespace: 'audit', ar: 'تم الحذف', en: 'Deleted' },
    { key: 'reports.title', namespace: 'reports', ar: 'التقارير', en: 'Reports' },
    { key: 'analytics.title', namespace: 'analytics', ar: 'التحليلات', en: 'Analytics' },
    { key: 'auth.map.pick_title', namespace: 'auth', ar: 'تحديد موقع المنشأة على الخريطة', en: 'Pick business location on map' },
    { key: 'auth.map.instructions', namespace: 'auth', ar: 'انقر على الخريطة لتحديد موقع المتجر أو الورشة بدقة، ثم اضغط تأكيد.', en: 'Tap the map to pick the store or workshop location, then confirm.' },
    { key: 'auth.map.confirm_location', namespace: 'auth', ar: 'تأكيد الموقع', en: 'Confirm location' },
    { key: 'auth.map.selected_location', namespace: 'auth', ar: 'موقع محدد على الخريطة', en: 'Selected map location' },
    { key: 'auth.map.tap_to_select', namespace: 'auth', ar: 'اضغط هنا لفتح الخريطة وتحديد الموقع', en: 'Tap to open map and pick location' },
    { key: 'auth.map.tap_to_select_notice', namespace: 'auth', ar: 'العنوان لا يكتب يدويًا. يجب تحديد الموقع من الخريطة حتى تحفظ الإحداثيات وتظهر للإدارة.', en: 'Address is not free text. Pick the location from the map so coordinates are saved for admin review.' },
    { key: 'auth.map.location_saved', namespace: 'auth', ar: 'تم حفظ الموقع المحدد', en: 'Selected location saved' },
    { key: 'auth.map.location_required', namespace: 'auth', ar: 'يرجى تحديد موقع المنشأة من الخريطة.', en: 'Please pick the business location from the map.' },
    { key: 'auth.map.location_outside_yemen', namespace: 'auth', ar: 'الموقع المحدد يجب أن يكون داخل اليمن.', en: 'Selected location must be inside Yemen.' },
    { key: 'common.edit', namespace: 'common', ar: 'تعديل', en: 'Edit' },
    { key: 'common.delete', namespace: 'common', ar: 'حذف', en: 'Delete' },
    { key: 'status.active', namespace: 'status', ar: 'نشط', en: 'Active' },
    { key: 'status.blocked', namespace: 'status', ar: 'محظور', en: 'Blocked' },
    { key: 'admin.users.subtitle', namespace: 'admin', ar: 'إضافة وتعديل وتعطيل وحذف المستخدمين وربطهم بالأدوار والصلاحيات.', en: 'Add, edit, block, delete users and assign roles and permissions.' },
    { key: 'admin.users.add', namespace: 'admin', ar: 'إضافة مستخدم', en: 'Add user' },
    { key: 'admin.users.edit', namespace: 'admin', ar: 'تعديل المستخدم', en: 'Edit user' },
    { key: 'admin.users.delete', namespace: 'admin', ar: 'حذف المستخدم', en: 'Delete user' },
    { key: 'admin.users.delete_confirm', namespace: 'admin', ar: 'هل أنت متأكد من حذف هذا المستخدم؟ سيتم حذف الحساب وارتباطاته حسب قواعد قاعدة البيانات.', en: 'Are you sure you want to delete this user? The account and relations will be removed according to database rules.' },
    { key: 'admin.users.roles', namespace: 'admin', ar: 'الأدوار', en: 'Roles' },
    { key: 'admin.users.block', namespace: 'admin', ar: 'حظر', en: 'Block' },
    { key: 'admin.users.activate', namespace: 'admin', ar: 'تفعيل', en: 'Activate' },
    { key: 'auth.map.offline_mode', namespace: 'auth', ar: 'خريطة تقريبية تعمل بدون إنترنت', en: 'Offline approximate map' },
    { key: 'auth.map.address_hint', namespace: 'auth', ar: 'مثال: صنعاء، شارع الزبيري، جوار...', en: 'Example: Sana’a, Al-Zubairi St, near...' },
    { key: 'key', namespace: 'common', ar: 'المفتاح', en: 'Key' },
    { key: 'exports.pdf', namespace: 'exports', ar: 'تصدير PDF', en: 'Export PDF' },
    { key: 'exports.excel', namespace: 'exports', ar: 'تصدير Excel', en: 'Export Excel' },
  ];

  for (const item of translations) {
    const keyRow = await (prisma as any).translationKey.upsert({
      where: { key: item.key },
      update: { namespace: item.namespace, description: item.description ?? null, status: 'PUBLISHED', isSystem: true },
      create: { key: item.key, namespace: item.namespace, description: item.description ?? null, status: 'PUBLISHED', isSystem: true },
    }).catch(() => null);
    if (!keyRow) continue;
    for (const locale of ['ar', 'en'] as const) {
      await (prisma as any).translationValue.upsert({
        where: { translationKeyId_locale_platform: { translationKeyId: keyRow.id, locale, platform: 'GLOBAL' } },
        update: { value: item[locale], status: 'PUBLISHED', publishedAt: new Date() },
        create: { translationKeyId: keyRow.id, locale, platform: 'GLOBAL', value: item[locale], status: 'PUBLISHED', publishedAt: new Date() },
      }).catch(() => null);
      await (prisma as any).translationEntry.upsert({
        where: { translationKey_locale_platform: { translationKey: item.key, locale, platform: 'GLOBAL' } },
        update: { value: item[locale], namespace: item.namespace, isSystem: true },
        create: { translationKey: item.key, locale, platform: 'GLOBAL', value: item[locale], namespace: item.namespace, isSystem: true },
      }).catch(() => null);
    }
  }
}

async function main() {
  await seedLocations();
  await seedRolesAndPermissions();
  await seedReleaseReadiness();
  await seedFullPlatformTranslations();
  await seedVehicles();
  await seedAdminAndSamples();
  await seedDemoAccessAccounts();
  await seedMarketplaceCore();
  await seedProductImportTemplates();
  await seedWorkshopOperations();
  await seedPhase7Operations();
  await seedPhase9Retention();
  await seedPaymentFinanceFoundation();
  await seedAccountingFoundation();
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });
