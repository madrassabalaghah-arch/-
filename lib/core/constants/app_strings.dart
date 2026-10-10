/// Every user-facing string in the application, in Urdu.
///
/// The interface is Urdu-first. No screen may hardcode a user-facing string;
/// all of them are declared here so wording stays consistent and can be
/// reviewed in one place.
///
/// Identifiers stay in professional English because they are code, not
/// interface text.
class AppStrings {
  const AppStrings._();

  // ---------------------------------------------------------------------
  // Common actions
  // ---------------------------------------------------------------------
  static const String welcome = 'خوش آمدید';
  static const String continueAction = 'جاری رکھیں';
  static const String submit = 'جمع کروائیں';
  static const String save = 'محفوظ کریں';
  static const String cancel = 'منسوخ کریں';
  static const String delete = 'حذف کریں';
  static const String edit = 'ترمیم کریں';
  static const String search = 'تلاش کریں';
  static const String filter = 'چھانٹیں';
  static const String viewDetails = 'تفصیلات دیکھیں';
  static const String back = 'واپس';
  static const String next = 'آگے';
  static const String previous = 'پچھلا';
  static const String viewAll = 'سب دیکھیں';
  static const String close = 'بند کریں';
  static const String confirm = 'تصدیق کریں';
  static const String review = 'جائزہ کریں';
  static const String add = 'شامل کریں';

  // ---------------------------------------------------------------------
  // States
  // ---------------------------------------------------------------------
  static const String loading = 'لوڈ ہو رہا ہے...';
  static const String noData = 'کوئی معلومات دستیاب نہیں';
  static const String somethingWentWrong = 'کچھ خرابی پیش آ گئی ہے';
  static const String tryAgain = 'دوبارہ کوشش کریں';
  static const String noDataDetail =
      'اس وقت اس حصے میں دکھانے کے لیے کوئی معلومات موجود نہیں ہیں۔';
  static const String errorDetail =
      'معلومات حاصل کرتے ہوئے مسئلہ درپیش ہوا۔ براہِ کرم دوبارہ کوشش کریں۔';
  static const String noSearchResults = 'تلاش کا کوئی نتیجہ نہیں ملا';
  // ---------------------------------------------------------------------
  // Report editing and evidence upload
  // ---------------------------------------------------------------------
  static const String newReport = 'نئی کارگزاری';
  static const String editReport = 'کارگزاری میں ترمیم';
  static const String saveDraft = 'مسودہ محفوظ کریں';
  static const String submitReport = 'کارگزاری جمع کروائیں';
  static const String deleteDraft = 'مسودہ حذف کریں';
  static const String deleteConfirm =
      'کیا آپ واقعی یہ مسودہ حذف کرنا چاہتے ہیں؟ یہ عمل واپس نہیں ہو سکتا۔';
  static const String reportSubmitted = 'کارگزاری جمع کروا دی گئی ہے۔';
  static const String reportSaved = 'مسودہ محفوظ کر لیا گیا ہے۔';
  static const String reportDeleted = 'مسودہ حذف کر دیا گیا ہے۔';
  static const String selectActivityFirst =
      'براہِ کرم پہلے عملی سرگرمی منتخب کریں۔';
  static const String noActivitiesAssigned =
      'آپ کے لیے ابھی کوئی عملی سرگرمی مقرر نہیں کی گئی';
  static const String uploadEvidence = 'ثبوت شامل کریں';
  static const String uploading = 'فائل اپ لوڈ ہو رہی ہے...';
  static const String uploadSuccess = 'فائل کامیابی سے شامل کر دی گئی ہے۔';
  static const String uploadFailed = 'فائل شامل نہیں کی جا سکی۔';
  static const String evidenceDeleted = 'ثبوت حذف کر دیا گیا ہے۔';
  static const String openFile = 'فائل کھولیں';
  static const String onlyDraftsEditable =
      'جمع شدہ کارگزاری میں ترمیم نہیں کی جا سکتی۔';

  // ---------------------------------------------------------------------
  // User administration
  // ---------------------------------------------------------------------
  static const String manageUser = 'صارف کا انتظام';
  static const String currentRole = 'موجودہ حیثیت';
  static const String changeRole = 'حیثیت تبدیل کریں';
  static const String assignedMentor = 'تفویض کردہ مربی';
  static const String assignMentor = 'مربی تفویض کریں';
  static const String noMentorAssigned = 'کوئی مربی تفویض نہیں';
  static const String removeMentor = 'مربی ہٹا دیں';
  static const String noMentorsAvailable =
      'ابھی کوئی مربی موجود نہیں۔ پہلے کسی صارف کو مربی بنائیں۔';
  static const String roleChanged = 'حیثیت تبدیل کر دی گئی ہے۔';
  static const String mentorAssigned = 'مربی تفویض کر دیا گیا ہے۔';
  static const String mentorRemoved = 'مربی ہٹا دیا گیا ہے۔';
  static const String cannotChangeOwnRole =
      'آپ اپنی حیثیت خود تبدیل نہیں کر سکتے۔';
  static const String supervisedGraduates = 'زیرِ رہنمائی فضلاء و فاضلات';
  static const String roleChangeNote =
      'حیثیت تبدیل ہونے کے بعد صارف کو دوبارہ داخل ہونا ہوگا۔';

