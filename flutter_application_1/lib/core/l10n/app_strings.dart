import 'package:flutter/material.dart';

class AppStrings {
  final bool isAr;
  const AppStrings(this.isAr);

  // ── Common ────────────────────────────────────────────────────────────────
  String get save => isAr ? 'حفظ' : 'Save';
  String get cancel => isAr ? 'إلغاء' : 'Cancel';
  String get confirm => isAr ? 'تأكيد' : 'Confirm';
  String get back => isAr ? 'رجوع' : 'Back';

  // ── Status labels (provider / worker) ─────────────────────────────────────
  String get statusAvailable => isAr ? 'متاح' : 'Available';
  String get statusBusy => isAr ? 'مشغول' : 'Busy';
  String get statusOffline => isAr ? 'غير متاح' : 'Offline';
  String statusFromRaw(String raw) {
    switch (raw) {
      case 'available': return statusAvailable;
      case 'busy':      return statusBusy;
      default:          return statusOffline;
    }
  }

  // ── Worker / provider cards ────────────────────────────────────────────────
  String yearsExpDisplay(int y) => isAr ? '$y سنوات خبرة' : '$y yrs exp.';
  String workerSaved(String name) =>
      isAr ? 'تم حفظ الفني $name في المفضلة بنجاح' : 'Technician $name saved to favourites';
  String workerUnsaved(String name) =>
      isAr ? 'تم إزالة الفني $name من المفضلة' : 'Technician $name removed from favourites';
  String get workerInfo => isAr ? 'معلومات الفني' : 'Technician Info';
  String get experienceAndJobs => isAr ? 'الخبرة والمهن' : 'Experience & Skills';
  String get availabilityLabel => isAr ? 'حالة التوفر' : 'Availability';
  String get chatAction => isAr ? 'محادثة' : 'Chat';
  String get requestAction => isAr ? 'الطلب' : 'Request';
  String get chatError => isAr ? 'تعذّر فتح المحادثة، حاول مجدداً' : 'Could not open chat. Please try again.';
  String get ratingLabel => isAr ? 'التقييم' : 'Rating';
  String get myInfoLabel => isAr ? 'معلوماتك' : 'Your Info';

  // ── Conversations ──────────────────────────────────────────────────────────
  String conversationNum(int id) => isAr ? 'محادثة #$id' : 'Chat #$id';
  String clientConvNum(int id) => isAr ? 'عميل #$id' : 'Client #$id';

  // ── Provider profile availability toggle ──────────────────────────────────
  String get availableNow => isAr ? 'متاح الآن' : 'Available Now';
  String get notAvailable => isAr ? 'غير متاح' : 'Offline';
  String get visibilityToClients => isAr ? 'حالة الظهور للعملاء' : 'Visibility to clients';

  // ── Register form ──────────────────────────────────────────────────────────
  String get province => isAr ? 'المحافظة' : 'Province';
  String get provinceRequired => isAr ? 'الرجاء اختيار المحافظة' : 'Please select a province';
  String get birthdateRequired => isAr ? 'الرجاء تحديد تاريخ الميلاد' : 'Please select your birthdate';
  String get confirmPassword => isAr ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get confirmPasswordHint => isAr ? 'أعد كتابة كلمة المرور' : 'Re-enter password';
  String get confirmPasswordRequired => isAr ? 'الرجاء تأكيد كلمة المرور' : 'Please confirm your password';
  String get passwordMismatch => isAr ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match';
  String get registerFailed => isAr ? 'فشل التسجيل' : 'Registration failed';
  String get phoneRequired => isAr ? 'الرجاء إدخال رقم الهاتف' : 'Please enter your phone number';
  String get phoneInvalid => isAr ? 'الرجاء إدخال رقم هاتف أردني صحيح (10 خانات)' : 'Please enter a valid Jordanian phone number (10 digits)';
  String get jobRequired => isAr ? 'الرجاء اختيار مهنة واحدة على الأقل' : 'Please select at least one profession';
  String get workLocationRequired => isAr ? 'الرجاء تحديد موقع العمل على الخريطة أولاً' : 'Please set your work location on the map first';
  String get workLocationLabel => isAr ? 'موقع العمل الجغرافي' : 'Work Location';
  String get workLocationHint => isAr ? 'اضغط لتحديد موقع عملك على الخريطة' : 'Tap to set your work location on the map';

