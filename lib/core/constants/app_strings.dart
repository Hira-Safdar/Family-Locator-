import 'package:flutter/material.dart';

abstract final class AppStrings {
  static const appName = 'Family Locator';
  static const loginTitle = 'Welcome Back!';
}

/// The app intentionally keeps its small translation catalogue in code.  This
/// makes strings available to widgets that are also used outside Material
/// routes, while still following the locale selected by settingsProvider.
class AppLocalizations {
  const AppLocalizations(this.locale);
  final Locale locale;
  bool get isUrdu => locale.languageCode == 'ur';
  String _t(String en, String ur) => isUrdu ? ur : en;

  static AppLocalizations of(BuildContext context) =>
      AppLocalizations(Localizations.localeOf(context));

  String get chooseLanguage => _t('Choose language', 'زبان منتخب کریں');
  String get selectPreferredLanguage =>
      _t('Select your preferred language', 'اپنی پسندیدہ زبان منتخب کریں');
  String get continueLabel => _t('Continue', 'جاری رکھیں');
  String get advertisement => _t('Advertisement', 'اشتہار');
  String get premiumTitle =>
      _t('Family Locator Premium', 'فیملی لوکیٹر پریمیم');
  String get premiumHeadline =>
      _t('Stay connected without interruptions', 'بغیر رکاوٹ کے جڑے رہیں');
  String get premiumDescription => _t(
    'Premium purchase will be available soon. You can continue using the free version for now.',
    'پریمیم خریداری جلد دستیاب ہوگی۔ فی الحال مفت ورژن استعمال جاری رکھیں۔',
  );
  String get continueFree =>
      _t('Continue with free version', 'مفت ورژن کے ساتھ جاری رکھیں');
  String get loginSubtitle => _t(
    'Sign in to see your family on the map',
    'نقشے پر اپنے خاندان کو دیکھنے کے لیے سائن اِن کریں',
  );
  String get email => _t('Email', 'ای میل');
  String get password => _t('Password', 'پاس ورڈ');
  String get forgotPassword => _t('Forgot password?', 'پاس ورڈ بھول گئے؟');
  String get signIn => _t('Sign In', 'سائن اِن');
  String get noAccount => _t("Don't have an account?", 'اکاؤنٹ نہیں ہے؟');
  String get signUp => _t('Sign Up', 'سائن اَپ');
  String get joinGroup => _t('Join Group', 'گروپ میں شامل ہوں');
  String get inviteMembers => _t('Invite Members', 'ارکان کو مدعو کریں');
  String get inviteCode => _t('Invite code', 'دعوتی کوڈ');
  String get enterInviteCode =>
      _t('Enter the invite code', 'دعوتی کوڈ درج کریں');
  String codeLength(int n) =>
      _t('Code must be $n characters', 'کوڈ $n حروف کا ہونا چاہیے');
  String get askInvite => _t(
    'Ask a family member for their invite code',
    'خاندان کے فرد سے دعوتی کوڈ لیں',
  );
  String get scanQr => _t('Scan QR Code', 'QR کوڈ اسکین کریں');
  String get groupCreated => _t('Group created!', 'گروپ بن گیا!');
  String get shareCode => _t(
    'Share this code or QR with the people you want to add.',
    'یہ کوڈ یا QR ان لوگوں کے ساتھ شیئر کریں جنہیں آپ شامل کرنا چاہتے ہیں۔',
  );
  String get copyCode => _t('Copy code', 'کوڈ کاپی کریں');
  String get shareInvite => _t('Share invite', 'دعوت شیئر کریں');
  String get done => _t('Done', 'مکمل');
  String get closeCamera => _t('Close', 'بند کریں');
  String get currentPassword => _t('Current password', 'موجودہ پاس ورڈ');
  String get newPassword => _t('New password', 'نیا پاس ورڈ');
  String get confirmNewPassword =>
      _t('Confirm new password', 'نئے پاس ورڈ کی تصدیق کریں');
  String get changePassword => _t('Change Password', 'پاس ورڈ تبدیل کریں');
  String get updatePassword => _t('Update Password', 'پاس ورڈ اپ ڈیٹ کریں');
  String get passwordSecurity => _t(
    'For your security, enter your current password, then choose a new one.',
    'اپنی حفاظت کے لیے موجودہ پاس ورڈ درج کریں، پھر نیا پاس ورڈ منتخب کریں۔',
  );
  String get passwordChanged => _t('Password changed', 'پاس ورڈ تبدیل ہو گیا');
  String get useNewPassword => _t(
    'Use your new password the next time you sign in.',
    'اگلی بار سائن اِن کرتے وقت نیا پاس ورڈ استعمال کریں۔',
  );
  String get changeEmail => _t('Change Email', 'ای میل تبدیل کریں');
  String get updateEmail => _t('Update Email', 'ای میل اپ ڈیٹ کریں');
  String get newEmail => _t('New email', 'نئی ای میل');
  String get emailSecurity => _t(
    'For your security, enter your current password, then your new email address.',
    'اپنی حفاظت کے لیے موجودہ پاس ورڈ اور پھر نئی ای میل درج کریں۔',
  );
  String currentEmail(String email) => _t('Current: $email', 'موجودہ: $email');
  String get checkInbox => _t('Check your inbox', 'اپنا ان باکس چیک کریں');
  String emailVerification(String email) => _t(
    'We sent a verification link to $email. Your email changes after you open that link.',
    'ہم نے $email پر تصدیقی لنک بھیجا ہے۔ لنک کھولنے کے بعد آپ کی ای میل تبدیل ہو جائے گی۔',
  );
  String get enterCurrentPassword =>
      _t('Enter your current password', 'اپنا موجودہ پاس ورڈ درج کریں');
  String get alreadyYourEmail =>
      _t('This is already your email', 'یہ پہلے ہی آپ کی ای میل ہے');
  String get sharing => _t('Sharing', 'شیئرنگ');
  String get shareMyLocation => _t('Share my location', 'میرا مقام شیئر کریں');
  String get locationLive =>
      _t('Your location updates are live', 'آپ کے مقام کی تازہ کاری جاری ہے');
  String get sharingPaused =>
      _t('Location sharing is paused', 'مقام کی شیئرنگ روک دی گئی ہے');
  String get locationHistory => _t('Location History', 'مقام کی تاریخ');
  String get clearLocationHistory =>
      _t('Clear my location history', 'مقام کی تاریخ صاف کریں');
  String get clearing => _t('Clearing...', 'صاف کیا جا رہا ہے...');
  String get removeSavedLocation => _t(
    'Removes your saved location from the map',
    'نقشے سے آپ کا محفوظ مقام ہٹا دیں',
  );
  String get locationHistoryCleared =>
      _t('Location history cleared.', 'مقام کی تاریخ صاف کر دی گئی۔');
  String get clearHistoryQuestion =>
      _t('Clear location history?', 'مقام کی تاریخ صاف کریں؟');
  String get clearHistoryDescription => _t(
    'This removes your latest saved location from the map. Your friends will stop seeing your pin until you share again.',
    'یہ نقشے سے آپ کا تازہ محفوظ مقام ہٹا دے گا۔ دوبارہ شیئر کرنے تک دوست آپ کا پن نہیں دیکھ سکیں گے۔',
  );
  String get cameraPermissionMessage => _t(
    'Camera permission is denied. Allow camera access in phone settings, then try again.',
    'کیمرے کی اجازت نہیں ہے۔ فون کی ترتیبات میں کیمرے کی اجازت دیں، پھر دوبارہ کوشش کریں۔',
  );
  String cameraOpenFailed(String code) =>
      _t('Camera could not open ($code).', 'کیمرہ نہیں کھل سکا ($code)۔');
  String get allGroups => _t('All Groups', 'تمام گروپس');
  String get createGroup => _t('Create Group', 'گروپ بنائیں');
  String get joinAGroup => _t('Join a Group', 'گروپ میں شامل ہوں');
  String get searchNameCode =>
      _t('Search by name or code', 'نام یا کوڈ سے تلاش کریں');
  String get sort => _t('Sort', 'ترتیب دیں');
  String get newestFirst => _t('Newest first', 'نئے پہلے');
  String get nameAZ => _t('Name (A-Z)', 'نام (الف تا ی)');
  String get mostMembers => _t('Most members', 'سب سے زیادہ ارکان');
  String get newGroup => _t('New Group', 'نیا گروپ');
  String get groupName => _t('Group name', 'گروپ کا نام');
  String get groupNameEmpty =>
      _t('Group name cannot be empty', 'گروپ کا نام خالی نہیں ہو سکتا');
  String get change => _t('Change', 'تبدیل کریں');
  String get myProfile => _t('My Profile', 'میرا پروفائل');
  String get editProfile => _t('Edit Profile', 'پروفائل میں ترمیم');
  String get displayName => _t('Display name', 'ظاہری نام');
  String get phoneOptional => _t('Phone (optional)', 'فون (اختیاری)');
  String get chooseGallery => _t('Choose from gallery', 'گیلری سے منتخب کریں');
  String get takePhoto => _t('Take a photo', 'تصویر لیں');
  String get yourProfile => _t('Your profile', 'آپ کا پروفائل');
  String get saveChanges => _t('Save', 'محفوظ کریں');
  String get profileLoadFailed => _t(
    'Could not load your profile. Please try again.',
    'پروفائل لوڈ نہیں ہو سکا۔ دوبارہ کوشش کریں۔',
  );
  String get back => _t('Back', 'واپس');
  String get retry => _t('Retry', 'دوبارہ کوشش کریں');
  String get tryAgain => _t('Try Again', 'دوبارہ کوشش کریں');
  String get dismiss => _t('Dismiss', 'بند کریں');
  String get createAccount => _t('Create your account', 'اپنا اکاؤنٹ بنائیں');
  String get fullName => _t('Full Name', 'پورا نام');
  String get confirmPassword => _t('Confirm Password', 'پاس ورڈ کی تصدیق کریں');
  String get nameEmpty => _t('Name cannot be empty', 'نام خالی نہیں ہو سکتا');
  String get passwordEmpty =>
      _t('Password cannot be empty', 'پاس ورڈ خالی نہیں ہو سکتا');
  String get validEmail => _t('Enter a valid email', 'درست ای میل درج کریں');
  String get passwordsMismatch =>
      _t('Passwords do not match', 'پاس ورڈ مماثل نہیں ہیں');
  String get confirmPasswordPrompt =>
      _t('Confirm your password', 'اپنا پاس ورڈ درج کریں');
  String get termsContinue => _t(
    'Please accept the Terms to continue',
    'جاری رکھنے کے لیے شرائط قبول کریں',
  );
  String get termsAgreement => _t(
    'I agree to the Terms of Service and Privacy Policy',
    'میں سروس کی شرائط اور رازداری کی پالیسی سے متفق ہوں',
  );
  String get alreadyAccount =>
      _t('Already have an account?', 'پہلے سے اکاؤنٹ ہے؟');
  String get somethingWrong => _t(
    'Something went wrong. Please try again.',
    'کچھ غلط ہو گیا۔ براہ کرم دوبارہ کوشش کریں۔',
  );
  String get forgotSubtitle => _t(
    'Enter your email and we will send you a link to reset it.',
    'اپنی ای میل درج کریں، ہم پاس ورڈ تبدیل کرنے کا لنک بھیجیں گے۔',
  );
  String get sendResetLink => _t('Send reset link', 'ری سیٹ لنک بھیجیں');
  String get rememberedIt => _t('Remembered it?', 'پاس ورڈ یاد آ گیا؟');
  String get checkEmail => _t('Check your email', 'اپنی ای میل چیک کریں');
  String get backToSignIn => _t('Back to sign in', 'سائن اِن پر واپس جائیں');
  String get chooseGroup => _t('Choose Group', 'گروپ منتخب کریں');
  String get groupQuestion => _t(
    'What kind of group are you creating?',
    'آپ کس قسم کا گروپ بنا رہے ہیں؟',
  );
  String get settings => _t('Settings', 'ترتیبات');
  String get map => _t('Map', 'نقشہ');
  String get groups => _t('Groups', 'گروپس');
  String get noInternet =>
      _t('No internet connection', 'انٹرنیٹ کنکشن نہیں ہے');
  String get checkConnection => _t(
    'Check your connection and try again.',
    'اپنا کنکشن چیک کر کے دوبارہ کوشش کریں۔',
  );
  String get locationPermission => _t('Location Permission', 'مقام کی اجازت');
  String get appearance => _t('Appearance', 'ظاہری شکل');
  String get notifications => _t('Notifications', 'اطلاعات');
  String get sosAlerts =>
      _t('SOS alerts and announcements', 'SOS الرٹس اور اعلانات');
  String get light => _t('Light', 'روشن');
  String get dark => _t('Dark', 'تاریک');
  String get systemDefault => _t('System default', 'سسٹم ڈیفالٹ');
  String get about => _t('About', 'ہمارے بارے میں');
  String get aboutSection => _t('About', 'ہمارے بارے میں');
  String get close => _t('Close', 'بند کریں');
  String get managePermissions => _t('Manage Permissions', 'اجازتوں کا انتظام');
  String get alwaysAllowed => _t('Always allowed', 'ہمیشہ اجازت ہے');
  String get whileUsing => _t('While using the app', 'ایپ استعمال کرتے وقت');
  String get denied => _t('Denied', 'مسترد');
  String get notAllowed => _t('Not allowed', 'اجازت نہیں ہے');
  String everySeconds(int n) => _t('Every $n seconds', 'ہر $n سیکنڈ');
  String everyMinutes(int n) => _t('Every $n min', 'ہر $n منٹ');
  String get myLocation => _t('My location', 'میرا مقام');
  String get sendSos => _t('Send SOS', 'SOS بھیجیں');
  String get cancel => _t('Cancel', 'منسوخ کریں');
  String get save => _t('Save', 'محفوظ کریں');
  String get pageNotFound => _t('Page not found', 'صفحہ نہیں ملا');
  String pageNotFoundAt(String location) =>
      _t("We couldn't find $location.", 'ہمیں $location نہیں ملا۔');
  String get goHome => _t('Go home', 'ہوم پر جائیں');
  String get privacyControls => _t('Privacy Controls', 'رازداری کے کنٹرولز');
  String get pauseSharing =>
      _t('Pause sharing or clear history', 'شیئرنگ روکیں یا تاریخ صاف کریں');
  String get general => _t('General', 'عام');
  String get locationRefresh => _t('Location Refresh', 'مقام کی تازہ کاری');
  String get alertsHistory => _t('Alerts History', 'الرٹس کی تاریخ');
  String get pastSos => _t('Past SOS alerts', 'پچھلے SOS الرٹس');
  String get others => _t('Others', 'دیگر');
  String get share => _t('Share', 'شیئر کریں');
  String get rateUs => _t('Rate us', 'ہمیں ریٹ کریں');
  String get feedback => _t('Feedback', 'رائے');
  String get helpSupport => _t('Help & Support', 'مدد اور معاونت');
  String get logout => _t('Logout', 'لاگ آؤٹ');
  String get deleteProfile => _t('Delete Profile', 'پروفائل حذف کریں');
  String get aboutDetails =>
      _t('App version and details', 'ایپ کا ورژن اور تفصیلات');
  String get privacyPolicy => _t('Privacy Policy', 'رازداری کی پالیسی');
  String get termsService => _t('Terms of Service', 'سروس کی شرائط');
  String categoryName(String value) => isUrdu
      ? const {
              'Friends': 'دوست',
              'School': 'اسکول',
              'Office': 'دفتر',
              'Travel': 'سفر',
              'Custom': 'اپنی مرضی',
            }[value] ??
            value
      : value;
  String categoryHint(String value) => isUrdu
      ? const {
              'Family and friends in one place': 'خاندان اور دوست ایک جگہ',
              'Classmates, trips and groups': 'ہم جماعت، سفر اور گروپس',
              'Colleagues and work teams': 'ساتھی اور کام کی ٹیمیں',
              'Trips, tours and travel buddies': 'سفر اور ہم سفر',
              'Type your own group name': 'اپنے گروپ کا نام لکھیں',
            }[value] ??
            value
      : value;
}
