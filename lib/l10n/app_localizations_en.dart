// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DKT Sales APP';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInToContinue => 'Sign in to your account to continue';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get roleId => 'Role ID';

  @override
  String get supervisorId => 'Supervisor ID (Optional)';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get guestMode => 'Guest mode';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get contactAdmin => 'Contact Admin';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get createUser => 'Create User';

  @override
  String get users => 'Users';

  @override
  String get targets => 'Targets';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get profile => 'Profile';

  @override
  String get createNewUser => 'Create New User';

  @override
  String get fillDetailsToCreateUser => 'Fill in the details to create a new user account';

  @override
  String get createUserButton => 'Create User';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get signedInSuccessfully => 'Signed in successfully!';

  @override
  String get userCreatedSuccessfully => 'User created successfully!';

  @override
  String get enterUsername => 'Enter your username';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get enterFullName => 'Enter full name';

  @override
  String get enterEmail => 'user@example.com';

  @override
  String get enterPhone => 'Enter phone number';

  @override
  String get enterRoleId => 'Enter role ID (UUID)';

  @override
  String get enterSupervisorId => 'Enter supervisor ID (UUID)';

  @override
  String get supervisor => 'Supervisor';

  @override
  String get selectSupervisor => 'Select supervisor';

  @override
  String get subRoles => 'Sub Roles';

  @override
  String get selectSubRoles => 'Select sub roles';

  @override
  String get sapSalesEmployeeCode => 'SAP Sales Employee';

  @override
  String get selectSapSalesEmployee => 'Select SAP Sales Employee';

  @override
  String get searchEmployee => 'Search employee by name or code';

  @override
  String get noEmployeesFound => 'No employees found';

  @override
  String get territoryId => 'Territory ID (Optional)';

  @override
  String get enterTerritoryId => 'Enter territory ID (UUID)';

  @override
  String get selectTerritory => 'Select Territory';

  @override
  String get selectSubTerritory => 'Select Sub-Territory';

  @override
  String get cancel => 'Cancel';

  @override
  String get exit => 'Exit';

  @override
  String get exitApp => 'Exit app?';

  @override
  String get exitAppConfirmation => 'Are you sure you want to exit?';

  @override
  String get home => 'Home';

  @override
  String get journeyPlans => 'Journey Plans';

  @override
  String get journeyPlan => 'Journey Plan';

  @override
  String get createJourneyPlan => 'Create Journey Plan';

  @override
  String get createJourneyPlanFor => 'Create Journey Plan For';

  @override
  String get totalJourneys => 'Total Journeys';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get approved => 'Approved';

  @override
  String get totalStops => 'Total Visits';

  @override
  String get totalTargets => 'Total Targets';

  @override
  String get avgProgress => 'Avg Progress';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get createJourney => 'Create Journey';

  @override
  String get viewTargets => 'View Targets';

  @override
  String get standaloneVisit => 'Standalone Visit';

  @override
  String get standaloneVisits => 'Standalone Visits';

  @override
  String get createStandaloneVisit => 'Create Visit';

  @override
  String get customers => 'Customers';

  @override
  String get salesOrder => 'Sales Order';

  @override
  String get salesOrders => 'Sales Orders';

  @override
  String get deliveries => 'Deliveries';

  @override
  String get noDeliveries => 'No deliveries found.';

  @override
  String get returns => 'Returns';

  @override
  String get noReturns => 'No returns found.';

  @override
  String welcomeBackUser(String name) {
    return 'Welcome back, $name!';
  }

  @override
  String get heresYourOverview => 'Here\'s your overview';

  @override
  String get forMyself => 'For Myself';

  @override
  String get forAnotherUser => 'For Another User';

  @override
  String get selectUser => 'Select User';

  @override
  String get selectUserHint => 'Select user...';

  @override
  String get noUsersAvailable => 'No users available';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get notesOptional => 'Notes (Optional)';

  @override
  String get enterAdditionalNotes => 'Enter any additional notes...';

  @override
  String get day => 'Day';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get quarter => 'Quarter';

  @override
  String get year => 'Year';

  @override
  String get next => 'Next';

  @override
  String get createPlan => 'Create Plan';

  @override
  String get addStops => 'Add Visits';

  @override
  String get plannedDateAndTime => 'Planned Date & Time';

  @override
  String get plannedTime => 'Planned Time';

  @override
  String get estimatedDurationMinutes => 'Estimated Duration (minutes)';

  @override
  String get enterDurationMinutes => 'Enter duration in minutes';

  @override
  String get normal => 'Normal';

  @override
  String get coach => 'Coach';

  @override
  String get double => 'Double';

  @override
  String get visitType => 'Visit Type';

  @override
  String get selectCustomer => 'Select Customer';

  @override
  String get searchCustomers => 'Search customers by name or code...';

  @override
  String get addToList => 'Add to List';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Save';

  @override
  String get saveAllStops => 'Save All Visits';

  @override
  String get saveAndReturn => 'Back to Plan';

  @override
  String get pendingStops => 'Pending Visits';

  @override
  String get existingStops => 'Existing Visits';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get clearAll => 'Clear All';

  @override
  String get allUsers => 'All Users';

  @override
  String get allPeriods => 'All Periods';

  @override
  String get selectPeriodType => 'Select period type...';

  @override
  String get myJourneys => 'My Journeys';

  @override
  String get myVisits => 'My Visits';

  @override
  String get assignedJourneys => 'Assigned Journeys';

  @override
  String get myJourneyPlans => 'My Journey Plans';

  @override
  String get journeyPlansList => 'Journey Plans List';

  @override
  String get myTargets => 'My Targets';

  @override
  String get targetsList => 'Targets List';

  @override
  String get pleaseSelectUser => 'Please select a user';

  @override
  String get deleteJourneyPlan => 'Delete Journey Plan';

  @override
  String get deleteJourneyPlanConfirmation => 'Are you sure you want to delete this journey plan?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get targetDetails => 'Target Details';

  @override
  String get breakdowns => 'Breakdowns';

  @override
  String get value => 'Value';

  @override
  String get achieved => 'Achieved';

  @override
  String get remaining => 'Remaining';

  @override
  String get progress => 'Progress';

  @override
  String get details => 'Details';

  @override
  String get noDetailsAvailable => 'No details available';

  @override
  String get saving => 'Saving...';

  @override
  String get pleaseSelectStartAndEndDates => 'Please select start and end dates';

  @override
  String get pleaseCreateJourneyPlanFirst => 'Please create a journey plan first';

  @override
  String get pleaseSelectCustomer => 'Please select a customer';

  @override
  String get tapToSelectCustomer => 'Tap to select customer';

  @override
  String get stop => 'Visit';

  @override
  String visitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Visits',
      one: '1 Visit',
    );
    return '$_temp0';
  }

  @override
  String visitOrderBadge(int order) {
    return 'Visit $order';
  }

  @override
  String get journeyPlanAddVisitTitle => 'Add Visit';

  @override
  String get journeyPlanCreateFirstBeforeVisits => 'Please create a journey plan in Step 1 before adding visits.';

  @override
  String get journeyPlanStep2SubtitleExisting => 'View existing visits and add new ones to your journey plan';

  @override
  String get journeyPlanStep2SubtitleNew => 'Create a visit for your journey plan';

  @override
  String get addNewVisit => 'Add New Visit';

  @override
  String get editVisit => 'Edit Visit';

  @override
  String get updateVisit => 'Update Visit';

  @override
  String get supervisorVisits => 'Supervisor Visits';

  @override
  String get notStarted => 'Not Started';

  @override
  String get completed => 'Completed';

  @override
  String get noVisitsFound => 'No visits found';

  @override
  String get surveys => 'Surveys';

  @override
  String get createSurvey => 'Create Survey';

  @override
  String get editSurvey => 'Edit Survey';

  @override
  String get surveyName => 'Survey Name';

  @override
  String get pleaseEnterSurveyName => 'Please enter survey name';

  @override
  String get description => 'Description';

  @override
  String get isActive => 'Is Active';

  @override
  String get validFrom => 'Valid From';

  @override
  String get validTo => 'Valid To';

  @override
  String get selectDate => 'Select Date';

  @override
  String get questions => 'Questions';

  @override
  String get addQuestion => 'Add Question';

  @override
  String get create => 'Create';

  @override
  String get update => 'Update';

  @override
  String get noSurveys => 'No Surveys';

  @override
  String get createYourFirstSurvey => 'Create your first survey to get started';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get actions => 'Actions';

  @override
  String get createCustomer => 'Create customer';

  @override
  String get createSalesOrder => 'Create sales order';

  @override
  String get createDelivery => 'Create delivery';

  @override
  String get createReturn => 'Create return';

  @override
  String get createIncomingPayment => 'Incoming payment';

  @override
  String get visitSurvey => 'Survey';

  @override
  String get visitSurveySubmissions => 'Survey submissions';

  @override
  String get visitSurveySelectTitle => 'Select survey';

  @override
  String get visitSurveyNoSurveys => 'No surveys available.';

  @override
  String get visitSurveyNoSubmissions => 'No survey submissions for this visit.';

  @override
  String get visitSurveyNoQuestions => 'This survey has no questions with IDs from the server. It cannot be answered in the app.';

  @override
  String get visitActionsEmpty => 'No visit actions or answered survey responses yet.';

  @override
  String get visitSurveySubmitted => 'Survey submitted.';

  @override
  String get visitSurveySubmit => 'Submit';

  @override
  String get visitSurveyRequired => 'Please answer all required questions.';

  @override
  String get visitSurveyAnswerAtLeastTwo => 'Please answer at least two questions before submitting.';

  @override
  String get visitSurveyAnswerAllQuestions => 'Please answer every question before submitting.';

  @override
  String get visitSurveyAnswerAllHint => 'Answer all questions in the card below, then tap Submit once to send your response.';

  @override
  String get visitSurveyNotActive => 'This survey is not active or is outside its validity period.';

  @override
  String get visitSurveyRecordedActions => 'Recorded actions';

  @override
  String get visitSurveyNoErpActions => 'No ERP actions for this visit yet.';

  @override
  String visitSurveyFreeTextTooShort(int count) {
    return 'Enter at least $count characters for this answer.';
  }

  @override
  String visitSurveyFreeTextMinHint(int count) {
    return 'Minimum $count characters';
  }

  @override
  String get readyForDeliveryTitle => 'Orders ready for delivery';

  @override
  String get readyForDeliverySearchHint => 'Search by doc no., customer code or name…';

  @override
  String get readyForDeliveryEmpty => 'No orders ready for delivery.';

  @override
  String get readyForDeliveryRetry => 'Retry';

  @override
  String get readyForReturnTitle => 'Deliveries ready for return';

  @override
  String get readyForReturnSearchHint => 'Search by doc no., customer code or name…';

  @override
  String get readyForReturnEmpty => 'No deliveries ready for return.';

  @override
  String get readyForReturnRetry => 'Retry';

  @override
  String get docNumber => 'Doc #';

  @override
  String get viewSalesOrders => 'View sales orders';

  @override
  String get visitAction => 'Visit action';

  @override
  String get inventory => 'Inventory transfer request';

  @override
  String get inventoryDocNotFound => 'Document not found.';

  @override
  String get inventorySearchClearResult => 'Clear result';

  @override
  String get inventorySearchByDocEntry => 'Search by document entry';

  @override
  String get inventoryListHint => 'Enter a document entry above to open a transfer, or use the button to create a new stock transfer.';

  @override
  String get inventoryFabCreate => 'Create';

  @override
  String get inventoryCreateTransfer => 'New stock transfer';

  @override
  String get inventoryDocumentDate => 'Document date';

  @override
  String get inventoryFromWarehouse => 'From warehouse';

  @override
  String get inventoryToWarehouse => 'To warehouse';

  @override
  String get inventorySelectWarehouse => 'Select warehouse';

  @override
  String get inventorySelectBothWarehouses => 'Select both from and to warehouses.';

  @override
  String get inventoryWarehousesMustDiffer => 'From and to warehouses must be different.';

  @override
  String get inventorySelectFromWarehouseFirst => 'Select a from warehouse before adding items.';

  @override
  String get inventoryAddItems => 'Add items';

  @override
  String get inventorySearchItemHint => 'Search item code or name…';

  @override
  String get inventoryNoItemFound => 'No item found.';

  @override
  String get inventoryItemAlreadyAdded => 'This item is already on the list.';

  @override
  String get inventoryAddAtLeastOneLine => 'Add at least one line.';

  @override
  String inventorySelectUomForLine(String itemCode) {
    return 'Select unit of measure for $itemCode';
  }

  @override
  String get inventoryQuantityMustBePositive => 'Quantity must be greater than zero.';

  @override
  String get inventoryCreateFailed => 'Could not create transfer.';

  @override
  String get inventoryTransferSuccessTitle => 'Success';

  @override
  String inventoryCreated(String doc) {
    return 'Transfer created — doc entry $doc';
  }

  @override
  String get inventorySubmitTransfer => 'Submit transfer';

  @override
  String get inventoryLines => 'Lines';

  @override
  String get inventoryNoLinesYet => 'No lines yet. Search and add items above.';

  @override
  String get inventoryColItemCode => 'Item code';

  @override
  String get inventoryColItemName => 'Item name';

  @override
  String get inventoryColItemUnit => 'Item unit';

  @override
  String get inventoryColOnHand => 'On hand';

  @override
  String get inventoryColQty => 'Qty';

  @override
  String get inventoryColUom => 'UoM';

  @override
  String get inventoryNoUom => '—';

  @override
  String get inventoryDocEntry => 'Doc entry';

  @override
  String get inventoryDocNum => 'Doc no.';

  @override
  String get inventoryStatus => 'Status';

  @override
  String get inventoryPickItemTitle => 'Select item';

  @override
  String get inventoryPickItemSearchHint => 'Filter by code or name…';

  @override
  String get inventoryCounting => 'Inventory counting';

  @override
  String get inventoryCountingListHint => 'Enter a document entry above to open a count, or use Create to start a new inventory count.';

  @override
  String get inventoryCountingNew => 'New inventory count';

  @override
  String get inventoryCountDate => 'Count date';

  @override
  String get inventoryColCountedQty => 'Counted';

  @override
  String get inventoryColVariance => 'Variance';

  @override
  String get inventoryColWarehouse => 'Warehouse';

  @override
  String get inventoryCountingCreateFailed => 'Could not create inventory count.';

  @override
  String get inventoryCountingSuccessTitle => 'Success';

  @override
  String inventoryCountingCreated(String doc) {
    return 'Count created — doc entry $doc';
  }

  @override
  String get inventoryCountingNoDefaultWarehouse => 'Set a default warehouse in your profile before creating a count.';

  @override
  String get inventoryCountedQtyNonNegative => 'Counted quantity cannot be negative.';

  @override
  String get customersPickCustomerLocationTitle => 'Pick customer location';

  @override
  String get customersPickLocationMapHint => 'Tap anywhere on the map to choose the customer location.';

  @override
  String get customersSearchAreaHint => 'Search area';

  @override
  String get customersSearchAreaTooltip => 'Search area';

  @override
  String get customersCouldNotSearchArea => 'Could not search this area right now';

  @override
  String customersLatLngLine(String lat, String lng) {
    return 'Lat: $lat , Lng: $lng';
  }

  @override
  String get customersGoogleMapsOpenedSnackbar => 'Google Maps opened. Select a location, tap Share, copy the link, and paste it in the field below.';

  @override
  String get customersInvalidMapsLink => 'Invalid Google Maps link. Please paste a link that contains coordinates.';

  @override
  String get customersCustomerCreatedSuccess => 'Customer created successfully';

  @override
  String customersCustomerCreatedWithDetails(String details) {
    return 'Customer created: $details';
  }

  @override
  String get customersDuplicatePhoneTitle => 'Phone already used';

  @override
  String get customersDuplicatePhoneCreateAnyway => 'Create anyway';

  @override
  String get customersDuplicatePhoneChange => 'Change';

  @override
  String get customersCustomerLocationSection => 'Customer location';

  @override
  String get customersLocationHowTo => 'To choose a location: open Google Maps using the button below, select the customer location on the map, tap Share, copy the link, then paste it in the field below.';

  @override
  String get customersGoogleMapsLinkLabel => 'Google Maps link';

  @override
  String get customersGoogleMapsLinkHint => 'https://www.google.com/maps?q=...';

  @override
  String get customersLatitude => 'Latitude';

  @override
  String get customersLongitude => 'Longitude';

  @override
  String get customersOpenGoogleMaps => 'Open Google Maps';

  @override
  String get customersPickOnMap => 'Pick on Map';

  @override
  String get customersMapConfirmPick => 'Pick';

  @override
  String get customersCreateCustomerTitle => 'Create Customer';

  @override
  String get customersFieldName => 'Name';

  @override
  String get customersFieldArabicName => 'Arabic Name';

  @override
  String get customersFieldArea => 'Area';

  @override
  String get customersFieldCity => 'City';

  @override
  String get customersFieldAddress => 'Address';

  @override
  String get customersFieldPhone1 => 'Phone 1';

  @override
  String get customersFieldPhone2 => 'Phone 2';

  @override
  String get customersPhoneKindMobile => 'Mobile';

  @override
  String get customersPhoneKindLandLine => 'Land line';

  @override
  String get customersPhoneMobileInvalid => 'Enter 11 digits after 2 (12 total)';

  @override
  String get customersPhoneLandLineInvalid => 'Enter exactly 10 digits for land line';

  @override
  String get customersPhoneDigitsOnly => 'Enter digits only';

  @override
  String customersPhoneMaxLengthInvalid(int max) {
    return 'Enter at most $max digits';
  }

  @override
  String get customersFieldVatNumber => 'VAT Number';

  @override
  String get customersFieldRequired => 'This field is required';

  @override
  String get customersEnglishNameOnly => 'English name must contain English characters only';

  @override
  String get customersArabicNameOnly => 'Arabic name must contain Arabic characters only';

  @override
  String get customersPhone1Invalid => 'Enter 11 digits after 2 (12 total, e.g. 01234567890)';

  @override
  String get customersPhone2Invalid => 'Phone 2 must be at most 10 characters';

  @override
  String get customersLocationRequired => 'Customer location is required';

  @override
  String get customersSelectSeriesRequired => 'Please select a series';

  @override
  String get customersSelectChannelBpRequired => 'Please select a channel BP customer';

  @override
  String get customersSelectAreaRequired => 'Please select an area';

  @override
  String get customersSelectZoneRequired => 'Please select a zone';

  @override
  String get customersSelectStateRequired => 'Please select a state';

  @override
  String get customersSelectCityRequired => 'Please select a city';

  @override
  String get customersSelectRegionRequired => 'Please select a region';

  @override
  String get customersSelectCustomerTypeRequired => 'Please select a customer type';

  @override
  String get customersFieldGov => 'Gov';

  @override
  String get customersFieldState => 'State';

  @override
  String get customersFieldZone => 'Zone';

  @override
  String get customersFieldRegion => 'Region';

  @override
  String get customersSelectZone => 'Select zone';

  @override
  String get customersSelectZoneTitle => 'Select zone';

  @override
  String get customersSelectZoneFirst => 'Select area first';

  @override
  String get customersSelectStateZoneFirst => 'Select zone first';

  @override
  String get customersSelectRegion => 'Select region';

  @override
  String get customersSelectRegionTitle => 'Select region';

  @override
  String get customersSelectCityFirst => 'Select city first';

  @override
  String get customersSelectArea => 'Select area';

  @override
  String get customersSelectAreaTitle => 'Select area';

  @override
  String get customersSelectState => 'Select state';

  @override
  String get customersSelectStateTitle => 'Select state';

  @override
  String get customersSelectStateFirst => 'Select state first';

  @override
  String get customersSelectCity => 'Select city';

  @override
  String get customersSelectCityTitle => 'Select city';

  @override
  String get customersSearchMasterDataHint => 'Search...';

  @override
  String get customersNoMasterDataFound => 'No results found';

  @override
  String get customersNoMatchingMasterData => 'No matching results';

  @override
  String get customersFieldTerr => 'Terr';

  @override
  String get customersSelectChannelBpTitle => 'Select Channel BP (Customer)';

  @override
  String get customersSearchCustomersEllipsis => 'Search customers...';

  @override
  String get customersNoCustomersFoundList => 'No customers found';

  @override
  String get customersChannelBpLabel => 'Channel BP';

  @override
  String get customersSelectCustomerPlaceholder => 'Select customer';

  @override
  String get customersSeries => 'Series';

  @override
  String get customersSearchTerritoriesHint => 'Search territories...';

  @override
  String get customersNoTerritoriesFound => 'No territories found';

  @override
  String get customersNoMatchingTerritories => 'No matching territories';

  @override
  String get customersSelectGovernorate => 'Select governorate';

  @override
  String get customersSelectGovernorateFirst => 'Select governorate first';

  @override
  String get customersSelectTerritory => 'Select territory';

  @override
  String get customersSelectGovernorateTitle => 'Select Governorate';

  @override
  String get customersSelectTerritoryTitle => 'Select Territory';

  @override
  String get customersUnknownPlace => 'Unknown place';

  @override
  String get visitCreatedSuccess => 'Visit created';

  @override
  String get userNotFound => 'User not found';

  @override
  String get locationCapturedSuccess => 'Location captured successfully!';

  @override
  String get locationErrorTitle => 'Location Error';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get locationServicesDisabled => 'Location services are disabled. Please enable location services in your device settings.';

  @override
  String get locationPermissionDenied => 'Location permissions are denied. Please grant location permission to use this feature.';

  @override
  String get locationPermissionDeniedForever => 'Location permissions are permanently denied. Please enable them in app settings.';

  @override
  String get couldNotOpenGoogleMaps => 'Could not open Google Maps. Please ensure you have a browser or Google Maps installed.';

  @override
  String get googleMapsOpenedPasteLinkAbove => 'Google Maps opened. Select a location, tap Share, copy the link, and paste it in the field above.';

  @override
  String get standaloneGoogleMapsLinkOptional => 'Google Maps Link (Optional)';

  @override
  String get standaloneGoogleMapsHintAuto => 'Google Maps link will be generated automatically';

  @override
  String get standaloneMapsLocationTip => 'Tip: Tap the location icon to get your current location, or the map icon to open Google Maps and pick a location manually.';

  @override
  String get tooltipGetCurrentLocation => 'Get current location';

  @override
  String get tooltipOpenMapsSelectLocation => 'Open Google Maps to select location';

  @override
  String get standaloneVisitHistoryTab => 'History';

  @override
  String get standaloneVisitCurrentTab => 'Current';

  @override
  String get standaloneVisitFutureTab => 'Future';

  @override
  String get customersListTitle => 'Customers';

  @override
  String get teamMapTitle => 'Team map';

  @override
  String teamMapLastUpdated(String time) {
    return 'Last updated: $time';
  }

  @override
  String get teamMapTeamList => 'Team';

  @override
  String get teamMapEmpty => 'No team members to show.';

  @override
  String get teamMapNoLocation => 'No location yet';

  @override
  String get teamMapMemberDetailsTitle => 'Sales rep details';

  @override
  String get teamMapMemberPlaceLabel => 'Nearby place';

  @override
  String get teamMapPlaceLookupLoading => 'Looking up nearby place…';

  @override
  String get teamMapPlaceUnknown => 'Place name unavailable';

  @override
  String get teamMapMemberLatitudeLabel => 'Latitude';

  @override
  String get teamMapMemberLongitudeLabel => 'Longitude';

  @override
  String teamMapMemberLocationTime(String time) {
    return 'Location time: $time';
  }

  @override
  String teamMapMemberAccuracyMeters(String meters) {
    return 'GPS accuracy ±$meters m';
  }

  @override
  String get teamMapOpenInMaps => 'Open in maps';

  @override
  String get customersSearchByNameOrCode => 'Search customers by name or code...';

  @override
  String get customersNoCustomersYet => 'No customers yet';

  @override
  String customersNoMatchSearch(String query) {
    return 'No customers match \"$query\"';
  }

  @override
  String get customersTapPlusToCreate => 'Tap + to create a customer';

  @override
  String get standaloneListNoPastVisits => 'No past visits';

  @override
  String get standaloneListNoVisitsToday => 'No visits today';

  @override
  String get standaloneListNoFutureVisits => 'No future visits';

  @override
  String get dateLabelToday => 'Today';

  @override
  String get dateLabelYesterday => 'Yesterday';

  @override
  String get walletTitle => 'Wallet balance';

  @override
  String get walletAccount => 'Account';

  @override
  String get walletProject => 'Project';

  @override
  String get walletLoadFailed => 'Couldn\'t load wallet balance';

  @override
  String get walletRefresh => 'Refresh wallet';
}