  // ── Email verification ─────────────────────────────────────────────────────
  String get verifyEmailTitle => isAr ? 'تفعيل البريد الإلكتروني' : 'Email Verification';
  String get codeSentTo => isAr ? 'تم إرسال رمز التحقق إلى:' : 'Verification code sent to:';
  String get otpLabel => isAr ? 'رمز التحقق (6 أرقام)' : 'Verification Code (6 digits)';
  String get otpSixDigits => isAr ? 'الرمز يجب أن يكون 6 أرقام' : 'Code must be 6 digits';
  String get numbersOnly => isAr ? 'أرقام فقط' : 'Numbers only';
  String get activateAccount => isAr ? 'تفعيل الحساب' : 'Activate Account';
  String get notReceived => isAr ? 'لم يصلك الرمز؟' : 'Didn\'t receive the code?';
  String get resend => isAr ? 'إعادة إرسال' : 'Resend';
  String get accountActivated => isAr ? '✅ تم تفعيل حسابك بنجاح! يمكنك الآن تسجيل الدخول.' : '✅ Account activated! You can now sign in.';
  String get codeExpiredOrInvalid => isAr ? 'رمز التحقق غير صحيح أو منتهي الصلاحية' : 'Invalid or expired verification code';
  String codeSentSuccessTo(String email) =>
      isAr ? 'تم إعادة إرسال رمز التحقق إلى $email' : 'Code resent to $email';
  String get resendFailed => isAr ? 'فشل إرسال الرمز' : 'Failed to send code';

  // ── Rating ─────────────────────────────────────────────────────────────────
  String get ratingTitle => isAr ? 'تقييمك' : 'Your Rating';
  String ratingSuccess(int r) => isAr ? 'تم إرسال تقييمك: $r ⭐' : 'Rating submitted: $r ⭐';
  String get ratingFailed => isAr ? 'فشل إرسال التقييم، حاول مجدداً' : 'Failed to submit rating. Please try again.';
  String get sendRating => isAr ? 'إرسال' : 'Send';

  // ── Select date/time ──────────────────────────────────────────────────────
  String get chooseDayDate => isAr ? 'اختر اليوم والتاريخ' : 'Choose Day & Date';
  String get chooseTime => isAr ? 'اختر الوقت' : 'Choose Time';
  String get pastTimeError => isAr
      ? 'عذراً، لا يمكن اختيار وقت قديم مرّ اليوم! يرجى اختيار وقت مستقبلي.'
      : 'Cannot select a past time. Please choose a future time.';

  // ── Map screen ─────────────────────────────────────────────────────────────
  String locationError(String e) => isAr ? 'تعذّر تحديد موقعك: $e' : 'Could not detect your location: $e';
  String get locationPermDeniedMsg => isAr ? 'تم رفض صلاحية الموقع.' : 'Location permission denied.';

  // ── Worker profile ─────────────────────────────────────────────────────────
  String get profileTitleLabel => isAr ? 'الملف الشخصي' : 'Profile';
  String get editProfileTitle => isAr ? 'معلومات الحساب' : 'Account Info';

  // ── Order details ──────────────────────────────────────────────────────────
  String get selectTime => isAr ? 'تحديد الوقت' : 'Set Time';
  String get selectLocation => isAr ? 'تحديد الموقع' : 'Set Location';
  String get confirmOrder => isAr ? 'تأكيد الطلب' : 'Confirm Order';
  String get locationSet => isAr ? 'الموقع المحدد' : 'Selected Location';
  String get locationNotSet => isAr ? 'لم يُحدَّد الموقع' : 'Location not set';
  String get orderLocationRequired => isAr
      ? 'الرجاء تحديد موقع الخدمة أولاً'
      : 'Please set the service location first';
  String get orderTimeRequired => isAr
      ? 'الرجاء تحديد وقت الخدمة أولاً'
      : 'Please set the service time first';
  String get orderSentSuccess => isAr ? 'تم إرسال طلبك بنجاح ✅' : 'Order sent successfully ✅';
  String get orderSentFailed => isAr ? 'فشل إرسال الطلب. حاول مجدداً' : 'Failed to send order. Please try again.';

  // ── Order tracking ─────────────────────────────────────────────────────────
  String trackingTitle(String id) => isAr ? 'تتبع الطلب #$id' : 'Tracking Order #$id';
  String get yourCurrentLocation => isAr ? 'موقعك الحالي' : 'Your Location';
  String get technicianOnWay => isAr ? 'الفني في الطريق إليك' : 'Technician on the way';
  String get technicianComingNow => isAr ? 'الفني متوجه إليك الآن' : 'Technician is heading to you';
  String get updatingLocationLive => isAr ? 'جاري تحديث الموقع حياً...' : 'Updating location live...';

