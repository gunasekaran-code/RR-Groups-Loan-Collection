import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ta')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'RR Groups'**
  String get appTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to FinCollect'**
  String get welcomeMessage;

  /// No description provided for @loans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get loans;

  /// No description provided for @collections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collections;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @paymentReminders.
  ///
  /// In en, this message translates to:
  /// **'Payment Reminders'**
  String get paymentReminders;

  /// No description provided for @groupUpdates.
  ///
  /// In en, this message translates to:
  /// **'Group Updates'**
  String get groupUpdates;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @changeMpin.
  ///
  /// In en, this message translates to:
  /// **'Change MPIN'**
  String get changeMpin;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @confirmLogoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your account?'**
  String get confirmLogoutQuestion;

  /// Button label to dismiss the send-notification dialog without sending
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @loggedOut.
  ///
  /// In en, this message translates to:
  /// **'Logged out'**
  String get loggedOut;

  /// No description provided for @connectBackendToEnable.
  ///
  /// In en, this message translates to:
  /// **'Connect backend to enable'**
  String get connectBackendToEnable;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get deleteEntry;

  /// Confirm button label for deleting a notification
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @printStatement.
  ///
  /// In en, this message translates to:
  /// **'Print Statement'**
  String get printStatement;

  /// No description provided for @accountBook.
  ///
  /// In en, this message translates to:
  /// **'Account Book'**
  String get accountBook;

  /// No description provided for @recycleBinTitle.
  ///
  /// In en, this message translates to:
  /// **'Recycle Bin'**
  String get recycleBinTitle;

  /// No description provided for @recycleBinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything deleted anywhere in the app — by an admin, an agent or a customer'**
  String get recycleBinSubtitle;

  /// No description provided for @recycleBinSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, type or who deleted it...'**
  String get recycleBinSearchHint;

  /// No description provided for @recycleBinEmptyButton.
  ///
  /// In en, this message translates to:
  /// **'Empty Recycle Bin'**
  String get recycleBinEmptyButton;

  /// No description provided for @recycleBinRestoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get recycleBinRestoreLabel;

  /// No description provided for @recycleBinRestoredBadge.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get recycleBinRestoredBadge;

  /// No description provided for @recycleBinDeletePermanentlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently?'**
  String get recycleBinDeletePermanentlyTitle;

  /// No description provided for @recycleBinEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty Recycle Bin?'**
  String get recycleBinEmptyTitle;

  /// No description provided for @recycleBinEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete all items? This action cannot be undone.'**
  String get recycleBinEmptyMessage;

  /// No description provided for @recycleBinNoItems.
  ///
  /// In en, this message translates to:
  /// **'No matching items found.'**
  String get recycleBinNoItems;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @customersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage customer information and details'**
  String get customersSubtitle;

  /// No description provided for @customersAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get customersAddButton;

  /// No description provided for @customersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name...'**
  String get customersSearchHint;

  /// No description provided for @customersFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All Status'**
  String get customersFilterAll;

  /// No description provided for @customersFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get customersFilterActive;

  /// No description provided for @customersFilterOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get customersFilterOverdue;

  /// No description provided for @customersFilterInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get customersFilterInactive;

  /// No description provided for @customersNoResults.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get customersNoResults;

  /// Button label to retry loading notifications after an error
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @customersLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to load customers'**
  String get customersLoadFailedTitle;

  /// No description provided for @customersDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Customer'**
  String get customersDeleteTitle;

  /// No description provided for @customersDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}? They will be moved to the Recycle Bin and can be restored later.'**
  String customersDeleteMessage(String name);

  /// No description provided for @customersDeletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer deleted'**
  String get customersDeletedTitle;

  /// No description provided for @customersDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} was removed successfully'**
  String customersDeletedMessage(String name);

  /// No description provided for @customersDeleteFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get customersDeleteFailedTitle;

  /// No description provided for @customersUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer updated'**
  String get customersUpdatedTitle;

  /// No description provided for @customersAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer added'**
  String get customersAddedTitle;

  /// No description provided for @customersUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} was updated successfully'**
  String customersUpdatedMessage(String name);

  /// No description provided for @customersAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} was added successfully'**
  String customersAddedMessage(String name);

  /// No description provided for @customersSaveFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get customersSaveFailedTitle;

  /// No description provided for @customerViewClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get customerViewClose;

  /// No description provided for @customerFieldId.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER ID'**
  String get customerFieldId;

  /// No description provided for @customerFieldMobile.
  ///
  /// In en, this message translates to:
  /// **'MOBILE'**
  String get customerFieldMobile;

  /// No description provided for @customerFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'ADDRESS'**
  String get customerFieldAddress;

  /// No description provided for @customerFieldAadhaar.
  ///
  /// In en, this message translates to:
  /// **'AADHAAR'**
  String get customerFieldAadhaar;

  /// No description provided for @customerFieldPan.
  ///
  /// In en, this message translates to:
  /// **'PAN'**
  String get customerFieldPan;

  /// No description provided for @customerFieldOccupation.
  ///
  /// In en, this message translates to:
  /// **'OCCUPATION'**
  String get customerFieldOccupation;

  /// No description provided for @customerFieldAgent.
  ///
  /// In en, this message translates to:
  /// **'ASSIGNED AGENT'**
  String get customerFieldAgent;

  /// No description provided for @customerFieldLoanStatus.
  ///
  /// In en, this message translates to:
  /// **'LOAN STATUS'**
  String get customerFieldLoanStatus;

  /// No description provided for @customerActionView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get customerActionView;

  /// No description provided for @customerActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get customerActionEdit;

  /// No description provided for @customerActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get customerActionDelete;

  /// No description provided for @customerUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get customerUnassigned;

  /// No description provided for @customerFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get customerFormEditTitle;

  /// No description provided for @customerFormAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get customerFormAddTitle;

  /// No description provided for @customerFormEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update customer details'**
  String get customerFormEditSubtitle;

  /// No description provided for @customerFormAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details below'**
  String get customerFormAddSubtitle;

  /// No description provided for @customerSectionPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get customerSectionPersonal;

  /// No description provided for @customerSectionAssignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get customerSectionAssignment;

  /// No description provided for @customerSectionPortalLogin.
  ///
  /// In en, this message translates to:
  /// **'Portal Login (optional)'**
  String get customerSectionPortalLogin;

  /// No description provided for @customerSectionPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get customerSectionPhoto;

  /// No description provided for @customerLabelFullName.
  ///
  /// In en, this message translates to:
  /// **'FULL NAME *'**
  String get customerLabelFullName;

  /// No description provided for @customerHintFullName.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ramesh Kumar'**
  String get customerHintFullName;

  /// No description provided for @customerLabelMobile.
  ///
  /// In en, this message translates to:
  /// **'MOBILE NUMBER *'**
  String get customerLabelMobile;

  /// No description provided for @customerHintMobile.
  ///
  /// In en, this message translates to:
  /// **'10-digit mobile number'**
  String get customerHintMobile;

  /// No description provided for @customerLabelAddress.
  ///
  /// In en, this message translates to:
  /// **'ADDRESS *'**
  String get customerLabelAddress;

  /// No description provided for @customerHintAddress.
  ///
  /// In en, this message translates to:
  /// **'Full residential address'**
  String get customerHintAddress;

  /// No description provided for @customerLabelAadhaar.
  ///
  /// In en, this message translates to:
  /// **'AADHAAR (optional)'**
  String get customerLabelAadhaar;

  /// No description provided for @customerHintAadhaar.
  ///
  /// In en, this message translates to:
  /// **'12-digit Aadhaar number'**
  String get customerHintAadhaar;

  /// No description provided for @customerLabelPan.
  ///
  /// In en, this message translates to:
  /// **'PAN (optional)'**
  String get customerLabelPan;

  /// No description provided for @customerHintPan.
  ///
  /// In en, this message translates to:
  /// **'e.g. ABCDE1234F'**
  String get customerHintPan;

  /// No description provided for @customerLabelOccupation.
  ///
  /// In en, this message translates to:
  /// **'OCCUPATION (optional)'**
  String get customerLabelOccupation;

  /// No description provided for @customerHintOccupation.
  ///
  /// In en, this message translates to:
  /// **'e.g. Shop owner'**
  String get customerHintOccupation;

  /// No description provided for @customerLabelAssignedAgent.
  ///
  /// In en, this message translates to:
  /// **'ASSIGNED AGENT'**
  String get customerLabelAssignedAgent;

  /// No description provided for @customerMapLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Map Location'**
  String get customerMapLocationTitle;

  /// No description provided for @customerMapLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'for agent route'**
  String get customerMapLocationSubtitle;

  /// No description provided for @customerPinFromAddress.
  ///
  /// In en, this message translates to:
  /// **'Pin from address'**
  String get customerPinFromAddress;

  /// No description provided for @customerUseMyGps.
  ///
  /// In en, this message translates to:
  /// **'Use my GPS'**
  String get customerUseMyGps;

  /// No description provided for @customerMapHelpText.
  ///
  /// In en, this message translates to:
  /// **'Shows this customer on the agent\'s live Route Map. \"Pin from address\" looks up the address above; \"Use my GPS\" captures where you\'re standing.'**
  String get customerMapHelpText;

  /// No description provided for @customerLatitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'LATITUDE'**
  String get customerLatitudeLabel;

  /// No description provided for @customerLongitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'LONGITUDE'**
  String get customerLongitudeLabel;

  /// No description provided for @customerLatLngHint.
  ///
  /// In en, this message translates to:
  /// **'0.0000000'**
  String get customerLatLngHint;

  /// No description provided for @customerAddressRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Address required'**
  String get customerAddressRequiredTitle;

  /// No description provided for @customerAddressRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter an address first so it can be located on the map'**
  String get customerAddressRequiredMessage;

  /// No description provided for @customerAddressNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find that address'**
  String get customerAddressNotFoundTitle;

  /// No description provided for @customerLocationFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location'**
  String get customerLocationFailedTitle;

  /// No description provided for @customerPhotoFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo upload failed'**
  String get customerPhotoFailedTitle;

  /// No description provided for @customerPortalLoginHelp.
  ///
  /// In en, this message translates to:
  /// **'Set a password to let this customer sign in with their mobile number to view their own loans & payments. No email needed.'**
  String get customerPortalLoginHelp;

  /// No description provided for @customerLabelEmail.
  ///
  /// In en, this message translates to:
  /// **'EMAIL (optional)'**
  String get customerLabelEmail;

  /// No description provided for @customerHintEmail.
  ///
  /// In en, this message translates to:
  /// **'customer@example.com'**
  String get customerHintEmail;

  /// No description provided for @customerLabelPassword.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD (optional)'**
  String get customerLabelPassword;

  /// No description provided for @customerHintPassword.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get customerHintPassword;

  /// No description provided for @customerLoginNote.
  ///
  /// In en, this message translates to:
  /// **'Login uses the mobile number above as the username.'**
  String get customerLoginNote;

  /// No description provided for @customerUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get customerUploadPhoto;

  /// No description provided for @customerSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get customerSaveChanges;

  /// No description provided for @customerFormValidationTitle.
  ///
  /// In en, this message translates to:
  /// **'Check the form'**
  String get customerFormValidationTitle;

  /// No description provided for @customerFormValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'Please fix the highlighted fields before saving'**
  String get customerFormValidationMessage;

  /// No description provided for @customerValidatorNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get customerValidatorNameRequired;

  /// No description provided for @customerValidatorNameMin.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 3 characters'**
  String get customerValidatorNameMin;

  /// No description provided for @customerValidatorNameChars.
  ///
  /// In en, this message translates to:
  /// **'Only letters and spaces are allowed'**
  String get customerValidatorNameChars;

  /// No description provided for @customerValidatorMobileRequired.
  ///
  /// In en, this message translates to:
  /// **'Mobile number is required'**
  String get customerValidatorMobileRequired;

  /// No description provided for @customerValidatorMobileInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number'**
  String get customerValidatorMobileInvalid;

  /// No description provided for @customerValidatorAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get customerValidatorAddressRequired;

  /// No description provided for @customerValidatorAddressMin.
  ///
  /// In en, this message translates to:
  /// **'Enter a more complete address'**
  String get customerValidatorAddressMin;

  /// No description provided for @customerValidatorAadhaarInvalid.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar must be exactly 12 digits'**
  String get customerValidatorAadhaarInvalid;

  /// No description provided for @customerValidatorPanInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid PAN (e.g. ABCDE1234F)'**
  String get customerValidatorPanInvalid;

  /// No description provided for @customerValidatorOccupationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid occupation'**
  String get customerValidatorOccupationInvalid;

  /// No description provided for @customerValidatorNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get customerValidatorNumberInvalid;

  /// No description provided for @customerValidatorLatRange.
  ///
  /// In en, this message translates to:
  /// **'Must be between -90 and 90'**
  String get customerValidatorLatRange;

  /// No description provided for @customerValidatorLngRange.
  ///
  /// In en, this message translates to:
  /// **'Must be between -180 and 180'**
  String get customerValidatorLngRange;

  /// No description provided for @customerValidatorEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get customerValidatorEmailInvalid;

  /// No description provided for @customerValidatorPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get customerValidatorPasswordMin;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardNotLinkedYet.
  ///
  /// In en, this message translates to:
  /// **'{label} is not linked yet'**
  String dashboardNotLinkedYet(String label);

  /// No description provided for @dashboardGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get dashboardGreetingMorning;

  /// No description provided for @dashboardGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get dashboardGreetingAfternoon;

  /// No description provided for @dashboardGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get dashboardGreetingEvening;

  /// No description provided for @dashboardGreetingWithName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String dashboardGreetingWithName(String greeting, String name);

  /// No description provided for @dashboardLiveFigures.
  ///
  /// In en, this message translates to:
  /// **'Live figures from the database: {amount} collected today and {count} active loans.'**
  String dashboardLiveFigures(String amount, int count);

  /// No description provided for @dashboardNetBalanceSummary.
  ///
  /// In en, this message translates to:
  /// **'Net Balance Summary'**
  String get dashboardNetBalanceSummary;

  /// No description provided for @dashboardNetBalanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time working capital position'**
  String get dashboardNetBalanceSubtitle;

  /// No description provided for @dashboardCashInHand.
  ///
  /// In en, this message translates to:
  /// **'CASH IN HAND'**
  String get dashboardCashInHand;

  /// No description provided for @dashboardLoanCollections.
  ///
  /// In en, this message translates to:
  /// **'Loan Collections'**
  String get dashboardLoanCollections;

  /// No description provided for @dashboardFundDeposits.
  ///
  /// In en, this message translates to:
  /// **'Fund Deposits'**
  String get dashboardFundDeposits;

  /// No description provided for @dashboardCustomCashIn.
  ///
  /// In en, this message translates to:
  /// **'+ Custom Cash In'**
  String get dashboardCustomCashIn;

  /// No description provided for @dashboardOutstandingMoneyLent.
  ///
  /// In en, this message translates to:
  /// **'OUTSTANDING MONEY LENT'**
  String get dashboardOutstandingMoneyLent;

  /// No description provided for @dashboardLoansOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Loans Outstanding'**
  String get dashboardLoansOutstanding;

  /// No description provided for @dashboardCustomLent.
  ///
  /// In en, this message translates to:
  /// **'+ Custom Lent'**
  String get dashboardCustomLent;

  /// No description provided for @dashboardNetBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'NET BALANCE'**
  String get dashboardNetBalanceLabel;

  /// No description provided for @dashboardTotalAssets.
  ///
  /// In en, this message translates to:
  /// **'TOTAL ASSETS'**
  String get dashboardTotalAssets;

  /// No description provided for @dashboardNetBalanceFormula.
  ///
  /// In en, this message translates to:
  /// **'Cash In Hand ({cash}) + Money Lent ({lent})'**
  String dashboardNetBalanceFormula(String cash, String lent);

  /// No description provided for @dashboardStatActiveLoans.
  ///
  /// In en, this message translates to:
  /// **'Active Loans'**
  String get dashboardStatActiveLoans;

  /// No description provided for @dashboardStatNewCustomers.
  ///
  /// In en, this message translates to:
  /// **'New Customers'**
  String get dashboardStatNewCustomers;

  /// No description provided for @dashboardStatTodaysCollections.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Collections'**
  String get dashboardStatTodaysCollections;

  /// No description provided for @dashboardStatOverdueAccounts.
  ///
  /// In en, this message translates to:
  /// **'Overdue Accounts'**
  String get dashboardStatOverdueAccounts;

  /// No description provided for @dashboardStatPendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Pending Approvals'**
  String get dashboardStatPendingApprovals;

  /// No description provided for @dashboardStatTotalLoanAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Loan Amount'**
  String get dashboardStatTotalLoanAmount;

  /// No description provided for @dashboardStatInterestRevenue.
  ///
  /// In en, this message translates to:
  /// **'Interest Revenue'**
  String get dashboardStatInterestRevenue;

  /// No description provided for @dashboardStatMonthlyCollection.
  ///
  /// In en, this message translates to:
  /// **'Monthly Collection'**
  String get dashboardStatMonthlyCollection;

  /// No description provided for @dashboardCollectionTrend.
  ///
  /// In en, this message translates to:
  /// **'Collection Trend'**
  String get dashboardCollectionTrend;

  /// No description provided for @dashboardCollectionTrendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Last months from reports table'**
  String get dashboardCollectionTrendSubtitle;

  /// No description provided for @dashboardLoanStatus.
  ///
  /// In en, this message translates to:
  /// **'Loan Status'**
  String get dashboardLoanStatus;

  /// No description provided for @dashboardLoanStatusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live database summary'**
  String get dashboardLoanStatusSubtitle;

  /// No description provided for @dashboardDonutTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get dashboardDonutTotal;

  /// No description provided for @dashboardStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get dashboardStatusActive;

  /// No description provided for @dashboardStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get dashboardStatusOverdue;

  /// No description provided for @dashboardStatusClosedOther.
  ///
  /// In en, this message translates to:
  /// **'Closed/Other'**
  String get dashboardStatusClosedOther;

  /// No description provided for @dashboardAgentPerformance.
  ///
  /// In en, this message translates to:
  /// **'Agent Performance'**
  String get dashboardAgentPerformance;

  /// No description provided for @dashboardAgentPerformanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Top field agents from report'**
  String get dashboardAgentPerformanceSubtitle;

  /// No description provided for @dashboardMonthlyProgress.
  ///
  /// In en, this message translates to:
  /// **'Monthly Collection Progress'**
  String get dashboardMonthlyProgress;

  /// No description provided for @dashboardMonthlyProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'₹{collected} of ₹{target} target'**
  String dashboardMonthlyProgressSubtitle(String collected, String target);

  /// No description provided for @dashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardQuickAddCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get dashboardQuickAddCustomer;

  /// No description provided for @dashboardQuickCreateLoan.
  ///
  /// In en, this message translates to:
  /// **'Create Loan'**
  String get dashboardQuickCreateLoan;

  /// No description provided for @dashboardQuickChitGroup.
  ///
  /// In en, this message translates to:
  /// **'Chit Group'**
  String get dashboardQuickChitGroup;

  /// No description provided for @dashboardQuickAddAgent.
  ///
  /// In en, this message translates to:
  /// **'Add Agent'**
  String get dashboardQuickAddAgent;

  /// No description provided for @dashboardQuickReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get dashboardQuickReports;

  /// No description provided for @dashboardRecentCollections.
  ///
  /// In en, this message translates to:
  /// **'Recent Collections'**
  String get dashboardRecentCollections;

  /// No description provided for @dashboardRecentCollectionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Latest payments received'**
  String get dashboardRecentCollectionsSubtitle;

  /// No description provided for @dashboardNoCollectionsToday.
  ///
  /// In en, this message translates to:
  /// **'No collections found for today.'**
  String get dashboardNoCollectionsToday;

  /// No description provided for @dashboardRecentLoans.
  ///
  /// In en, this message translates to:
  /// **'Recent Loans'**
  String get dashboardRecentLoans;

  /// No description provided for @dashboardRecentLoansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Newly disbursed loans'**
  String get dashboardRecentLoansSubtitle;

  /// No description provided for @dashboardNoLoansToday.
  ///
  /// In en, this message translates to:
  /// **'No new loans found for today.'**
  String get dashboardNoLoansToday;

  /// No description provided for @dashboardViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dashboardViewAll;

  /// No description provided for @loansTitle.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get loansTitle;

  /// No description provided for @loansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage customer loans and repayment schedules'**
  String get loansSubtitle;

  /// No description provided for @loansCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Loan'**
  String get loansCreateButton;

  /// No description provided for @loansSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by customer or loan number...'**
  String get loansSearchHint;

  /// No description provided for @loansFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get loansFilterAll;

  /// No description provided for @loansStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get loansStatusActive;

  /// No description provided for @loansStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get loansStatusOverdue;

  /// No description provided for @loansStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get loansStatusClosed;

  /// No description provided for @loansStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get loansStatusPending;

  /// No description provided for @loansScheduleStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get loansScheduleStatusPaid;

  /// No description provided for @loansScheduleStatusDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due Today'**
  String get loansScheduleStatusDueToday;

  /// No description provided for @loansTypeMonthlyEmi.
  ///
  /// In en, this message translates to:
  /// **'Monthly EMI'**
  String get loansTypeMonthlyEmi;

  /// No description provided for @loansTypeMonthlyInterest.
  ///
  /// In en, this message translates to:
  /// **'Monthly Interest'**
  String get loansTypeMonthlyInterest;

  /// No description provided for @loansTypeWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get loansTypeWeekly;

  /// No description provided for @loansTypeDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get loansTypeDaily;

  /// No description provided for @loansScheduleEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No repayment schedule available.'**
  String get loansScheduleEmptyMessage;

  /// No description provided for @loansScheduleColIndex.
  ///
  /// In en, this message translates to:
  /// **'#'**
  String get loansScheduleColIndex;

  /// No description provided for @loansScheduleColDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get loansScheduleColDueDate;

  /// No description provided for @loansScheduleColEmi.
  ///
  /// In en, this message translates to:
  /// **'EMI'**
  String get loansScheduleColEmi;

  /// No description provided for @loansScheduleColPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get loansScheduleColPaid;

  /// No description provided for @loansScheduleColBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get loansScheduleColBalance;

  /// No description provided for @loansScheduleColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get loansScheduleColStatus;

  /// No description provided for @loansCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load loans: {error}'**
  String loansCouldNotLoad(String error);

  /// No description provided for @loansLoanCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Loan created'**
  String get loansLoanCreatedTitle;

  /// No description provided for @loansLoanUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Loan updated'**
  String get loansLoanUpdatedTitle;

  /// No description provided for @loansCloseLoanTitle.
  ///
  /// In en, this message translates to:
  /// **'Close Loan'**
  String get loansCloseLoanTitle;

  /// No description provided for @loansCloseLoanMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to close loan {loanNumber}?'**
  String loansCloseLoanMessage(String loanNumber);

  /// No description provided for @loansCloseLoanConfirm.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get loansCloseLoanConfirm;

  /// No description provided for @loansLoanClosedTitle.
  ///
  /// In en, this message translates to:
  /// **'Loan closed'**
  String get loansLoanClosedTitle;

  /// No description provided for @loansLoanClosedMessage.
  ///
  /// In en, this message translates to:
  /// **'Loan {loanNumber} was closed successfully.'**
  String loansLoanClosedMessage(String loanNumber);

  /// No description provided for @loansCloseFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Close failed'**
  String get loansCloseFailedTitle;

  /// No description provided for @loansCloseBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot close loan'**
  String get loansCloseBlockedTitle;

  /// No description provided for @loansCloseBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'This loan still has {amount} pending. Collect the full outstanding amount before closing it.'**
  String loansCloseBlockedMessage(String amount);

  /// No description provided for @loansDeleteLoanTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Loan'**
  String get loansDeleteLoanTitle;

  /// No description provided for @loansDeleteLoanMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete loan {loanNumber}? It will be moved to the Recycle Bin.'**
  String loansDeleteLoanMessage(String loanNumber);

  /// No description provided for @loansDeleteLoanConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get loansDeleteLoanConfirm;

  /// No description provided for @loansLoanDeletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Loan deleted'**
  String get loansLoanDeletedTitle;

  /// No description provided for @loansLoanDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Loan {loanNumber} was moved to the Recycle Bin.'**
  String loansLoanDeletedMessage(String loanNumber);

  /// No description provided for @loansDeleteFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get loansDeleteFailedTitle;

  /// No description provided for @loansNoLoansFound.
  ///
  /// In en, this message translates to:
  /// **'No loans found'**
  String get loansNoLoansFound;

  /// No description provided for @loansColHpNo.
  ///
  /// In en, this message translates to:
  /// **'HP No.'**
  String get loansColHpNo;

  /// No description provided for @loansColCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get loansColCustomer;

  /// No description provided for @loansColType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get loansColType;

  /// No description provided for @loansColAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get loansColAmount;

  /// No description provided for @loansColEmi.
  ///
  /// In en, this message translates to:
  /// **'EMI'**
  String get loansColEmi;

  /// No description provided for @loansColOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get loansColOutstanding;

  /// No description provided for @loansColAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get loansColAgent;

  /// No description provided for @loansColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get loansColStatus;

  /// No description provided for @loansColStart.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get loansColStart;

  /// No description provided for @loansColActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get loansColActions;

  /// No description provided for @loansActionView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get loansActionView;

  /// No description provided for @loansActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get loansActionEdit;

  /// No description provided for @loansActionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get loansActionClose;

  /// No description provided for @loansActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get loansActionDelete;

  /// No description provided for @loansDurationWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks'**
  String loansDurationWeeks(int count);

  /// No description provided for @loansDurationDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String loansDurationDays(int count);

  /// No description provided for @loansDurationMonthsInterestOnly.
  ///
  /// In en, this message translates to:
  /// **'{count} months (interest only)'**
  String loansDurationMonthsInterestOnly(int count);

  /// No description provided for @loansDurationMonths.
  ///
  /// In en, this message translates to:
  /// **'{count} months'**
  String loansDurationMonths(int count);

  /// No description provided for @loansDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Loan {loanNumber}'**
  String loansDetailTitle(String loanNumber);

  /// No description provided for @loansFieldCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get loansFieldCustomer;

  /// No description provided for @loansFieldLoanType.
  ///
  /// In en, this message translates to:
  /// **'Loan Type'**
  String get loansFieldLoanType;

  /// No description provided for @loansFieldLoanAmount.
  ///
  /// In en, this message translates to:
  /// **'Loan Amount'**
  String get loansFieldLoanAmount;

  /// No description provided for @loansFieldMonthlyInterest.
  ///
  /// In en, this message translates to:
  /// **'Monthly Interest'**
  String get loansFieldMonthlyInterest;

  /// No description provided for @loansFieldEmi.
  ///
  /// In en, this message translates to:
  /// **'EMI'**
  String get loansFieldEmi;

  /// No description provided for @loansFieldOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get loansFieldOutstanding;

  /// No description provided for @loansFieldPenalty.
  ///
  /// In en, this message translates to:
  /// **'Penalty'**
  String get loansFieldPenalty;

  /// No description provided for @loansFieldTotalDuePenalty.
  ///
  /// In en, this message translates to:
  /// **'Total Due (with Penalty)'**
  String get loansFieldTotalDuePenalty;

  /// No description provided for @loansFieldInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest Rate'**
  String get loansFieldInterest;

  /// No description provided for @loansFieldDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get loansFieldDuration;

  /// No description provided for @loansFieldStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get loansFieldStartDate;

  /// No description provided for @loansFieldAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get loansFieldAgent;

  /// No description provided for @loansHideSchedule.
  ///
  /// In en, this message translates to:
  /// **'Hide Schedule'**
  String get loansHideSchedule;

  /// No description provided for @loansShowSchedule.
  ///
  /// In en, this message translates to:
  /// **'Show Schedule'**
  String get loansShowSchedule;

  /// No description provided for @loansRepaymentSchedule.
  ///
  /// In en, this message translates to:
  /// **'Repayment Schedule'**
  String get loansRepaymentSchedule;

  /// No description provided for @loansRefreshScheduleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh schedule'**
  String get loansRefreshScheduleTooltip;

  /// No description provided for @loansInterestOnlyScheduleNote.
  ///
  /// In en, this message translates to:
  /// **'This is an interest-only loan. Principal repayment is flexible and isn\'t reflected in the schedule below.'**
  String get loansInterestOnlyScheduleNote;

  /// No description provided for @loansCustomerRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Required'**
  String get loansCustomerRequiredTitle;

  /// No description provided for @loansCustomerRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please select a customer before saving this loan.'**
  String get loansCustomerRequiredMessage;

  /// No description provided for @loansSaveFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Failed'**
  String get loansSaveFailedTitle;

  /// No description provided for @loansEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Loan'**
  String get loansEditTitle;

  /// No description provided for @loansCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Loan'**
  String get loansCreateTitle;

  /// No description provided for @loansHpNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'HP Number'**
  String get loansHpNumberLabel;

  /// No description provided for @loansHpNumberLoading.
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get loansHpNumberLoading;

  /// No description provided for @loansHpNumberAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto-generated'**
  String get loansHpNumberAuto;

  /// No description provided for @loansProcessingFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Processing Fee'**
  String get loansProcessingFeeLabel;

  /// No description provided for @loansProcessingFeeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter processing fee'**
  String get loansProcessingFeeHint;

  /// No description provided for @loansNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get loansNotesLabel;

  /// No description provided for @loansNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add any additional notes'**
  String get loansNotesHint;

  /// No description provided for @loansSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get loansSave;

  /// No description provided for @loansApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get loansApprove;

  /// No description provided for @loansCustomerRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer *'**
  String get loansCustomerRequiredLabel;

  /// No description provided for @loansCustomerHint.
  ///
  /// In en, this message translates to:
  /// **'Search customer'**
  String get loansCustomerHint;

  /// No description provided for @loansAgentLabel.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get loansAgentLabel;

  /// No description provided for @loansAgentHint.
  ///
  /// In en, this message translates to:
  /// **'Search agent'**
  String get loansAgentHint;

  /// No description provided for @loansCollectionTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Collection Type'**
  String get loansCollectionTypeLabel;

  /// No description provided for @loansLoanAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Loan Amount'**
  String get loansLoanAmountLabel;

  /// No description provided for @loansLoanAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Enter loan amount'**
  String get loansLoanAmountHint;

  /// No description provided for @loansInterestRateMonthlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly Interest Rate (%)'**
  String get loansInterestRateMonthlyLabel;

  /// No description provided for @loansInterestRateHint25.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2.5'**
  String get loansInterestRateHint25;

  /// No description provided for @loansDurationMonthsLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration (Months)'**
  String get loansDurationMonthsLabel;

  /// No description provided for @loansDurationHint10.
  ///
  /// In en, this message translates to:
  /// **'e.g. 10'**
  String get loansDurationHint10;

  /// No description provided for @loansMonthlyInterestRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly Interest Rate (%)'**
  String get loansMonthlyInterestRateLabel;

  /// No description provided for @loansLoanTenureLabel.
  ///
  /// In en, this message translates to:
  /// **'Loan Tenure (Months)'**
  String get loansLoanTenureLabel;

  /// No description provided for @loansInterestRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Interest Rate (%)'**
  String get loansInterestRateLabel;

  /// No description provided for @loansDurationFixedLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get loansDurationFixedLabel;

  /// No description provided for @loansDurationWeeksFixed.
  ///
  /// In en, this message translates to:
  /// **'10 weeks (fixed)'**
  String get loansDurationWeeksFixed;

  /// No description provided for @loansCollectionPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Collection Plan'**
  String get loansCollectionPlanLabel;

  /// No description provided for @loansPlan60Days.
  ///
  /// In en, this message translates to:
  /// **'60 Days'**
  String get loansPlan60Days;

  /// No description provided for @loansPlan100Days.
  ///
  /// In en, this message translates to:
  /// **'100 Days'**
  String get loansPlan100Days;

  /// No description provided for @loansInterestOnlyBoxTitle.
  ///
  /// In en, this message translates to:
  /// **'Interest-Only Loan'**
  String get loansInterestOnlyBoxTitle;

  /// No description provided for @loansInterestOnlyBoxBody.
  ///
  /// In en, this message translates to:
  /// **'The borrower repays only the monthly interest. Principal can be repaid anytime and isn\'t part of the fixed schedule.'**
  String get loansInterestOnlyBoxBody;

  /// No description provided for @loansWeeklyPenaltyTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Penalty'**
  String get loansWeeklyPenaltyTitle;

  /// No description provided for @loansDailyPenaltyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Penalty'**
  String get loansDailyPenaltyTitle;

  /// No description provided for @loansWeeklyPenaltyHelper.
  ///
  /// In en, this message translates to:
  /// **'Apply a fixed penalty for missed weekly payments.'**
  String get loansWeeklyPenaltyHelper;

  /// No description provided for @loansDailyPenaltyHelper.
  ///
  /// In en, this message translates to:
  /// **'Apply a daily penalty rate on overdue balances.'**
  String get loansDailyPenaltyHelper;

  /// No description provided for @loansDailyPenaltyRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Penalty Rate / Day'**
  String get loansDailyPenaltyRateLabel;

  /// No description provided for @loansDailyPenaltyRateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 50'**
  String get loansDailyPenaltyRateHint;

  /// No description provided for @loansDailyPenaltyExample.
  ///
  /// In en, this message translates to:
  /// **'Applied daily to any overdue balance.'**
  String get loansDailyPenaltyExample;

  /// No description provided for @loansWeeklyPenaltyAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Penalty Amount / Week'**
  String get loansWeeklyPenaltyAmountLabel;

  /// No description provided for @loansWeeklyPenaltyAmountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 100'**
  String get loansWeeklyPenaltyAmountHint;

  /// No description provided for @loansWeeklyPenaltyAutoNote.
  ///
  /// In en, this message translates to:
  /// **'Applied automatically each week a payment is missed.'**
  String get loansWeeklyPenaltyAutoNote;

  /// No description provided for @loansSummaryMonthlyEmi.
  ///
  /// In en, this message translates to:
  /// **'Monthly EMI'**
  String get loansSummaryMonthlyEmi;

  /// No description provided for @loansSummaryPerMonth.
  ///
  /// In en, this message translates to:
  /// **'for {count} months'**
  String loansSummaryPerMonth(int count);

  /// No description provided for @loansSummaryTotalInterest.
  ///
  /// In en, this message translates to:
  /// **'Total Interest'**
  String get loansSummaryTotalInterest;

  /// No description provided for @loansSummaryPerMonthAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} per month'**
  String loansSummaryPerMonthAmount(String amount);

  /// No description provided for @loansSummaryTotalRepayment.
  ///
  /// In en, this message translates to:
  /// **'Total Repayment'**
  String get loansSummaryTotalRepayment;

  /// No description provided for @loansSummaryPrincipalPlusInterest.
  ///
  /// In en, this message translates to:
  /// **'Principal + Interest'**
  String get loansSummaryPrincipalPlusInterest;

  /// No description provided for @loansSummaryMonthlyInterestDue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Interest Due'**
  String get loansSummaryMonthlyInterestDue;

  /// No description provided for @loansSummaryRateOfPrincipal.
  ///
  /// In en, this message translates to:
  /// **'{rate}% of {principal}'**
  String loansSummaryRateOfPrincipal(String rate, String principal);

  /// No description provided for @loansSummaryPrincipalRepayment.
  ///
  /// In en, this message translates to:
  /// **'Principal Repayment'**
  String get loansSummaryPrincipalRepayment;

  /// No description provided for @loansSummaryFlexibleInstallments.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get loansSummaryFlexibleInstallments;

  /// No description provided for @loansSummaryRepayAnytime.
  ///
  /// In en, this message translates to:
  /// **'Repay the principal anytime'**
  String get loansSummaryRepayAnytime;

  /// No description provided for @loansSummaryPrincipalDisbursed.
  ///
  /// In en, this message translates to:
  /// **'Principal Disbursed'**
  String get loansSummaryPrincipalDisbursed;

  /// No description provided for @loansSummaryTenureMonths.
  ///
  /// In en, this message translates to:
  /// **'Over {count} months'**
  String loansSummaryTenureMonths(int count);

  /// No description provided for @loansSummaryWeeklyInstallment.
  ///
  /// In en, this message translates to:
  /// **'Weekly Installment'**
  String get loansSummaryWeeklyInstallment;

  /// No description provided for @loansSummaryWeeksEqual.
  ///
  /// In en, this message translates to:
  /// **'10 weeks totalling {principal}'**
  String loansSummaryWeeksEqual(String principal);

  /// No description provided for @loansSummaryInterestDeducted.
  ///
  /// In en, this message translates to:
  /// **'Interest Deducted'**
  String get loansSummaryInterestDeducted;

  /// No description provided for @loansSummaryDeductedUpfront.
  ///
  /// In en, this message translates to:
  /// **'Deducted upfront'**
  String get loansSummaryDeductedUpfront;

  /// No description provided for @loansSummaryAmountDisbursed.
  ///
  /// In en, this message translates to:
  /// **'Amount Disbursed'**
  String get loansSummaryAmountDisbursed;

  /// No description provided for @loansSummaryPrincipalMinusInterest.
  ///
  /// In en, this message translates to:
  /// **'Principal − Interest'**
  String get loansSummaryPrincipalMinusInterest;

  /// No description provided for @loansSummaryDailyInstallment.
  ///
  /// In en, this message translates to:
  /// **'Daily Installment'**
  String get loansSummaryDailyInstallment;

  /// No description provided for @loansSummaryDaysEqual.
  ///
  /// In en, this message translates to:
  /// **'{days} days totalling {total}'**
  String loansSummaryDaysEqual(int days, String total);

  /// No description provided for @loansSummaryInterestAdded.
  ///
  /// In en, this message translates to:
  /// **'Interest Added'**
  String get loansSummaryInterestAdded;

  /// No description provided for @loansSummaryAddedToRepayment.
  ///
  /// In en, this message translates to:
  /// **'Added to total repayment'**
  String get loansSummaryAddedToRepayment;

  /// No description provided for @loansSummaryAmountDisbursedToBorrower.
  ///
  /// In en, this message translates to:
  /// **'Amount Disbursed to Borrower'**
  String get loansSummaryAmountDisbursedToBorrower;

  /// No description provided for @loansSummaryFullLoanAmount.
  ///
  /// In en, this message translates to:
  /// **'Full loan amount'**
  String get loansSummaryFullLoanAmount;

  /// No description provided for @loansScheduleSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Repayment Schedule Preview'**
  String get loansScheduleSectionTitle;

  /// No description provided for @loansStartDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get loansStartDateLabel;

  /// No description provided for @loansStartDateHint.
  ///
  /// In en, this message translates to:
  /// **'DD/MM/YYYY'**
  String get loansStartDateHint;

  /// No description provided for @repaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Repayment Schedule'**
  String get repaymentTitle;

  /// No description provided for @repaymentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track installment-wise EMI collections and outstanding balances'**
  String get repaymentSubtitle;

  /// No description provided for @repaymentCouldNotLoadLoans.
  ///
  /// In en, this message translates to:
  /// **'Could not load loans'**
  String get repaymentCouldNotLoadLoans;

  /// No description provided for @repaymentLoanLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Loan load failed'**
  String get repaymentLoanLoadFailedTitle;

  /// No description provided for @repaymentCouldNotLoadSchedule.
  ///
  /// In en, this message translates to:
  /// **'Could not load repayment schedule'**
  String get repaymentCouldNotLoadSchedule;

  /// No description provided for @repaymentLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get repaymentLoadFailedTitle;

  /// No description provided for @repaymentSelectLoanLabel.
  ///
  /// In en, this message translates to:
  /// **'SELECT LOAN'**
  String get repaymentSelectLoanLabel;

  /// No description provided for @repaymentSelectLoanHint.
  ///
  /// In en, this message translates to:
  /// **'Select loan'**
  String get repaymentSelectLoanHint;

  /// No description provided for @repaymentLoanSwitchedTitle.
  ///
  /// In en, this message translates to:
  /// **'Loan switched'**
  String get repaymentLoanSwitchedTitle;

  /// No description provided for @repaymentInstallmentBreakdown.
  ///
  /// In en, this message translates to:
  /// **'INSTALLMENT BREAKDOWN'**
  String get repaymentInstallmentBreakdown;

  /// No description provided for @repaymentNoInstallmentsFound.
  ///
  /// In en, this message translates to:
  /// **'No installments found for this loan'**
  String get repaymentNoInstallmentsFound;

  /// No description provided for @repaymentStatLoanNumber.
  ///
  /// In en, this message translates to:
  /// **'LOAN NUMBER'**
  String get repaymentStatLoanNumber;

  /// No description provided for @repaymentStatCustomer.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER'**
  String get repaymentStatCustomer;

  /// No description provided for @repaymentStatLoanAmount.
  ///
  /// In en, this message translates to:
  /// **'LOAN AMOUNT'**
  String get repaymentStatLoanAmount;

  /// No description provided for @repaymentStatEmi.
  ///
  /// In en, this message translates to:
  /// **'EMI'**
  String get repaymentStatEmi;

  /// No description provided for @repaymentStatTotalRepayment.
  ///
  /// In en, this message translates to:
  /// **'TOTAL REPAYMENT'**
  String get repaymentStatTotalRepayment;

  /// No description provided for @repaymentStatOutstanding.
  ///
  /// In en, this message translates to:
  /// **'OUTSTANDING'**
  String get repaymentStatOutstanding;

  /// No description provided for @repaymentStatPenalty.
  ///
  /// In en, this message translates to:
  /// **'PENALTY'**
  String get repaymentStatPenalty;

  /// No description provided for @repaymentStatTotalDuePenalty.
  ///
  /// In en, this message translates to:
  /// **'TOTAL DUE + PENALTY'**
  String get repaymentStatTotalDuePenalty;

  /// No description provided for @repaymentStatTotalInstallments.
  ///
  /// In en, this message translates to:
  /// **'TOTAL INST.'**
  String get repaymentStatTotalInstallments;

  /// No description provided for @repaymentStatPaid.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get repaymentStatPaid;

  /// No description provided for @repaymentStatPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get repaymentStatPending;

  /// No description provided for @repaymentStatOverdue.
  ///
  /// In en, this message translates to:
  /// **'OVERDUE'**
  String get repaymentStatOverdue;

  /// No description provided for @repaymentStatNextDue.
  ///
  /// In en, this message translates to:
  /// **'NEXT DUE'**
  String get repaymentStatNextDue;

  /// No description provided for @repaymentColInstNo.
  ///
  /// In en, this message translates to:
  /// **'INST. NO'**
  String get repaymentColInstNo;

  /// No description provided for @repaymentColDueDate.
  ///
  /// In en, this message translates to:
  /// **'DUE DATE'**
  String get repaymentColDueDate;

  /// No description provided for @repaymentColEmiAmount.
  ///
  /// In en, this message translates to:
  /// **'EMI AMOUNT'**
  String get repaymentColEmiAmount;

  /// No description provided for @repaymentColPaid.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get repaymentColPaid;

  /// No description provided for @repaymentColBalance.
  ///
  /// In en, this message translates to:
  /// **'BALANCE'**
  String get repaymentColBalance;

  /// No description provided for @repaymentColPenalty.
  ///
  /// In en, this message translates to:
  /// **'PENALTY'**
  String get repaymentColPenalty;

  /// No description provided for @repaymentColStatus.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get repaymentColStatus;

  /// No description provided for @repaymentNoLoanSelected.
  ///
  /// In en, this message translates to:
  /// **'No loan selected'**
  String get repaymentNoLoanSelected;

  /// No description provided for @repaymentPenaltyBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'{type} Finance ({duration})'**
  String repaymentPenaltyBannerTitle(String type, String duration);

  /// No description provided for @repaymentPenaltyBannerWeeklyBody.
  ///
  /// In en, this message translates to:
  /// **'Automatic default penalty of ₹100 applies per ₹10,000 principal for every missed weekly payment.'**
  String get repaymentPenaltyBannerWeeklyBody;

  /// No description provided for @repaymentPenaltyBannerRateBody.
  ///
  /// In en, this message translates to:
  /// **'A penalty of {rate} per day applies for every day a payment remains overdue.'**
  String repaymentPenaltyBannerRateBody(String rate);

  /// No description provided for @repaymentAccruedPenaltyLabel.
  ///
  /// In en, this message translates to:
  /// **'ACCRUED PENALTY: {amount}'**
  String repaymentAccruedPenaltyLabel(String amount);

  /// No description provided for @repaymentDurationWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 Week} other{{count} Weeks}}'**
  String repaymentDurationWeeks(int count);

  /// No description provided for @repaymentDurationMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 Month} other{{count} Months}}'**
  String repaymentDurationMonths(int count);

  /// No description provided for @repaymentDurationDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 Day} other{{count} Days}}'**
  String repaymentDurationDays(int count);

  /// No description provided for @repaymentRecordCollectionButton.
  ///
  /// In en, this message translates to:
  /// **'Record Collection'**
  String get repaymentRecordCollectionButton;

  /// No description provided for @repaymentRecordCollectionSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Record Collection'**
  String get repaymentRecordCollectionSheetTitle;

  /// No description provided for @repaymentRecordCollectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{loanNumber} — {customer}'**
  String repaymentRecordCollectionSubtitle(String loanNumber, String customer);

  /// No description provided for @repaymentRecordCollectionInstallmentLabel.
  ///
  /// In en, this message translates to:
  /// **'INSTALLMENT'**
  String get repaymentRecordCollectionInstallmentLabel;

  /// No description provided for @repaymentRecordCollectionGeneralPayment.
  ///
  /// In en, this message translates to:
  /// **'General Payment'**
  String get repaymentRecordCollectionGeneralPayment;

  /// No description provided for @repaymentRecordCollectionAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'AMOUNT'**
  String get repaymentRecordCollectionAmountLabel;

  /// No description provided for @repaymentRecordCollectionMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT METHOD'**
  String get repaymentRecordCollectionMethodLabel;

  /// No description provided for @repaymentRecordCollectionDateLabel.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT DATE'**
  String get repaymentRecordCollectionDateLabel;

  /// No description provided for @repaymentRecordCollectionNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'NOTES (OPTIONAL)'**
  String get repaymentRecordCollectionNotesLabel;

  /// No description provided for @repaymentRecordCollectionNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note about this payment'**
  String get repaymentRecordCollectionNotesHint;

  /// No description provided for @repaymentRecordCollectionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Save Collection'**
  String get repaymentRecordCollectionSubmit;

  /// No description provided for @repaymentRecordCollectionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get repaymentRecordCollectionCancel;

  /// No description provided for @repaymentRecordCollectionAllPaidTitle.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get repaymentRecordCollectionAllPaidTitle;

  /// No description provided for @repaymentRecordCollectionAllPaidMessage.
  ///
  /// In en, this message translates to:
  /// **'Every installment on this loan is already paid.'**
  String get repaymentRecordCollectionAllPaidMessage;

  /// No description provided for @repaymentRecordCollectionSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Collection recorded'**
  String get repaymentRecordCollectionSuccessTitle;

  /// No description provided for @repaymentRecordCollectionFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not record collection'**
  String get repaymentRecordCollectionFailedTitle;

  /// No description provided for @repaymentRecordCollectionSelectLoanFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a loan first'**
  String get repaymentRecordCollectionSelectLoanFirst;

  /// No description provided for @repaymentRecordCollectionAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get repaymentRecordCollectionAmountRequired;

  /// No description provided for @collectionsLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to load collections'**
  String get collectionsLoadFailedTitle;

  /// No description provided for @collectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collectionsTitle;

  /// No description provided for @collectionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record and track daily collections across all loans'**
  String get collectionsSubtitle;

  /// No description provided for @collectionsAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Collection'**
  String get collectionsAddButton;

  /// No description provided for @collectionsStatTodayTotal.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S TOTAL'**
  String get collectionsStatTodayTotal;

  /// No description provided for @collectionsStatThisWeek.
  ///
  /// In en, this message translates to:
  /// **'THIS WEEK'**
  String get collectionsStatThisWeek;

  /// No description provided for @collectionsStatThisMonth.
  ///
  /// In en, this message translates to:
  /// **'THIS MONTH'**
  String get collectionsStatThisMonth;

  /// No description provided for @collectionsStatTotalRecords.
  ///
  /// In en, this message translates to:
  /// **'TOTAL RECORDS'**
  String get collectionsStatTotalRecords;

  /// No description provided for @collectionsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search customer, loan or receipt number...'**
  String get collectionsSearchHint;

  /// No description provided for @collectionsPeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get collectionsPeriodToday;

  /// No description provided for @collectionsPeriodThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get collectionsPeriodThisWeek;

  /// No description provided for @collectionsPeriodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get collectionsPeriodThisMonth;

  /// No description provided for @collectionsColCustomer.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER'**
  String get collectionsColCustomer;

  /// No description provided for @collectionsColLoanNumber.
  ///
  /// In en, this message translates to:
  /// **'LOAN NUMBER'**
  String get collectionsColLoanNumber;

  /// No description provided for @collectionsColAmount.
  ///
  /// In en, this message translates to:
  /// **'AMOUNT'**
  String get collectionsColAmount;

  /// No description provided for @collectionsColMethod.
  ///
  /// In en, this message translates to:
  /// **'METHOD'**
  String get collectionsColMethod;

  /// No description provided for @collectionsColDate.
  ///
  /// In en, this message translates to:
  /// **'DATE'**
  String get collectionsColDate;

  /// No description provided for @collectionsColAgent.
  ///
  /// In en, this message translates to:
  /// **'AGENT'**
  String get collectionsColAgent;

  /// No description provided for @collectionsColActions.
  ///
  /// In en, this message translates to:
  /// **'ACTIONS'**
  String get collectionsColActions;

  /// No description provided for @collectionsActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get collectionsActionEdit;

  /// No description provided for @collectionsActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get collectionsActionDelete;

  /// No description provided for @collectionsNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No collections found'**
  String get collectionsNoneFound;

  /// No description provided for @collectionsShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get collectionsShowLess;

  /// No description provided for @collectionsShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show More ({count} more)'**
  String collectionsShowMore(int count);

  /// No description provided for @collectionsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Collection'**
  String get collectionsDeleteTitle;

  /// No description provided for @collectionsDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete the collection record for {customer} ({receipt})? It will be moved to the Recycle Bin and can be restored later.'**
  String collectionsDeleteMessage(String customer, String receipt);

  /// No description provided for @collectionsDeleteFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get collectionsDeleteFailedTitle;

  /// No description provided for @collectionsUpdateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get collectionsUpdateFailedTitle;

  /// No description provided for @collectionsRecordIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find record id'**
  String get collectionsRecordIdNotFound;

  /// No description provided for @collectionsDeletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Collection deleted'**
  String get collectionsDeletedTitle;

  /// No description provided for @collectionsDeleteApiFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete collection'**
  String get collectionsDeleteApiFailedTitle;

  /// No description provided for @collectionsRecordedTitle.
  ///
  /// In en, this message translates to:
  /// **'Collection recorded'**
  String get collectionsRecordedTitle;

  /// No description provided for @collectionsSaveFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to save collection'**
  String get collectionsSaveFailedTitle;

  /// No description provided for @collectionsUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Collection updated'**
  String get collectionsUpdatedTitle;

  /// No description provided for @collectionsUpdateApiFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to update collection'**
  String get collectionsUpdateApiFailedTitle;

  /// No description provided for @collectionsMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get collectionsMethodCash;

  /// No description provided for @collectionsMethodUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get collectionsMethodUpi;

  /// No description provided for @collectionsMethodBank.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get collectionsMethodBank;

  /// No description provided for @collectionsMethodCheque.
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get collectionsMethodCheque;

  /// No description provided for @collectionsMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get collectionsMethodCard;

  /// No description provided for @collectionsSelectCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a customer'**
  String get collectionsSelectCustomerTitle;

  /// No description provided for @collectionsSelectCustomerMessage.
  ///
  /// In en, this message translates to:
  /// **'Please choose a customer before saving.'**
  String get collectionsSelectCustomerMessage;

  /// No description provided for @collectionsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Collection'**
  String get collectionsEditTitle;

  /// No description provided for @collectionsCustomerRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER *'**
  String get collectionsCustomerRequiredLabel;

  /// No description provided for @collectionsSelectCustomerHint.
  ///
  /// In en, this message translates to:
  /// **'Select customer'**
  String get collectionsSelectCustomerHint;

  /// No description provided for @collectionsLoanNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'LOAN NUMBER'**
  String get collectionsLoanNumberLabel;

  /// No description provided for @collectionsSelectCustomerFirstHint.
  ///
  /// In en, this message translates to:
  /// **'Select customer first'**
  String get collectionsSelectCustomerFirstHint;

  /// No description provided for @collectionsSelectLoanHint.
  ///
  /// In en, this message translates to:
  /// **'Select loan'**
  String get collectionsSelectLoanHint;

  /// No description provided for @collectionsOutstandingAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get collectionsOutstandingAbbrev;

  /// No description provided for @collectionsSelectLoanPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a loan to view its live details'**
  String get collectionsSelectLoanPrompt;

  /// No description provided for @collectionsLoansLinkedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} loan linked to the selected customer} other{{count} loans linked to the selected customer}}'**
  String collectionsLoansLinkedCount(int count);

  /// No description provided for @collectionsAmountReceivedLabel.
  ///
  /// In en, this message translates to:
  /// **'AMOUNT RECEIVED *'**
  String get collectionsAmountReceivedLabel;

  /// No description provided for @collectionsPaymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT METHOD *'**
  String get collectionsPaymentMethodLabel;

  /// No description provided for @collectionsCollectionDateLabel.
  ///
  /// In en, this message translates to:
  /// **'COLLECTION DATE *'**
  String get collectionsCollectionDateLabel;

  /// No description provided for @collectionsSelectAgentHint.
  ///
  /// In en, this message translates to:
  /// **'Select agent'**
  String get collectionsSelectAgentHint;

  /// No description provided for @collectionsNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'NOTES'**
  String get collectionsNotesLabel;

  /// No description provided for @collectionsNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Any remarks about this collection...'**
  String get collectionsNotesHint;

  /// No description provided for @collectionsPaymentScreenshotLabel.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT SCREENSHOT'**
  String get collectionsPaymentScreenshotLabel;

  /// No description provided for @collectionsCustomerSignatureLabel.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER SIGNATURE'**
  String get collectionsCustomerSignatureLabel;

  /// No description provided for @collectionsCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get collectionsCancelButton;

  /// No description provided for @collectionsReceiptButton.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get collectionsReceiptButton;

  /// No description provided for @collectionsUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get collectionsUpdateButton;

  /// No description provided for @collectionsSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get collectionsSaveButton;

  /// No description provided for @collectionsGeneratingReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Generating receipt...'**
  String get collectionsGeneratingReceiptTitle;

  /// No description provided for @collectionsUploadSignatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Customer Signature'**
  String get collectionsUploadSignatureTitle;

  /// No description provided for @collectionsUploadScreenshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Payment Screenshot'**
  String get collectionsUploadScreenshotTitle;

  /// No description provided for @collectionsUploadPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Upload document...'**
  String get collectionsUploadPlaceholder;

  /// No description provided for @collectionsSummaryAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent: {name}'**
  String collectionsSummaryAgent(String name);

  /// No description provided for @collectionsSummaryPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Principal: {amount}'**
  String collectionsSummaryPrincipal(String amount);

  /// No description provided for @collectionsSummaryInstallment.
  ///
  /// In en, this message translates to:
  /// **'Installment: {amount}'**
  String collectionsSummaryInstallment(String amount);

  /// No description provided for @collectionsSummaryOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding: {amount}'**
  String collectionsSummaryOutstanding(String amount);

  /// No description provided for @collectionsSummaryOverdueDue.
  ///
  /// In en, this message translates to:
  /// **'Overdue due: {amount}'**
  String collectionsSummaryOverdueDue(String amount);

  /// No description provided for @collectionsSummaryPenalty.
  ///
  /// In en, this message translates to:
  /// **'Penalty: {amount}'**
  String collectionsSummaryPenalty(String amount);

  /// No description provided for @collectionsSummaryTotalDue.
  ///
  /// In en, this message translates to:
  /// **'Total due: {amount}'**
  String collectionsSummaryTotalDue(String amount);

  /// No description provided for @collectionsPresetOneEmi.
  ///
  /// In en, this message translates to:
  /// **'1 EMI'**
  String get collectionsPresetOneEmi;

  /// No description provided for @collectionsPresetFillInterest.
  ///
  /// In en, this message translates to:
  /// **'Fill Interest'**
  String get collectionsPresetFillInterest;

  /// No description provided for @collectionsPresetPayDue.
  ///
  /// In en, this message translates to:
  /// **'Pay Due Amount'**
  String get collectionsPresetPayDue;

  /// No description provided for @collectionsPresetPrincipalPartPayment.
  ///
  /// In en, this message translates to:
  /// **'Principal Part-Payment'**
  String get collectionsPresetPrincipalPartPayment;

  /// No description provided for @collectionsPresetFullBalance.
  ///
  /// In en, this message translates to:
  /// **'Full Balance'**
  String get collectionsPresetFullBalance;

  /// No description provided for @collectionsPurposeMonthlyInterest.
  ///
  /// In en, this message translates to:
  /// **'Monthly Interest Payment'**
  String get collectionsPurposeMonthlyInterest;

  /// No description provided for @collectionsPaymentSummaryLine.
  ///
  /// In en, this message translates to:
  /// **'Payment: {payment} • Remaining balance: {remaining}'**
  String collectionsPaymentSummaryLine(String payment, String remaining);

  /// No description provided for @handoverLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to load handover data'**
  String get handoverLoadFailedTitle;

  /// No description provided for @handoverUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Handover updated'**
  String get handoverUpdatedTitle;

  /// No description provided for @handoverRecordedTitle.
  ///
  /// In en, this message translates to:
  /// **'Handover recorded'**
  String get handoverRecordedTitle;

  /// No description provided for @handoverFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Handover failed'**
  String get handoverFailedTitle;

  /// No description provided for @handoverMarkedPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Marked pending'**
  String get handoverMarkedPendingTitle;

  /// No description provided for @handoverMarkedVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Marked verified'**
  String get handoverMarkedVerifiedTitle;

  /// No description provided for @handoverUpdateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not update handover'**
  String get handoverUpdateFailedTitle;

  /// No description provided for @handoverDeletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Handover deleted'**
  String get handoverDeletedTitle;

  /// No description provided for @handoverDeleteFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not delete handover'**
  String get handoverDeleteFailedTitle;

  /// No description provided for @handoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash Handover'**
  String get handoverTitle;

  /// No description provided for @handoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Agents settle collected cash & UPI to the office — pending carries forward'**
  String get handoverSubtitle;

  /// No description provided for @handoverRecordButton.
  ///
  /// In en, this message translates to:
  /// **'Record Handover'**
  String get handoverRecordButton;

  /// No description provided for @handoverStatTotalCollected.
  ///
  /// In en, this message translates to:
  /// **'Total Collected'**
  String get handoverStatTotalCollected;

  /// No description provided for @handoverStatTodayZero.
  ///
  /// In en, this message translates to:
  /// **'Today: ₹0'**
  String get handoverStatTodayZero;

  /// No description provided for @handoverStatHandedOver.
  ///
  /// In en, this message translates to:
  /// **'Handed Over'**
  String get handoverStatHandedOver;

  /// No description provided for @handoverStatPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get handoverStatPending;

  /// No description provided for @handoverStatAgentsWithPending.
  ///
  /// In en, this message translates to:
  /// **'Agents With Pending'**
  String get handoverStatAgentsWithPending;

  /// No description provided for @handoverSettlementPositionTitle.
  ///
  /// In en, this message translates to:
  /// **'Agent Settlement Position'**
  String get handoverSettlementPositionTitle;

  /// No description provided for @handoverSettlementPositionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pending = collected − handed over (runs continuously)'**
  String get handoverSettlementPositionSubtitle;

  /// No description provided for @handoverHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Handover History'**
  String get handoverHistoryTitle;

  /// No description provided for @handoverHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No handovers recorded yet.'**
  String get handoverHistoryEmpty;

  /// No description provided for @handoverColAgent.
  ///
  /// In en, this message translates to:
  /// **'AGENT'**
  String get handoverColAgent;

  /// No description provided for @handoverColCollected.
  ///
  /// In en, this message translates to:
  /// **'COLLECTED'**
  String get handoverColCollected;

  /// No description provided for @handoverColHandedOver.
  ///
  /// In en, this message translates to:
  /// **'HANDED OVER'**
  String get handoverColHandedOver;

  /// No description provided for @handoverColPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get handoverColPending;

  /// No description provided for @handoverDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Handover?'**
  String get handoverDeleteConfirmTitle;

  /// No description provided for @handoverDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'{agentName}\'s handover record of {amount} will be moved to the Recycle Bin and can be restored later.'**
  String handoverDeleteConfirmMessage(String agentName, String amount);

  /// No description provided for @handoverDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get handoverDeleteButton;

  /// No description provided for @handoverStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'verified'**
  String get handoverStatusVerified;

  /// No description provided for @handoverStatusPending.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get handoverStatusPending;

  /// No description provided for @handoverReceivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get handoverReceivedLabel;

  /// No description provided for @handoverEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get handoverEditButton;

  /// No description provided for @handoverUnverifyButton.
  ///
  /// In en, this message translates to:
  /// **'Unverify'**
  String get handoverUnverifyButton;

  /// No description provided for @handoverVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get handoverVerifyButton;

  /// No description provided for @handoverSummaryLine.
  ///
  /// In en, this message translates to:
  /// **'{date} · {cash} cash · {upi} UPI'**
  String handoverSummaryLine(String date, String cash, String upi);

  /// No description provided for @handoverSelectAgentValidator.
  ///
  /// In en, this message translates to:
  /// **'Select an agent'**
  String get handoverSelectAgentValidator;

  /// No description provided for @handoverCashAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'CASH AMOUNT'**
  String get handoverCashAmountLabel;

  /// No description provided for @handoverUpiAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'UPI AMOUNT'**
  String get handoverUpiAmountLabel;

  /// No description provided for @handoverNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'NOTES'**
  String get handoverNotesLabel;

  /// No description provided for @handoverNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional remarks'**
  String get handoverNotesHint;

  /// No description provided for @handoverDateLabel.
  ///
  /// In en, this message translates to:
  /// **'DATE *'**
  String get handoverDateLabel;

  /// No description provided for @handoverRecordActionButton.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get handoverRecordActionButton;

  /// No description provided for @handoverSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get handoverSaveButton;

  /// No description provided for @handoverCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get handoverCancelButton;

  /// No description provided for @handoverRefreshButton.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get handoverRefreshButton;

  /// No description provided for @handoverStatToday.
  ///
  /// In en, this message translates to:
  /// **'Today: {amount}'**
  String handoverStatToday(String amount);

  /// No description provided for @handoverStatPendingToHandOver.
  ///
  /// In en, this message translates to:
  /// **'Pending to Hand Over'**
  String get handoverStatPendingToHandOver;

  /// No description provided for @handoverStatCashCollected.
  ///
  /// In en, this message translates to:
  /// **'Cash Collected'**
  String get handoverStatCashCollected;

  /// No description provided for @handoverStatOnlineUpi.
  ///
  /// In en, this message translates to:
  /// **'Online / UPI'**
  String get handoverStatOnlineUpi;

  /// No description provided for @handoverStillPendingBanner.
  ///
  /// In en, this message translates to:
  /// **'You have {amount} still to hand over. This balance carries forward — tomorrow\'s collections add on top of it until you settle.'**
  String handoverStillPendingBanner(String amount);

  /// No description provided for @accountBookSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track cash in hand and outstanding money lent'**
  String get accountBookSubtitle;

  /// No description provided for @accountTabAllEntries.
  ///
  /// In en, this message translates to:
  /// **'All Entries'**
  String get accountTabAllEntries;

  /// No description provided for @accountTabCashInHand.
  ///
  /// In en, this message translates to:
  /// **'Cash In Hand'**
  String get accountTabCashInHand;

  /// No description provided for @accountTabOutstandingLent.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Lent'**
  String get accountTabOutstandingLent;

  /// No description provided for @accountAddEntryButton.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get accountAddEntryButton;

  /// No description provided for @accountAddCashEntryButton.
  ///
  /// In en, this message translates to:
  /// **'Add Cash Entry'**
  String get accountAddCashEntryButton;

  /// No description provided for @accountAddMoneyLentButton.
  ///
  /// In en, this message translates to:
  /// **'Add Money Lent'**
  String get accountAddMoneyLentButton;

  /// No description provided for @accountEntrySavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Entry Saved'**
  String get accountEntrySavedTitle;

  /// No description provided for @accountEntrySavedMessage.
  ///
  /// In en, this message translates to:
  /// **'The ledger entry has been added successfully.'**
  String get accountEntrySavedMessage;

  /// No description provided for @accountEntryUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Entry Updated'**
  String get accountEntryUpdatedTitle;

  /// No description provided for @accountEntryUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'The ledger entry has been updated successfully.'**
  String get accountEntryUpdatedMessage;

  /// No description provided for @accountEntryDeletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Entry Deleted'**
  String get accountEntryDeletedTitle;

  /// No description provided for @accountEntryDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'The ledger entry has been removed.'**
  String get accountEntryDeletedMessage;

  /// No description provided for @accountDeleteFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Failed'**
  String get accountDeleteFailedTitle;

  /// No description provided for @accountDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This action cannot be undone.'**
  String accountDeleteConfirmMessage(String title);

  /// No description provided for @accountNetBalanceSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Net Balance Summary'**
  String get accountNetBalanceSummaryTitle;

  /// No description provided for @accountCashInHandLabel.
  ///
  /// In en, this message translates to:
  /// **'Cash In Hand'**
  String get accountCashInHandLabel;

  /// No description provided for @accountOutstandingLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Money Lent'**
  String get accountOutstandingLabel;

  /// No description provided for @accountNetBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get accountNetBalanceLabel;

  /// No description provided for @accountUpdatingBadge.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get accountUpdatingBadge;

  /// No description provided for @accountLiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get accountLiveBadge;

  /// No description provided for @accountSummaryRefreshError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh summary: {error}'**
  String accountSummaryRefreshError(String error);

  /// No description provided for @accountCashInHandSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Total liquid cash available'**
  String get accountCashInHandSubtitle;

  /// No description provided for @accountBreakdownLoanCollection.
  ///
  /// In en, this message translates to:
  /// **'Loan Collections'**
  String get accountBreakdownLoanCollection;

  /// No description provided for @accountBreakdownFundDeposits.
  ///
  /// In en, this message translates to:
  /// **'Fund Deposits'**
  String get accountBreakdownFundDeposits;

  /// No description provided for @accountBreakdownChitCollection.
  ///
  /// In en, this message translates to:
  /// **'Chit Collections'**
  String get accountBreakdownChitCollection;

  /// No description provided for @accountBreakdownCustomCashNet.
  ///
  /// In en, this message translates to:
  /// **'Custom Cash Entries'**
  String get accountBreakdownCustomCashNet;

  /// No description provided for @accountOutstandingMoneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Money'**
  String get accountOutstandingMoneyTitle;

  /// No description provided for @accountOutstandingMoneySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Total money owed to you'**
  String get accountOutstandingMoneySubtitle;

  /// No description provided for @accountBreakdownLoanOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Loan Outstanding'**
  String get accountBreakdownLoanOutstanding;

  /// No description provided for @accountBreakdownChitPending.
  ///
  /// In en, this message translates to:
  /// **'Chit Pending'**
  String get accountBreakdownChitPending;

  /// No description provided for @accountBreakdownFundPending.
  ///
  /// In en, this message translates to:
  /// **'Fund Pending'**
  String get accountBreakdownFundPending;

  /// No description provided for @accountBreakdownCustomMoneyLent.
  ///
  /// In en, this message translates to:
  /// **'Custom Money Lent'**
  String get accountBreakdownCustomMoneyLent;

  /// No description provided for @accountSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title or category...'**
  String get accountSearchHint;

  /// No description provided for @accountLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Entries'**
  String get accountLoadFailedTitle;

  /// No description provided for @accountEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'No Entries Yet'**
  String get accountEmptyStateTitle;

  /// No description provided for @accountEmptyStateBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first cash or lending entry to start tracking your account book.'**
  String get accountEmptyStateBody;

  /// No description provided for @accountColDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get accountColDate;

  /// No description provided for @accountColTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get accountColTitle;

  /// No description provided for @accountColCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get accountColCategory;

  /// No description provided for @accountColSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get accountColSection;

  /// No description provided for @accountColType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get accountColType;

  /// No description provided for @accountColAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get accountColAmount;

  /// No description provided for @accountColActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get accountColActions;

  /// No description provided for @accountMissingTitleTitle.
  ///
  /// In en, this message translates to:
  /// **'Title Required'**
  String get accountMissingTitleTitle;

  /// No description provided for @accountMissingTitleMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title for this entry.'**
  String get accountMissingTitleMessage;

  /// No description provided for @accountInvalidDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid Date'**
  String get accountInvalidDateTitle;

  /// No description provided for @accountInvalidDateMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid date in dd/mm/yyyy format.'**
  String get accountInvalidDateMessage;

  /// No description provided for @accountUpdateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Failed'**
  String get accountUpdateFailedTitle;

  /// No description provided for @accountSaveFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Failed'**
  String get accountSaveFailedTitle;

  /// No description provided for @accountEditEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get accountEditEntryTitle;

  /// No description provided for @accountAddEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get accountAddEntryTitle;

  /// No description provided for @accountEntryTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get accountEntryTitleLabel;

  /// No description provided for @accountEntryTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Office rent, Cash deposit'**
  String get accountEntryTitleHint;

  /// No description provided for @accountEntryTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Entry Type'**
  String get accountEntryTypeLabel;

  /// No description provided for @accountAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get accountAmountLabel;

  /// No description provided for @accountAmountHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get accountAmountHint;

  /// No description provided for @accountCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get accountCategoryLabel;

  /// No description provided for @accountEntryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get accountEntryDateLabel;

  /// No description provided for @accountEntryDateHint.
  ///
  /// In en, this message translates to:
  /// **'dd/mm/yyyy'**
  String get accountEntryDateHint;

  /// No description provided for @accountNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get accountNotesLabel;

  /// No description provided for @accountNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes about this entry'**
  String get accountNotesHint;

  /// No description provided for @accountUpdateEntryButton.
  ///
  /// In en, this message translates to:
  /// **'Update Entry'**
  String get accountUpdateEntryButton;

  /// No description provided for @accountSaveEntryButton.
  ///
  /// In en, this message translates to:
  /// **'Save Entry'**
  String get accountSaveEntryButton;

  /// No description provided for @overdueManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Overdue Management'**
  String get overdueManagementTitle;

  /// No description provided for @overdueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track and follow up on overdue loan accounts'**
  String get overdueSubtitle;

  /// No description provided for @overdueCountBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue'**
  String overdueCountBadge(int count);

  /// No description provided for @overdueStatTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'TOTAL OVERDUE'**
  String get overdueStatTotalLabel;

  /// No description provided for @overdueStatTotalSub.
  ///
  /// In en, this message translates to:
  /// **'accounts'**
  String get overdueStatTotalSub;

  /// No description provided for @overdueStatAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'OVERDUE AMOUNT'**
  String get overdueStatAmountLabel;

  /// No description provided for @overdueStatAmountSub.
  ///
  /// In en, this message translates to:
  /// **'outstanding'**
  String get overdueStatAmountSub;

  /// No description provided for @overdueStatAvgDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'AVG DAYS OVERDUE'**
  String get overdueStatAvgDaysLabel;

  /// No description provided for @overdueStatAvgDaysValue.
  ///
  /// In en, this message translates to:
  /// **'{days} d'**
  String overdueStatAvgDaysValue(int days);

  /// No description provided for @overdueStatAvgDaysSub.
  ///
  /// In en, this message translates to:
  /// **'across accounts'**
  String get overdueStatAvgDaysSub;

  /// No description provided for @overdueStatCriticalLabel.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL (>30D)'**
  String get overdueStatCriticalLabel;

  /// No description provided for @overdueStatCriticalSub.
  ///
  /// In en, this message translates to:
  /// **'needs attention'**
  String get overdueStatCriticalSub;

  /// No description provided for @overdueSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search customer or loan number...'**
  String get overdueSearchHint;

  /// No description provided for @overdueFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All overdue'**
  String get overdueFilterAll;

  /// No description provided for @overdueFilterCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical (>30d)'**
  String get overdueFilterCritical;

  /// No description provided for @overdueNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'No overdue accounts match your search.'**
  String get overdueNoMatchMessage;

  /// No description provided for @overdueNoPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'No phone number'**
  String get overdueNoPhoneTitle;

  /// No description provided for @overdueNoPhoneMessage.
  ///
  /// In en, this message translates to:
  /// **'This overdue account does not have a mobile number yet.'**
  String get overdueNoPhoneMessage;

  /// No description provided for @overdueSendMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Message Reminder'**
  String get overdueSendMessageTitle;

  /// No description provided for @overdueSendMessageBody.
  ///
  /// In en, this message translates to:
  /// **'Open WhatsApp for {name}?\n{phone}'**
  String overdueSendMessageBody(String name, String phone);

  /// No description provided for @overdueSendLabel.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get overdueSendLabel;

  /// No description provided for @overdueWhatsappTemplate.
  ///
  /// In en, this message translates to:
  /// **'Hello {name}, your loan {loanNumber} is overdue by {days} days. Please contact us to clear the pending amount of {amount}.'**
  String overdueWhatsappTemplate(
      String name, String loanNumber, int days, String amount);

  /// No description provided for @overdueWhatsappFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to open WhatsApp'**
  String get overdueWhatsappFailedTitle;

  /// No description provided for @overdueCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Call Customer'**
  String get overdueCallTitle;

  /// No description provided for @overdueCallBody.
  ///
  /// In en, this message translates to:
  /// **'{name}\n{phone}'**
  String overdueCallBody(String name, String phone);

  /// No description provided for @overdueCallLabel.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get overdueCallLabel;

  /// No description provided for @overdueCallFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to start call'**
  String get overdueCallFailedTitle;

  /// No description provided for @overdueFollowUpAssignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow-up assigned'**
  String get overdueFollowUpAssignedTitle;

  /// No description provided for @overdueGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get overdueGenericError;

  /// No description provided for @overdueBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueBadgeLabel;

  /// No description provided for @overdueLoanNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Loan No.'**
  String get overdueLoanNumberLabel;

  /// No description provided for @overdueDueAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Amount'**
  String get overdueDueAmountLabel;

  /// No description provided for @overdueDaysOverdueLabel.
  ///
  /// In en, this message translates to:
  /// **'Days Overdue'**
  String get overdueDaysOverdueLabel;

  /// No description provided for @overdueDaysValue.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String overdueDaysValue(int days);

  /// No description provided for @overdueStartedLabel.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get overdueStartedLabel;

  /// No description provided for @overdueFollowUpSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'FOLLOW-UP'**
  String get overdueFollowUpSectionLabel;

  /// No description provided for @overdueFollowUpDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String overdueFollowUpDueLabel(String date);

  /// No description provided for @overdueActionMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get overdueActionMessage;

  /// No description provided for @overdueActionCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get overdueActionCall;

  /// No description provided for @overdueActionAssignFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Assign Follow-up'**
  String get overdueActionAssignFollowUp;

  /// No description provided for @overdueAssignFollowUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign Follow-up'**
  String get overdueAssignFollowUpTitle;

  /// No description provided for @overdueFollowUpNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Called customer, promised to pay by Friday'**
  String get overdueFollowUpNoteHint;

  /// No description provided for @overdueFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get overdueFieldRequired;

  /// No description provided for @overdueFollowUpNoteFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'FOLLOW-UP NOTE'**
  String get overdueFollowUpNoteFieldLabel;

  /// No description provided for @overdueFollowUpDateFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'FOLLOW-UP DATE'**
  String get overdueFollowUpDateFieldLabel;

  /// No description provided for @overdueStartedValue.
  ///
  /// In en, this message translates to:
  /// **'Started: {date}'**
  String overdueStartedValue(String date);

  /// No description provided for @overdueOutstandingValue.
  ///
  /// In en, this message translates to:
  /// **'Outstanding: {amount}'**
  String overdueOutstandingValue(String amount);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @agentManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Agent Management'**
  String get agentManagementTitle;

  /// No description provided for @agentManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add, edit, and manage your collection agents'**
  String get agentManagementSubtitle;

  /// No description provided for @agentAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Agent'**
  String get agentAddButton;

  /// No description provided for @agentLoadFailedFallback.
  ///
  /// In en, this message translates to:
  /// **'Failed to load agents.'**
  String get agentLoadFailedFallback;

  /// No description provided for @agentStatTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Agents'**
  String get agentStatTotal;

  /// No description provided for @agentStatActive.
  ///
  /// In en, this message translates to:
  /// **'Active Agents'**
  String get agentStatActive;

  /// No description provided for @agentStatInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive Agents'**
  String get agentStatInactive;

  /// No description provided for @agentStatAddedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Added This Month'**
  String get agentStatAddedThisMonth;

  /// No description provided for @agentSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or mobile...'**
  String get agentSearchHint;

  /// No description provided for @agentRoleAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get agentRoleAgent;

  /// No description provided for @agentRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get agentRoleAdmin;

  /// No description provided for @agentRoleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get agentRoleManager;

  /// No description provided for @agentRoleAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get agentRoleAll;

  /// No description provided for @agentColUser.
  ///
  /// In en, this message translates to:
  /// **'USER'**
  String get agentColUser;

  /// No description provided for @agentColMobile.
  ///
  /// In en, this message translates to:
  /// **'MOBILE'**
  String get agentColMobile;

  /// No description provided for @agentColRole.
  ///
  /// In en, this message translates to:
  /// **'ROLE'**
  String get agentColRole;

  /// No description provided for @agentColStatus.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get agentColStatus;

  /// No description provided for @agentColCreated.
  ///
  /// In en, this message translates to:
  /// **'CREATED'**
  String get agentColCreated;

  /// No description provided for @agentColActions.
  ///
  /// In en, this message translates to:
  /// **'ACTIONS'**
  String get agentColActions;

  /// No description provided for @agentNoAgentsFound.
  ///
  /// In en, this message translates to:
  /// **'No agents found.'**
  String get agentNoAgentsFound;

  /// No description provided for @agentEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get agentEditTooltip;

  /// No description provided for @agentDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get agentDeleteTooltip;

  /// No description provided for @agentCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Agent created'**
  String get agentCreatedTitle;

  /// No description provided for @agentCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} has been added'**
  String agentCreatedMessage(String name);

  /// No description provided for @agentCreateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not create agent'**
  String get agentCreateFailedTitle;

  /// No description provided for @agentUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Agent updated'**
  String get agentUpdatedTitle;

  /// No description provided for @agentUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} has been updated'**
  String agentUpdatedMessage(String name);

  /// No description provided for @agentUpdateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not update agent'**
  String get agentUpdateFailedTitle;

  /// No description provided for @agentDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Agent'**
  String get agentDeleteDialogTitle;

  /// No description provided for @agentDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}? They will be moved to the Recycle Bin and can be restored later.'**
  String agentDeleteConfirmMessage(String name);

  /// No description provided for @agentDeleteConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete Agent'**
  String get agentDeleteConfirmLabel;

  /// No description provided for @agentDeletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Agent deleted'**
  String get agentDeletedTitle;

  /// No description provided for @agentDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} has been removed'**
  String agentDeletedMessage(String name);

  /// No description provided for @agentDeleteFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not delete agent'**
  String get agentDeleteFailedTitle;

  /// No description provided for @agentPhotoUploadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo upload failed'**
  String get agentPhotoUploadFailedTitle;

  /// No description provided for @agentMissingInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Missing information'**
  String get agentMissingInfoTitle;

  /// No description provided for @agentMissingInfoMessage.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get agentMissingInfoMessage;

  /// No description provided for @agentFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get agentFormEditTitle;

  /// No description provided for @agentFormAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get agentFormAddTitle;

  /// No description provided for @agentFormCredentialsNotice.
  ///
  /// In en, this message translates to:
  /// **'Set an email and password so this user can sign in to the app.'**
  String get agentFormCredentialsNotice;

  /// No description provided for @agentFieldFullName.
  ///
  /// In en, this message translates to:
  /// **'FULL NAME *'**
  String get agentFieldFullName;

  /// No description provided for @agentFieldFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Priya Sharma'**
  String get agentFieldFullNameHint;

  /// No description provided for @agentFieldMobile.
  ///
  /// In en, this message translates to:
  /// **'MOBILE'**
  String get agentFieldMobile;

  /// No description provided for @agentFieldMobileHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. +91 98765 43210'**
  String get agentFieldMobileHint;

  /// No description provided for @agentFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'EMAIL *'**
  String get agentFieldEmail;

  /// No description provided for @agentFieldEmailHint.
  ///
  /// In en, this message translates to:
  /// **'user@rrgroups.in'**
  String get agentFieldEmailHint;

  /// No description provided for @agentFieldPassword.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD *'**
  String get agentFieldPassword;

  /// No description provided for @agentFieldPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Min. 6 characters'**
  String get agentFieldPasswordHint;

  /// No description provided for @agentFieldRole.
  ///
  /// In en, this message translates to:
  /// **'ROLE'**
  String get agentFieldRole;

  /// No description provided for @agentFieldStatus.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get agentFieldStatus;

  /// No description provided for @agentFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'ADDRESS'**
  String get agentFieldAddress;

  /// No description provided for @agentFieldAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Residential address'**
  String get agentFieldAddressHint;

  /// No description provided for @agentFieldAadhaar.
  ///
  /// In en, this message translates to:
  /// **'AADHAAR'**
  String get agentFieldAadhaar;

  /// No description provided for @agentFieldAadhaarHint.
  ///
  /// In en, this message translates to:
  /// **'[Aadhaar Redacted]'**
  String get agentFieldAadhaarHint;

  /// No description provided for @agentFieldPan.
  ///
  /// In en, this message translates to:
  /// **'PAN'**
  String get agentFieldPan;

  /// No description provided for @agentFieldPanHint.
  ///
  /// In en, this message translates to:
  /// **'ABCDE1234F'**
  String get agentFieldPanHint;

  /// No description provided for @agentFieldOccupation.
  ///
  /// In en, this message translates to:
  /// **'OCCUPATION'**
  String get agentFieldOccupation;

  /// No description provided for @agentFieldOccupationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Field Executive'**
  String get agentFieldOccupationHint;

  /// No description provided for @agentFieldProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'PROFILE PHOTO'**
  String get agentFieldProfilePhoto;

  /// No description provided for @agentUploadPhotoButton.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get agentUploadPhotoButton;

  /// No description provided for @agentSaveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get agentSaveChangesButton;

  /// No description provided for @agentCreateUserButton.
  ///
  /// In en, this message translates to:
  /// **'Create User'**
  String get agentCreateUserButton;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @fundsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Funds'**
  String get fundsScreenTitle;

  /// No description provided for @fundsScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly-deposit savings schemes with a maturity bonus'**
  String get fundsScreenSubtitle;

  /// No description provided for @fundCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Fund'**
  String get fundCreateButton;

  /// No description provided for @fundSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by customer name'**
  String get fundSearchHint;

  /// No description provided for @fundSearchClearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get fundSearchClearTooltip;

  /// No description provided for @fundRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get fundRetryButton;

  /// No description provided for @fundStatTotalFunds.
  ///
  /// In en, this message translates to:
  /// **'Total Funds'**
  String get fundStatTotalFunds;

  /// No description provided for @fundStatActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get fundStatActive;

  /// No description provided for @fundStatMaturityPayout.
  ///
  /// In en, this message translates to:
  /// **'Maturity Payout'**
  String get fundStatMaturityPayout;

  /// No description provided for @fundStatCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get fundStatCollected;

  /// No description provided for @fundEmptySearch.
  ///
  /// In en, this message translates to:
  /// **'No funds match your search.'**
  String get fundEmptySearch;

  /// No description provided for @fundEmptyCustomer.
  ///
  /// In en, this message translates to:
  /// **'You have no funds yet.'**
  String get fundEmptyCustomer;

  /// No description provided for @fundEmptyDefault.
  ///
  /// In en, this message translates to:
  /// **'No funds yet.'**
  String get fundEmptyDefault;

  /// No description provided for @fundCardWeekly.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY'**
  String get fundCardWeekly;

  /// No description provided for @fundCardWeeks.
  ///
  /// In en, this message translates to:
  /// **'WEEKS'**
  String get fundCardWeeks;

  /// No description provided for @fundCardBonus.
  ///
  /// In en, this message translates to:
  /// **'BONUS'**
  String get fundCardBonus;

  /// No description provided for @fundCardMaturityPayout.
  ///
  /// In en, this message translates to:
  /// **'Maturity payout'**
  String get fundCardMaturityPayout;

  /// No description provided for @fundCardDepositedProgress.
  ///
  /// In en, this message translates to:
  /// **'Deposited {deposited} / {total}'**
  String fundCardDepositedProgress(String deposited, String total);

  /// No description provided for @fundCardPassbookButton.
  ///
  /// In en, this message translates to:
  /// **'Passbook'**
  String get fundCardPassbookButton;

  /// No description provided for @fundCardCollectButton.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get fundCardCollectButton;

  /// No description provided for @fundCardSettleBanner.
  ///
  /// In en, this message translates to:
  /// **'Settle in full · {amount} left'**
  String fundCardSettleBanner(String amount);

  /// No description provided for @fundDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Fund'**
  String get fundDeleteDialogTitle;

  /// No description provided for @fundDeleteDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{code}\" for {customerName}? It will be moved to the Recycle Bin and can be restored later.'**
  String fundDeleteDialogMessage(String code, String customerName);

  /// No description provided for @fundDeleteDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get fundDeleteDialogConfirm;

  /// No description provided for @fundAgentSettleDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Settle Fund in Full'**
  String get fundAgentSettleDialogTitle;

  /// No description provided for @fundAgentSettleDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Collect the remaining {amount} for \"{code}\" ({customerName}) now and mark it matured?'**
  String fundAgentSettleDialogMessage(
      String amount, String code, String customerName);

  /// No description provided for @fundAgentSettleDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Settle Now'**
  String get fundAgentSettleDialogConfirm;

  /// No description provided for @fundToastLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to load funds'**
  String get fundToastLoadFailedTitle;

  /// No description provided for @fundToastCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Fund created'**
  String get fundToastCreatedTitle;

  /// No description provided for @fundToastCreateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Create failed'**
  String get fundToastCreateFailedTitle;

  /// No description provided for @fundToastUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Fund updated'**
  String get fundToastUpdatedTitle;

  /// No description provided for @fundToastUpdateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get fundToastUpdateFailedTitle;

  /// No description provided for @fundToastSettledTitle.
  ///
  /// In en, this message translates to:
  /// **'Fund settled'**
  String get fundToastSettledTitle;

  /// No description provided for @fundToastSettlementFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Settlement failed'**
  String get fundToastSettlementFailedTitle;

  /// No description provided for @fundToastCollectionRecordedTitle.
  ///
  /// In en, this message translates to:
  /// **'Collection recorded'**
  String get fundToastCollectionRecordedTitle;

  /// No description provided for @fundToastDeletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Fund deleted'**
  String get fundToastDeletedTitle;

  /// No description provided for @fundToastDeleteFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get fundToastDeleteFailedTitle;

  /// No description provided for @fundToastSelectCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a customer'**
  String get fundToastSelectCustomerTitle;

  /// No description provided for @fundToastSelectCustomerMessage.
  ///
  /// In en, this message translates to:
  /// **'Please choose a customer'**
  String get fundToastSelectCustomerMessage;

  /// No description provided for @fundFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Fund'**
  String get fundFormTitleEdit;

  /// No description provided for @fundFormTitleAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Fund'**
  String get fundFormTitleAdd;

  /// No description provided for @fundFormFieldCustomer.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER'**
  String get fundFormFieldCustomer;

  /// No description provided for @fundFormFieldCustomerHint.
  ///
  /// In en, this message translates to:
  /// **'Select a customer...'**
  String get fundFormFieldCustomerHint;

  /// No description provided for @fundFormFieldCustomerFallback.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get fundFormFieldCustomerFallback;

  /// No description provided for @fundFormFieldAgent.
  ///
  /// In en, this message translates to:
  /// **'ASSIGNED AGENT (OPTIONAL)'**
  String get fundFormFieldAgent;

  /// No description provided for @fundFormFieldAgentHint.
  ///
  /// In en, this message translates to:
  /// **'Select an agent...'**
  String get fundFormFieldAgentHint;

  /// No description provided for @fundFormFieldAgentFallback.
  ///
  /// In en, this message translates to:
  /// **'Unknown agent'**
  String get fundFormFieldAgentFallback;

  /// No description provided for @fundFormFieldUnits.
  ///
  /// In en, this message translates to:
  /// **'FUND UNITS (QUANTITY)'**
  String get fundFormFieldUnits;

  /// No description provided for @fundFormFieldWeeklyAmount.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY AMOUNT'**
  String get fundFormFieldWeeklyAmount;

  /// No description provided for @fundFormFieldWeeks.
  ///
  /// In en, this message translates to:
  /// **'NUMBER OF WEEKS'**
  String get fundFormFieldWeeks;

  /// No description provided for @fundFormFieldBonus.
  ///
  /// In en, this message translates to:
  /// **'MATURITY BONUS'**
  String get fundFormFieldBonus;

  /// No description provided for @fundFormFieldStartDate.
  ///
  /// In en, this message translates to:
  /// **'START DATE'**
  String get fundFormFieldStartDate;

  /// No description provided for @fundFormValidatorRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fundFormValidatorRequired;

  /// No description provided for @fundFormSummaryDeposited.
  ///
  /// In en, this message translates to:
  /// **'Deposited (₹{weekly} x {weeks} weeks)'**
  String fundFormSummaryDeposited(String weekly, String weeks);

  /// No description provided for @fundFormSummaryBonus.
  ///
  /// In en, this message translates to:
  /// **'Maturity bonus'**
  String get fundFormSummaryBonus;

  /// No description provided for @fundFormSummaryBonusValue.
  ///
  /// In en, this message translates to:
  /// **'+ {amount}'**
  String fundFormSummaryBonusValue(String amount);

  /// No description provided for @fundFormSummaryTotalPayout.
  ///
  /// In en, this message translates to:
  /// **'Total maturity payout'**
  String get fundFormSummaryTotalPayout;

  /// No description provided for @fundFormMaturesOn.
  ///
  /// In en, this message translates to:
  /// **'Matures on {date}'**
  String fundFormMaturesOn(String date);

  /// No description provided for @fundFormCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get fundFormCancelButton;

  /// No description provided for @fundFormSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get fundFormSaveButton;

  /// No description provided for @fundFormCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Fund'**
  String get fundFormCreateButton;

  /// No description provided for @fundCollectDialogInvalidAmountTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get fundCollectDialogInvalidAmountTitle;

  /// No description provided for @fundCollectDialogInvalidAmountMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a collection amount greater than 0'**
  String get fundCollectDialogInvalidAmountMessage;

  /// No description provided for @fundCollectDialogNotSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Collection not saved'**
  String get fundCollectDialogNotSavedTitle;

  /// No description provided for @fundCollectDialogNotSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Only {remaining} left to fully fund this deposit.'**
  String fundCollectDialogNotSavedMessage(String remaining);

  /// No description provided for @fundCollectDialogFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Collection failed'**
  String get fundCollectDialogFailedTitle;

  /// No description provided for @fundCollectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Record Collection'**
  String get fundCollectDialogTitle;

  /// No description provided for @fundCollectDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{code} · {customerName}'**
  String fundCollectDialogSubtitle(String code, String customerName);

  /// No description provided for @fundCollectDialogCollectedLabel.
  ///
  /// In en, this message translates to:
  /// **'COLLECTED'**
  String get fundCollectDialogCollectedLabel;

  /// No description provided for @fundCollectDialogRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'REMAINING'**
  String get fundCollectDialogRemainingLabel;

  /// No description provided for @fundCollectDialogAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'COLLECTION AMOUNT'**
  String get fundCollectDialogAmountLabel;

  /// No description provided for @fundCollectDialogPaymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT METHOD'**
  String get fundCollectDialogPaymentMethodLabel;

  /// No description provided for @fundCollectDialogPaymentDateLabel.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT DATE'**
  String get fundCollectDialogPaymentDateLabel;

  /// No description provided for @fundCollectDialogHelperText.
  ///
  /// In en, this message translates to:
  /// **'Adds this amount to the fund\'s collected total. Auto-marks the fund matured once the full deposit target is collected.'**
  String get fundCollectDialogHelperText;

  /// No description provided for @fundCollectDialogRecordButton.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get fundCollectDialogRecordButton;

  /// No description provided for @fundSettleDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Fund Closure & Settlement'**
  String get fundSettleDialogTitle;

  /// No description provided for @fundSettleDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{code} · {customerName} ({units} Active Units)'**
  String fundSettleDialogSubtitle(
      String code, String customerName, String units);

  /// No description provided for @fundSettleTabPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial Unit Closure'**
  String get fundSettleTabPartial;

  /// No description provided for @fundSettleTabFull.
  ///
  /// In en, this message translates to:
  /// **'Settle Full Account'**
  String get fundSettleTabFull;

  /// No description provided for @fundSettleUnitsToCloseLabel.
  ///
  /// In en, this message translates to:
  /// **'NUMBER OF UNITS TO CLOSE'**
  String get fundSettleUnitsToCloseLabel;

  /// No description provided for @fundSettleHalfUnitButton.
  ///
  /// In en, this message translates to:
  /// **'0.5 Units'**
  String get fundSettleHalfUnitButton;

  /// No description provided for @fundSettleOneUnitButton.
  ///
  /// In en, this message translates to:
  /// **'1 Unit'**
  String get fundSettleOneUnitButton;

  /// No description provided for @fundSettleClosedPayoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Closed Units Payout'**
  String get fundSettleClosedPayoutLabel;

  /// No description provided for @fundSettleClosedPayoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accrued Deposit + Bonus'**
  String get fundSettleClosedPayoutSubtitle;

  /// No description provided for @fundSettleRemainingBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining Active Balance'**
  String get fundSettleRemainingBalanceLabel;

  /// No description provided for @fundSettleRemainingUnitsValue.
  ///
  /// In en, this message translates to:
  /// **'{units} Units left'**
  String fundSettleRemainingUnitsValue(String units);

  /// No description provided for @fundSettleNewWeeklyValue.
  ///
  /// In en, this message translates to:
  /// **'New Weekly: {amount} / week'**
  String fundSettleNewWeeklyValue(String amount);

  /// No description provided for @fundSettleTotalDepositedLabel.
  ///
  /// In en, this message translates to:
  /// **'TOTAL DEPOSITED'**
  String get fundSettleTotalDepositedLabel;

  /// No description provided for @fundSettleRemainingTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'REMAINING TARGET'**
  String get fundSettleRemainingTargetLabel;

  /// No description provided for @fundSettlePaymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT METHOD'**
  String get fundSettlePaymentMethodLabel;

  /// No description provided for @fundSettleSettlementDateLabel.
  ///
  /// In en, this message translates to:
  /// **'SETTLEMENT DATE'**
  String get fundSettleSettlementDateLabel;

  /// No description provided for @fundSettleSummaryClosingTarget.
  ///
  /// In en, this message translates to:
  /// **'Closing units deposit target'**
  String get fundSettleSummaryClosingTarget;

  /// No description provided for @fundSettleSummaryClosingTargetValue.
  ///
  /// In en, this message translates to:
  /// **'{amount} ({units} of {maxUnits} Units)'**
  String fundSettleSummaryClosingTargetValue(
      String amount, String units, String maxUnits);

  /// No description provided for @fundSettleSummaryTotalDeposit.
  ///
  /// In en, this message translates to:
  /// **'Total deposit'**
  String get fundSettleSummaryTotalDeposit;

  /// No description provided for @fundSettleSummaryProportionalBonus.
  ///
  /// In en, this message translates to:
  /// **'🎁 Proportional Bonus'**
  String get fundSettleSummaryProportionalBonus;

  /// No description provided for @fundSettleSummaryNetClosurePayout.
  ///
  /// In en, this message translates to:
  /// **'Net Closure Payout Amount'**
  String get fundSettleSummaryNetClosurePayout;

  /// No description provided for @fundSettleSummaryPayoutToCustomer.
  ///
  /// In en, this message translates to:
  /// **'Payout to customer'**
  String get fundSettleSummaryPayoutToCustomer;

  /// No description provided for @fundSettleFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Closure failed'**
  String get fundSettleFailedTitle;

  /// No description provided for @fundSettleCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get fundSettleCancelButton;

  /// No description provided for @fundSettleConfirmPartialButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Partial Closure'**
  String get fundSettleConfirmPartialButton;

  /// No description provided for @fundSettleConfirmFullButton.
  ///
  /// In en, this message translates to:
  /// **'Settle Full Account'**
  String get fundSettleConfirmFullButton;

  /// No description provided for @fundPassbookTitle.
  ///
  /// In en, this message translates to:
  /// **'Passbook'**
  String get fundPassbookTitle;

  /// No description provided for @fundPassbookSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{code} · {customerName}'**
  String fundPassbookSubtitle(String code, String customerName);

  /// No description provided for @fundPassbookDepositedLabel.
  ///
  /// In en, this message translates to:
  /// **'DEPOSITED'**
  String get fundPassbookDepositedLabel;

  /// No description provided for @fundPassbookToDepositLabel.
  ///
  /// In en, this message translates to:
  /// **'TO DEPOSIT'**
  String get fundPassbookToDepositLabel;

  /// No description provided for @fundPassbookEntriesLabel.
  ///
  /// In en, this message translates to:
  /// **'ENTRIES'**
  String get fundPassbookEntriesLabel;

  /// No description provided for @fundPassbookEntriesValue.
  ///
  /// In en, this message translates to:
  /// **'{paid} / {total}'**
  String fundPassbookEntriesValue(String paid, String total);

  /// No description provided for @fundPassbookSummaryTotalDeposit.
  ///
  /// In en, this message translates to:
  /// **'Total deposit (₹{weekly} x {weeks} weeks)'**
  String fundPassbookSummaryTotalDeposit(String weekly, String weeks);

  /// No description provided for @fundPassbookSummaryBonus.
  ///
  /// In en, this message translates to:
  /// **'🎁 Maturity bonus (at settlement)'**
  String get fundPassbookSummaryBonus;

  /// No description provided for @fundPassbookSummaryPayout.
  ///
  /// In en, this message translates to:
  /// **'Maturity payout'**
  String get fundPassbookSummaryPayout;

  /// No description provided for @fundPassbookNextDuePrefix.
  ///
  /// In en, this message translates to:
  /// **'Next deposit due · '**
  String get fundPassbookNextDuePrefix;

  /// No description provided for @fundPassbookNextDueValue.
  ///
  /// In en, this message translates to:
  /// **'{date} · Week {week} · {amount}'**
  String fundPassbookNextDueValue(String date, String week, String amount);

  /// No description provided for @fundPassbookColWeek.
  ///
  /// In en, this message translates to:
  /// **'WK'**
  String get fundPassbookColWeek;

  /// No description provided for @fundPassbookColDateMethod.
  ///
  /// In en, this message translates to:
  /// **'DATE · METHOD'**
  String get fundPassbookColDateMethod;

  /// No description provided for @fundPassbookColAmountBalance.
  ///
  /// In en, this message translates to:
  /// **'AMOUNT · BALANCE'**
  String get fundPassbookColAmountBalance;

  /// No description provided for @fundPassbookNextDueRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Next due'**
  String get fundPassbookNextDueRowLabel;

  /// No description provided for @fundPassbookPaidFallback.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get fundPassbookPaidFallback;

  /// No description provided for @fundPassbookPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get fundPassbookPendingLabel;

  /// No description provided for @fundPassbookBalanceValue.
  ///
  /// In en, this message translates to:
  /// **'Bal {balance}'**
  String fundPassbookBalanceValue(String balance);

  /// No description provided for @fundPassbookCloseButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get fundPassbookCloseButton;

  /// No description provided for @routeMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Map'**
  String get routeMapTitle;

  /// No description provided for @routeMapAllLocationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All customer locations'**
  String get routeMapAllLocationsSubtitle;

  /// No description provided for @routeMapSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search customer, loan or agent...'**
  String get routeMapSearchHint;

  /// No description provided for @routeMapCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get routeMapCustomerLabel;

  /// No description provided for @routeMapAllCustomers.
  ///
  /// In en, this message translates to:
  /// **'All customers'**
  String get routeMapAllCustomers;

  /// No description provided for @routeMapTotalMapped.
  ///
  /// In en, this message translates to:
  /// **'Total Mapped'**
  String get routeMapTotalMapped;

  /// No description provided for @routeMapActiveCustomers.
  ///
  /// In en, this message translates to:
  /// **'Active Customers'**
  String get routeMapActiveCustomers;

  /// No description provided for @routeMapNoLocationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No locations found'**
  String get routeMapNoLocationsTitle;

  /// No description provided for @routeMapNoLocationsMessage.
  ///
  /// In en, this message translates to:
  /// **'Customers with valid coordinates will appear here.'**
  String get routeMapNoLocationsMessage;

  /// No description provided for @routeMapActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get routeMapActive;

  /// No description provided for @routeMapInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get routeMapInactive;

  /// No description provided for @routeMapRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get routeMapRetryButton;

  /// No description provided for @routeMapLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to load map data'**
  String get routeMapLoadFailedTitle;

  /// Shown in the customer info sheet with a formatted join date
  ///
  /// In en, this message translates to:
  /// **'Joined: {date}'**
  String routeMapJoinedLabel(String date);

  /// No description provided for @reportsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports & Analytics'**
  String get reportsScreenTitle;

  /// No description provided for @reportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily, monthly and agent performance insights'**
  String get reportsSubtitle;

  /// No description provided for @reportsExportPdfButton.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get reportsExportPdfButton;

  /// No description provided for @reportsExportExcelButton.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get reportsExportExcelButton;

  /// No description provided for @reportsExportingExcelTitle.
  ///
  /// In en, this message translates to:
  /// **'Exporting Excel'**
  String get reportsExportingExcelTitle;

  /// No description provided for @reportsExportingExcelMessage.
  ///
  /// In en, this message translates to:
  /// **'Compiling spreadsheet cells...'**
  String get reportsExportingExcelMessage;

  /// No description provided for @reportsExportCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Complete'**
  String get reportsExportCompleteTitle;

  /// No description provided for @reportsExportCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Excel sheet generated successfully.'**
  String get reportsExportCompleteMessage;

  /// No description provided for @reportsExportFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Failed'**
  String get reportsExportFailedTitle;

  /// No description provided for @reportsExportFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not generate spreadsheet. Technical reason: {error}'**
  String reportsExportFailedMessage(String error);

  /// No description provided for @reportsDailyHint.
  ///
  /// In en, this message translates to:
  /// **'Daily report shows data for the end date above.'**
  String get reportsDailyHint;

  /// No description provided for @reportsRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get reportsRetryButton;

  /// No description provided for @reportsGenericErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while loading the report.'**
  String get reportsGenericErrorMessage;

  /// No description provided for @reportsTabDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily\nReport'**
  String get reportsTabDaily;

  /// No description provided for @reportsTabMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly\nReport'**
  String get reportsTabMonthly;

  /// No description provided for @reportsTabAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent\nPerformance'**
  String get reportsTabAgent;

  /// No description provided for @reportsTodaysCollectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Collections'**
  String get reportsTodaysCollectionsTitle;

  /// No description provided for @reportsNoCollectionsTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'No collections today'**
  String get reportsNoCollectionsTodayTitle;

  /// No description provided for @reportsNoCollectionsTodayMessage.
  ///
  /// In en, this message translates to:
  /// **'Collections made today will appear here.'**
  String get reportsNoCollectionsTodayMessage;

  /// No description provided for @reportsNewLoansTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'New Loans Created Today'**
  String get reportsNewLoansTodayTitle;

  /// No description provided for @reportsNoNewLoansTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'No new loans today'**
  String get reportsNoNewLoansTodayTitle;

  /// No description provided for @reportsNoNewLoansTodayMessage.
  ///
  /// In en, this message translates to:
  /// **'Loans created today will appear here.'**
  String get reportsNoNewLoansTodayMessage;

  /// No description provided for @reportsMetricDisbursement.
  ///
  /// In en, this message translates to:
  /// **'LOAN DISBURSEMENT'**
  String get reportsMetricDisbursement;

  /// No description provided for @reportsMetricInterest.
  ///
  /// In en, this message translates to:
  /// **'INTEREST EARNED'**
  String get reportsMetricInterest;

  /// No description provided for @reportsMetricCollectionTotal.
  ///
  /// In en, this message translates to:
  /// **'COLLECTION TOTAL'**
  String get reportsMetricCollectionTotal;

  /// No description provided for @reportsMetricNewCustomers.
  ///
  /// In en, this message translates to:
  /// **'NEW CUSTOMERS'**
  String get reportsMetricNewCustomers;

  /// No description provided for @reportsCollectionsTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Collections Trend'**
  String get reportsCollectionsTrendTitle;

  /// No description provided for @reportsLastNMonths.
  ///
  /// In en, this message translates to:
  /// **'Last {count} months'**
  String reportsLastNMonths(int count);

  /// No description provided for @reportsLoanDisbursementTitle.
  ///
  /// In en, this message translates to:
  /// **'Loan Disbursement'**
  String get reportsLoanDisbursementTitle;

  /// No description provided for @reportsByMonth.
  ///
  /// In en, this message translates to:
  /// **'By month'**
  String get reportsByMonth;

  /// No description provided for @reportsAgentPerformanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Agent Performance'**
  String get reportsAgentPerformanceTitle;

  /// No description provided for @reportsNoAgentDataTitle.
  ///
  /// In en, this message translates to:
  /// **'No agent data'**
  String get reportsNoAgentDataTitle;

  /// No description provided for @reportsNoAgentDataMessage.
  ///
  /// In en, this message translates to:
  /// **'Agent performance will appear here once agents are active.'**
  String get reportsNoAgentDataMessage;

  /// No description provided for @reportsColumnAgent.
  ///
  /// In en, this message translates to:
  /// **'AGENT'**
  String get reportsColumnAgent;

  /// No description provided for @reportsColumnAssigned.
  ///
  /// In en, this message translates to:
  /// **'ASSIGNED'**
  String get reportsColumnAssigned;

  /// No description provided for @reportsColumnCollected.
  ///
  /// In en, this message translates to:
  /// **'COLLECTED'**
  String get reportsColumnCollected;

  /// No description provided for @reportsColumnEfficiency.
  ///
  /// In en, this message translates to:
  /// **'EFFICIENCY'**
  String get reportsColumnEfficiency;

  /// No description provided for @reportsCollectionsByAgentTitle.
  ///
  /// In en, this message translates to:
  /// **'Collections by Agent'**
  String get reportsCollectionsByAgentTitle;

  /// No description provided for @reportsTotalAmountCollected.
  ///
  /// In en, this message translates to:
  /// **'Total amount collected'**
  String get reportsTotalAmountCollected;

  /// No description provided for @reportsNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get reportsNoData;

  /// Title of the notifications screen, shown in the app shell app bar
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsScreenTitle;

  /// Subtitle shown under the notifications screen title
  ///
  /// In en, this message translates to:
  /// **'Stay on top of dues, approvals, and reminders'**
  String get notificationsSubtitle;

  /// Button label to mark every notification as read
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// Button label to open/submit the send-notification dialog
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Stat card label for total notification count
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get statTotal;

  /// Stat card label for unread notification count
  ///
  /// In en, this message translates to:
  /// **'UNREAD'**
  String get statUnread;

  /// Stat card label for overdue notification count
  ///
  /// In en, this message translates to:
  /// **'OVERDUE'**
  String get statOverdue;

  /// Notification filter pill: show all notifications
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Notification filter pill: show only unread notifications
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get filterUnread;

  /// Notification filter pill: show only EMI due notifications
  ///
  /// In en, this message translates to:
  /// **'EMI Due'**
  String get filterEmiDue;

  /// Notification filter pill: show only overdue notifications
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get filterOverdue;

  /// Notification filter pill: show only approval notifications
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get filterApprovals;

  /// Notification filter pill: show only reminder notifications
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get filterReminders;

  /// Empty state shown when the filtered notification list has no items
  ///
  /// In en, this message translates to:
  /// **'No notifications here.'**
  String get noNotificationsHere;

  /// Inline error message shown when notifications fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get failedToLoadNotifications;

  /// Toast title shown when notifications fail to load
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications'**
  String get couldNotLoadNotificationsToastTitle;

  /// Toast title shown after successfully marking all notifications as read
  ///
  /// In en, this message translates to:
  /// **'All notifications cleared'**
  String get allNotificationsClearedToastTitle;

  /// Toast message shown after successfully marking all notifications as read
  ///
  /// In en, this message translates to:
  /// **'Everything has been marked as read.'**
  String get allNotificationsClearedToastMessage;

  /// Toast title shown when marking all notifications as read fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update'**
  String get failedToUpdateToastTitle;

  /// Title of the confirmation dialog shown before deleting a notification
  ///
  /// In en, this message translates to:
  /// **'Delete Notification'**
  String get deleteNotificationTitle;

  /// Confirmation message shown before deleting a notification
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? It will be moved to the Recycle Bin and can be restored later.'**
  String deleteNotificationMessage(String title);

  /// Toast title shown after successfully deleting a notification
  ///
  /// In en, this message translates to:
  /// **'Notification removed'**
  String get notificationRemovedToastTitle;

  /// Toast title shown when deleting a notification fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete'**
  String get failedToDeleteToastTitle;

  /// Toast title shown after successfully marking a single notification as read
  ///
  /// In en, this message translates to:
  /// **'Marked as read'**
  String get markedAsReadToastTitle;

  /// Toast title shown when marking a single notification as read fails
  ///
  /// In en, this message translates to:
  /// **'Failed to mark as read'**
  String get failedToMarkAsReadToastTitle;

  /// Debug/reference label showing the user id on a notification card
  ///
  /// In en, this message translates to:
  /// **'user_id: {id}'**
  String userIdLabel(String id);

  /// Title of the send-notification bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Send Notification'**
  String get sendNotificationTitle;

  /// Subtitle of the send-notification bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Notify your customers instantly'**
  String get sendNotificationSubtitle;

  /// Section label for choosing notification recipients
  ///
  /// In en, this message translates to:
  /// **'RECIPIENTS'**
  String get recipientsLabel;

  /// Toggle chip: send to all customers
  ///
  /// In en, this message translates to:
  /// **'All Customers'**
  String get allCustomers;

  /// Toggle chip: manually select customers
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectLabel;

  /// Search field hint for filtering the customer list
  ///
  /// In en, this message translates to:
  /// **'Search customers...'**
  String get searchCustomersHint;

  /// Empty state inside the customer selection list
  ///
  /// In en, this message translates to:
  /// **'No customers found.'**
  String get noCustomersFoundInList;

  /// Shown next to a customer who has no linked portal login and cannot receive notifications
  ///
  /// In en, this message translates to:
  /// **'No portal login'**
  String get noPortalLogin;

  /// Section label for choosing the notification type
  ///
  /// In en, this message translates to:
  /// **'TYPE'**
  String get typeLabel;

  /// Notification type option: informational
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get typeInfo;

  /// Notification type option: reminder
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get typeReminder;

  /// Notification type option: EMI due
  ///
  /// In en, this message translates to:
  /// **'EMI Due'**
  String get typeEmiDue;

  /// Notification type option: overdue
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get typeOverdue;

  /// Notification type option: approval
  ///
  /// In en, this message translates to:
  /// **'Approval'**
  String get typeApproval;

  /// Label for the notification title input field
  ///
  /// In en, this message translates to:
  /// **'TITLE'**
  String get titleFieldLabel;

  /// Placeholder text for the notification title input field
  ///
  /// In en, this message translates to:
  /// **'e.g. EMI due tomorrow'**
  String get titleFieldHint;

  /// Label for the notification message input field
  ///
  /// In en, this message translates to:
  /// **'MESSAGE'**
  String get messageFieldLabel;

  /// Placeholder text for the notification message input field
  ///
  /// In en, this message translates to:
  /// **'Write your message...'**
  String get messageFieldHint;

  /// Shown when zero recipients are selected for the notification being composed
  ///
  /// In en, this message translates to:
  /// **'No recipients selected'**
  String get noRecipientsSelected;

  /// Shown with the number of recipients currently selected
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recipient selected} other{{count} recipients selected}}'**
  String recipientsSelectedCount(int count);

  /// Validation error toast when the notification title is empty
  ///
  /// In en, this message translates to:
  /// **'Title required'**
  String get titleRequiredError;

  /// Error toast when there are no customers to send to at all
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get noCustomersFoundError;

  /// Error toast when no customers have a linked portal login
  ///
  /// In en, this message translates to:
  /// **'No linked customer logins found'**
  String get noLinkedCustomerLoginsFoundError;

  /// Error toast when sending with manual selection but nothing is selected
  ///
  /// In en, this message translates to:
  /// **'Select at least one recipient'**
  String get selectAtLeastOneRecipientError;

  /// Error toast title when selected customers have no portal login
  ///
  /// In en, this message translates to:
  /// **'No eligible recipients'**
  String get noEligibleRecipientsToastTitle;

  /// Error toast message when selected customers have no portal login
  ///
  /// In en, this message translates to:
  /// **'Selected customers need a portal login to receive notifications.'**
  String get noEligibleRecipientsToastMessage;

  /// Success toast title after a notification is sent
  ///
  /// In en, this message translates to:
  /// **'Notification sent'**
  String get notificationSentToastTitle;

  /// Success toast message showing how many recipients received the notification
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recipient} other{{count} recipients}}'**
  String recipientsCount(int count);

  /// Error toast title when sending a notification fails
  ///
  /// In en, this message translates to:
  /// **'Send failed'**
  String get sendFailedToastTitle;

  /// Error toast title when the customer list fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load customers'**
  String get couldNotLoadCustomersToastTitle;

  /// Title of the user management screen
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagementScreenTitle;

  /// Subtitle shown under the user management screen title
  ///
  /// In en, this message translates to:
  /// **'Manage roles, access, and permissions across your organization'**
  String get userManagementSubtitle;

  /// Button label and dialog title for adding a new user
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// Tooltip for the button that reloads the user list
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// Tooltip/label for the edit-user action
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Stat card label for total number of users
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get statTotalUsers;

  /// Stat card label for number of active users
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statActive;

  /// Stat card label for number of collection agents
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get statAgents;

  /// Stat card label for number of admins
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get statAdmins;

  /// Hint text for the user search field
  ///
  /// In en, this message translates to:
  /// **'Search by name or mobile...'**
  String get searchByNameOrMobileHint;

  /// Role filter dropdown option: show users of every role
  ///
  /// In en, this message translates to:
  /// **'All Roles'**
  String get roleAll;

  /// Role label/dropdown option: admin
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// Role label/dropdown option: collection agent
  ///
  /// In en, this message translates to:
  /// **'Collection Agent'**
  String get roleCollectionAgent;

  /// Role label/dropdown option: customer
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get roleCustomer;

  /// Empty state shown when the filtered user list has no results
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// User table column header: name/avatar/email
  ///
  /// In en, this message translates to:
  /// **'USER'**
  String get tableColumnUser;

  /// User table column header: mobile number
  ///
  /// In en, this message translates to:
  /// **'MOBILE'**
  String get tableColumnMobile;

  /// User table column header: role
  ///
  /// In en, this message translates to:
  /// **'ROLE'**
  String get tableColumnRole;

  /// User table column header: status
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get tableColumnStatus;

  /// Tooltip shown on the disabled edit button for admin accounts
  ///
  /// In en, this message translates to:
  /// **'Admin accounts cannot be edited'**
  String get adminCannotBeEditedTooltip;

  /// Tooltip shown on the disabled delete button for admin accounts
  ///
  /// In en, this message translates to:
  /// **'Admin accounts cannot be deleted'**
  String get adminCannotBeDeletedTooltip;

  /// Title of the confirmation dialog shown before removing a user
  ///
  /// In en, this message translates to:
  /// **'Remove user?'**
  String get removeUserDialogTitle;

  /// Confirmation message shown before removing a user
  ///
  /// In en, this message translates to:
  /// **'{name} will be moved to the Recycle Bin and can be restored later.'**
  String removeUserDialogMessage(String name);

  /// Confirm button label for removing a user
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Toast title shown after a user is successfully created
  ///
  /// In en, this message translates to:
  /// **'User created'**
  String get userCreatedToastTitle;

  /// Toast message shown after a user is successfully created
  ///
  /// In en, this message translates to:
  /// **'{name} was added successfully'**
  String userCreatedToastMessage(String name);

  /// Toast title shown when creating a user fails
  ///
  /// In en, this message translates to:
  /// **'Could not create user'**
  String get couldNotCreateUserToastTitle;

  /// Generic fallback error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// Toast title shown after a user is successfully updated
  ///
  /// In en, this message translates to:
  /// **'User updated'**
  String get userUpdatedToastTitle;

  /// Toast message shown after a user is successfully updated
  ///
  /// In en, this message translates to:
  /// **'{name} was saved'**
  String userUpdatedToastMessage(String name);

  /// Toast title shown when updating a user fails
  ///
  /// In en, this message translates to:
  /// **'Could not update user'**
  String get couldNotUpdateUserToastTitle;

  /// Toast title shown after a user is successfully deleted
  ///
  /// In en, this message translates to:
  /// **'User removed'**
  String get userRemovedToastTitle;

  /// Toast message shown after a user is successfully deleted
  ///
  /// In en, this message translates to:
  /// **'{name} was deleted'**
  String userRemovedToastMessage(String name);

  /// Toast title shown when deleting a user fails
  ///
  /// In en, this message translates to:
  /// **'Could not delete user'**
  String get couldNotDeleteUserToastTitle;

  /// Inline error message shown when the user list fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load users'**
  String get failedToLoadUsers;

  /// Accessibility barrier label for the add-user bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Dismiss Add User Dialog'**
  String get dismissAddUserDialogLabel;

  /// Accessibility barrier label for the edit-user bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Dismiss Edit User Dialog'**
  String get dismissEditUserDialogLabel;

  /// Title of the edit-user bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUserDialogTitle;

  /// Helper note shown in the edit-user dialog about the password field
  ///
  /// In en, this message translates to:
  /// **'Leave password blank to keep the current password unchanged.'**
  String get editPasswordHintNote;

  /// Helper note shown in the add-user dialog explaining account creation
  ///
  /// In en, this message translates to:
  /// **'This creates a login account directly on the backend. The user can sign in immediately with the email and password below.'**
  String get addUserBackendNote;

  /// Validation error shown when the full name field is empty
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequiredError;

  /// Validation error shown when the email field is empty or invalid
  ///
  /// In en, this message translates to:
  /// **'A valid email is required'**
  String get validEmailRequiredError;

  /// Validation error shown when the password is shorter than 6 characters
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLengthError;

  /// Label for the full name input field
  ///
  /// In en, this message translates to:
  /// **'FULL NAME *'**
  String get fullNameFieldLabel;

  /// Placeholder text for the full name input field
  ///
  /// In en, this message translates to:
  /// **'e.g. Priya Sharma'**
  String get fullNameFieldHint;

  /// Label for the email input field
  ///
  /// In en, this message translates to:
  /// **'EMAIL *'**
  String get emailFieldLabel;

  /// Placeholder text for the email input field
  ///
  /// In en, this message translates to:
  /// **'e.g. priya@example.com'**
  String get emailFieldHint;

  /// Label for the password field when editing an existing user
  ///
  /// In en, this message translates to:
  /// **'NEW PASSWORD (OPTIONAL)'**
  String get newPasswordOptionalLabel;

  /// Label for the password field when creating a new user
  ///
  /// In en, this message translates to:
  /// **'PASSWORD *'**
  String get passwordFieldLabel;

  /// Placeholder text for the password field when editing an existing user
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep unchanged'**
  String get passwordLeaveBlankHint;

  /// Placeholder text for the password field when creating a new user
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get passwordMinCharsHint;

  /// Label for the mobile number input field
  ///
  /// In en, this message translates to:
  /// **'MOBILE'**
  String get mobileFieldLabel;

  /// Placeholder text for the mobile number input field
  ///
  /// In en, this message translates to:
  /// **'e.g. +91 98765 43210'**
  String get mobileFieldHint;

  /// Label for the role dropdown field
  ///
  /// In en, this message translates to:
  /// **'ROLE'**
  String get roleFieldLabel;

  /// Label for the status dropdown field
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get statusFieldLabel;

  /// Label for the avatar URL input field
  ///
  /// In en, this message translates to:
  /// **'AVATAR URL'**
  String get avatarUrlFieldLabel;

  /// Placeholder text for the avatar URL input field
  ///
  /// In en, this message translates to:
  /// **'https://...'**
  String get avatarUrlFieldHint;

  /// Helper text shown under the avatar URL input field
  ///
  /// In en, this message translates to:
  /// **'Optional profile image link'**
  String get avatarUrlHelperText;

  /// Button label for saving changes to an existing user
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Page title / app bar title for the Chit Groups screen
  ///
  /// In en, this message translates to:
  /// **'Chit Groups'**
  String get chitGroupsTitle;

  /// Subtitle shown under the Chit Groups page header
  ///
  /// In en, this message translates to:
  /// **'View and manage chit group collections'**
  String get chitGroupsSubtitle;

  /// Button label to open the create-group form
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroupButton;

  /// Placeholder text in the chit group search field
  ///
  /// In en, this message translates to:
  /// **'Search by chit fund name or number...'**
  String get searchHint;

  /// Tooltip for the button that clears the search field
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearchTooltip;

  /// Generic retry button label shown after a failed load
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// Empty state when a search query returns no chit groups
  ///
  /// In en, this message translates to:
  /// **'No chit funds match your search.'**
  String get noSearchResultsMessage;

  /// Empty state shown to a customer with no chit group membership
  ///
  /// In en, this message translates to:
  /// **'You have not been added to a chit group yet.'**
  String get customerNoGroupMessage;

  /// Empty state when there are no chit groups at all
  ///
  /// In en, this message translates to:
  /// **'No chit groups found.'**
  String get noGroupsFoundMessage;

  /// Label for the members count on a group card
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersLabel;

  /// Label for the group duration on a group card
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// Label for the group value on a group card
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get valueLabel;

  /// Label above the collection progress bar
  ///
  /// In en, this message translates to:
  /// **'Collection Progress'**
  String get collectionProgressLabel;

  /// Button label to record a collection for a group or member
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get collectButton;

  /// Button label for a customer to open their chit passbook
  ///
  /// In en, this message translates to:
  /// **'View Passbook'**
  String get viewPassbookButton;

  /// Group code shown on a chit group card
  ///
  /// In en, this message translates to:
  /// **'Group No.: {code}'**
  String groupNumberLabel(String code);

  /// Short duration value in months, e.g. '30 mo'
  ///
  /// In en, this message translates to:
  /// **'{months} mo'**
  String durationMonthsShort(int months);

  /// Toast title when a customer opens a group they don't belong to
  ///
  /// In en, this message translates to:
  /// **'Not a member'**
  String get notAMemberTitle;

  /// Toast message when a customer opens a group they don't belong to
  ///
  /// In en, this message translates to:
  /// **'You are not part of this chit group yet.'**
  String get notAMemberMessage;

  /// Toast title when opening a customer's passbook fails
  ///
  /// In en, this message translates to:
  /// **'Failed to open passbook'**
  String get failedOpenPassbookTitle;

  /// Toast title when the group list fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load chit groups'**
  String get failedLoadGroupsTitle;

  /// Title of the confirm dialog for deleting a chit group
  ///
  /// In en, this message translates to:
  /// **'Delete Chit Group'**
  String get deleteGroupTitle;

  /// Body of the confirm dialog for deleting a chit group
  ///
  /// In en, this message translates to:
  /// **'Delete \"{groupName}\"? It will be moved to the Recycle Bin and can be restored later.'**
  String deleteGroupMessage(String groupName);

  /// Confirm button label for a delete action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// Toast title after a group is deleted
  ///
  /// In en, this message translates to:
  /// **'Group deleted'**
  String get groupDeletedTitle;

  /// Toast message after a group is deleted
  ///
  /// In en, this message translates to:
  /// **'{groupName} was removed'**
  String groupRemovedMessage(String groupName);

  /// Toast title when deleting a group fails
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailedTitle;

  /// Toast title when override schedule inputs are invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid schedule values'**
  String get invalidScheduleValuesTitle;

  /// Toast message when override schedule inputs are invalid
  ///
  /// In en, this message translates to:
  /// **'Enter valid payable and pool amounts.'**
  String get invalidScheduleValuesMessage;

  /// Toast title when saving a schedule override fails
  ///
  /// In en, this message translates to:
  /// **'Schedule update failed'**
  String get scheduleUpdateFailedTitle;

  /// Title of the override schedule bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Override Draw #{installmentNo}'**
  String overrideDrawTitle(int installmentNo);

  /// Field label for the payable amount in the override sheet
  ///
  /// In en, this message translates to:
  /// **'PAYABLE AMOUNT'**
  String get payableAmountLabel;

  /// Field label for the pool / dividend value in the override sheet
  ///
  /// In en, this message translates to:
  /// **'POOL / DIVIDEND VALUE'**
  String get poolDividendValueLabel;

  /// Field label for the due date picker
  ///
  /// In en, this message translates to:
  /// **'DUE DATE'**
  String get dueDateLabel;

  /// Field label for the notes text field in the override sheet
  ///
  /// In en, this message translates to:
  /// **'NOTES'**
  String get notesLabel;

  /// Generic cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// Button label while a save operation is in progress
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingButton;

  /// Button label to save a schedule override
  ///
  /// In en, this message translates to:
  /// **'Save Override'**
  String get saveOverrideButton;

  /// Title of the group form sheet when editing an existing group
  ///
  /// In en, this message translates to:
  /// **'Edit Group'**
  String get editGroupTitle;

  /// Title of the group form sheet when creating a new group
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroupSheetTitle;

  /// Label above the row of quick preset chips in the group form
  ///
  /// In en, this message translates to:
  /// **'Quick Scheme Presets:'**
  String get quickSchemePresetsLabel;

  /// Field label for the group name input
  ///
  /// In en, this message translates to:
  /// **'GROUP NAME *'**
  String get groupNameLabel;

  /// Validation error for an empty required field
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredValidation;

  /// Field label for the total members input
  ///
  /// In en, this message translates to:
  /// **'MEMBERS *'**
  String get membersFieldLabel;

  /// Validation error when a numeric field is not a valid number
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get enterNumberValidation;

  /// Field label for the group duration in months
  ///
  /// In en, this message translates to:
  /// **'DURATION (mo) *'**
  String get durationFieldLabel;

  /// Field label for the total group value
  ///
  /// In en, this message translates to:
  /// **'GROUP VALUE *'**
  String get groupValueLabel;

  /// Field label for the monthly contribution amount
  ///
  /// In en, this message translates to:
  /// **'MONTHLY CONTRIBUTION *'**
  String get monthlyContributionLabel;

  /// Field label for the group start date
  ///
  /// In en, this message translates to:
  /// **'START DATE *'**
  String get startDateLabel;

  /// Field label for the draw frequency dropdown
  ///
  /// In en, this message translates to:
  /// **'DRAW FREQUENCY *'**
  String get drawFrequencyLabel;

  /// Field label for the draw day interval input
  ///
  /// In en, this message translates to:
  /// **'DRAW DAYS / INTERVAL'**
  String get drawIntervalLabel;

  /// Hint text for the draw interval input
  ///
  /// In en, this message translates to:
  /// **'e.g. 7'**
  String get drawIntervalHint;

  /// Validation error for an invalid custom day interval
  ///
  /// In en, this message translates to:
  /// **'Enter days > 0'**
  String get enterDaysValidation;

  /// Helper text shown for the Monthly draw frequency
  ///
  /// In en, this message translates to:
  /// **'Each draw falls on the same day next calendar month.'**
  String get monthlyIntervalHelp;

  /// Helper text shown for the Custom Day Interval draw frequency
  ///
  /// In en, this message translates to:
  /// **'Gap in days between one draw and the next.'**
  String get customIntervalHelp;

  /// Helper text shown for fixed-gap draw frequencies
  ///
  /// In en, this message translates to:
  /// **'Gap in days between draws — fixed by the selected frequency.'**
  String get fixedIntervalHelp;

  /// Helper text shown for the Custom Calendar Days draw frequency
  ///
  /// In en, this message translates to:
  /// **'Set each draw date individually in the schedule list below.'**
  String get manualDatesHelp;

  /// Field label for the group status dropdown
  ///
  /// In en, this message translates to:
  /// **'STATUS *'**
  String get statusLabel;

  /// Button label to save changes to an existing group
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesButton;

  /// Header above the auto-generated installment schedule preview
  ///
  /// In en, this message translates to:
  /// **'INSTALLMENT SCHEDULE ({count} DRAWS)'**
  String installmentScheduleHeader(int count);

  /// Badge indicating how many installments were auto-generated
  ///
  /// In en, this message translates to:
  /// **'Auto-Generated 1–{count}'**
  String autoGeneratedBadge(int count);

  /// Toast title after successfully creating a group
  ///
  /// In en, this message translates to:
  /// **'Group created'**
  String get groupCreatedTitle;

  /// Toast title after successfully updating a group
  ///
  /// In en, this message translates to:
  /// **'Group updated'**
  String get groupUpdatedTitle;

  /// Toast title when saving a group fails
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailedTitle;

  /// Chip label showing an installment's number in the schedule editor
  ///
  /// In en, this message translates to:
  /// **'Installment #{number}'**
  String installmentNumberLabel(int number);

  /// Short label for the payable amount in a schedule config card
  ///
  /// In en, this message translates to:
  /// **'Payable'**
  String get payableLabel;

  /// Short label for the pool / dividend value in a schedule config card
  ///
  /// In en, this message translates to:
  /// **'Pool / Dividend Value'**
  String get poolDividendValueShortLabel;

  /// Toast title after an installment override is saved
  ///
  /// In en, this message translates to:
  /// **'Installment updated'**
  String get installmentUpdatedTitle;

  /// Toast message after an installment override is saved
  ///
  /// In en, this message translates to:
  /// **'Draw #{number} overridden'**
  String drawOverriddenMessage(int number);

  /// Title of the confirm dialog for removing a member
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get removeMemberTitle;

  /// Body of the confirm dialog for removing a member
  ///
  /// In en, this message translates to:
  /// **'Remove \"{memberName}\" from this group?'**
  String removeMemberMessage(String memberName);

  /// Confirm button label for a remove action
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeButton;

  /// Toast title after a member is removed
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get memberRemovedTitle;

  /// Toast title when removing a member fails
  ///
  /// In en, this message translates to:
  /// **'Remove failed'**
  String get removeFailedTitle;

  /// Toast title when there is no schedule to collect against
  ///
  /// In en, this message translates to:
  /// **'Collection unavailable'**
  String get collectionUnavailableTitle;

  /// Toast message when there is no schedule to collect against
  ///
  /// In en, this message translates to:
  /// **'No installment schedule exists for this group.'**
  String get noScheduleMessage;

  /// Toast title after a member is added to a group
  ///
  /// In en, this message translates to:
  /// **'Member added'**
  String get memberAddedTitle;

  /// Toast title after a collection is saved
  ///
  /// In en, this message translates to:
  /// **'Collection recorded'**
  String get collectionRecordedTitle;

  /// Toast message after a collection is saved
  ///
  /// In en, this message translates to:
  /// **'{memberName} · {amount}'**
  String collectionRecordedMessage(String memberName, String amount);

  /// Toast title when saving a collection fails
  ///
  /// In en, this message translates to:
  /// **'Collection failed'**
  String get collectionFailedTitle;

  /// Short label for the group code stat in the group details sheet
  ///
  /// In en, this message translates to:
  /// **'Group No.'**
  String get groupNumberShortLabel;

  /// Tab label for the member collections list, with member count
  ///
  /// In en, this message translates to:
  /// **'Member Collections ({count})'**
  String memberCollectionsTab(int count);

  /// Tab label for the installment schedule list, with installment count
  ///
  /// In en, this message translates to:
  /// **'Installment Schedule ({count})'**
  String installmentScheduleTab(int count);

  /// Section title above the member collections table
  ///
  /// In en, this message translates to:
  /// **'Member Collection Tracking'**
  String get memberCollectionTrackingTitle;

  /// Button label to open the add-member form
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMemberButton;

  /// Empty state when a group has no members
  ///
  /// In en, this message translates to:
  /// **'No members yet.'**
  String get noMembersMessage;

  /// Table column header for member name
  ///
  /// In en, this message translates to:
  /// **'MEMBER'**
  String get memberColumnHeader;

  /// Table column header for contribution amount
  ///
  /// In en, this message translates to:
  /// **'CONTRIBUTION'**
  String get contributionColumnHeader;

  /// Table column header for due date
  ///
  /// In en, this message translates to:
  /// **'DUE DATE'**
  String get dueDateColumnHeader;

  /// Table column header for payment status
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get statusColumnHeader;

  /// Table column header for row actions
  ///
  /// In en, this message translates to:
  /// **'ACTION'**
  String get actionColumnHeader;

  /// Payment status label: paid
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidStatus;

  /// Payment status label: partially paid
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partialStatus;

  /// Payment status label: overdue
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueStatus;

  /// Payment status label: pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// Subtitle under the installment schedule section title
  ///
  /// In en, this message translates to:
  /// **'View and manually edit installment dates for draws'**
  String get installmentScheduleSubtitle;

  /// Empty state when a group has no installment schedule
  ///
  /// In en, this message translates to:
  /// **'No installment schedule found.'**
  String get noScheduleFoundMessage;

  /// Table column header for installment number
  ///
  /// In en, this message translates to:
  /// **'INST #'**
  String get instNumberColumnHeader;

  /// Table column header for payable amount
  ///
  /// In en, this message translates to:
  /// **'PAYABLE AMOUNT'**
  String get payableAmountColumnHeader;

  /// Table column header for pool / dividend value
  ///
  /// In en, this message translates to:
  /// **'POOL / DIVIDEND VALUE'**
  String get poolDividendValueColumnHeader;

  /// Table column header for whether a date is auto or overridden
  ///
  /// In en, this message translates to:
  /// **'DATE TYPE'**
  String get dateTypeColumnHeader;

  /// Badge label for a manually overridden installment date
  ///
  /// In en, this message translates to:
  /// **'Custom Overridden'**
  String get customOverriddenBadge;

  /// Badge label for an automatically generated installment date
  ///
  /// In en, this message translates to:
  /// **'Auto-Scheduled'**
  String get autoScheduledBadge;

  /// Button label to open the schedule override sheet
  ///
  /// In en, this message translates to:
  /// **'Override Date & Amount'**
  String get overrideDateAmountButton;

  /// Shown instead of the override action for read-only roles
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get viewOnlyLabel;

  /// Label in the mobile schedule card for due date
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDateCardLabel;

  /// Label in the mobile schedule card for payable amount
  ///
  /// In en, this message translates to:
  /// **'Payable Amount'**
  String get payableAmountCardLabel;

  /// Label in the mobile schedule card for pool value
  ///
  /// In en, this message translates to:
  /// **'Pool Value'**
  String get poolValueCardLabel;

  /// Short button label to override a schedule row on mobile
  ///
  /// In en, this message translates to:
  /// **'Override'**
  String get overrideButton;

  /// Title of the collection entry bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Record Chit Collection'**
  String get recordChitCollectionTitle;

  /// Field label for the collection amount input
  ///
  /// In en, this message translates to:
  /// **'COLLECTION AMOUNT (₹)'**
  String get collectionAmountLabel;

  /// Field label for the payment method dropdown
  ///
  /// In en, this message translates to:
  /// **'PAYMENT METHOD'**
  String get paymentMethodLabel;

  /// Field label for the collection date picker
  ///
  /// In en, this message translates to:
  /// **'COLLECTION DATE'**
  String get collectionDateLabel;

  /// Hint text for the payment method dropdown
  ///
  /// In en, this message translates to:
  /// **'Select method'**
  String get selectMethodHint;

  /// Hint text for the collection date field
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateHint;

  /// Field label for the optional notes field on a collection
  ///
  /// In en, this message translates to:
  /// **'NOTES (OPTIONAL)'**
  String get notesOptionalLabel;

  /// Hint text for the collection notes field
  ///
  /// In en, this message translates to:
  /// **'Receipt or transaction ref...'**
  String get receiptNotesHint;

  /// Button label to submit a recorded collection
  ///
  /// In en, this message translates to:
  /// **'Confirm Collection'**
  String get confirmCollectionButton;

  /// Title of the add-member bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMemberTitle;

  /// Field label for the customer selector
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER *'**
  String get customerLabel;

  /// Hint text for the customer dropdown
  ///
  /// In en, this message translates to:
  /// **'Select a customer...'**
  String get selectCustomerHint;

  /// Shown under the customer selector when the selected customer has no phone number
  ///
  /// In en, this message translates to:
  /// **'{role} · Customer number not available'**
  String customerNumberNotAvailable(String role);

  /// Shown under the customer selector with the selected customer's role and phone
  ///
  /// In en, this message translates to:
  /// **'{role} · {phone}'**
  String customerRolePhone(String role, String phone);

  /// Field label for the new member's contribution amount
  ///
  /// In en, this message translates to:
  /// **'CONTRIBUTION AMOUNT'**
  String get contributionAmountLabel;

  /// Validation error for an invalid numeric field
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterValidNumberValidation;

  /// Helper text showing the default contribution amount
  ///
  /// In en, this message translates to:
  /// **'Defaults to {amount}'**
  String defaultsToAmount(String amount);

  /// Toast title when no customer is selected before saving
  ///
  /// In en, this message translates to:
  /// **'Select a customer'**
  String get selectCustomerTitle;

  /// Toast message when no customer is selected before saving
  ///
  /// In en, this message translates to:
  /// **'Choose a customer to add to this group.'**
  String get selectCustomerMessage;

  /// Toast title when adding a member fails
  ///
  /// In en, this message translates to:
  /// **'Add member failed'**
  String get addMemberFailedTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
