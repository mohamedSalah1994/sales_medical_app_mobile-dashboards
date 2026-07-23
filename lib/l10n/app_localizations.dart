import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ar'),
    Locale('en'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'DKT Sales APP'**
  String get appTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account to continue'**
  String get signInToContinue;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @roleId.
  ///
  /// In en, this message translates to:
  /// **'Role ID'**
  String get roleId;

  /// No description provided for @supervisorId.
  ///
  /// In en, this message translates to:
  /// **'Supervisor ID (Optional)'**
  String get supervisorId;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'Guest mode'**
  String get guestMode;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @contactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Contact Admin'**
  String get contactAdmin;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @createUser.
  ///
  /// In en, this message translates to:
  /// **'Create User'**
  String get createUser;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @targets.
  ///
  /// In en, this message translates to:
  /// **'Targets'**
  String get targets;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @createNewUser.
  ///
  /// In en, this message translates to:
  /// **'Create New User'**
  String get createNewUser;

  /// No description provided for @fillDetailsToCreateUser.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details to create a new user account'**
  String get fillDetailsToCreateUser;

  /// No description provided for @createUserButton.
  ///
  /// In en, this message translates to:
  /// **'Create User'**
  String get createUserButton;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @signedInSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully!'**
  String get signedInSuccessfully;

  /// No description provided for @userCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User created successfully!'**
  String get userCreatedSuccessfully;

  /// No description provided for @enterUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get enterUsername;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get enterFullName;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'user@example.com'**
  String get enterEmail;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhone;

  /// No description provided for @enterRoleId.
  ///
  /// In en, this message translates to:
  /// **'Enter role ID (UUID)'**
  String get enterRoleId;

  /// No description provided for @enterSupervisorId.
  ///
  /// In en, this message translates to:
  /// **'Enter supervisor ID (UUID)'**
  String get enterSupervisorId;

  /// No description provided for @supervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get supervisor;

  /// No description provided for @selectSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Select supervisor'**
  String get selectSupervisor;

  /// No description provided for @subRoles.
  ///
  /// In en, this message translates to:
  /// **'Sub Roles'**
  String get subRoles;

  /// No description provided for @selectSubRoles.
  ///
  /// In en, this message translates to:
  /// **'Select sub roles'**
  String get selectSubRoles;

  /// No description provided for @sapSalesEmployeeCode.
  ///
  /// In en, this message translates to:
  /// **'SAP Sales Employee'**
  String get sapSalesEmployeeCode;

  /// No description provided for @selectSapSalesEmployee.
  ///
  /// In en, this message translates to:
  /// **'Select SAP Sales Employee'**
  String get selectSapSalesEmployee;

  /// No description provided for @searchEmployee.
  ///
  /// In en, this message translates to:
  /// **'Search employee by name or code'**
  String get searchEmployee;

  /// No description provided for @noEmployeesFound.
  ///
  /// In en, this message translates to:
  /// **'No employees found'**
  String get noEmployeesFound;

  /// No description provided for @territoryId.
  ///
  /// In en, this message translates to:
  /// **'Territory ID (Optional)'**
  String get territoryId;

  /// No description provided for @enterTerritoryId.
  ///
  /// In en, this message translates to:
  /// **'Enter territory ID (UUID)'**
  String get enterTerritoryId;

  /// No description provided for @selectTerritory.
  ///
  /// In en, this message translates to:
  /// **'Select Territory'**
  String get selectTerritory;

  /// No description provided for @selectSubTerritory.
  ///
  /// In en, this message translates to:
  /// **'Select Sub-Territory'**
  String get selectSubTerritory;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit app?'**
  String get exitApp;

  /// No description provided for @exitAppConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit?'**
  String get exitAppConfirmation;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @journeyPlans.
  ///
  /// In en, this message translates to:
  /// **'Journey Plans'**
  String get journeyPlans;

  /// No description provided for @journeyPlan.
  ///
  /// In en, this message translates to:
  /// **'Journey Plan'**
  String get journeyPlan;

  /// No description provided for @createJourneyPlan.
  ///
  /// In en, this message translates to:
  /// **'Create Journey Plan'**
  String get createJourneyPlan;

  /// No description provided for @createJourneyPlanFor.
  ///
  /// In en, this message translates to:
  /// **'Create Journey Plan For'**
  String get createJourneyPlanFor;

  /// No description provided for @totalJourneys.
  ///
  /// In en, this message translates to:
  /// **'Total Journeys'**
  String get totalJourneys;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @totalStops.
  ///
  /// In en, this message translates to:
  /// **'Total Visits'**
  String get totalStops;

  /// No description provided for @totalTargets.
  ///
  /// In en, this message translates to:
  /// **'Total Targets'**
  String get totalTargets;

  /// No description provided for @avgProgress.
  ///
  /// In en, this message translates to:
  /// **'Avg Progress'**
  String get avgProgress;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @createJourney.
  ///
  /// In en, this message translates to:
  /// **'Create Journey'**
  String get createJourney;

  /// No description provided for @viewTargets.
  ///
  /// In en, this message translates to:
  /// **'View Targets'**
  String get viewTargets;

  /// No description provided for @standaloneVisit.
  ///
  /// In en, this message translates to:
  /// **'Standalone Visit'**
  String get standaloneVisit;

  /// No description provided for @standaloneVisits.
  ///
  /// In en, this message translates to:
  /// **'Standalone Visits'**
  String get standaloneVisits;

  /// No description provided for @createStandaloneVisit.
  ///
  /// In en, this message translates to:
  /// **'Create Visit'**
  String get createStandaloneVisit;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @salesOrder.
  ///
  /// In en, this message translates to:
  /// **'Sales Order'**
  String get salesOrder;

  /// No description provided for @salesOrders.
  ///
  /// In en, this message translates to:
  /// **'Sales Orders'**
  String get salesOrders;

  /// No description provided for @deliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveries;

  /// No description provided for @noDeliveries.
  ///
  /// In en, this message translates to:
  /// **'No deliveries found.'**
  String get noDeliveries;

  /// No description provided for @returns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get returns;

  /// No description provided for @noReturns.
  ///
  /// In en, this message translates to:
  /// **'No returns found.'**
  String get noReturns;

  /// No description provided for @welcomeBackUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String welcomeBackUser(String name);

  /// No description provided for @heresYourOverview.
  ///
  /// In en, this message translates to:
  /// **'Here\'s your overview'**
  String get heresYourOverview;

  /// No description provided for @forMyself.
  ///
  /// In en, this message translates to:
  /// **'For Myself'**
  String get forMyself;

  /// No description provided for @forAnotherUser.
  ///
  /// In en, this message translates to:
  /// **'For Another User'**
  String get forAnotherUser;

  /// No description provided for @selectUser.
  ///
  /// In en, this message translates to:
  /// **'Select User'**
  String get selectUser;

  /// No description provided for @selectUserHint.
  ///
  /// In en, this message translates to:
  /// **'Select user...'**
  String get selectUserHint;

  /// No description provided for @noUsersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No users available'**
  String get noUsersAvailable;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptional;

  /// No description provided for @enterAdditionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Enter any additional notes...'**
  String get enterAdditionalNotes;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @quarter.
  ///
  /// In en, this message translates to:
  /// **'Quarter'**
  String get quarter;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @createPlan.
  ///
  /// In en, this message translates to:
  /// **'Create Plan'**
  String get createPlan;

  /// No description provided for @addStops.
  ///
  /// In en, this message translates to:
  /// **'Add Visits'**
  String get addStops;

  /// No description provided for @plannedDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Planned Date & Time'**
  String get plannedDateAndTime;

  /// No description provided for @plannedTime.
  ///
  /// In en, this message translates to:
  /// **'Planned Time'**
  String get plannedTime;

  /// No description provided for @estimatedDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'Estimated Duration (minutes)'**
  String get estimatedDurationMinutes;

  /// No description provided for @enterDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'Enter duration in minutes'**
  String get enterDurationMinutes;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @coach.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get coach;

  /// No description provided for @double.
  ///
  /// In en, this message translates to:
  /// **'Double'**
  String get double;

  /// No description provided for @visitType.
  ///
  /// In en, this message translates to:
  /// **'Visit Type'**
  String get visitType;

  /// No description provided for @selectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select Customer'**
  String get selectCustomer;

  /// No description provided for @searchCustomers.
  ///
  /// In en, this message translates to:
  /// **'Search customers by name or code...'**
  String get searchCustomers;

  /// No description provided for @addToList.
  ///
  /// In en, this message translates to:
  /// **'Add to List'**
  String get addToList;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveAllStops.
  ///
  /// In en, this message translates to:
  /// **'Save All Visits'**
  String get saveAllStops;

  /// No description provided for @saveAndReturn.
  ///
  /// In en, this message translates to:
  /// **'Back to Plan'**
  String get saveAndReturn;

  /// No description provided for @pendingStops.
  ///
  /// In en, this message translates to:
  /// **'Pending Visits'**
  String get pendingStops;

  /// No description provided for @existingStops.
  ///
  /// In en, this message translates to:
  /// **'Existing Visits'**
  String get existingStops;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @allUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get allUsers;

  /// No description provided for @allPeriods.
  ///
  /// In en, this message translates to:
  /// **'All Periods'**
  String get allPeriods;

  /// No description provided for @selectPeriodType.
  ///
  /// In en, this message translates to:
  /// **'Select period type...'**
  String get selectPeriodType;

  /// No description provided for @myJourneys.
  ///
  /// In en, this message translates to:
  /// **'My Journeys'**
  String get myJourneys;

  /// No description provided for @myVisits.
  ///
  /// In en, this message translates to:
  /// **'My Visits'**
  String get myVisits;

  /// No description provided for @assignedJourneys.
  ///
  /// In en, this message translates to:
  /// **'Assigned Journeys'**
  String get assignedJourneys;

  /// No description provided for @myJourneyPlans.
  ///
  /// In en, this message translates to:
  /// **'My Journey Plans'**
  String get myJourneyPlans;

  /// No description provided for @journeyPlansList.
  ///
  /// In en, this message translates to:
  /// **'Journey Plans List'**
  String get journeyPlansList;

  /// No description provided for @myTargets.
  ///
  /// In en, this message translates to:
  /// **'My Targets'**
  String get myTargets;

  /// No description provided for @targetsList.
  ///
  /// In en, this message translates to:
  /// **'Targets List'**
  String get targetsList;

  /// No description provided for @pleaseSelectUser.
  ///
  /// In en, this message translates to:
  /// **'Please select a user'**
  String get pleaseSelectUser;

  /// No description provided for @deleteJourneyPlan.
  ///
  /// In en, this message translates to:
  /// **'Delete Journey Plan'**
  String get deleteJourneyPlan;

  /// No description provided for @deleteJourneyPlanConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this journey plan?'**
  String get deleteJourneyPlanConfirmation;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @targetDetails.
  ///
  /// In en, this message translates to:
  /// **'Target Details'**
  String get targetDetails;

  /// No description provided for @breakdowns.
  ///
  /// In en, this message translates to:
  /// **'Breakdowns'**
  String get breakdowns;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @achieved.
  ///
  /// In en, this message translates to:
  /// **'Achieved'**
  String get achieved;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @noDetailsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No details available'**
  String get noDetailsAvailable;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @pleaseSelectStartAndEndDates.
  ///
  /// In en, this message translates to:
  /// **'Please select start and end dates'**
  String get pleaseSelectStartAndEndDates;

  /// No description provided for @pleaseCreateJourneyPlanFirst.
  ///
  /// In en, this message translates to:
  /// **'Please create a journey plan first'**
  String get pleaseCreateJourneyPlanFirst;

  /// No description provided for @pleaseSelectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Please select a customer'**
  String get pleaseSelectCustomer;

  /// No description provided for @tapToSelectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Tap to select customer'**
  String get tapToSelectCustomer;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get stop;

  /// No description provided for @visitsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 Visit} other{{count} Visits}}'**
  String visitsCount(int count);

  /// No description provided for @visitOrderBadge.
  ///
  /// In en, this message translates to:
  /// **'Visit {order}'**
  String visitOrderBadge(int order);

  /// No description provided for @journeyPlanAddVisitTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Visit'**
  String get journeyPlanAddVisitTitle;

  /// No description provided for @journeyPlanCreateFirstBeforeVisits.
  ///
  /// In en, this message translates to:
  /// **'Please create a journey plan in Step 1 before adding visits.'**
  String get journeyPlanCreateFirstBeforeVisits;

  /// No description provided for @journeyPlanStep2SubtitleExisting.
  ///
  /// In en, this message translates to:
  /// **'View existing visits and add new ones to your journey plan'**
  String get journeyPlanStep2SubtitleExisting;

  /// No description provided for @journeyPlanStep2SubtitleNew.
  ///
  /// In en, this message translates to:
  /// **'Create a visit for your journey plan'**
  String get journeyPlanStep2SubtitleNew;

  /// No description provided for @addNewVisit.
  ///
  /// In en, this message translates to:
  /// **'Add New Visit'**
  String get addNewVisit;

  /// No description provided for @editVisit.
  ///
  /// In en, this message translates to:
  /// **'Edit Visit'**
  String get editVisit;

  /// No description provided for @updateVisit.
  ///
  /// In en, this message translates to:
  /// **'Update Visit'**
  String get updateVisit;

  /// No description provided for @supervisorVisits.
  ///
  /// In en, this message translates to:
  /// **'Supervisor Visits'**
  String get supervisorVisits;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get notStarted;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @noVisitsFound.
  ///
  /// In en, this message translates to:
  /// **'No visits found'**
  String get noVisitsFound;

  /// No description provided for @surveys.
  ///
  /// In en, this message translates to:
  /// **'Surveys'**
  String get surveys;

  /// No description provided for @createSurvey.
  ///
  /// In en, this message translates to:
  /// **'Create Survey'**
  String get createSurvey;

  /// No description provided for @editSurvey.
  ///
  /// In en, this message translates to:
  /// **'Edit Survey'**
  String get editSurvey;

  /// No description provided for @surveyName.
  ///
  /// In en, this message translates to:
  /// **'Survey Name'**
  String get surveyName;

  /// No description provided for @pleaseEnterSurveyName.
  ///
  /// In en, this message translates to:
  /// **'Please enter survey name'**
  String get pleaseEnterSurveyName;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @isActive.
  ///
  /// In en, this message translates to:
  /// **'Is Active'**
  String get isActive;

  /// No description provided for @validFrom.
  ///
  /// In en, this message translates to:
  /// **'Valid From'**
  String get validFrom;

  /// No description provided for @validTo.
  ///
  /// In en, this message translates to:
  /// **'Valid To'**
  String get validTo;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questions;

  /// No description provided for @addQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add Question'**
  String get addQuestion;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @noSurveys.
  ///
  /// In en, this message translates to:
  /// **'No Surveys'**
  String get noSurveys;

  /// No description provided for @createYourFirstSurvey.
  ///
  /// In en, this message translates to:
  /// **'Create your first survey to get started'**
  String get createYourFirstSurvey;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @createCustomer.
  ///
  /// In en, this message translates to:
  /// **'Create customer'**
  String get createCustomer;

  /// No description provided for @createSalesOrder.
  ///
  /// In en, this message translates to:
  /// **'Create sales order'**
  String get createSalesOrder;

  /// No description provided for @createDelivery.
  ///
  /// In en, this message translates to:
  /// **'Create delivery'**
  String get createDelivery;

  /// No description provided for @createReturn.
  ///
  /// In en, this message translates to:
  /// **'Create return'**
  String get createReturn;

  /// No description provided for @createIncomingPayment.
  ///
  /// In en, this message translates to:
  /// **'Incoming payment'**
  String get createIncomingPayment;

  /// No description provided for @visitSurvey.
  ///
  /// In en, this message translates to:
  /// **'Survey'**
  String get visitSurvey;

  /// No description provided for @visitSurveySubmissions.
  ///
  /// In en, this message translates to:
  /// **'Survey submissions'**
  String get visitSurveySubmissions;

  /// No description provided for @visitSurveySelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select survey'**
  String get visitSurveySelectTitle;

  /// No description provided for @visitSurveyNoSurveys.
  ///
  /// In en, this message translates to:
  /// **'No surveys available.'**
  String get visitSurveyNoSurveys;

  /// No description provided for @visitSurveyNoSubmissions.
  ///
  /// In en, this message translates to:
  /// **'No survey submissions for this visit.'**
  String get visitSurveyNoSubmissions;

  /// No description provided for @visitSurveyNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'This survey has no questions with IDs from the server. It cannot be answered in the app.'**
  String get visitSurveyNoQuestions;

  /// No description provided for @visitActionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No visit actions or answered survey responses yet.'**
  String get visitActionsEmpty;

  /// No description provided for @visitSurveySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Survey submitted.'**
  String get visitSurveySubmitted;

  /// No description provided for @visitSurveySubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get visitSurveySubmit;

  /// No description provided for @visitSurveyRequired.
  ///
  /// In en, this message translates to:
  /// **'Please answer all required questions.'**
  String get visitSurveyRequired;

  /// No description provided for @visitSurveyAnswerAtLeastTwo.
  ///
  /// In en, this message translates to:
  /// **'Please answer at least two questions before submitting.'**
  String get visitSurveyAnswerAtLeastTwo;

  /// No description provided for @visitSurveyAnswerAllQuestions.
  ///
  /// In en, this message translates to:
  /// **'Please answer every question before submitting.'**
  String get visitSurveyAnswerAllQuestions;

  /// No description provided for @visitSurveyAnswerAllHint.
  ///
  /// In en, this message translates to:
  /// **'Answer all questions in the card below, then tap Submit once to send your response.'**
  String get visitSurveyAnswerAllHint;

  /// No description provided for @visitSurveyNotActive.
  ///
  /// In en, this message translates to:
  /// **'This survey is not active or is outside its validity period.'**
  String get visitSurveyNotActive;

  /// No description provided for @visitSurveyRecordedActions.
  ///
  /// In en, this message translates to:
  /// **'Recorded actions'**
  String get visitSurveyRecordedActions;

  /// No description provided for @visitSurveyNoErpActions.
  ///
  /// In en, this message translates to:
  /// **'No ERP actions for this visit yet.'**
  String get visitSurveyNoErpActions;

  /// No description provided for @visitSurveyFreeTextTooShort.
  ///
  /// In en, this message translates to:
  /// **'Enter at least {count} characters for this answer.'**
  String visitSurveyFreeTextTooShort(int count);

  /// No description provided for @visitSurveyFreeTextMinHint.
  ///
  /// In en, this message translates to:
  /// **'Minimum {count} characters'**
  String visitSurveyFreeTextMinHint(int count);

  /// No description provided for @readyForDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders ready for delivery'**
  String get readyForDeliveryTitle;

  /// No description provided for @readyForDeliverySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by doc no., customer code or name…'**
  String get readyForDeliverySearchHint;

  /// No description provided for @readyForDeliveryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No orders ready for delivery.'**
  String get readyForDeliveryEmpty;

  /// No description provided for @readyForDeliveryRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get readyForDeliveryRetry;

  /// No description provided for @readyForReturnTitle.
  ///
  /// In en, this message translates to:
  /// **'Deliveries ready for return'**
  String get readyForReturnTitle;

  /// No description provided for @readyForReturnSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by doc no., customer code or name…'**
  String get readyForReturnSearchHint;

  /// No description provided for @readyForReturnEmpty.
  ///
  /// In en, this message translates to:
  /// **'No deliveries ready for return.'**
  String get readyForReturnEmpty;

  /// No description provided for @readyForReturnRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get readyForReturnRetry;

  /// No description provided for @docNumber.
  ///
  /// In en, this message translates to:
  /// **'Doc #'**
  String get docNumber;

  /// No description provided for @viewSalesOrders.
  ///
  /// In en, this message translates to:
  /// **'View sales orders'**
  String get viewSalesOrders;

  /// No description provided for @visitAction.
  ///
  /// In en, this message translates to:
  /// **'Visit action'**
  String get visitAction;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory transfer request'**
  String get inventory;

  /// No description provided for @inventoryDocNotFound.
  ///
  /// In en, this message translates to:
  /// **'Document not found.'**
  String get inventoryDocNotFound;

  /// No description provided for @inventorySearchClearResult.
  ///
  /// In en, this message translates to:
  /// **'Clear result'**
  String get inventorySearchClearResult;

  /// No description provided for @inventorySearchByDocEntry.
  ///
  /// In en, this message translates to:
  /// **'Search by document entry'**
  String get inventorySearchByDocEntry;

  /// No description provided for @inventoryListHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a document entry above to open a transfer, or use the button to create a new stock transfer.'**
  String get inventoryListHint;

  /// No description provided for @inventoryFabCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get inventoryFabCreate;

  /// No description provided for @inventoryCreateTransfer.
  ///
  /// In en, this message translates to:
  /// **'New stock transfer'**
  String get inventoryCreateTransfer;

  /// No description provided for @inventoryDocumentDate.
  ///
  /// In en, this message translates to:
  /// **'Document date'**
  String get inventoryDocumentDate;

  /// No description provided for @inventoryFromWarehouse.
  ///
  /// In en, this message translates to:
  /// **'From warehouse'**
  String get inventoryFromWarehouse;

  /// No description provided for @inventoryToWarehouse.
  ///
  /// In en, this message translates to:
  /// **'To warehouse'**
  String get inventoryToWarehouse;

  /// No description provided for @inventorySelectWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Select warehouse'**
  String get inventorySelectWarehouse;

  /// No description provided for @inventorySelectBothWarehouses.
  ///
  /// In en, this message translates to:
  /// **'Select both from and to warehouses.'**
  String get inventorySelectBothWarehouses;

  /// No description provided for @inventoryWarehousesMustDiffer.
  ///
  /// In en, this message translates to:
  /// **'From and to warehouses must be different.'**
  String get inventoryWarehousesMustDiffer;

  /// No description provided for @inventorySelectFromWarehouseFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a from warehouse before adding items.'**
  String get inventorySelectFromWarehouseFirst;

  /// No description provided for @inventoryAddItems.
  ///
  /// In en, this message translates to:
  /// **'Add items'**
  String get inventoryAddItems;

  /// No description provided for @inventorySearchItemHint.
  ///
  /// In en, this message translates to:
  /// **'Search item code or name…'**
  String get inventorySearchItemHint;

  /// No description provided for @inventoryNoItemFound.
  ///
  /// In en, this message translates to:
  /// **'No item found.'**
  String get inventoryNoItemFound;

  /// No description provided for @inventoryItemAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'This item is already on the list.'**
  String get inventoryItemAlreadyAdded;

  /// No description provided for @inventoryAddAtLeastOneLine.
  ///
  /// In en, this message translates to:
  /// **'Add at least one line.'**
  String get inventoryAddAtLeastOneLine;

  /// No description provided for @inventorySelectUomForLine.
  ///
  /// In en, this message translates to:
  /// **'Select unit of measure for {itemCode}'**
  String inventorySelectUomForLine(String itemCode);

  /// No description provided for @inventoryQuantityMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be greater than zero.'**
  String get inventoryQuantityMustBePositive;

  /// No description provided for @inventoryCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create transfer.'**
  String get inventoryCreateFailed;

  /// No description provided for @inventoryTransferSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get inventoryTransferSuccessTitle;

  /// No description provided for @inventoryCreated.
  ///
  /// In en, this message translates to:
  /// **'Transfer created — doc entry {doc}'**
  String inventoryCreated(String doc);

  /// No description provided for @inventorySubmitTransfer.
  ///
  /// In en, this message translates to:
  /// **'Submit transfer'**
  String get inventorySubmitTransfer;

  /// No description provided for @inventoryLines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get inventoryLines;

  /// No description provided for @inventoryNoLinesYet.
  ///
  /// In en, this message translates to:
  /// **'No lines yet. Search and add items above.'**
  String get inventoryNoLinesYet;

  /// No description provided for @inventoryColItemCode.
  ///
  /// In en, this message translates to:
  /// **'Item code'**
  String get inventoryColItemCode;

  /// No description provided for @inventoryColItemName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get inventoryColItemName;

  /// No description provided for @inventoryColItemUnit.
  ///
  /// In en, this message translates to:
  /// **'Item unit'**
  String get inventoryColItemUnit;

  /// No description provided for @inventoryColOnHand.
  ///
  /// In en, this message translates to:
  /// **'On hand'**
  String get inventoryColOnHand;

  /// No description provided for @inventoryColQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get inventoryColQty;

  /// No description provided for @inventoryColUom.
  ///
  /// In en, this message translates to:
  /// **'UoM'**
  String get inventoryColUom;

  /// No description provided for @inventoryNoUom.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get inventoryNoUom;

  /// No description provided for @inventoryDocEntry.
  ///
  /// In en, this message translates to:
  /// **'Doc entry'**
  String get inventoryDocEntry;

  /// No description provided for @inventoryDocNum.
  ///
  /// In en, this message translates to:
  /// **'Doc no.'**
  String get inventoryDocNum;

  /// No description provided for @inventoryStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get inventoryStatus;

  /// No description provided for @inventoryPickItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Select item'**
  String get inventoryPickItemTitle;

  /// No description provided for @inventoryPickItemSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by code or name…'**
  String get inventoryPickItemSearchHint;

  /// No description provided for @inventoryCounting.
  ///
  /// In en, this message translates to:
  /// **'Inventory counting'**
  String get inventoryCounting;

  /// No description provided for @inventoryCountingListHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a document entry above to open a count, or use Create to start a new inventory count.'**
  String get inventoryCountingListHint;

  /// No description provided for @inventoryCountingNew.
  ///
  /// In en, this message translates to:
  /// **'New inventory count'**
  String get inventoryCountingNew;

  /// No description provided for @inventoryCountDate.
  ///
  /// In en, this message translates to:
  /// **'Count date'**
  String get inventoryCountDate;

  /// No description provided for @inventoryColCountedQty.
  ///
  /// In en, this message translates to:
  /// **'Counted'**
  String get inventoryColCountedQty;

  /// No description provided for @inventoryColVariance.
  ///
  /// In en, this message translates to:
  /// **'Variance'**
  String get inventoryColVariance;

  /// No description provided for @inventoryColWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get inventoryColWarehouse;

  /// No description provided for @inventoryCountingCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create inventory count.'**
  String get inventoryCountingCreateFailed;

  /// No description provided for @inventoryCountingSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get inventoryCountingSuccessTitle;

  /// No description provided for @inventoryCountingCreated.
  ///
  /// In en, this message translates to:
  /// **'Count created — doc entry {doc}'**
  String inventoryCountingCreated(String doc);

  /// No description provided for @inventoryCountingNoDefaultWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Set a default warehouse in your profile before creating a count.'**
  String get inventoryCountingNoDefaultWarehouse;

  /// No description provided for @inventoryCountedQtyNonNegative.
  ///
  /// In en, this message translates to:
  /// **'Counted quantity cannot be negative.'**
  String get inventoryCountedQtyNonNegative;

  /// No description provided for @customersPickCustomerLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick customer location'**
  String get customersPickCustomerLocationTitle;

  /// No description provided for @customersPickLocationMapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere on the map to choose the customer location.'**
  String get customersPickLocationMapHint;

  /// No description provided for @customersSearchAreaHint.
  ///
  /// In en, this message translates to:
  /// **'Search area'**
  String get customersSearchAreaHint;

  /// No description provided for @customersSearchAreaTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search area'**
  String get customersSearchAreaTooltip;

  /// No description provided for @customersCouldNotSearchArea.
  ///
  /// In en, this message translates to:
  /// **'Could not search this area right now'**
  String get customersCouldNotSearchArea;

  /// No description provided for @customersLatLngLine.
  ///
  /// In en, this message translates to:
  /// **'Lat: {lat} , Lng: {lng}'**
  String customersLatLngLine(String lat, String lng);

  /// No description provided for @customersGoogleMapsOpenedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Google Maps opened. Select a location, tap Share, copy the link, and paste it in the field below.'**
  String get customersGoogleMapsOpenedSnackbar;

  /// No description provided for @customersInvalidMapsLink.
  ///
  /// In en, this message translates to:
  /// **'Invalid Google Maps link. Please paste a link that contains coordinates.'**
  String get customersInvalidMapsLink;

  /// No description provided for @customersCustomerCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Customer created successfully'**
  String get customersCustomerCreatedSuccess;

  /// No description provided for @customersCustomerCreatedWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer created: {details}'**
  String customersCustomerCreatedWithDetails(String details);

  /// No description provided for @customersCustomerLocationSection.
  ///
  /// In en, this message translates to:
  /// **'Customer location'**
  String get customersCustomerLocationSection;

  /// No description provided for @customersLocationHowTo.
  ///
  /// In en, this message translates to:
  /// **'To choose a location: open Google Maps using the button below, select the customer location on the map, tap Share, copy the link, then paste it in the field below.'**
  String get customersLocationHowTo;

  /// No description provided for @customersGoogleMapsLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Google Maps link'**
  String get customersGoogleMapsLinkLabel;

  /// No description provided for @customersGoogleMapsLinkHint.
  ///
  /// In en, this message translates to:
  /// **'https://www.google.com/maps?q=...'**
  String get customersGoogleMapsLinkHint;

  /// No description provided for @customersLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get customersLatitude;

  /// No description provided for @customersLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get customersLongitude;

  /// No description provided for @customersOpenGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open Google Maps'**
  String get customersOpenGoogleMaps;

  /// No description provided for @customersPickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on Map'**
  String get customersPickOnMap;

  /// No description provided for @customersMapConfirmPick.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get customersMapConfirmPick;

  /// No description provided for @customersCreateCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Customer'**
  String get customersCreateCustomerTitle;

  /// No description provided for @customersFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get customersFieldName;

  /// No description provided for @customersFieldArabicName.
  ///
  /// In en, this message translates to:
  /// **'Arabic Name'**
  String get customersFieldArabicName;

  /// No description provided for @customersFieldArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get customersFieldArea;

  /// No description provided for @customersFieldCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get customersFieldCity;

  /// No description provided for @customersFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get customersFieldAddress;

  /// No description provided for @customersFieldPhone1.
  ///
  /// In en, this message translates to:
  /// **'Phone 1'**
  String get customersFieldPhone1;

  /// No description provided for @customersFieldPhone2.
  ///
  /// In en, this message translates to:
  /// **'Phone 2'**
  String get customersFieldPhone2;

  /// No description provided for @customersFieldGov.
  ///
  /// In en, this message translates to:
  /// **'Gov'**
  String get customersFieldGov;

  /// No description provided for @customersFieldState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get customersFieldState;

  /// No description provided for @customersFieldZone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get customersFieldZone;

  /// No description provided for @customersFieldRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get customersFieldRegion;

  /// No description provided for @customersSelectZone.
  ///
  /// In en, this message translates to:
  /// **'Select zone'**
  String get customersSelectZone;

  /// No description provided for @customersSelectZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Select zone'**
  String get customersSelectZoneTitle;

  /// No description provided for @customersSelectZoneFirst.
  ///
  /// In en, this message translates to:
  /// **'Select area first'**
  String get customersSelectZoneFirst;

  /// No description provided for @customersSelectStateZoneFirst.
  ///
  /// In en, this message translates to:
  /// **'Select zone first'**
  String get customersSelectStateZoneFirst;

  /// No description provided for @customersSelectRegion.
  ///
  /// In en, this message translates to:
  /// **'Select region'**
  String get customersSelectRegion;

  /// No description provided for @customersSelectRegionTitle.
  ///
  /// In en, this message translates to:
  /// **'Select region'**
  String get customersSelectRegionTitle;

  /// No description provided for @customersSelectCityFirst.
  ///
  /// In en, this message translates to:
  /// **'Select city first'**
  String get customersSelectCityFirst;

  /// No description provided for @customersSelectArea.
  ///
  /// In en, this message translates to:
  /// **'Select area'**
  String get customersSelectArea;

  /// No description provided for @customersSelectAreaTitle.
  ///
  /// In en, this message translates to:
  /// **'Select area'**
  String get customersSelectAreaTitle;

  /// No description provided for @customersSelectState.
  ///
  /// In en, this message translates to:
  /// **'Select state'**
  String get customersSelectState;

  /// No description provided for @customersSelectStateTitle.
  ///
  /// In en, this message translates to:
  /// **'Select state'**
  String get customersSelectStateTitle;

  /// No description provided for @customersSelectStateFirst.
  ///
  /// In en, this message translates to:
  /// **'Select state first'**
  String get customersSelectStateFirst;

  /// No description provided for @customersSelectCity.
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get customersSelectCity;

  /// No description provided for @customersSelectCityTitle.
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get customersSelectCityTitle;

  /// No description provided for @customersSearchMasterDataHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get customersSearchMasterDataHint;

  /// No description provided for @customersNoMasterDataFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get customersNoMasterDataFound;

  /// No description provided for @customersNoMatchingMasterData.
  ///
  /// In en, this message translates to:
  /// **'No matching results'**
  String get customersNoMatchingMasterData;

  /// No description provided for @customersFieldTerr.
  ///
  /// In en, this message translates to:
  /// **'Terr'**
  String get customersFieldTerr;

  /// No description provided for @customersSelectChannelBpTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Channel BP (Customer)'**
  String get customersSelectChannelBpTitle;

  /// No description provided for @customersSearchCustomersEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Search customers...'**
  String get customersSearchCustomersEllipsis;

  /// No description provided for @customersNoCustomersFoundList.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get customersNoCustomersFoundList;

  /// No description provided for @customersChannelBpLabel.
  ///
  /// In en, this message translates to:
  /// **'Channel BP'**
  String get customersChannelBpLabel;

  /// No description provided for @customersSelectCustomerPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select customer'**
  String get customersSelectCustomerPlaceholder;

  /// No description provided for @customersSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get customersSeries;

  /// No description provided for @customersSearchTerritoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Search territories...'**
  String get customersSearchTerritoriesHint;

  /// No description provided for @customersNoTerritoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No territories found'**
  String get customersNoTerritoriesFound;

  /// No description provided for @customersNoMatchingTerritories.
  ///
  /// In en, this message translates to:
  /// **'No matching territories'**
  String get customersNoMatchingTerritories;

  /// No description provided for @customersSelectGovernorate.
  ///
  /// In en, this message translates to:
  /// **'Select governorate'**
  String get customersSelectGovernorate;

  /// No description provided for @customersSelectGovernorateFirst.
  ///
  /// In en, this message translates to:
  /// **'Select governorate first'**
  String get customersSelectGovernorateFirst;

  /// No description provided for @customersSelectTerritory.
  ///
  /// In en, this message translates to:
  /// **'Select territory'**
  String get customersSelectTerritory;

  /// No description provided for @customersSelectGovernorateTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Governorate'**
  String get customersSelectGovernorateTitle;

  /// No description provided for @customersSelectTerritoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Territory'**
  String get customersSelectTerritoryTitle;

  /// No description provided for @customersUnknownPlace.
  ///
  /// In en, this message translates to:
  /// **'Unknown place'**
  String get customersUnknownPlace;

  /// No description provided for @visitCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Visit created'**
  String get visitCreatedSuccess;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @locationCapturedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Location captured successfully!'**
  String get locationCapturedSuccess;

  /// No description provided for @locationErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Error'**
  String get locationErrorTitle;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable location services in your device settings.'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are denied. Please grant location permission to use this feature.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied. Please enable them in app settings.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @couldNotOpenGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Maps. Please ensure you have a browser or Google Maps installed.'**
  String get couldNotOpenGoogleMaps;

  /// No description provided for @googleMapsOpenedPasteLinkAbove.
  ///
  /// In en, this message translates to:
  /// **'Google Maps opened. Select a location, tap Share, copy the link, and paste it in the field above.'**
  String get googleMapsOpenedPasteLinkAbove;

  /// No description provided for @standaloneGoogleMapsLinkOptional.
  ///
  /// In en, this message translates to:
  /// **'Google Maps Link (Optional)'**
  String get standaloneGoogleMapsLinkOptional;

  /// No description provided for @standaloneGoogleMapsHintAuto.
  ///
  /// In en, this message translates to:
  /// **'Google Maps link will be generated automatically'**
  String get standaloneGoogleMapsHintAuto;

  /// No description provided for @standaloneMapsLocationTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: Tap the location icon to get your current location, or the map icon to open Google Maps and pick a location manually.'**
  String get standaloneMapsLocationTip;

  /// No description provided for @tooltipGetCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Get current location'**
  String get tooltipGetCurrentLocation;

  /// No description provided for @tooltipOpenMapsSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Open Google Maps to select location'**
  String get tooltipOpenMapsSelectLocation;

  /// No description provided for @standaloneVisitHistoryTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get standaloneVisitHistoryTab;

  /// No description provided for @standaloneVisitCurrentTab.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get standaloneVisitCurrentTab;

  /// No description provided for @standaloneVisitFutureTab.
  ///
  /// In en, this message translates to:
  /// **'Future'**
  String get standaloneVisitFutureTab;

  /// No description provided for @customersListTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersListTitle;

  /// No description provided for @teamMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Team map'**
  String get teamMapTitle;

  /// No description provided for @teamMapLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {time}'**
  String teamMapLastUpdated(String time);

  /// No description provided for @teamMapTeamList.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get teamMapTeamList;

  /// No description provided for @teamMapEmpty.
  ///
  /// In en, this message translates to:
  /// **'No team members to show.'**
  String get teamMapEmpty;

  /// No description provided for @teamMapNoLocation.
  ///
  /// In en, this message translates to:
  /// **'No location yet'**
  String get teamMapNoLocation;

  /// No description provided for @teamMapMemberDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales rep details'**
  String get teamMapMemberDetailsTitle;

  /// No description provided for @teamMapMemberPlaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Nearby place'**
  String get teamMapMemberPlaceLabel;

  /// No description provided for @teamMapPlaceLookupLoading.
  ///
  /// In en, this message translates to:
  /// **'Looking up nearby place…'**
  String get teamMapPlaceLookupLoading;

  /// No description provided for @teamMapPlaceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Place name unavailable'**
  String get teamMapPlaceUnknown;

  /// No description provided for @teamMapMemberLatitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get teamMapMemberLatitudeLabel;

  /// No description provided for @teamMapMemberLongitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get teamMapMemberLongitudeLabel;

  /// No description provided for @teamMapMemberLocationTime.
  ///
  /// In en, this message translates to:
  /// **'Location time: {time}'**
  String teamMapMemberLocationTime(String time);

  /// No description provided for @teamMapMemberAccuracyMeters.
  ///
  /// In en, this message translates to:
  /// **'GPS accuracy ±{meters} m'**
  String teamMapMemberAccuracyMeters(String meters);

  /// No description provided for @teamMapOpenInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in maps'**
  String get teamMapOpenInMaps;

  /// No description provided for @customersSearchByNameOrCode.
  ///
  /// In en, this message translates to:
  /// **'Search customers by name or code...'**
  String get customersSearchByNameOrCode;

  /// No description provided for @customersNoCustomersYet.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get customersNoCustomersYet;

  /// No description provided for @customersNoMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No customers match \"{query}\"'**
  String customersNoMatchSearch(String query);

  /// No description provided for @customersTapPlusToCreate.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create a customer'**
  String get customersTapPlusToCreate;

  /// No description provided for @standaloneListNoPastVisits.
  ///
  /// In en, this message translates to:
  /// **'No past visits'**
  String get standaloneListNoPastVisits;

  /// No description provided for @standaloneListNoVisitsToday.
  ///
  /// In en, this message translates to:
  /// **'No visits today'**
  String get standaloneListNoVisitsToday;

  /// No description provided for @standaloneListNoFutureVisits.
  ///
  /// In en, this message translates to:
  /// **'No future visits'**
  String get standaloneListNoFutureVisits;

  /// No description provided for @dateLabelToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateLabelToday;

  /// No description provided for @dateLabelYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateLabelYesterday;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet balance'**
  String get walletTitle;

  /// No description provided for @walletAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get walletAccount;

  /// No description provided for @walletProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get walletProject;

  /// No description provided for @walletLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load wallet balance'**
  String get walletLoadFailed;

  /// No description provided for @walletRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh wallet'**
  String get walletRefresh;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