  // ── Select location screen ─────────────────────────────────────────────────
  String get locationServiceDisabledShort => isAr
      ? 'خدمة الموقع معطلة. يرجى تفعيلها من الإعدادات.'
      : 'Location service disabled. Enable it in settings.';
  String get locationPermDeniedApp => isAr
      ? 'تم رفض صلاحية الموقع. يرجى تفعيلها من إعدادات التطبيق.'
      : 'Location permission denied. Enable it in app settings.';
  String locationDetectError(String e) =>
      isAr ? 'حدث خطأ أثناء تحديد موقعك: $e' : 'Error detecting your location: $e';
  String get logout => isAr ? 'تسجيل الخروج' : 'Log Out';
  String get or => isAr ? 'أو' : 'Or';
  String get done => isAr ? 'تم' : 'Done';
  String get edit => isAr ? 'تعديل' : 'Edit';
  String get send => isAr ? 'إرسال' : 'Send';
  String get retry => isAr ? 'إعادة المحاولة' : 'Retry';
  String get sendError => isAr ? 'حدث خطأ، حاول مجدداً' : 'An error occurred, please try again';

  // ── Auth ──────────────────────────────────────────────────────────────────
  String get welcome => isAr ? 'مرحبا' : 'Welcome';
  String get loginToContinue => isAr ? 'سجل الدخول للمتابعة' : 'Sign in to continue';
  String get email => isAr ? 'البريد الالكتروني' : 'Email';
  String get emailHint => isAr ? 'ادخل بريدك الالكتروني' : 'Enter your email';
  String get password => isAr ? 'كلمة المرور' : 'Password';
  String get passwordHint => isAr ? 'ادخل كلمة المرور' : 'Enter your password';
  String get forgotPassword => isAr ? 'نسيت كلمة المرور؟' : 'Forgot password?';
  String get login => isAr ? 'تسجيل الدخول' : 'Sign In';
  String get noAccount => isAr ? 'ليس لديك حساب؟' : "Don't have an account?";
  String get createAccount => isAr ? 'إنشاء حساب جديد' : 'Create new account';
  String get continueAsGuest => isAr ? 'المتابعة كضيف' : 'Continue as guest';
  String get loginError => isAr ? 'خطأ في تسجيل الدخول' : 'Login error';
  String get emailRequired => isAr ? 'الرجاء إدخال البريد الإلكتروني' : 'Please enter your email';
  String get emailInvalid => isAr ? 'الرجاء إدخال بريد إلكتروني صحيح' : 'Please enter a valid email';
  String get passwordRequired => isAr ? 'الرجاء إدخال كلمة المرور' : 'Please enter your password';
  String get passwordMin => isAr ? 'كلمة المرور يجب أن لا تقل عن 6 خانات' : 'Password must be at least 6 characters';

  // ── User type screen ───────────────────────────────────────────────────────
  String get user => isAr ? 'المستخدم' : 'User';
  String get serviceProviderBtn => isAr ? 'مزود خدمة' : 'Service Provider';

  // ── Home ──────────────────────────────────────────────────────────────────
  String greet(String name) => isAr ? 'مرحبا، $name' : 'Hello, $name';
  String get availableServices => isAr ? 'الخدمات المتاحة' : 'Available Services';
  String get recentOrders => isAr ? 'طلباتي الأخيرة' : 'Recent Orders';
  String get noOrders => isAr ? 'لا توجد طلبات حتى الآن' : 'No orders yet';
  String get aiAssistant => isAr ? 'المساعد الذكي' : 'AI Assistant';
  String get aiSubtitle => isAr ? 'اوصف مشكلتك وسنساعدك' : 'Describe your problem, we\'ll help';

  // ── Services ──────────────────────────────────────────────────────────────
  String get electricity => isAr ? 'كهرباء' : 'Electrical';
  String get plumbing => isAr ? 'سباكة' : 'Plumbing';
  String get painting => isAr ? 'دهان' : 'Painting';
  String get carpentry => isAr ? 'نجارة' : 'Carpentry';

  // ── Profile ───────────────────────────────────────────────────────────────
  String get profileTitle => isAr ? 'الملف الشخصي' : 'Profile';
  String get manageAccount => isAr ? 'إدارة حسابك وإعداداتك' : 'Manage your account & settings';
  String get accountInfo => isAr ? 'معلومات الحساب' : 'Account Info';
  String get personalDetails => isAr ? 'البيانات الشخصية والتفاصيل' : 'Personal data and details';
  String get settingsTitle => isAr ? 'الإعدادات' : 'Settings';
  String get favoriteOptions => isAr ? 'الخيارات المفضلة' : 'Saved Providers';
  String get serviceProviderLabel => isAr ? 'مزود خدمة' : 'Service Provider';

  // ── Provider home ─────────────────────────────────────────────────────────
  String get welcomeProvider => isAr ? 'اهلا وسهلا بك' : 'Welcome';
  String get inHandcom => isAr ? 'في HandCom' : 'to HandCom';
  String get myOrders => isAr ? 'طلباتي' : 'My Orders';
  String get noOrdersNow => isAr ? 'لا توجد طلبات حالياً' : 'No orders currently';
  String get ordersBtn => isAr ? 'الطلبات' : 'Orders';