  // ---------------------------------------------------------------------
  // Wifaq and institute selection
  // ---------------------------------------------------------------------
  static const String selectWifaq = 'اپنا وفاق منتخب کریں';
  static const String selectInstitute = 'اپنا ادارہ منتخب کریں';
  static const String noWifaqSelected = 'وفاق منتخب نہیں کیا گیا';
  static const String noInstituteSelected = 'ادارہ منتخب نہیں کیا گیا';
  static const String addInstitute = 'نیا ادارہ شامل کریں';
  static const String newInstituteName = 'ادارے کا نام درج کریں';
  static const String instituteAdded = 'ادارہ شامل کر دیا گیا ہے۔';
  static const String selectWifaqFirst =
      'ادارہ منتخب کرنے سے پہلے وفاق منتخب کریں۔';
  static const String noWifaqsYet =
      'ابھی کوئی وفاق شامل نہیں کیا گیا۔ منتظم سے رابطہ کریں۔';
  static const String noInstitutesYet =
      'اس وفاق کے تحت ابھی کوئی ادارہ نہیں۔ نیا ادارہ شامل کریں۔';
  static const String addWifaq = 'نیا وفاق شامل کریں';
  static const String wifaqName = 'وفاق کا نام';
  static const String wifaqAdded = 'وفاق شامل کر دیا گیا ہے۔';
  static const String cityOptional = 'شہر (اختیاری)';
  static const String institutes = 'ادارے';

  // ---------------------------------------------------------------------
  // Prompt 05: graduate dashboard
  // ---------------------------------------------------------------------
  static const String graduateStatus = 'فارغ التحصیل / عملی میدان';
  static const String currentStatus = 'موجودہ حیثیت';
  static const String myPracticalJourney = 'میرا عملی سفر';
  static const String newKarGuzari = '+ نئی کارگزاری درج کریں';
  static const String totalKarGuzari = 'مجموعی کارگزاریاں';
  static const String socialActivities = 'معاشرتی و اصلاحی سرگرمیاں';
  static const String completedProjects = 'مکمل شدہ پروجیکٹس';
  static const String recentActivity = 'حالیہ سرگرمی';
  static const String pendingItems = 'زیرِ التوا امور';
  static const String evidenceGroup = 'ثبوت و رپورٹس';
  static const String evidenceImages = 'تصاویر';
  static const String evidenceDocuments = 'دستاویزات';
  static const String evidenceOther = 'دیگر متعلقہ فائلیں';
  static const String category = 'نوعیت';

  /// The کارگزاری is filed under one of four main categories, then one of
  /// that category's three sub criteria.
  static const String selectMainCategory = 'بنیادی شعبہ منتخب کریں';
  static const String selectSubCriterion = 'ذیلی معیار منتخب کریں';
  static const String subCriterionNeeded =
      'براہِ کرم ذیلی معیار منتخب کریں۔';
  static const String noCategoriesYet =
      'ابھی کوئی شعبہ متعین نہیں۔';
  static const String emptyNoPending = 'الحمدللہ! فی الحال کوئی زیرِ التوا کام نہیں۔';
  static const String emptyNoNotifications = 'ابھی کوئی نئی اطلاع موجود نہیں۔';
  static const String emptyFirstKarGuzari =
      'اپنی پہلی کارگزاری درج کریں اور اپنے عملی سفر کو ریکارڈ کریں۔';
  static const String emptyNothingInCategory = 'اس نوعیت کی ابھی کوئی کارگزاری نہیں۔';
  static const String reviewAndFeedback = 'جائزہ و رہنمائی';
  static const String noReviewYet = 'ابھی جائزہ نہیں ہوا۔';

  // Evidence review
  static const String evidenceUnderReview = 'زیرِ جائزہ';
  static const String evidenceApproved = 'منظور شدہ';
  static const String evidenceNeedsInfo = 'مزید معلومات درکار ہیں';
  static const String reviewEvidence = 'ثبوت کا جائزہ لیں';
  static const String reviewNote = 'رائے';
  static const String relatedKarGuzari = 'متعلقہ کارگزاری';
  static const String uploadedOn = 'تاریخِ اندراج';
  static const String evidenceReviewed = 'ثبوت کا جائزہ محفوظ کر دیا گیا ہے۔';

  // Mentor review and today's work
  static const String todaysWork = 'آج کے کام';
  static const String awaitingYourReview = 'آپ کے جائزے کی منتظر';
  static const String needsFeedback = 'رہنمائی کے منتظر فضلاء و فاضلات';
  static const String reviewStepReport = 'کارگزاری';
  static const String reviewStepEvidence = 'ثبوت';
  static const String reviewStepAssessment = 'جائزہ';
  static const String reviewStepComment = 'مربی کا تبصرہ';
  static const String reviewStepGuidance = 'آئندہ رہنمائی';
  static const String hintGuidance = 'آئندہ کے لیے عملی رہنمائی لکھیں';
  static const String emptyNoReviewsWaiting = 'الحمدللہ! کوئی کارگزاری جائزے کی منتظر نہیں۔';

  // Admin grouping
  static const String groupManagement = 'انتظام';
  static const String groupKarGuzari = 'کارگزاری';
  static const String groupSystem = 'نظام';
  static const String groupBackend = 'بیک اینڈ';
  static const String backendDataManagement = 'بیک اینڈ ڈیٹا مینجمنٹ';
  static const String allInstitutes = 'ادارے';
  static const String allReviews = 'جائزے';
  static const String statisticsReports = 'رپورٹس';

  // Registration period
  static const String coursePeriod = 'دورانیہ';
  static const String hintCoursePeriod = 'مثلاً: مارچ تا جون 2024';
  static const String regPeriodMismatch =
      'درج کردہ دورانیہ ہمارے ریکارڈ سے مطابقت نہیں رکھتا۔ کورس کا سال ضرور لکھیں۔';
  static const String recordMatched = 'آپ کا ریکارڈ مل گیا';
  static const String continueRegistration = 'رجسٹریشن جاری رکھیں';

