import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/app_preferences.dart';

/// Class cung cấp từ điển song ngữ (Tiếng Việt & Tiếng Anh) cho toàn bộ ứng dụng SMGS Mobile.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(Locale(AppPreferences.instance.language));
  }

  static AppLocalizations get current =>
      AppLocalizations(Locale(AppPreferences.instance.language));

  bool get isEn => locale.languageCode == 'en';

  // ==========================================
  // NAVIGATION BOTTOM BAR (THANH ĐIỀU HƯỚNG DƯỚI)
  // ==========================================
  String get tabHome => isEn ? 'Home' : 'Trang chủ';
  String get tabExplore => isEn ? 'Explore' : 'Khám phá';
  String get tabScan => isEn ? 'Scan' : 'Quét mã';
  String get tabJourneys => isEn ? 'Journeys' : 'Hành trình';
  String get tabProfile => isEn ? 'Profile' : 'Cá nhân';

  // ==========================================
  // 1. CHUNG & HÀNH ĐỘNG CƠ BẢN (COMMON ACTIONS)
  // ==========================================
  String get appTitle => isEn ? 'SMGS • Museum Handbook' : 'SMGS • Cẩm nang bảo tàng';
  String get ok => isEn ? 'OK' : 'Đồng ý';
  String get cancel => isEn ? 'Cancel' : 'Hủy';
  String get confirm => isEn ? 'Confirm' : 'Xác nhận';
  String get close => isEn ? 'Close' : 'Đóng';
  String get save => isEn ? 'Save' : 'Lưu';
  String get retry => isEn ? 'Retry' : 'Thử lại';
  String get delete => isEn ? 'Delete' : 'Xóa';
  String get search => isEn ? 'Search' : 'Tìm kiếm';
  String get loading => isEn ? 'Loading...' : 'Đang tải...';
  String get error => isEn ? 'An error occurred' : 'Có lỗi xảy ra';
  String get errorGeneric => isEn ? 'Unable to load data. Please try again.' : 'Không thể tải dữ liệu. Vui lòng thử lại.';
  String get emptyData => isEn ? 'No data available' : 'Chưa có dữ liệu';
  String get seeAll => isEn ? 'See all' : 'Xem tất cả';
  String get viewDetails => isEn ? 'View details' : 'Xem chi tiết';
  String get back => isEn ? 'Back' : 'Quay lại';
  String get filter => isEn ? 'Filter' : 'Bộ lọc';
  String get all => isEn ? 'All' : 'Tất cả';
  String get apply => isEn ? 'Apply' : 'Áp dụng';
  String get reset => isEn ? 'Reset' : 'Đặt lại';
  String get success => isEn ? 'Success' : 'Thành công';
  String get failed => isEn ? 'Failed' : 'Thất bại';
  String get next => isEn ? 'Next' : 'Tiếp theo';
  String get previous => isEn ? 'Previous' : 'Trước đó';
  String get finish => isEn ? 'Finish' : 'Hoàn thành';

  // ==========================================
  // 2. MÀN HÌNH CHÍNH (HOME SCREEN & SECTIONS)
  // ==========================================
  String get greetingMorning => isEn ? 'Good morning,' : 'Chào buổi sáng,';
  String get greetingAfternoon => isEn ? 'Good afternoon,' : 'Chào buổi chiều,';
  String get greetingEvening => isEn ? 'Good evening,' : 'Chào buổi tối,';
  String get greetingDefault => isEn ? 'Welcome,' : 'Xin chào,';
  String get visitorWelcome => isEn ? 'Heritage Explorer' : 'Khách tham quan';

  String get searchPlaceholder => isEn
      ? 'Search museums, artifacts, dynasties...'
      : 'Tìm bảo tàng, hiện vật, triều đại...';

  String get handbookButton => isEn ? 'Handbook' : 'Cẩm nang tham quan';
  String get visitorGuideTitle => isEn ? 'Visitor Guide & Code of Conduct' : 'Cẩm nang tham quan bảo tàng';
  String get visitorGuideSubtitle => isEn ? 'Tips, etiquette and navigation assistance' : 'Nội quy, hướng dẫn và thông tin tiện ích';

  String get quickActionsTitle => isEn ? 'Quick Access' : 'Truy cập nhanh';
  String get scanQrCode => isEn ? 'Scan Artifact' : 'Quét hiện vật';
  String get findNearestMuseum => isEn ? 'Nearby Museums' : 'Bảo tàng gần bạn';
  String get interactiveMap => isEn ? 'Heritage Map' : 'Bản đồ di sản';
  String get audioGuideQuick => isEn ? 'Audio Tour' : 'Thuyết minh số';

  String get featuredMuseums => isEn ? 'Featured Museums' : 'Bảo tàng nổi bật';
  String get featuredMuseumsSubtitle => isEn ? 'Iconic cultural institutions in Vietnam' : 'Những điểm đến văn hóa tiêu biểu tại Việt Nam';

  String get iconicArtifacts => isEn ? 'Iconic Artifacts' : 'Hiện vật tiêu biểu';
  String get iconicArtifactsSubtitle => isEn ? 'National treasures with timeless stories' : 'Bảo vật quốc gia mang đậm dấu ấn lịch sử';

  String get journeysAndTours => isEn ? 'Journeys & Tours' : 'Hành trình & Tour';
  String get journeysSubtitle => isEn ? 'Specially curated exploration pathways' : 'Lộ trình tham quan được thiết kế chọn lọc';

  String get dailyChallenge => isEn ? 'Heritage Challenge' : 'Thử thách di sản';
  String get dailyChallengeSubtitle => isEn ? 'Answer quick trivia and earn badges' : 'Khám phá kiến thức lịch sử & nhận huy hiệu';
  String get playDailyQuiz => isEn ? 'Start Quiz' : 'Bắt đầu';
  String get quizReadyPrompt => isEn ? 'Test your knowledge on artifacts today!' : 'Thử tài hiểu biết về các bảo vật hôm nay!';

  // ==========================================
  // 3. KHÁM PHÁ & BẢN ĐỒ (EXPLORE & DISCOVERY)
  // ==========================================
  String get exploreTitle => isEn ? 'Discover Museums' : 'Khám phá bảo tàng';
  String get exploreSubtitle => isEn ? 'Browse through Vietnam’s rich cultural network' : 'Mạng lưới bảo tàng và di sản trên toàn quốc';
  String get searchMuseumHint => isEn ? 'Search by name, province, or era...' : 'Tìm theo tên, tỉnh thành hoặc thời kỳ...';

  String get categoryAll => isEn ? 'All' : 'Tất cả';
  String get categoryHistory => isEn ? 'History' : 'Lịch sử';
  String get categoryArt => isEn ? 'Fine Arts' : 'Mỹ thuật';
  String get categoryCulture => isEn ? 'Ethnology' : 'Dân tộc học';
  String get categoryNature => isEn ? 'Nature & Science' : 'Thiên nhiên';
  String get categoryMilitary => isEn ? 'Military' : 'Quân sự';

  String get filterNearby => isEn ? 'Nearby' : 'Gần bạn';
  String get filterOpenNow => isEn ? 'Open now' : 'Đang mở cửa';
  String get filterPopular => isEn ? 'Popular' : 'Nổi bật nhất';
  String get filterNorth => isEn ? 'Northern' : 'Miền Bắc';
  String get filterCentral => isEn ? 'Central' : 'Miền Trung';
  String get filterSouth => isEn ? 'Southern' : 'Miền Nam';

  String get openStatusOpen => isEn ? 'Open' : 'Đang mở cửa';
  String get openStatusClosed => isEn ? 'Closed' : 'Đã đóng cửa';
  String get distanceUnit => isEn ? 'km away' : 'km';
  String get viewOnMap => isEn ? 'View on map' : 'Xem trên bản đồ';
  String get noMuseumsFound => isEn ? 'No museums match your criteria' : 'Không tìm thấy bảo tàng phù hợp';

  // ==========================================
  // 4. CHI TIẾT BẢO TÀNG (MUSEUM DETAIL)
  // ==========================================
  String get tabOverview => isEn ? 'Overview' : 'Tổng quan';
  String get tabArtifacts => isEn ? 'Artifacts' : 'Hiện vật';
  String get tabIndoorMap => isEn ? 'Floor Map' : 'Bản đồ';
  String get tabServices => isEn ? 'Amenities' : 'Tiện ích';

  String get museumAbout => isEn ? 'Introduction' : 'Giới thiệu';
  String get museumHistory => isEn ? 'Historical Background' : 'Dấu ấn lịch sử';
  String get museumAddress => isEn ? 'Address' : 'Địa chỉ';
  String get museumHours => isEn ? 'Opening Hours' : 'Giờ mở cửa';
  String get museumTicket => isEn ? 'Ticket Pricing' : 'Giá vé tham quan';
  String get ticketFree => isEn ? 'Free Admission' : 'Miễn phí';
  String get ticketStandard => isEn ? 'Standard' : 'Tiêu chuẩn';

  String get indoorGuideCTA => isEn ? 'Indoor Navigation' : 'Chỉ đường trong nhà';
  String get startExploreCTA => isEn ? 'Start Exploring' : 'Bắt đầu khám phá';
  String get viewAllArtifacts => isEn ? 'View all artifacts' : 'Xem toàn bộ hiện vật';
  String get totalArtifactsCount => isEn ? 'artifacts on display' : 'hiện vật trưng bày';

  String get serviceRestroom => isEn ? 'Restrooms' : 'Nhà vệ sinh';
  String get serviceElevator => isEn ? 'Elevator' : 'Thang máy';
  String get serviceTicketCounter => isEn ? 'Ticket Booth' : 'Quầy vé';
  String get serviceGiftShop => isEn ? 'Souvenir Shop' : 'Quà lưu niệm';
  String get serviceCafe => isEn ? 'Café & Refreshments' : 'Cà phê & Giải khát';
  String get serviceAudioGuide => isEn ? 'Audio Guide Counter' : 'Thiết bị thuyết minh';
  String get serviceLocker => isEn ? 'Luggage Locker' : 'Gửi đồ miễn phí';

  // ==========================================
  // 5. HIỆN VẬT & 3D & AUDIO GUIDE (ARTIFACTS)
  // ==========================================
  String get artifactDetailTitle => isEn ? 'Artifact Information' : 'Thông tin hiện vật';
  String get audioGuide => isEn ? 'Audio Guide' : 'Thuyết minh giọng đọc';
  String get playAudio => isEn ? 'Listen to Story' : 'Nghe thuyết minh';
  String get pauseAudio => isEn ? 'Pause Audio' : 'Tạm dừng';
  String get stopAudio => isEn ? 'Stop' : 'Dừng';
  String get speedLabel => isEn ? 'Speed' : 'Tốc độ';

  String get model3DView => isEn ? 'Interactive 3D Model' : 'Mô hình 3D tương tác';
  String get rotateHint => isEn ? 'Drag to rotate • Pinch to zoom' : 'Chạm xoay • Thu phóng 360°';
  String get arViewCTA => isEn ? 'View in AR' : 'Xem trong không gian thực';

  String get artifactNarrative => isEn ? 'Historical Narrative' : 'Câu chuyện lịch sử';
  String get artifactSpecs => isEn ? 'Specifications' : 'Thông số hiện vật';
  String get specEra => isEn ? 'Period / Dynasty' : 'Niên đại / Triều đại';
  String get specOrigin => isEn ? 'Discovery Origin' : 'Nơi phát hiện';
  String get specMaterial => isEn ? 'Material' : 'Chất liệu';
  String get specDimensions => isEn ? 'Dimensions' : 'Kích thước';
  String get nationalTreasure => isEn ? 'National Treasure' : 'Bảo vật quốc gia';
  String get relatedArtifacts => isEn ? 'Related Artifacts' : 'Hiện vật liên quan';

  // ==========================================
  // 6. QUÉT MÃ QR (SCAN & AR)
  // ==========================================
  String get scanTitle => isEn ? 'QR Scanner' : 'Quét mã QR';
  String get scanInstruction => isEn
      ? 'Point your camera at the QR code next to the artifact or exhibit'
      : 'Hướng camera vào mã QR đặt cạnh hiện vật hoặc phòng trưng bày';
  String get flashlight => isEn ? 'Flashlight' : 'Đèn pin';
  String get photoGallery => isEn ? 'Gallery' : 'Thư viện ảnh';
  String get scanningProgress => isEn ? 'Recognizing QR code...' : 'Đang nhận diện mã QR...';
  String get invalidQrNotice => isEn
      ? 'Invalid QR code. Please scan an authentic SMGS museum code.'
      : 'Mã QR không hợp lệ. Vui lòng quét mã chính thức của hệ thống SMGS.';
  String get permissionCameraTitle => isEn ? 'Camera Access Required' : 'Cần quyền truy cập máy ảnh';
  String get permissionCameraMsg => isEn
      ? 'SMGS needs camera permission to scan artifact QR codes.'
      : 'SMGS cần quyền máy ảnh để nhận diện mã QR hiện vật tại bảo tàng.';
  String get grantPermission => isEn ? 'Open Settings' : 'Mở cài đặt';

  // ==========================================
  // 7. HÀNH TRÌNH & TOUR (TOURS & ITINERARIES)
  // ==========================================
  String get toursTabTitle => isEn ? 'Museum Journeys' : 'Hành trình tham quan';
  String get curatedToursTab => isEn ? 'Featured Tours' : 'Tour tuyển chọn';
  String get personalizedTourTab => isEn ? 'Custom Tour' : 'Tour cá nhân hóa';
  String get createCustomTourCTA => isEn ? 'Create Tailored Tour' : 'Tạo lộ trình riêng';
  String get tourDurationMinutes => isEn ? 'mins' : 'phút';
  String get tourStopsCount => isEn ? 'stops' : 'điểm dừng';
  String get startTourCTA => isEn ? 'Begin Tour' : 'Bắt đầu hành trình';
  String get currentStop => isEn ? 'Current stop' : 'Điểm hiện tại';
  String get nextStop => isEn ? 'Next stop' : 'Điểm tiếp theo';
  String get finishTourCTA => isEn ? 'End Tour' : 'Kết thúc tour';
  String get tourCompleted => isEn ? 'Journey Completed!' : 'Hoàn thành hành trình!';

  // ==========================================
  // 8. CÁ NHÂN & CÀI ĐẶT (PROFILE & SETTINGS)
  // ==========================================
  String get profileTitle => isEn ? 'Visitor Profile' : 'Trang cá nhân';
  String get guestUser => isEn ? 'Heritage Visitor' : 'Khách tham quan';
  String get loginPrompt => isEn ? 'Sign in to sync your journey and badges' : 'Đăng nhập để đồng bộ lịch sử và vé tham quan';
  String get loginButton => isEn ? 'Sign In' : 'Đăng nhập';
  String get logoutButton => isEn ? 'Sign Out' : 'Đăng xuất';
  String get logoutConfirmTitle => isEn ? 'Sign Out Confirmation' : 'Xác nhận đăng xuất';
  String get logoutConfirmMsg => isEn ? 'Are you sure you want to sign out?' : 'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?';

  String get menuMyMuseum => isEn ? 'My Museums' : 'Bảo tàng của tôi';
  String get menuVisitHistory => isEn ? 'Visit History' : 'Lịch sử tham quan';
  String get menuMyOrders => isEn ? 'My Orders & Passes' : 'Đơn hàng & Vé của tôi';
  String get menuSupport => isEn ? 'Help & Support' : 'Hỗ trợ & Góp ý';
  String get menuRefunds => isEn ? 'Complaints & Inquiries' : 'Khiếu nại & Hoàn tiền';

  String get sectionLanguage => isEn ? 'Language' : 'Ngôn ngữ';
  String get langVietnamese => isEn ? 'Tiếng Việt' : 'Tiếng Việt';
  String get langEnglish => isEn ? 'English' : 'English';

  String get sectionAccessibility => isEn ? 'Accessibility' : 'Trợ năng & Trải nghiệm';
  String get prefLargeText => isEn ? 'Large Text' : 'Cỡ chữ lớn';
  String get prefReducedMotion => isEn ? 'Reduce Animations' : 'Giảm chuyển động';
  String get prefNotifications => isEn ? 'Notification Alerts' : 'Thông báo ứng dụng';

  // ==========================================
  // 9. THÔNG BÁO (NOTIFICATIONS)
  // ==========================================
  String get notificationCenterTitle => isEn ? 'Notifications' : 'Thông báo';
  String get tabAllNotifications => isEn ? 'All' : 'Tất cả';
  String get tabUnreadOnly => isEn ? 'Unread' : 'Chưa đọc';
  String get markAllRead => isEn ? 'Mark all as read' : 'Đánh dấu tất cả đã đọc';
  String get noNotifications => isEn ? 'No notifications yet' : 'Chưa có thông báo nào';
  String get noUnreadNotifications => isEn ? 'No unread notifications' : 'Không có thông báo chưa đọc';
  String get inAppBannerView => isEn ? 'View' : 'Xem ngay';
  String get inAppBannerDismiss => isEn ? 'Dismiss' : 'Đóng';

  String get timeJustNow => isEn ? 'Just now' : 'Vừa xong';
  String timeMinutesAgo(int m) => isEn ? '${m}m ago' : '$m phút trước';
  String timeHoursAgo(int h) => isEn ? '${h}h ago' : '$h giờ trước';
  String timeDaysAgo(int d) => isEn ? '${d}d ago' : '$d ngày trước';

  // ==========================================
  // 10. ĐƠN HÀNG & KHIẾU NẠI (ORDERS & SUPPORT)
  // ==========================================
  String get orderDetailTitle => isEn ? 'Order & Pass Details' : 'Chi tiết đơn hàng & vé';
  String get orderCode => isEn ? 'Order Code' : 'Mã đơn hàng';
  String get orderDate => isEn ? 'Purchase Date' : 'Ngày đặt vé';
  String get orderTotal => isEn ? 'Total Amount' : 'Tổng số tiền';
  String get passValid => isEn ? 'Valid Pass' : 'Vé hợp lệ';
  String get passUsed => isEn ? 'Used' : 'Đã sử dụng';
  String get supportTitle => isEn ? 'Feedback & Assistance' : 'Hỗ trợ & Đóng góp ý kiến';
  String get submitFeedback => isEn ? 'Submit' : 'Gửi yêu cầu';
  String get feedbackSuccess => isEn ? 'Feedback submitted successfully' : 'Gửi ý kiến đóng góp thành công';
}

/// Localizations delegate cho Flutter
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['vi', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

/// Extension tiện ích trên BuildContext
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