  // ── Notifications ─────────────────────────────────────────────────────────
  String get notificationsTitle => isAr ? 'الإشعارات' : 'Notifications';
  String get noNotifications => isAr ? 'لا توجد إشعارات' : 'No notifications';
  String get noNewNotifications => isAr ? 'لا توجد إشعارات جديدة' : 'No new notifications';
  String newNotifCount(int c) => isAr ? 'لديك $c إشعار جديد' : 'You have $c new notification${c == 1 ? '' : 's'}';
  String get markAllRead => isAr ? 'قراءة الكل' : 'Mark all read';
  String get darkMode => isAr ? 'الوضع الداكن' : 'Dark Mode';
  String get notificationsToggle => isAr ? 'الاشعارات' : 'Notifications';
  String get language => isAr ? 'اللغة' : 'Language';

  // ── Settings: legal & support ────────────────────────────────────────────
  String get termsOfUse => isAr ? 'شروط الاستخدام' : 'Terms of Use';
  String get technicalSupport => isAr ? 'دعم فني' : 'Technical Support';
  String get supportIntro => isAr
      ? 'لأي استفسار أو مشكلة تقنية أو ملاحظة، تواصل معنا عبر البريد الإلكتروني التالي:'
      : 'For any question, technical issue, or feedback, reach us at the email below:';
  String get sendEmail => isAr ? 'إرسال بريد إلكتروني' : 'Send Email';
  String get copyEmail => isAr ? 'نسخ البريد الإلكتروني' : 'Copy Email';
  String get emailCopied =>
      isAr ? 'تم نسخ البريد الإلكتروني' : 'Email copied to clipboard';
  String get couldNotOpenEmailApp =>
      isAr ? 'تعذّر فتح تطبيق البريد الإلكتروني' : 'Could not open the email app';
  String get termsOfUseContent => isAr ? _termsOfUseAr : _termsOfUseEn;

  static const String _termsOfUseAr = '''
مرحباً بك في تطبيق Handcom. يرجى قراءة شروط الاستخدام التالية بعناية، فاستخدامك للتطبيق يعني موافقتك الكاملة عليها.

1. وصف الخدمة
يوفر تطبيق Handcom منصة تربط بين مستخدمي الخدمة ومزودي خدمات الصيانة المنزلية (سباكة، كهرباء، نجارة، ودهان) لتسهيل طلب الخدمات وتتبعها والتواصل بشأنها وتقييمها.

2. إنشاء الحساب
- يجب تقديم بيانات صحيحة ودقيقة عند التسجيل، وتفعيل البريد الإلكتروني عبر رمز التحقق (OTP) المرسل إليك.
- يتحمل المستخدم مسؤولية الحفاظ على سرية بيانات حسابه وعدم مشاركتها مع أي طرف آخر.

3. مسؤوليات مستخدم الخدمة
- تقديم وصف واضح ودقيق للخدمة المطلوبة وموقعها والوقت المناسب لها.
- الالتزام بالمواعيد المتفق عليها مع مزود الخدمة، وإلغاء الطلب مسبقاً في حال تعذر الحضور.
- تقييم الخدمة بصدق وموضوعية بعد اكتمالها.

4. مسؤوليات مزود الخدمة
- تقديم معلومات صحيحة عن المهارات والخبرة وحالة التوفر.
- الالتزام بالمواعيد المتفق عليها، وعدم قبول طلبات تتعارض زمنياً مع طلبات أخرى مؤكدة.
- تقديم الخدمة بجودة ومهنية مناسبة، والتعامل بأخلاق مع المستخدمين.

5. السلوك والمحتوى
يُمنع استخدام التطبيق لأي غرض غير قانوني، أو إرسال محتوى مسيء أو مضايق أو احتيالي عبر المحادثات أو التقييمات.

6. التقييمات
يجب أن تعكس التقييمات تجربة فعلية وصادقة، ويحتفظ التطبيق بالحق في إزالة أي تقييم مخالف أو مسيء.

7. تعليق أو إيقاف الحساب
يحتفظ Handcom بالحق في تعليق أو إيقاف أي حساب يخالف هذه الشروط أو يُستخدم بطريقة تضر بالمستخدمين الآخرين أو بالمنصة.

8. حدود المسؤولية
يعمل التطبيق كوسيط لتسهيل التواصل بين الطرفين، ولا يتحمل مسؤولية مباشرة عن جودة الخدمة المقدمة من مزود الخدمة، لكنه يلتزم بمتابعة الشكاوى لتحسين جودة المنصة.

9. التعديلات على الشروط
قد تُحدَّث هذه الشروط من وقت لآخر، واستمرارك في استخدام التطبيق بعد أي تحديث يُعد موافقة عليها.

10. التواصل
لأي استفسار بخصوص هذه الشروط، يمكنك التواصل معنا عبر "دعم فني" من الإعدادات.''';