  // Adding participants one at a time
  static const String importFromFile = 'فائل سے درآمد کریں';
  static const String addByForm = 'فارم سے شامل کریں';
  static const String saveAndAddAnother = 'محفوظ کریں اور اگلا شامل کریں';
  static const String participantAlreadyExists =
      'یہ رقم التسجیل پہلے سے ریکارڈ میں موجود ہے۔';
  static const String periodNeedsYear =
      'دورانیہ میں کورس کا سال لکھیں، مثلاً: مارچ تا جون 2024';
  static const String optionalMonths = 'داخلہ اور فراغت کے مہینے (اختیاری)';

  // Mentors and administrators joining by invitation
  static const String staffManagement = 'منتظمین اور دعوت نامے';
  static const String inviteStaff = 'نیا مربی / منتظم شامل کریں';
  static const String inviteMentor = 'نیا مربی شامل کریں';
  static const String inviteStaffNote =
      'یہ ان لوگوں کے لیے ہے جو کورس کے ریکارڈ میں شامل نہیں۔ جس فاضل / فاضلہ کا اکاؤنٹ پہلے سے موجود ہو، اس کی حیثیت "صارف کا انتظام" سے تبدیل کریں۔';
  static const String staffFullName = 'پورا نام';
  static const String inviteAs = 'کس حیثیت سے شامل کریں';
  static const String createInvite = 'دعوت نامہ بنائیں';
  static const String inviteCreated = 'دعوت نامہ تیار ہو گیا';
  static const String inviteCode = 'دعوتی کوڈ';
  static const String hintInviteCode = 'آٹھ حروف، مثلاً: ABCD-2345';
  static const String inviteCodeLength = 'دعوتی کوڈ کے آٹھ حروف درج کریں۔';
  static const String inviteInstructions =
      'یہ کوڈ صرف اسی شخص کو بھیجیں۔ وہ ایپ میں "داخل ہوں" کے صفحے پر "دعوتی کوڈ سے اکاؤنٹ بنائیں" منتخب کر کے یہی ای میل اور یہ کوڈ درج کریں گے۔ کوڈ ایک ہی بار استعمال ہو سکتا ہے۔';
  static const String copyCode = 'کوڈ کاپی کریں';
  static const String codeCopied = 'دعوتی کوڈ کاپی ہو گیا ہے۔';
  static const String openInvites = 'زیرِ التوا دعوت نامے';
  static const String noOpenInvites = 'کوئی زیرِ التوا دعوت نامہ نہیں';
  static const String invitedOn = 'دعوت کی تاریخ';
  static const String cancelInvite = 'دعوت نامہ منسوخ کریں';
  static const String cancelInviteQuestion =
      'کیا آپ یہ دعوت نامہ منسوخ کرنا چاہتے ہیں؟ اس کے بعد یہ کوڈ کام نہیں کرے گا۔';
  static const String inviteCancelled = 'دعوت نامہ منسوخ کر دیا گیا ہے۔';
  static const String administrators = 'منتظمین';
  static const String accountsWithoutRole = 'بغیر حیثیت کے اکاؤنٹ';
  static const String accountsWithoutRoleNote =
      'یہ اکاؤنٹ ایپ استعمال نہیں کر سکتے۔ کسی پر ٹیپ کر کے حیثیت مقرر کریں۔';
  static const String unnamedAccount = 'بے نام اکاؤنٹ';
  static const String inviteEmailRegistered =
      'اس ای میل سے پہلے ہی اکاؤنٹ موجود ہے۔ دعوت نامے کے بجائے اس اکاؤنٹ کی حیثیت "صارف کا انتظام" سے تبدیل کریں۔';
  static const String inviteAlreadyOpen =
      'اس ای میل کے لیے ایک دعوت نامہ پہلے سے زیرِ التوا ہے۔';
  static const String adminOnlyAction = 'یہ کام صرف منتظم کر سکتا ہے۔';

  // Signing up with an invitation
  static const String staffSignUpPrompt = 'مربی یا منتظم؟';
  static const String staffSignUpLink = 'دعوتی کوڈ سے اکاؤنٹ بنائیں';
  static const String staffSignUpTitle = 'دعوت نامے سے اکاؤنٹ بنائیں';
  static const String staffSignUpSubtitle =
      'وہی ای میل درج کریں جس پر منتظم نے دعوت دی ہے، اور ان کا بھیجا ہوا دعوتی کوڈ۔';
  static const String verifyInvite = 'دعوت نامے کی تصدیق کریں';
  static const String inviteMatched = 'آپ کا دعوت نامہ مل گیا';
  static const String invitedAs = 'بطور';
  static const String changeInvite = 'تبدیل کریں';
  static const String inviteRequired = 'ای میل اور دعوتی کوڈ دونوں درج کریں۔';
  static const String inviteNotFound =
      'یہ ای میل اور دعوتی کوڈ کسی دعوت نامے سے مطابقت نہیں رکھتے۔ دونوں دوبارہ دیکھ لیں۔';
  static const String inviteUsed = 'یہ دعوتی کوڈ پہلے ہی استعمال ہو چکا ہے۔';
  static const String inviteEmailHasAccount =
      'اس ای میل سے پہلے ہی اکاؤنٹ موجود ہے۔ "داخل ہوں" سے اپنے اکاؤنٹ میں داخل ہوں۔';
  static const String staffAccountCreated = 'آپ کا اکاؤنٹ بن گیا ہے۔';

