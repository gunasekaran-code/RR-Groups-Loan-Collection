// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'RR Groups';

  @override
  String get welcomeMessage => 'फिनकलेक्ट में आपका स्वागत है';

  @override
  String get loans => 'ऋण';

  @override
  String get collections => 'वसूली';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get paymentReminders => 'भुगतान रिमाइंडर';

  @override
  String get groupUpdates => 'समूह अपडेट';

  @override
  String get security => 'सुरक्षा';

  @override
  String get changeMpin => 'MPIN बदलें';

  @override
  String get biometricLogin => 'बायोमेट्रिक लॉगिन';

  @override
  String get preferences => 'प्राथमिकताएं';

  @override
  String get language => 'भाषा';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get help => 'सहायता';

  @override
  String get contactSupport => 'सहायता से संपर्क करें';

  @override
  String get faq => 'सामान्य प्रश्न';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get confirmLogoutQuestion =>
      'क्या आप वाकई अपने खाते से लॉग आउट करना चाहते हैं?';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get loggedOut => 'लॉग आउट हो गया';

  @override
  String get connectBackendToEnable => 'सक्षम करने के लिए बैकएंड कनेक्ट करें';

  @override
  String get deleteEntry => 'एंट्री हटाएं';

  @override
  String get delete => 'हटाएं';

  @override
  String get printStatement => 'स्टेटमेंट प्रिंट करें';

  @override
  String get accountBook => 'खाता बही';

  @override
  String get recycleBinTitle => 'रीसायकल बिन';

  @override
  String get recycleBinSubtitle =>
      'ऐप में कहीं भी हटाई गई हर चीज़ — किसी व्यवस्थापक, एजेंट या ग्राहक द्वारा';

  @override
  String get recycleBinSearchHint =>
      'नाम, प्रकार या जिसने इसे हटाया है, उसके अनुसार खोजें...';

  @override
  String get recycleBinEmptyButton => 'रीसायकल बिन खाली करें';

  @override
  String get recycleBinRestoreLabel => 'पुनर्स्थापित करें';

  @override
  String get recycleBinRestoredBadge => 'पुनर्स्थापित किया गया';

  @override
  String get recycleBinDeletePermanentlyTitle => 'स्थायी रूप से हटाएँ?';

  @override
  String get recycleBinEmptyTitle => 'रीसायकल बिन खाली करें?';

  @override
  String get recycleBinEmptyMessage =>
      'क्या आप वाकई सभी आइटम स्थायी रूप से हटाना चाहते हैं? इस कार्रवाई को पूर्ववत नहीं किया जा सकता है।';

  @override
  String get recycleBinNoItems => 'कोई मिलान करने वाली आइटम नहीं मिली।';

  @override
  String get customersTitle => 'ग्राहक';

  @override
  String get customersSubtitle => 'ग्राहक जानकारी और विवरण प्रबंधित करें';

  @override
  String get customersAddButton => 'ग्राहक जोड़ें';

  @override
  String get customersSearchHint => 'नाम से खोजें...';

  @override
  String get customersFilterAll => 'सभी स्थिति';

  @override
  String get customersFilterActive => 'सक्रिय';

  @override
  String get customersFilterOverdue => 'अतिदेय';

  @override
  String get customersFilterInactive => 'निष्क्रिय';

  @override
  String get customersNoResults => 'कोई ग्राहक नहीं मिला';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get customersLoadFailedTitle => 'ग्राहकों को लोड करने में विफल';

  @override
  String get customersDeleteTitle => 'ग्राहक हटाएँ';

  @override
  String customersDeleteMessage(String name) {
    return 'क्या आप निश्चित हैं कि आप $name को हटाना चाहते हैं? उन्हें रीसायकल बिन में भेज दिया जाएगा और बाद में बहाल किया जा सकता है।';
  }

  @override
  String get customersDeletedTitle => 'ग्राहक हटा दिया गया';

  @override
  String customersDeletedMessage(String name) {
    return '$name को सफलतापूर्वक हटा दिया गया';
  }

  @override
  String get customersDeleteFailedTitle => 'हटाने में विफल';

  @override
  String get customersUpdatedTitle => 'ग्राहक अपडेट किया गया';

  @override
  String get customersAddedTitle => 'ग्राहक जोड़ा गया';

  @override
  String customersUpdatedMessage(String name) {
    return '$name को सफलतापूर्वक अपडेट किया गया';
  }

  @override
  String customersAddedMessage(String name) {
    return '$name को सफलतापूर्वक जोड़ा गया';
  }

  @override
  String get customersSaveFailedTitle => 'कुछ गलत हो गया';

  @override
  String get customerViewClose => 'बंद करें';

  @override
  String get customerFieldId => 'ग्राहक आईडी';

  @override
  String get customerFieldMobile => 'मोबाइल';

  @override
  String get customerFieldAddress => 'पता';

  @override
  String get customerFieldAadhaar => 'आधार';

  @override
  String get customerFieldPan => 'पैन';

  @override
  String get customerFieldOccupation => 'पेशा';

  @override
  String get customerFieldAgent => 'नियुक्त एजेंट';

  @override
  String get customerFieldLoanStatus => 'ऋण स्थिति';

  @override
  String get customerActionView => 'देखें';

  @override
  String get customerActionEdit => 'संपादित करें';

  @override
  String get customerActionDelete => 'हटाएँ';

  @override
  String get customerUnassigned => 'अनासाइन किया गया';

  @override
  String get customerFormEditTitle => 'ग्राहक संपादित करें';

  @override
  String get customerFormAddTitle => 'ग्राहक जोड़ें';

  @override
  String get customerFormEditSubtitle => 'ग्राहक विवरण अपडेट करें';

  @override
  String get customerFormAddSubtitle => 'नीचे विवरण भरें';

  @override
  String get customerSectionPersonal => 'व्यक्तिगत विवरण';

  @override
  String get customerSectionAssignment => 'नियुक्ति';

  @override
  String get customerSectionPortalLogin => 'पोर्टल लॉगिन (वैकल्पिक)';

  @override
  String get customerSectionPhoto => 'फ़ोटो';

  @override
  String get customerLabelFullName => 'पूरा नाम *';

  @override
  String get customerHintFullName => 'उदाहरण: रमेश कुमार';

  @override
  String get customerLabelMobile => 'मोबाइल नंबर *';

  @override
  String get customerHintMobile => '10 अंकों का मोबाइल नंबर';

  @override
  String get customerLabelAddress => 'पता *';

  @override
  String get customerHintAddress => 'पूरा आवासीय पता';

  @override
  String get customerLabelAadhaar => 'आधार (वैकल्पिक)';

  @override
  String get customerHintAadhaar => '12 अंकों का आधार नंबर';

  @override
  String get customerLabelPan => 'पैन (वैकल्पिक)';

  @override
  String get customerHintPan => 'उदाहरण: ABCDE1234F';

  @override
  String get customerLabelOccupation => 'पेशा (वैकल्पिक)';

  @override
  String get customerHintOccupation => 'उदाहरण: दुकान मालिक';

  @override
  String get customerLabelAssignedAgent => 'नियुक्त एजेंट';

  @override
  String get customerMapLocationTitle => 'नक्शे पर स्थान';

  @override
  String get customerMapLocationSubtitle => 'एजेंट मार्ग के लिए';

  @override
  String get customerPinFromAddress => 'पते से पिन करें';

  @override
  String get customerUseMyGps => 'मेरा जीपीएस उपयोग करें';

  @override
  String get customerMapHelpText =>
      'यह ग्राहक एजेंट के लाइव रूट मैप पर दिखाता है। \"पते से पिन करें\" ऊपर दिए गए पते को खोजता है; \"मेरा जीपीएस उपयोग करें\" आपकी वर्तमान स्थिति को कैप्चर करता है।';

  @override
  String get customerLatitudeLabel => 'अक्षांश';

  @override
  String get customerLongitudeLabel => 'देशांतर';

  @override
  String get customerLatLngHint => '0.0000000';

  @override
  String get customerAddressRequiredTitle => 'पता आवश्यक है';

  @override
  String get customerAddressRequiredMessage =>
      'पहले एक पता दर्ज करें ताकि इसे नक्शे पर खोजा जा सके';

  @override
  String get customerAddressNotFoundTitle => 'वह पता नहीं मिल सका';

  @override
  String get customerLocationFailedTitle => 'आपका स्थान प्राप्त नहीं हो सका';

  @override
  String get customerPhotoFailedTitle => 'फ़ोटो अपलोड विफल';

  @override
  String get customerPortalLoginHelp =>
      'इस ग्राहक को अपने ऋण और भुगतान देखने के लिए अपने मोबाइल नंबर से साइन इन करने देने के लिए एक पासवर्ड सेट करें। ईमेल की आवश्यकता नहीं है।';

  @override
  String get customerLabelEmail => 'ईमेल (वैकल्पिक)';

  @override
  String get customerHintEmail => 'customer@example.com';

  @override
  String get customerLabelPassword => 'पासवर्ड (वैकल्पिक)';

  @override
  String get customerHintPassword => 'कम से कम 6 अक्षर';

  @override
  String get customerLoginNote =>
      'लॉगिन ऊपर दिए गए मोबाइल नंबर को उपयोगकर्ता नाम के रूप में उपयोग करता है।';

  @override
  String get customerUploadPhoto => 'फ़ोटो अपलोड करें';

  @override
  String get customerSaveChanges => 'परिवर्तन सहेजें';

  @override
  String get customerFormValidationTitle => 'फ़ॉर्म जांचें';

  @override
  String get customerFormValidationMessage =>
      'सहेजने से पहले हाइलाइट किए गए फ़ील्ड को ठीक करें';

  @override
  String get customerValidatorNameRequired => 'पूरा नाम आवश्यक है';

  @override
  String get customerValidatorNameMin => 'कम से कम 3 वर्ण दर्ज करें';

  @override
  String get customerValidatorNameChars =>
      'केवल अक्षर और रिक्त स्थान अनुमत हैं';

  @override
  String get customerValidatorMobileRequired => 'मोबाइल नंबर आवश्यक है';

  @override
  String get customerValidatorMobileInvalid =>
      'एक वैध 10-अंकीय मोबाइल नंबर दर्ज करें';

  @override
  String get customerValidatorAddressRequired => 'पता आवश्यक है';

  @override
  String get customerValidatorAddressMin => 'अधिक पूरा पता दर्ज करें';

  @override
  String get customerValidatorAadhaarInvalid =>
      'आधार ठीक 12 अंकों का होना चाहिए';

  @override
  String get customerValidatorPanInvalid =>
      'एक वैध पैन दर्ज करें (उदा. ABCDE1234F)';

  @override
  String get customerValidatorOccupationInvalid => 'एक वैध व्यवसाय दर्ज करें';

  @override
  String get customerValidatorNumberInvalid => 'एक वैध संख्या दर्ज करें';

  @override
  String get customerValidatorLatRange => 'यह -90 और 90 के बीच होना चाहिए';

  @override
  String get customerValidatorLngRange => 'यह -180 और 180 के बीच होना चाहिए';

  @override
  String get customerValidatorEmailInvalid => 'एक वैध ईमेल पता दर्ज करें';

  @override
  String get customerValidatorPasswordMin =>
      'पासवर्ड कम से कम 6 वर्णों का होना चाहिए';

  @override
  String get dashboardTitle => 'डैशबोर्ड';

  @override
  String dashboardNotLinkedYet(String label) {
    return '$label अभी तक लिंक नहीं किया गया है';
  }

  @override
  String get dashboardGreetingMorning => 'सुप्रभात';

  @override
  String get dashboardGreetingAfternoon => 'शुभ दोपहर';

  @override
  String get dashboardGreetingEvening => 'शुभ संध्या';

  @override
  String dashboardGreetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String dashboardLiveFigures(String amount, int count) {
    return 'डेटाबेस से लाइव आंकड़े: आज $amount जमा हुए और $count सक्रिय ऋण हैं।';
  }

  @override
  String get dashboardNetBalanceSummary => 'शुद्ध शेष सारांश';

  @override
  String get dashboardNetBalanceSubtitle => 'रीयल-टाइम कार्यशील पूंजी स्थिति';

  @override
  String get dashboardCashInHand => 'नकद राशि';

  @override
  String get dashboardLoanCollections => 'ऋण संग्रह';

  @override
  String get dashboardFundDeposits => 'निधि जमा';

  @override
  String get dashboardCustomCashIn => '+ कस्टम नकद जमा';

  @override
  String get dashboardOutstandingMoneyLent => 'बकाया उधार दिया गया पैसा';

  @override
  String get dashboardLoansOutstanding => 'बकाया ऋण';

  @override
  String get dashboardCustomLent => '+ कस्टम उधार';

  @override
  String get dashboardNetBalanceLabel => 'शुद्ध शेष';

  @override
  String get dashboardTotalAssets => 'कुल संपत्ति';

  @override
  String dashboardNetBalanceFormula(String cash, String lent) {
    return 'नकद राशि ($cash) + उधार दिया गया पैसा ($lent)';
  }

  @override
  String get dashboardStatActiveLoans => 'सक्रिय ऋण';

  @override
  String get dashboardStatNewCustomers => 'नए ग्राहक';

  @override
  String get dashboardStatTodaysCollections => 'आज का संग्रह';

  @override
  String get dashboardStatOverdueAccounts => 'देय खाते';

  @override
  String get dashboardStatPendingApprovals => 'लंबित स्वीकृतियां';

  @override
  String get dashboardStatTotalLoanAmount => 'कुल ऋण राशि';

  @override
  String get dashboardStatInterestRevenue => 'ब्याज राजस्व';

  @override
  String get dashboardStatMonthlyCollection => 'मासिक संग्रह';

  @override
  String get dashboardCollectionTrend => 'संग्रह रुझान';

  @override
  String get dashboardCollectionTrendSubtitle =>
      'रिपोर्ट तालिका से पिछले महीने';

  @override
  String get dashboardLoanStatus => 'ऋण स्थिति';

  @override
  String get dashboardLoanStatusSubtitle => 'लाइव डेटाबेस सारांश';

  @override
  String get dashboardDonutTotal => 'कुल';

  @override
  String get dashboardStatusActive => 'सक्रिय';

  @override
  String get dashboardStatusOverdue => 'देय';

  @override
  String get dashboardStatusClosedOther => 'बंद/अन्य';

  @override
  String get dashboardAgentPerformance => 'एजेंट प्रदर्शन';

  @override
  String get dashboardAgentPerformanceSubtitle =>
      'रिपोर्ट से शीर्ष फील्ड एजेंट';

  @override
  String get dashboardMonthlyProgress => 'मासिक संग्रह प्रगति';

  @override
  String dashboardMonthlyProgressSubtitle(String collected, String target) {
    return '₹$target लक्ष्य में से ₹$collected';
  }

  @override
  String get dashboardQuickActions => 'त्वरित कार्य';

  @override
  String get dashboardQuickAddCustomer => 'ग्राहक जोड़ें';

  @override
  String get dashboardQuickCreateLoan => 'ऋण बनाएँ';

  @override
  String get dashboardQuickChitGroup => 'चिट समूह';

  @override
  String get dashboardQuickAddAgent => 'एजेंट जोड़ें';

  @override
  String get dashboardQuickReports => 'रिपोर्ट';

  @override
  String get dashboardRecentCollections => 'हाल के संग्रह';

  @override
  String get dashboardRecentCollectionsSubtitle => 'नवीनतम भुगतान प्राप्त हुए';

  @override
  String get dashboardNoCollectionsToday => 'आज के लिए कोई संग्रह नहीं मिला।';

  @override
  String get dashboardRecentLoans => 'हाल के ऋण';

  @override
  String get dashboardRecentLoansSubtitle => 'नए वितरित ऋण';

  @override
  String get dashboardNoLoansToday => 'आज के लिए कोई नया ऋण नहीं मिला।';

  @override
  String get dashboardViewAll => 'सभी देखें';

  @override
  String get loansTitle => 'ऋण';

  @override
  String get loansSubtitle => 'ग्राहक ऋण और भुगतान अनुसूचियां प्रबंधित करें';

  @override
  String get loansCreateButton => 'ऋण बनाएं';

  @override
  String get loansSearchHint => 'ग्राहक या ऋण संख्या से खोजें...';

  @override
  String get loansFilterAll => 'सभी';

  @override
  String get loansStatusActive => 'सक्रिय';

  @override
  String get loansStatusOverdue => 'अतिदेय';

  @override
  String get loansStatusClosed => 'बंद';

  @override
  String get loansStatusPending => 'लंबित';

  @override
  String get loansScheduleStatusPaid => 'भुगतान किया गया';

  @override
  String get loansScheduleStatusDueToday => 'आज देय';

  @override
  String get loansTypeMonthlyEmi => 'मासिक EMI';

  @override
  String get loansTypeMonthlyInterest => 'मासिक ब्याज';

  @override
  String get loansTypeWeekly => 'साप्ताहिक';

  @override
  String get loansTypeDaily => 'दैनिक';

  @override
  String get loansScheduleEmptyMessage => 'भुगतान अनुसूची उपलब्ध नहीं है।';

  @override
  String get loansScheduleColIndex => 'क्रम';

  @override
  String get loansScheduleColDueDate => 'देय तिथि';

  @override
  String get loansScheduleColEmi => 'EMI';

  @override
  String get loansScheduleColPaid => 'भुगतान';

  @override
  String get loansScheduleColBalance => 'शेष';

  @override
  String get loansScheduleColStatus => 'स्थिति';

  @override
  String loansCouldNotLoad(String error) {
    return 'ऋण लोड नहीं हो सके: $error';
  }

  @override
  String get loansLoanCreatedTitle => 'ऋण बनाया गया';

  @override
  String get loansLoanUpdatedTitle => 'ऋण अपडेट किया गया';

  @override
  String get loansCloseLoanTitle => 'ऋण बंद करें';

  @override
  String loansCloseLoanMessage(String loanNumber) {
    return 'क्या आप ऋण $loanNumber बंद करना चाहते हैं?';
  }

  @override
  String get loansCloseLoanConfirm => 'बंद करें';

  @override
  String get loansLoanClosedTitle => 'ऋण बंद किया गया';

  @override
  String loansLoanClosedMessage(String loanNumber) {
    return 'ऋण $loanNumber सफलतापूर्वक बंद किया गया।';
  }

  @override
  String get loansCloseFailedTitle => 'बंद करना विफल';

  @override
  String get loansCloseBlockedTitle => 'ऋण बंद नहीं किया जा सकता';

  @override
  String loansCloseBlockedMessage(String amount) {
    return 'इस ऋण में अभी भी $amount बकाया है। बंद करने से पहले पूरी बकाया राशि वसूल करें।';
  }

  @override
  String get loansDeleteLoanTitle => 'ऋण हटाएं';

  @override
  String loansDeleteLoanMessage(String loanNumber) {
    return 'क्या आप ऋण $loanNumber हटाना चाहते हैं? इसे रीसायकल बिन में भेजा जाएगा।';
  }

  @override
  String get loansDeleteLoanConfirm => 'हटाएं';

  @override
  String get loansLoanDeletedTitle => 'ऋण हटाया गया';

  @override
  String loansLoanDeletedMessage(String loanNumber) {
    return 'ऋण $loanNumber रीसायकल बिन में भेजा गया।';
  }

  @override
  String get loansDeleteFailedTitle => 'हटाना विफल';

  @override
  String get loansNoLoansFound => 'कोई ऋण नहीं मिला';

  @override
  String get loansColHpNo => 'HP नंबर';

  @override
  String get loansColCustomer => 'ग्राहक';

  @override
  String get loansColType => 'प्रकार';

  @override
  String get loansColAmount => 'राशि';

  @override
  String get loansColEmi => 'EMI';

  @override
  String get loansColOutstanding => 'बकाया';

  @override
  String get loansColAgent => 'एजेंट';

  @override
  String get loansColStatus => 'स्थिति';

  @override
  String get loansColStart => 'आरंभ तिथि';

  @override
  String get loansColActions => 'कार्रवाइयां';

  @override
  String get loansActionView => 'देखें';

  @override
  String get loansActionEdit => 'संपादित करें';

  @override
  String get loansActionClose => 'बंद करें';

  @override
  String get loansActionDelete => 'मिटाएँ';

  @override
  String loansDurationWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count हफ्ते',
      one: '1 हफ्ता',
    );
    return '$_temp0';
  }

  @override
  String loansDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन',
      one: '1 दिन',
    );
    return '$_temp0';
  }

  @override
  String loansDurationMonthsInterestOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count महीने (केवल ब्याज़)',
      one: '1 महीना (केवल ब्याज़)',
    );
    return '$_temp0';
  }

  @override
  String loansDurationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count महीने',
      one: '1 महीना',
    );
    return '$_temp0';
  }

  @override
  String loansDetailTitle(String loanNumber) {
    return 'लोन $loanNumber';
  }

  @override
  String get loansFieldCustomer => 'ग्राहक';

  @override
  String get loansFieldLoanType => 'लोन का प्रकार';

  @override
  String get loansFieldLoanAmount => 'लोन राशि';

  @override
  String get loansFieldMonthlyInterest => 'मासिक ब्याज़';

  @override
  String get loansFieldEmi => 'ईएमआई';

  @override
  String get loansFieldOutstanding => 'बकाया राशि';

  @override
  String get loansFieldPenalty => 'जुर्माना';

  @override
  String get loansFieldTotalDuePenalty => 'कुल देय (जुर्माने के साथ)';

  @override
  String get loansFieldInterest => 'ब्याज़ दर';

  @override
  String get loansFieldDuration => 'अवधि';

  @override
  String get loansFieldStartDate => 'शुरू होने की तारीख';

  @override
  String get loansFieldAgent => 'एजेंट';

  @override
  String get loansHideSchedule => 'शेड्यूल छिपाएँ';

  @override
  String get loansShowSchedule => 'शेड्यूल दिखाएँ';

  @override
  String get loansRepaymentSchedule => 'पुनर्भुगतान शेड्यूल';

  @override
  String get loansRefreshScheduleTooltip => 'शेड्यूल रीफ़्रेश करें';

  @override
  String get loansInterestOnlyScheduleNote =>
      'यह केवल ब्याज़ वाला लोन है। मूलधन का पुनर्भुगतान लचीला है और नीचे दिए गए शेड्यूल में नहीं दर्शाया गया है।';

  @override
  String get loansCustomerRequiredTitle => 'ग्राहक आवश्यक है';

  @override
  String get loansCustomerRequiredMessage =>
      'इस लोन को सहेजने से पहले कृपया एक ग्राहक चुनें।';

  @override
  String get loansSaveFailedTitle => 'सहेजने में विफल';

  @override
  String get loansEditTitle => 'लोन संपादित करें';

  @override
  String get loansCreateTitle => 'लोन बनाएँ';

  @override
  String get loansHpNumberLabel => 'एचपी नंबर';

  @override
  String get loansHpNumberLoading => 'जनरेट हो रहा है…';

  @override
  String get loansHpNumberAuto => 'स्वचालित रूप से जनरेट किया गया';

  @override
  String get loansProcessingFeeLabel => 'प्रोसेसिंग शुल्क';

  @override
  String get loansProcessingFeeHint => 'प्रोसेसिंग शुल्क दर्ज करें';

  @override
  String get loansNotesLabel => 'नोट्स';

  @override
  String get loansNotesHint => 'कोई अतिरिक्त नोट्स जोड़ें';

  @override
  String get loansSave => 'सहेजें';

  @override
  String get loansApprove => 'मंज़ूर करें';

  @override
  String get loansCustomerRequiredLabel => 'ग्राहक *';

  @override
  String get loansCustomerHint => 'ग्राहक खोजें';

  @override
  String get loansAgentLabel => 'एजेंट';

  @override
  String get loansAgentHint => 'एजेंट खोजें';

  @override
  String get loansCollectionTypeLabel => 'संग्रह का प्रकार';

  @override
  String get loansLoanAmountLabel => 'लोन राशि';

  @override
  String get loansLoanAmountHint => 'लोन राशि दर्ज करें';

  @override
  String get loansInterestRateMonthlyLabel => 'मासिक ब्याज़ दर (%)';

  @override
  String get loansInterestRateHint25 => 'उदाहरण: 2.5';

  @override
  String get loansDurationMonthsLabel => 'अवधि (महीने)';

  @override
  String get loansDurationHint10 => 'उदाहरण: 10';

  @override
  String get loansMonthlyInterestRateLabel => 'मासिक ब्याज़ दर (%)';

  @override
  String get loansLoanTenureLabel => 'लोन अवधि (महीने)';

  @override
  String get loansInterestRateLabel => 'ब्याज़ दर (%)';

  @override
  String get loansDurationFixedLabel => 'अवधि';

  @override
  String get loansDurationWeeksFixed => '10 हफ्ते (निश्चित)';

  @override
  String get loansCollectionPlanLabel => 'संग्रह योजना';

  @override
  String get loansPlan60Days => '60 दिन';

  @override
  String get loansPlan100Days => '100 दिन';

  @override
  String get loansInterestOnlyBoxTitle => 'केवल ब्याज़ वाला लोन';

  @override
  String get loansInterestOnlyBoxBody =>
      'उधारकर्ता केवल मासिक ब्याज़ का भुगतान करता है। मूलधन का भुगतान कभी भी किया जा सकता है और यह निश्चित शेड्यूल का हिस्सा नहीं है।';

  @override
  String get loansWeeklyPenaltyTitle => 'साप्ताहिक जुर्माना';

  @override
  String get loansDailyPenaltyTitle => 'दैनिक जुर्माना';

  @override
  String get loansWeeklyPenaltyHelper =>
      'छूटे हुए साप्ताहिक भुगतानों के लिए एक निश्चित जुर्माना लागू करें।';

  @override
  String get loansDailyPenaltyHelper =>
      'देय शेष राशि पर दैनिक जुर्माना दर लागू करें।';

  @override
  String get loansDailyPenaltyRateLabel => 'जुर्माना दर / दिन';

  @override
  String get loansDailyPenaltyRateHint => 'उदाहरण: 50';

  @override
  String get loansDailyPenaltyExample =>
      'किसी भी अतिदेय शेष राशि पर दैनिक रूप से लागू होता है।';

  @override
  String get loansWeeklyPenaltyAmountLabel => 'जुर्माना राशि / हफ्ता';

  @override
  String get loansWeeklyPenaltyAmountHint => 'उदाहरण: 100';

  @override
  String get loansWeeklyPenaltyAutoNote =>
      'हर उस हफ़्ते स्वचालित रूप से लागू होता है जब भुगतान छूट जाता है।';

  @override
  String get loansSummaryMonthlyEmi => 'मासिक ईएमआई';

  @override
  String loansSummaryPerMonth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count महीनों के लिए',
      one: '1 महीने के लिए',
    );
    return '$_temp0';
  }

  @override
  String get loansSummaryTotalInterest => 'कुल ब्याज़';

  @override
  String loansSummaryPerMonthAmount(String amount) {
    return '$amount प्रति माह';
  }

  @override
  String get loansSummaryTotalRepayment => 'कुल पुनर्भुगतान';

  @override
  String get loansSummaryPrincipalPlusInterest => 'मूलधन + ब्याज़';

  @override
  String get loansSummaryMonthlyInterestDue => 'मासिक देय ब्याज़';

  @override
  String loansSummaryRateOfPrincipal(String rate, String principal) {
    return '$principal का $rate%';
  }

  @override
  String get loansSummaryPrincipalRepayment => 'मूलधन चुकौती';

  @override
  String get loansSummaryFlexibleInstallments => 'लचीली';

  @override
  String get loansSummaryRepayAnytime => 'मूलधन कभी भी चुकाएँ';

  @override
  String get loansSummaryPrincipalDisbursed => 'वितरित मूलधन';

  @override
  String loansSummaryTenureMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count महीनों से अधिक',
      one: '$count महीने से अधिक',
    );
    return '$_temp0';
  }

  @override
  String get loansSummaryWeeklyInstallment => 'साप्ताहिक किश्त';

  @override
  String loansSummaryWeeksEqual(String principal) {
    return '10 सप्ताह कुल $principal';
  }

  @override
  String get loansSummaryInterestDeducted => 'काटा गया ब्याज';

  @override
  String get loansSummaryDeductedUpfront => 'पहले ही काटा गया';

  @override
  String get loansSummaryAmountDisbursed => 'वितरित राशि';

  @override
  String get loansSummaryPrincipalMinusInterest => 'मूलधन − ब्याज';

  @override
  String get loansSummaryDailyInstallment => 'दैनिक किश्त';

  @override
  String loansSummaryDaysEqual(int days, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन कुल $total',
      one: '$days दिन कुल $total',
    );
    return '$_temp0';
  }

  @override
  String get loansSummaryInterestAdded => 'जोड़ा गया ब्याज';

  @override
  String get loansSummaryAddedToRepayment => 'कुल चुकौती में जोड़ा गया';

  @override
  String get loansSummaryAmountDisbursedToBorrower =>
      'ऋण लेने वाले को वितरित राशि';

  @override
  String get loansSummaryFullLoanAmount => 'पूर्ण ऋण राशि';

  @override
  String get loansScheduleSectionTitle => 'चुकौती अनुसूची का पूर्वावलोकन';

  @override
  String get loansStartDateLabel => 'आरंभ तिथि';

  @override
  String get loansStartDateHint => 'DD/MM/YYYY';

  @override
  String get repaymentTitle => 'चुकौती अनुसूची';

  @override
  String get repaymentSubtitle =>
      'किस्त-वार ईएमआई संग्रह और बकाया शेष को ट्रैक करें';

  @override
  String get repaymentCouldNotLoadLoans => 'ऋण लोड नहीं किए जा सके';

  @override
  String get repaymentLoanLoadFailedTitle => 'ऋण लोड करने में विफल';

  @override
  String get repaymentCouldNotLoadSchedule =>
      'चुकौती अनुसूची लोड नहीं की जा सकी';

  @override
  String get repaymentLoadFailedTitle => 'लोड करने में विफल';

  @override
  String get repaymentSelectLoanLabel => 'ऋण चुनें';

  @override
  String get repaymentSelectLoanHint => 'ऋण चुनें';

  @override
  String get repaymentLoanSwitchedTitle => 'ऋण बदला गया';

  @override
  String get repaymentInstallmentBreakdown => 'किस्त का विवरण';

  @override
  String get repaymentNoInstallmentsFound => 'इस ऋण के लिए कोई किस्त नहीं मिली';

  @override
  String get repaymentStatLoanNumber => 'ऋण संख्या';

  @override
  String get repaymentStatCustomer => 'ग्राहक';

  @override
  String get repaymentStatLoanAmount => 'ऋण राशि';

  @override
  String get repaymentStatEmi => 'ईएमआई';

  @override
  String get repaymentStatTotalRepayment => 'कुल चुकौती';

  @override
  String get repaymentStatOutstanding => 'बकाया';

  @override
  String get repaymentStatPenalty => 'जुर्माना';

  @override
  String get repaymentStatTotalDuePenalty => 'कुल देय + जुर्माना';

  @override
  String get repaymentStatTotalInstallments => 'कुल किस्तें';

  @override
  String get repaymentStatPaid => 'भुगतान किया गया';

  @override
  String get repaymentStatPending => 'लंबित';

  @override
  String get repaymentStatOverdue => 'अतिदेय';

  @override
  String get repaymentStatNextDue => 'अगली देय तिथि';

  @override
  String get repaymentColInstNo => 'किस्त संख्या';

  @override
  String get repaymentColDueDate => 'देय तिथि';

  @override
  String get repaymentColEmiAmount => 'ईएमआई राशि';

  @override
  String get repaymentColPaid => 'भुगतान किया गया';

  @override
  String get repaymentColBalance => 'शेष';

  @override
  String get repaymentColPenalty => 'जुर्माना';

  @override
  String get repaymentColStatus => 'स्थिति';

  @override
  String get repaymentNoLoanSelected => 'कोई ऋण चयनित नहीं';

  @override
  String repaymentPenaltyBannerTitle(String type, String duration) {
    return '$type फाइनेंस ($duration)';
  }

  @override
  String get repaymentPenaltyBannerWeeklyBody =>
      'हर छूटी हुई साप्ताहिक किस्त पर प्रति ₹10,000 मूलधन पर स्वतः ₹100 का जुर्माना लगाया जाता है।';

  @override
  String repaymentPenaltyBannerRateBody(String rate) {
    return 'भुगतान के अतिदेय रहने के हर दिन के लिए $rate प्रतिदिन जुर्माना लगाया जाता है।';
  }

  @override
  String repaymentAccruedPenaltyLabel(String amount) {
    return 'संचित जुर्माना: $amount';
  }

  @override
  String repaymentDurationWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सप्ताह',
      one: '1 सप्ताह',
    );
    return '$_temp0';
  }

  @override
  String repaymentDurationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count महीने',
      one: '1 महीना',
    );
    return '$_temp0';
  }

  @override
  String repaymentDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन',
      one: '1 दिन',
    );
    return '$_temp0';
  }

  @override
  String get repaymentRecordCollectionButton => 'संग्रह दर्ज करें';

  @override
  String get repaymentRecordCollectionSheetTitle => 'संग्रह दर्ज करें';

  @override
  String repaymentRecordCollectionSubtitle(String loanNumber, String customer) {
    return '$loanNumber — $customer';
  }

  @override
  String get repaymentRecordCollectionInstallmentLabel => 'किस्त';

  @override
  String get repaymentRecordCollectionGeneralPayment => 'सामान्य भुगतान';

  @override
  String get repaymentRecordCollectionAmountLabel => 'राशि';

  @override
  String get repaymentRecordCollectionMethodLabel => 'भुगतान का तरीका';

  @override
  String get repaymentRecordCollectionDateLabel => 'भुगतान तिथि';

  @override
  String get repaymentRecordCollectionNotesLabel => 'टिप्पणी (वैकल्पिक)';

  @override
  String get repaymentRecordCollectionNotesHint =>
      'इस भुगतान के बारे में एक टिप्पणी जोड़ें';

  @override
  String get repaymentRecordCollectionSubmit => 'संग्रह सहेजें';

  @override
  String get repaymentRecordCollectionCancel => 'रद्द करें';

  @override
  String get repaymentRecordCollectionAllPaidTitle => 'सभी भुगतान पूर्ण';

  @override
  String get repaymentRecordCollectionAllPaidMessage =>
      'इस ऋण की सभी किस्तें पहले ही चुकाई जा चुकी हैं।';

  @override
  String get repaymentRecordCollectionSuccessTitle => 'संग्रह दर्ज किया गया';

  @override
  String get repaymentRecordCollectionFailedTitle =>
      'संग्रह दर्ज नहीं किया जा सका';

  @override
  String get repaymentRecordCollectionSelectLoanFirst => 'पहले एक ऋण चुनें';

  @override
  String get repaymentRecordCollectionAmountRequired =>
      'एक मान्य राशि दर्ज करें';

  @override
  String get collectionsLoadFailedTitle => 'संग्रह लोड करने में विफल';

  @override
  String get collectionsTitle => 'संग्रह';

  @override
  String get collectionsSubtitle =>
      'सभी ऋणों पर दैनिक संग्रह रिकॉर्ड करें और ट्रैक करें';

  @override
  String get collectionsAddButton => 'संग्रह जोड़ें';

  @override
  String get collectionsStatTodayTotal => 'आज का कुल';

  @override
  String get collectionsStatThisWeek => 'इस सप्ताह';

  @override
  String get collectionsStatThisMonth => 'इस महीने';

  @override
  String get collectionsStatTotalRecords => 'कुल रिकॉर्ड';

  @override
  String get collectionsSearchHint => 'ग्राहक, ऋण या रसीद संख्या खोजें...';

  @override
  String get collectionsPeriodToday => 'आज';

  @override
  String get collectionsPeriodThisWeek => 'इस सप्ताह';

  @override
  String get collectionsPeriodThisMonth => 'इस महीने';

  @override
  String get collectionsColCustomer => 'ग्राहक';

  @override
  String get collectionsColLoanNumber => 'ऋण संख्या';

  @override
  String get collectionsColAmount => 'राशि';

  @override
  String get collectionsColMethod => 'तरीका';

  @override
  String get collectionsColDate => 'तिथि';

  @override
  String get collectionsColAgent => 'एजेंट';

  @override
  String get collectionsColActions => 'कार्य';

  @override
  String get collectionsActionEdit => 'संपादित करें';

  @override
  String get collectionsActionDelete => 'हटाएँ';

  @override
  String get collectionsNoneFound => 'कोई संग्रह नहीं मिला';

  @override
  String get collectionsShowLess => 'कम दिखाएँ';

  @override
  String collectionsShowMore(int count) {
    return 'और दिखाएँ ($count और)';
  }

  @override
  String get collectionsDeleteTitle => 'संग्रह हटाएँ';

  @override
  String collectionsDeleteMessage(String customer, String receipt) {
    return '$customer ($receipt) के लिए संग्रह रिकॉर्ड हटाएँ? इसे रीसायकल बिन में ले जाया जाएगा और बाद में पुनर्स्थापित किया जा सकता है।';
  }

  @override
  String get collectionsDeleteFailedTitle => 'हटाने में विफल';

  @override
  String get collectionsUpdateFailedTitle => 'अपडेट करने में विफल';

  @override
  String get collectionsRecordIdNotFound => 'रिकॉर्ड आईडी नहीं मिली';

  @override
  String get collectionsDeletedTitle => 'संग्रह हटाया गया';

  @override
  String get collectionsDeleteApiFailedTitle => 'संग्रह हटाने में विफल';

  @override
  String get collectionsRecordedTitle => 'संग्रह दर्ज किया गया';

  @override
  String get collectionsSaveFailedTitle => 'संग्रह सहेजने में विफल';

  @override
  String get collectionsUpdatedTitle => 'संग्रह अपडेट किया गया';

  @override
  String get collectionsUpdateApiFailedTitle => 'संग्रह अपडेट करने में विफल';

  @override
  String get collectionsMethodCash => 'नकद';

  @override
  String get collectionsMethodUpi => 'यूपीआई';

  @override
  String get collectionsMethodBank => 'बैंक हस्तांतरण';

  @override
  String get collectionsMethodCheque => 'चेक';

  @override
  String get collectionsMethodCard => 'कार्ड';

  @override
  String get collectionsSelectCustomerTitle => 'एक ग्राहक चुनें';

  @override
  String get collectionsSelectCustomerMessage =>
      'कृपया सहेजने से पहले एक ग्राहक चुनें।';

  @override
  String get collectionsEditTitle => 'संग्रह संपादित करें';

  @override
  String get collectionsCustomerRequiredLabel => 'ग्राहक *';

  @override
  String get collectionsSelectCustomerHint => 'ग्राहक चुनें';

  @override
  String get collectionsLoanNumberLabel => 'ऋण संख्या';

  @override
  String get collectionsSelectCustomerFirstHint => 'पहले ग्राहक चुनें';

  @override
  String get collectionsSelectLoanHint => 'ऋण चुनें';

  @override
  String get collectionsOutstandingAbbrev => 'बकाया';

  @override
  String get collectionsSelectLoanPrompt =>
      'उसके लाइव विवरण देखने के लिए एक ऋण चुनें';

  @override
  String collectionsLoansLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ऋण चुने गए ग्राहक से जुड़े हुए हैं',
    );
    return '$_temp0';
  }

  @override
  String get collectionsAmountReceivedLabel => 'प्राप्त राशि *';

  @override
  String get collectionsPaymentMethodLabel => 'भुगतान विधि *';

  @override
  String get collectionsCollectionDateLabel => 'संग्रह तिथि *';

  @override
  String get collectionsSelectAgentHint => 'एजेंट चुनें';

  @override
  String get collectionsNotesLabel => 'टिप्पणियाँ';

  @override
  String get collectionsNotesHint => 'इस संग्रह के बारे में कोई टिप्पणी...';

  @override
  String get collectionsPaymentScreenshotLabel => 'भुगतान का स्क्रीनशॉट';

  @override
  String get collectionsCustomerSignatureLabel => 'ग्राहक के हस्ताक्षर';

  @override
  String get collectionsCancelButton => 'रद्द करें';

  @override
  String get collectionsReceiptButton => 'रसीद';

  @override
  String get collectionsUpdateButton => 'अपडेट करें';

  @override
  String get collectionsSaveButton => 'सहेजें';

  @override
  String get collectionsGeneratingReceiptTitle => 'रसीद जनरेट हो रही है...';

  @override
  String get collectionsUploadSignatureTitle => 'ग्राहक के हस्ताक्षर जोड़ें';

  @override
  String get collectionsUploadScreenshotTitle =>
      'भुगतान का स्क्रीनशॉट अपलोड करें';

  @override
  String get collectionsUploadPlaceholder => 'दस्तावेज़ अपलोड करें...';

  @override
  String collectionsSummaryAgent(String name) {
    return 'एजेंट: $name';
  }

  @override
  String collectionsSummaryPrincipal(String amount) {
    return 'मूलधन: $amount';
  }

  @override
  String collectionsSummaryInstallment(String amount) {
    return 'किस्त: $amount';
  }

  @override
  String collectionsSummaryOutstanding(String amount) {
    return 'बकाया: $amount';
  }

  @override
  String collectionsSummaryOverdueDue(String amount) {
    return 'देय अतिदेय: $amount';
  }

  @override
  String collectionsSummaryPenalty(String amount) {
    return 'जुर्माना: $amount';
  }

  @override
  String collectionsSummaryTotalDue(String amount) {
    return 'कुल देय: $amount';
  }

  @override
  String get collectionsPresetOneEmi => '1 ईएमआई';

  @override
  String get collectionsPresetFillInterest => 'ब्याज भरें';

  @override
  String get collectionsPresetPayDue => 'देय राशि का भुगतान करें';

  @override
  String get collectionsPresetPrincipalPartPayment => 'मूलधन का आंशिक भुगतान';

  @override
  String get collectionsPresetFullBalance => 'पूरा शेष';

  @override
  String get collectionsPurposeMonthlyInterest => 'मासिक ब्याज भुगतान';

  @override
  String collectionsPaymentSummaryLine(String payment, String remaining) {
    return 'भुगतान: $payment • शेष राशि: $remaining';
  }

  @override
  String get handoverLoadFailedTitle => 'हैंडओवर डेटा लोड करने में विफल';

  @override
  String get handoverUpdatedTitle => 'हैंडओवर अपडेट किया गया';

  @override
  String get handoverRecordedTitle => 'हैंडओवर रिकॉर्ड किया गया';

  @override
  String get handoverFailedTitle => 'हैंडओवर विफल';

  @override
  String get handoverMarkedPendingTitle => 'लंबित के रूप में चिह्नित किया गया';

  @override
  String get handoverMarkedVerifiedTitle =>
      'सत्यापित के रूप में चिह्नित किया गया';

  @override
  String get handoverUpdateFailedTitle => 'हैंडओवर अपडेट नहीं हो सका';

  @override
  String get handoverDeletedTitle => 'हैंडओवर हटाया गया';

  @override
  String get handoverDeleteFailedTitle => 'हैंडओवर हटाया नहीं जा सका';

  @override
  String get handoverTitle => 'नकद हैंडओवर';

  @override
  String get handoverSubtitle =>
      'एजेंट एकत्रित नकद और यूपीआई को कार्यालय में जमा करते हैं — लंबित राशि आगे बढ़ती है';

  @override
  String get handoverRecordButton => 'हैंडओवर रिकॉर्ड करें';

  @override
  String get handoverStatTotalCollected => 'कुल एकत्रित';

  @override
  String get handoverStatTodayZero => 'आज: ₹0';

  @override
  String get handoverStatHandedOver => 'हैंडओवर किया गया';

  @override
  String get handoverStatPending => 'लंबित';

  @override
  String get handoverStatAgentsWithPending => 'लंबित वाले एजेंट';

  @override
  String get handoverSettlementPositionTitle => 'एजेंट निपटान स्थिति';

  @override
  String get handoverSettlementPositionSubtitle =>
      'लंबित = एकत्रित − हैंडओवर किया गया (लगातार चलता रहता है)';

  @override
  String get handoverHistoryTitle => 'हैंडओवर इतिहास';

  @override
  String get handoverHistoryEmpty =>
      'अभी तक कोई हैंडओवर रिकॉर्ड नहीं किया गया है।';

  @override
  String get handoverColAgent => 'एजेंट';

  @override
  String get handoverColCollected => 'एकत्रित';

  @override
  String get handoverColHandedOver => 'हैंडओवर किया गया';

  @override
  String get handoverColPending => 'लंबित';

  @override
  String get handoverDeleteConfirmTitle => 'हैंडओवर हटाएँ?';

  @override
  String handoverDeleteConfirmMessage(String agentName, String amount) {
    return '$agentName का $amount का हैंडओवर रिकॉर्ड रीसायकल बिन में चला जाएगा और बाद में बहाल किया जा सकता है।';
  }

  @override
  String get handoverDeleteButton => 'हटाएँ';

  @override
  String get handoverStatusVerified => 'सत्यापित';

  @override
  String get handoverStatusPending => 'लंबित';

  @override
  String get handoverReceivedLabel => 'प्राप्त हुआ';

  @override
  String get handoverEditButton => 'संपादित करें';

  @override
  String get handoverUnverifyButton => 'अपुष्ट करें';

  @override
  String get handoverVerifyButton => 'सत्यापित करें';

  @override
  String handoverSummaryLine(String date, String cash, String upi) {
    return '$date · $cash नकद · $upi यूपीआई';
  }

  @override
  String get handoverSelectAgentValidator => 'एक एजेंट चुनें';

  @override
  String get handoverCashAmountLabel => 'नकद राशि';

  @override
  String get handoverUpiAmountLabel => 'यूपीआई राशि';

  @override
  String get handoverNotesLabel => 'नोट्स';

  @override
  String get handoverNotesHint => 'वैकल्पिक टिप्पणियाँ';

  @override
  String get handoverDateLabel => 'दिनांक *';

  @override
  String get handoverRecordActionButton => 'रिकॉर्ड करें';

  @override
  String get handoverSaveButton => 'सहेजें';

  @override
  String get handoverCancelButton => 'रद्द करें';

  @override
  String get handoverRefreshButton => 'रीफ्रेश करें';

  @override
  String handoverStatToday(String amount) {
    return 'आज: $amount';
  }

  @override
  String get handoverStatPendingToHandOver => 'सौंपना बाकी है';

  @override
  String get handoverStatCashCollected => 'नकद एकत्रित';

  @override
  String get handoverStatOnlineUpi => 'ऑनलाइन / UPI';

  @override
  String handoverStillPendingBanner(String amount) {
    return 'आपको अभी भी $amount सौंपना बाकी है। यह शेष राशि आगे बढ़ती रहती है — जब तक आप निपटान नहीं करते, कल के संग्रह इसमें और जुड़ते जाएंगे।';
  }

  @override
  String get accountBookSubtitle =>
      'हाथ में नकदी और बकाया उधार दिए गए धन को ट्रैक करें';

  @override
  String get accountTabAllEntries => 'सभी प्रविष्टियाँ';

  @override
  String get accountTabCashInHand => 'हाथ में नकदी';

  @override
  String get accountTabOutstandingLent => 'बकाया उधार';

  @override
  String get accountAddEntryButton => 'प्रविष्टि जोड़ें';

  @override
  String get accountAddCashEntryButton => 'नकद प्रविष्टि जोड़ें';

  @override
  String get accountAddMoneyLentButton => 'उधार पैसे जोड़ें';

  @override
  String get accountEntrySavedTitle => 'प्रविष्टि सहेजी गई';

  @override
  String get accountEntrySavedMessage =>
      'खाता बही की प्रविष्टि सफलतापूर्वक जोड़ दी गई है।';

  @override
  String get accountEntryUpdatedTitle => 'प्रविष्टि अपडेट की गई';

  @override
  String get accountEntryUpdatedMessage =>
      'खाता बही की प्रविष्टि सफलतापूर्वक अपडेट कर दी गई है।';

  @override
  String get accountEntryDeletedTitle => 'प्रविष्टि हटाई गई';

  @override
  String get accountEntryDeletedMessage =>
      'खाता बही की प्रविष्टि हटा दी गई है।';

  @override
  String get accountDeleteFailedTitle => 'हटाने में विफल';

  @override
  String accountDeleteConfirmMessage(String title) {
    return 'क्या आप निश्चित हैं कि आप \"$title\" हटाना चाहते हैं? इस क्रिया को पूर्ववत नहीं किया जा सकता है।';
  }

  @override
  String get accountNetBalanceSummaryTitle => 'शुद्ध शेष सारांश';

  @override
  String get accountCashInHandLabel => 'हाथ में नकदी';

  @override
  String get accountOutstandingLabel => 'बकाया उधार दिया गया धन';

  @override
  String get accountNetBalanceLabel => 'शुद्ध शेष';

  @override
  String get accountUpdatingBadge => 'अपडेट हो रहा है...';

  @override
  String get accountLiveBadge => 'लाइव';

  @override
  String accountSummaryRefreshError(String error) {
    return 'सारांश रीफ्रेश नहीं हो सका: $error';
  }

  @override
  String get accountCashInHandSubtitle => 'उपलब्ध कुल तरल नकदी';

  @override
  String get accountBreakdownLoanCollection => 'ऋण संग्रह';

  @override
  String get accountBreakdownFundDeposits => 'फंड जमा';

  @override
  String get accountBreakdownChitCollection => 'चिट संग्रह';

  @override
  String get accountBreakdownCustomCashNet => 'कस्टम नकद प्रविष्टियाँ';

  @override
  String get accountOutstandingMoneyTitle => 'बकाया राशि';

  @override
  String get accountOutstandingMoneySubtitle => 'आपको देय कुल राशि';

  @override
  String get accountBreakdownLoanOutstanding => 'ऋण बकाया';

  @override
  String get accountBreakdownChitPending => 'चिट लंबित';

  @override
  String get accountBreakdownFundPending => 'फंड लंबित';

  @override
  String get accountBreakdownCustomMoneyLent => 'कस्टम उधार पैसा';

  @override
  String get accountSearchHint => 'शीर्षक या श्रेणी के अनुसार खोजें...';

  @override
  String get accountLoadFailedTitle => 'प्रविष्टियां लोड करने में विफल';

  @override
  String get accountEmptyStateTitle => 'अभी तक कोई प्रविष्टियां नहीं';

  @override
  String get accountEmptyStateBody =>
      'अपनी खाता बही को ट्रैक करना शुरू करने के लिए अपनी पहली नकद या उधार प्रविष्टि जोड़ें।';

  @override
  String get accountColDate => 'दिनांक';

  @override
  String get accountColTitle => 'शीर्षक';

  @override
  String get accountColCategory => 'श्रेणी';

  @override
  String get accountColSection => 'अनुभाग';

  @override
  String get accountColType => 'प्रकार';

  @override
  String get accountColAmount => 'राशि';

  @override
  String get accountColActions => 'कार्यवाहियाँ';

  @override
  String get accountMissingTitleTitle => 'शीर्षक आवश्यक है';

  @override
  String get accountMissingTitleMessage =>
      'कृपया इस प्रविष्टि के लिए एक शीर्षक दर्ज करें।';

  @override
  String get accountInvalidDateTitle => 'अमान्य दिनांक';

  @override
  String get accountInvalidDateMessage =>
      'कृपया dd/mm/yyyy प्रारूप में एक वैध दिनांक दर्ज करें।';

  @override
  String get accountUpdateFailedTitle => 'अपडेट विफल';

  @override
  String get accountSaveFailedTitle => 'सहेजने में विफल';

  @override
  String get accountEditEntryTitle => 'प्रविष्टि संपादित करें';

  @override
  String get accountAddEntryTitle => 'प्रविष्टि जोड़ें';

  @override
  String get accountEntryTitleLabel => 'शीर्षक';

  @override
  String get accountEntryTitleHint => 'उदा. कार्यालय किराया, नकद जमा';

  @override
  String get accountEntryTypeLabel => 'प्रविष्टि का प्रकार';

  @override
  String get accountAmountLabel => 'राशि';

  @override
  String get accountAmountHint => '0.00';

  @override
  String get accountCategoryLabel => 'श्रेणी';

  @override
  String get accountEntryDateLabel => 'दिनांक';

  @override
  String get accountEntryDateHint => 'dd/mm/yyyy';

  @override
  String get accountNotesLabel => 'नोट्स';

  @override
  String get accountNotesHint => 'इस प्रविष्टि के बारे में वैकल्पिक नोट्स';

  @override
  String get accountUpdateEntryButton => 'प्रविष्टि अपडेट करें';

  @override
  String get accountSaveEntryButton => 'प्रविष्टि सहेजें';

  @override
  String get overdueManagementTitle => 'बकाया प्रबंधन';

  @override
  String get overdueSubtitle =>
      'बकाया ऋण खातों को ट्रैक करें और उन पर कार्रवाई करें';

  @override
  String overdueCountBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बकाया',
      one: '$count बकाया',
    );
    return '$_temp0';
  }

  @override
  String get overdueStatTotalLabel => 'कुल बकाया';

  @override
  String get overdueStatTotalSub => 'खाते';

  @override
  String get overdueStatAmountLabel => 'बकाया राशि';

  @override
  String get overdueStatAmountSub => 'बकाया';

  @override
  String get overdueStatAvgDaysLabel => 'औसत बकाया दिन';

  @override
  String overdueStatAvgDaysValue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन',
      one: '$days दिन',
    );
    return '$_temp0';
  }

  @override
  String get overdueStatAvgDaysSub => 'सभी खातों में';

  @override
  String get overdueStatCriticalLabel => 'गंभीर (>30 दिन)';

  @override
  String get overdueStatCriticalSub => 'ध्यान देने की आवश्यकता है';

  @override
  String get overdueSearchHint => 'ग्राहक या ऋण संख्या खोजें...';

  @override
  String get overdueFilterAll => 'सभी बकाया';

  @override
  String get overdueFilterCritical => 'गंभीर (>30 दिन)';

  @override
  String get overdueNoMatchMessage =>
      'आपकी खोज से कोई बकाया खाता मेल नहीं खाता।';

  @override
  String get overdueNoPhoneTitle => 'कोई फ़ोन नंबर नहीं';

  @override
  String get overdueNoPhoneMessage =>
      'इस बकाया खाते में अभी तक कोई मोबाइल नंबर नहीं है।';

  @override
  String get overdueSendMessageTitle => 'संदेश रिमाइंडर भेजें';

  @override
  String overdueSendMessageBody(String name, String phone) {
    return '$name के लिए WhatsApp खोलें?\n$phone';
  }

  @override
  String get overdueSendLabel => 'भेजें';

  @override
  String overdueWhatsappTemplate(
      String name, String loanNumber, int days, String amount) {
    return 'नमस्ते $name, आपका ऋण $loanNumber, $days दिनों से बकाया है। कृपया बकाया राशि $amount का भुगतान करने के लिए हमसे संपर्क करें।';
  }

  @override
  String get overdueWhatsappFailedTitle => 'WhatsApp खोलने में असमर्थ';

  @override
  String get overdueCallTitle => 'ग्राहक को कॉल करें';

  @override
  String overdueCallBody(String name, String phone) {
    return '$name\n$phone';
  }

  @override
  String get overdueCallLabel => 'कॉल करें';

  @override
  String get overdueCallFailedTitle => 'कॉल शुरू करने में असमर्थ';

  @override
  String get overdueFollowUpAssignedTitle => 'अनुवर्ती कार्रवाई असाइन की गई';

  @override
  String get overdueGenericError => 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get overdueBadgeLabel => 'बकाया';

  @override
  String get overdueLoanNumberLabel => 'ऋण संख्या';

  @override
  String get overdueDueAmountLabel => 'देय राशि';

  @override
  String get overdueDaysOverdueLabel => 'बकाया दिन';

  @override
  String overdueDaysValue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन',
      one: '$days दिन',
    );
    return '$_temp0';
  }

  @override
  String get overdueStartedLabel => 'शुरू हुआ';

  @override
  String get overdueFollowUpSectionLabel => 'अनुवर्ती कार्रवाई';

  @override
  String overdueFollowUpDueLabel(String date) {
    return 'देय: $date';
  }

  @override
  String get overdueActionMessage => 'संदेश';

  @override
  String get overdueActionCall => 'कॉल करें';

  @override
  String get overdueActionAssignFollowUp => 'अनुवर्ती कार्रवाई असाइन करें';

  @override
  String get overdueAssignFollowUpTitle => 'अनुवर्ती कार्रवाई असाइन करें';

  @override
  String get overdueFollowUpNoteHint =>
      'उदाहरण: ग्राहक को कॉल किया, शुक्रवार तक भुगतान करने का वादा किया।';

  @override
  String get overdueFieldRequired => 'आवश्यक';

  @override
  String get overdueFollowUpNoteFieldLabel => 'अनुवर्ती कार्रवाई नोट';

  @override
  String get overdueFollowUpDateFieldLabel => 'अनुवर्ती कार्रवाई की तिथि';

  @override
  String overdueStartedValue(String date) {
    return 'शुरू हुआ: $date';
  }

  @override
  String overdueOutstandingValue(String amount) {
    return 'बकाया: $amount';
  }

  @override
  String get save => 'सहेजें';

  @override
  String get agentManagementTitle => 'एजेंट प्रबंधन';

  @override
  String get agentManagementSubtitle =>
      'अपने कलेक्शन एजेंटों को जोड़ें, संपादित करें और प्रबंधित करें';

  @override
  String get agentAddButton => 'एजेंट जोड़ें';

  @override
  String get agentLoadFailedFallback => 'एजेंट लोड करने में विफल।';

  @override
  String get agentStatTotal => 'कुल एजेंट';

  @override
  String get agentStatActive => 'सक्रिय एजेंट';

  @override
  String get agentStatInactive => 'निष्क्रिय एजेंट';

  @override
  String get agentStatAddedThisMonth => 'इस महीने जोड़े गए';

  @override
  String get agentSearchHint => 'नाम या मोबाइल से खोजें...';

  @override
  String get agentRoleAgent => 'एजेंट';

  @override
  String get agentRoleAdmin => 'व्यवस्थापक';

  @override
  String get agentRoleManager => 'प्रबंधक';

  @override
  String get agentRoleAll => 'सभी';

  @override
  String get agentColUser => 'उपयोगकर्ता';

  @override
  String get agentColMobile => 'मोबाइल';

  @override
  String get agentColRole => 'भूमिका';

  @override
  String get agentColStatus => 'स्थिति';

  @override
  String get agentColCreated => 'बनाया गया';

  @override
  String get agentColActions => 'कार्यवाहियां';

  @override
  String get agentNoAgentsFound => 'कोई एजेंट नहीं मिला।';

  @override
  String get agentEditTooltip => 'संपादित करें';

  @override
  String get agentDeleteTooltip => 'हटाएं';

  @override
  String get agentCreatedTitle => 'एजेंट बनाया गया';

  @override
  String agentCreatedMessage(String name) {
    return '$name को जोड़ दिया गया है';
  }

  @override
  String get agentCreateFailedTitle => 'एजेंट नहीं बनाया जा सका';

  @override
  String get agentUpdatedTitle => 'एजेंट अपडेट किया गया';

  @override
  String agentUpdatedMessage(String name) {
    return '$name को अपडेट कर दिया गया है';
  }

  @override
  String get agentUpdateFailedTitle => 'एजेंट अपडेट नहीं किया जा सका';

  @override
  String get agentDeleteDialogTitle => 'एजेंट हटाएं';

  @override
  String agentDeleteConfirmMessage(String name) {
    return 'क्या आप निश्चित हैं कि आप $name को हटाना चाहते हैं? उन्हें रीसायकल बिन में भेज दिया जाएगा और बाद में बहाल किया जा सकता है।';
  }

  @override
  String get agentDeleteConfirmLabel => 'एजेंट हटाएं';

  @override
  String get agentDeletedTitle => 'एजेंट हटाया गया';

  @override
  String agentDeletedMessage(String name) {
    return '$name को हटा दिया गया है';
  }

  @override
  String get agentDeleteFailedTitle => 'एजेंट हटाया नहीं जा सका';

  @override
  String get agentPhotoUploadFailedTitle => 'फोटो अपलोड विफल';

  @override
  String get agentMissingInfoTitle => 'जानकारी अधूरी है';

  @override
  String get agentMissingInfoMessage => 'कृपया सभी आवश्यक फ़ील्ड भरें';

  @override
  String get agentFormEditTitle => 'उपयोगकर्ता संपादित करें';

  @override
  String get agentFormAddTitle => 'उपयोगकर्ता जोड़ें';

  @override
  String get agentFormCredentialsNotice =>
      'एक ईमेल और पासवर्ड सेट करें ताकि यह उपयोगकर्ता ऐप में साइन इन कर सके।';

  @override
  String get agentFieldFullName => 'पूरा नाम *';

  @override
  String get agentFieldFullNameHint => 'उदा. प्रिया शर्मा';

  @override
  String get agentFieldMobile => 'मोबाइल';

  @override
  String get agentFieldMobileHint => 'उदा. +91 98765 43210';

  @override
  String get agentFieldEmail => 'ईमेल *';

  @override
  String get agentFieldEmailHint => 'user@rrgroups.in';

  @override
  String get agentFieldPassword => 'पासवर्ड *';

  @override
  String get agentFieldPasswordHint => 'न्यूनतम 6 अक्षर';

  @override
  String get agentFieldRole => 'भूमिका';

  @override
  String get agentFieldStatus => 'स्थिति';

  @override
  String get agentFieldAddress => 'पता';

  @override
  String get agentFieldAddressHint => 'आवासीय पता';

  @override
  String get agentFieldAadhaar => 'आधार';

  @override
  String get agentFieldAadhaarHint => '[आधार छुपाया गया]';

  @override
  String get agentFieldPan => 'पैन';

  @override
  String get agentFieldPanHint => 'ABCDE1234F';

  @override
  String get agentFieldOccupation => 'पेशा';

  @override
  String get agentFieldOccupationHint => 'उदा. फील्ड एग्जीक्यूटिव';

  @override
  String get agentFieldProfilePhoto => 'प्रोफ़ाइल फ़ोटो';

  @override
  String get agentUploadPhotoButton => 'फ़ोटो अपलोड करें';

  @override
  String get agentSaveChangesButton => 'परिवर्तन सहेजें';

  @override
  String get agentCreateUserButton => 'उपयोगकर्ता बनाएं';

  @override
  String get statusActive => 'सक्रिय';

  @override
  String get statusInactive => 'निष्क्रिय';

  @override
  String get fundsScreenTitle => 'फंड';

  @override
  String get fundsScreenSubtitle =>
      'परिपक्वता बोनस के साथ साप्ताहिक जमा बचत योजनाएँ';

  @override
  String get fundCreateButton => 'फंड बनाएँ';

  @override
  String get fundSearchHint => 'ग्राहक के नाम से खोजें';

  @override
  String get fundSearchClearTooltip => 'खोज साफ़ करें';

  @override
  String get fundRetryButton => 'पुनः प्रयास करें';

  @override
  String get fundStatTotalFunds => 'कुल फंड';

  @override
  String get fundStatActive => 'सक्रिय';

  @override
  String get fundStatMaturityPayout => 'परिपक्वता भुगतान';

  @override
  String get fundStatCollected => 'संग्रहित';

  @override
  String get fundEmptySearch => 'आपकी खोज से कोई फंड मेल नहीं खाता।';

  @override
  String get fundEmptyCustomer => 'आपके पास अभी तक कोई फंड नहीं है।';

  @override
  String get fundEmptyDefault => 'अभी तक कोई फंड नहीं है।';

  @override
  String get fundCardWeekly => 'साप्ताहिक';

  @override
  String get fundCardWeeks => 'सप्ताह';

  @override
  String get fundCardBonus => 'बोनस';

  @override
  String get fundCardMaturityPayout => 'परिपक्वता भुगतान';

  @override
  String fundCardDepositedProgress(String deposited, String total) {
    return 'जमा किए गए $deposited / $total';
  }

  @override
  String get fundCardPassbookButton => 'पासबुक';

  @override
  String get fundCardCollectButton => 'संग्रह करें';

  @override
  String fundCardSettleBanner(String amount) {
    return 'पूरा सेटल करें · $amount शेष';
  }

  @override
  String get fundDeleteDialogTitle => 'फंड हटाएँ';

  @override
  String fundDeleteDialogMessage(String code, String customerName) {
    return 'क्या आप $customerName के लिए \"$code\" को हटाना चाहते हैं? इसे रीसायकल बिन में ले जाया जाएगा और बाद में बहाल किया जा सकता है।';
  }

  @override
  String get fundDeleteDialogConfirm => 'हटाएँ';

  @override
  String get fundAgentSettleDialogTitle => 'फंड का पूरा सेटलमेंट करें';

  @override
  String fundAgentSettleDialogMessage(
      String amount, String code, String customerName) {
    return 'क्या आप अभी $customerName के \"$code\" के लिए शेष $amount एकत्र करना चाहते हैं और इसे परिपक्व चिह्नित करना चाहते हैं?';
  }

  @override
  String get fundAgentSettleDialogConfirm => 'अभी सेटल करें';

  @override
  String get fundToastLoadFailedTitle => 'फंड लोड करने में विफल';

  @override
  String get fundToastCreatedTitle => 'फंड बनाया गया';

  @override
  String get fundToastCreateFailedTitle => 'बनाने में विफल';

  @override
  String get fundToastUpdatedTitle => 'फंड अपडेट किया गया';

  @override
  String get fundToastUpdateFailedTitle => 'अपडेट विफल';

  @override
  String get fundToastSettledTitle => 'फंड सेटल किया गया';

  @override
  String get fundToastSettlementFailedTitle => 'सेटलमेंट विफल';

  @override
  String get fundToastCollectionRecordedTitle => 'संग्रह दर्ज किया गया';

  @override
  String get fundToastDeletedTitle => 'फंड हटाया गया';

  @override
  String get fundToastDeleteFailedTitle => 'हटाने में विफल';

  @override
  String get fundToastSelectCustomerTitle => 'एक ग्राहक चुनें';

  @override
  String get fundToastSelectCustomerMessage => 'कृपया एक ग्राहक चुनें';

  @override
  String get fundFormTitleEdit => 'फंड संपादित करें';

  @override
  String get fundFormTitleAdd => 'फंड जोड़ें';

  @override
  String get fundFormFieldCustomer => 'ग्राहक';

  @override
  String get fundFormFieldCustomerHint => 'एक ग्राहक चुनें...';

  @override
  String get fundFormFieldCustomerFallback => 'अज्ञात';

  @override
  String get fundFormFieldAgent => 'नियुक्त एजेंट (वैकल्पिक)';

  @override
  String get fundFormFieldAgentHint => 'एक एजेंट चुनें...';

  @override
  String get fundFormFieldAgentFallback => 'अज्ञात एजेंट';

  @override
  String get fundFormFieldUnits => 'फंड इकाइयाँ (मात्रा)';

  @override
  String get fundFormFieldWeeklyAmount => 'साप्ताहिक राशि';

  @override
  String get fundFormFieldWeeks => 'सप्ताहों की संख्या';

  @override
  String get fundFormFieldBonus => 'परिपक्वता बोनस';

  @override
  String get fundFormFieldStartDate => 'आरंभ तिथि';

  @override
  String get fundFormValidatorRequired => 'आवश्यक';

  @override
  String fundFormSummaryDeposited(String weekly, String weeks) {
    return 'जमा किया गया (₹$weekly x $weeks सप्ताह)';
  }

  @override
  String get fundFormSummaryBonus => 'परिपक्वता बोनस';

  @override
  String fundFormSummaryBonusValue(String amount) {
    return '+ $amount';
  }

  @override
  String get fundFormSummaryTotalPayout => 'कुल परिपक्वता भुगतान';

  @override
  String fundFormMaturesOn(String date) {
    return '$date को परिपक्व होगा';
  }

  @override
  String get fundFormCancelButton => 'रद्द करें';

  @override
  String get fundFormSaveButton => 'परिवर्तन सहेजें';

  @override
  String get fundFormCreateButton => 'फंड बनाएँ';

  @override
  String get fundCollectDialogInvalidAmountTitle => 'अमान्य राशि';

  @override
  String get fundCollectDialogInvalidAmountMessage =>
      '0 से अधिक संग्रह राशि दर्ज करें';

  @override
  String get fundCollectDialogNotSavedTitle => 'संग्रह सहेजा नहीं गया';

  @override
  String fundCollectDialogNotSavedMessage(String remaining) {
    return 'इस जमा को पूरी तरह से फंड करने के लिए केवल $remaining शेष है।';
  }

  @override
  String get fundCollectDialogFailedTitle => 'संग्रह विफल';

  @override
  String get fundCollectDialogTitle => 'संग्रह दर्ज करें';

  @override
  String fundCollectDialogSubtitle(String code, String customerName) {
    return '$code · $customerName';
  }

  @override
  String get fundCollectDialogCollectedLabel => 'एकत्रित';

  @override
  String get fundCollectDialogRemainingLabel => 'शेष';

  @override
  String get fundCollectDialogAmountLabel => 'संग्रह राशि';

  @override
  String get fundCollectDialogPaymentMethodLabel => 'भुगतान विधि';

  @override
  String get fundCollectDialogPaymentDateLabel => 'भुगतान तिथि';

  @override
  String get fundCollectDialogHelperText =>
      'यह राशि फंड के कुल एकत्रित योग में जोड़ता है। एक बार पूरा जमा लक्ष्य एकत्र हो जाने पर फंड को स्वतः परिपक्व चिह्नित कर देता है।';

  @override
  String get fundCollectDialogRecordButton => 'रिकॉर्ड करें';

  @override
  String get fundSettleDialogTitle => 'फंड बंद करना और निपटान';

  @override
  String fundSettleDialogSubtitle(
      String code, String customerName, String units) {
    return '$code · $customerName ($units सक्रिय इकाइयाँ)';
  }

  @override
  String get fundSettleTabPartial => 'आंशिक इकाई बंद करना';

  @override
  String get fundSettleTabFull => 'पूरा खाता निपटाएँ';

  @override
  String get fundSettleUnitsToCloseLabel =>
      'बंद की जाने वाली इकाइयों की संख्या';

  @override
  String get fundSettleHalfUnitButton => '0.5 इकाइयाँ';

  @override
  String get fundSettleOneUnitButton => '1 इकाई';

  @override
  String get fundSettleClosedPayoutLabel => 'बंद इकाइयों का भुगतान';

  @override
  String get fundSettleClosedPayoutSubtitle => 'उपार्जित जमा + बोनस';

  @override
  String get fundSettleRemainingBalanceLabel => 'शेष सक्रिय शेष';

  @override
  String fundSettleRemainingUnitsValue(String units) {
    return '$units इकाइयाँ शेष';
  }

  @override
  String fundSettleNewWeeklyValue(String amount) {
    return 'नया साप्ताहिक: $amount / सप्ताह';
  }

  @override
  String get fundSettleTotalDepositedLabel => 'कुल जमा';

  @override
  String get fundSettleRemainingTargetLabel => 'शेष लक्ष्य';

  @override
  String get fundSettlePaymentMethodLabel => 'भुगतान विधि';

  @override
  String get fundSettleSettlementDateLabel => 'निपटान तिथि';

  @override
  String get fundSettleSummaryClosingTarget => 'इकाइयाँ बंद करने का जमा लक्ष्य';

  @override
  String fundSettleSummaryClosingTargetValue(
      String amount, String units, String maxUnits) {
    return '$amount ($maxUnits इकाइयों में से $units इकाइयाँ)';
  }

  @override
  String get fundSettleSummaryTotalDeposit => 'कुल जमा';

  @override
  String get fundSettleSummaryProportionalBonus => '🎁 आनुपातिक बोनस';

  @override
  String get fundSettleSummaryNetClosurePayout =>
      'शुद्ध बंद करने की भुगतान राशि';

  @override
  String get fundSettleSummaryPayoutToCustomer => 'ग्राहक को भुगतान';

  @override
  String get fundSettleFailedTitle => 'बंद करने में विफल';

  @override
  String get fundSettleCancelButton => 'रद्द करें';

  @override
  String get fundSettleConfirmPartialButton => 'आंशिक बंद करने की पुष्टि करें';

  @override
  String get fundSettleConfirmFullButton => 'पूरा खाता निपटाएँ';

  @override
  String get fundPassbookTitle => 'पासबुक';

  @override
  String fundPassbookSubtitle(String code, String customerName) {
    return '$code · $customerName';
  }

  @override
  String get fundPassbookDepositedLabel => 'जमा किया गया';

  @override
  String get fundPassbookToDepositLabel => 'जमा करना है';

  @override
  String get fundPassbookEntriesLabel => 'प्रविष्टियाँ';

  @override
  String fundPassbookEntriesValue(String paid, String total) {
    return '$paid / $total';
  }

  @override
  String fundPassbookSummaryTotalDeposit(String weekly, String weeks) {
    return 'कुल जमा (₹$weekly x $weeks सप्ताह)';
  }

  @override
  String get fundPassbookSummaryBonus => '🎁 परिपक्वता बोनस (निपटान पर)';

  @override
  String get fundPassbookSummaryPayout => 'परिपक्वता भुगतान';

  @override
  String get fundPassbookNextDuePrefix => 'अगली जमा देय · ';

  @override
  String fundPassbookNextDueValue(String date, String week, String amount) {
    return '$date · सप्ताह $week · $amount';
  }

  @override
  String get fundPassbookColWeek => 'सप्ताह';

  @override
  String get fundPassbookColDateMethod => 'तिथि · विधि';

  @override
  String get fundPassbookColAmountBalance => 'राशि · शेष';

  @override
  String get fundPassbookNextDueRowLabel => 'अगली देय';

  @override
  String get fundPassbookPaidFallback => 'भुगतान किया गया';

  @override
  String get fundPassbookPendingLabel => 'लंबित';

  @override
  String fundPassbookBalanceValue(String balance) {
    return 'शेष $balance';
  }

  @override
  String get fundPassbookCloseButton => 'बंद करें';

  @override
  String get routeMapTitle => 'ग्राहक मानचित्र';

  @override
  String get routeMapAllLocationsSubtitle => 'सभी ग्राहक स्थान';

  @override
  String get routeMapSearchHint => 'ग्राहक, ऋण या एजेंट खोजें...';

  @override
  String get routeMapCustomerLabel => 'ग्राहक';

  @override
  String get routeMapAllCustomers => 'सभी ग्राहक';

  @override
  String get routeMapTotalMapped => 'कुल मैप किए गए';

  @override
  String get routeMapActiveCustomers => 'सक्रिय ग्राहक';

  @override
  String get routeMapNoLocationsTitle => 'कोई स्थान नहीं मिला';

  @override
  String get routeMapNoLocationsMessage =>
      'वैध निर्देशांक वाले ग्राहक यहाँ दिखेंगे।';

  @override
  String get routeMapActive => 'सक्रिय';

  @override
  String get routeMapInactive => 'निष्क्रिय';

  @override
  String get routeMapRetryButton => 'पुनः प्रयास करें';

  @override
  String get routeMapLoadFailedTitle => 'मैप डेटा लोड करने में विफल';

  @override
  String routeMapJoinedLabel(String date) {
    return 'शामिल हुए: $date';
  }

  @override
  String get reportsScreenTitle => 'रिपोर्ट और विश्लेषण';

  @override
  String get reportsSubtitle => 'दैनिक, मासिक और एजेंट के प्रदर्शन की जानकारी';

  @override
  String get reportsExportPdfButton => 'पीडीएफ निर्यात करें';

  @override
  String get reportsExportExcelButton => 'एक्सेल निर्यात करें';

  @override
  String get reportsExportingExcelTitle => 'एक्सेल निर्यात हो रहा है';

  @override
  String get reportsExportingExcelMessage =>
      'स्प्रेडशीट सेल संकलित किए जा रहे हैं...';

  @override
  String get reportsExportCompleteTitle => 'निर्यात पूर्ण';

  @override
  String get reportsExportCompleteMessage =>
      'एक्सेल शीट सफलतापूर्वक जनरेट हो गई।';

  @override
  String get reportsExportFailedTitle => 'निर्यात विफल';

  @override
  String reportsExportFailedMessage(String error) {
    return 'स्प्रेडशीट जनरेट नहीं हो सकी। तकनीकी कारण: $error';
  }

  @override
  String get reportsDailyHint =>
      'दैनिक रिपोर्ट ऊपर दी गई अंतिम तिथि का डेटा दिखाती है।';

  @override
  String get reportsRetryButton => 'पुनः प्रयास करें';

  @override
  String get reportsGenericErrorMessage =>
      'रिपोर्ट लोड करते समय कुछ गड़बड़ हो गई।';

  @override
  String get reportsTabDaily => 'दैनिक\nरिपोर्ट';

  @override
  String get reportsTabMonthly => 'मासिक\nरिपोर्ट';

  @override
  String get reportsTabAgent => 'एजेंट\nप्रदर्शन';

  @override
  String get reportsTodaysCollectionsTitle => 'आज का संग्रह';

  @override
  String get reportsNoCollectionsTodayTitle => 'आज कोई संग्रह नहीं';

  @override
  String get reportsNoCollectionsTodayMessage =>
      'आज किए गए संग्रह यहाँ दिखेंगे।';

  @override
  String get reportsNewLoansTodayTitle => 'आज बनाए गए नए ऋण';

  @override
  String get reportsNoNewLoansTodayTitle => 'आज कोई नया ऋण नहीं';

  @override
  String get reportsNoNewLoansTodayMessage => 'आज बनाए गए ऋण यहाँ दिखेंगे।';

  @override
  String get reportsMetricDisbursement => 'ऋण संवितरण';

  @override
  String get reportsMetricInterest => 'अर्जित ब्याज';

  @override
  String get reportsMetricCollectionTotal => 'कुल संग्रह';

  @override
  String get reportsMetricNewCustomers => 'नए ग्राहक';

  @override
  String get reportsCollectionsTrendTitle => 'संग्रह रुझान';

  @override
  String reportsLastNMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'पिछले $count महीने',
      one: 'पिछला 1 महीना',
    );
    return '$_temp0';
  }

  @override
  String get reportsLoanDisbursementTitle => 'ऋण संवितरण';

  @override
  String get reportsByMonth => 'माह के अनुसार';

  @override
  String get reportsAgentPerformanceTitle => 'एजेंट प्रदर्शन';

  @override
  String get reportsNoAgentDataTitle => 'कोई एजेंट डेटा नहीं';

  @override
  String get reportsNoAgentDataMessage =>
      'एजेंट सक्रिय होने पर एजेंट का प्रदर्शन यहाँ दिखेगा।';

  @override
  String get reportsColumnAgent => 'एजेंट';

  @override
  String get reportsColumnAssigned => 'असाइन किया गया';

  @override
  String get reportsColumnCollected => 'संग्रहित';

  @override
  String get reportsColumnEfficiency => 'दक्षता';

  @override
  String get reportsCollectionsByAgentTitle => 'एजेंट द्वारा संग्रह';

  @override
  String get reportsTotalAmountCollected => 'कुल एकत्रित राशि';

  @override
  String get reportsNoData => 'कोई डेटा नहीं';

  @override
  String get notificationsScreenTitle => 'सूचनाएं';

  @override
  String get notificationsSubtitle =>
      'देय राशि, अनुमोदन और अनुस्मारक के साथ अपडेट रहें';

  @override
  String get markAllRead => 'सभी पढ़े गए चिह्नित करें';

  @override
  String get send => 'भेजें';

  @override
  String get statTotal => 'कुल';

  @override
  String get statUnread => 'अपठित';

  @override
  String get statOverdue => 'देय तिथि से अधिक';

  @override
  String get filterAll => 'सभी';

  @override
  String get filterUnread => 'अपठित';

  @override
  String get filterEmiDue => 'ईएमआई देय';

  @override
  String get filterOverdue => 'देय तिथि से अधिक';

  @override
  String get filterApprovals => 'अनुमोदन';

  @override
  String get filterReminders => 'रिमाइंडर';

  @override
  String get noNotificationsHere => 'यहां कोई सूचना नहीं है।';

  @override
  String get failedToLoadNotifications => 'सूचनाएं लोड करने में विफल रहा';

  @override
  String get couldNotLoadNotificationsToastTitle =>
      'सूचनाएं लोड नहीं की जा सकीं';

  @override
  String get allNotificationsClearedToastTitle => 'सभी सूचनाएं साफ़ कर दी गईं';

  @override
  String get allNotificationsClearedToastMessage =>
      'सब कुछ पढ़ा हुआ के रूप में चिह्नित कर दिया गया है।';

  @override
  String get failedToUpdateToastTitle => 'अपडेट करने में विफल';

  @override
  String get deleteNotificationTitle => 'सूचना हटाएं';

  @override
  String deleteNotificationMessage(String title) {
    return 'क्या आप \"$title\" हटाना चाहते हैं? इसे रीसायकल बिन में ले जाया जाएगा और बाद में पुनर्स्थापित किया जा सकता है।';
  }

  @override
  String get notificationRemovedToastTitle => 'सूचना हटा दी गई';

  @override
  String get failedToDeleteToastTitle => 'हटाने में विफल';

  @override
  String get markedAsReadToastTitle => 'पढ़ा हुआ के रूप में चिह्नित';

  @override
  String get failedToMarkAsReadToastTitle =>
      'पढ़ा हुआ के रूप में चिह्नित करने में विफल';

  @override
  String userIdLabel(String id) {
    return 'उपयोगकर्ता_आईडी: $id';
  }

  @override
  String get sendNotificationTitle => 'सूचना भेजें';

  @override
  String get sendNotificationSubtitle => 'अपने ग्राहकों को तुरंत सूचित करें';

  @override
  String get recipientsLabel => 'प्राप्तकर्ता';

  @override
  String get allCustomers => 'सभी ग्राहक';

  @override
  String get selectLabel => 'चुनें';

  @override
  String get searchCustomersHint => 'ग्राहकों को खोजें...';

  @override
  String get noCustomersFoundInList => 'कोई ग्राहक नहीं मिला।';

  @override
  String get noPortalLogin => 'कोई पोर्टल लॉगिन नहीं';

  @override
  String get typeLabel => 'प्रकार';

  @override
  String get typeInfo => 'जानकारी';

  @override
  String get typeReminder => 'रिमाइंडर';

  @override
  String get typeEmiDue => 'ईएमआई देय';

  @override
  String get typeOverdue => 'अतिदेय';

  @override
  String get typeApproval => 'अनुमोदन';

  @override
  String get titleFieldLabel => 'शीर्षक';

  @override
  String get titleFieldHint => 'उदा. EMI कल देय है';

  @override
  String get messageFieldLabel => 'संदेश';

  @override
  String get messageFieldHint => 'अपना संदेश लिखें...';

  @override
  String get noRecipientsSelected => 'कोई प्राप्तकर्ता नहीं चुना गया';

  @override
  String recipientsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count प्राप्तकर्ता चुने गए',
      one: '1 प्राप्तकर्ता चुना गया',
    );
    return '$_temp0';
  }

  @override
  String get titleRequiredError => 'शीर्षक आवश्यक है';

  @override
  String get noCustomersFoundError => 'कोई ग्राहक नहीं मिला';

  @override
  String get noLinkedCustomerLoginsFoundError =>
      'कोई लिंक किया गया ग्राहक लॉगिन नहीं मिला';

  @override
  String get selectAtLeastOneRecipientError => 'कम से कम एक प्राप्तकर्ता चुनें';

  @override
  String get noEligibleRecipientsToastTitle => 'कोई योग्य प्राप्तकर्ता नहीं';

  @override
  String get noEligibleRecipientsToastMessage =>
      'सूचनाएं प्राप्त करने के लिए चुने गए ग्राहकों को पोर्टल लॉगिन की आवश्यकता है।';

  @override
  String get notificationSentToastTitle => 'सूचना भेजी गई';

  @override
  String recipientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count प्राप्तकर्ता',
      one: '1 प्राप्तकर्ता',
    );
    return '$_temp0';
  }

  @override
  String get sendFailedToastTitle => 'भेजना असफल रहा';

  @override
  String get couldNotLoadCustomersToastTitle => 'ग्राहक लोड नहीं किए जा सके';

  @override
  String get userManagementScreenTitle => 'उपयोगकर्ता प्रबंधन';

  @override
  String get userManagementSubtitle =>
      'अपने संगठन में भूमिकाएँ, पहुँच और अनुमतियाँ प्रबंधित करें';

  @override
  String get addUser => 'उपयोगकर्ता जोड़ें';

  @override
  String get refreshTooltip => 'रीफ़्रेश करें';

  @override
  String get edit => 'संपादित करें';

  @override
  String get statTotalUsers => 'कुल उपयोगकर्ता';

  @override
  String get statActive => 'सक्रिय';

  @override
  String get statAgents => 'एजेंट';

  @override
  String get statAdmins => 'एडमिन';

  @override
  String get searchByNameOrMobileHint => 'नाम या मोबाइल से खोजें...';

  @override
  String get roleAll => 'सभी भूमिकाएँ';

  @override
  String get roleAdmin => 'एडमिन';

  @override
  String get roleCollectionAgent => 'कलेक्शन एजेंट';

  @override
  String get roleCustomer => 'ग्राहक';

  @override
  String get noUsersFound => 'कोई उपयोगकर्ता नहीं मिला';

  @override
  String get tableColumnUser => 'उपयोगकर्ता';

  @override
  String get tableColumnMobile => 'मोबाइल';

  @override
  String get tableColumnRole => 'भूमिका';

  @override
  String get tableColumnStatus => 'स्थिति';

  @override
  String get adminCannotBeEditedTooltip =>
      'एडमिन खाते संपादित नहीं किए जा सकते';

  @override
  String get adminCannotBeDeletedTooltip => 'एडमिन खाते हटाए नहीं जा सकते';

  @override
  String get removeUserDialogTitle => 'उपयोगकर्ता हटाएँ?';

  @override
  String removeUserDialogMessage(String name) {
    return '$name को रीसायकल बिन में ले जाया जाएगा और बाद में पुनर्स्थापित किया जा सकता है।';
  }

  @override
  String get remove => 'हटाएँ';

  @override
  String get userCreatedToastTitle => 'उपयोगकर्ता बनाया गया';

  @override
  String userCreatedToastMessage(String name) {
    return '$name सफलतापूर्वक जोड़ा गया';
  }

  @override
  String get couldNotCreateUserToastTitle => 'उपयोगकर्ता नहीं बनाया जा सका';

  @override
  String get somethingWentWrong => 'कुछ गलत हो गया';

  @override
  String get userUpdatedToastTitle => 'उपयोगकर्ता अपडेट किया गया';

  @override
  String userUpdatedToastMessage(String name) {
    return '$name सहेजा गया';
  }

  @override
  String get couldNotUpdateUserToastTitle =>
      'उपयोगकर्ता अपडेट नहीं किया जा सका';

  @override
  String get userRemovedToastTitle => 'उपयोगकर्ता हटाया गया';

  @override
  String userRemovedToastMessage(String name) {
    return '$name हटा दिया गया';
  }

  @override
  String get couldNotDeleteUserToastTitle => 'उपयोगकर्ता हटाया नहीं जा सका';

  @override
  String get failedToLoadUsers => 'उपयोगकर्ता लोड करने में विफल';

  @override
  String get dismissAddUserDialogLabel => 'उपयोगकर्ता जोड़ें संवाद बंद करें';

  @override
  String get dismissEditUserDialogLabel =>
      'उपयोगकर्ता संपादित करें संवाद बंद करें';

  @override
  String get editUserDialogTitle => 'उपयोगकर्ता संपादित करें';

  @override
  String get editPasswordHintNote =>
      'वर्तमान पासवर्ड अपरिवर्तित रखने के लिए पासवर्ड खाली छोड़ें।';

  @override
  String get addUserBackendNote =>
      'यह सीधे बैकएंड पर एक लॉगिन खाता बनाता है। उपयोगकर्ता नीचे दिए गए ईमेल और पासवर्ड से तुरंत साइन इन कर सकता है।';

  @override
  String get fullNameRequiredError => 'पूरा नाम आवश्यक है';

  @override
  String get validEmailRequiredError => 'एक वैध ईमेल आवश्यक है';

  @override
  String get passwordMinLengthError =>
      'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए';

  @override
  String get fullNameFieldLabel => 'पूरा नाम *';

  @override
  String get fullNameFieldHint => 'उदा. प्रिया शर्मा';

  @override
  String get emailFieldLabel => 'ईमेल *';

  @override
  String get emailFieldHint => 'उदा. priya@example.com';

  @override
  String get newPasswordOptionalLabel => 'नया पासवर्ड (वैकल्पिक)';

  @override
  String get passwordFieldLabel => 'पासवर्ड *';

  @override
  String get passwordLeaveBlankHint => 'अपरिवर्तित रखने के लिए खाली छोड़ें';

  @override
  String get passwordMinCharsHint => 'न्यूनतम 6 अक्षर';

  @override
  String get mobileFieldLabel => 'मोबाइल';

  @override
  String get mobileFieldHint => 'उदा. +91 98765 43210';

  @override
  String get roleFieldLabel => 'भूमिका';

  @override
  String get statusFieldLabel => 'स्थिति';

  @override
  String get avatarUrlFieldLabel => 'अवतार यूआरएल';

  @override
  String get avatarUrlFieldHint => 'https://...';

  @override
  String get avatarUrlHelperText => 'वैकल्पिक प्रोफ़ाइल छवि लिंक';

  @override
  String get saveChanges => 'परिवर्तन सहेजें';

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