  static const String _termsOfUseEn = '''
Welcome to Handcom. Please read these Terms of Use carefully — by using the app, you agree to be bound by them.

1. Service Description
Handcom is a platform that connects service users with home-maintenance service providers (plumbing, electrical, carpentry, and painting), making it easy to request, track, discuss, and rate services.

2. Account Creation
- You must provide accurate information when registering and verify your email using the OTP code sent to you.
- You are responsible for keeping your account credentials confidential and not sharing them with anyone else.

3. Responsibilities of Service Users
- Provide a clear and accurate description of the requested service, its location, and the preferred time.
- Honor scheduled appointments with the service provider, and cancel in advance if you can't attend.
- Rate the completed service honestly and fairly.

4. Responsibilities of Service Providers
- Provide accurate information about your skills, experience, and availability.
- Honor scheduled appointments, and do not accept requests that conflict with other confirmed bookings.
- Deliver services with appropriate quality and professionalism, and treat users respectfully.

5. Conduct and Content
You may not use the app for any unlawful purpose, or send abusive, harassing, or fraudulent content through chats or ratings.

6. Ratings
Ratings must reflect a genuine, honest experience. Handcom reserves the right to remove any rating that violates these terms or is abusive.

7. Account Suspension
Handcom reserves the right to suspend or terminate any account that violates these terms or harms other users or the platform.

8. Limitation of Liability
The app acts as an intermediary to facilitate communication between users and providers, and is not directly responsible for the quality of services delivered by providers, though complaints are reviewed to improve platform quality.

9. Changes to These Terms
These terms may be updated from time to time. Continued use of the app after an update constitutes acceptance of the changes.

10. Contact
For any questions about these terms, please reach us via "Technical Support" in Settings.''';

  // ── Order appointments ─────────────────────────────────────────────────────
  String get orderAppointments => isAr ? 'موعد الطلبات' : 'Order Appointments';
  String get noIncomingOrders => isAr ? 'لا يوجد طلبات واردة حالياً' : 'No incoming orders';
  String orderNum(String n) => isAr ? 'طلب رقم ($n)' : 'Order #$n';
  String get confirmBtn => isAr ? 'تأكيد' : 'Confirm';
  String get cancelBtn => isAr ? 'إلغاء' : 'Cancel';
  String get orderConfirmedMsg => isAr ? 'تم تأكيد الطلب وبدء المتابعة' : 'Order confirmed and tracking started';
  String get orderCancelledMsg => isAr ? 'تم إلغاء الطلب بنجاح' : 'Order cancelled successfully';
  String get cannotCancelMsg => isAr ? 'لا يمكن إلغاء هذا الطلب حالياً' : 'Cannot cancel this order right now';

  // ── Service tracking ──────────────────────────────────────────────────────
  String get trackOrder => isAr ? 'متابعة الطلب' : 'Track Order';
  String get orderDetails => isAr ? 'تفاصيل الطلب' : 'Order Details';
  String get stepConfirm => isAr ? 'تأكيد الطلب' : 'Confirmed';
  String get stepStart => isAr ? 'بدء تنفيذ' : 'Started';
  String get stepDone => isAr ? 'الانتهاء' : 'Done';
  String get clientLocationBtn => isAr ? 'موقع العميل' : 'Client Location';
  String get addressLabel => isAr ? 'العنوان' : 'Address';
  String get clientNameLabel => isAr ? 'اسم العميل' : 'Client Name';
  String get serviceTypeLabel => isAr ? 'نوع الخدمة' : 'Service Type';
  String get orderDateLabel => isAr ? 'تاريخ الطلب' : 'Order Date';
  String get statusLabel => isAr ? 'الحالة' : 'Status';
  String get endOrderBtn => isAr ? 'انتهاء الطلب' : 'Complete Order';
  String get orderCompletedBadge => isAr ? 'تم إنهاء الطلب ✅' : 'Order Completed ✅';
  String get completedSuccess => isAr ? 'تم إنهاء الطلب بنجاح ✅' : 'Order completed successfully ✅';
  String get completeFailed => isAr ? 'فشل إنهاء الطلب. حاول مجدداً' : 'Failed to complete. Please try again';
  String get checkProcedures => isAr
      ? 'يرجى التأكد من إنهاء كافة الإجراءات قبل ضغط زر الانتهاء'
      : 'Please complete all procedures before pressing the finish button';
  String get loadFailed => isAr ? 'تعذّر تحميل بيانات الطلب' : 'Failed to load order data';
  String get clientLabel => isAr ? 'العميل' : 'Client';
  List<String> get weekdays => isAr
      ? ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت']
      : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  String get am => isAr ? 'ص' : 'AM';
  String get pm => isAr ? 'م' : 'PM';