  // The register, the accounts, and the difference between them
  static const String registerSection = 'کورس رجسٹر — کل';
  static const String accountsSection = 'اکاؤنٹس — فعال';
  // Group figures, so the plural forms: فضلاء and فاضلات.
  static const String totalMale = 'کل فضلاء';
  static const String totalFemale = 'کل فاضلات';
  static const String totalBoth = 'کل فضلاء و فاضلات';
  static const String activeMale = 'فعال فضلاء';
  static const String activeFemale = 'فعال فاضلات';
  static const String activeBoth = 'فعال فضلاء و فاضلات';
  static const String genderNotRecorded = 'جنس درج نہیں';
  static const String accountsWithoutRecord = 'رجسٹر سے غیر منسلک اکاؤنٹ';
  static const String countsExplained =
      'کل: کورس رجسٹر کے تمام اہل ریکارڈ۔ فعال: وہ ریکارڈ جن کا ایپ اکاؤنٹ بن چکا ہے۔';
  static const String participantGender = 'جنس';
  static const String genderMale = 'فاضل';
  static const String genderFemale = 'فاضلہ';
  static const String genderUnknown = 'درج نہیں';
  static const String setGender = 'جنس درج کریں';
  static const String genderUpdated = 'جنس درج کر دی گئی ہے۔';


  // Evidence and feedback, with the people they belong to
  static const String submittedBy = 'جمع کروانے والے';
  static const String submittedOn = 'جمع کروانے کی تاریخ';
  static const String mentorLabel = 'مربی';
  static const String mentorNotRecorded = 'مربی درج نہیں';
  static const String feedbackAndGuidance = 'مربی کی رائے اور رہنمائی';
  static const String noFeedbackYet = 'ابھی کوئی رائے درج نہیں';
  static const String searchEvidenceHint = 'نام یا کارگزاری سے تلاش کریں';

  // کمیونٹی بورڈ
  static const String communityBoard = 'کمیونٹی بورڈ';
  static const String communityBoardSubtitle =
      'فضلاء و فاضلات کی مشترکہ سرگرمیاں، حوصلہ افزائی اور مفید تجربات۔';
  static const String communityAll = 'تمام سرگرمیاں';
  static const String communityKarguzari = 'کارگزاریاں';
  static const String communityPosts = 'مربیوں کی پوسٹس';
  static const String communityEmpty = 'ابھی کوئی نئی سرگرمی موجود نہیں';
  static const String communityLoadMore = 'مزید دیکھیں';

  // عوامی تبصرہ، اور اس سے بالکل الگ: نجی جائزہ
  static const String publicComment = 'عوامی تبصرہ';
  static const String publicCommentNote =
      'یہ تبصرہ کمیونٹی بورڈ پر سب کو نظر آئے گا۔';
  static const String publicCommentHint = 'حوصلہ افزائی یا مفید رائے لکھیں';
  static const String addComment = 'تبصرہ شامل کریں';
  static const String commentAdded = 'آپ کا تبصرہ شامل ہو گیا ہے۔';
  static const String noComments = 'ابھی کوئی تبصرہ نہیں';
  static const String privateReview = 'نجی جائزہ';
  static const String privateReviewNote =
      'نجی جائزہ صرف متعلقہ فاضل / فاضلہ، ان کے مربی اور منتظم کو نظر آتا ہے۔ کمیونٹی بورڈ پر کبھی نہیں۔';

  // مربیوں کی پوسٹس
  static const String newPost = 'نئی پوسٹ';
  static const String postTitle = 'عنوان';
  static const String postBody = 'تفصیل';
  static const String postPublished = 'پوسٹ شائع ہو گئی ہے۔';
  static const String hideFromBoard = 'بورڈ سے چھپائیں';
  static const String hidePostConfirm =
      'یہ پوسٹ کمیونٹی بورڈ سے ہٹا دی جائے گی۔ کیا آپ متفق ہیں؟';
  static const String hiddenFromBoard = 'بورڈ سے چھپا دیا گیا ہے۔';

  // کارگزاری کو کمیونٹی بورڈ پر شیئر کرنا
  static const String shareToCommunity = 'کمیونٹی بورڈ پر شیئر کریں';
  static const String shareToCommunityNote =
      'شیئر کرنے پر آپ کا نام، کارگزاری کا عنوان، تفصیل، زمرہ اور تاریخ سب کو نظر آئے گی۔ نجی جائزہ کبھی نظر نہیں آتا۔';
  static const String sharedToCommunity =
      'کارگزاری کمیونٹی بورڈ پر شیئر کر دی گئی ہے۔';
  static const String unsharedFromCommunity =
      'کارگزاری کمیونٹی بورڈ سے ہٹا دی گئی ہے۔';

  // کارگزاری اپ لوڈ
  static const String uploadWorkPhotosNote =
      'براہِ کرم کام کی تصاویر اپ لوڈ کریں، اپنی تصاویر نہیں۔';

  // Changing a role
  static const String confirmRoleChange = 'حیثیت کی تبدیلی';
  static const String newRole = 'نئی حیثیت';
  static const String roleChangeEndsMentoring =
      'ان کے زیرِ رہنمائی تمام فضلاء و فاضلات کی تفویض ختم ہو جائے گی۔';
  static const String roleChangeEndsSupervision =
      'ان کے مربی کی تفویض ختم ہو جائے گی۔';
  static const String adminRoleWarning =
      'منتظم کو پورے نظام اور تمام ریکارڈ تک رسائی ہوتی ہے۔';
  static const String noRoleYet = 'کوئی حیثیت مقرر نہیں';

