// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'RR Groups';

  @override
  String get welcomeMessage => 'Welcome to FinCollect';

  @override
  String get loans => 'Loans';

  @override
  String get collections => 'Collections';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get paymentReminders => 'Payment Reminders';

  @override
  String get groupUpdates => 'Group Updates';

  @override
  String get security => 'Security';

  @override
  String get changeMpin => 'Change MPIN';

  @override
  String get biometricLogin => 'Biometric Login';

  @override
  String get preferences => 'Preferences';

  @override
  String get language => 'Language';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get help => 'Help';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get faq => 'FAQ';

  @override
  String get logout => 'Log out';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get confirmLogoutQuestion =>
      'Are you sure you want to log out of your account?';

  @override
  String get cancel => 'Cancel';

  @override
  String get loggedOut => 'Logged out';

  @override
  String get connectBackendToEnable => 'Connect backend to enable';

  @override
  String get deleteEntry => 'Delete Entry';

  @override
  String get delete => 'Delete';

  @override
  String get printStatement => 'Print Statement';

  @override
  String get accountBook => 'Account Book';

  @override
  String get recycleBinTitle => 'Recycle Bin';

  @override
  String get recycleBinSubtitle =>
      'Everything deleted anywhere in the app — by an admin, an agent or a customer';

  @override
  String get recycleBinSearchHint =>
      'Search by name, type or who deleted it...';

  @override
  String get recycleBinEmptyButton => 'Empty Recycle Bin';

  @override
  String get recycleBinRestoreLabel => 'Restore';

  @override
  String get recycleBinRestoredBadge => 'Restored';

  @override
  String get recycleBinDeletePermanentlyTitle => 'Delete Permanently?';

  @override
  String get recycleBinEmptyTitle => 'Empty Recycle Bin?';

  @override
  String get recycleBinEmptyMessage =>
      'Are you sure you want to permanently delete all items? This action cannot be undone.';

  @override
  String get recycleBinNoItems => 'No matching items found.';

  @override
  String get customersTitle => 'Customers';

  @override
  String get customersSubtitle => 'Manage customer information and details';

  @override
  String get customersAddButton => 'Add Customer';

  @override
  String get customersSearchHint => 'Search by name...';

  @override
  String get customersFilterAll => 'All Status';

  @override
  String get customersFilterActive => 'Active';

  @override
  String get customersFilterOverdue => 'Overdue';

  @override
  String get customersFilterInactive => 'Inactive';

  @override
  String get customersNoResults => 'No customers found';

  @override
  String get retry => 'Retry';

  @override
  String get customersLoadFailedTitle => 'Failed to load customers';

  @override
  String get customersDeleteTitle => 'Delete Customer';

  @override
  String customersDeleteMessage(String name) {
    return 'Are you sure you want to delete $name? They will be moved to the Recycle Bin and can be restored later.';
  }

  @override
  String get customersDeletedTitle => 'Customer deleted';

  @override
  String customersDeletedMessage(String name) {
    return '$name was removed successfully';
  }

  @override
  String get customersDeleteFailedTitle => 'Delete failed';

  @override
  String get customersUpdatedTitle => 'Customer updated';

  @override
  String get customersAddedTitle => 'Customer added';

  @override
  String customersUpdatedMessage(String name) {
    return '$name was updated successfully';
  }

  @override
  String customersAddedMessage(String name) {
    return '$name was added successfully';
  }

  @override
  String get customersSaveFailedTitle => 'Something went wrong';

  @override
  String get customerViewClose => 'Close';

  @override
  String get customerFieldId => 'CUSTOMER ID';

  @override
  String get customerFieldMobile => 'MOBILE';

  @override
  String get customerFieldAddress => 'ADDRESS';

  @override
  String get customerFieldAadhaar => 'AADHAAR';

  @override
  String get customerFieldPan => 'PAN';

  @override
  String get customerFieldOccupation => 'OCCUPATION';

  @override
  String get customerFieldAgent => 'ASSIGNED AGENT';

  @override
  String get customerFieldLoanStatus => 'LOAN STATUS';

  @override
  String get customerActionView => 'View';

  @override
  String get customerActionEdit => 'Edit';

  @override
  String get customerActionDelete => 'Delete';

  @override
  String get customerUnassigned => 'Unassigned';

  @override
  String get customerFormEditTitle => 'Edit Customer';

  @override
  String get customerFormAddTitle => 'Add Customer';

  @override
  String get customerFormEditSubtitle => 'Update customer details';

  @override
  String get customerFormAddSubtitle => 'Fill in the details below';

  @override
  String get customerSectionPersonal => 'Personal Details';

  @override
  String get customerSectionAssignment => 'Assignment';

  @override
  String get customerSectionPortalLogin => 'Portal Login (optional)';

  @override
  String get customerSectionPhoto => 'Photo';

  @override
  String get customerLabelFullName => 'FULL NAME *';

  @override
  String get customerHintFullName => 'e.g. Ramesh Kumar';

  @override
  String get customerLabelMobile => 'MOBILE NUMBER *';

  @override
  String get customerHintMobile => '10-digit mobile number';

  @override
  String get customerLabelAddress => 'ADDRESS *';

  @override
  String get customerHintAddress => 'Full residential address';

  @override
  String get customerLabelAadhaar => 'AADHAAR (optional)';

  @override
  String get customerHintAadhaar => '12-digit Aadhaar number';

  @override
  String get customerLabelPan => 'PAN (optional)';

  @override
  String get customerHintPan => 'e.g. ABCDE1234F';

  @override
  String get customerLabelOccupation => 'OCCUPATION (optional)';

  @override
  String get customerHintOccupation => 'e.g. Shop owner';

  @override
  String get customerLabelAssignedAgent => 'ASSIGNED AGENT';

  @override
  String get customerMapLocationTitle => 'Map Location';

  @override
  String get customerMapLocationSubtitle => 'for agent route';

  @override
  String get customerPinFromAddress => 'Pin from address';

  @override
  String get customerUseMyGps => 'Use my GPS';

  @override
  String get customerMapHelpText =>
      'Shows this customer on the agent\'s live Route Map. \"Pin from address\" looks up the address above; \"Use my GPS\" captures where you\'re standing.';

  @override
  String get customerLatitudeLabel => 'LATITUDE';

  @override
  String get customerLongitudeLabel => 'LONGITUDE';

  @override
  String get customerLatLngHint => '0.0000000';

  @override
  String get customerAddressRequiredTitle => 'Address required';

  @override
  String get customerAddressRequiredMessage =>
      'Enter an address first so it can be located on the map';

  @override
  String get customerAddressNotFoundTitle => 'Couldn\'t find that address';

  @override
  String get customerLocationFailedTitle => 'Couldn\'t get your location';

  @override
  String get customerPhotoFailedTitle => 'Photo upload failed';

  @override
  String get customerPortalLoginHelp =>
      'Set a password to let this customer sign in with their mobile number to view their own loans & payments. No email needed.';

  @override
  String get customerLabelEmail => 'EMAIL (optional)';

  @override
  String get customerHintEmail => 'customer@example.com';

  @override
  String get customerLabelPassword => 'PASSWORD (optional)';

  @override
  String get customerHintPassword => 'At least 6 characters';

  @override
  String get customerLoginNote =>
      'Login uses the mobile number above as the username.';

  @override
  String get customerUploadPhoto => 'Upload Photo';

  @override
  String get customerSaveChanges => 'Save Changes';

  @override
  String get customerFormValidationTitle => 'Check the form';

  @override
  String get customerFormValidationMessage =>
      'Please fix the highlighted fields before saving';

  @override
  String get customerValidatorNameRequired => 'Full name is required';

  @override
  String get customerValidatorNameMin => 'Enter at least 3 characters';

  @override
  String get customerValidatorNameChars =>
      'Only letters and spaces are allowed';

  @override
  String get customerValidatorMobileRequired => 'Mobile number is required';

  @override
  String get customerValidatorMobileInvalid =>
      'Enter a valid 10-digit mobile number';

  @override
  String get customerValidatorAddressRequired => 'Address is required';

  @override
  String get customerValidatorAddressMin => 'Enter a more complete address';

  @override
  String get customerValidatorAadhaarInvalid =>
      'Aadhaar must be exactly 12 digits';

  @override
  String get customerValidatorPanInvalid =>
      'Enter a valid PAN (e.g. ABCDE1234F)';

  @override
  String get customerValidatorOccupationInvalid => 'Enter a valid occupation';

  @override
  String get customerValidatorNumberInvalid => 'Enter a valid number';

  @override
  String get customerValidatorLatRange => 'Must be between -90 and 90';

  @override
  String get customerValidatorLngRange => 'Must be between -180 and 180';

  @override
  String get customerValidatorEmailInvalid => 'Enter a valid email address';

  @override
  String get customerValidatorPasswordMin =>
      'Password must be at least 6 characters';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String dashboardNotLinkedYet(String label) {
    return '$label is not linked yet';
  }

  @override
  String get dashboardGreetingMorning => 'Good morning';

  @override
  String get dashboardGreetingAfternoon => 'Good afternoon';

  @override
  String get dashboardGreetingEvening => 'Good evening';

  @override
  String dashboardGreetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String dashboardLiveFigures(String amount, int count) {
    return 'Live figures from the database: $amount collected today and $count active loans.';
  }

  @override
  String get dashboardNetBalanceSummary => 'Net Balance Summary';

  @override
  String get dashboardNetBalanceSubtitle =>
      'Real-time working capital position';

  @override
  String get dashboardCashInHand => 'CASH IN HAND';

  @override
  String get dashboardLoanCollections => 'Loan Collections';

  @override
  String get dashboardFundDeposits => 'Fund Deposits';

  @override
  String get dashboardCustomCashIn => '+ Custom Cash In';

  @override
  String get dashboardOutstandingMoneyLent => 'OUTSTANDING MONEY LENT';

  @override
  String get dashboardLoansOutstanding => 'Loans Outstanding';

  @override
  String get dashboardCustomLent => '+ Custom Lent';

  @override
  String get dashboardNetBalanceLabel => 'NET BALANCE';

  @override
  String get dashboardTotalAssets => 'TOTAL ASSETS';

  @override
  String dashboardNetBalanceFormula(String cash, String lent) {
    return 'Cash In Hand ($cash) + Money Lent ($lent)';
  }

  @override
  String get dashboardStatActiveLoans => 'Active Loans';

  @override
  String get dashboardStatNewCustomers => 'New Customers';

  @override
  String get dashboardStatTodaysCollections => 'Today\'s Collections';

  @override
  String get dashboardStatOverdueAccounts => 'Overdue Accounts';

  @override
  String get dashboardStatPendingApprovals => 'Pending Approvals';

  @override
  String get dashboardStatTotalLoanAmount => 'Total Loan Amount';

  @override
  String get dashboardStatInterestRevenue => 'Interest Revenue';

  @override
  String get dashboardStatMonthlyCollection => 'Monthly Collection';

  @override
  String get dashboardCollectionTrend => 'Collection Trend';

  @override
  String get dashboardCollectionTrendSubtitle =>
      'Last months from reports table';

  @override
  String get dashboardLoanStatus => 'Loan Status';

  @override
  String get dashboardLoanStatusSubtitle => 'Live database summary';

  @override
  String get dashboardDonutTotal => 'Total';

  @override
  String get dashboardStatusActive => 'Active';

  @override
  String get dashboardStatusOverdue => 'Overdue';

  @override
  String get dashboardStatusClosedOther => 'Closed/Other';

  @override
  String get dashboardAgentPerformance => 'Agent Performance';

  @override
  String get dashboardAgentPerformanceSubtitle =>
      'Top field agents from report';

  @override
  String get dashboardMonthlyProgress => 'Monthly Collection Progress';

  @override
  String dashboardMonthlyProgressSubtitle(String collected, String target) {
    return '₹$collected of ₹$target target';
  }

  @override
  String get dashboardQuickActions => 'Quick Actions';

  @override
  String get dashboardQuickAddCustomer => 'Add Customer';

  @override
  String get dashboardQuickCreateLoan => 'Create Loan';

  @override
  String get dashboardQuickChitGroup => 'Chit Group';

  @override
  String get dashboardQuickAddAgent => 'Add Agent';

  @override
  String get dashboardQuickReports => 'Reports';

  @override
  String get dashboardRecentCollections => 'Recent Collections';

  @override
  String get dashboardRecentCollectionsSubtitle => 'Latest payments received';

  @override
  String get dashboardNoCollectionsToday => 'No collections found for today.';

  @override
  String get dashboardRecentLoans => 'Recent Loans';

  @override
  String get dashboardRecentLoansSubtitle => 'Newly disbursed loans';

  @override
  String get dashboardNoLoansToday => 'No new loans found for today.';

  @override
  String get dashboardViewAll => 'View all';

  @override
  String get loansTitle => 'Loans';

  @override
  String get loansSubtitle => 'Manage customer loans and repayment schedules';

  @override
  String get loansCreateButton => 'Create Loan';

  @override
  String get loansSearchHint => 'Search by customer or loan number...';

  @override
  String get loansFilterAll => 'All';

  @override
  String get loansStatusActive => 'Active';

  @override
  String get loansStatusOverdue => 'Overdue';

  @override
  String get loansStatusClosed => 'Closed';

  @override
  String get loansStatusPending => 'Pending';

  @override
  String get loansScheduleStatusPaid => 'Paid';

  @override
  String get loansScheduleStatusDueToday => 'Due Today';

  @override
  String get loansTypeMonthlyEmi => 'Monthly EMI';

  @override
  String get loansTypeMonthlyInterest => 'Monthly Interest';

  @override
  String get loansTypeWeekly => 'Weekly';

  @override
  String get loansTypeDaily => 'Daily';

  @override
  String get loansScheduleEmptyMessage => 'No repayment schedule available.';

  @override
  String get loansScheduleColIndex => '#';

  @override
  String get loansScheduleColDueDate => 'Due Date';

  @override
  String get loansScheduleColEmi => 'EMI';

  @override
  String get loansScheduleColPaid => 'Paid';

  @override
  String get loansScheduleColBalance => 'Balance';

  @override
  String get loansScheduleColStatus => 'Status';

  @override
  String loansCouldNotLoad(String error) {
    return 'Could not load loans: $error';
  }

  @override
  String get loansLoanCreatedTitle => 'Loan created';

  @override
  String get loansLoanUpdatedTitle => 'Loan updated';

  @override
  String get loansCloseLoanTitle => 'Close Loan';

  @override
  String loansCloseLoanMessage(String loanNumber) {
    return 'Are you sure you want to close loan $loanNumber?';
  }

  @override
  String get loansCloseLoanConfirm => 'Close';

  @override
  String get loansLoanClosedTitle => 'Loan closed';

  @override
  String loansLoanClosedMessage(String loanNumber) {
    return 'Loan $loanNumber was closed successfully.';
  }

  @override
  String get loansCloseFailedTitle => 'Close failed';

  @override
  String get loansCloseBlockedTitle => 'Cannot close loan';

  @override
  String loansCloseBlockedMessage(String amount) {
    return 'This loan still has $amount pending. Collect the full outstanding amount before closing it.';
  }

  @override
  String get loansDeleteLoanTitle => 'Delete Loan';

  @override
  String loansDeleteLoanMessage(String loanNumber) {
    return 'Are you sure you want to delete loan $loanNumber? It will be moved to the Recycle Bin.';
  }

  @override
  String get loansDeleteLoanConfirm => 'Delete';

  @override
  String get loansLoanDeletedTitle => 'Loan deleted';

  @override
  String loansLoanDeletedMessage(String loanNumber) {
    return 'Loan $loanNumber was moved to the Recycle Bin.';
  }

  @override
  String get loansDeleteFailedTitle => 'Delete failed';

  @override
  String get loansNoLoansFound => 'No loans found';

  @override
  String get loansColHpNo => 'HP No.';

  @override
  String get loansColCustomer => 'Customer';

  @override
  String get loansColType => 'Type';

  @override
  String get loansColAmount => 'Amount';

  @override
  String get loansColEmi => 'EMI';

  @override
  String get loansColOutstanding => 'Outstanding';

  @override
  String get loansColAgent => 'Agent';

  @override
  String get loansColStatus => 'Status';

  @override
  String get loansColStart => 'Start Date';

  @override
  String get loansColActions => 'Actions';

  @override
  String get loansActionView => 'View';

  @override
  String get loansActionEdit => 'Edit';

  @override
  String get loansActionClose => 'Close';

  @override
  String get loansActionDelete => 'Delete';

  @override
  String loansDurationWeeks(int count) {
    return '$count weeks';
  }

  @override
  String loansDurationDays(int count) {
    return '$count days';
  }

  @override
  String loansDurationMonthsInterestOnly(int count) {
    return '$count months (interest only)';
  }

  @override
  String loansDurationMonths(int count) {
    return '$count months';
  }

  @override
  String loansDetailTitle(String loanNumber) {
    return 'Loan $loanNumber';
  }

  @override
  String get loansFieldCustomer => 'Customer';

  @override
  String get loansFieldLoanType => 'Loan Type';

  @override
  String get loansFieldLoanAmount => 'Loan Amount';

  @override
  String get loansFieldMonthlyInterest => 'Monthly Interest';

  @override
  String get loansFieldEmi => 'EMI';

  @override
  String get loansFieldOutstanding => 'Outstanding';

  @override
  String get loansFieldPenalty => 'Penalty';

  @override
  String get loansFieldTotalDuePenalty => 'Total Due (with Penalty)';

  @override
  String get loansFieldInterest => 'Interest Rate';

  @override
  String get loansFieldDuration => 'Duration';

  @override
  String get loansFieldStartDate => 'Start Date';

  @override
  String get loansFieldAgent => 'Agent';

  @override
  String get loansHideSchedule => 'Hide Schedule';

  @override
  String get loansShowSchedule => 'Show Schedule';

  @override
  String get loansRepaymentSchedule => 'Repayment Schedule';

  @override
  String get loansRefreshScheduleTooltip => 'Refresh schedule';

  @override
  String get loansInterestOnlyScheduleNote =>
      'This is an interest-only loan. Principal repayment is flexible and isn\'t reflected in the schedule below.';

  @override
  String get loansCustomerRequiredTitle => 'Customer Required';

  @override
  String get loansCustomerRequiredMessage =>
      'Please select a customer before saving this loan.';

  @override
  String get loansSaveFailedTitle => 'Save Failed';

  @override
  String get loansEditTitle => 'Edit Loan';

  @override
  String get loansCreateTitle => 'Create Loan';

  @override
  String get loansHpNumberLabel => 'HP Number';

  @override
  String get loansHpNumberLoading => 'Generating…';

  @override
  String get loansHpNumberAuto => 'Auto-generated';

  @override
  String get loansProcessingFeeLabel => 'Processing Fee';

  @override
  String get loansProcessingFeeHint => 'Enter processing fee';

  @override
  String get loansNotesLabel => 'Notes';

  @override
  String get loansNotesHint => 'Add any additional notes';

  @override
  String get loansSave => 'Save';

  @override
  String get loansApprove => 'Approve';

  @override
  String get loansCustomerRequiredLabel => 'Customer *';

  @override
  String get loansCustomerHint => 'Search customer';

  @override
  String get loansAgentLabel => 'Agent';

  @override
  String get loansAgentHint => 'Search agent';

  @override
  String get loansCollectionTypeLabel => 'Collection Type';

  @override
  String get loansLoanAmountLabel => 'Loan Amount';

  @override
  String get loansLoanAmountHint => 'Enter loan amount';

  @override
  String get loansInterestRateMonthlyLabel => 'Monthly Interest Rate (%)';

  @override
  String get loansInterestRateHint25 => 'e.g. 2.5';

  @override
  String get loansDurationMonthsLabel => 'Duration (Months)';

  @override
  String get loansDurationHint10 => 'e.g. 10';

  @override
  String get loansMonthlyInterestRateLabel => 'Monthly Interest Rate (%)';

  @override
  String get loansLoanTenureLabel => 'Loan Tenure (Months)';

  @override
  String get loansInterestRateLabel => 'Interest Rate (%)';

  @override
  String get loansDurationFixedLabel => 'Duration';

  @override
  String get loansDurationWeeksFixed => '10 weeks (fixed)';

  @override
  String get loansCollectionPlanLabel => 'Collection Plan';

  @override
  String get loansPlan60Days => '60 Days';

  @override
  String get loansPlan100Days => '100 Days';

  @override
  String get loansInterestOnlyBoxTitle => 'Interest-Only Loan';

  @override
  String get loansInterestOnlyBoxBody =>
      'The borrower repays only the monthly interest. Principal can be repaid anytime and isn\'t part of the fixed schedule.';

  @override
  String get loansWeeklyPenaltyTitle => 'Weekly Penalty';

  @override
  String get loansDailyPenaltyTitle => 'Daily Penalty';

  @override
  String get loansWeeklyPenaltyHelper =>
      'Apply a fixed penalty for missed weekly payments.';

  @override
  String get loansDailyPenaltyHelper =>
      'Apply a daily penalty rate on overdue balances.';

  @override
  String get loansDailyPenaltyRateLabel => 'Penalty Rate / Day';

  @override
  String get loansDailyPenaltyRateHint => 'e.g. 50';

  @override
  String get loansDailyPenaltyExample =>
      'Applied daily to any overdue balance.';

  @override
  String get loansWeeklyPenaltyAmountLabel => 'Penalty Amount / Week';

  @override
  String get loansWeeklyPenaltyAmountHint => 'e.g. 100';

  @override
  String get loansWeeklyPenaltyAutoNote =>
      'Applied automatically each week a payment is missed.';

  @override
  String get loansSummaryMonthlyEmi => 'Monthly EMI';

  @override
  String loansSummaryPerMonth(int count) {
    return 'for $count months';
  }

  @override
  String get loansSummaryTotalInterest => 'Total Interest';

  @override
  String loansSummaryPerMonthAmount(String amount) {
    return '$amount per month';
  }

  @override
  String get loansSummaryTotalRepayment => 'Total Repayment';

  @override
  String get loansSummaryPrincipalPlusInterest => 'Principal + Interest';

  @override
  String get loansSummaryMonthlyInterestDue => 'Monthly Interest Due';

  @override
  String loansSummaryRateOfPrincipal(String rate, String principal) {
    return '$rate% of $principal';
  }

  @override
  String get loansSummaryPrincipalRepayment => 'Principal Repayment';

  @override
  String get loansSummaryFlexibleInstallments => 'Flexible';

  @override
  String get loansSummaryRepayAnytime => 'Repay the principal anytime';

  @override
  String get loansSummaryPrincipalDisbursed => 'Principal Disbursed';

  @override
  String loansSummaryTenureMonths(int count) {
    return 'Over $count months';
  }

  @override
  String get loansSummaryWeeklyInstallment => 'Weekly Installment';

  @override
  String loansSummaryWeeksEqual(String principal) {
    return '10 weeks totalling $principal';
  }

  @override
  String get loansSummaryInterestDeducted => 'Interest Deducted';

  @override
  String get loansSummaryDeductedUpfront => 'Deducted upfront';

  @override
  String get loansSummaryAmountDisbursed => 'Amount Disbursed';

  @override
  String get loansSummaryPrincipalMinusInterest => 'Principal − Interest';

  @override
  String get loansSummaryDailyInstallment => 'Daily Installment';

  @override
  String loansSummaryDaysEqual(int days, String total) {
    return '$days days totalling $total';
  }

  @override
  String get loansSummaryInterestAdded => 'Interest Added';

  @override
  String get loansSummaryAddedToRepayment => 'Added to total repayment';

  @override
  String get loansSummaryAmountDisbursedToBorrower =>
      'Amount Disbursed to Borrower';

  @override
  String get loansSummaryFullLoanAmount => 'Full loan amount';

  @override
  String get loansScheduleSectionTitle => 'Repayment Schedule Preview';

  @override
  String get loansStartDateLabel => 'Start Date';

  @override
  String get loansStartDateHint => 'DD/MM/YYYY';

  @override
  String get repaymentTitle => 'Repayment Schedule';

  @override
  String get repaymentSubtitle =>
      'Track installment-wise EMI collections and outstanding balances';

  @override
  String get repaymentCouldNotLoadLoans => 'Could not load loans';

  @override
  String get repaymentLoanLoadFailedTitle => 'Loan load failed';

  @override
  String get repaymentCouldNotLoadSchedule =>
      'Could not load repayment schedule';

  @override
  String get repaymentLoadFailedTitle => 'Load failed';

  @override
  String get repaymentSelectLoanLabel => 'SELECT LOAN';

  @override
  String get repaymentSelectLoanHint => 'Select loan';

  @override
  String get repaymentLoanSwitchedTitle => 'Loan switched';

  @override
  String get repaymentInstallmentBreakdown => 'INSTALLMENT BREAKDOWN';

  @override
  String get repaymentNoInstallmentsFound =>
      'No installments found for this loan';

  @override
  String get repaymentStatLoanNumber => 'LOAN NUMBER';

  @override
  String get repaymentStatCustomer => 'CUSTOMER';

  @override
  String get repaymentStatLoanAmount => 'LOAN AMOUNT';

  @override
  String get repaymentStatEmi => 'EMI';

  @override
  String get repaymentStatTotalRepayment => 'TOTAL REPAYMENT';

  @override
  String get repaymentStatOutstanding => 'OUTSTANDING';

  @override
  String get repaymentStatPenalty => 'PENALTY';

  @override
  String get repaymentStatTotalDuePenalty => 'TOTAL DUE + PENALTY';

  @override
  String get repaymentStatTotalInstallments => 'TOTAL INST.';

  @override
  String get repaymentStatPaid => 'PAID';

  @override
  String get repaymentStatPending => 'PENDING';

  @override
  String get repaymentStatOverdue => 'OVERDUE';

  @override
  String get repaymentStatNextDue => 'NEXT DUE';

  @override
  String get repaymentColInstNo => 'INST. NO';

  @override
  String get repaymentColDueDate => 'DUE DATE';

  @override
  String get repaymentColEmiAmount => 'EMI AMOUNT';

  @override
  String get repaymentColPaid => 'PAID';

  @override
  String get repaymentColBalance => 'BALANCE';

  @override
  String get repaymentColPenalty => 'PENALTY';

  @override
  String get repaymentColStatus => 'STATUS';

  @override
  String get repaymentNoLoanSelected => 'No loan selected';

  @override
  String repaymentPenaltyBannerTitle(String type, String duration) {
    return '$type Finance ($duration)';
  }

  @override
  String get repaymentPenaltyBannerWeeklyBody =>
      'Automatic default penalty of ₹100 applies per ₹10,000 principal for every missed weekly payment.';

  @override
  String repaymentPenaltyBannerRateBody(String rate) {
    return 'A penalty of $rate per day applies for every day a payment remains overdue.';
  }

  @override
  String repaymentAccruedPenaltyLabel(String amount) {
    return 'ACCRUED PENALTY: $amount';
  }

  @override
  String repaymentDurationWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Weeks',
      one: '1 Week',
    );
    return '$_temp0';
  }

  @override
  String repaymentDurationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Months',
      one: '1 Month',
    );
    return '$_temp0';
  }

  @override
  String repaymentDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Days',
      one: '1 Day',
    );
    return '$_temp0';
  }

  @override
  String get repaymentRecordCollectionButton => 'Record Collection';

  @override
  String get repaymentRecordCollectionSheetTitle => 'Record Collection';

  @override
  String repaymentRecordCollectionSubtitle(String loanNumber, String customer) {
    return '$loanNumber — $customer';
  }

  @override
  String get repaymentRecordCollectionInstallmentLabel => 'INSTALLMENT';

  @override
  String get repaymentRecordCollectionGeneralPayment => 'General Payment';

  @override
  String get repaymentRecordCollectionAmountLabel => 'AMOUNT';

  @override
  String get repaymentRecordCollectionMethodLabel => 'PAYMENT METHOD';

  @override
  String get repaymentRecordCollectionDateLabel => 'PAYMENT DATE';

  @override
  String get repaymentRecordCollectionNotesLabel => 'NOTES (OPTIONAL)';

  @override
  String get repaymentRecordCollectionNotesHint =>
      'Add a note about this payment';

  @override
  String get repaymentRecordCollectionSubmit => 'Save Collection';

  @override
  String get repaymentRecordCollectionCancel => 'Cancel';

  @override
  String get repaymentRecordCollectionAllPaidTitle => 'All caught up';

  @override
  String get repaymentRecordCollectionAllPaidMessage =>
      'Every installment on this loan is already paid.';

  @override
  String get repaymentRecordCollectionSuccessTitle => 'Collection recorded';

  @override
  String get repaymentRecordCollectionFailedTitle =>
      'Could not record collection';

  @override
  String get repaymentRecordCollectionSelectLoanFirst => 'Select a loan first';

  @override
  String get repaymentRecordCollectionAmountRequired => 'Enter a valid amount';

  @override
  String get collectionsLoadFailedTitle => 'Failed to load collections';

  @override
  String get collectionsTitle => 'Collections';

  @override
  String get collectionsSubtitle =>
      'Record and track daily collections across all loans';

  @override
  String get collectionsAddButton => 'Add Collection';

  @override
  String get collectionsStatTodayTotal => 'TODAY\'S TOTAL';

  @override
  String get collectionsStatThisWeek => 'THIS WEEK';

  @override
  String get collectionsStatThisMonth => 'THIS MONTH';

  @override
  String get collectionsStatTotalRecords => 'TOTAL RECORDS';

  @override
  String get collectionsSearchHint =>
      'Search customer, loan or receipt number...';

  @override
  String get collectionsPeriodToday => 'Today';

  @override
  String get collectionsPeriodThisWeek => 'This Week';

  @override
  String get collectionsPeriodThisMonth => 'This Month';

  @override
  String get collectionsColCustomer => 'CUSTOMER';

  @override
  String get collectionsColLoanNumber => 'LOAN NUMBER';

  @override
  String get collectionsColAmount => 'AMOUNT';

  @override
  String get collectionsColMethod => 'METHOD';

  @override
  String get collectionsColDate => 'DATE';

  @override
  String get collectionsColAgent => 'AGENT';

  @override
  String get collectionsColActions => 'ACTIONS';

  @override
  String get collectionsActionEdit => 'Edit';

  @override
  String get collectionsActionDelete => 'Delete';

  @override
  String get collectionsNoneFound => 'No collections found';

  @override
  String get collectionsShowLess => 'Show Less';

  @override
  String collectionsShowMore(int count) {
    return 'Show More ($count more)';
  }

  @override
  String get collectionsDeleteTitle => 'Delete Collection';

  @override
  String collectionsDeleteMessage(String customer, String receipt) {
    return 'Delete the collection record for $customer ($receipt)? It will be moved to the Recycle Bin and can be restored later.';
  }

  @override
  String get collectionsDeleteFailedTitle => 'Delete failed';

  @override
  String get collectionsUpdateFailedTitle => 'Update failed';

  @override
  String get collectionsRecordIdNotFound => 'Could not find record id';

  @override
  String get collectionsDeletedTitle => 'Collection deleted';

  @override
  String get collectionsDeleteApiFailedTitle => 'Failed to delete collection';

  @override
  String get collectionsRecordedTitle => 'Collection recorded';

  @override
  String get collectionsSaveFailedTitle => 'Failed to save collection';

  @override
  String get collectionsUpdatedTitle => 'Collection updated';

  @override
  String get collectionsUpdateApiFailedTitle => 'Failed to update collection';

  @override
  String get collectionsMethodCash => 'Cash';

  @override
  String get collectionsMethodUpi => 'UPI';

  @override
  String get collectionsMethodBank => 'Bank Transfer';

  @override
  String get collectionsMethodCheque => 'Cheque';

  @override
  String get collectionsMethodCard => 'Card';

  @override
  String get collectionsSelectCustomerTitle => 'Select a customer';

  @override
  String get collectionsSelectCustomerMessage =>
      'Please choose a customer before saving.';

  @override
  String get collectionsEditTitle => 'Edit Collection';

  @override
  String get collectionsCustomerRequiredLabel => 'CUSTOMER *';

  @override
  String get collectionsSelectCustomerHint => 'Select customer';

  @override
  String get collectionsLoanNumberLabel => 'LOAN NUMBER';

  @override
  String get collectionsSelectCustomerFirstHint => 'Select customer first';

  @override
  String get collectionsSelectLoanHint => 'Select loan';

  @override
  String get collectionsOutstandingAbbrev => 'Out';

  @override
  String get collectionsSelectLoanPrompt =>
      'Select a loan to view its live details';

  @override
  String collectionsLoansLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count loans linked to the selected customer',
      one: '$count loan linked to the selected customer',
    );
    return '$_temp0';
  }

  @override
  String get collectionsAmountReceivedLabel => 'AMOUNT RECEIVED *';

  @override
  String get collectionsPaymentMethodLabel => 'PAYMENT METHOD *';

  @override
  String get collectionsCollectionDateLabel => 'COLLECTION DATE *';

  @override
  String get collectionsSelectAgentHint => 'Select agent';

  @override
  String get collectionsNotesLabel => 'NOTES';

  @override
  String get collectionsNotesHint => 'Any remarks about this collection...';

  @override
  String get collectionsPaymentScreenshotLabel => 'PAYMENT SCREENSHOT';

  @override
  String get collectionsCustomerSignatureLabel => 'CUSTOMER SIGNATURE';

  @override
  String get collectionsCancelButton => 'Cancel';

  @override
  String get collectionsReceiptButton => 'Receipt';

  @override
  String get collectionsUpdateButton => 'Update';

  @override
  String get collectionsSaveButton => 'Save';

  @override
  String get collectionsGeneratingReceiptTitle => 'Generating receipt...';

  @override
  String get collectionsUploadSignatureTitle => 'Add Customer Signature';

  @override
  String get collectionsUploadScreenshotTitle => 'Upload Payment Screenshot';

  @override
  String get collectionsUploadPlaceholder => 'Upload document...';

  @override
  String collectionsSummaryAgent(String name) {
    return 'Agent: $name';
  }

  @override
  String collectionsSummaryPrincipal(String amount) {
    return 'Principal: $amount';
  }

  @override
  String collectionsSummaryInstallment(String amount) {
    return 'Installment: $amount';
  }

  @override
  String collectionsSummaryOutstanding(String amount) {
    return 'Outstanding: $amount';
  }

  @override
  String collectionsSummaryOverdueDue(String amount) {
    return 'Overdue due: $amount';
  }

  @override
  String collectionsSummaryPenalty(String amount) {
    return 'Penalty: $amount';
  }

  @override
  String collectionsSummaryTotalDue(String amount) {
    return 'Total due: $amount';
  }

  @override
  String get collectionsPresetOneEmi => '1 EMI';

  @override
  String get collectionsPresetFillInterest => 'Fill Interest';

  @override
  String get collectionsPresetPayDue => 'Pay Due Amount';

  @override
  String get collectionsPresetPrincipalPartPayment => 'Principal Part-Payment';

  @override
  String get collectionsPresetFullBalance => 'Full Balance';

  @override
  String get collectionsPurposeMonthlyInterest => 'Monthly Interest Payment';

  @override
  String collectionsPaymentSummaryLine(String payment, String remaining) {
    return 'Payment: $payment • Remaining balance: $remaining';
  }

  @override
  String get handoverLoadFailedTitle => 'Failed to load handover data';

  @override
  String get handoverUpdatedTitle => 'Handover updated';

  @override
  String get handoverRecordedTitle => 'Handover recorded';

  @override
  String get handoverFailedTitle => 'Handover failed';

  @override
  String get handoverMarkedPendingTitle => 'Marked pending';

  @override
  String get handoverMarkedVerifiedTitle => 'Marked verified';

  @override
  String get handoverUpdateFailedTitle => 'Could not update handover';

  @override
  String get handoverDeletedTitle => 'Handover deleted';

  @override
  String get handoverDeleteFailedTitle => 'Could not delete handover';

  @override
  String get handoverTitle => 'Cash Handover';

  @override
  String get handoverSubtitle =>
      'Agents settle collected cash & UPI to the office — pending carries forward';

  @override
  String get handoverRecordButton => 'Record Handover';

  @override
  String get handoverStatTotalCollected => 'Total Collected';

  @override
  String get handoverStatTodayZero => 'Today: ₹0';

  @override
  String get handoverStatHandedOver => 'Handed Over';

  @override
  String get handoverStatPending => 'Pending';

  @override
  String get handoverStatAgentsWithPending => 'Agents With Pending';

  @override
  String get handoverSettlementPositionTitle => 'Agent Settlement Position';

  @override
  String get handoverSettlementPositionSubtitle =>
      'Pending = collected − handed over (runs continuously)';

  @override
  String get handoverHistoryTitle => 'Handover History';

  @override
  String get handoverHistoryEmpty => 'No handovers recorded yet.';

  @override
  String get handoverColAgent => 'AGENT';

  @override
  String get handoverColCollected => 'COLLECTED';

  @override
  String get handoverColHandedOver => 'HANDED OVER';

  @override
  String get handoverColPending => 'PENDING';

  @override
  String get handoverDeleteConfirmTitle => 'Delete Handover?';

  @override
  String handoverDeleteConfirmMessage(String agentName, String amount) {
    return '$agentName\'s handover record of $amount will be moved to the Recycle Bin and can be restored later.';
  }

  @override
  String get handoverDeleteButton => 'Delete';

  @override
  String get handoverStatusVerified => 'verified';

  @override
  String get handoverStatusPending => 'pending';

  @override
  String get handoverReceivedLabel => 'Received';

  @override
  String get handoverEditButton => 'Edit';

  @override
  String get handoverUnverifyButton => 'Unverify';

  @override
  String get handoverVerifyButton => 'Verify';

  @override
  String handoverSummaryLine(String date, String cash, String upi) {
    return '$date · $cash cash · $upi UPI';
  }

  @override
  String get handoverSelectAgentValidator => 'Select an agent';

  @override
  String get handoverCashAmountLabel => 'CASH AMOUNT';

  @override
  String get handoverUpiAmountLabel => 'UPI AMOUNT';

  @override
  String get handoverNotesLabel => 'NOTES';

  @override
  String get handoverNotesHint => 'Optional remarks';

  @override
  String get handoverDateLabel => 'DATE *';

  @override
  String get handoverRecordActionButton => 'Record';

  @override
  String get handoverSaveButton => 'Save';

  @override
  String get handoverCancelButton => 'Cancel';

  @override
  String get handoverRefreshButton => 'Refresh';

  @override
  String handoverStatToday(String amount) {
    return 'Today: $amount';
  }

  @override
  String get handoverStatPendingToHandOver => 'Pending to Hand Over';

  @override
  String get handoverStatCashCollected => 'Cash Collected';

  @override
  String get handoverStatOnlineUpi => 'Online / UPI';

  @override
  String handoverStillPendingBanner(String amount) {
    return 'You have $amount still to hand over. This balance carries forward — tomorrow\'s collections add on top of it until you settle.';
  }

  @override
  String get accountBookSubtitle =>
      'Track cash in hand and outstanding money lent';

  @override
  String get accountTabAllEntries => 'All Entries';

  @override
  String get accountTabCashInHand => 'Cash In Hand';

  @override
  String get accountTabOutstandingLent => 'Outstanding Lent';

  @override
  String get accountAddEntryButton => 'Add Entry';

  @override
  String get accountAddCashEntryButton => 'Add Cash Entry';

  @override
  String get accountAddMoneyLentButton => 'Add Money Lent';

  @override
  String get accountEntrySavedTitle => 'Entry Saved';

  @override
  String get accountEntrySavedMessage =>
      'The ledger entry has been added successfully.';

  @override
  String get accountEntryUpdatedTitle => 'Entry Updated';

  @override
  String get accountEntryUpdatedMessage =>
      'The ledger entry has been updated successfully.';

  @override
  String get accountEntryDeletedTitle => 'Entry Deleted';

  @override
  String get accountEntryDeletedMessage => 'The ledger entry has been removed.';

  @override
  String get accountDeleteFailedTitle => 'Delete Failed';

  @override
  String accountDeleteConfirmMessage(String title) {
    return 'Are you sure you want to delete \"$title\"? This action cannot be undone.';
  }

  @override
  String get accountNetBalanceSummaryTitle => 'Net Balance Summary';

  @override
  String get accountCashInHandLabel => 'Cash In Hand';

  @override
  String get accountOutstandingLabel => 'Outstanding Money Lent';

  @override
  String get accountNetBalanceLabel => 'Net Balance';

  @override
  String get accountUpdatingBadge => 'Updating...';

  @override
  String get accountLiveBadge => 'Live';

  @override
  String accountSummaryRefreshError(String error) {
    return 'Couldn\'t refresh summary: $error';
  }

  @override
  String get accountCashInHandSubtitle => 'Total liquid cash available';

  @override
  String get accountBreakdownLoanCollection => 'Loan Collections';

  @override
  String get accountBreakdownFundDeposits => 'Fund Deposits';

  @override
  String get accountBreakdownChitCollection => 'Chit Collections';

  @override
  String get accountBreakdownCustomCashNet => 'Custom Cash Entries';

  @override
  String get accountOutstandingMoneyTitle => 'Outstanding Money';

  @override
  String get accountOutstandingMoneySubtitle => 'Total money owed to you';

  @override
  String get accountBreakdownLoanOutstanding => 'Loan Outstanding';

  @override
  String get accountBreakdownChitPending => 'Chit Pending';

  @override
  String get accountBreakdownFundPending => 'Fund Pending';

  @override
  String get accountBreakdownCustomMoneyLent => 'Custom Money Lent';

  @override
  String get accountSearchHint => 'Search by title or category...';

  @override
  String get accountLoadFailedTitle => 'Failed to Load Entries';

  @override
  String get accountEmptyStateTitle => 'No Entries Yet';

  @override
  String get accountEmptyStateBody =>
      'Add your first cash or lending entry to start tracking your account book.';

  @override
  String get accountColDate => 'Date';

  @override
  String get accountColTitle => 'Title';

  @override
  String get accountColCategory => 'Category';

  @override
  String get accountColSection => 'Section';

  @override
  String get accountColType => 'Type';

  @override
  String get accountColAmount => 'Amount';

  @override
  String get accountColActions => 'Actions';

  @override
  String get accountMissingTitleTitle => 'Title Required';

  @override
  String get accountMissingTitleMessage =>
      'Please enter a title for this entry.';

  @override
  String get accountInvalidDateTitle => 'Invalid Date';

  @override
  String get accountInvalidDateMessage =>
      'Please enter a valid date in dd/mm/yyyy format.';

  @override
  String get accountUpdateFailedTitle => 'Update Failed';

  @override
  String get accountSaveFailedTitle => 'Save Failed';

  @override
  String get accountEditEntryTitle => 'Edit Entry';

  @override
  String get accountAddEntryTitle => 'Add Entry';

  @override
  String get accountEntryTitleLabel => 'Title';

  @override
  String get accountEntryTitleHint => 'e.g. Office rent, Cash deposit';

  @override
  String get accountEntryTypeLabel => 'Entry Type';

  @override
  String get accountAmountLabel => 'Amount';

  @override
  String get accountAmountHint => '0.00';

  @override
  String get accountCategoryLabel => 'Category';

  @override
  String get accountEntryDateLabel => 'Date';

  @override
  String get accountEntryDateHint => 'dd/mm/yyyy';

  @override
  String get accountNotesLabel => 'Notes';

  @override
  String get accountNotesHint => 'Optional notes about this entry';

  @override
  String get accountUpdateEntryButton => 'Update Entry';

  @override
  String get accountSaveEntryButton => 'Save Entry';

  @override
  String get overdueManagementTitle => 'Overdue Management';

  @override
  String get overdueSubtitle => 'Track and follow up on overdue loan accounts';

  @override
  String overdueCountBadge(int count) {
    return '$count overdue';
  }

  @override
  String get overdueStatTotalLabel => 'TOTAL OVERDUE';

  @override
  String get overdueStatTotalSub => 'accounts';

  @override
  String get overdueStatAmountLabel => 'OVERDUE AMOUNT';

  @override
  String get overdueStatAmountSub => 'outstanding';

  @override
  String get overdueStatAvgDaysLabel => 'AVG DAYS OVERDUE';

  @override
  String overdueStatAvgDaysValue(int days) {
    return '$days d';
  }

  @override
  String get overdueStatAvgDaysSub => 'across accounts';

  @override
  String get overdueStatCriticalLabel => 'CRITICAL (>30D)';

  @override
  String get overdueStatCriticalSub => 'needs attention';

  @override
  String get overdueSearchHint => 'Search customer or loan number...';

  @override
  String get overdueFilterAll => 'All overdue';

  @override
  String get overdueFilterCritical => 'Critical (>30d)';

  @override
  String get overdueNoMatchMessage => 'No overdue accounts match your search.';

  @override
  String get overdueNoPhoneTitle => 'No phone number';

  @override
  String get overdueNoPhoneMessage =>
      'This overdue account does not have a mobile number yet.';

  @override
  String get overdueSendMessageTitle => 'Send Message Reminder';

  @override
  String overdueSendMessageBody(String name, String phone) {
    return 'Open WhatsApp for $name?\n$phone';
  }

  @override
  String get overdueSendLabel => 'Send';

  @override
  String overdueWhatsappTemplate(
      String name, String loanNumber, int days, String amount) {
    return 'Hello $name, your loan $loanNumber is overdue by $days days. Please contact us to clear the pending amount of $amount.';
  }

  @override
  String get overdueWhatsappFailedTitle => 'Unable to open WhatsApp';

  @override
  String get overdueCallTitle => 'Call Customer';

  @override
  String overdueCallBody(String name, String phone) {
    return '$name\n$phone';
  }

  @override
  String get overdueCallLabel => 'Call';

  @override
  String get overdueCallFailedTitle => 'Unable to start call';

  @override
  String get overdueFollowUpAssignedTitle => 'Follow-up assigned';

  @override
  String get overdueGenericError => 'Something went wrong. Please try again.';

  @override
  String get overdueBadgeLabel => 'Overdue';

  @override
  String get overdueLoanNumberLabel => 'Loan No.';

  @override
  String get overdueDueAmountLabel => 'Due Amount';

  @override
  String get overdueDaysOverdueLabel => 'Days Overdue';

  @override
  String overdueDaysValue(int days) {
    return '$days days';
  }

  @override
  String get overdueStartedLabel => 'Started';

  @override
  String get overdueFollowUpSectionLabel => 'FOLLOW-UP';

  @override
  String overdueFollowUpDueLabel(String date) {
    return 'Due $date';
  }

  @override
  String get overdueActionMessage => 'Message';

  @override
  String get overdueActionCall => 'Call';

  @override
  String get overdueActionAssignFollowUp => 'Assign Follow-up';

  @override
  String get overdueAssignFollowUpTitle => 'Assign Follow-up';

  @override
  String get overdueFollowUpNoteHint =>
      'e.g. Called customer, promised to pay by Friday';

  @override
  String get overdueFieldRequired => 'Required';

  @override
  String get overdueFollowUpNoteFieldLabel => 'FOLLOW-UP NOTE';

  @override
  String get overdueFollowUpDateFieldLabel => 'FOLLOW-UP DATE';

  @override
  String overdueStartedValue(String date) {
    return 'Started: $date';
  }

  @override
  String overdueOutstandingValue(String amount) {
    return 'Outstanding: $amount';
  }

  @override
  String get save => 'Save';

  @override
  String get agentManagementTitle => 'Agent Management';

  @override
  String get agentManagementSubtitle =>
      'Add, edit, and manage your collection agents';

  @override
  String get agentAddButton => 'Add Agent';

  @override
  String get agentLoadFailedFallback => 'Failed to load agents.';

  @override
  String get agentStatTotal => 'Total Agents';

  @override
  String get agentStatActive => 'Active Agents';

  @override
  String get agentStatInactive => 'Inactive Agents';

  @override
  String get agentStatAddedThisMonth => 'Added This Month';

  @override
  String get agentSearchHint => 'Search by name or mobile...';

  @override
  String get agentRoleAgent => 'Agent';

  @override
  String get agentRoleAdmin => 'Admin';

  @override
  String get agentRoleManager => 'Manager';

  @override
  String get agentRoleAll => 'All';

  @override
  String get agentColUser => 'USER';

  @override
  String get agentColMobile => 'MOBILE';

  @override
  String get agentColRole => 'ROLE';

  @override
  String get agentColStatus => 'STATUS';

  @override
  String get agentColCreated => 'CREATED';

  @override
  String get agentColActions => 'ACTIONS';

  @override
  String get agentNoAgentsFound => 'No agents found.';

  @override
  String get agentEditTooltip => 'Edit';

  @override
  String get agentDeleteTooltip => 'Delete';

  @override
  String get agentCreatedTitle => 'Agent created';

  @override
  String agentCreatedMessage(String name) {
    return '$name has been added';
  }

  @override
  String get agentCreateFailedTitle => 'Could not create agent';

  @override
  String get agentUpdatedTitle => 'Agent updated';

  @override
  String agentUpdatedMessage(String name) {
    return '$name has been updated';
  }

  @override
  String get agentUpdateFailedTitle => 'Could not update agent';

  @override
  String get agentDeleteDialogTitle => 'Delete Agent';

  @override
  String agentDeleteConfirmMessage(String name) {
    return 'Are you sure you want to delete $name? They will be moved to the Recycle Bin and can be restored later.';
  }

  @override
  String get agentDeleteConfirmLabel => 'Delete Agent';

  @override
  String get agentDeletedTitle => 'Agent deleted';

  @override
  String agentDeletedMessage(String name) {
    return '$name has been removed';
  }

  @override
  String get agentDeleteFailedTitle => 'Could not delete agent';

  @override
  String get agentPhotoUploadFailedTitle => 'Photo upload failed';

  @override
  String get agentMissingInfoTitle => 'Missing information';

  @override
  String get agentMissingInfoMessage => 'Please fill all required fields';

  @override
  String get agentFormEditTitle => 'Edit User';

  @override
  String get agentFormAddTitle => 'Add User';

  @override
  String get agentFormCredentialsNotice =>
      'Set an email and password so this user can sign in to the app.';

  @override
  String get agentFieldFullName => 'FULL NAME *';

  @override
  String get agentFieldFullNameHint => 'e.g. Priya Sharma';

  @override
  String get agentFieldMobile => 'MOBILE';

  @override
  String get agentFieldMobileHint => 'e.g. +91 98765 43210';

  @override
  String get agentFieldEmail => 'EMAIL *';

  @override
  String get agentFieldEmailHint => 'user@rrgroups.in';

  @override
  String get agentFieldPassword => 'PASSWORD *';

  @override
  String get agentFieldPasswordHint => 'Min. 6 characters';

  @override
  String get agentFieldRole => 'ROLE';

  @override
  String get agentFieldStatus => 'STATUS';

  @override
  String get agentFieldAddress => 'ADDRESS';

  @override
  String get agentFieldAddressHint => 'Residential address';

  @override
  String get agentFieldAadhaar => 'AADHAAR';

  @override
  String get agentFieldAadhaarHint => '[Aadhaar Redacted]';

  @override
  String get agentFieldPan => 'PAN';

  @override
  String get agentFieldPanHint => 'ABCDE1234F';

  @override
  String get agentFieldOccupation => 'OCCUPATION';

  @override
  String get agentFieldOccupationHint => 'e.g. Field Executive';

  @override
  String get agentFieldProfilePhoto => 'PROFILE PHOTO';

  @override
  String get agentUploadPhotoButton => 'Upload Photo';

  @override
  String get agentSaveChangesButton => 'Save Changes';

  @override
  String get agentCreateUserButton => 'Create User';

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get fundsScreenTitle => 'Funds';

  @override
  String get fundsScreenSubtitle =>
      'Weekly-deposit savings schemes with a maturity bonus';

  @override
  String get fundCreateButton => 'Create Fund';

  @override
  String get fundSearchHint => 'Search by customer name';

  @override
  String get fundSearchClearTooltip => 'Clear search';

  @override
  String get fundRetryButton => 'Retry';

  @override
  String get fundStatTotalFunds => 'Total Funds';

  @override
  String get fundStatActive => 'Active';

  @override
  String get fundStatMaturityPayout => 'Maturity Payout';

  @override
  String get fundStatCollected => 'Collected';

  @override
  String get fundEmptySearch => 'No funds match your search.';

  @override
  String get fundEmptyCustomer => 'You have no funds yet.';

  @override
  String get fundEmptyDefault => 'No funds yet.';

  @override
  String get fundCardWeekly => 'WEEKLY';

  @override
  String get fundCardWeeks => 'WEEKS';

  @override
  String get fundCardBonus => 'BONUS';

  @override
  String get fundCardMaturityPayout => 'Maturity payout';

  @override
  String fundCardDepositedProgress(String deposited, String total) {
    return 'Deposited $deposited / $total';
  }

  @override
  String get fundCardPassbookButton => 'Passbook';

  @override
  String get fundCardCollectButton => 'Collect';

  @override
  String fundCardSettleBanner(String amount) {
    return 'Settle in full · $amount left';
  }

  @override
  String get fundDeleteDialogTitle => 'Delete Fund';

  @override
  String fundDeleteDialogMessage(String code, String customerName) {
    return 'Are you sure you want to delete \"$code\" for $customerName? It will be moved to the Recycle Bin and can be restored later.';
  }

  @override
  String get fundDeleteDialogConfirm => 'Delete';

  @override
  String get fundAgentSettleDialogTitle => 'Settle Fund in Full';

  @override
  String fundAgentSettleDialogMessage(
      String amount, String code, String customerName) {
    return 'Collect the remaining $amount for \"$code\" ($customerName) now and mark it matured?';
  }

  @override
  String get fundAgentSettleDialogConfirm => 'Settle Now';

  @override
  String get fundToastLoadFailedTitle => 'Failed to load funds';

  @override
  String get fundToastCreatedTitle => 'Fund created';

  @override
  String get fundToastCreateFailedTitle => 'Create failed';

  @override
  String get fundToastUpdatedTitle => 'Fund updated';

  @override
  String get fundToastUpdateFailedTitle => 'Update failed';

  @override
  String get fundToastSettledTitle => 'Fund settled';

  @override
  String get fundToastSettlementFailedTitle => 'Settlement failed';

  @override
  String get fundToastCollectionRecordedTitle => 'Collection recorded';

  @override
  String get fundToastDeletedTitle => 'Fund deleted';

  @override
  String get fundToastDeleteFailedTitle => 'Delete failed';

  @override
  String get fundToastSelectCustomerTitle => 'Select a customer';

  @override
  String get fundToastSelectCustomerMessage => 'Please choose a customer';

  @override
  String get fundFormTitleEdit => 'Edit Fund';

  @override
  String get fundFormTitleAdd => 'Add Fund';

  @override
  String get fundFormFieldCustomer => 'CUSTOMER';

  @override
  String get fundFormFieldCustomerHint => 'Select a customer...';

  @override
  String get fundFormFieldCustomerFallback => 'Unknown';

  @override
  String get fundFormFieldAgent => 'ASSIGNED AGENT (OPTIONAL)';

  @override
  String get fundFormFieldAgentHint => 'Select an agent...';

  @override
  String get fundFormFieldAgentFallback => 'Unknown agent';

  @override
  String get fundFormFieldUnits => 'FUND UNITS (QUANTITY)';

  @override
  String get fundFormFieldWeeklyAmount => 'WEEKLY AMOUNT';

  @override
  String get fundFormFieldWeeks => 'NUMBER OF WEEKS';

  @override
  String get fundFormFieldBonus => 'MATURITY BONUS';

  @override
  String get fundFormFieldStartDate => 'START DATE';

  @override
  String get fundFormValidatorRequired => 'Required';

  @override
  String fundFormSummaryDeposited(String weekly, String weeks) {
    return 'Deposited (₹$weekly x $weeks weeks)';
  }

  @override
  String get fundFormSummaryBonus => 'Maturity bonus';

  @override
  String fundFormSummaryBonusValue(String amount) {
    return '+ $amount';
  }

  @override
  String get fundFormSummaryTotalPayout => 'Total maturity payout';

  @override
  String fundFormMaturesOn(String date) {
    return 'Matures on $date';
  }

  @override
  String get fundFormCancelButton => 'Cancel';

  @override
  String get fundFormSaveButton => 'Save Changes';

  @override
  String get fundFormCreateButton => 'Create Fund';

  @override
  String get fundCollectDialogInvalidAmountTitle => 'Invalid amount';

  @override
  String get fundCollectDialogInvalidAmountMessage =>
      'Enter a collection amount greater than 0';

  @override
  String get fundCollectDialogNotSavedTitle => 'Collection not saved';

  @override
  String fundCollectDialogNotSavedMessage(String remaining) {
    return 'Only $remaining left to fully fund this deposit.';
  }

  @override
  String get fundCollectDialogFailedTitle => 'Collection failed';

  @override
  String get fundCollectDialogTitle => 'Record Collection';

  @override
  String fundCollectDialogSubtitle(String code, String customerName) {
    return '$code · $customerName';
  }

  @override
  String get fundCollectDialogCollectedLabel => 'COLLECTED';

  @override
  String get fundCollectDialogRemainingLabel => 'REMAINING';

  @override
  String get fundCollectDialogAmountLabel => 'COLLECTION AMOUNT';

  @override
  String get fundCollectDialogPaymentMethodLabel => 'PAYMENT METHOD';

  @override
  String get fundCollectDialogPaymentDateLabel => 'PAYMENT DATE';

  @override
  String get fundCollectDialogHelperText =>
      'Adds this amount to the fund\'s collected total. Auto-marks the fund matured once the full deposit target is collected.';

  @override
  String get fundCollectDialogRecordButton => 'Record';

  @override
  String get fundSettleDialogTitle => 'Fund Closure & Settlement';

  @override
  String fundSettleDialogSubtitle(
      String code, String customerName, String units) {
    return '$code · $customerName ($units Active Units)';
  }

  @override
  String get fundSettleTabPartial => 'Partial Unit Closure';

  @override
  String get fundSettleTabFull => 'Settle Full Account';

  @override
  String get fundSettleUnitsToCloseLabel => 'NUMBER OF UNITS TO CLOSE';

  @override
  String get fundSettleHalfUnitButton => '0.5 Units';

  @override
  String get fundSettleOneUnitButton => '1 Unit';

  @override
  String get fundSettleClosedPayoutLabel => 'Closed Units Payout';

  @override
  String get fundSettleClosedPayoutSubtitle => 'Accrued Deposit + Bonus';

  @override
  String get fundSettleRemainingBalanceLabel => 'Remaining Active Balance';

  @override
  String fundSettleRemainingUnitsValue(String units) {
    return '$units Units left';
  }

  @override
  String fundSettleNewWeeklyValue(String amount) {
    return 'New Weekly: $amount / week';
  }

  @override
  String get fundSettleTotalDepositedLabel => 'TOTAL DEPOSITED';

  @override
  String get fundSettleRemainingTargetLabel => 'REMAINING TARGET';

  @override
  String get fundSettlePaymentMethodLabel => 'PAYMENT METHOD';

  @override
  String get fundSettleSettlementDateLabel => 'SETTLEMENT DATE';

  @override
  String get fundSettleSummaryClosingTarget => 'Closing units deposit target';

  @override
  String fundSettleSummaryClosingTargetValue(
      String amount, String units, String maxUnits) {
    return '$amount ($units of $maxUnits Units)';
  }

  @override
  String get fundSettleSummaryTotalDeposit => 'Total deposit';

  @override
  String get fundSettleSummaryProportionalBonus => '🎁 Proportional Bonus';

  @override
  String get fundSettleSummaryNetClosurePayout => 'Net Closure Payout Amount';

  @override
  String get fundSettleSummaryPayoutToCustomer => 'Payout to customer';

  @override
  String get fundSettleFailedTitle => 'Closure failed';

  @override
  String get fundSettleCancelButton => 'Cancel';

  @override
  String get fundSettleConfirmPartialButton => 'Confirm Partial Closure';

  @override
  String get fundSettleConfirmFullButton => 'Settle Full Account';

  @override
  String get fundPassbookTitle => 'Passbook';

  @override
  String fundPassbookSubtitle(String code, String customerName) {
    return '$code · $customerName';
  }

  @override
  String get fundPassbookDepositedLabel => 'DEPOSITED';

  @override
  String get fundPassbookToDepositLabel => 'TO DEPOSIT';

  @override
  String get fundPassbookEntriesLabel => 'ENTRIES';

  @override
  String fundPassbookEntriesValue(String paid, String total) {
    return '$paid / $total';
  }

  @override
  String fundPassbookSummaryTotalDeposit(String weekly, String weeks) {
    return 'Total deposit (₹$weekly x $weeks weeks)';
  }

  @override
  String get fundPassbookSummaryBonus => '🎁 Maturity bonus (at settlement)';

  @override
  String get fundPassbookSummaryPayout => 'Maturity payout';

  @override
  String get fundPassbookNextDuePrefix => 'Next deposit due · ';

  @override
  String fundPassbookNextDueValue(String date, String week, String amount) {
    return '$date · Week $week · $amount';
  }

  @override
  String get fundPassbookColWeek => 'WK';

  @override
  String get fundPassbookColDateMethod => 'DATE · METHOD';

  @override
  String get fundPassbookColAmountBalance => 'AMOUNT · BALANCE';

  @override
  String get fundPassbookNextDueRowLabel => 'Next due';

  @override
  String get fundPassbookPaidFallback => 'Paid';

  @override
  String get fundPassbookPendingLabel => 'Pending';

  @override
  String fundPassbookBalanceValue(String balance) {
    return 'Bal $balance';
  }

  @override
  String get fundPassbookCloseButton => 'Close';

  @override
  String get routeMapTitle => 'Customer Map';

  @override
  String get routeMapAllLocationsSubtitle => 'All customer locations';

  @override
  String get routeMapSearchHint => 'Search customer, loan or agent...';

  @override
  String get routeMapCustomerLabel => 'Customer';

  @override
  String get routeMapAllCustomers => 'All customers';

  @override
  String get routeMapTotalMapped => 'Total Mapped';

  @override
  String get routeMapActiveCustomers => 'Active Customers';

  @override
  String get routeMapNoLocationsTitle => 'No locations found';

  @override
  String get routeMapNoLocationsMessage =>
      'Customers with valid coordinates will appear here.';

  @override
  String get routeMapActive => 'Active';

  @override
  String get routeMapInactive => 'Inactive';

  @override
  String get routeMapRetryButton => 'Retry';

  @override
  String get routeMapLoadFailedTitle => 'Failed to load map data';

  @override
  String routeMapJoinedLabel(String date) {
    return 'Joined: $date';
  }

  @override
  String get reportsScreenTitle => 'Reports & Analytics';

  @override
  String get reportsSubtitle => 'Daily, monthly and agent performance insights';

  @override
  String get reportsExportPdfButton => 'Export PDF';

  @override
  String get reportsExportExcelButton => 'Export Excel';

  @override
  String get reportsExportingExcelTitle => 'Exporting Excel';

  @override
  String get reportsExportingExcelMessage => 'Compiling spreadsheet cells...';

  @override
  String get reportsExportCompleteTitle => 'Export Complete';

  @override
  String get reportsExportCompleteMessage =>
      'Excel sheet generated successfully.';

  @override
  String get reportsExportFailedTitle => 'Export Failed';

  @override
  String reportsExportFailedMessage(String error) {
    return 'Could not generate spreadsheet. Technical reason: $error';
  }

  @override
  String get reportsDailyHint =>
      'Daily report shows data for the end date above.';

  @override
  String get reportsRetryButton => 'Retry';

  @override
  String get reportsGenericErrorMessage =>
      'Something went wrong while loading the report.';

  @override
  String get reportsTabDaily => 'Daily\nReport';

  @override
  String get reportsTabMonthly => 'Monthly\nReport';

  @override
  String get reportsTabAgent => 'Agent\nPerformance';

  @override
  String get reportsTodaysCollectionsTitle => 'Today\'s Collections';

  @override
  String get reportsNoCollectionsTodayTitle => 'No collections today';

  @override
  String get reportsNoCollectionsTodayMessage =>
      'Collections made today will appear here.';

  @override
  String get reportsNewLoansTodayTitle => 'New Loans Created Today';

  @override
  String get reportsNoNewLoansTodayTitle => 'No new loans today';

  @override
  String get reportsNoNewLoansTodayMessage =>
      'Loans created today will appear here.';

  @override
  String get reportsMetricDisbursement => 'LOAN DISBURSEMENT';

  @override
  String get reportsMetricInterest => 'INTEREST EARNED';

  @override
  String get reportsMetricCollectionTotal => 'COLLECTION TOTAL';

  @override
  String get reportsMetricNewCustomers => 'NEW CUSTOMERS';

  @override
  String get reportsCollectionsTrendTitle => 'Collections Trend';

  @override
  String reportsLastNMonths(int count) {
    return 'Last $count months';
  }

  @override
  String get reportsLoanDisbursementTitle => 'Loan Disbursement';

  @override
  String get reportsByMonth => 'By month';

  @override
  String get reportsAgentPerformanceTitle => 'Agent Performance';

  @override
  String get reportsNoAgentDataTitle => 'No agent data';

  @override
  String get reportsNoAgentDataMessage =>
      'Agent performance will appear here once agents are active.';

  @override
  String get reportsColumnAgent => 'AGENT';

  @override
  String get reportsColumnAssigned => 'ASSIGNED';

  @override
  String get reportsColumnCollected => 'COLLECTED';

  @override
  String get reportsColumnEfficiency => 'EFFICIENCY';

  @override
  String get reportsCollectionsByAgentTitle => 'Collections by Agent';

  @override
  String get reportsTotalAmountCollected => 'Total amount collected';

  @override
  String get reportsNoData => 'No data';

  @override
  String get notificationsScreenTitle => 'Notifications';

  @override
  String get notificationsSubtitle =>
      'Stay on top of dues, approvals, and reminders';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get send => 'Send';

  @override
  String get statTotal => 'TOTAL';

  @override
  String get statUnread => 'UNREAD';

  @override
  String get statOverdue => 'OVERDUE';

  @override
  String get filterAll => 'All';

  @override
  String get filterUnread => 'Unread';

  @override
  String get filterEmiDue => 'EMI Due';

  @override
  String get filterOverdue => 'Overdue';

  @override
  String get filterApprovals => 'Approvals';

  @override
  String get filterReminders => 'Reminders';

  @override
  String get noNotificationsHere => 'No notifications here.';

  @override
  String get failedToLoadNotifications => 'Failed to load notifications';

  @override
  String get couldNotLoadNotificationsToastTitle =>
      'Could not load notifications';

  @override
  String get allNotificationsClearedToastTitle => 'All notifications cleared';

  @override
  String get allNotificationsClearedToastMessage =>
      'Everything has been marked as read.';

  @override
  String get failedToUpdateToastTitle => 'Failed to update';

  @override
  String get deleteNotificationTitle => 'Delete Notification';

  @override
  String deleteNotificationMessage(String title) {
    return 'Are you sure you want to delete \"$title\"? It will be moved to the Recycle Bin and can be restored later.';
  }

  @override
  String get notificationRemovedToastTitle => 'Notification removed';

  @override
  String get failedToDeleteToastTitle => 'Failed to delete';

  @override
  String get markedAsReadToastTitle => 'Marked as read';

  @override
  String get failedToMarkAsReadToastTitle => 'Failed to mark as read';

  @override
  String userIdLabel(String id) {
    return 'user_id: $id';
  }

  @override
  String get sendNotificationTitle => 'Send Notification';

  @override
  String get sendNotificationSubtitle => 'Notify your customers instantly';

  @override
  String get recipientsLabel => 'RECIPIENTS';

  @override
  String get allCustomers => 'All Customers';

  @override
  String get selectLabel => 'Select';

  @override
  String get searchCustomersHint => 'Search customers...';

  @override
  String get noCustomersFoundInList => 'No customers found.';

  @override
  String get noPortalLogin => 'No portal login';

  @override
  String get typeLabel => 'TYPE';

  @override
  String get typeInfo => 'Info';

  @override
  String get typeReminder => 'Reminder';

  @override
  String get typeEmiDue => 'EMI Due';

  @override
  String get typeOverdue => 'Overdue';

  @override
  String get typeApproval => 'Approval';

  @override
  String get titleFieldLabel => 'TITLE';

  @override
  String get titleFieldHint => 'e.g. EMI due tomorrow';

  @override
  String get messageFieldLabel => 'MESSAGE';

  @override
  String get messageFieldHint => 'Write your message...';

  @override
  String get noRecipientsSelected => 'No recipients selected';

  @override
  String recipientsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipients selected',
      one: '1 recipient selected',
    );
    return '$_temp0';
  }

  @override
  String get titleRequiredError => 'Title required';

  @override
  String get noCustomersFoundError => 'No customers found';

  @override
  String get noLinkedCustomerLoginsFoundError =>
      'No linked customer logins found';

  @override
  String get selectAtLeastOneRecipientError => 'Select at least one recipient';

  @override
  String get noEligibleRecipientsToastTitle => 'No eligible recipients';

  @override
  String get noEligibleRecipientsToastMessage =>
      'Selected customers need a portal login to receive notifications.';

  @override
  String get notificationSentToastTitle => 'Notification sent';

  @override
  String recipientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipients',
      one: '1 recipient',
    );
    return '$_temp0';
  }

  @override
  String get sendFailedToastTitle => 'Send failed';

  @override
  String get couldNotLoadCustomersToastTitle => 'Could not load customers';

  @override
  String get userManagementScreenTitle => 'User Management';

  @override
  String get userManagementSubtitle =>
      'Manage roles, access, and permissions across your organization';

  @override
  String get addUser => 'Add User';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get edit => 'Edit';

  @override
  String get statTotalUsers => 'Total Users';

  @override
  String get statActive => 'Active';

  @override
  String get statAgents => 'Agents';

  @override
  String get statAdmins => 'Admins';

  @override
  String get searchByNameOrMobileHint => 'Search by name or mobile...';

  @override
  String get roleAll => 'All Roles';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleCollectionAgent => 'Collection Agent';

  @override
  String get roleCustomer => 'Customer';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get tableColumnUser => 'USER';

  @override
  String get tableColumnMobile => 'MOBILE';

  @override
  String get tableColumnRole => 'ROLE';

  @override
  String get tableColumnStatus => 'STATUS';

  @override
  String get adminCannotBeEditedTooltip => 'Admin accounts cannot be edited';

  @override
  String get adminCannotBeDeletedTooltip => 'Admin accounts cannot be deleted';

  @override
  String get removeUserDialogTitle => 'Remove user?';

  @override
  String removeUserDialogMessage(String name) {
    return '$name will be moved to the Recycle Bin and can be restored later.';
  }

  @override
  String get remove => 'Remove';

  @override
  String get userCreatedToastTitle => 'User created';

  @override
  String userCreatedToastMessage(String name) {
    return '$name was added successfully';
  }

  @override
  String get couldNotCreateUserToastTitle => 'Could not create user';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get userUpdatedToastTitle => 'User updated';

  @override
  String userUpdatedToastMessage(String name) {
    return '$name was saved';
  }

  @override
  String get couldNotUpdateUserToastTitle => 'Could not update user';

  @override
  String get userRemovedToastTitle => 'User removed';

  @override
  String userRemovedToastMessage(String name) {
    return '$name was deleted';
  }

  @override
  String get couldNotDeleteUserToastTitle => 'Could not delete user';

  @override
  String get failedToLoadUsers => 'Failed to load users';

  @override
  String get dismissAddUserDialogLabel => 'Dismiss Add User Dialog';

  @override
  String get dismissEditUserDialogLabel => 'Dismiss Edit User Dialog';

  @override
  String get editUserDialogTitle => 'Edit User';

  @override
  String get editPasswordHintNote =>
      'Leave password blank to keep the current password unchanged.';

  @override
  String get addUserBackendNote =>
      'This creates a login account directly on the backend. The user can sign in immediately with the email and password below.';

  @override
  String get fullNameRequiredError => 'Full name is required';

  @override
  String get validEmailRequiredError => 'A valid email is required';

  @override
  String get passwordMinLengthError => 'Password must be at least 6 characters';

  @override
  String get fullNameFieldLabel => 'FULL NAME *';

  @override
  String get fullNameFieldHint => 'e.g. Priya Sharma';

  @override
  String get emailFieldLabel => 'EMAIL *';

  @override
  String get emailFieldHint => 'e.g. priya@example.com';

  @override
  String get newPasswordOptionalLabel => 'NEW PASSWORD (OPTIONAL)';

  @override
  String get passwordFieldLabel => 'PASSWORD *';

  @override
  String get passwordLeaveBlankHint => 'Leave blank to keep unchanged';

  @override
  String get passwordMinCharsHint => 'Min 6 characters';

  @override
  String get mobileFieldLabel => 'MOBILE';

  @override
  String get mobileFieldHint => 'e.g. +91 98765 43210';

  @override
  String get roleFieldLabel => 'ROLE';

  @override
  String get statusFieldLabel => 'STATUS';

  @override
  String get avatarUrlFieldLabel => 'AVATAR URL';

  @override
  String get avatarUrlFieldHint => 'https://...';

  @override
  String get avatarUrlHelperText => 'Optional profile image link';

  @override
  String get saveChanges => 'Save Changes';

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