  // ── Forgot / reset password ────────────────────────────────────────────────
  String get forgotPasswordTitle => isAr ? 'نسيت كلمة المرور' : 'Forgot Password';
  String get enterEmailHint => isAr ? 'ادخل البريد الالكتروني' : 'Enter Email Address';
  String get enterVerifyCode => isAr ? 'ادخل رمز التحقق' : 'Enter Verification Code';
  String get codeRequired => isAr ? 'الرجاء إدخال رمز التحقق' : 'Please enter the verification code';
  String get codeDigitsOnly => isAr ? 'الرجاء إدخال أرقام صحيحة فقط' : 'Please enter valid digits only';
  String get newPassword => isAr ? 'كلمة المرور الجديدة' : 'New Password';
  String get newPasswordRequired => isAr ? 'الرجاء إدخال كلمة المرور الجديدة' : 'Please enter your new password';
  String get passwordChangedSuccess => isAr ? 'تم تغيير كلمة المرور بنجاح' : 'Password changed successfully';
  String get invalidCode => isAr ? 'رمز التحقق غير صحيح' : 'Invalid verification code';

  // ── Chat ──────────────────────────────────────────────────────────────────
  String get chatsTitle => isAr ? 'المحادثات' : 'Chats';
  String get noChats => isAr ? 'لا توجد محادثات حتى الآن' : 'No chats yet';
  String get typeMessage => isAr ? '...اكتب رسالتك' : 'Type a message...';
  String get recordingVoice => isAr ? 'جاري تسجيل فويس...' : 'Recording voice...';
  String get online => isAr ? 'متصل الآن' : 'Online';
  String get closedChat => isAr ? 'محادثة مغلقة' : 'Closed';
  String get openChat => isAr ? 'مفتوحة' : 'Open';

  // ── Workers / guest ───────────────────────────────────────────────────────
  String get noElectricians => isAr ? 'لا يوجد كهربائيون متاحون حالياً' : 'No electricians available';
  String get noCarpenters => isAr ? 'لا يوجد نجارون متاحون حالياً' : 'No carpenters available';
  String get noPainters => isAr ? 'لا يوجد دهانون متاحون حالياً' : 'No painters available';
  String get noPlumbers => isAr ? 'لا يوجد سباكون متاحون حالياً' : 'No plumbers available';
  String get loginRequired => isAr ? 'تسجيل الدخول مطلوب' : 'Login Required';
  String get loginRequiredMsg => isAr
      ? 'عذراً، يجب عليك تسجيل الدخول أولاً لتتمكن من استخدام هذه الميزة.'
      : 'Sorry, you need to sign in first to use this feature.';
  String get loginNow => isAr ? 'تسجيل الدخول الآن' : 'Sign In Now';
  String get guestWelcome => isAr ? 'Handcom أهلاً بك في' : 'Welcome to HandCom';
  String get noResults => isAr ? 'لا يوجد' : 'Nothing here';

  // ── Favorites ─────────────────────────────────────────────────────────────
  String get noSavedOptions => isAr ? 'لا توجد خيارات محفوظة بعد' : 'No saved options yet';
  String get removedFromFavorites => isAr ? 'تم الإزالة من المفضلة' : 'Removed from favorites';

  // ── Account info / edit profile ───────────────────────────────────────────
  String get firstName => isAr ? 'الإسم الأول' : 'First Name';
  String get firstNameRequired => isAr ? 'الرجاء إدخال الاسم الأول' : 'Please enter your first name';
  String get lastName => isAr ? 'الإسم الأخير' : 'Last Name';
  String get lastNameRequired => isAr ? 'الرجاء إدخال الاسم الأخير' : 'Please enter your last name';
  String get phone => isAr ? 'رقم الهاتف' : 'Phone Number';
  String get city => isAr ? 'المدينة' : 'City';
  String get birthdate => isAr ? 'تاريخ الميلاد' : 'Birthdate';
  String get datePlaceholder => isAr ? 'يوم / شهر / سنة' : 'DD / MM / YYYY';
  String get profession => isAr ? 'المهنة' : 'Profession';
  String get chooseProfession => isAr ? 'اختر المهنة' : 'Choose profession';
  String get yearsExp => isAr ? 'سنوات الخبرة' : 'Years of Experience';
  String get bio => isAr ? 'النبذة التعريفية' : 'Bio';
  String get offeredServices => isAr ? 'الخدمات المقدمة' : 'Offered Services';
  String get editPassword => isAr ? 'لتعديل كلمة المرور' : 'To change password';
  String get saveChanges => isAr ? 'حفظ التغييرات' : 'Save Changes';
  String get saveDone => isAr ? 'تم الحفظ بنجاح' : 'Saved successfully';
  String get changesSaved => isAr ? 'تم حفظ التغييرات بنجاح' : 'Changes saved successfully';
  String get chooseProfessions => isAr ? 'اختر المهن' : 'Choose professions';
  String get male => isAr ? 'ذكر' : 'Male';
  String get female => isAr ? 'أنثى' : 'Female';
  String get gender => isAr ? 'الجنس' : 'Gender';
  String get newProviderTitle => isAr ? 'مزود خدمة جديد' : 'New Service Provider';
  String get newUserTitle => isAr ? 'مستخدم جديد' : 'New User';