  // ---------------------------------------------------------------------
  // Kar-guzari detail and the follow-up cycle
  // ---------------------------------------------------------------------
  static const String activityTypeLabel = 'سرگرمی کی نوعیت';
  static const String activityTypeHint = 'مثلاً: ورکشاپ، درس، ویبینار، سیمینار';
  static const String locationLabel = 'مقام';
  static const String organisationLabel = 'ادارہ یا معاشرتی حلقہ';
  static const String beneficiariesLabel = 'مستفید افراد کی تعداد';
  static const String learningAppliedLabel = 'کورس سے کیا عملی طور پر نافذ کیا';
  static const String impactLabel = 'عملی اثر';
  static const String resultsLabel = 'نتائج';
  static const String challengesLabel = 'درپیش مشکلات';
  static const String futurePlanLabel = 'آئندہ کا منصوبہ';
  static const String moreDetails = 'مزید تفصیل (اختیاری)';
  static const String followUpTitle = 'اگلی کارگزاری';
  static const String followUpDue = 'مقررہ تاریخ';
  static const String followUpOverdue = 'مقررہ وقت گزر چکا ہے';
  static const String followUpDaysLeft = 'باقی دن';
  static const String followUpSubmitted = 'جمع شدہ کارگزاریاں';
  static const String followUpNone = 'ابھی تک کوئی کارگزاری جمع نہیں کی گئی۔';
  static const String daysUnit = 'دن';
  static const String monthsUnit = 'ماہ';

  // ---------------------------------------------------------------------
  // System settings and recognition rules
  // ---------------------------------------------------------------------
  static const String systemSettings = 'نظام کی ترتیبات';
  static const String followUpIntervalLabel = 'کارگزاری کا وقفہ';
  static const String followUpIntervalHelp =
      'ہر کتنے ماہ بعد فضلاء و فاضلات سے کارگزاری طلب کی جائے۔';
  static const String settingSaved = 'ترتیب محفوظ کر دی گئی ہے۔';
  static const String recognitionRules = 'اعزازات کے اصول';
  static const String addRecognitionRule = 'نیا اصول شامل کریں';
  static const String ruleTitle = 'اعزاز کا عنوان';
  static const String ruleDetail = 'وضاحت (اختیاری)';
  static const String ruleCriterion = 'کس بنیاد پر';
  static const String ruleThreshold = 'مطلوبہ تعداد';
  static const String ruleAdded = 'اصول شامل کر دیا گیا ہے۔';
  static const String noRulesYet =
      'ابھی کوئی اصول مقرر نہیں۔ جب تک اصول شامل نہ ہو، کوئی اعزاز خودکار طور پر نہیں دیا جائے گا۔';
  static const String criterionSubmitted = 'جمع شدہ کارگزاریاں';
  static const String criterionReviewed = 'مکمل جائزہ شدہ کارگزاریاں';
  static const String criterionOnTime = 'بروقت کارگزاریاں';
  static const String criterionEvidence = 'شامل کردہ ثبوت';
  static const String requestRevision = 'اصلاح کے لیے واپس بھیجیں';
  static const String revisionRequested =
      'کارگزاری اصلاح کے لیے واپس بھیج دی گئی ہے۔';
  static const String relatedReports = 'متعلقہ کارگزاریاں';
  static const String noEvidenceForReport =
      'اس کارگزاری کے ساتھ کوئی ثبوت منسلک نہیں۔';
  static const String noReportsForActivity =
      'اس سرگرمی کے لیے ابھی کوئی کارگزاری درج نہیں کی گئی۔';
  static const String noEvidenceForActivity =
      'اس سرگرمی کی کارگزاریوں کے ساتھ ابھی کوئی ثبوت منسلک نہیں۔';
  static const String evidenceManagement = 'ثبوتوں کا انتظام';
  static const String showPassword = 'پاس ورڈ دکھائیں';
  static const String hidePassword = 'پاس ورڈ چھپائیں';
  static const String offlineNotice =
      'انٹرنیٹ دستیاب نہیں۔ آپ کا اکاؤنٹ کھلا ہے، معلومات پرانی ہو سکتی ہیں۔';

  // ---------------------------------------------------------------------
  // Important links
  // ---------------------------------------------------------------------
  static const String importantLinks = 'اہم لنکس';
  static const String addLink = 'نیا لنک شامل کریں';
  static const String linkTitle = 'لنک کا عنوان';
  static const String linkUrl = 'لنک کا پتہ (URL)';
  static const String linkDetail = 'مختصر وضاحت (اختیاری)';
  static const String linkAdded = 'لنک شامل کر دیا گیا ہے۔';
  static const String noLinksYet =
      'ابھی کوئی لنک شامل نہیں کیا گیا۔ منتظم اسے شامل کرے گا۔';
  static const String couldNotOpenLink = 'لنک کھولا نہیں جا سکا۔';
  static const String couldNotOpenEvidence = 'ثبوت کھولا نہیں جا سکا۔';
  static const String linkMustBeHttp =
      'لنک http:// یا https:// سے شروع ہونا چاہیے۔';
  // One person, naming themselves or one record: the singular forms.
  static const String maleLabel = 'فاضل';
  static const String femaleLabel = 'فاضلہ';

  // The same people counted as a group: the plural forms.
  static const String malePlural = 'فضلاء';
  static const String femalePlural = 'فاضلات';
  static const String unassignedWifaq = 'غیر منسلک وفاق';
  static const String unassignedInstitute = 'ادارہ درج نہیں';
  static const String noGraduatesHere = 'یہاں ابھی کوئی فاضل / فاضلہ نہیں۔';

  // ---------------------------------------------------------------------
  // Activity administration
  // ---------------------------------------------------------------------
  static const String manageActivities = 'عملی سرگرمیوں کا انتظام';
  static const String addActivity = 'نئی عملی سرگرمی شامل کریں';
  static const String activityTitle = 'سرگرمی کا عنوان';
  static const String activityDetail = 'سرگرمی کی تفصیل';
  static const String activitySteps = 'کل مراحل';
  static const String activityAdded = 'عملی سرگرمی شامل کر دی گئی ہے۔';
  static const String activityRetired = 'سرگرمی غیر فعال کر دی گئی ہے۔';
  static const String activityRestored = 'سرگرمی دوبارہ فعال کر دی گئی ہے۔';
  static const String retireActivity = 'غیر فعال کریں';
  static const String restoreActivity = 'دوبارہ فعال کریں';

