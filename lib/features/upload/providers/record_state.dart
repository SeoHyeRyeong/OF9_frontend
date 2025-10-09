import 'package:flutter/foundation.dart';

class RecordState extends ChangeNotifier {
  // 기본 정보
  String? _gameId;
  int? _emotionCode;

  // 티켓 정보
  String? _ticketImagePath;
  String? _selectedHome;
  String? _selectedAway;
  String? _selectedDateTime;
  String? _selectedStadium;
  String? _selectedSeat;
  String? _extractedHomeTeam;
  String? _extractedAwayTeam;
  String? _extractedDate;
  String? _extractedTime;
  String? _extractedStadium;
  String? _extractedSeat;

  // 상세 기록
  String? _comment;
  String? _longContent;
  String? _bestPlayer;
  List<int> _companions = [];
  List<String> _foodTags = [];
  List<String> _detailImages = [];

  // Getters - 기본 정보
  String? get gameId => _gameId;
  int? get emotionCode => _emotionCode;

  // Getters - 티켓 정보
  String? get ticketImagePath => _ticketImagePath;
  String? get selectedHome => _selectedHome;
  String? get selectedAway => _selectedAway;
  String? get selectedDateTime => _selectedDateTime;
  String? get selectedStadium => _selectedStadium;
  String? get selectedSeat => _selectedSeat;
  String? get extractedHomeTeam => _extractedHomeTeam;
  String? get extractedAwayTeam => _extractedAwayTeam;
  String? get extractedDate => _extractedDate;
  String? get extractedTime => _extractedTime;
  String? get extractedStadium => _extractedStadium;
  String? get extractedSeat => _extractedSeat;

  // Getters - 상세 기록
  String? get comment => _comment;
  String? get longContent => _longContent;
  String? get bestPlayer => _bestPlayer;
  List<int> get companions => _companions;
  List<String> get foodTags => _foodTags;
  List<String> get detailImages => _detailImages;

  // 티켓 정보 저장
  void setTicketInfo({
    required String ticketImagePath,
    String? selectedHome,
    String? selectedAway,
    String? selectedDateTime,
    String? selectedStadium,
    String? selectedSeat,
    String? extractedHomeTeam,
    String? extractedAwayTeam,
    String? extractedDate,
    String? extractedTime,
    String? extractedStadium,
    String? extractedSeat,
    String? gameId,
  }) {
    _ticketImagePath = ticketImagePath;
    _selectedHome = selectedHome;
    _selectedAway = selectedAway;
    _selectedDateTime = selectedDateTime;
    _selectedStadium = selectedStadium;
    _selectedSeat = selectedSeat;
    _extractedHomeTeam = extractedHomeTeam;
    _extractedAwayTeam = extractedAwayTeam;
    _extractedDate = extractedDate;
    _extractedTime = extractedTime;
    _extractedStadium = extractedStadium;
    _extractedSeat = extractedSeat;
    _gameId = gameId;
    notifyListeners();
  }

  // 개별 필드 업데이트
  void updateEmotionCode(int emotionCode) {
    _emotionCode = emotionCode;
    notifyListeners();
  }

  void updateComment(String comment) {
    _comment = comment;
    notifyListeners();
  }

  void updateLongContent(String longContent) {
    _longContent = longContent;
    notifyListeners();
  }

  void updateBestPlayer(String bestPlayer) {
    _bestPlayer = bestPlayer;
    notifyListeners();
  }

  void updateCompanions(List<int> companions) {
    _companions = companions;
    notifyListeners();
  }

  void updateFoodTags(List<String> foodTags) {
    _foodTags = foodTags;
    notifyListeners();
  }

  void updateDetailImages(List<String> images) {
    _detailImages = images;
    notifyListeners();
  }

  // 구 메서드 호환성 유지
  @Deprecated('Use updateDetailImages instead')
  void updateImagePaths(List<String> imagePaths) {
    updateDetailImages(imagePaths);
  }

  @Deprecated('Use detailImages instead')
  List<String> get imagePaths => _detailImages;

  // 티켓 정보 완료 여부
  bool get isTicketInfoComplete {
    return _ticketImagePath != null &&
        (_selectedHome != null || _extractedHomeTeam != null) &&
        (_selectedAway != null || _extractedAwayTeam != null) &&
        (_selectedDateTime != null || (_extractedDate != null && _extractedTime != null)) &&
        (_selectedStadium != null || _extractedStadium != null) &&
        (_selectedSeat != null || _extractedSeat != null);
  }

  // 최종 표시값 가져오기
  String? get finalHome => _selectedHome ?? _extractedHomeTeam;
  String? get finalAway => _selectedAway ?? _extractedAwayTeam;
  String? get finalDateTime => _selectedDateTime ?? (_extractedDate != null && _extractedTime != null ? '$_extractedDate $_extractedTime' : null);
  String? get finalStadium => _selectedStadium ?? _extractedStadium;
  String? get finalSeat => _selectedSeat ?? _extractedSeat;

  // 상태 초기화
  void reset() {
    _gameId = null;
    _emotionCode = null;

    _ticketImagePath = null;
    _selectedHome = null;
    _selectedAway = null;
    _selectedDateTime = null;
    _selectedStadium = null;
    _selectedSeat = null;
    _extractedHomeTeam = null;
    _extractedAwayTeam = null;
    _extractedDate = null;
    _extractedTime = null;
    _extractedStadium = null;
    _extractedSeat = null;

    _comment = null;
    _longContent = null;
    _bestPlayer = null;
    _companions = [];
    _foodTags = [];
    _detailImages = [];
    notifyListeners();
  }

  // 디버그용
  void printCurrentState() {
    print('=== 현재 기록 상태 ===');
    print('[기본 정보]');
    print('gameId: $_gameId');
    print('emotionCode: $_emotionCode');
    print('[티켓 정보]');
    print('ticketImagePath: $_ticketImagePath');
    print('selectedHome: $_selectedHome (extracted: $_extractedHomeTeam)');
    print('selectedAway: $_selectedAway (extracted: $_extractedAwayTeam)');
    print('selectedDateTime: $_selectedDateTime (extracted: $_extractedDate $_extractedTime)');
    print('selectedStadium: $_selectedStadium (extracted: $_extractedStadium)');
    print('selectedSeat: $_selectedSeat (extracted: $_extractedSeat)');
    print('[상세 기록]');
    print('comment: $_comment');
    print('longContent: $_longContent');
    print('bestPlayer: $_bestPlayer');
    print('companions: $_companions');
    print('foodTags: $_foodTags');
    print('detailImages: $_detailImages');
    print('==================');
  }
}