  // ── Jordan cities ─────────────────────────────────────────────────────────
  static const Map<String, String> _cityArToEn = {
    'عمان': 'Amman', 'الزرقاء': 'Zarqa', 'إربد': 'Irbid',
    'العقبة': 'Aqaba', 'المفرق': 'Mafraq', 'جرش': 'Jerash',
    'عجلون': 'Ajloun', 'مأدبا': 'Madaba', 'مادبا': 'Madaba',
    'البلقاء': 'Balqa', 'الكرك': 'Karak', 'الطفيلة': 'Tafilah',
    'معان': "Ma'an",
  };
  static const List<String> jordanCitiesCanonical = [
    'عمان', 'الزرقاء', 'إربد', 'العقبة', 'المفرق', 'جرش',
    'عجلون', 'مأدبا', 'البلقاء', 'الكرك', 'الطفيلة', 'معان',
  ];
  String jordanCityLabel(String arabic) =>
      isAr ? arabic : (_cityArToEn[arabic] ?? arabic);

  // ── Location ──────────────────────────────────────────────────────────────
  String get locationPickerTitle => isAr ? 'تحديد الموقع' : 'Set Location';
  String get enableGPS => isAr
      ? 'الرجاء تفعيل خدمات الموقع (GPS) في الجهاز'
      : 'Please enable location services (GPS) on your device';
  String get locationDenied => isAr ? 'تم رفض إذن الوصول للموقع' : 'Location permission denied';
  String get locationPermanentDenied => isAr
      ? 'إذن الموقع مرفوض بشكل دائم من إعدادات الجهاز'
      : 'Location permission permanently denied. Enable in device settings.';
  String get sendCurrentLocation => isAr ? 'إرسال الموقع الحالي' : 'Send Current Location';
  String get workLocation => isAr ? 'موقع عملك' : 'Your Work Location';
  String get locationDisabled => isAr
      ? 'خدمات الموقع معطلة. يرجى تفعيلها من الإعدادات.'
      : 'Location services disabled. Please enable them in settings.';
  String get locationPermDenied => isAr ? 'تم رفض صلاحية الموقع.' : 'Location permission denied.';
  String get noProviders => isAr ? 'لا يوجد مزودون متاحون حالياً' : 'No providers available';
  String availableProviders(int n) => isAr ? 'المزودون المتاحون ($n)' : 'Available Providers ($n)';

  // ── AI assistant ──────────────────────────────────────────────────────────
  String get aiWelcome => isAr
      ? 'مرحباً! 👋 أنا مساعدك الذكي في Handcom.\n\nأخبرني عن أي مشكلة في منزلك وسأساعدك في إيجاد الحل أو أقترح عليك أفضل الفنيين المتاحين في منطقتك 🔧'
      : 'Hello! 👋 I\'m your AI assistant in HandCom.\n\nTell me about any home problem and I\'ll help you find a solution or suggest the best available technicians in your area 🔧';
  String get typing => isAr ? 'جاري الكتابة' : 'Typing';
  String get requestLabel => isAr ? 'طلب' : 'Request';
  String get aiConnError => isAr
      ? 'عذراً، حدث خطأ في الاتصال. حاول مجدداً 😔'
      : 'Sorry, a connection error occurred. Please try again 😔';
  String get galleryError => isAr ? 'تعذّر فتح المعرض' : 'Could not open gallery';
  String get cameraPermission => isAr
      ? 'يرجى منح صلاحية الكاميرا من إعدادات الجهاز'
      : 'Please grant camera permission in device settings';
  String get cameraError => isAr ? 'تعذّر فتح الكاميرا' : 'Could not open camera';
  String get micPermission => isAr
      ? 'يرجى منح صلاحية الميكروفون من إعدادات الجهاز'
      : 'Please grant microphone permission in device settings';
  String get requestSentSuccess => isAr
      ? 'تم إرسال طلبك بنجاح! ✅\nستتلقى إشعاراً عند قبول الطلب.'
      : 'Your request was sent successfully! ✅\nYou\'ll receive a notification when it\'s accepted.';
  String get requestFailed => isAr ? 'فشل إرسال الطلب. حاول مجدداً.' : 'Failed to send request. Please try again.';

  // ── Customer location ─────────────────────────────────────────────────────
  String get customerLocationTitle => isAr ? 'موقع العميل' : 'Customer Location';
  String get startNavigation => isAr ? 'بدء التوجيه (خرائط Google)' : 'Start Navigation (Google Maps)';

