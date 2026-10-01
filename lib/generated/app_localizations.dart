import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Anup Dhotre'**
  String get appTitle;

  /// No description provided for @howCanWeHelpYou.
  ///
  /// In en, this message translates to:
  /// **'How can we help you?'**
  String get howCanWeHelpYou;

  /// No description provided for @postComplaint.
  ///
  /// In en, this message translates to:
  /// **'Post Complaint'**
  String get postComplaint;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @latestNews.
  ///
  /// In en, this message translates to:
  /// **'Latest News'**
  String get latestNews;

  /// No description provided for @messageMp.
  ///
  /// In en, this message translates to:
  /// **'Message MP'**
  String get messageMp;

  /// No description provided for @emergencyNumbers.
  ///
  /// In en, this message translates to:
  /// **'Emergency\nNumbers'**
  String get emergencyNumbers;

  /// No description provided for @latestUpdates.
  ///
  /// In en, this message translates to:
  /// **'Latest Updates'**
  String get latestUpdates;

  /// No description provided for @followUs.
  ///
  /// In en, this message translates to:
  /// **'Follow Us'**
  String get followUs;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @officials.
  ///
  /// In en, this message translates to:
  /// **'Officials'**
  String get officials;

  /// No description provided for @emergencyImportantNumbers.
  ///
  /// In en, this message translates to:
  /// **'Emergency & Important Numbers'**
  String get emergencyImportantNumbers;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @appointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get appointment;

  /// No description provided for @trackRequest.
  ///
  /// In en, this message translates to:
  /// **'Track Request'**
  String get trackRequest;

  /// No description provided for @myAppointments.
  ///
  /// In en, this message translates to:
  /// **'My Appointments'**
  String get myAppointments;

  /// No description provided for @noAppointmentsYet.
  ///
  /// In en, this message translates to:
  /// **'You have no appointments yet.'**
  String get noAppointmentsYet;

  /// No description provided for @purpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get purpose;

  /// No description provided for @trackMyRequests.
  ///
  /// In en, this message translates to:
  /// **'Track My Requests'**
  String get trackMyRequests;

  /// No description provided for @appointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments;

  /// No description provided for @complaints.
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get complaints;

  /// No description provided for @noAppointmentsBooked.
  ///
  /// In en, this message translates to:
  /// **'No appointments booked yet.'**
  String get noAppointmentsBooked;

  /// No description provided for @noComplaintsYet.
  ///
  /// In en, this message translates to:
  /// **'No complaints filed yet.'**
  String get noComplaintsYet;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @sendMessageToMp.
  ///
  /// In en, this message translates to:
  /// **'Send Message to MP'**
  String get sendMessageToMp;

  /// No description provided for @messageSubmitDesc.
  ///
  /// In en, this message translates to:
  /// **'Submit your query, message, or request directly to Hon. Anup Dhotre\'s office.'**
  String get messageSubmitDesc;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @messageDetails.
  ///
  /// In en, this message translates to:
  /// **'Message details'**
  String get messageDetails;

  /// No description provided for @iAmSeniorCitizen.
  ///
  /// In en, this message translates to:
  /// **'I am a Senior Citizen (60+ years)'**
  String get iAmSeniorCitizen;

  /// No description provided for @helpsPrioritize.
  ///
  /// In en, this message translates to:
  /// **'Helps prioritize support requests'**
  String get helpsPrioritize;

  /// No description provided for @iAmMediaContact.
  ///
  /// In en, this message translates to:
  /// **'I am representing Media / Press'**
  String get iAmMediaContact;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @messageSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Message sent to MP desk successfully!'**
  String get messageSentSuccess;

  /// No description provided for @pleaseEnterSubjectAndBody.
  ///
  /// In en, this message translates to:
  /// **'Please enter a subject and message body'**
  String get pleaseEnterSubjectAndBody;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageMarathi.
  ///
  /// In en, this message translates to:
  /// **'मराठी'**
  String get languageMarathi;

  /// No description provided for @notificationsUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Notifications are up to date'**
  String get notificationsUpToDate;

  /// No description provided for @sliderImageAdded.
  ///
  /// In en, this message translates to:
  /// **'Slider image added successfully!'**
  String get sliderImageAdded;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @officialPortal.
  ///
  /// In en, this message translates to:
  /// **'OFFICIAL PORTAL'**
  String get officialPortal;

  /// No description provided for @mpName.
  ///
  /// In en, this message translates to:
  /// **'Hon. Anup Dhotre'**
  String get mpName;

  /// No description provided for @mpDescription.
  ///
  /// In en, this message translates to:
  /// **'Member of Parliament (Akola)'**
  String get mpDescription;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login using Email or Phone Number'**
  String get loginSubtitle;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email or Phone Number'**
  String get emailOrPhone;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'LOG IN'**
  String get loginButton;

  /// No description provided for @newHereCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'New here? Create Citizen Account'**
  String get newHereCreateAccount;

  /// No description provided for @pleaseFillMandatoryFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all mandatory fields'**
  String get pleaseFillMandatoryFields;

  /// No description provided for @phoneNumberLengthError.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be 10 digits'**
  String get phoneNumberLengthError;

  /// No description provided for @invalidEmailOrPhoneError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email or 10-digit phone number'**
  String get invalidEmailOrPhoneError;

  /// No description provided for @passwordMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters required'**
  String get passwordMinLengthError;

  /// No description provided for @citizenRegistration.
  ///
  /// In en, this message translates to:
  /// **'Citizen Registration'**
  String get citizenRegistration;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your profile to stay connected'**
  String get signUpSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email ID (Optional)'**
  String get emailOptional;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @ward.
  ///
  /// In en, this message translates to:
  /// **'Ward'**
  String get ward;

  /// No description provided for @village.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get village;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'REGISTER'**
  String get registerButton;

  /// No description provided for @alreadyRegisteredSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already registered? Sign in'**
  String get alreadyRegisteredSignIn;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'CREATING ACCOUNT...'**
  String get creatingAccount;

  /// No description provided for @agreePrivacyPolicyError.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the privacy policy'**
  String get agreePrivacyPolicyError;

  /// No description provided for @passwordsDoNotMatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatchError;

  /// No description provided for @isRequired.
  ///
  /// In en, this message translates to:
  /// **'is required'**
  String get isRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @digitsOnly.
  ///
  /// In en, this message translates to:
  /// **'Digits only'**
  String get digitsOnly;

  /// No description provided for @minSixCharacters.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get minSixCharacters;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpTitle;

  /// No description provided for @signUpTitleDesc.
  ///
  /// In en, this message translates to:
  /// **'Digital Bridge to Your Representative'**
  String get signUpTitleDesc;

  /// No description provided for @agreePrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'I agree with privacy policy'**
  String get agreePrivacyPolicy;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
    case 'mr': return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
