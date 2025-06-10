import 'package:flutter/foundation.dart';

class RecordState extends ChangeNotifier {
  // 필수 필드
  int? _userId;
  String? _gameId;
  String? _seatInfo;
  int? _emotionCode;
  String? _stadium;

  // 선택적 필드
  String? _comment;
  String? _longContent;
  String? _bestPlayer;
  List<String> _companions = [];
  List<String> _foodTags = [];
  List<String> _imagePaths = [];

  // Getters
  int? get userId => _userId;
  String? get gameId => _gameId;
  String? get seatInfo => _seatInfo;
  int? get emotionCode => _emotionCode;
  String? get stadium => _stadium;
  String? get comment => _comment;
  String? get longContent => _longContent;
  String? get bestPlayer => _bestPlayer;
  List<String> get companions => _companions;
  List<String> get foodTags => _foodTags;
  List<String> get imagePaths => _imagePaths;

  // 필수 정보 설정 (EmotionSelectScreen에서 사용)
  void setBasicInfo({
    required int userId,
    required String gameId,
    required String seatInfo,
    required int emotionCode,
    required String stadium,
  }) {
    _userId = userId;
    _gameId = gameId;
    _seatInfo = seatInfo;
    _emotionCode = emotionCode;
    _stadium = stadium;
    notifyListeners();
  }

  // 상세 정보 설정 (DetailRecordScreen에서 사용)
  void setDetailInfo({
    String? comment,
    String? longContent,
    String? bestPlayer,
    List<String>? companions,
    List<String>? foodTags,
    List<String>? imagePaths,
  }) {
    if (comment != null) _comment = comment;
    if (longContent != null) _longContent = longContent;
    if (bestPlayer != null) _bestPlayer = bestPlayer;
    if (companions != null) _companions = companions;
    if (foodTags != null) _foodTags = foodTags;
    if (imagePaths != null) _imagePaths = imagePaths;
    notifyListeners();
  }

  // 개별 필드 업데이트
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

  void updateCompanions(List<String> companions) {
    _companions = companions;
    notifyListeners();
  }

  void updateFoodTags(List<String> foodTags) {
    _foodTags = foodTags;
    notifyListeners();
  }

  void updateImagePaths(List<String> imagePaths) {
    _imagePaths = imagePaths;
    notifyListeners();
  }

  // 데이터 유효성 검사
  bool get isBasicInfoComplete {
    return _userId != null &&
        _gameId != null &&
        _seatInfo != null &&
        _emotionCode != null &&
        _stadium != null;
  }

  // 상태 초기화
  void reset() {
    _userId = null;
    _gameId = null;
    _seatInfo = null;
    _emotionCode = null;
    _stadium = null;
    _comment = null;
    _longContent = null;
    _bestPlayer = null;
    _companions = [];
    _foodTags = [];
    _imagePaths = [];
    notifyListeners();
  }

  // 디버그용
  void printCurrentState() {
    print('=== 현재 기록 상태 ===');
    print('userId: $_userId');
    print('gameId: $_gameId');
    print('seatInfo: $_seatInfo');
    print('emotionCode: $_emotionCode');
    print('stadium: $_stadium');
    print('comment: $_comment');
    print('longContent: $_longContent');
    print('bestPlayer: $_bestPlayer');
    print('companions: $_companions');
    print('foodTags: $_foodTags');
    print('imagePaths: $_imagePaths');
    print('==================');
  }
}
