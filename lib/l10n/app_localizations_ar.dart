// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'DKT Sales APP';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get signInToContinue => 'قم بتسجيل الدخول إلى حسابك للمتابعة';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get password => 'كلمة المرور';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get phone => 'الهاتف';

  @override
  String get roleId => 'معرف الدور';

  @override
  String get supervisorId => 'معرف المشرف (اختياري)';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get guestMode => 'وضع الضيف';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get contactAdmin => 'اتصل بالمسؤول';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get createUser => 'إنشاء مستخدم';

  @override
  String get users => 'المستخدمون';

  @override
  String get targets => 'الأهداف';

  @override
  String get settings => 'الإعدادات';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get createNewUser => 'إنشاء مستخدم جديد';

  @override
  String get fillDetailsToCreateUser => 'املأ التفاصيل لإنشاء حساب مستخدم جديد';

  @override
  String get createUserButton => 'إنشاء مستخدم';

  @override
  String get language => 'اللغة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get signedInSuccessfully => 'تم تسجيل الدخول بنجاح!';

  @override
  String get userCreatedSuccessfully => 'تم إنشاء المستخدم بنجاح!';

  @override
  String get enterUsername => 'أدخل اسم المستخدم';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get enterFullName => 'أدخل الاسم الكامل';

  @override
  String get enterEmail => 'user@example.com';

  @override
  String get enterPhone => 'أدخل رقم الهاتف';

  @override
  String get enterRoleId => 'أدخل معرف الدور (UUID)';

  @override
  String get enterSupervisorId => 'أدخل معرف المشرف (UUID)';

  @override
  String get supervisor => 'المشرف';

  @override
  String get selectSupervisor => 'اختر المشرف';

  @override
  String get subRoles => 'الأدوار الفرعية';

  @override
  String get selectSubRoles => 'اختر الأدوار الفرعية';

  @override
  String get sapSalesEmployeeCode => 'موظف المبيعات SAP';

  @override
  String get selectSapSalesEmployee => 'اختر موظف المبيعات SAP';

  @override
  String get searchEmployee => 'ابحث عن الموظف بالاسم أو الرمز';

  @override
  String get noEmployeesFound => 'لم يتم العثور على موظفين';

  @override
  String get territoryId => 'معرف الإقليم (اختياري)';

  @override
  String get enterTerritoryId => 'أدخل معرف الإقليم (UUID)';

  @override
  String get selectTerritory => 'اختر الإقليم';

  @override
  String get selectSubTerritory => 'اختر الإقليم الفرعي';

  @override
  String get cancel => 'إلغاء';

  @override
  String get exit => 'خروج';

  @override
  String get exitApp => 'الخروج من التطبيق؟';

  @override
  String get exitAppConfirmation => 'هل أنت متأكد أنك تريد الخروج؟';

  @override
  String get home => 'الرئيسية';

  @override
  String get journeyPlans => 'خطط الرحلات';

  @override
  String get journeyPlan => 'خطة الرحلة';

  @override
  String get createJourneyPlan => 'إنشاء خطة رحلة';

  @override
  String get createJourneyPlanFor => 'إنشاء خطة رحلة لـ';

  @override
  String get totalJourneys => 'إجمالي الرحلات';

  @override
  String get upcoming => 'القادمة';

  @override
  String get approved => 'المعتمدة';

  @override
  String get totalStops => 'إجمالي الزيارات';

  @override
  String get totalTargets => 'إجمالي الأهداف';

  @override
  String get avgProgress => 'متوسط التقدم';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get createJourney => 'إنشاء رحلة';

  @override
  String get viewTargets => 'عرض الأهداف';

  @override
  String get standaloneVisit => 'زيارة منفردة';

  @override
  String get standaloneVisits => 'الزيارات المنفردة';

  @override
  String get createStandaloneVisit => 'إنشاء زيارة';

  @override
  String get customers => 'العملاء';

  @override
  String get salesOrder => 'أمر البيع';

  @override
  String get salesOrders => 'أوامر البيع';

  @override
  String get deliveries => 'التسليمات';

  @override
  String get noDeliveries => 'لا توجد تسليمات.';

  @override
  String get returns => 'المرتجعات';

  @override
  String get noReturns => 'لا توجد مرتجعات.';

  @override
  String welcomeBackUser(String name) {
    return 'مرحباً بعودتك، $name!';
  }

  @override
  String get heresYourOverview => 'إليك نظرة عامة';

  @override
  String get forMyself => 'لنفسي';

  @override
  String get forAnotherUser => 'لمستخدم آخر';

  @override
  String get selectUser => 'اختر المستخدم';

  @override
  String get selectUserHint => 'اختر المستخدم...';

  @override
  String get noUsersAvailable => 'لا يوجد مستخدمون متاحون';

  @override
  String get startDate => 'تاريخ البداية';

  @override
  String get endDate => 'تاريخ النهاية';

  @override
  String get notesOptional => 'ملاحظات (اختياري)';

  @override
  String get enterAdditionalNotes => 'أدخل أي ملاحظات إضافية...';

  @override
  String get day => 'يوم';

  @override
  String get week => 'أسبوع';

  @override
  String get month => 'شهر';

  @override
  String get quarter => 'ربع سنوي';

  @override
  String get year => 'سنة';

  @override
  String get next => 'التالي';

  @override
  String get createPlan => 'إنشاء خطة';

  @override
  String get addStops => 'إضافة زيارات';

  @override
  String get plannedDateAndTime => 'التاريخ والوقت المخطط';

  @override
  String get plannedTime => 'الوقت المخطط';

  @override
  String get estimatedDurationMinutes => 'المدة المقدرة (بالدقائق)';

  @override
  String get enterDurationMinutes => 'أدخل المدة بالدقائق';

  @override
  String get normal => 'عادي';

  @override
  String get coach => 'تدريب';

  @override
  String get double => 'مزدوج';

  @override
  String get visitType => 'نوع الزيارة';

  @override
  String get selectCustomer => 'اختر العميل';

  @override
  String get searchCustomers => 'ابحث عن العملاء بالاسم أو الرمز...';

  @override
  String get addToList => 'إضافة إلى القائمة';

  @override
  String get ok => 'موافق';

  @override
  String get save => 'حفظ';

  @override
  String get saveAllStops => 'حفظ جميع الزيارات';

  @override
  String get saveAndReturn => 'العودة إلى الخطة';

  @override
  String get pendingStops => 'الزيارات المعلقة';

  @override
  String get existingStops => 'الزيارات الحالية';

  @override
  String get edit => 'تعديل';

  @override
  String get delete => 'حذف';

  @override
  String get close => 'إغلاق';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get allUsers => 'جميع المستخدمين';

  @override
  String get allPeriods => 'جميع الفترات';

  @override
  String get selectPeriodType => 'اختر نوع الفترة...';

  @override
  String get myJourneys => 'رحلاتي';

  @override
  String get myVisits => 'زياراتي';

  @override
  String get assignedJourneys => 'الرحلات المعينة';

  @override
  String get myJourneyPlans => 'خطط رحلاتي';

  @override
  String get journeyPlansList => 'قائمة خطط الرحلات';

  @override
  String get myTargets => 'أهدافي';

  @override
  String get targetsList => 'قائمة الأهداف';

  @override
  String get pleaseSelectUser => 'يرجى اختيار مستخدم';

  @override
  String get deleteJourneyPlan => 'حذف خطة الرحلة';

  @override
  String get deleteJourneyPlanConfirmation =>
      'هل أنت متأكد من حذف خطة الرحلة هذه؟';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get targetDetails => 'تفاصيل الهدف';

  @override
  String get breakdowns => 'التفاصيل';

  @override
  String get value => 'القيمة';

  @override
  String get achieved => 'المحقق';

  @override
  String get remaining => 'المتبقي';

  @override
  String get progress => 'التقدم';

  @override
  String get details => 'التفاصيل';

  @override
  String get noDetailsAvailable => 'لا توجد تفاصيل متاحة';

  @override
  String get saving => 'جاري الحفظ...';

  @override
  String get pleaseSelectStartAndEndDates =>
      'يرجى اختيار تاريخ البداية والنهاية';

  @override
  String get pleaseCreateJourneyPlanFirst => 'يرجى إنشاء خطة رحلة أولاً';

  @override
  String get pleaseSelectCustomer => 'يرجى اختيار عميل';

  @override
  String get tapToSelectCustomer => 'اضغط لاختيار العميل';

  @override
  String get stop => 'زيارة';

  @override
  String visitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count زيارات',
      one: 'زيارة واحدة',
    );
    return '$_temp0';
  }

  @override
  String visitOrderBadge(int order) {
    return 'زيارة $order';
  }

  @override
  String get journeyPlanAddVisitTitle => 'إضافة زيارة';

  @override
  String get journeyPlanCreateFirstBeforeVisits =>
      'يرجى إنشاء خطة رحلة في الخطوة 1 قبل إضافة الزيارات.';

  @override
  String get journeyPlanStep2SubtitleExisting =>
      'اعرض الزيارات الحالية وأضف زيارات جديدة إلى خطتك';

  @override
  String get journeyPlanStep2SubtitleNew => 'أنشئ زيارة لخطة رحلتك';

  @override
  String get addNewVisit => 'إضافة زيارة جديدة';

  @override
  String get editVisit => 'تعديل الزيارة';

  @override
  String get updateVisit => 'تحديث الزيارة';

  @override
  String get supervisorVisits => 'زيارات المشرف';

  @override
  String get notStarted => 'لم تبدأ';

  @override
  String get completed => 'مكتملة';

  @override
  String get noVisitsFound => 'لم يتم العثور على زيارات';

  @override
  String get surveys => 'الاستبيانات';

  @override
  String get createSurvey => 'إنشاء استبيان';

  @override
  String get editSurvey => 'تعديل استبيان';

  @override
  String get surveyName => 'اسم الاستبيان';

  @override
  String get pleaseEnterSurveyName => 'الرجاء إدخال اسم الاستبيان';

  @override
  String get description => 'الوصف';

  @override
  String get isActive => 'نشط';

  @override
  String get validFrom => 'صالح من';

  @override
  String get validTo => 'صالح حتى';

  @override
  String get selectDate => 'اختر التاريخ';

  @override
  String get questions => 'الأسئلة';

  @override
  String get addQuestion => 'إضافة سؤال';

  @override
  String get create => 'إنشاء';

  @override
  String get update => 'تحديث';

  @override
  String get noSurveys => 'لا توجد استبيانات';

  @override
  String get createYourFirstSurvey => 'قم بإنشاء أول استبيان للبدء';

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'غير نشط';

  @override
  String get actions => 'إجراءات';

  @override
  String get createCustomer => 'إنشاء عميل';

  @override
  String get createSalesOrder => 'إنشاء أمر بيع';

  @override
  String get createDelivery => 'إنشاء تسليم';

  @override
  String get createReturn => 'إنشاء مرتجع';

  @override
  String get createIncomingPayment => 'دفعة واردة';

  @override
  String get visitSurvey => 'استبيان';

  @override
  String get visitSurveySubmissions => 'إجابات الاستبيانات';

  @override
  String get visitSurveySelectTitle => 'اختر استبياناً';

  @override
  String get visitSurveyNoSurveys => 'لا توجد استبيانات متاحة.';

  @override
  String get visitSurveyNoSubmissions => 'لا توجد إجابات استبيان لهذه الزيارة.';

  @override
  String get visitSurveyNoQuestions =>
      'لا تحتوي أسئلة هذا الاستبيان على معرّفات من الخادم ولا يمكن الإجابة عليها في التطبيق.';

  @override
  String get visitActionsEmpty =>
      'لا توجد إجراءات زيارة أو إجابات استبيان بعد.';

  @override
  String get visitSurveySubmitted => 'تم إرسال الاستبيان.';

  @override
  String get visitSurveySubmit => 'إرسال';

  @override
  String get visitSurveyRequired => 'يرجى الإجابة عن جميع الأسئلة المطلوبة.';

  @override
  String get visitSurveyAnswerAtLeastTwo =>
      'يرجى الإجابة عن سؤالين على الأقل قبل الإرسال.';

  @override
  String get visitSurveyAnswerAllQuestions =>
      'يرجى الإجابة عن كل الأسئلة قبل الإرسال.';

  @override
  String get visitSurveyAnswerAllHint =>
      'أجب عن جميع الأسئلة في البطاقة أدناه، ثم اضغط إرسال مرة واحدة لإرسال إجابتك.';

  @override
  String get visitSurveyNotActive =>
      'هذا الاستبيان غير نشط أو خارج فترة الصلاحية.';

  @override
  String get visitSurveyRecordedActions => 'الإجراءات المسجّلة';

  @override
  String get visitSurveyNoErpActions => 'لا توجد إجراءات ERP لهذه الزيارة بعد.';

  @override
  String visitSurveyFreeTextTooShort(int count) {
    return 'يُرجى إدخال $count أحرف على الأقل لهذه الإجابة.';
  }

  @override
  String visitSurveyFreeTextMinHint(int count) {
    return 'الحد الأدنى $count أحرف';
  }

  @override
  String get readyForDeliveryTitle => 'أوامر جاهزة للتسليم';

  @override
  String get readyForDeliverySearchHint =>
      'ابحث برقم المستند أو رمز أو اسم العميل…';

  @override
  String get readyForDeliveryEmpty => 'لا توجد أوامر جاهزة للتسليم.';

  @override
  String get readyForDeliveryRetry => 'إعادة المحاولة';

  @override
  String get readyForReturnTitle => 'تسليمات جاهزة للمرتجع';

  @override
  String get readyForReturnSearchHint =>
      'ابحث برقم المستند أو رمز أو اسم العميل…';

  @override
  String get readyForReturnEmpty => 'لا توجد تسليمات جاهزة للمرتجع.';

  @override
  String get readyForReturnRetry => 'إعادة المحاولة';

  @override
  String get docNumber => 'المستند';

  @override
  String get viewSalesOrders => 'عرض أوامر البيع';

  @override
  String get visitAction => 'إجراء الزيارة';

  @override
  String get inventory => 'طلب تحويل مخزون';

  @override
  String get inventoryDocNotFound => 'المستند غير موجود.';

  @override
  String get inventorySearchClearResult => 'مسح النتيجة';

  @override
  String get inventorySearchByDocEntry => 'البحث برقم المستند';

  @override
  String get inventoryListHint =>
      'أدخل رقم المستند أعلاه لفتح تحويل، أو استخدم الزر لإنشاء تحويل مخزون جديد.';

  @override
  String get inventoryFabCreate => 'إنشاء';

  @override
  String get inventoryCreateTransfer => 'تحويل مخزون جديد';

  @override
  String get inventoryDocumentDate => 'تاريخ المستند';

  @override
  String get inventoryFromWarehouse => 'من مستودع';

  @override
  String get inventoryToWarehouse => 'إلى مستودع';

  @override
  String get inventorySelectWarehouse => 'اختر مستودعاً';

  @override
  String get inventorySelectBothWarehouses => 'اختر مستودع المصدر والوجهة.';

  @override
  String get inventoryWarehousesMustDiffer =>
      'يجب أن يختلف مستودع المصدر عن الوجهة.';

  @override
  String get inventorySelectFromWarehouseFirst =>
      'اختر مستودع المصدر قبل إضافة الأصناف.';

  @override
  String get inventoryAddItems => 'إضافة أصناف';

  @override
  String get inventorySearchItemHint => 'ابحث برمز أو اسم الصنف…';

  @override
  String get inventoryNoItemFound => 'لم يُعثر على صنف.';

  @override
  String get inventoryItemAlreadyAdded => 'هذا الصنف مضاف بالفعل.';

  @override
  String get inventoryAddAtLeastOneLine => 'أضف سطراً واحداً على الأقل.';

  @override
  String inventorySelectUomForLine(String itemCode) {
    return 'اختر وحدة القياس لـ $itemCode';
  }

  @override
  String get inventoryQuantityMustBePositive =>
      'الكمية يجب أن تكون أكبر من صفر.';

  @override
  String get inventoryCreateFailed => 'تعذر إنشاء التحويل.';

  @override
  String get inventoryTransferSuccessTitle => 'تم بنجاح';

  @override
  String inventoryCreated(String doc) {
    return 'تم إنشاء التحويل — رقم المستند $doc';
  }

  @override
  String get inventorySubmitTransfer => 'إرسال التحويل';

  @override
  String get inventoryLines => 'الأسطر';

  @override
  String get inventoryNoLinesYet => 'لا توجد أسطر. ابحث وأضف أصنافاً أعلاه.';

  @override
  String get inventoryColItemCode => 'رمز الصنف';

  @override
  String get inventoryColItemName => 'اسم الصنف';

  @override
  String get inventoryColItemUnit => 'وحدة الصنف';

  @override
  String get inventoryColOnHand => 'المتاح';

  @override
  String get inventoryColQty => 'الكمية';

  @override
  String get inventoryColUom => 'وحدة القياس';

  @override
  String get inventoryNoUom => '—';

  @override
  String get inventoryDocEntry => 'رقم المستند';

  @override
  String get inventoryDocNum => 'رقم المستند';

  @override
  String get inventoryStatus => 'الحالة';

  @override
  String get inventoryPickItemTitle => 'اختر الصنف';

  @override
  String get inventoryPickItemSearchHint => 'تصفية بالرمز أو الاسم…';

  @override
  String get inventoryCounting => 'جرد المخزون';

  @override
  String get inventoryCountingListHint =>
      'أدخل رقم المستند أعلاه لفتح جرد، أو استخدم إنشاء لبدء جرد جديد.';

  @override
  String get inventoryCountingNew => 'جرد مخزون جديد';

  @override
  String get inventoryCountDate => 'تاريخ الجرد';

  @override
  String get inventoryColCountedQty => 'المعدود';

  @override
  String get inventoryColVariance => 'الفرق';

  @override
  String get inventoryColWarehouse => 'المستودع';

  @override
  String get inventoryCountingCreateFailed => 'تعذر إنشاء الجرد.';

  @override
  String get inventoryCountingSuccessTitle => 'تم بنجاح';

  @override
  String inventoryCountingCreated(String doc) {
    return 'تم إنشاء الجرد — رقم المستند $doc';
  }

  @override
  String get inventoryCountingNoDefaultWarehouse =>
      'عيّن مستودعاً افتراضياً في ملفك قبل إنشاء جرد.';

  @override
  String get inventoryCountedQtyNonNegative =>
      'لا يمكن أن تكون الكمية المعدودة سالبة.';

  @override
  String get customersPickCustomerLocationTitle => 'اختر موقع العميل';

  @override
  String get customersPickLocationMapHint =>
      'اضغط على الخريطة في أي مكان لاختيار موقع العميل.';

  @override
  String get customersSearchAreaHint => 'بحث في المنطقة';

  @override
  String get customersSearchAreaTooltip => 'بحث في المنطقة';

  @override
  String get customersCouldNotSearchArea => 'تعذر البحث في هذه المنطقة حالياً';

  @override
  String customersLatLngLine(String lat, String lng) {
    return 'خط العرض: $lat ، خط الطول: $lng';
  }

  @override
  String get customersGoogleMapsOpenedSnackbar =>
      'تم فتح خرائط Google. اختر موقعاً، ثم مشاركة، انسخ الرابط والصقه في الحقل أدناه.';

  @override
  String get customersInvalidMapsLink =>
      'رابط خرائط Google غير صالح. يرجى لصق رابط يحتوي على الإحداثيات.';

  @override
  String get customersCustomerCreatedSuccess => 'تم إنشاء العميل بنجاح';

  @override
  String customersCustomerCreatedWithDetails(String details) {
    return 'تم إنشاء العميل: $details';
  }

  @override
  String get customersDuplicatePhoneTitle => 'الهاتف مستخدم مسبقاً';

  @override
  String get customersDuplicatePhoneCreateAnyway => 'إنشاء على أي حال';

  @override
  String get customersDuplicatePhoneChange => 'تغيير';

  @override
  String get customersCustomerLocationSection => 'موقع العميل';

  @override
  String get customersLocationHowTo =>
      'لاختيار الموقع: افتح خرائط Google بالزر أدناه، حدد موقع العميل على الخريطة، اضغط مشاركة، انسخ الرابط ثم الصقه في الحقل أدناه.';

  @override
  String get customersGoogleMapsLinkLabel => 'رابط خرائط Google';

  @override
  String get customersGoogleMapsLinkHint => 'https://www.google.com/maps?q=...';

  @override
  String get customersLatitude => 'خط العرض';

  @override
  String get customersLongitude => 'خط الطول';

  @override
  String get customersOpenGoogleMaps => 'فتح خرائط Google';

  @override
  String get customersPickOnMap => 'اختيار على الخريطة';

  @override
  String get customersMapConfirmPick => 'اختيار';

  @override
  String get customersCreateCustomerTitle => 'إنشاء عميل';

  @override
  String get customersFieldName => 'الاسم';

  @override
  String get customersFieldArabicName => 'الاسم بالعربية';

  @override
  String get customersFieldArea => 'المنطقة';

  @override
  String get customersFieldCity => 'المدينة';

  @override
  String get customersFieldAddress => 'العنوان';

  @override
  String get customersFieldPhone1 => 'هاتف 1';

  @override
  String get customersFieldPhone2 => 'هاتف 2';

  @override
  String get customersPhoneKindMobile => 'جوال';

  @override
  String get customersPhoneKindLandLine => 'خط أرضي';

  @override
  String get customersPhoneMobileInvalid => 'أدخل 11 رقماً بالضبط للجوال';

  @override
  String get customersPhoneLandLineInvalid =>
      'أدخل 10 أرقام بالضبط للخط الأرضي';

  @override
  String get customersPhoneDigitsOnly => 'أدخل أرقاماً فقط';

  @override
  String customersPhoneMaxLengthInvalid(int max) {
    return 'أدخل $max أرقام كحد أقصى';
  }

  @override
  String get customersFieldVatNumber => 'الرقم الضريبي';

  @override
  String get customersFieldRequired => 'هذا الحقل مطلوب';

  @override
  String get customersEnglishNameOnly =>
      'يجب أن يحتوي الاسم الإنجليزي على أحرف إنجليزية فقط';

  @override
  String get customersArabicNameOnly =>
      'يجب أن يحتوي الاسم العربي على أحرف عربية فقط';

  @override
  String get customersPhone1Invalid =>
      'أدخل 11 رقماً بالضبط للجوال (مثال: 01234567890)';

  @override
  String get customersPhone2Invalid => 'يجب ألا يتجاوز هاتف 2 10 أحرف';

  @override
  String get customersLocationRequired => 'موقع العميل مطلوب';

  @override
  String get customersSelectSeriesRequired => 'يرجى اختيار السلسلة';

  @override
  String get customersSelectChannelBpRequired => 'يرجى اختيار عميل قناة BP';

  @override
  String get customersSelectAreaRequired => 'يرجى اختيار المنطقة';

  @override
  String get customersSelectZoneRequired => 'يرجى اختيار النطاق';

  @override
  String get customersSelectStateRequired => 'يرجى اختيار المحافظة / الولاية';

  @override
  String get customersSelectCityRequired => 'يرجى اختيار المدينة';

  @override
  String get customersSelectRegionRequired => 'يرجى اختيار المنطقة الفرعية';

  @override
  String get customersSelectCustomerTypeRequired => 'يرجى اختيار نوع العميل';

  @override
  String get customersFieldGov => 'المحافظة';

  @override
  String get customersFieldState => 'المحافظة / الولاية';

  @override
  String get customersFieldZone => 'النطاق';

  @override
  String get customersFieldRegion => 'المنطقة الفرعية';

  @override
  String get customersSelectZone => 'اختر النطاق';

  @override
  String get customersSelectZoneTitle => 'اختر النطاق';

  @override
  String get customersSelectZoneFirst => 'اختر المنطقة أولاً';

  @override
  String get customersSelectStateZoneFirst => 'اختر النطاق أولاً';

  @override
  String get customersSelectRegion => 'اختر المنطقة الفرعية';

  @override
  String get customersSelectRegionTitle => 'اختر المنطقة الفرعية';

  @override
  String get customersSelectCityFirst => 'اختر المدينة أولاً';

  @override
  String get customersSelectArea => 'اختر المنطقة';

  @override
  String get customersSelectAreaTitle => 'اختر المنطقة';

  @override
  String get customersSelectState => 'اختر الولاية';

  @override
  String get customersSelectStateTitle => 'اختر الولاية';

  @override
  String get customersSelectStateFirst => 'اختر الولاية أولاً';

  @override
  String get customersSelectCity => 'اختر المدينة';

  @override
  String get customersSelectCityTitle => 'اختر المدينة';

  @override
  String get customersSearchMasterDataHint => 'بحث...';

  @override
  String get customersNoMasterDataFound => 'لا توجد نتائج';

  @override
  String get customersNoMatchingMasterData => 'لا توجد نتائج مطابقة';

  @override
  String get customersFieldTerr => 'الإقليم';

  @override
  String get customersSelectChannelBpTitle => 'اختر قناة BP (عميل)';

  @override
  String get customersSearchCustomersEllipsis => 'ابحث عن العملاء...';

  @override
  String get customersNoCustomersFoundList => 'لم يُعثر على عملاء';

  @override
  String get customersChannelBpLabel => 'قناة BP';

  @override
  String get customersSelectCustomerPlaceholder => 'اختر عميلاً';

  @override
  String get customersSeries => 'السلسلة';

  @override
  String get customersSearchTerritoriesHint => 'ابحث في الأقاليم...';

  @override
  String get customersNoTerritoriesFound => 'لم يُعثر على أقاليم';

  @override
  String get customersNoMatchingTerritories => 'لا توجد أقاليم مطابقة';

  @override
  String get customersSelectGovernorate => 'اختر المحافظة';

  @override
  String get customersSelectGovernorateFirst => 'اختر المحافظة أولاً';

  @override
  String get customersSelectTerritory => 'اختر الإقليم';

  @override
  String get customersSelectGovernorateTitle => 'اختر المحافظة';

  @override
  String get customersSelectTerritoryTitle => 'اختر الإقليم';

  @override
  String get customersUnknownPlace => 'مكان غير معروف';

  @override
  String get visitCreatedSuccess => 'تم إنشاء الزيارة';

  @override
  String get userNotFound => 'المستخدم غير موجود';

  @override
  String get locationCapturedSuccess => 'تم التقاط الموقع بنجاح!';

  @override
  String get locationErrorTitle => 'خطأ في الموقع';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get locationServicesDisabled =>
      'خدمات الموقع معطّلة. يرجى تفعيلها من إعدادات الجهاز.';

  @override
  String get locationPermissionDenied =>
      'تم رفض إذن الموقع. يرجى منح الإذن لاستخدام هذه الميزة.';

  @override
  String get locationPermissionDeniedForever =>
      'تم رفض إذن الموقع بشكل دائم. يرجى تفعيله من إعدادات التطبيق.';

  @override
  String get couldNotOpenGoogleMaps =>
      'تعذر فتح خرائط Google. تأكد من وجود متصفح أو تطبيق الخرائط.';

  @override
  String get googleMapsOpenedPasteLinkAbove =>
      'تم فتح خرائط Google. اختر موقعاً، ثم مشاركة، انسخ الرابط والصقه في الحقل أعلاه.';

  @override
  String get standaloneGoogleMapsLinkOptional => 'رابط خرائط Google (اختياري)';

  @override
  String get standaloneGoogleMapsHintAuto => 'يُنشأ رابط خرائط Google تلقائياً';

  @override
  String get standaloneMapsLocationTip =>
      'نصيحة: اضغط أيقونة الموقع لالتقاط موقعك الحالي، أو أيقونة الخريطة لفتح خرائط Google واختيار موقع يدوياً.';

  @override
  String get tooltipGetCurrentLocation => 'الحصول على الموقع الحالي';

  @override
  String get tooltipOpenMapsSelectLocation => 'فتح خرائط Google لاختيار موقع';

  @override
  String get standaloneVisitHistoryTab => 'السجل';

  @override
  String get standaloneVisitCurrentTab => 'الحالية';

  @override
  String get standaloneVisitFutureTab => 'المستقبلية';

  @override
  String get customersListTitle => 'العملاء';

  @override
  String get teamMapTitle => 'خريطة الفريق';

  @override
  String teamMapLastUpdated(String time) {
    return 'آخر تحديث: $time';
  }

  @override
  String get teamMapTeamList => 'الفريق';

  @override
  String get teamMapEmpty => 'لا يوجد أعضاء فريق للعرض.';

  @override
  String get teamMapNoLocation => 'لا يوجد موقع بعد';

  @override
  String get teamMapMemberDetailsTitle => 'تفاصيل مندوب المبيعات';

  @override
  String get teamMapMemberPlaceLabel => 'موقع قريب / نقطة مبيعات';

  @override
  String get teamMapPlaceLookupLoading => 'جاري البحث عن المكان القريب…';

  @override
  String get teamMapPlaceUnknown => 'تعذّر عرض اسم المكان';

  @override
  String get teamMapMemberLatitudeLabel => 'خط العرض';

  @override
  String get teamMapMemberLongitudeLabel => 'خط الطول';

  @override
  String teamMapMemberLocationTime(String time) {
    return 'وقت الموقع: $time';
  }

  @override
  String teamMapMemberAccuracyMeters(String meters) {
    return 'دقة GPS ±$meters م';
  }

  @override
  String get teamMapOpenInMaps => 'فتح في الخرائط';

  @override
  String get customersSearchByNameOrCode =>
      'ابحث عن العملاء بالاسم أو الرمز...';

  @override
  String get customersNoCustomersYet => 'لا يوجد عملاء بعد';

  @override
  String customersNoMatchSearch(String query) {
    return 'لا يوجد عملاء يطابقون \"$query\"';
  }

  @override
  String get customersTapPlusToCreate => 'اضغط + لإنشاء عميل';

  @override
  String get standaloneListNoPastVisits => 'لا توجد زيارات سابقة';

  @override
  String get standaloneListNoVisitsToday => 'لا توجد زيارات اليوم';

  @override
  String get standaloneListNoFutureVisits => 'لا توجد زيارات مستقبلية';

  @override
  String get dateLabelToday => 'اليوم';

  @override
  String get dateLabelYesterday => 'أمس';

  @override
  String get walletTitle => 'رصيد المحفظة';

  @override
  String get walletAccount => 'الحساب';

  @override
  String get walletProject => 'المشروع';

  @override
  String get walletLoadFailed => 'تعذّر تحميل رصيد المحفظة';

  @override
  String get walletRefresh => 'تحديث المحفظة';
}
