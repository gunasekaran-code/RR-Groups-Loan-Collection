// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'RR Groups';

  @override
  String get welcomeMessage => 'FinCollect-க்கு நல்வரவு';

  @override
  String get loans => 'கடன்கள்';

  @override
  String get collections => 'வசூல்கள்';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get profile => 'சுயவிவரம்';

  @override
  String get editProfile => 'சுயவிவரத்தைத் திருத்து';

  @override
  String get notifications => 'அறிவிப்புகள்';

  @override
  String get paymentReminders => 'கட்டண நினைவூட்டல்கள்';

  @override
  String get groupUpdates => 'குழு புதுப்பிப்புகள்';

  @override
  String get security => 'பாதுகாப்பு';

  @override
  String get changeMpin => 'MPIN-ஐ மாற்று';

  @override
  String get biometricLogin => 'பயோமெட்ரிக் உள்நுழைவு';

  @override
  String get preferences => 'விருப்பங்கள்';

  @override
  String get language => 'மொழி';

  @override
  String get darkMode => 'டார்க் மோட்';

  @override
  String get help => 'உதவி';

  @override
  String get contactSupport => 'ஆதரவைத் தொடர்புகொள்ளவும்';

  @override
  String get faq => 'அடிக்கடி கேட்கப்படும் கேள்விகள்';

  @override
  String get logout => 'வெளியேறு';

  @override
  String get selectLanguage => 'மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get confirmLogoutQuestion =>
      'உங்கள் கணக்கிலிருந்து வெளியேற விரும்புகிறீர்களா?';

  @override
  String get cancel => 'ரத்துசெய்';

  @override
  String get loggedOut => 'வெளியேறிவிட்டீர்கள்';

  @override
  String get connectBackendToEnable =>
      'செயல்படுத்த பின்புற சேவையகத்தை இணைக்கவும்';

  @override
  String get deleteEntry => 'பதிவை நீக்கு';

  @override
  String get delete => 'நீக்கு';

  @override
  String get printStatement => 'அறிக்கையை அச்சிடு';

  @override
  String get accountBook => 'கணக்குப் புத்தகம்';

  @override
  String get recycleBinTitle => 'மறுசுழற்சி தொட்டி';

  @override
  String get recycleBinSubtitle =>
      'செயலியில் எங்கு நீக்கப்பட்டாலும் — நிர்வாகியால், முகவரால் அல்லது வாடிக்கையாளரால் நீக்கப்பட்டவை அனைத்தும்';

  @override
  String get recycleBinSearchHint =>
      'பெயர், வகை அல்லது யார் நீக்கினார்கள் என்பதன் அடிப்படையில் தேடவும்...';

  @override
  String get recycleBinEmptyButton => 'மறுசுழற்சி தொட்டியை காலி செய்';

  @override
  String get recycleBinRestoreLabel => 'மீட்டெடு';

  @override
  String get recycleBinRestoredBadge => 'மீட்கப்பட்டது';

  @override
  String get recycleBinDeletePermanentlyTitle => 'நிரந்தரமாக நீக்கவா?';

  @override
  String get recycleBinEmptyTitle => 'மறுசுழற்சி தொட்டியை காலி செய்யவா?';

  @override
  String get recycleBinEmptyMessage =>
      'அனைத்து உருப்படிகளையும் நிரந்தரமாக நீக்க விரும்புகிறீர்களா? இந்தச் செயலைத் திரும்பப் பெற முடியாது.';

  @override
  String get recycleBinNoItems =>
      'பொருத்தமான உருப்படிகள் எதுவும் கண்டறியப்படவில்லை.';

  @override
  String get customersTitle => 'வாடிக்கையாளர்கள்';

  @override
  String get customersSubtitle =>
      'வாடிக்கையாளர் தகவல்கள் மற்றும் விவரங்களை நிர்வகிக்கவும்';

  @override
  String get customersAddButton => 'வாடிக்கையாளரைச் சேர்';

  @override
  String get customersSearchHint => 'பெயர் மூலம் தேடு...';

  @override
  String get customersFilterAll => 'அனைத்து நிலைகள்';

  @override
  String get customersFilterActive => 'செயலில் உள்ளது';

  @override
  String get customersFilterOverdue => 'காலதாமதமாகிவிட்டது';

  @override
  String get customersFilterInactive => 'செயலற்றது';

  @override
  String get customersNoResults => 'வாடிக்கையாளர்கள் யாரும் காணப்படவில்லை';

  @override
  String get retry => 'மீண்டும் முயற்சி செய்';

  @override
  String get customersLoadFailedTitle => 'வாடிக்கையாளர்களை ஏற்ற முடியவில்லை';

  @override
  String get customersDeleteTitle => 'வாடிக்கையாளரை நீக்கு';

  @override
  String customersDeleteMessage(String name) {
    return '$name ஐ நீக்க விரும்புகிறீர்களா? அவர்கள் மறுசுழற்சி தொட்டிக்கு மாற்றப்பட்டு பின்னர் மீட்டெடுக்கப்படலாம்.';
  }

  @override
  String get customersDeletedTitle => 'வாடிக்கையாளர் நீக்கப்பட்டார்';

  @override
  String customersDeletedMessage(String name) {
    return '$name வெற்றிகரமாக அகற்றப்பட்டது';
  }

  @override
  String get customersDeleteFailedTitle => 'நீக்குதல் தோல்வியடைந்தது';

  @override
  String get customersUpdatedTitle => 'வாடிக்கையாளர் புதுப்பிக்கப்பட்டார்';

  @override
  String get customersAddedTitle => 'வாடிக்கையாளர் சேர்க்கப்பட்டார்';

  @override
  String customersUpdatedMessage(String name) {
    return '$name வெற்றிகரமாக புதுப்பிக்கப்பட்டது';
  }

  @override
  String customersAddedMessage(String name) {
    return '$name வெற்றிகரமாக சேர்க்கப்பட்டது';
  }

  @override
  String get customersSaveFailedTitle => 'ஏதோ தவறு நடந்துவிட்டது';

  @override
  String get customerViewClose => 'மூடு';

  @override
  String get customerFieldId => 'வாடிக்கையாளர் ஐடி';

  @override
  String get customerFieldMobile => 'மொபைல்';

  @override
  String get customerFieldAddress => 'முகவரி';

  @override
  String get customerFieldAadhaar => 'ஆதார்';

  @override
  String get customerFieldPan => 'பான்';

  @override
  String get customerFieldOccupation => 'தொழில்';

  @override
  String get customerFieldAgent => 'ஒதுக்கப்பட்ட முகவர்';

  @override
  String get customerFieldLoanStatus => 'கடன் நிலை';

  @override
  String get customerActionView => 'காண்க';

  @override
  String get customerActionEdit => 'திருத்து';

  @override
  String get customerActionDelete => 'நீக்கு';

  @override
  String get customerUnassigned => 'ஒதுக்கப்படாதது';

  @override
  String get customerFormEditTitle => 'வாடிக்கையாளரைத் திருத்து';

  @override
  String get customerFormAddTitle => 'வாடிக்கையாளரைச் சேர்';

  @override
  String get customerFormEditSubtitle =>
      'வாடிக்கையாளர் விவரங்களைப் புதுப்பிக்கவும்';

  @override
  String get customerFormAddSubtitle => 'கீழே உள்ள விவரங்களை நிரப்பவும்';

  @override
  String get customerSectionPersonal => 'தனிப்பட்ட விவரங்கள்';

  @override
  String get customerSectionAssignment => 'ஒப்படைப்பு';

  @override
  String get customerSectionPortalLogin => 'போர்டல் உள்நுழைவு (விரும்பினால்)';

  @override
  String get customerSectionPhoto => 'புகைப்படம்';

  @override
  String get customerLabelFullName => 'முழு பெயர் *';

  @override
  String get customerHintFullName => 'எ.கா. ரமேஷ் குமார்';

  @override
  String get customerLabelMobile => 'மொபைல் எண் *';

  @override
  String get customerHintMobile => '10 இலக்க மொபைல் எண்';

  @override
  String get customerLabelAddress => 'முகவரி *';

  @override
  String get customerHintAddress => 'முழு குடியிருப்பு முகவரி';

  @override
  String get customerLabelAadhaar => 'ஆதார் (விரும்பினால்)';

  @override
  String get customerHintAadhaar => '12 இலக்க ஆதார் எண்';

  @override
  String get customerLabelPan => 'பான் (விரும்பினால்)';

  @override
  String get customerHintPan => 'எ.கா. ABCDE1234F';

  @override
  String get customerLabelOccupation => 'தொழில் (விரும்பினால்)';

  @override
  String get customerHintOccupation => 'எ.கா. கடை உரிமையாளர்';

  @override
  String get customerLabelAssignedAgent => 'ஒதுக்கப்பட்ட முகவர்';

  @override
  String get customerMapLocationTitle => 'வரைபட இடம்';

  @override
  String get customerMapLocationSubtitle => 'முகவர் பாதைக்கு';

  @override
  String get customerPinFromAddress => 'முகவரியில் இருந்து குறிக்கவும்';

  @override
  String get customerUseMyGps => 'எனது GPS ஐப் பயன்படுத்து';

  @override
  String get customerMapHelpText =>
      'இந்த வாடிக்கையாளரை முகவரின் நேரடி பாதை வரைபடத்தில் காட்டுகிறது. \"முகவரியில் இருந்து குறிக்கவும்\" என்பது மேலே உள்ள முகவரியைத் தேடுகிறது; \"எனது GPS ஐப் பயன்படுத்து\" என்பது நீங்கள் நிற்கும் இடத்தைப் பிடிக்கிறது.';

  @override
  String get customerLatitudeLabel => 'அகலாங்கு';

  @override
  String get customerLongitudeLabel => 'நெடுங்கோடு';

  @override
  String get customerLatLngHint => '0.0000000';

  @override
  String get customerAddressRequiredTitle => 'முகவரி தேவை';

  @override
  String get customerAddressRequiredMessage =>
      'வரைபடத்தில் இருப்பிடத்தைக் கண்டறிய முதலில் முகவரியை உள்ளிடவும்';

  @override
  String get customerAddressNotFoundTitle =>
      'அந்த முகவரியைக் கண்டுபிடிக்க முடியவில்லை';

  @override
  String get customerLocationFailedTitle =>
      'உங்கள் இருப்பிடத்தைப் பெற முடியவில்லை';

  @override
  String get customerPhotoFailedTitle =>
      'புகைப்படம் பதிவேற்றுதல் தோல்வியடைந்தது';

  @override
  String get customerPortalLoginHelp =>
      'இந்த வாடிக்கையாளர் தங்கள் மொபைல் எண்ணுடன் உள்நுழைந்து அவர்களின் கடன்கள் மற்றும் கட்டணங்களைப் பார்க்க கடவுச்சொல்லை அமைக்கவும். மின்னஞ்சல் தேவையில்லை.';

  @override
  String get customerLabelEmail => 'மின்னஞ்சல் (விரும்பினால்)';

  @override
  String get customerHintEmail => 'customer@example.com';

  @override
  String get customerLabelPassword => 'கடவுச்சொல் (விரும்பினால்)';

  @override
  String get customerHintPassword => 'குறைந்தபட்சம் 6 எழுத்துக்கள்';

  @override
  String get customerLoginNote =>
      'மேலே உள்ள மொபைல் எண்ணை உள்நுழைவுக்கான பயனர் பெயராகப் பயன்படுத்தவும்.';

  @override
  String get customerUploadPhoto => 'புகைப்படத்தைப் பதிவேற்று';

  @override
  String get customerSaveChanges => 'மாற்றங்களைச் சேமி';

  @override
  String get customerFormValidationTitle => 'படிவத்தைச் சரிபார்க்கவும்';

  @override
  String get customerFormValidationMessage =>
      'சேமிக்கும் முன் முன்னிலைப்படுத்தப்பட்ட புலங்களைச் சரிசெய்யவும்';

  @override
  String get customerValidatorNameRequired => 'முழு பெயர் தேவை';

  @override
  String get customerValidatorNameMin =>
      'குறைந்தபட்சம் 3 எழுத்துக்களை உள்ளிடவும்';

  @override
  String get customerValidatorNameChars =>
      'எழுத்துக்களும் இடைவெளிகளும் மட்டுமே அனுமதிக்கப்படுகின்றன';

  @override
  String get customerValidatorMobileRequired => 'மொபைல் எண் கட்டாயம்';

  @override
  String get customerValidatorMobileInvalid =>
      'சரியான 10 இலக்க மொபைல் எண்ணை உள்ளிடவும்';

  @override
  String get customerValidatorAddressRequired => 'முகவரி கட்டாயம்';

  @override
  String get customerValidatorAddressMin =>
      'மேலும் முழுமையான முகவரியை உள்ளிடவும்';

  @override
  String get customerValidatorAadhaarInvalid =>
      'ஆதார் எண் சரியாக 12 இலக்கங்களைக் கொண்டிருக்க வேண்டும்';

  @override
  String get customerValidatorPanInvalid =>
      'சரியான PAN எண்ணை உள்ளிடவும் (உதாரணமாக: ABCDE1234F)';

  @override
  String get customerValidatorOccupationInvalid => 'சரியான தொழிலை உள்ளிடவும்';

  @override
  String get customerValidatorNumberInvalid => 'சரியான எண்ணை உள்ளிடவும்';

  @override
  String get customerValidatorLatRange =>
      '-90 மற்றும் 90 க்கு இடையில் இருக்க வேண்டும்';

  @override
  String get customerValidatorLngRange =>
      '-180 மற்றும் 180 க்கு இடையில் இருக்க வேண்டும்';

  @override
  String get customerValidatorEmailInvalid =>
      'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்';

  @override
  String get customerValidatorPasswordMin =>
      'கடவுச்சொல் குறைந்தபட்சம் 6 எழுத்துக்களைக் கொண்டிருக்க வேண்டும்';

  @override
  String get dashboardTitle => 'டாஷ்போர்டு';

  @override
  String dashboardNotLinkedYet(String label) {
    return '$label இன்னும் இணைக்கப்படவில்லை';
  }

  @override
  String get dashboardGreetingMorning => 'காலை வணக்கம்';

  @override
  String get dashboardGreetingAfternoon => 'பிற்பகல் வணக்கம்';

  @override
  String get dashboardGreetingEvening => 'மாலை வணக்கம்';

  @override
  String dashboardGreetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String dashboardLiveFigures(String amount, int count) {
    return 'தரவுத்தளத்தில் இருந்து நேரடி புள்ளிவிவரங்கள்: இன்று $amount வசூலிக்கப்பட்டுள்ளது மற்றும் $count செயலில் உள்ள கடன்கள்.';
  }

  @override
  String get dashboardNetBalanceSummary => 'நிகர இருப்புச் சுருக்கம்';

  @override
  String get dashboardNetBalanceSubtitle => 'நிகழ்நேர செயல்பாட்டு மூலதன நிலை';

  @override
  String get dashboardCashInHand => 'கை இருப்பு ரொக்கம்';

  @override
  String get dashboardLoanCollections => 'கடன் வசூல்';

  @override
  String get dashboardFundDeposits => 'நிதி வைப்புத்தொகைகள்';

  @override
  String get dashboardCustomCashIn => '+ தனிப்பயன் ரொக்கம் வரவு';

  @override
  String get dashboardOutstandingMoneyLent => 'நிலுவையில் உள்ள கடன் தொகை';

  @override
  String get dashboardLoansOutstanding => 'நிலுவையிலுள்ள கடன்கள்';

  @override
  String get dashboardCustomLent => '+ தனிப்பயன் கடன்';

  @override
  String get dashboardNetBalanceLabel => 'நிகர இருப்பு';

  @override
  String get dashboardTotalAssets => 'மொத்த சொத்துக்கள்';

  @override
  String dashboardNetBalanceFormula(String cash, String lent) {
    return 'கை இருப்பு ரொக்கம் ($cash) + கடன் தொகை ($lent)';
  }

  @override
  String get dashboardStatActiveLoans => 'செயலில் உள்ள கடன்கள்';

  @override
  String get dashboardStatNewCustomers => 'புதிய வாடிக்கையாளர்கள்';

  @override
  String get dashboardStatTodaysCollections => 'இன்றைய வசூல்';

  @override
  String get dashboardStatOverdueAccounts => 'நிலுவையிலுள்ள கணக்குகள்';

  @override
  String get dashboardStatPendingApprovals => 'நிலுவையிலுள்ள ஒப்புதல்கள்';

  @override
  String get dashboardStatTotalLoanAmount => 'மொத்த கடன் தொகை';

  @override
  String get dashboardStatInterestRevenue => 'வட்டி வருவாய்';

  @override
  String get dashboardStatMonthlyCollection => 'மாத வசூல்';

  @override
  String get dashboardCollectionTrend => 'வசூல் போக்கு';

  @override
  String get dashboardCollectionTrendSubtitle =>
      'அறிக்கைப் பட்டியலிலிருந்து கடந்த மாதங்கள்';

  @override
  String get dashboardLoanStatus => 'கடன் நிலை';

  @override
  String get dashboardLoanStatusSubtitle => 'நேரடி தரவுத்தள சுருக்கம்';

  @override
  String get dashboardDonutTotal => 'மொத்தம்';

  @override
  String get dashboardStatusActive => 'செயலில் உள்ளது';

  @override
  String get dashboardStatusOverdue => 'நிலுவையில் உள்ளது';

  @override
  String get dashboardStatusClosedOther => 'முடிந்தது/மற்றவை';

  @override
  String get dashboardAgentPerformance => 'முகவர் செயல்திறன்';

  @override
  String get dashboardAgentPerformanceSubtitle =>
      'அறிக்கையிலிருந்து சிறந்த கள முகவர்கள்';

  @override
  String get dashboardMonthlyProgress => 'மாத வசூல் முன்னேற்றம்';

  @override
  String dashboardMonthlyProgressSubtitle(String collected, String target) {
    return '₹$target இலக்கில் ₹$collected வசூலிக்கப்பட்டது';
  }

  @override
  String get dashboardQuickActions => 'விரைவுச் செயல்கள்';

  @override
  String get dashboardQuickAddCustomer => 'வாடிக்கையாளரைச் சேர்க்கவும்';

  @override
  String get dashboardQuickCreateLoan => 'கடன் உருவாக்கவும்';

  @override
  String get dashboardQuickChitGroup => 'சீட்டுக் குழு';

  @override
  String get dashboardQuickAddAgent => 'முகவரைச் சேர்க்கவும்';

  @override
  String get dashboardQuickReports => 'அறிக்கைகள்';

  @override
  String get dashboardRecentCollections => 'சமீபத்திய வசூல்';

  @override
  String get dashboardRecentCollectionsSubtitle => 'சமீபத்தில் பெறப்பட்ட பணம்';

  @override
  String get dashboardNoCollectionsToday =>
      'இன்று வசூல் எதுவும் கண்டறியப்படவில்லை.';

  @override
  String get dashboardRecentLoans => 'சமீபத்திய கடன்கள்';

  @override
  String get dashboardRecentLoansSubtitle => 'புதிதாக வழங்கப்பட்ட கடன்கள்';

  @override
  String get dashboardNoLoansToday =>
      'இன்று புதிய கடன்கள் எதுவும் கண்டறியப்படவில்லை.';

  @override
  String get dashboardViewAll => 'அனைத்தையும் காண்க';

  @override
  String get loansTitle => 'கடன்கள்';

  @override
  String get loansSubtitle =>
      'வாடிக்கையாளர் கடன்கள் மற்றும் திருப்பிச் செலுத்தும் அட்டவணைகளை நிர்வகிக்கவும்';

  @override
  String get loansCreateButton => 'கடனை உருவாக்கு';

  @override
  String get loansSearchHint => 'வாடிக்கையாளர் அல்லது கடன் எண்ணால் தேடவும்...';

  @override
  String get loansFilterAll => 'அனைத்தும்';

  @override
  String get loansStatusActive => 'செயலில்';

  @override
  String get loansStatusOverdue => 'நிலுவையில்';

  @override
  String get loansStatusClosed => 'மூடப்பட்டது';

  @override
  String get loansStatusPending => 'நிலுவை';

  @override
  String get loansScheduleStatusPaid => 'செலுத்தப்பட்டது';

  @override
  String get loansScheduleStatusDueToday => 'இன்று செலுத்த வேண்டியது';

  @override
  String get loansTypeMonthlyEmi => 'மாதாந்திர EMI';

  @override
  String get loansTypeMonthlyInterest => 'மாதாந்திர வட்டி';

  @override
  String get loansTypeWeekly => 'வாராந்திரம்';

  @override
  String get loansTypeDaily => 'தினசரி';

  @override
  String get loansScheduleEmptyMessage =>
      'திருப்பிச் செலுத்தும் அட்டவணை இல்லை.';

  @override
  String get loansScheduleColIndex => 'எண்';

  @override
  String get loansScheduleColDueDate => 'செலுத்த வேண்டிய தேதி';

  @override
  String get loansScheduleColEmi => 'EMI';

  @override
  String get loansScheduleColPaid => 'செலுத்தியது';

  @override
  String get loansScheduleColBalance => 'மீதம்';

  @override
  String get loansScheduleColStatus => 'நிலை';

  @override
  String loansCouldNotLoad(String error) {
    return 'கடன்களை ஏற்ற முடியவில்லை: $error';
  }

  @override
  String get loansLoanCreatedTitle => 'கடன் உருவாக்கப்பட்டது';

  @override
  String get loansLoanUpdatedTitle => 'கடன் புதுப்பிக்கப்பட்டது';

  @override
  String get loansCloseLoanTitle => 'கடனை மூடு';

  @override
  String loansCloseLoanMessage(String loanNumber) {
    return 'கடன் $loanNumber-ஐ மூட விரும்புகிறீர்களா?';
  }

  @override
  String get loansCloseLoanConfirm => 'மூடு';

  @override
  String get loansLoanClosedTitle => 'கடன் மூடப்பட்டது';

  @override
  String loansLoanClosedMessage(String loanNumber) {
    return 'கடன் $loanNumber வெற்றிகரமாக மூடப்பட்டது.';
  }

  @override
  String get loansCloseFailedTitle => 'மூடுதல் தோல்வியடைந்தது';

  @override
  String get loansCloseBlockedTitle => 'கடனை மூட முடியாது';

  @override
  String loansCloseBlockedMessage(String amount) {
    return 'இந்தக் கடனில் இன்னும் $amount நிலுவையில் உள்ளது. மூடுவதற்கு முன் முழு நிலுவைத் தொகையையும் வசூலிக்கவும்.';
  }

  @override
  String get loansDeleteLoanTitle => 'கடனை நீக்கு';

  @override
  String loansDeleteLoanMessage(String loanNumber) {
    return 'கடன் $loanNumber-ஐ நீக்க விரும்புகிறீர்களா? இது மறுசுழற்சி தொட்டிக்கு நகர்த்தப்படும்.';
  }

  @override
  String get loansDeleteLoanConfirm => 'நீக்கு';

  @override
  String get loansLoanDeletedTitle => 'கடன் நீக்கப்பட்டது';

  @override
  String loansLoanDeletedMessage(String loanNumber) {
    return 'கடன் $loanNumber மறுசுழற்சி தொட்டிக்கு நகர்த்தப்பட்டது.';
  }

  @override
  String get loansDeleteFailedTitle => 'நீக்குதல் தோல்வியடைந்தது';

  @override
  String get loansNoLoansFound => 'கடன்கள் எதுவும் இல்லை';

  @override
  String get loansColHpNo => 'HP எண்';

  @override
  String get loansColCustomer => 'வாடிக்கையாளர்';

  @override
  String get loansColType => 'வகை';

  @override
  String get loansColAmount => 'தொகை';

  @override
  String get loansColEmi => 'EMI';

  @override
  String get loansColOutstanding => 'நிலுவை';

  @override
  String get loansColAgent => 'முகவர்';

  @override
  String get loansColStatus => 'நிலை';

  @override
  String get loansColStart => 'தொடக்க தேதி';

  @override
  String get loansColActions => 'செயல்கள்';

  @override
  String get loansActionView => 'காண்க';

  @override
  String get loansActionEdit => 'திருத்து';

  @override
  String get loansActionClose => 'மூடு';

  @override
  String get loansActionDelete => 'நீக்கு';

  @override
  String loansDurationWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count வாரங்கள்',
    );
    return '$_temp0';
  }

  @override
  String loansDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count நாட்கள்',
    );
    return '$_temp0';
  }

  @override
  String loansDurationMonthsInterestOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மாதங்கள் (வட்டி மட்டும்)',
    );
    return '$_temp0';
  }

  @override
  String loansDurationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மாதங்கள்',
    );
    return '$_temp0';
  }

  @override
  String loansDetailTitle(String loanNumber) {
    return 'கடன் $loanNumber';
  }

  @override
  String get loansFieldCustomer => 'வாடிக்கையாளர்';

  @override
  String get loansFieldLoanType => 'கடன் வகை';

  @override
  String get loansFieldLoanAmount => 'கடன் தொகை';

  @override
  String get loansFieldMonthlyInterest => 'மாதாந்திர வட்டி';

  @override
  String get loansFieldEmi => 'மாதத் தவணை';

  @override
  String get loansFieldOutstanding => 'நிலுவையில் உள்ளது';

  @override
  String get loansFieldPenalty => 'அபராதம்';

  @override
  String get loansFieldTotalDuePenalty =>
      'மொத்த செலுத்த வேண்டிய தொகை (அபராதத்துடன்)';

  @override
  String get loansFieldInterest => 'வட்டி விகிதம்';

  @override
  String get loansFieldDuration => 'கால அளவு';

  @override
  String get loansFieldStartDate => 'தொடங்கும் தேதி';

  @override
  String get loansFieldAgent => 'முகவர்';

  @override
  String get loansHideSchedule => 'அட்டவணையை மறை';

  @override
  String get loansShowSchedule => 'அட்டவணையைக் காட்டு';

  @override
  String get loansRepaymentSchedule => 'திருப்பிச் செலுத்தும் அட்டவணை';

  @override
  String get loansRefreshScheduleTooltip => 'அட்டவணையைப் புதுப்பி';

  @override
  String get loansInterestOnlyScheduleNote =>
      'இது வட்டி மட்டும் செலுத்த வேண்டிய கடன். அசல் தொகை திருப்பிச் செலுத்துதல் நெகிழ்வானது மற்றும் கீழேயுள்ள அட்டவணையில் பிரதிபலிக்கவில்லை.';

  @override
  String get loansCustomerRequiredTitle => 'வாடிக்கையாளர் தேவை';

  @override
  String get loansCustomerRequiredMessage =>
      'இந்தக் கடனைச் சேமிக்கும் முன் ஒரு வாடிக்கையாளரைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get loansSaveFailedTitle => 'சேமிப்பு தோல்வியடைந்தது';

  @override
  String get loansEditTitle => 'கடனைத் திருத்து';

  @override
  String get loansCreateTitle => 'கடனை உருவாக்கு';

  @override
  String get loansHpNumberLabel => 'HP எண்';

  @override
  String get loansHpNumberLoading => 'உருவாக்கப்படுகிறது…';

  @override
  String get loansHpNumberAuto => 'தானாக உருவாக்கப்பட்டது';

  @override
  String get loansProcessingFeeLabel => 'செயலாக்கக் கட்டணம்';

  @override
  String get loansProcessingFeeHint => 'செயலாக்கக் கட்டணத்தை உள்ளிடவும்';

  @override
  String get loansNotesLabel => 'குறிப்புகள்';

  @override
  String get loansNotesHint => 'கூடுதல் குறிப்புகளைச் சேர்க்கவும்';

  @override
  String get loansSave => 'சேமி';

  @override
  String get loansApprove => 'அங்கீகரி';

  @override
  String get loansCustomerRequiredLabel => 'வாடிக்கையாளர் *';

  @override
  String get loansCustomerHint => 'வாடிக்கையாளரைத் தேடு';

  @override
  String get loansAgentLabel => 'முகவர்';

  @override
  String get loansAgentHint => 'முகவரைத் தேடு';

  @override
  String get loansCollectionTypeLabel => 'வசூல் வகை';

  @override
  String get loansLoanAmountLabel => 'கடன் தொகை';

  @override
  String get loansLoanAmountHint => 'கடன் தொகையை உள்ளிடவும்';

  @override
  String get loansInterestRateMonthlyLabel => 'மாதாந்திர வட்டி விகிதம் (%)';

  @override
  String get loansInterestRateHint25 => 'உதாரணமாக 2.5';

  @override
  String get loansDurationMonthsLabel => 'கால அளவு (மாதங்கள்)';

  @override
  String get loansDurationHint10 => 'உதாரணமாக 10';

  @override
  String get loansMonthlyInterestRateLabel => 'மாதாந்திர வட்டி விகிதம் (%)';

  @override
  String get loansLoanTenureLabel => 'கடன் காலம் (மாதங்கள்)';

  @override
  String get loansInterestRateLabel => 'வட்டி விகிதம் (%)';

  @override
  String get loansDurationFixedLabel => 'கால அளவு';

  @override
  String get loansDurationWeeksFixed => '10 வாரங்கள் (நிலையானது)';

  @override
  String get loansCollectionPlanLabel => 'வசூல் திட்டம்';

  @override
  String get loansPlan60Days => '60 நாட்கள்';

  @override
  String get loansPlan100Days => '100 நாட்கள்';

  @override
  String get loansInterestOnlyBoxTitle => 'வட்டி மட்டும் செலுத்த வேண்டிய கடன்';

  @override
  String get loansInterestOnlyBoxBody =>
      'கடன் வாங்கியவர் மாதாந்திர வட்டியை மட்டும் செலுத்துவார். அசல் தொகையை எப்போது வேண்டுமானாலும் திருப்பிச் செலுத்தலாம் மற்றும் அது நிலையான அட்டவணையின் ஒரு பகுதியாக இருக்காது.';

  @override
  String get loansWeeklyPenaltyTitle => 'வாராந்திர அபராதம்';

  @override
  String get loansDailyPenaltyTitle => 'தினசரி அபராதம்';

  @override
  String get loansWeeklyPenaltyHelper =>
      'தவறவிட்ட வாராந்திர கொடுப்பனவுகளுக்கு ஒரு நிலையான அபராதத்தைப் பயன்படுத்துங்கள்.';

  @override
  String get loansDailyPenaltyHelper =>
      'காலக்கெடு கடந்த நிலுவைகளுக்கு தினசரி அபராத விகிதத்தைப் பயன்படுத்துங்கள்.';

  @override
  String get loansDailyPenaltyRateLabel => 'அபராத விகிதம் / நாள்';

  @override
  String get loansDailyPenaltyRateHint => 'உதாரணமாக 50';

  @override
  String get loansDailyPenaltyExample =>
      'காலக்கெடு கடந்த எந்தவொரு நிலுவைக்கும் தினமும் பொருந்தும்.';

  @override
  String get loansWeeklyPenaltyAmountLabel => 'அபராதத் தொகை / வாரம்';

  @override
  String get loansWeeklyPenaltyAmountHint => 'உதாரணமாக 100';

  @override
  String get loansWeeklyPenaltyAutoNote =>
      'ஒரு கட்டணம் தவறவிடப்படும் ஒவ்வொரு வாரமும் தானாகவே பொருந்தும்.';

  @override
  String get loansSummaryMonthlyEmi => 'மாதாந்திர மாதத் தவணை';

  @override
  String loansSummaryPerMonth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மாதங்களுக்கு',
    );
    return '$_temp0';
  }

  @override
  String get loansSummaryTotalInterest => 'மொத்த வட்டி';

  @override
  String loansSummaryPerMonthAmount(String amount) {
    return '$amount ஒரு மாதத்திற்கு';
  }

  @override
  String get loansSummaryTotalRepayment => 'மொத்த திருப்பிச் செலுத்தும் தொகை';

  @override
  String get loansSummaryPrincipalPlusInterest => 'அசல் + வட்டி';

  @override
  String get loansSummaryMonthlyInterestDue =>
      'மாதாந்திர செலுத்த வேண்டிய வட்டி';

  @override
  String loansSummaryRateOfPrincipal(String rate, String principal) {
    return '$principalல் $rate%';
  }

  @override
  String get loansSummaryPrincipalRepayment => 'அசல் திருப்பிச் செலுத்துதல்';

  @override
  String get loansSummaryFlexibleInstallments => 'நெகிழ்வானது';

  @override
  String get loansSummaryRepayAnytime =>
      'அசலை எந்நேரமும் திருப்பிச் செலுத்தலாம்';

  @override
  String get loansSummaryPrincipalDisbursed => 'அசல் வழங்கப்பட்டது';

  @override
  String loansSummaryTenureMonths(int count) {
    return '$count மாதங்களுக்கு மேல்';
  }

  @override
  String get loansSummaryWeeklyInstallment => 'வாராந்திர தவணை';

  @override
  String loansSummaryWeeksEqual(String principal) {
    return '$principal மொத்தத்துடன் 10 வாரங்கள்';
  }

  @override
  String get loansSummaryInterestDeducted => 'வட்டி கழிக்கப்பட்டது';

  @override
  String get loansSummaryDeductedUpfront => 'முன்கூட்டியே கழிக்கப்பட்டது';

  @override
  String get loansSummaryAmountDisbursed => 'வழங்கப்பட்ட தொகை';

  @override
  String get loansSummaryPrincipalMinusInterest => 'அசல் − வட்டி';

  @override
  String get loansSummaryDailyInstallment => 'தினசரி தவணை';

  @override
  String loansSummaryDaysEqual(int days, String total) {
    return '$total மொத்தத்துடன் $days நாட்கள்';
  }

  @override
  String get loansSummaryInterestAdded => 'வட்டி சேர்க்கப்பட்டது';

  @override
  String get loansSummaryAddedToRepayment =>
      'மொத்த திருப்பிச் செலுத்துதலுடன் சேர்க்கப்பட்டது';

  @override
  String get loansSummaryAmountDisbursedToBorrower =>
      'கடன் வாங்கியவருக்கு வழங்கப்பட்ட தொகை';

  @override
  String get loansSummaryFullLoanAmount => 'முழு கடன் தொகை';

  @override
  String get loansScheduleSectionTitle =>
      'திருப்பிச் செலுத்தும் அட்டவணை முன்னோட்டம்';

  @override
  String get loansStartDateLabel => 'தொடங்கும் தேதி';

  @override
  String get loansStartDateHint => 'நாள்/மாதம்/ஆண்டு';

  @override
  String get repaymentTitle => 'திருப்பிச் செலுத்தும் அட்டவணை';

  @override
  String get repaymentSubtitle =>
      'தவணை வாரியான EMI வசூலிப்புகள் மற்றும் நிலுவைத் தொகைகளைக் கண்காணிக்கவும்';

  @override
  String get repaymentCouldNotLoadLoans => 'கடன்களை ஏற்ற முடியவில்லை';

  @override
  String get repaymentLoanLoadFailedTitle => 'கடன் ஏற்றுதல் தோல்வியடைந்தது';

  @override
  String get repaymentCouldNotLoadSchedule =>
      'திருப்பிச் செலுத்தும் அட்டவணையை ஏற்ற முடியவில்லை';

  @override
  String get repaymentLoadFailedTitle => 'ஏற்றுதல் தோல்வியடைந்தது';

  @override
  String get repaymentSelectLoanLabel => 'கடன் தேர்வு செய்யவும்';

  @override
  String get repaymentSelectLoanHint => 'கடன் தேர்வு செய்யவும்';

  @override
  String get repaymentLoanSwitchedTitle => 'கடன் மாற்றப்பட்டது';

  @override
  String get repaymentInstallmentBreakdown => 'தவணை விவரங்கள்';

  @override
  String get repaymentNoInstallmentsFound =>
      'இந்தக் கடனுக்குத் தவணைகள் எதுவும் இல்லை';

  @override
  String get repaymentStatLoanNumber => 'கடன் எண்';

  @override
  String get repaymentStatCustomer => 'வாடிக்கையாளர்';

  @override
  String get repaymentStatLoanAmount => 'கடன் தொகை';

  @override
  String get repaymentStatEmi => 'EMI';

  @override
  String get repaymentStatTotalRepayment => 'மொத்த திருப்பிச் செலுத்துதல்';

  @override
  String get repaymentStatOutstanding => 'நிலுவையில் உள்ளது';

  @override
  String get repaymentStatPenalty => 'அபராதம்';

  @override
  String get repaymentStatTotalDuePenalty => 'மொத்தத் தொகை + அபராதம்';

  @override
  String get repaymentStatTotalInstallments => 'மொத்த தவணைகள்';

  @override
  String get repaymentStatPaid => 'செலுத்தப்பட்டது';

  @override
  String get repaymentStatPending => 'நிலுவையில்';

  @override
  String get repaymentStatOverdue => 'காலாவதியானது';

  @override
  String get repaymentStatNextDue => 'அடுத்த கட்டணம்';

  @override
  String get repaymentColInstNo => 'தவணை எண்';

  @override
  String get repaymentColDueDate => 'கடைசி தேதி';

  @override
  String get repaymentColEmiAmount => 'EMI தொகை';

  @override
  String get repaymentColPaid => 'செலுத்தப்பட்டது';

  @override
  String get repaymentColBalance => 'மீதி';

  @override
  String get repaymentColPenalty => 'அபராதம்';

  @override
  String get repaymentColStatus => 'நிலை';

  @override
  String get repaymentNoLoanSelected => 'கடன் எதுவும் தேர்ந்தெடுக்கப்படவில்லை';

  @override
  String repaymentPenaltyBannerTitle(String type, String duration) {
    return '$type நிதி ($duration)';
  }

  @override
  String get repaymentPenaltyBannerWeeklyBody =>
      'தவறவிடப்படும் ஒவ்வொரு வாராந்திர தவணைக்கும், ₹10,000 அசல் தொகைக்கு ₹100 என்ற விகிதத்தில் அபராதம் தானாகவே விதிக்கப்படும்.';

  @override
  String repaymentPenaltyBannerRateBody(String rate) {
    return 'கட்டணம் தாமதமாகும் ஒவ்வொரு நாளுக்கும் நாளொன்றுக்கு $rate அபராதம் விதிக்கப்படும்.';
  }

  @override
  String repaymentAccruedPenaltyLabel(String amount) {
    return 'சேர்ந்த அபராதம்: $amount';
  }

  @override
  String repaymentDurationWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count வாரங்கள்',
      one: '1 வாரம்',
    );
    return '$_temp0';
  }

  @override
  String repaymentDurationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மாதங்கள்',
      one: '1 மாதம்',
    );
    return '$_temp0';
  }

  @override
  String repaymentDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count நாட்கள்',
      one: '1 நாள்',
    );
    return '$_temp0';
  }

  @override
  String get repaymentRecordCollectionButton => 'வசூலைப் பதிவு செய்யவும்';

  @override
  String get repaymentRecordCollectionSheetTitle => 'வசூலைப் பதிவு செய்யவும்';

  @override
  String repaymentRecordCollectionSubtitle(String loanNumber, String customer) {
    return '$loanNumber — $customer';
  }

  @override
  String get repaymentRecordCollectionInstallmentLabel => 'தவணை';

  @override
  String get repaymentRecordCollectionGeneralPayment => 'பொது கட்டணம்';

  @override
  String get repaymentRecordCollectionAmountLabel => 'தொகை';

  @override
  String get repaymentRecordCollectionMethodLabel => 'பணம் செலுத்தும் முறை';

  @override
  String get repaymentRecordCollectionDateLabel => 'பணம் செலுத்திய தேதி';

  @override
  String get repaymentRecordCollectionNotesLabel => 'குறிப்புகள் (விருப்பம்)';

  @override
  String get repaymentRecordCollectionNotesHint =>
      'இந்தப் பணம் செலுத்துதல் குறித்து ஒரு குறிப்பைச் சேர்க்கவும்';

  @override
  String get repaymentRecordCollectionSubmit => 'வசூலைச் சேமிக்கவும்';

  @override
  String get repaymentRecordCollectionCancel => 'ரத்துசெய்';

  @override
  String get repaymentRecordCollectionAllPaidTitle =>
      'அனைத்தும் செலுத்தப்பட்டது';

  @override
  String get repaymentRecordCollectionAllPaidMessage =>
      'இந்தக் கடனின் அனைத்து தவணைகளும் ஏற்கனவே செலுத்தப்பட்டுவிட்டன.';

  @override
  String get repaymentRecordCollectionSuccessTitle =>
      'வசூல் பதிவு செய்யப்பட்டது';

  @override
  String get repaymentRecordCollectionFailedTitle =>
      'வசூலைப் பதிவு செய்ய முடியவில்லை';

  @override
  String get repaymentRecordCollectionSelectLoanFirst =>
      'முதலில் ஒரு கடனைத் தேர்ந்தெடுக்கவும்';

  @override
  String get repaymentRecordCollectionAmountRequired =>
      'சரியான தொகையை உள்ளிடவும்';

  @override
  String get collectionsLoadFailedTitle => 'வசூலிப்புகளை ஏற்ற முடியவில்லை';

  @override
  String get collectionsTitle => 'வசூலிப்புகள்';

  @override
  String get collectionsSubtitle =>
      'அனைத்து கடன்களிலுமான தினசரி வசூலிப்புகளைப் பதிவுசெய்து கண்காணிக்கவும்';

  @override
  String get collectionsAddButton => 'வசூலிப்பைச் சேர்';

  @override
  String get collectionsStatTodayTotal => 'இன்றைய மொத்தத் தொகை';

  @override
  String get collectionsStatThisWeek => 'இந்த வாரம்';

  @override
  String get collectionsStatThisMonth => 'இந்த மாதம்';

  @override
  String get collectionsStatTotalRecords => 'மொத்தப் பதிவுகள்';

  @override
  String get collectionsSearchHint =>
      'வாடிக்கையாளர், கடன் அல்லது ரசீது எண்ணைத் தேடுங்கள்...';

  @override
  String get collectionsPeriodToday => 'இன்று';

  @override
  String get collectionsPeriodThisWeek => 'இந்த வாரம்';

  @override
  String get collectionsPeriodThisMonth => 'இந்த மாதம்';

  @override
  String get collectionsColCustomer => 'வாடிக்கையாளர்';

  @override
  String get collectionsColLoanNumber => 'கடன் எண்';

  @override
  String get collectionsColAmount => 'தொகை';

  @override
  String get collectionsColMethod => 'முறை';

  @override
  String get collectionsColDate => 'தேதி';

  @override
  String get collectionsColAgent => 'முகவர்';

  @override
  String get collectionsColActions => 'செயல்கள்';

  @override
  String get collectionsActionEdit => 'திருத்து';

  @override
  String get collectionsActionDelete => 'நீக்கு';

  @override
  String get collectionsNoneFound => 'வசூலிப்புகள் எதுவும் இல்லை';

  @override
  String get collectionsShowLess => 'குறைவாகக் காட்டு';

  @override
  String collectionsShowMore(int count) {
    return 'மேலும் காட்டு ($count அதிகம்)';
  }

  @override
  String get collectionsDeleteTitle => 'வசூலிப்பை நீக்கு';

  @override
  String collectionsDeleteMessage(String customer, String receipt) {
    return '$customer ($receipt) க்கான வசூலிப்புப் பதிவை நீக்கவா? இது மறுசுழற்சி தொட்டிக்கு நகர்த்தப்படும், பின்னர் மீட்டெடுக்கலாம்.';
  }

  @override
  String get collectionsDeleteFailedTitle => 'நீக்குதல் தோல்வியடைந்தது';

  @override
  String get collectionsUpdateFailedTitle => 'புதுப்பித்தல் தோல்வியடைந்தது';

  @override
  String get collectionsRecordIdNotFound =>
      'பதிவு ஐடி கண்டுபிடிக்க முடியவில்லை';

  @override
  String get collectionsDeletedTitle => 'வசூலிப்பு நீக்கப்பட்டது';

  @override
  String get collectionsDeleteApiFailedTitle => 'வசூலிப்பை நீக்க முடியவில்லை';

  @override
  String get collectionsRecordedTitle => 'வசூலிப்புப் பதிவுசெய்யப்பட்டது';

  @override
  String get collectionsSaveFailedTitle => 'வசூலிப்பைச் சேமிக்க முடியவில்லை';

  @override
  String get collectionsUpdatedTitle => 'வசூலிப்பு புதுப்பிக்கப்பட்டது';

  @override
  String get collectionsUpdateApiFailedTitle =>
      'வசூலிப்பைப் புதுப்பிக்க முடியவில்லை';

  @override
  String get collectionsMethodCash => 'பணம்';

  @override
  String get collectionsMethodUpi => 'UPI';

  @override
  String get collectionsMethodBank => 'வங்கிப் பரிமாற்றம்';

  @override
  String get collectionsMethodCheque => 'காசோலை';

  @override
  String get collectionsMethodCard => 'அட்டை';

  @override
  String get collectionsSelectCustomerTitle =>
      'ஒரு வாடிக்கையாளரைத் தேர்வு செய்யவும்';

  @override
  String get collectionsSelectCustomerMessage =>
      'சேமிப்பதற்கு முன் ஒரு வாடிக்கையாளரைத் தேர்வு செய்யவும்.';

  @override
  String get collectionsEditTitle => 'வசூலிப்பைத் திருத்து';

  @override
  String get collectionsCustomerRequiredLabel => 'வாடிக்கையாளர் *';

  @override
  String get collectionsSelectCustomerHint =>
      'வாடிக்கையாளரைத் தேர்வு செய்யவும்';

  @override
  String get collectionsLoanNumberLabel => 'கடன் எண்';

  @override
  String get collectionsSelectCustomerFirstHint =>
      'முதலில் வாடிக்கையாளரைத் தேர்வு செய்யவும்';

  @override
  String get collectionsSelectLoanHint => 'கடனைத் தேர்வு செய்யவும்';

  @override
  String get collectionsOutstandingAbbrev => 'நிலுவை';

  @override
  String get collectionsSelectLoanPrompt =>
      'கடன் விவரங்களைப் பார்க்க ஒரு கடனைத் தேர்வு செய்யவும்';

  @override
  String collectionsLoansLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count தேர்ந்தெடுக்கப்பட்ட வாடிக்கையாளருடன் இணைக்கப்பட்ட கடன்கள்',
    );
    return '$_temp0';
  }

  @override
  String get collectionsAmountReceivedLabel => 'பெறப்பட்ட தொகை *';

  @override
  String get collectionsPaymentMethodLabel => 'பணம் செலுத்தும் முறை *';

  @override
  String get collectionsCollectionDateLabel => 'வசூல் தேதி *';

  @override
  String get collectionsSelectAgentHint => 'முகவரைத் தேர்ந்தெடுக்கவும்';

  @override
  String get collectionsNotesLabel => 'குறிப்புகள்';

  @override
  String get collectionsNotesHint =>
      'இந்த வசூல் குறித்த ஏதேனும் குறிப்புகள்...';

  @override
  String get collectionsPaymentScreenshotLabel => 'பணம் செலுத்திய ஸ்கிரீன்ஷாட்';

  @override
  String get collectionsCustomerSignatureLabel => 'வாடிக்கையாளர் கையொப்பம்';

  @override
  String get collectionsCancelButton => 'ரத்துசெய்';

  @override
  String get collectionsReceiptButton => 'ரசீது';

  @override
  String get collectionsUpdateButton => 'புதுப்பிக்கவும்';

  @override
  String get collectionsSaveButton => 'சேமி';

  @override
  String get collectionsGeneratingReceiptTitle => 'ரசீது உருவாக்கப்படுகிறது...';

  @override
  String get collectionsUploadSignatureTitle =>
      'வாடிக்கையாளர் கையொப்பத்தைச் சேர்க்கவும்';

  @override
  String get collectionsUploadScreenshotTitle =>
      'பணம் செலுத்திய ஸ்கிரீன்ஷாட்டைப் பதிவேற்றவும்';

  @override
  String get collectionsUploadPlaceholder => 'ஆவணத்தைப் பதிவேற்றவும்...';

  @override
  String collectionsSummaryAgent(String name) {
    return 'முகவர்: $name';
  }

  @override
  String collectionsSummaryPrincipal(String amount) {
    return 'அசல்: $amount';
  }

  @override
  String collectionsSummaryInstallment(String amount) {
    return 'தவணை: $amount';
  }

  @override
  String collectionsSummaryOutstanding(String amount) {
    return 'நிலுவையில் உள்ளவை: $amount';
  }

  @override
  String collectionsSummaryOverdueDue(String amount) {
    return 'காலக்கெடு கடந்த நிலுவைத் தொகை: $amount';
  }

  @override
  String collectionsSummaryPenalty(String amount) {
    return 'அபராதம்: $amount';
  }

  @override
  String collectionsSummaryTotalDue(String amount) {
    return 'மொத்த நிலுவைத் தொகை: $amount';
  }

  @override
  String get collectionsPresetOneEmi => '1 EMI';

  @override
  String get collectionsPresetFillInterest => 'வட்டியை நிரப்பவும்';

  @override
  String get collectionsPresetPayDue => 'நிலுவைத் தொகையைச் செலுத்தவும்';

  @override
  String get collectionsPresetPrincipalPartPayment =>
      'அசல் பகுதியளவு செலுத்துதல்';

  @override
  String get collectionsPresetFullBalance => 'முழு இருப்பு';

  @override
  String get collectionsPurposeMonthlyInterest => 'மாதாந்திர வட்டி செலுத்துதல்';

  @override
  String collectionsPaymentSummaryLine(String payment, String remaining) {
    return 'செலுத்துதல்: $payment • மீதமுள்ள இருப்பு: $remaining';
  }

  @override
  String get handoverLoadFailedTitle => 'கைமாற்றுத் தரவைப் பெறத் தவறிவிட்டது';

  @override
  String get handoverUpdatedTitle => 'கைமாற்று புதுப்பிக்கப்பட்டது';

  @override
  String get handoverRecordedTitle => 'கைமாற்றுப் பதிவு செய்யப்பட்டது';

  @override
  String get handoverFailedTitle => 'கைமாற்று தோல்வியடைந்தது';

  @override
  String get handoverMarkedPendingTitle => 'நிலுவையில் எனக் குறிக்கப்பட்டது';

  @override
  String get handoverMarkedVerifiedTitle =>
      'சரிபார்க்கப்பட்டது எனக் குறிக்கப்பட்டது';

  @override
  String get handoverUpdateFailedTitle => 'கைமாற்றைப் புதுப்பிக்க முடியவில்லை';

  @override
  String get handoverDeletedTitle => 'கைமாற்று நீக்கப்பட்டது';

  @override
  String get handoverDeleteFailedTitle => 'கைமாற்றை நீக்க முடியவில்லை';

  @override
  String get handoverTitle => 'பணக் கைமாற்று';

  @override
  String get handoverSubtitle =>
      'முகவர்கள் வசூலித்த பணம் மற்றும் UPI தொகையை அலுவலகத்தில் செலுத்துகிறார்கள் — நிலுவையில் உள்ளவை அடுத்ததற்கு எடுத்துச் செல்லப்படும்';

  @override
  String get handoverRecordButton => 'கைமாற்றைப் பதிவுசெய்';

  @override
  String get handoverStatTotalCollected => 'மொத்தமாக வசூலிக்கப்பட்டது';

  @override
  String get handoverStatTodayZero => 'இன்று: ₹0';

  @override
  String get handoverStatHandedOver => 'கைமாற்றப்பட்டது';

  @override
  String get handoverStatPending => 'நிலுவையில் உள்ளது';

  @override
  String get handoverStatAgentsWithPending => 'நிலுவையில் உள்ள முகவர்கள்';

  @override
  String get handoverSettlementPositionTitle => 'முகவர் தீர்வு நிலை';

  @override
  String get handoverSettlementPositionSubtitle =>
      'நிலுவையில் உள்ளது = வசூலிக்கப்பட்டது − கைமாற்றப்பட்டது (தொடர்ந்து இயங்கும்)';

  @override
  String get handoverHistoryTitle => 'கைமாற்று வரலாறு';

  @override
  String get handoverHistoryEmpty =>
      'இதுவரை கைமாற்றுகள் எதுவும் பதிவு செய்யப்படவில்லை.';

  @override
  String get handoverColAgent => 'முகவர்';

  @override
  String get handoverColCollected => 'வசூலிக்கப்பட்டது';

  @override
  String get handoverColHandedOver => 'கைமாற்றப்பட்டது';

  @override
  String get handoverColPending => 'நிலுவையில் உள்ளது';

  @override
  String get handoverDeleteConfirmTitle => 'கைமாற்றை நீக்கவா?';

  @override
  String handoverDeleteConfirmMessage(String agentName, String amount) {
    return '$agentName இன் $amount கைமாற்றுப் பதிவு மறுசுழற்சி தொட்டிக்கு நகர்த்தப்படும், பின்னர் மீட்டெடுக்கப்படலாம்.';
  }

  @override
  String get handoverDeleteButton => 'நீக்கு';

  @override
  String get handoverStatusVerified => 'சரிபார்க்கப்பட்டது';

  @override
  String get handoverStatusPending => 'நிலுவையில் உள்ளது';

  @override
  String get handoverReceivedLabel => 'பெறப்பட்டது';

  @override
  String get handoverEditButton => 'திருத்து';

  @override
  String get handoverUnverifyButton => 'சரிபார்வை நீக்கு';

  @override
  String get handoverVerifyButton => 'சரிபார்';

  @override
  String handoverSummaryLine(String date, String cash, String upi) {
    return '$date · $cash ரொக்கம் · $upi UPI';
  }

  @override
  String get handoverSelectAgentValidator => 'ஒரு முகவரைத் தேர்ந்தெடுங்கள்';

  @override
  String get handoverCashAmountLabel => 'ரொக்கத் தொகை';

  @override
  String get handoverUpiAmountLabel => 'UPI தொகை';

  @override
  String get handoverNotesLabel => 'குறிப்புகள்';

  @override
  String get handoverNotesHint => 'விரும்பினால் சேர்க்கக்கூடிய குறிப்புகள்';

  @override
  String get handoverDateLabel => 'தேதி *';

  @override
  String get handoverRecordActionButton => 'பதிவு செய்';

  @override
  String get handoverSaveButton => 'சேமி';

  @override
  String get handoverCancelButton => 'ரத்து செய்';

  @override
  String get handoverRefreshButton => 'புதுப்பிக்கவும்';

  @override
  String handoverStatToday(String amount) {
    return 'இன்று: $amount';
  }

  @override
  String get handoverStatPendingToHandOver => 'ஒப்படைக்க வேண்டியது';

  @override
  String get handoverStatCashCollected => 'பணமாக வசூலிக்கப்பட்டது';

  @override
  String get handoverStatOnlineUpi => 'ஆன்லைன் / UPI';

  @override
  String handoverStillPendingBanner(String amount) {
    return 'நீங்கள் இன்னும் $amount ஒப்படைக்க வேண்டும். இந்த இருப்புத் தொகை தொடர்ந்து கடத்தப்படும் — நீங்கள் தீர்வு செய்யும் வரை நாளையத் தொகைகள் இதனுடன் சேர்க்கப்படும்.';
  }

  @override
  String get accountBookSubtitle =>
      'கையிருப்பில் உள்ள ரொக்கம் மற்றும் கொடுக்க வேண்டிய பணத்தைக் கண்காணிக்கவும்';

  @override
  String get accountTabAllEntries => 'அனைத்து உள்ளீடுகள்';

  @override
  String get accountTabCashInHand => 'கையிருப்பில் உள்ள ரொக்கம்';

  @override
  String get accountTabOutstandingLent => 'நிலுவையில் உள்ள பணம்';

  @override
  String get accountAddEntryButton => 'உள்ளீட்டைச் சேர்';

  @override
  String get accountAddCashEntryButton => 'ரொக்க உள்ளீட்டைச் சேர்';

  @override
  String get accountAddMoneyLentButton => 'கடன் பணத்தைச் சேர்';

  @override
  String get accountEntrySavedTitle => 'உள்ளீடு சேமிக்கப்பட்டது';

  @override
  String get accountEntrySavedMessage =>
      'பேரேட்டு உள்ளீடு வெற்றிகரமாக சேர்க்கப்பட்டது.';

  @override
  String get accountEntryUpdatedTitle => 'உள்ளீடு புதுப்பிக்கப்பட்டது';

  @override
  String get accountEntryUpdatedMessage =>
      'பேரேட்டு உள்ளீடு வெற்றிகரமாக புதுப்பிக்கப்பட்டது.';

  @override
  String get accountEntryDeletedTitle => 'உள்ளீடு நீக்கப்பட்டது';

  @override
  String get accountEntryDeletedMessage => 'பேரேட்டு உள்ளீடு நீக்கப்பட்டது.';

  @override
  String get accountDeleteFailedTitle => 'நீக்குதல் தோல்வியடைந்தது';

  @override
  String accountDeleteConfirmMessage(String title) {
    return '\"$title\" ஐ நீக்க விரும்புகிறீர்களா? இந்தச் செயலை மாற்ற முடியாது.';
  }

  @override
  String get accountNetBalanceSummaryTitle => 'நிகர இருப்புச் சுருக்கம்';

  @override
  String get accountCashInHandLabel => 'கையிருப்பில் உள்ள ரொக்கம்';

  @override
  String get accountOutstandingLabel => 'நிலுவையில் உள்ள கடன் பணம்';

  @override
  String get accountNetBalanceLabel => 'நிகர இருப்பு';

  @override
  String get accountUpdatingBadge => 'புதுப்பிக்கப்படுகிறது...';

  @override
  String get accountLiveBadge => 'நேரலை';

  @override
  String accountSummaryRefreshError(String error) {
    return 'சுருக்கத்தைப் புதுப்பிக்க முடியவில்லை: $error';
  }

  @override
  String get accountCashInHandSubtitle => 'மொத்தக் கையிருப்பு ரொக்கம்';

  @override
  String get accountBreakdownLoanCollection => 'கடன் வசூல்';

  @override
  String get accountBreakdownFundDeposits => 'நிதி வைப்புத்தொகை';

  @override
  String get accountBreakdownChitCollection => 'சீட்டு வசூல்';

  @override
  String get accountBreakdownCustomCashNet => 'தனிப்பயன் ரொக்க உள்ளீடுகள்';

  @override
  String get accountOutstandingMoneyTitle => 'நிலுவையில் உள்ள பணம்';

  @override
  String get accountOutstandingMoneySubtitle =>
      'உங்களுக்குச் செலுத்த வேண்டிய மொத்தப் பணம்';

  @override
  String get accountBreakdownLoanOutstanding => 'கடன் நிலுவை';

  @override
  String get accountBreakdownChitPending => 'சீட்டு நிலுவை';

  @override
  String get accountBreakdownFundPending => 'நிதி நிலுவை';

  @override
  String get accountBreakdownCustomMoneyLent => 'தனிப்பயன் கொடுக்கப்பட்ட பணம்';

  @override
  String get accountSearchHint =>
      'தலைப்பு அல்லது வகையின் அடிப்படையில் தேடுங்கள்...';

  @override
  String get accountLoadFailedTitle => 'உள்ளீடுகளை ஏற்ற முடியவில்லை';

  @override
  String get accountEmptyStateTitle => 'இதுவரை உள்ளீடுகள் இல்லை';

  @override
  String get accountEmptyStateBody =>
      'உங்கள் கணக்குப் புத்தகத்தைக் கண்காணிக்க உங்கள் முதல் ரொக்க அல்லது கடன் உள்ளீட்டைச் சேர்க்கவும்.';

  @override
  String get accountColDate => 'தேதி';

  @override
  String get accountColTitle => 'தலைப்பு';

  @override
  String get accountColCategory => 'வகை';

  @override
  String get accountColSection => 'பிரிவு';

  @override
  String get accountColType => 'வகை';

  @override
  String get accountColAmount => 'தொகை';

  @override
  String get accountColActions => 'செயல்கள்';

  @override
  String get accountMissingTitleTitle => 'தலைப்பு தேவை';

  @override
  String get accountMissingTitleMessage =>
      'இந்த உள்ளீட்டிற்கு ஒரு தலைப்பை உள்ளிடவும்.';

  @override
  String get accountInvalidDateTitle => 'தவறான தேதி';

  @override
  String get accountInvalidDateMessage =>
      'dd/mm/yyyy வடிவத்தில் சரியான தேதியை உள்ளிடவும்.';

  @override
  String get accountUpdateFailedTitle => 'புதுப்பிப்பு தோல்வியடைந்தது';

  @override
  String get accountSaveFailedTitle => 'சேமிப்பு தோல்வியடைந்தது';

  @override
  String get accountEditEntryTitle => 'உள்ளீட்டைத் திருத்து';

  @override
  String get accountAddEntryTitle => 'உள்ளீட்டைச் சேர்';

  @override
  String get accountEntryTitleLabel => 'தலைப்பு';

  @override
  String get accountEntryTitleHint => 'எ.கா: அலுவலக வாடகை, ரொக்க வைப்பு';

  @override
  String get accountEntryTypeLabel => 'உள்ளீட்டு வகை';

  @override
  String get accountAmountLabel => 'தொகை';

  @override
  String get accountAmountHint => '0.00';

  @override
  String get accountCategoryLabel => 'வகை';

  @override
  String get accountEntryDateLabel => 'தேதி';

  @override
  String get accountEntryDateHint => 'dd/mm/yyyy';

  @override
  String get accountNotesLabel => 'குறிப்புகள்';

  @override
  String get accountNotesHint => 'இந்த உள்ளீடு குறித்த விருப்பக் குறிப்புகள்';

  @override
  String get accountUpdateEntryButton => 'உள்ளீட்டைப் புதுப்பி';

  @override
  String get accountSaveEntryButton => 'உள்ளீட்டைச் சேமி';

  @override
  String get overdueManagementTitle => 'நிலுவை மேலாண்மை';

  @override
  String get overdueSubtitle =>
      'நிலுவையிலுள்ள கடன் கணக்குகளைக் கண்காணித்து, பின்தொடரவும்';

  @override
  String overdueCountBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count நிலுவையில்',
      one: '1 நிலுவையில்',
    );
    return '$_temp0';
  }

  @override
  String get overdueStatTotalLabel => 'மொத்த நிலுவை';

  @override
  String get overdueStatTotalSub => 'கணக்குகள்';

  @override
  String get overdueStatAmountLabel => 'நிலுவைத் தொகை';

  @override
  String get overdueStatAmountSub => 'நிலுவையுள்ளது';

  @override
  String get overdueStatAvgDaysLabel => 'சராசரி நிலுவை நாட்கள்';

  @override
  String overdueStatAvgDaysValue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days நாட்கள்',
      one: '1 நாள்',
    );
    return '$_temp0';
  }

  @override
  String get overdueStatAvgDaysSub => 'கணக்குகள் முழுவதும்';

  @override
  String get overdueStatCriticalLabel => 'முக்கியமான (>30 நா)';

  @override
  String get overdueStatCriticalSub => 'கவனம் தேவை';

  @override
  String get overdueSearchHint =>
      'வாடிக்கையாளர் அல்லது கடன் எண்ணைத் தேடவும்...';

  @override
  String get overdueFilterAll => 'அனைத்து நிலுவைகள்';

  @override
  String get overdueFilterCritical => 'முக்கியமான (>30 நா)';

  @override
  String get overdueNoMatchMessage =>
      'உங்கள் தேடலுடன் பொருந்தும் நிலுவை கணக்குகள் எதுவும் இல்லை.';

  @override
  String get overdueNoPhoneTitle => 'தொலைபேசி எண் இல்லை';

  @override
  String get overdueNoPhoneMessage =>
      'இந்த நிலுவைக் கணக்கிற்கு இன்னும் மொபைல் எண் இல்லை.';

  @override
  String get overdueSendMessageTitle => 'நினைவூட்டல் செய்தி அனுப்பவும்';

  @override
  String overdueSendMessageBody(String name, String phone) {
    return '$nameக்கு WhatsApp திறக்கவா?\n$phone';
  }

  @override
  String get overdueSendLabel => 'அனுப்பு';

  @override
  String overdueWhatsappTemplate(
      String name, String loanNumber, int days, String amount) {
    return 'வணக்கம் $name, உங்கள் கடன் எண் $loanNumber $days நாட்கள் நிலுவையில் உள்ளது. நிலுவையிலுள்ள $amount தொகையைச் செலுத்த எங்களைத் தொடர்பு கொள்ளவும்.';
  }

  @override
  String get overdueWhatsappFailedTitle => 'WhatsApp திறக்க முடியவில்லை';

  @override
  String get overdueCallTitle => 'வாடிக்கையாளருக்கு அழைக்கவும்';

  @override
  String overdueCallBody(String name, String phone) {
    return '$name\n$phone';
  }

  @override
  String get overdueCallLabel => 'அழை';

  @override
  String get overdueCallFailedTitle => 'அழைப்பைத் தொடங்க முடியவில்லை';

  @override
  String get overdueFollowUpAssignedTitle => 'பின்தொடர்தல் ஒதுக்கப்பட்டது';

  @override
  String get overdueGenericError =>
      'ஏதோ தவறு நிகழ்ந்துவிட்டது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get overdueBadgeLabel => 'நிலுவை';

  @override
  String get overdueLoanNumberLabel => 'கடன் எண்.';

  @override
  String get overdueDueAmountLabel => 'நிலுவைத் தொகை';

  @override
  String get overdueDaysOverdueLabel => 'நிலுவை நாட்கள்';

  @override
  String overdueDaysValue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days நாட்கள்',
      one: '1 நாள்',
    );
    return '$_temp0';
  }

  @override
  String get overdueStartedLabel => 'தொடங்கப்பட்டது';

  @override
  String get overdueFollowUpSectionLabel => 'பின்தொடர்தல்';

  @override
  String overdueFollowUpDueLabel(String date) {
    return '$date அன்று செலுத்தப்பட வேண்டும்';
  }

  @override
  String get overdueActionMessage => 'செய்தி அனுப்பு';

  @override
  String get overdueActionCall => 'அழை';

  @override
  String get overdueActionAssignFollowUp => 'பின்தொடர்தலை ஒதுக்கு';

  @override
  String get overdueAssignFollowUpTitle => 'பின்தொடர்தலை ஒதுக்கு';

  @override
  String get overdueFollowUpNoteHint =>
      'எ.கா. வாடிக்கையாளரை அழைத்தோம், வெள்ளிக்கிழமைக்குள் செலுத்துவதாக உறுதியளித்தார்';

  @override
  String get overdueFieldRequired => 'தேவை';

  @override
  String get overdueFollowUpNoteFieldLabel => 'பின்தொடர்தல் குறிப்பு';

  @override
  String get overdueFollowUpDateFieldLabel => 'பின்தொடர்தல் தேதி';

  @override
  String overdueStartedValue(String date) {
    return 'தொடங்கியது: $date';
  }

  @override
  String overdueOutstandingValue(String amount) {
    return 'நிலுவையுள்ளது: $amount';
  }

  @override
  String get save => 'சேமி';

  @override
  String get agentManagementTitle => 'முகவர் மேலாண்மை';

  @override
  String get agentManagementSubtitle =>
      'உங்கள் வசூல் முகவர்களைச் சேர்க்கவும், திருத்தவும், நிர்வகிக்கவும்';

  @override
  String get agentAddButton => 'முகவரைச் சேர்';

  @override
  String get agentLoadFailedFallback => 'முகவர்களை ஏற்ற முடியவில்லை.';

  @override
  String get agentStatTotal => 'மொத்த முகவர்கள்';

  @override
  String get agentStatActive => 'செயலில் உள்ள முகவர்கள்';

  @override
  String get agentStatInactive => 'செயலற்ற முகவர்கள்';

  @override
  String get agentStatAddedThisMonth => 'இந்த மாதம் சேர்க்கப்பட்டது';

  @override
  String get agentSearchHint => 'பெயர் அல்லது மொபைல் மூலம் தேடுக...';

  @override
  String get agentRoleAgent => 'முகவர்';

  @override
  String get agentRoleAdmin => 'நிர்வாகி';

  @override
  String get agentRoleManager => 'மேலாளர்';

  @override
  String get agentRoleAll => 'அனைத்தும்';

  @override
  String get agentColUser => 'பயனர்';

  @override
  String get agentColMobile => 'மொபைல்';

  @override
  String get agentColRole => 'பங்கு';

  @override
  String get agentColStatus => 'நிலை';

  @override
  String get agentColCreated => 'உருவாக்கப்பட்டது';

  @override
  String get agentColActions => 'செயல்கள்';

  @override
  String get agentNoAgentsFound => 'முகவர்கள் யாரும் இல்லை.';

  @override
  String get agentEditTooltip => 'திருத்து';

  @override
  String get agentDeleteTooltip => 'நீக்கு';

  @override
  String get agentCreatedTitle => 'முகவர் உருவாக்கப்பட்டது';

  @override
  String agentCreatedMessage(String name) {
    return '$name சேர்க்கப்பட்டுள்ளது';
  }

  @override
  String get agentCreateFailedTitle => 'முகவரை உருவாக்க முடியவில்லை';

  @override
  String get agentUpdatedTitle => 'முகவர் புதுப்பிக்கப்பட்டது';

  @override
  String agentUpdatedMessage(String name) {
    return '$name புதுப்பிக்கப்பட்டுள்ளது';
  }

  @override
  String get agentUpdateFailedTitle => 'முகவரைப் புதுப்பிக்க முடியவில்லை';

  @override
  String get agentDeleteDialogTitle => 'முகவரை நீக்கு';

  @override
  String agentDeleteConfirmMessage(String name) {
    return '$name நீக்க விரும்புகிறீர்களா? அவர்கள் மறுசுழற்சி தொட்டிக்கு நகர்த்தப்படுவார்கள், பின்னர் மீட்டெடுக்கப்படலாம்.';
  }

  @override
  String get agentDeleteConfirmLabel => 'முகவரை நீக்கு';

  @override
  String get agentDeletedTitle => 'முகவர் நீக்கப்பட்டது';

  @override
  String agentDeletedMessage(String name) {
    return '$name நீக்கப்பட்டது';
  }

  @override
  String get agentDeleteFailedTitle => 'முகவரை நீக்க முடியவில்லை';

  @override
  String get agentPhotoUploadFailedTitle =>
      'புகைப்படம் பதிவேற்றம் தோல்வியடைந்தது';

  @override
  String get agentMissingInfoTitle => 'தகவல்கள் இல்லை';

  @override
  String get agentMissingInfoMessage =>
      'தேவையான அனைத்து புலங்களையும் நிரப்பவும்';

  @override
  String get agentFormEditTitle => 'பயனரைத் திருத்து';

  @override
  String get agentFormAddTitle => 'பயனரைச் சேர்';

  @override
  String get agentFormCredentialsNotice =>
      'இந்த பயனர் பயன்பாட்டில் உள்நுழைய ஒரு மின்னஞ்சல் மற்றும் கடவுச்சொல்லை அமைக்கவும்.';

  @override
  String get agentFieldFullName => 'முழு பெயர் *';

  @override
  String get agentFieldFullNameHint => 'எ.கா. பிரியா சர்மா';

  @override
  String get agentFieldMobile => 'மொபைல்';

  @override
  String get agentFieldMobileHint => 'எ.கா. +91 98765 43210';

  @override
  String get agentFieldEmail => 'மின்னஞ்சல் *';

  @override
  String get agentFieldEmailHint => 'பயனர்@rrgroups.in';

  @override
  String get agentFieldPassword => 'கடவுச்சொல் *';

  @override
  String get agentFieldPasswordHint => 'குறைந்தபட்சம் 6 எழுத்துகள்';

  @override
  String get agentFieldRole => 'பங்கு';

  @override
  String get agentFieldStatus => 'நிலை';

  @override
  String get agentFieldAddress => 'முகவரி';

  @override
  String get agentFieldAddressHint => 'வசிப்பிட முகவரி';

  @override
  String get agentFieldAadhaar => 'ஆதார்';

  @override
  String get agentFieldAadhaarHint => '[ஆதார் மறைக்கப்பட்டது]';

  @override
  String get agentFieldPan => 'பான்';

  @override
  String get agentFieldPanHint => 'ABCDE1234F';

  @override
  String get agentFieldOccupation => 'தொழில்';

  @override
  String get agentFieldOccupationHint => 'எ.கா. கள நிர்வாகி';

  @override
  String get agentFieldProfilePhoto => 'சுயவிவரப் படம்';

  @override
  String get agentUploadPhotoButton => 'புகைப்படத்தைப் பதிவேற்று';

  @override
  String get agentSaveChangesButton => 'மாற்றங்களைச் சேமி';

  @override
  String get agentCreateUserButton => 'பயனரை உருவாக்கு';

  @override
  String get statusActive => 'செயலில்';

  @override
  String get statusInactive => 'செயலற்ற';

  @override
  String get fundsScreenTitle => 'நிதிகள்';

  @override
  String get fundsScreenSubtitle =>
      'முதிர்வு போனஸுடன் கூடிய வாராந்திர வைப்பு சேமிப்புத் திட்டங்கள்';

  @override
  String get fundCreateButton => 'நிதியை உருவாக்கு';

  @override
  String get fundSearchHint => 'வாடிக்கையாளர் பெயர் மூலம் தேடவும்';

  @override
  String get fundSearchClearTooltip => 'தேடலை அழி';

  @override
  String get fundRetryButton => 'மீண்டும் முயற்சி செய்';

  @override
  String get fundStatTotalFunds => 'மொத்த நிதிகள்';

  @override
  String get fundStatActive => 'செயலில் உள்ளது';

  @override
  String get fundStatMaturityPayout => 'முதிர்வுத் தொகை';

  @override
  String get fundStatCollected => 'சேகரிக்கப்பட்டது';

  @override
  String get fundEmptySearch =>
      'உங்கள் தேடலுடன் பொருந்தும் நிதிகள் எதுவும் இல்லை.';

  @override
  String get fundEmptyCustomer => 'உங்களுக்கு இன்னும் நிதிகள் எதுவும் இல்லை.';

  @override
  String get fundEmptyDefault => 'இன்னும் நிதிகள் இல்லை.';

  @override
  String get fundCardWeekly => 'வாராந்திரம்';

  @override
  String get fundCardWeeks => 'வாரங்கள்';

  @override
  String get fundCardBonus => 'போனஸ்';

  @override
  String get fundCardMaturityPayout => 'முதிர்வுத் தொகை';

  @override
  String fundCardDepositedProgress(String deposited, String total) {
    return '$deposited / $total செலுத்தப்பட்டது';
  }

  @override
  String get fundCardPassbookButton => 'பாஸ்புக்';

  @override
  String get fundCardCollectButton => 'சேகரி';

  @override
  String fundCardSettleBanner(String amount) {
    return 'முழுமையாகத் தீர்க்கவும் · $amount மீதமுள்ளது';
  }

  @override
  String get fundDeleteDialogTitle => 'நிதியை நீக்கு';

  @override
  String fundDeleteDialogMessage(String code, String customerName) {
    return '$customerName க்கான \"$code\" என்பதை நீக்க விரும்புகிறீர்களா? இது மறுசுழற்சி தொட்டிக்கு நகர்த்தப்பட்டு, பின்னர் மீட்டெடுக்கப்படலாம்.';
  }

  @override
  String get fundDeleteDialogConfirm => 'நீக்கு';

  @override
  String get fundAgentSettleDialogTitle => 'நிதியை முழுமையாகத் தீர்க்கவும்';

  @override
  String fundAgentSettleDialogMessage(
      String amount, String code, String customerName) {
    return '$customerName க்கான \"$code\" என்பதில் மீதமுள்ள $amount தொகையை இப்போது சேகரித்து, முதிர்வடைந்ததாகக் குறிக்க வேண்டுமா?';
  }

  @override
  String get fundAgentSettleDialogConfirm => 'இப்போது தீர்க்கவும்';

  @override
  String get fundToastLoadFailedTitle => 'நிதிகளை ஏற்றத் தவறிவிட்டது';

  @override
  String get fundToastCreatedTitle => 'நிதி உருவாக்கப்பட்டது';

  @override
  String get fundToastCreateFailedTitle => 'உருவாக்கத் தவறிவிட்டது';

  @override
  String get fundToastUpdatedTitle => 'நிதி புதுப்பிக்கப்பட்டது';

  @override
  String get fundToastUpdateFailedTitle => 'புதுப்பிக்கத் தவறிவிட்டது';

  @override
  String get fundToastSettledTitle => 'நிதி தீர்க்கப்பட்டது';

  @override
  String get fundToastSettlementFailedTitle => 'தீர்க்கத் தவறிவிட்டது';

  @override
  String get fundToastCollectionRecordedTitle => 'வசூல் பதிவு செய்யப்பட்டது';

  @override
  String get fundToastDeletedTitle => 'நிதி நீக்கப்பட்டது';

  @override
  String get fundToastDeleteFailedTitle => 'நீக்கத் தவறிவிட்டது';

  @override
  String get fundToastSelectCustomerTitle =>
      'ஒரு வாடிக்கையாளரைத் தேர்ந்தெடுக்கவும்';

  @override
  String get fundToastSelectCustomerMessage =>
      'தயவுசெய்து ஒரு வாடிக்கையாளரைத் தேர்ந்தெடுக்கவும்';

  @override
  String get fundFormTitleEdit => 'நிதியைத் திருத்து';

  @override
  String get fundFormTitleAdd => 'நிதியைச் சேர்';

  @override
  String get fundFormFieldCustomer => 'வாடிக்கையாளர்';

  @override
  String get fundFormFieldCustomerHint =>
      'ஒரு வாடிக்கையாளரைத் தேர்ந்தெடுக்கவும்...';

  @override
  String get fundFormFieldCustomerFallback => 'அறியப்படாதவர்';

  @override
  String get fundFormFieldAgent => 'நியமிக்கப்பட்ட முகவர் (விருப்பத்தேர்வு)';

  @override
  String get fundFormFieldAgentHint => 'ஒரு முகவரைத் தேர்ந்தெடுக்கவும்...';

  @override
  String get fundFormFieldAgentFallback => 'அறியப்படாத முகவர்';

  @override
  String get fundFormFieldUnits => 'நிதி அலகுகள் (அளவு)';

  @override
  String get fundFormFieldWeeklyAmount => 'வாராந்திரத் தொகை';

  @override
  String get fundFormFieldWeeks => 'வாரங்களின் எண்ணிக்கை';

  @override
  String get fundFormFieldBonus => 'முதிர்வு போனஸ்';

  @override
  String get fundFormFieldStartDate => 'தொடங்கும் தேதி';

  @override
  String get fundFormValidatorRequired => 'தேவை';

  @override
  String fundFormSummaryDeposited(String weekly, String weeks) {
    return 'செலுத்தப்பட்டது (₹$weekly x $weeks வாரங்கள்)';
  }

  @override
  String get fundFormSummaryBonus => 'முதிர்வு போனஸ்';

  @override
  String fundFormSummaryBonusValue(String amount) {
    return '+ $amount';
  }

  @override
  String get fundFormSummaryTotalPayout => 'மொத்த முதிர்வுத் தொகை';

  @override
  String fundFormMaturesOn(String date) {
    return '$date அன்று முதிர்வடையும்';
  }

  @override
  String get fundFormCancelButton => 'ரத்துசெய்';

  @override
  String get fundFormSaveButton => 'மாற்றங்களைச் சேமி';

  @override
  String get fundFormCreateButton => 'நிதியை உருவாக்கு';

  @override
  String get fundCollectDialogInvalidAmountTitle => 'தவறான தொகை';

  @override
  String get fundCollectDialogInvalidAmountMessage =>
      '0 ஐ விட அதிகமான வசூல் தொகையை உள்ளிடவும்';

  @override
  String get fundCollectDialogNotSavedTitle => 'வசூல் சேமிக்கப்படவில்லை';

  @override
  String fundCollectDialogNotSavedMessage(String remaining) {
    return 'இந்த வைப்புத்தொகையை முழுமையாகச் செலுத்த இன்னும் $remaining மட்டுமே உள்ளது.';
  }

  @override
  String get fundCollectDialogFailedTitle => 'வசூல் தோல்வியடைந்தது';

  @override
  String get fundCollectDialogTitle => 'வசூலைப் பதிவுசெய்';

  @override
  String fundCollectDialogSubtitle(String code, String customerName) {
    return '$code · $customerName';
  }

  @override
  String get fundCollectDialogCollectedLabel => 'சேகரிக்கப்பட்டது';

  @override
  String get fundCollectDialogRemainingLabel => 'மீதமுள்ளது';

  @override
  String get fundCollectDialogAmountLabel => 'சேகரிப்புத் தொகை';

  @override
  String get fundCollectDialogPaymentMethodLabel => 'பணம் செலுத்தும் முறை';

  @override
  String get fundCollectDialogPaymentDateLabel => 'பணம் செலுத்திய தேதி';

  @override
  String get fundCollectDialogHelperText =>
      'இந்தத் தொகையை நிதியின் சேகரிக்கப்பட்ட மொத்தத் தொகையில் சேர்க்கிறது. முழு வைப்பு இலக்கு சேகரிக்கப்பட்டவுடன் நிதியை முதிர்ச்சியடைந்ததாக தானாகவே குறிக்கும்.';

  @override
  String get fundCollectDialogRecordButton => 'பதிவுசெய்';

  @override
  String get fundSettleDialogTitle => 'நிதி மூடல் மற்றும் தீர்வு';

  @override
  String fundSettleDialogSubtitle(
      String code, String customerName, String units) {
    return '$code · $customerName ($units செயலில் உள்ள அலகுகள்)';
  }

  @override
  String get fundSettleTabPartial => 'பகுதி அலகு மூடல்';

  @override
  String get fundSettleTabFull => 'முழு கணக்கையும் தீர்வுசெய்';

  @override
  String get fundSettleUnitsToCloseLabel => 'மூட வேண்டிய அலகுகளின் எண்ணிக்கை';

  @override
  String get fundSettleHalfUnitButton => '0.5 அலகுகள்';

  @override
  String get fundSettleOneUnitButton => '1 அலகு';

  @override
  String get fundSettleClosedPayoutLabel => 'மூடப்பட்ட அலகுகளின் செலுத்தம்';

  @override
  String get fundSettleClosedPayoutSubtitle => 'சேர்ந்த வைப்புத்தொகை + போனஸ்';

  @override
  String get fundSettleRemainingBalanceLabel => 'மீதமுள்ள செயலில் உள்ள இருப்பு';

  @override
  String fundSettleRemainingUnitsValue(String units) {
    return '$units அலகுகள் மீதமுள்ளன';
  }

  @override
  String fundSettleNewWeeklyValue(String amount) {
    return 'புதிய வாராந்திர: $amount / வாரம்';
  }

  @override
  String get fundSettleTotalDepositedLabel => 'மொத்தமாக வைப்பு செய்யப்பட்டவை';

  @override
  String get fundSettleRemainingTargetLabel => 'மீதமுள்ள இலக்கு';

  @override
  String get fundSettlePaymentMethodLabel => 'பணம் செலுத்தும் முறை';

  @override
  String get fundSettleSettlementDateLabel => 'தீர்வு தேதி';

  @override
  String get fundSettleSummaryClosingTarget =>
      'மூடப்படும் அலகுகளின் வைப்பு இலக்கு';

  @override
  String fundSettleSummaryClosingTargetValue(
      String amount, String units, String maxUnits) {
    return '$amount ($maxUnits அலகுகளில் $units அலகுகள்)';
  }

  @override
  String get fundSettleSummaryTotalDeposit => 'மொத்த வைப்புத்தொகை';

  @override
  String get fundSettleSummaryProportionalBonus => '🎁 விகிதாசார போனஸ்';

  @override
  String get fundSettleSummaryNetClosurePayout => 'நிகர மூடல் செலுத்தும் தொகை';

  @override
  String get fundSettleSummaryPayoutToCustomer => 'வாடிக்கையாளருக்கு செலுத்தம்';

  @override
  String get fundSettleFailedTitle => 'மூடல் தோல்வியடைந்தது';

  @override
  String get fundSettleCancelButton => 'ரத்துசெய்';

  @override
  String get fundSettleConfirmPartialButton => 'பகுதி மூடலை உறுதிசெய்';

  @override
  String get fundSettleConfirmFullButton => 'முழு கணக்கையும் தீர்வுசெய்';

  @override
  String get fundPassbookTitle => 'பாஸ்புக்';

  @override
  String fundPassbookSubtitle(String code, String customerName) {
    return '$code · $customerName';
  }

  @override
  String get fundPassbookDepositedLabel => 'வைப்பு செய்யப்பட்டது';

  @override
  String get fundPassbookToDepositLabel => 'வைப்பு செய்ய வேண்டியது';

  @override
  String get fundPassbookEntriesLabel => 'பதிவுகள்';

  @override
  String fundPassbookEntriesValue(String paid, String total) {
    return '$totalல் $paid';
  }

  @override
  String fundPassbookSummaryTotalDeposit(String weekly, String weeks) {
    return 'மொத்த வைப்புத்தொகை (₹$weekly x $weeks வாரங்கள்)';
  }

  @override
  String get fundPassbookSummaryBonus =>
      '🎁 முதிர்வு போனஸ் (தீர்வு செய்யும் போது)';

  @override
  String get fundPassbookSummaryPayout => 'முதிர்வு செலுத்தம்';

  @override
  String get fundPassbookNextDuePrefix => 'அடுத்த வைப்புத்தொகை தேதி · ';

  @override
  String fundPassbookNextDueValue(String date, String week, String amount) {
    return '$date · வாரம் $week · $amount';
  }

  @override
  String get fundPassbookColWeek => 'வாரம்';

  @override
  String get fundPassbookColDateMethod => 'தேதி · முறை';

  @override
  String get fundPassbookColAmountBalance => 'தொகை · இருப்பு';

  @override
  String get fundPassbookNextDueRowLabel => 'அடுத்து வர வேண்டியது';

  @override
  String get fundPassbookPaidFallback => 'செலுத்தப்பட்டது';

  @override
  String get fundPassbookPendingLabel => 'நிலுவையில் உள்ளது';

  @override
  String fundPassbookBalanceValue(String balance) {
    return 'இருப்பு $balance';
  }

  @override
  String get fundPassbookCloseButton => 'மூடு';

  @override
  String get routeMapTitle => 'வாடிக்கையாளர் வரைபடம்';

  @override
  String get routeMapAllLocationsSubtitle =>
      'அனைத்து வாடிக்கையாளர் இருப்பிடங்கள்';

  @override
  String get routeMapSearchHint => 'வாடிக்கையாளர், கடன் அல்லது முகவரை தேடு...';

  @override
  String get routeMapCustomerLabel => 'வாடிக்கையாளர்';

  @override
  String get routeMapAllCustomers => 'அனைத்து வாடிக்கையாளர்கள்';

  @override
  String get routeMapTotalMapped => 'மொத்தமாக வரைபடமாக்கப்பட்டது';

  @override
  String get routeMapActiveCustomers => 'செயலில் உள்ள வாடிக்கையாளர்கள்';

  @override
  String get routeMapNoLocationsTitle =>
      'இருப்பிடங்கள் எதுவும் கண்டுபிடிக்கப்படவில்லை';

  @override
  String get routeMapNoLocationsMessage =>
      'சரியான ஒருங்கிணைப்புடன் கூடிய வாடிக்கையாளர்கள் இங்கே தோன்றுவார்கள்.';

  @override
  String get routeMapActive => 'செயலில்';

  @override
  String get routeMapInactive => 'செயலற்றது';

  @override
  String get routeMapRetryButton => 'மீண்டும் முயலுங்கள்';

  @override
  String get routeMapLoadFailedTitle => 'வரைபடத் தரவை ஏற்ற முடியவில்லை';

  @override
  String routeMapJoinedLabel(String date) {
    return 'சேர்ந்தது: $date';
  }

  @override
  String get reportsScreenTitle => 'அறிக்கைகள் மற்றும் பகுப்பாய்வுகள்';

  @override
  String get reportsSubtitle =>
      'தினசரி, மாதாந்திர மற்றும் முகவர் செயல்திறன் நுண்ணறிவுகள்';

  @override
  String get reportsExportPdfButton => 'PDF ஆக ஏற்றுமதி செய்';

  @override
  String get reportsExportExcelButton => 'Excel ஆக ஏற்றுமதி செய்';

  @override
  String get reportsExportingExcelTitle => 'Excel ஏற்றுமதி செய்யப்படுகிறது';

  @override
  String get reportsExportingExcelMessage =>
      'விரிதாள் கலங்கள் தொகுக்கப்படுகின்றன...';

  @override
  String get reportsExportCompleteTitle => 'ஏற்றுமதி நிறைவு';

  @override
  String get reportsExportCompleteMessage =>
      'Excel தாள் வெற்றிகரமாக உருவாக்கப்பட்டது.';

  @override
  String get reportsExportFailedTitle => 'ஏற்றுமதி தோல்வியடைந்தது';

  @override
  String reportsExportFailedMessage(String error) {
    return 'விரிதாளை உருவாக்க முடியவில்லை. தொழில்நுட்பக் காரணம்: $error';
  }

  @override
  String get reportsDailyHint =>
      'தினசரி அறிக்கை மேலே உள்ள இறுதி தேதிக்கான தரவைக் காட்டுகிறது.';

  @override
  String get reportsRetryButton => 'மீண்டும் முயலுங்கள்';

  @override
  String get reportsGenericErrorMessage =>
      'அறிக்கையை ஏற்றும்போது ஏதோ தவறு ஏற்பட்டது.';

  @override
  String get reportsTabDaily => 'தினசரி\nஅறிக்கை';

  @override
  String get reportsTabMonthly => 'மாதாந்திர\nஅறிக்கை';

  @override
  String get reportsTabAgent => 'முகவர்\nசெயல்திறன்';

  @override
  String get reportsTodaysCollectionsTitle => 'இன்றைய வசூல்கள்';

  @override
  String get reportsNoCollectionsTodayTitle => 'இன்று வசூல்கள் இல்லை';

  @override
  String get reportsNoCollectionsTodayMessage =>
      'இன்று செய்யப்பட்ட வசூல்கள் இங்கே தோன்றும்.';

  @override
  String get reportsNewLoansTodayTitle => 'இன்று உருவாக்கப்பட்ட புதிய கடன்கள்';

  @override
  String get reportsNoNewLoansTodayTitle => 'இன்று புதிய கடன்கள் இல்லை';

  @override
  String get reportsNoNewLoansTodayMessage =>
      'இன்று உருவாக்கப்பட்ட கடன்கள் இங்கே தோன்றும்.';

  @override
  String get reportsMetricDisbursement => 'கடன் வழங்கல்';

  @override
  String get reportsMetricInterest => 'சம்பாதித்த வட்டி';

  @override
  String get reportsMetricCollectionTotal => 'மொத்த வசூல்';

  @override
  String get reportsMetricNewCustomers => 'புதிய வாடிக்கையாளர்கள்';

  @override
  String get reportsCollectionsTrendTitle => 'வசூல் போக்கு';

  @override
  String reportsLastNMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'கடைசி $count மாதங்கள்',
      one: 'கடைசி $count மாதம்',
    );
    return '$_temp0';
  }

  @override
  String get reportsLoanDisbursementTitle => 'கடன் வழங்கல்';

  @override
  String get reportsByMonth => 'மாதம் தோறும்';

  @override
  String get reportsAgentPerformanceTitle => 'முகவர் செயல்திறன்';

  @override
  String get reportsNoAgentDataTitle => 'முகவர் தரவு இல்லை';

  @override
  String get reportsNoAgentDataMessage =>
      'முகவர்கள் செயலில் இருக்கும்போது முகவர் செயல்திறன் இங்கே தோன்றும்.';

  @override
  String get reportsColumnAgent => 'முகவர்';

  @override
  String get reportsColumnAssigned => 'ஒதுக்கப்பட்டவை';

  @override
  String get reportsColumnCollected => 'வசூலிக்கப்பட்டவை';

  @override
  String get reportsColumnEfficiency => 'செயல்திறன்';

  @override
  String get reportsCollectionsByAgentTitle => 'முகவர் வாரியான வசூல்கள்';

  @override
  String get reportsTotalAmountCollected => 'மொத்த வசூலிக்கப்பட்ட தொகை';

  @override
  String get reportsNoData => 'தரவு இல்லை';

  @override
  String get notificationsScreenTitle => 'அறிவிப்புகள்';

  @override
  String get notificationsSubtitle =>
      'நிலுவைகள், ஒப்புதல்கள் மற்றும் நினைவூட்டல்களின் மேல் இருங்கள்';

  @override
  String get markAllRead => 'அனைத்தையும் படித்ததாகக் குறி';

  @override
  String get send => 'அனுப்பு';

  @override
  String get statTotal => 'மொத்தம்';

  @override
  String get statUnread => 'படிக்காதவை';

  @override
  String get statOverdue => 'காலாவதியானது';

  @override
  String get filterAll => 'அனைத்தும்';

  @override
  String get filterUnread => 'படிக்காதவை';

  @override
  String get filterEmiDue => 'EMI நிலுவை';

  @override
  String get filterOverdue => 'காலாவதியானது';

  @override
  String get filterApprovals => 'ஒப்புதல்கள்';

  @override
  String get filterReminders => 'நினைவூட்டல்கள்';

  @override
  String get noNotificationsHere => 'இங்கே அறிவிப்புகள் எதுவும் இல்லை.';

  @override
  String get failedToLoadNotifications => 'அறிவிப்புகளை ஏற்ற முடியவில்லை';

  @override
  String get couldNotLoadNotificationsToastTitle =>
      'அறிவிப்புகளை ஏற்ற முடியவில்லை';

  @override
  String get allNotificationsClearedToastTitle =>
      'அனைத்து அறிவிப்புகளும் அழிக்கப்பட்டன';

  @override
  String get allNotificationsClearedToastMessage =>
      'அனைத்தும் படித்ததாகக் குறிக்கப்பட்டுள்ளன.';

  @override
  String get failedToUpdateToastTitle => 'புதுப்பிக்கத் தவறிவிட்டது';

  @override
  String get deleteNotificationTitle => 'அறிவிப்பை நீக்கு';

  @override
  String deleteNotificationMessage(String title) {
    return '\"$title\" என்பதை நீக்க விரும்புகிறீர்களா? இது மறுசுழற்சி தொட்டிக்கு நகர்த்தப்படும் மற்றும் பின்னர் மீட்டெடுக்கப்படலாம்.';
  }

  @override
  String get notificationRemovedToastTitle => 'அறிவிப்பு நீக்கப்பட்டது';

  @override
  String get failedToDeleteToastTitle => 'நீக்கத் தவறிவிட்டது';

  @override
  String get markedAsReadToastTitle => 'படித்ததாகக் குறிக்கப்பட்டது';

  @override
  String get failedToMarkAsReadToastTitle =>
      'படித்ததாகக் குறிக்கத் தவறிவிட்டது';

  @override
  String userIdLabel(String id) {
    return 'பயனர் ஐடி: $id';
  }

  @override
  String get sendNotificationTitle => 'அறிவிப்பை அனுப்பு';

  @override
  String get sendNotificationSubtitle =>
      'உங்கள் வாடிக்கையாளர்களுக்கு உடனடியாக அறிவிக்கவும்';

  @override
  String get recipientsLabel => 'பெறுநர்கள்';

  @override
  String get allCustomers => 'அனைத்து வாடிக்கையாளர்களும்';

  @override
  String get selectLabel => 'தேர்ந்தெடு';

  @override
  String get searchCustomersHint => 'வாடிக்கையாளர்களைத் தேடவும்...';

  @override
  String get noCustomersFoundInList => 'வாடிக்கையாளர்கள் யாரும் காணப்படவில்லை.';

  @override
  String get noPortalLogin => 'போர்ட்டல் உள்நுழைவு இல்லை';

  @override
  String get typeLabel => 'வகை';

  @override
  String get typeInfo => 'தகவல்';

  @override
  String get typeReminder => 'நினைவூட்டல்';

  @override
  String get typeEmiDue => 'இஎம்ஐ நிலுவையில் உள்ளது';

  @override
  String get typeOverdue => 'நிலுவைத் தேதி கடந்துவிட்டது';

  @override
  String get typeApproval => 'ஒப்புதல்';

  @override
  String get titleFieldLabel => 'தலைப்பு';

  @override
  String get titleFieldHint => 'எ.கா. EMI நாளை செலுத்தப்பட வேண்டும்';

  @override
  String get messageFieldLabel => 'செய்தி';

  @override
  String get messageFieldHint => 'உங்கள் செய்தியை எழுதவும்...';

  @override
  String get noRecipientsSelected =>
      'பெறுநர்கள் யாரும் தேர்ந்தெடுக்கப்படவில்லை';

  @override
  String recipientsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count பெறுநர்கள் தேர்ந்தெடுக்கப்பட்டுள்ளது',
      one: '1 பெறுநர் தேர்ந்தெடுக்கப்பட்டுள்ளது',
    );
    return '$_temp0';
  }

  @override
  String get titleRequiredError => 'தலைப்பு அவசியம்';

  @override
  String get noCustomersFoundError => 'வாடிக்கையாளர்கள் யாரும் இல்லை';

  @override
  String get noLinkedCustomerLoginsFoundError =>
      'இணைக்கப்பட்ட வாடிக்கையாளர் உள்நுழைவுகள் எதுவும் இல்லை';

  @override
  String get selectAtLeastOneRecipientError =>
      'குறைந்தது ஒரு பெறுநரையாவது தேர்ந்தெடுக்கவும்';

  @override
  String get noEligibleRecipientsToastTitle =>
      'தகுதியான பெறுநர்கள் யாரும் இல்லை';

  @override
  String get noEligibleRecipientsToastMessage =>
      'தேர்ந்தெடுக்கப்பட்ட வாடிக்கையாளர்கள் அறிவிப்புகளைப் பெற ஒரு போர்டல் உள்நுழைவு வைத்திருக்க வேண்டும்.';

  @override
  String get notificationSentToastTitle => 'அறிவிப்பு அனுப்பப்பட்டது';

  @override
  String recipientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count பெறுநர்கள்',
      one: '1 பெறுநர்',
    );
    return '$_temp0';
  }

  @override
  String get sendFailedToastTitle => 'அனுப்புதல் தோல்வியடைந்தது';

  @override
  String get couldNotLoadCustomersToastTitle =>
      'வாடிக்கையாளர்களை ஏற்ற முடியவில்லை';

  @override
  String get userManagementScreenTitle => 'பயனர் மேலாண்மை';

  @override
  String get userManagementSubtitle =>
      'உங்கள் அமைப்பில் பங்குகள், அணுகல் மற்றும் அனுமதிகளை நிர்வகிக்கவும்';

  @override
  String get addUser => 'பயனரைச் சேர்';

  @override
  String get refreshTooltip => 'புதுப்பி';

  @override
  String get edit => 'திருத்து';

  @override
  String get statTotalUsers => 'மொத்த பயனர்கள்';

  @override
  String get statActive => 'செயலில்';

  @override
  String get statAgents => 'முகவர்கள்';

  @override
  String get statAdmins => 'நிர்வாகிகள்';

  @override
  String get searchByNameOrMobileHint => 'பெயர் அல்லது மொபைல் மூலம் தேடு...';

  @override
  String get roleAll => 'அனைத்து பங்குகள்';

  @override
  String get roleAdmin => 'நிர்வாகி';

  @override
  String get roleCollectionAgent => 'வசூல் முகவர்';

  @override
  String get roleCustomer => 'வாடிக்கையாளர்';

  @override
  String get noUsersFound => 'பயனர்கள் இல்லை';

  @override
  String get tableColumnUser => 'பயனர்';

  @override
  String get tableColumnMobile => 'மொபைல்';

  @override
  String get tableColumnRole => 'பங்கு';

  @override
  String get tableColumnStatus => 'நிலை';

  @override
  String get adminCannotBeEditedTooltip =>
      'நிர்வாகி கணக்குகளைத் திருத்த முடியாது';

  @override
  String get adminCannotBeDeletedTooltip => 'நிர்வாகி கணக்குகளை நீக்க முடியாது';

  @override
  String get removeUserDialogTitle => 'பயனரை அகற்றவா?';

  @override
  String removeUserDialogMessage(String name) {
    return '$name மறுசுழற்சி தொட்டிக்கு நகர்த்தப்படும், பின்னர் மீட்டமைக்கலாம்.';
  }

  @override
  String get remove => 'அகற்று';

  @override
  String get userCreatedToastTitle => 'பயனர் உருவாக்கப்பட்டார்';

  @override
  String userCreatedToastMessage(String name) {
    return '$name வெற்றிகரமாக சேர்க்கப்பட்டார்';
  }

  @override
  String get couldNotCreateUserToastTitle => 'பயனரை உருவாக்க முடியவில்லை';

  @override
  String get somethingWentWrong => 'ஏதோ தவறு நடந்தது';

  @override
  String get userUpdatedToastTitle => 'பயனர் புதுப்பிக்கப்பட்டார்';

  @override
  String userUpdatedToastMessage(String name) {
    return '$name சேமிக்கப்பட்டார்';
  }

  @override
  String get couldNotUpdateUserToastTitle => 'பயனரைப் புதுப்பிக்க முடியவில்லை';

  @override
  String get userRemovedToastTitle => 'பயனர் அகற்றப்பட்டார்';

  @override
  String userRemovedToastMessage(String name) {
    return '$name நீக்கப்பட்டார்';
  }

  @override
  String get couldNotDeleteUserToastTitle => 'பயனரை நீக்க முடியவில்லை';

  @override
  String get failedToLoadUsers => 'பயனர்களை ஏற்ற முடியவில்லை';

  @override
  String get dismissAddUserDialogLabel => 'பயனர் சேர் உரையாடலை மூடு';

  @override
  String get dismissEditUserDialogLabel => 'பயனர் திருத்து உரையாடலை மூடு';

  @override
  String get editUserDialogTitle => 'பயனரைத் திருத்து';

  @override
  String get editPasswordHintNote =>
      'தற்போதைய கடவுச்சொல்லை மாற்றாமல் வைக்க கடவுச்சொல்லை காலியாக விடவும்.';

  @override
  String get addUserBackendNote =>
      'இது நேரடியாக பின்தளத்தில் ஒரு உள்நுழைவு கணக்கை உருவாக்குகிறது. கீழே உள்ள மின்னஞ்சல் மற்றும் கடவுச்சொல்லுடன் பயனர் உடனடியாக உள்நுழையலாம்.';

  @override
  String get fullNameRequiredError => 'முழு பெயர் தேவை';

  @override
  String get validEmailRequiredError => 'சரியான மின்னஞ்சல் தேவை';

  @override
  String get passwordMinLengthError =>
      'கடவுச்சொல் குறைந்தது 6 எழுத்துகள் இருக்க வேண்டும்';

  @override
  String get fullNameFieldLabel => 'முழு பெயர் *';

  @override
  String get fullNameFieldHint => 'எ.கா. பிரியா சர்மா';

  @override
  String get emailFieldLabel => 'மின்னஞ்சல் *';

  @override
  String get emailFieldHint => 'எ.கா. priya@example.com';

  @override
  String get newPasswordOptionalLabel => 'புதிய கடவுச்சொல் (விருப்பம்)';

  @override
  String get passwordFieldLabel => 'கடவுச்சொல் *';

  @override
  String get passwordLeaveBlankHint => 'மாற்றாமல் வைக்க காலியாக விடவும்';

  @override
  String get passwordMinCharsHint => 'குறைந்தது 6 எழுத்துகள்';

  @override
  String get mobileFieldLabel => 'மொபைல்';

  @override
  String get mobileFieldHint => 'எ.கா. +91 98765 43210';

  @override
  String get roleFieldLabel => 'பங்கு';

  @override
  String get statusFieldLabel => 'நிலை';

  @override
  String get avatarUrlFieldLabel => 'அவதார் URL';

  @override
  String get avatarUrlFieldHint => 'https://...';

  @override
  String get avatarUrlHelperText => 'விருப்ப சுயவிவரப் பட இணைப்பு';

  @override
  String get saveChanges => 'மாற்றங்களைச் சேமி';

  @override
  String get chitGroupsTitle => 'Chit Groups';

  @override
  String get chitGroupsSubtitle => 'View and manage chit group collections';

  @override
  String get createGroupButton => 'Create Group';

  @override
  String get searchHint => 'Search by chit fund name or number...';

  @override
  String get clearSearchTooltip => 'Clear search';

  @override
  String get retryButton => 'Retry';

  @override
  String get noSearchResultsMessage => 'No chit funds match your search.';

  @override
  String get customerNoGroupMessage =>
      'You have not been added to a chit group yet.';

  @override
  String get noGroupsFoundMessage => 'No chit groups found.';

  @override
  String get membersLabel => 'Members';

  @override
  String get durationLabel => 'Duration';

  @override
  String get valueLabel => 'Value';

  @override
  String get collectionProgressLabel => 'Collection Progress';

  @override
  String get collectButton => 'Collect';

  @override
  String get viewPassbookButton => 'View Passbook';

  @override
  String get viewDetailsButton => 'View Details';

  @override
  String groupNumberLabel(String code) {
    return 'Group No.: $code';
  }

  @override
  String durationMonthsShort(int months) {
    return '$months mo';
  }

  @override
  String get notAMemberTitle => 'Not a member';

  @override
  String get notAMemberMessage => 'You are not part of this chit group yet.';

  @override
  String get failedOpenPassbookTitle => 'Failed to open passbook';

  @override
  String get failedLoadGroupsTitle => 'Failed to load chit groups';

  @override
  String get deleteGroupTitle => 'Delete Chit Group';

  @override
  String deleteGroupMessage(String groupName) {
    return 'Delete \"$groupName\"? It will be moved to the Recycle Bin and can be restored later.';
  }

  @override
  String get deleteButton => 'Delete';

  @override
  String get groupDeletedTitle => 'Group deleted';

  @override
  String groupRemovedMessage(String groupName) {
    return '$groupName was removed';
  }

  @override
  String get deleteFailedTitle => 'Delete failed';

  @override
  String get invalidScheduleValuesTitle => 'Invalid schedule values';

  @override
  String get invalidScheduleValuesMessage =>
      'Enter valid payable and pool amounts.';

  @override
  String get scheduleUpdateFailedTitle => 'Schedule update failed';

  @override
  String overrideDrawTitle(int installmentNo) {
    return 'Override Draw #$installmentNo';
  }

  @override
  String get payableAmountLabel => 'PAYABLE AMOUNT';

  @override
  String get poolDividendValueLabel => 'POOL / DIVIDEND VALUE';

  @override
  String get dueDateLabel => 'DUE DATE';

  @override
  String get notesLabel => 'NOTES';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get savingButton => 'Saving...';

  @override
  String get saveOverrideButton => 'Save Override';

  @override
  String get editGroupTitle => 'Edit Group';

  @override
  String get createGroupSheetTitle => 'Create Group';

  @override
  String get quickSchemePresetsLabel => 'Quick Scheme Presets:';

  @override
  String get groupNameLabel => 'GROUP NAME *';

  @override
  String get requiredValidation => 'Required';

  @override
  String get membersFieldLabel => 'MEMBERS *';

  @override
  String get enterNumberValidation => 'Enter a number';

  @override
  String get durationFieldLabel => 'DURATION (mo) *';

  @override
  String get groupValueLabel => 'GROUP VALUE *';

  @override
  String get monthlyContributionLabel => 'MONTHLY CONTRIBUTION *';

  @override
  String get startDateLabel => 'START DATE *';

  @override
  String get drawFrequencyLabel => 'DRAW FREQUENCY *';

  @override
  String get drawIntervalLabel => 'DRAW DAYS / INTERVAL';

  @override
  String get drawIntervalHint => 'e.g. 7';

  @override
  String get enterDaysValidation => 'Enter days > 0';

  @override
  String get monthlyIntervalHelp =>
      'Each draw falls on the same day next calendar month.';

  @override
  String get customIntervalHelp => 'Gap in days between one draw and the next.';

  @override
  String get fixedIntervalHelp =>
      'Gap in days between draws — fixed by the selected frequency.';

  @override
  String get manualDatesHelp =>
      'Set each draw date individually in the schedule list below.';

  @override
  String get statusLabel => 'STATUS *';

  @override
  String get saveChangesButton => 'Save Changes';

  @override
  String installmentScheduleHeader(int count) {
    return 'INSTALLMENT SCHEDULE ($count DRAWS)';
  }

  @override
  String autoGeneratedBadge(int count) {
    return 'Auto-Generated 1–$count';
  }

  @override
  String get groupCreatedTitle => 'Group created';

  @override
  String get groupUpdatedTitle => 'Group updated';

  @override
  String get saveFailedTitle => 'Save failed';

  @override
  String installmentNumberLabel(int number) {
    return 'Installment #$number';
  }

  @override
  String get payableLabel => 'Payable';

  @override
  String get poolDividendValueShortLabel => 'Pool / Dividend Value';

  @override
  String get installmentUpdatedTitle => 'Installment updated';

  @override
  String drawOverriddenMessage(int number) {
    return 'Draw #$number overridden';
  }

  @override
  String get removeMemberTitle => 'Remove Member';

  @override
  String removeMemberMessage(String memberName) {
    return 'Remove \"$memberName\" from this group?';
  }

  @override
  String get removeButton => 'Remove';

  @override
  String get memberRemovedTitle => 'Member removed';

  @override
  String get removeFailedTitle => 'Remove failed';

  @override
  String get collectionUnavailableTitle => 'Collection unavailable';

  @override
  String get noScheduleMessage =>
      'No installment schedule exists for this group.';

  @override
  String get memberAddedTitle => 'Member added';

  @override
  String get collectionRecordedTitle => 'Collection recorded';

  @override
  String collectionRecordedMessage(String memberName, String amount) {
    return '$memberName · $amount';
  }

  @override
  String get collectionFailedTitle => 'Collection failed';

  @override
  String get collectionCompleteTitle => 'Collection complete';

  @override
  String get collectionCompleteMessage =>
      'You have collected the required amount.';

  @override
  String get groupNumberShortLabel => 'Group No.';

  @override
  String memberCollectionsTab(int count) {
    return 'Member Collections ($count)';
  }

  @override
  String installmentScheduleTab(int count) {
    return 'Installment Schedule ($count)';
  }

  @override
  String get memberCollectionTrackingTitle => 'Member Collection Tracking';

  @override
  String get addMemberButton => 'Add Member';

  @override
  String get noMembersMessage => 'No members yet.';

  @override
  String get memberColumnHeader => 'MEMBER';

  @override
  String get contributionColumnHeader => 'CONTRIBUTION';

  @override
  String get dueDateColumnHeader => 'DUE DATE';

  @override
  String get statusColumnHeader => 'STATUS';

  @override
  String get actionColumnHeader => 'ACTION';

  @override
  String get paidStatus => 'Paid';

  @override
  String get partialStatus => 'Partial';

  @override
  String get overdueStatus => 'Overdue';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get installmentScheduleSubtitle =>
      'View and manually edit installment dates for draws';

  @override
  String get noScheduleFoundMessage => 'No installment schedule found.';

  @override
  String get instNumberColumnHeader => 'INST #';

  @override
  String get payableAmountColumnHeader => 'PAYABLE AMOUNT';

  @override
  String get poolDividendValueColumnHeader => 'POOL / DIVIDEND VALUE';

  @override
  String get paymentStatusColumnHeader => 'PAYMENT STATUS';

  @override
  String scheduleMembersPaidLabel(int paid, int total, String amount) {
    return '$paid/$total members · $amount';
  }

  @override
  String get dateTypeColumnHeader => 'DATE TYPE';

  @override
  String get customOverriddenBadge => 'Custom Overridden';

  @override
  String get autoScheduledBadge => 'Auto-Scheduled';

  @override
  String get overrideDateAmountButton => 'Override Date & Amount';

  @override
  String get viewOnlyLabel => 'View only';

  @override
  String get dueDateCardLabel => 'Due Date';

  @override
  String get payableAmountCardLabel => 'Payable Amount';

  @override
  String get poolValueCardLabel => 'Pool Value';

  @override
  String get overrideButton => 'Override';

  @override
  String get recordChitCollectionTitle => 'Record Chit Collection';

  @override
  String get collectionAmountLabel => 'COLLECTION AMOUNT (₹)';

  @override
  String get paymentMethodLabel => 'PAYMENT METHOD';

  @override
  String get collectionDateLabel => 'COLLECTION DATE';

  @override
  String get selectMethodHint => 'Select method';

  @override
  String get dateHint => 'Date';

  @override
  String get notesOptionalLabel => 'NOTES (OPTIONAL)';

  @override
  String get receiptNotesHint => 'Receipt or transaction ref...';

  @override
  String get confirmCollectionButton => 'Confirm Collection';

  @override
  String get addMemberTitle => 'Add Member';

  @override
  String get customerLabel => 'CUSTOMER *';

  @override
  String get selectCustomerHint => 'Select a customer...';

  @override
  String customerNumberNotAvailable(String role) {
    return '$role · Customer number not available';
  }

  @override
  String customerRolePhone(String role, String phone) {
    return '$role · $phone';
  }

  @override
  String get contributionAmountLabel => 'CONTRIBUTION AMOUNT';

  @override
  String get enterValidNumberValidation => 'Enter a valid number';

  @override
  String defaultsToAmount(String amount) {
    return 'Defaults to $amount';
  }

  @override
  String get selectCustomerTitle => 'Select a customer';

  @override
  String get selectCustomerMessage => 'Choose a customer to add to this group.';

  @override
  String get addMemberFailedTitle => 'Add member failed';
}