  // ---------------------------------------------------------------------
  // Workshop registration gate
  // ---------------------------------------------------------------------
  // ---------------------------------------------------------------------
  // Course registration
  // ---------------------------------------------------------------------
  static const String courseGateTitle = 'کورس کی تصدیق';
  static const String courseGateSubtitle =
      'اکاؤنٹ بنانے کے لیے تین ماہی کورس کی رقم التسجیل درج کریں۔';
  static const String registrationNumber = 'رقم التسجیل';
  static const String hintRegistrationNumber = 'مثلاً: MD-2026/001';
  static const String verifyNumber = 'تصدیق کریں';
  static const String verifying = 'آپ کی معلومات کی تصدیق کی جا رہی ہے...';
  static const String verifiedAs = 'تصدیق ہو گئی';
  static const String verifiedActivated =
      'آپ کی معلومات کی کامیابی سے تصدیق ہو گئی ہے۔ آپ کا پروفائل فعال کر دیا گیا ہے۔';
  static const String changeNumber = 'نمبر تبدیل کریں';
  static const String regNotFound =
      'یہ رقم التسجیل ہمارے ریکارڈ میں موجود نہیں ہے۔';
  static const String regNameMismatch =
      'درج کردہ نام ہمارے ریکارڈ سے مطابقت نہیں رکھتا۔';
  static const String regNotEligible =
      'یہ رقم التسجیل اکاؤنٹ بنانے کے لیے اہل نہیں ہے۔ منتظم سے رابطہ کریں۔';
  static const String regAlreadyUsed =
      'اس رقم التسجیل کے ساتھ پہلے سے ایک اکاؤنٹ موجود ہے۔';
  static const String regRequired = 'رقم التسجیل درج کرنا ضروری ہے۔';
  static const String publicSignupClosed =
      'عام رجسٹریشن دستیاب نہیں۔ صرف کورس کے شرکاء اکاؤنٹ بنا سکتے ہیں۔';
  static const String selectCategory = 'اپنی حیثیت منتخب کریں';

  // ---------------------------------------------------------------------
  // Course participant administration
  // ---------------------------------------------------------------------
  static const String manageParticipants = 'کورس کے شرکاء کا انتظام';
  static const String addParticipant = 'نیا شریک شامل کریں';
  static const String importParticipants = 'کورس کے شرکاء کی فائل درآمد کریں';
  /// The person's own name. Kept apart from [labelFatherName], because the
  /// register's own column once held both and an account could not be created
  /// unless the two were typed exactly as that one column happened to hold
  /// them.
  static const String participantName = 'نام';
  static const String participantFatherName = 'ولدیت';
  static const String hintFatherNameOptional = 'اختیاری';
  static const String courseStartMonth = 'داخلہ ماہ';
  static const String courseCompletionMonth = 'فراغت ماہ';
  static const String eligibleForApp = 'اکاؤنٹ کے لیے اہل';
  static const String accountCreated = 'اکاؤنٹ بن چکا ہے';
  static const String accountNotCreated = 'اکاؤنٹ نہیں بنا';
  static const String participantAdded = 'شریک شامل کر دیا گیا ہے۔';
  static const String participantUpdated = 'ریکارڈ تبدیل کر دیا گیا ہے۔';
  static const String noParticipantsYet = 'ابھی کوئی شریک درج نہیں';
  static const String fileFormatHint =
      'فائل کے کالم: رقم التسجیل، نام، ولدیت، داخلہ ماہ، فراغت ماہ';
  static const String missingColumnsError =
      'فائل میں ضروری کالم موجود نہیں۔ رقم التسجیل اور نام لازمی ہیں۔';
  static const String importPreviewTitle = 'درآمد کا جائزہ';
  static const String totalRecords = 'کل ریکارڈ';
  static const String validRecords = 'درست ریکارڈ';
  static const String duplicateRecords = 'نقل ریکارڈ';
  static const String invalidRecords = 'نامکمل ریکارڈ';
  static const String confirmImport = 'درآمد شروع کریں';
  static const String importDone = 'درآمد مکمل';
  static const String nothingToImport = 'درآمد کے لیے کوئی نیا ریکارڈ نہیں۔';
  static const String importHistory = 'درآمد کی تاریخ';
  static const String noImportsYet = 'ابھی کوئی فائل درآمد نہیں کی گئی۔';

  // ---------------------------------------------------------------------
  // Empty states, one per section so the wording is specific
  // ---------------------------------------------------------------------
  static const String noPendingTasks = 'کوئی زیرِ التوا کام نہیں';
  static const String noGuidanceYet = 'ابھی کوئی رہنمائی موصول نہیں ہوئی';
  static const String noRecognitionsYet = 'ابھی کوئی اعزاز حاصل نہیں ہوا';
  static const String noFollowUpYet = 'کوئی پیروی مقرر نہیں';
  static const String noNotificationsYet = 'کوئی اطلاع موجود نہیں';
  static const String noGraduatesYet = 'ابھی کوئی فاضل / فاضلہ تفویض نہیں';
  static const String noReportsYet = 'ابھی کوئی کارگزاری موجود نہیں';
  static const String noEvidenceYet = 'ابھی کوئی ثبوت منسلک نہیں';
  static const String noEvaluationsYet = 'ابھی کوئی جائزہ مکمل نہیں ہوا';
  static const String noRecordsYet = 'ابھی کوئی اندراج موجود نہیں';