  // ── Select date/time ──────────────────────────────────────────────────────
  String get amFull => isAr ? 'صباحاً' : 'AM';
  String get pmFull => isAr ? 'مساءً' : 'PM';

  // ── Error codes ────────────────────────────────────────────────────────────
  /// Maps a stable backend `code` (or an `ApiException.code` like
  /// `TIMEOUT`/`NETWORK_ERROR`) to a localized, specific message. Falls back
  /// to [fallback] (typically the backend's raw `detail` text) for unmapped
  /// codes, and finally to a generic message.
  String errorMessage(String? code, {String? fallback}) {
    switch (code) {
      case 'TIMEOUT':
        return isAr
            ? 'استغرق الاتصال وقتاً طويلاً. تحقق من اتصالك وحاول مجدداً.'
            : 'The request took too long. Check your connection and try again.';
      case 'NETWORK_ERROR':
        return isAr
            ? 'تعذّر الاتصال بالخادم. تحقق من اتصالك بالإنترنت.'
            : 'Could not reach the server. Check your internet connection.';
      case 'email_not_verified':
        return isAr
            ? 'البريد الإلكتروني غير مفعّل. تحقق من صندوق البريد الوارد لرمز التفعيل.'
            : 'Your email is not verified yet. Check your inbox for the verification code.';
      case 'invalid_credentials':
      case 'authentication_failed':
        return isAr ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.' : 'Incorrect email or password.';
      case 'email_already_exists':
        return isAr
            ? 'يوجد حساب مسجّل بهذا البريد الإلكتروني مسبقاً.'
            : 'An account with this email already exists.';
      case 'otp_expired':
        return isAr ? 'انتهت صلاحية رمز التحقق. اطلب رمزاً جديداً.' : 'This code has expired. Request a new one.';
      case 'otp_invalid':
        return isAr ? 'رمز التحقق غير صحيح.' : 'Invalid verification code.';
      case 'account_not_found':
        return isAr ? 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني.' : 'No account found for this email.';
      case 'provider_not_found':
        return isAr
            ? 'مزود الخدمة المختار غير متاح حالياً.'
            : 'The selected provider is no longer available.';
      case 'schedule_conflict':
        return isAr
            ? 'يوجد لدى هذا المزود طلب آخر في هذا الوقت تقريباً. الرجاء اختيار وقت مختلف.'
            : 'This provider already has a booking around that time. Please choose a different time.';
      case 'service_not_found':
        return isAr ? 'الخدمة غير موجودة.' : 'Service not found.';
      case 'service_not_completed':
        return isAr ? 'يمكنك تقييم الخدمة بعد اكتمالها فقط.' : 'You can only rate a completed service.';
      case 'not_service_owner':
        return isAr ? 'يمكنك تقييم الخدمات التي طلبتها أنت فقط.' : 'You can only rate services you requested.';
      case 'rating_window_expired':
        return isAr
            ? 'انتهت فترة السماح لتقييم هذه الخدمة.'
            : 'The rating window for this service has expired.';
      case 'already_rated':
        return isAr ? 'لقد قيّمت هذه الخدمة من قبل.' : 'You already rated this service.';
      case 'email_send_failed':
        return isAr
            ? 'تعذّر إرسال البريد الإلكتروني. حاول مرة أخرى لاحقاً.'
            : 'Could not send the email. Please try again later.';
      case 'no_analysis_found':
        return isAr
            ? 'لا يوجد تحليل لهذه المحادثة بعد. صف مشكلتك أولاً.'
            : 'No analysis found for this conversation yet. Describe your issue first.';
      case 'permission_denied':
        return isAr ? 'لا تملك صلاحية لتنفيذ هذا الإجراء.' : "You don't have permission to do this.";
      case 'not_found':
        return isAr ? 'العنصر المطلوب غير موجود.' : 'Not found.';
      case 'throttled':
        return isAr ? 'عدد كبير من الطلبات. الرجاء الانتظار قليلاً.' : 'Too many requests. Please wait a moment.';
      case 'validation_error':
        return (fallback != null && fallback.isNotEmpty)
            ? fallback
            : (isAr ? 'البيانات المدخلة غير صحيحة.' : 'The submitted data is invalid.');
      case 'server_error':
        return isAr
            ? 'حدث خطأ من جانبنا. الرجاء المحاولة مرة أخرى لاحقاً.'
            : 'Something went wrong on our end. Please try again later.';
      default:
        if (fallback != null && fallback.isNotEmpty) return fallback;
        return isAr ? 'حدث خطأ. الرجاء المحاولة مجدداً' : 'Something went wrong. Please try again.';
    }
  }
}

extension BuildContextStrings on BuildContext {
  AppStrings get l10n {
    final code = Localizations.localeOf(this).languageCode;
    return AppStrings(code == 'ar');
  }
}