  static const String saveSuccess = 'تبدیلیاں محفوظ کر دی گئی ہیں۔';
  static const String submitSuccess = 'کامیابی سے جمع کروا دیا گیا ہے۔';
  static const String awaitingAccess =
      'آپ کا اکاؤنٹ بن چکا ہے۔ منتظم کی جانب سے حیثیت مقرر ہوتے ہی رسائی مل جائے گی۔';

  // ---------------------------------------------------------------------
  // Greetings and shared headings
  // ---------------------------------------------------------------------
  static const String dashboard = 'ڈیش بورڈ';
  static const String profile = 'میرا پروفائل';
  static const String notifications = 'اطلاعات';
  static const String settings = 'ترتیبات';
  static const String reports = 'کارگزاری';
  static const String evidence = 'ثبوت';
  static const String evaluation = 'جائزہ';
  static const String evaluations = 'جائزے';
  static const String recognition = 'اعزاز';
  static const String recognitions = 'اعزازات';
  static const String selectRole = 'اپنی حیثیت منتخب کریں';
  static const String selectRoleDetail =
      'ابتدائی نمونے کے لیے کوئی ایک حیثیت منتخب کریں۔ بعد میں یہ حصہ باقاعدہ '
      'داخلے سے تبدیل کر دیا جائے گا۔';

  // ---------------------------------------------------------------------
  // Bottom navigation
  // ---------------------------------------------------------------------
  static const String navHome = 'ہوم';
  static const String navMyProfile = 'میرا پروفائل';
  static const String navLinks = 'اہم لنکس';
  static const String navDashboard = 'ڈیش بورڈ';
  static const String navReports = 'کارگزاری';
  static const String navEvidence = 'ثبوت';
  static const String navNotifications = 'اطلاعات';
  static const String navProfile = 'پروفائل';
  static const String navGraduates = 'زیرِ رہنمائی';
  static const String navReviews = 'جائزے';
  static const String navMentors = 'مربی';

  // ---------------------------------------------------------------------
  // Graduate dashboard
  // ---------------------------------------------------------------------
  static const String myJourney = 'میرا عملی سفر';
  static const String trainingStage = 'تربیتی مرحلہ';
  static const String currentStanding = 'موجودہ حیثیت';
  static const String pendingTasks = 'میرے زیرِ التوا کام';

  /// Shorter form used inside statistic tiles, where the full heading
  /// would not fit.
  static const String pendingTasksShort = 'زیرِ التوا کام';
  static const String quickActions = 'فوری رسائی';
  static const String mentorGuidance = 'مربی کی رہنمائی';
  static const String recognitionSection = 'اعزازات اور حوصلہ افزائی';
  static const String followUp = 'اگلی پیروی';
  static const String recentNotifications = 'حالیہ اطلاعات';
  static const String practicalActivities = 'عملی سرگرمیاں';
  static const String myReports = 'میری کارگزاری';
  static const String evaluationResults = 'جائزے کے نتائج';
  static const String nextStep = 'اگلا مرحلہ';
  static const String completedSteps = 'مکمل مراحل';

  // ---------------------------------------------------------------------
  // Mentor dashboard
  // ---------------------------------------------------------------------
  static const String myGraduates = 'میرے زیرِ رہنمائی فضلاء و فاضلات';
  static const String newReports = 'نئی کارگزاریاں';
  static const String awaitingReview = 'جائزے کے لیے منتظر';
  static const String underReview = 'زیرِ جائزہ';
  static const String completedReviews = 'مکمل جائزے';
  static const String lateSubmissions = 'تاخیر سے جمع ہونے والی';
  static const String pendingReviews = 'زیرِ التوا جائزے';
  static const String recentGraduates = 'حالیہ فضلاء و فاضلات';
  static const String graduateName = 'فاضل / فاضلہ کا نام';
  static const String instituteName = 'ادارے کا نام';
  static const String reportStatus = 'کارگزاری کی حیثیت';
  static const String graduateDetails = 'فاضل / فاضلہ کی تفصیلات';
  static const String reportDetails = 'کارگزاری کی تفصیلات';
  static const String reportReview = 'کارگزاری کا جائزہ';
  static const String assessment = 'جانچ';

  // ---------------------------------------------------------------------
  // Admin dashboard
  // ---------------------------------------------------------------------
  static const String totalGraduates = 'کل فضلاء و فاضلات';
  static const String activeGraduates = 'فعال فضلاء و فاضلات';
  static const String totalMentors = 'کل مربی';
  static const String pendingReports = 'زیرِ التوا کارگزاریاں';
  static const String managementAreas = 'انتظامی حصے';
  static const String graduateManagement = 'فضلاء و فاضلات کا انتظام';
  static const String mentorManagement = 'مربیوں کا انتظام';
  static const String wifaqManagement = 'وفاق کا انتظام';
  static const String courses = 'کورسز';
  static const String assignments = 'ذمہ داریاں';
  static const String allReports = 'کارگزاریاں';
  static const String standards = 'جانچ کے معیارات';
  static const String graduates = 'فضلاء و فاضلات';
  static const String mentors = 'مربی';
  static const String wifaqs = 'وفاق';
  static const String systemOverview = 'نظام کا خلاصہ';

  // ---------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------
  static const String signIn = 'داخل ہوں';
  static const String signUp = 'اکاؤنٹ بنائیں';
  static const String signOut = 'باہر نکلیں';
  static const String signInTitle = 'اپنے اکاؤنٹ میں داخل ہوں';
  static const String signUpTitle = 'نیا اکاؤنٹ بنائیں';
  static const String signInSubtitle =
      'اپنا ای میل پتہ اور پاس ورڈ درج کریں۔';
  static const String signUpSubtitle =
      'اندراج کے بعد آپ کو فاضل / فاضلہ کی حیثیت دی جائے گی۔';
  static const String noAccountYet = 'اکاؤنٹ نہیں ہے؟';
  static const String alreadyHaveAccount = 'پہلے سے اکاؤنٹ موجود ہے؟';
  static const String labelPassword = 'پاس ورڈ';
  static const String labelConfirmPassword = 'پاس ورڈ کی تصدیق کریں';
  static const String hintPassword = 'کم از کم آٹھ حروف';
  static const String forgotPassword = 'پاس ورڈ بھول گئے؟';
  static const String resetLinkSent =
      'پاس ورڈ تبدیل کرنے کا لنک آپ کے ای میل پر بھیج دیا گیا ہے۔';
  static const String signUpSuccess =
      'اکاؤنٹ بن گیا ہے۔ اگر تصدیقی ای میل موصول ہو تو اس کی تصدیق کریں۔';
  static const String signOutConfirm = 'کیا آپ واقعی باہر نکلنا چاہتے ہیں؟';
  static const String validationPassword =
      'پاس ورڈ کم از کم آٹھ حروف کا ہونا چاہیے۔';
  static const String validationPasswordMatch = 'دونوں پاس ورڈ یکساں نہیں ہیں۔';
  static const String emailNotConfirmed =
      'آپ کا ای میل پتہ ابھی تصدیق شدہ نہیں ہے۔ تصدیقی پیغام دیکھیں۔';
  static const String resendConfirmation = 'تصدیقی پیغام دوبارہ بھیجیں';
  static const String confirmationResent =
      'تصدیقی پیغام دوبارہ بھیج دیا گیا ہے۔ اپنا ای میل دیکھیں۔';

  // A پاس ورڈ بھول گئے؟ link opens the application here.
  static const String newPasswordTitle = 'نیا پاس ورڈ مقرر کریں';
  static const String newPasswordSubtitle =
      'اپنا نیا پاس ورڈ دو بار لکھیں تاکہ آپ دوبارہ داخل ہو سکیں۔';
  static const String savePassword = 'پاس ورڈ محفوظ کریں';
  static const String passwordChanged =
      'آپ کا پاس ورڈ تبدیل ہو گیا ہے۔';
  static const String networkError =
      'انٹرنیٹ سے رابطہ نہیں ہو سکا۔ اپنا کنکشن دیکھ کر دوبارہ کوشش کریں۔';
  static const String tooManyAttempts =
      'بہت زیادہ کوششیں۔ کچھ دیر بعد دوبارہ کوشش کریں۔';
  static const String authFailed =
      'ای میل یا پاس ورڈ درست نہیں ہے۔';
  static const String noRoleAssigned =
      'آپ کے اکاؤنٹ کے لیے ابھی کوئی حیثیت مقرر نہیں کی گئی۔ براہِ کرم منتظم سے رابطہ کریں۔';
  static const String sessionLoading = 'آپ کی معلومات حاصل کی جا رہی ہیں...';

  // ---------------------------------------------------------------------
  // Form section headings
  // ---------------------------------------------------------------------
  static const String personalDetails = 'ذاتی معلومات';
  static const String contactDetails = 'رابطہ کی تفصیلات';

  // ---------------------------------------------------------------------
  // Form labels
  // ---------------------------------------------------------------------
  static const String labelName = 'اپنا نام درج کریں';
  static const String labelFatherName = 'ولدیت';
  static const String labelCity = 'شہر کا نام';
  static const String labelInstitute = 'ادارے کا نام';
  static const String labelPhone = 'رابطہ نمبر';
  static const String labelEmail = 'ای میل پتہ';
  static const String labelReportTitle = 'کارگزاری کا عنوان';
  static const String labelReportDetail = 'کارگزاری کی تفصیل';
  static const String labelSelectActivity = 'عملی سرگرمی کا انتخاب کریں';
  static const String labelAddImages = 'تصاویر شامل کریں';
  static const String labelAddVideo = 'ویڈیو شامل کریں';
  static const String labelAddDocument = 'دستاویز شامل کریں';
  static const String labelWifaq = 'وفاق کا نام';
  static const String labelStage = 'تربیتی مرحلہ';
  static const String labelReviewNote = 'جائزے کا تبصرہ';

  // ---------------------------------------------------------------------
  // Hints
  // ---------------------------------------------------------------------
  static const String hintName = 'اپنا پورا نام';
  static const String hintCity = 'مثلاً: لاہور';
  static const String hintPhone = 'مثلاً: 03001234567';
  static const String hintEmail = 'مثلاً: name@example.com';
  static const String hintReportDetail =
      'اپنی عملی سرگرمی کی مکمل تفصیل یہاں تحریر کریں۔';
  static const String hintSearchGraduate = 'فاضل / فاضلہ کا نام تلاش کریں';
  static const String hintSearchReport = 'کارگزاری تلاش کریں';
  static const String hintSearchGeneral = 'تلاش کریں';

  // ---------------------------------------------------------------------
  // Validation messages
  // ---------------------------------------------------------------------
  static const String validationRequired = 'یہ خانہ بھرنا ضروری ہے۔';
  static const String validationInvalid = 'براہِ کرم درست معلومات درج کریں۔';
  static const String validationPhone = 'رابطہ نمبر درست نہیں ہے۔';
  static const String validationReportDetail = 'کارگزاری کی تفصیل درج کریں۔';
  static const String validationFileRequired =
      'براہِ کرم ایک فائل منتخب کریں۔';
  static const String validationFileSize =
      'فائل کا حجم مقررہ حد سے زیادہ ہے۔';
  static const String validationEmail = 'ای میل پتہ درست نہیں ہے۔';
}
