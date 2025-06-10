import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/fixed_text.dart';

// 구장별 좌석 정보 매핑
class StadiumSeatInfo {
  static const Map<String, Map<String, List<String>>> stadiumSeats = {
    '잠실 야구장': {
      '1루 테이블석': ['110', '111', '212', '213'],
      '1루 블루석': ['107', '108', '109', '209', '210', '211'],
      '1루 오렌지석': ['205', '206', '207', '208'],
      '1루 레드석': ['102', '103', '104', '105', '106', '201', '202', '203', '204'],
      '1루 네이비석': ['301', '302', '303', '304', '305', '306', '307', '308', '309', '310', '311', '312'],
      '1루 외야석': ['401', '402', '403', '404', '405', '406', '407', '408', '409', '410', '411'],
      '중앙 네이비석': ['313', '314', '315', '316', '317', '318', '319', '320', '321', '322'],
      '3루 테이블석': ['112', '113', '213', '214'],
      '3루 블루석': ['114', '115', '116', '216', '217', '218'],
      '3루 오렌지석': ['219', '220', '221', '222'],
      '3루 레드석': ['117', '118', '119', '120', '121', '122', '223', '224', '225', '226'],
      '3루 네이비석': ['323', '324', '325', '326', '327', '328', '329', '330', '331', '332', '333', '334'],
      '3루 외야석': ['412', '413', '414', '415', '416', '417', '418', '419', '420', '421', '422'],
      '익사이팅존': ['1루', '3루'],
    },
    '사직 야구장': {
      'SKY BOX': ['SKY BOX'],
      '에비뉴엘석': ['012', '013'],
      '중앙탁자석': ['021', '022', '023', '024', '031', '032', '033', '034', '041', '044'],
      '응원탁자석': ['121', '131'],
      '와이드탁자석': ['321', '322', '331', '332'],
      '3루 단체석': ['327', '337'],
      '1루 내야상단석': ['116', '126', '127', '134', '135', '136', '137', '142', '143'],
      '1루 내야필드석': ['111', '112', '113', '114', '115', '122', '123', '124', '125'],
      '중앙 상단석': ['051', '052', '053', '054', '055', '056', '057'],
      '3루 내야상단석': ['315', '316', '325', '326', '333', '334', '335', '336', '342', '343'],
      '3루 내야필드석': ['311', '312', '313', '314', '323', '324'],
      '1루 외야석': ['921', '922', '923', '924', '925', '931', '932', '933', '934', '935'],
      '3루 외야석': ['721', '722', '723', '724', '731', '732', '733', '734'],
      '1루 외야 탁자석': ['941', '942'],
      '3루 외야 탁자석': ['338'],
      '휠체어석': ['휠체어석'],
    },
    '고척 SKYDOME': {
      'R.d_club석': ['D01', 'D02', 'D03', 'D04', 'D05', 'D06', 'D07'],
      '1루 테이블석': ['T01', 'T02', 'T11', 'T12', 'T13'],
      '중앙 테이블석': ['T03', 'T04', 'T05'],
      '3루 테이블석': ['T06', 'T07', 'T15', 'T16', 'T17'],
      '1루 다크버건디석': ['106', '107', '204', '205'],
      '3루 다크버건디석': ['108', '109', '206', '207'],
      '1루 버건디석': ['101', '102', '103', '104', '105', '201', '202', '203'],
      '3루 버건디석': ['110', '111', '112', '113', '114', '208', '209', '210'],
      '1루 3층 지정석': ['301', '302', '303', '304', '305', '306', '307', '308', '309', '310', '311'],
      '3루 3층 지정석': ['312', '313', '314', '315', '316', '317', '318', '319', '320', '321', '322'],
      '1루 4층 지정석': ['401', '402', '403', '404', '405', '406', '407', '408', '409'],
      '중앙 4층 지정석': ['410', '411', '412', '413', '414', '415'],
      '3루 4층 지정석': ['416', '417', '418', '419', '420', '421', '422', '423', '424'],
      '1루 1~2층 외야 일반석': ['124', '125', '126', '127', '128', '129', '130', '131', '132', '217', '218', '219', '220', '221', '222'],
      '1루 3~4층 외야 일반석': ['329', '330', '331', '332', '333', '334', '430', '431', '432', '433', '434', '435'],
      '3루 1~2층 외야 일반석': ['115', '116', '117', '118', '119', '120', '121', '122', '123', '211', '212', '213', '214', '215', '216'],
      '3루 3~4층 외야 일반석': ['323', '324', '325', '326', '327', '328', '425', '426', '427', '428', '429'],
      '커플석': ['1루 내야', '3루 내야', '1루 외야', '3루 외야'],
      '패밀리석': ['1루 외야 (4인)', '1루 외야 (5인)', '3루 외야 (4인)'],
      '유아동반석': ['1루 외야', '3루 외야'],
      '휠체어석': ['1루', '3루', '다크버건디'],
    },
    '대구삼성라이온즈파크': {
      'VIP석': ['VIP 1구역', 'VIP 2구역', 'VIP 3구역'],
      '1루 테이블석': ['T1-1구역', 'T1-2구역', 'T1-3구역', 'T1-4구역'],
      '중앙 테이블석': ['TC-1구역', 'TC-2구역', 'TC-3구역'],
      '3루 테이블석': ['T3-1구역', 'T3-2구역', 'T3-3구역', 'T3-4구역'],
      '1루 익사이팅석': ['1E-1구역', '1E-2구역', '1E-3구역'],
      '3루 익사이팅석': ['3E-1구역', '3E-2구역', '3E-3구역'],
      '원정응원석': ['1-1구역', '1-2구역', '1-3구역', '1-4구역', '1-5구역'],
      '블루존': ['3-1구역', '3-2구역', '3-3구역', '3-4구역', '3-5구역', '3-6구역', '3-7구역'],
      '1루 내야지정석': ['1-6구역', '1-7구역', '1-8구역', '1-9구역', '1-10구역', '1-11구역', '1-12구역'],
      '3루 내야지정석': ['3-8구역', '3-9구역', '3-10구역', '3-11구역', '3-12구역'],
      '내야 패밀리석': ['내야 패밀리석'],
      'SKY 하단지정석': ['U-1구역', 'U-2구역', 'U-3구역', 'U-4구역', 'U-5구역', 'U-6구역', 'U-7구역', 'U-8구역', 'U-9구역', 'U-10구역', 'U-11구역', 'U-12구역', 'U-13구역', 'U-14구역', 'U-15구역', 'U-16구역', 'U-17구역', 'U-18구역', 'U-19구역', 'U-20구역', 'U-21구역', 'U-22구역', 'U-23구역', 'U-24구역', 'U-25구역', 'U-26구역', 'U-27구역', 'U-28구역', 'U-29구역', 'U-30구역', 'U-31구역'],
      '1루 SKY 상단지정석': ['U-1구역', 'U-2구역', 'U-3구역', 'U-4구역', 'U-5구역', 'U-6구역', 'U-7구역', 'U-8구역', 'U-9구역'],
      '중앙 SKY 상단지정석': ['U-10구역', 'U-11구역', 'U-12구역', 'U-13구역', 'U-14구역'],
      '3루 SKY 상단지정석': ['U-15구역', 'U-16구역', 'U-17구역', 'U-18구역', 'U-19구역', 'U-20구역', 'U-21구역', 'U-22구역', 'U-23구역', 'U-24구역', 'U-25구역', 'U-26구역', 'U-27구역', 'U-28구역', 'U-29구역', 'U-30구역', 'U-31구역'],
      '외야지정석': ['LF-1구역', 'LF-2구역', 'LF-3구역', 'LF-4구역', 'LF-5구역', 'LF-6구역', 'LF-7구역', 'LF-8구역', 'LF-9구역', 'LF-10구역', 'RF-1구역', 'RF-2구역', 'RF-3구역', 'RF-4구역', 'RF-5구역', 'RF-6구역', 'RF-7구역', 'RF-8구역', 'RF-9구역', 'RF-10구역'],
      '외야패밀리석': ['F-1구역', 'F-2구역'],
      '외야테이블석': ['TR-1구역', 'TR-2구역', 'TR-3구역', 'TR-4구역', 'TR-5구역', 'TR-6구역', 'TR-7구역'],
      '외야커플테이블석': ['MR-1구역', 'MR-2구역', 'MR-3구역', 'MR-4구역', 'MR-5구역', 'MR-6구역', 'MR-7구역', 'MR-8구역', 'MR-10구역', 'ML-1구역', 'ML-2구역', 'ML-3구역', 'ML-4구역', 'ML-5구역', 'ML-6구역', 'ML-7구역', 'ML-8구역', 'ML-10구역'],
      '루프탑 테이블석': ['루프탑 테이블석'],
      '파티플로어 라이브석': ['파티플로어 라이브석'],
      '캠핑존': ['캠핑존'],
      '잔디그린존': ['잔디그린존'],
      '휠체어 장애인석': ['1-1구역', '1-2구역', '1-3구역', '1-4구역', '1-5구역', '3-1구역', '3-2구역', '3-5구역', '3-6구역', '3-7구역', '3-8구역', '3-9구역', '3-10구역', '3-11구역', '3-12구역', 'T1-2구역', 'T1-3구역', 'T1-4구역', 'T3-2구역', 'T3-3구역'],
    },
    '한화생명 볼파크': {
      '1루 내야지정석A': ['109', '110', '111', '112', '201', '202', '203', '204', '205', '206', '207', '208', '209', '210', '211', '212'],
      '3루 내야지정석A': ['113', '114', '115', '116', '117', '118', '119', '120', '121', '213', '214', '215', '216', '217', '218', '219', '220', '221', '222', '223', '224', '225'],
      '1루 내야지정석B': ['101', '102', '103', '104', '301', '302', '401', '402', '403', '404', '405', '406', '407', '408', '409', '410', '411', '412', '413', '414', '415'],
      '3루 내야지정석B': ['121', '122', '123', '124', '326', '327', '328', '329', '330', '416', '417', '418', '419', '420', '421', '422', '423', '424', '425'],
      '응원단석': ['104', '105', '106', '107', '108'],
      '포수후면석': ['100A', '100B', '100C'],
      '중앙지정석': ['100A', '100B', '100C'],
      '중앙탁자석': ['100A(테이블)', '100B(테이블)', '100C(테이블)'],
      '1루 내야커플석': ['202', '203', '204', '205', '206', '207', '208', '209', '210', '211'],
      '3루 내야박스석': ['215', '216', '217', '218', '219', '220', '221', '222', '223'],
      '1루 내야탁자석': ['400'],
      '외야지정석': ['501', '502', '503', '504', '505', '506', '507', '508'],
      '잔디석': ['500'],
      '외야탁자석': ['509'],
      '이닝스 VIP 바&룸': ['200'],
      '스카이박스': ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'S9', 'S10', 'S11', 'S12', 'S13', 'S14', 'S15', 'S16', 'S17', 'S18', 'S19', 'S20', 'S21', 'S22', 'S23', 'S24', 'S25', 'S26', 'S27', 'S28', 'S29', 'S30', 'S31'],
      '중앙 휠체어석': ['100A(테이블)', '100B(테이블)', '100C(테이블)'],
      '내야 휠체어석': ['101', '102', '104', '107', '109', '111', '114', '115', '116', '118', '120', '121', '122', '123', '124', '400'],
      '외야 휠체어석': ['500', '501', '502'],
    },
    '기아 챔피언스 필드': {
      '챔피언석': ['챔피언석'],
      '중앙테이블석': ['중앙테이블석'],
      '서프라이즈석': ['1루', '3루'],
      '타이거즈 가족석': ['1루', '3루'],
      '파티석': ['1루', '3루'],
      '스카이피크닉석': ['T7', 'T8', 'T9', 'T10', 'T11', 'T12', 'T13', 'T14', 'T15', 'T16', 'T17', 'T18', 'T19', 'T20', 'T21', 'T22', 'T23', 'T24', 'T25', 'T26', 'T27', 'T28', 'T29'],
      '외야가족석': ['1루', '3루'],
      '테이블석': ['501T', '502T', '503T', '504T', '505T', '506T', '507T', '508T', '509T', '510T', '511T', '512T', '513T', '514T', '515T', '516T', '517T', '518T', '519T', '520T', '521T', '522T', '523T', '524T', '525T', '526T', '527T', '528T', '529T', '530T', '531T', '532T', '533T', '534T', '535T'],
      '응원특별석': ['120', '121', '122'],
      '1루 내야석A(K9)': ['112', '113'],
      '1루 내야석B(K8)': ['107', '108', '109', '110', '111'],
      '1루 내야석C(K5)': ['101', '102', '103', '104', '105'],
      '3루 내야석A(K9)': ['116', '117'],
      '3루 내야석B(K8)': ['118', '119', '123'],
      '3루 내야석C(K5)': ['124', '125', '126', '127'],
      '1루 내야 상단석(EV석)': ['501', '502', '503', '504', '505', '506', '507', '508', '509', '510', '511', '512', '513', '514', '515', '516', '517', '518'],
      '3루 내야 상단석(EV석)': ['519', '520', '521', '522', '523', '524', '525', '526', '527', '528', '529', '530', '531', '532', '533', '534', '535'],
      '외야석': ['외야석'],
      '1루 휠체어 장애인석': ['103', '104', '105', '106', '107', '108', '109', '110', '111', '112', '113'],
      '3루 휠체어 장애인석': ['116', '117', '118', '119', '120', '121', '122', '123', '124', '125', '126'],
      '스카이박스석': ['S-301', 'S-302', 'S-303', 'S-304', 'S-305', 'S-306', 'S-307', 'S-308', 'S-309', 'S-310', 'S-311', 'S-312', 'S-313', 'S-314', 'S-315', 'S-316', 'S-317', 'S-318', 'S-319', 'S-320', 'S-321', 'S-322', 'S-323', 'S-324', 'S-325', 'S-326', 'S-327', 'S-328', 'S-329', 'S-330', 'S-331', 'S-332', 'S-333', 'S-334', 'S-335'],
    },
    '수원 케이티 위즈 파크': {
      '중앙 내야석': ['좌', '중', '우'],
      '1루 테이블석': ['113', '114', '115', '213', '214', '215', '310', '311', '312'],
      '3루 테이블석': ['116', '117', '118', '224', '225', '226', '321', '322', '333'],
      '중앙 지정석': ['215', '216', '217', '218', '219', '220', '221', '222', '223', '224', '313', '314', '315', '316', '317', '318', '319', '320'],
      '1루 응원 지정석': ['101', '102', '103', '104', '105', '106', '107', '108', '109', '110', '111', '112', '201', '202', '203', '204', '205', '206', '207', '208', '209', '210', '211', '212', '301', '302', '303', '304', '305', '306', '307', '308', '309'],
      '3루 응원 지정석': ['119', '120', '121', '122', '123', '124', '125', '126', '127', '128', '129', '130', '227', '228', '229', '230', '231', '232', '233', '234', '235', '236', '237', '238', '324', '325', '326', '327', '328', '329', '330', '331', '332'],
      '1루 스카이존': ['401', '402', '403', '404', '405', '406', '407', '408', '409', '410', '411', '412'],
      '3루 스카이존': ['413', '414', '415', '416', '417', '418', '419', '420', '421', '422', '423', '424', '425', '426', '427', '428', '429', '430', '431', '432'],
      '익사이팅': ['1루(하이파이브존)', '3루'],
      '외야잔디/자유석': ['외야잔디/자유석'],
      '외야 테이블석': ['501', '502', '503', '504', '505'],
      '위즈 캠핑존': ['4층', '5층'],
      '1루 휠체어석': ['111', '112', '113', '114', '115'],
      '3루 휠체어석': ['116', '117', '118', '119', '120', '121', '122', '123'],
    },
    '창원 NC파크': {
      // NC파크 좌석 정보가 제공되지 않아 기본값 사용
      '1루': ['A', 'B', 'C', 'D'],
      '3루': ['A', 'B', 'C', 'D'],
      '중앙': ['A', 'B', 'C', 'D'],
      '외야': ['A', 'B', 'C', 'D'],
    },
    '인천 SSG 랜더스필드': {
      '랜더스 라이브존': ['V1', 'V2', 'V3', 'V4', 'V5', 'V6'],
      '프렌들리존': ['1루', '3루'],
      '1층 테이블석': ['11B', '13B', '15B', '17B', '19B', '21B'],
      '2층 테이블석': ['12B', '14B', '16B', '18B', '20B', '22B'],
      '1루 덕아웃 상단석': ['7B', '9B'],
      '1루 으쓱이존': ['N1', 'N2', 'N3', 'N4', '1B', '2B', '3B', '4B', '5B', '6B'],
      '1루 내야패밀리존': ['8B', '10B'],
      '1루 내야 필드석': ['101', '102', '103', '201', '202', '203'],
      '1루 외야 필드석': ['104', '105', '106', '204', '205', '206'],
      '3루 덕아웃 상단석': ['23B', '25B'],
      '3루 원정응원석': ['27B', '28B', '29B', '30B', '31B', '32B'],
      '3루 내야패밀리존': ['24B', '26B'],
      '3루 내야 필드석': ['115', '116', '117', '118', '207', '208', '209'],
      '3루 외야 필드석': ['107', '108', '109', '110', '111', '112', '113', '114'],
      '4층 SKY뷰석': ['301', '302', '303', '304', '305', '306', '307', '308', '401', '402', '403', '404', '405', '406', '407', '408', '409', '410', '411', '412', '413', '414', '415', '416', '417', '418'],
      'SKY탁자석': ['36B', '37B', '38B', '39B', '40B', '41B', '42B', '43B', '44B', '45B'],
      '홈런커플존': ['1루', '3루'],
      '휠체어 장애인석': ['9B', '23B'],
      '그린존': ['그린존'],
      '바비큐존': ['바비큐존'],
      '외야파티덱': ['외야파티덱'],
      '외야패밀리존': ['외야패밀리존'],
      '초가정자': ['초가정자'],
      '미니스카이박스': ['(M)SKY-L1', '(M)SKY-L2', '(M)SKY-L3', '(M)SKY-L4', '(M)SKY-R1', '(M)SKY-R2', '(M)SKY-R3', '(M)SKY-R4', '(M)SKY-R5', '(M)SKY-R6', '(M)SKY-R7', '(M)SKY-R8', '(M)SKY-R9', '(M)SKY-R10', '(M)SKY-R11', '(M)SKY-R12', '(M)SKY-R13', '(M)SKY-R14'],
      '스카이박스': ['SKY-L1', 'SKY-L2', 'SKY-L3', 'SKY-L4', 'SKY-L5', 'SKY-L6', 'SKY-L7', 'SKY-L8', 'SKY-L9', 'SKY-L10', 'SKY-L11', 'SKY-L12', 'SKY-L13', 'SKY-L14', 'SKY-L15', 'SKY-L16', 'SKY-L17', 'SKY-L18', 'SKY-R1', 'SKY-R2', 'SKY-R3', 'SKY-R4', 'SKY-R5', 'SKY-R6', 'SKY-R7', 'SKY-R8', 'SKY-R9', 'SKY-R10', 'SKY-R11', 'SKY-R12', 'SKY-R13', 'SKY-R14', 'SKY-R15', 'SKY-R16', 'SKY-R17', 'SKY-R18', 'SKY-VVIP', 'SKY-C1'],
    },
    // 기본 구장 (매핑되지 않은 구장용)
    'default': {
      '1루': ['A', 'B', 'C', 'D'],
      '3루': ['A', 'B', 'C', 'D'],
      '중앙': ['A', 'B', 'C', 'D'],
      '외야': ['A', 'B', 'C', 'D'],
    }
  };

  static String? mapOcrStadiumToSeatKey(String? ocrStadium) {
    if (ocrStadium == null || ocrStadium.isEmpty) return null;

    final cleaned = ocrStadium.trim();

    // 정확히 일치하는 경우 (stadiumSeats의 키와 동일)
    if (stadiumSeats.containsKey(cleaned)) {
      return cleaned;
    }

    // OCR 구장명을 stadiumSeats 키로 매핑
    const ocrToSeatMapping = {
      '잠실': '잠실 야구장',
      '문학': '인천 SSG 랜더스필드',
      '대구': '대구삼성라이온즈파크',
      '수원': '수원 케이티 위즈 파크',
      '광주': '기아 챔피언스 필드',
      '창원': '창원 NC파크',
      '고척': '고척 SKYDOME',
      '대전(신)': '한화생명 볼파크',
      '사직': '사직 야구장',
      // 추가적인 매핑들
      '잠실야구장': '잠실 야구장',
      '사직야구장': '사직 야구장',
      '고척스카이돔': '고척 SKYDOME',
      '대구삼성라이온즈파크': '대구삼성라이온즈파크',
      '한화생명볼파크': '한화생명 볼파크',
      '기아챔피언스필드': '기아 챔피언스 필드',
      '수원케이티위즈파크': '수원 케이티 위즈 파크',
      '창원NC파크': '창원 NC파크',
      '인천SSG랜더스필드': '인천 SSG 랜더스필드',
    };

    // 정확히 일치하는 매핑
    if (ocrToSeatMapping.containsKey(cleaned)) {
      return ocrToSeatMapping[cleaned];
    }

    // 부분 일치 검색 (대소문자 무시)
    for (final entry in ocrToSeatMapping.entries) {
      if (cleaned.toLowerCase().contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(cleaned.toLowerCase())) {
        return entry.value;
      }
    }

    // stadiumSeats의 키들과 부분 일치 검색
    for (final key in stadiumSeats.keys) {
      if (key == 'default') continue;

      if (cleaned.toLowerCase().contains(key.toLowerCase()) ||
          key.toLowerCase().contains(cleaned.toLowerCase())) {
        return key;
      }
    }

    // 매핑되지 않은 경우 null 반환 (default 처리됨)
    return null;
  }

  static List<String> getZones(String? stadium) {
    // OCR 구장명을 먼저 매핑 시도
    final mappedStadium = mapOcrStadiumToSeatKey(stadium);
    final seatInfo = stadiumSeats[mappedStadium] ?? stadiumSeats['default']!;
    return seatInfo.keys.toList();
  }

  static List<String> getBlocks(String? stadium, String? zone) {
    if (zone == null) return [];
    // OCR 구장명을 먼저 매핑 시도
    final mappedStadium = mapOcrStadiumToSeatKey(stadium);
    final seatInfo = stadiumSeats[mappedStadium] ?? stadiumSeats['default']!;
    return seatInfo[zone] ?? [];
  }
}

// parseSeatString 함수를 수정 - stadium 매개변수 추가
Map<String, String>? parseSeatString(String? text, {String? stadium}) {
  if (text == null || text.isEmpty) return null;

  // 패턴 1: "구역 블럭 열 번" 형태
  final reg1 = RegExp(r'(.+?)\s+(.+?)블럭\s+(.+?)열\s+(.+?)번');
  final match1 = reg1.firstMatch(text);
  if (match1 != null) {
    return {
      'zone': match1.group(1)!,
      'block': match1.group(2)!,
      'row': match1.group(3)!,
      'num': match1.group(4)!,
    };
  }

  // 패턴 2: "구역 블럭 번" 형태 (열 없음)
  final reg2 = RegExp(r'(.+?)\s+(.+?)블럭\s+(.+?)번');
  final match2 = reg2.firstMatch(text);
  if (match2 != null) {
    return {
      'zone': match2.group(1)!,
      'block': match2.group(2)!,
      'row': '',
      'num': match2.group(3)!,
    };
  }

  return null;
}

Future<String?> showSeatInputDialog(
    BuildContext context, {
      String? initial,
      String? stadium, // 구장 정보 추가
    }) async {
  // OCR 구장명을 좌석 데이터 키로 매핑
  final mappedStadium = StadiumSeatInfo.mapOcrStadiumToSeatKey(stadium);
  print('🏟️ 원본 구장명: $stadium → 매핑된 구장명: $mappedStadium');

  // 기존 파싱에서 stadium 정보도 전달하고, 실제 데이터와 검증
  final parsed = parseSeatString(initial, stadium: mappedStadium ?? stadium);

  String? selectedZone;
  String? selectedBlock;
  final rowController = TextEditingController();
  final numController = TextEditingController();

  // 파싱된 좌석 정보도 출력
  if (parsed != null) {
    print('🎫 파싱된 좌석 정보: $parsed');
  }

  // 🔧 파싱된 데이터가 실제 구장 데이터에 존재하는지 검증 후 자동 입력
  if (mappedStadium != null && parsed != null) {
    final zones = StadiumSeatInfo.getZones(mappedStadium);
    final parsedZone = parsed['zone'];

    // 구역이 실제 데이터에 존재하는지 확인
    if (parsedZone != null && zones.contains(parsedZone)) {
      selectedZone = parsedZone;
      print('✅ 구역 "$parsedZone" 매칭 성공 → 자동 입력');

      // 구역이 매칭되면 블럭도 확인
      final blocks = StadiumSeatInfo.getBlocks(mappedStadium, parsedZone);
      final parsedBlock = parsed['block'];

      if (parsedBlock != null && blocks.contains(parsedBlock)) {
        selectedBlock = parsedBlock;
        print('✅ 블럭 "$parsedBlock" 매칭 성공 → 자동 입력');
      } else {
        print('❌ 블럭 "$parsedBlock"이 구역 "$parsedZone"에 없음 → 빈 상태로 유지');
      }
    } else {
      print('❌ 구역 "$parsedZone"이 실제 구장 데이터에 없음 → 빈 상태로 유지');
    }

    // 열과 번호는 검증 없이 자동 입력 (자유 입력)
    rowController.text = parsed['row'] ?? '';
    numController.text = parsed['num'] ?? '';
  }

  // 구장에 따른 동적 zones와 blocks (매핑된 구장명 사용)
  List<String> zones = StadiumSeatInfo.getZones(mappedStadium ?? stadium);
  List<String> blocks = StadiumSeatInfo.getBlocks(mappedStadium ?? stadium, selectedZone);
  bool isZoneDropdownOpen = false;
  bool isBlockDropdownOpen = false;

  // 정의된 구장인지 확인 (매핑된 구장명 기준)
  bool isDefinedStadium = mappedStadium != null &&
      StadiumSeatInfo.stadiumSeats.containsKey(mappedStadium) &&
      mappedStadium != '창원 NC파크'; // NC파크는 아직 정보가 없어 default 값으로 텍스트필드 처리

  // 정의되지 않은 구장의 경우 텍스트필드용 컨트롤러
  final zoneController = TextEditingController(text: parsed?['zone'] ?? '');
  final blockController = TextEditingController(text: parsed?['block'] ?? '');

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      final viewInset = MediaQuery.of(context).viewInsets.bottom;
      final adjustedInset = viewInset * 0.5;
      return Padding(
        padding: EdgeInsets.only(bottom: adjustedInset),
        child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              final screenHeight = MediaQuery.of(context).size.height;
              const baseH = 800;

              final isComplete = isDefinedStadium
                  ? (selectedZone != null &&
                  selectedBlock != null &&
                  numController.text.isNotEmpty)
                  : (zoneController.text.isNotEmpty &&
                  blockController.text.isNotEmpty &&
                  numController.text.isNotEmpty);

              return Container(
                width: 360.w,
                height: 537.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),
                ),
                child: Stack(
                  children: [
                    // 상단 바
                    Positioned(
                      top: 0,
                      left: 0,
                      width: 360.w,
                      height: 60.h,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 18.h,
                            left: 20.w,
                            child: SvgPicture.asset(
                              AppImages.backBlack,
                              width: 24.w,
                              height: screenHeight * (24 / baseH),
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned(
                            top: 22.h,
                            left: 166.w,
                            child: FixedText(
                              '좌석',
                              style: AppFonts.b2_b(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 구역
                    Positioned(
                      top: 86.h,
                      left: 20.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              FixedText(
                                '구역',
                                style: AppFonts.c1_b(
                                  context,
                                ).copyWith(color: AppColors.gray400),
                              ),
                              SizedBox(width: 2.w),
                              FixedText(
                                '*',
                                style: AppFonts.c1_b(
                                  context,
                                ).copyWith(color: AppColors.pri200),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          if (isDefinedStadium)
                          // 정의된 구장: 드롭다운
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isZoneDropdownOpen = !isZoneDropdownOpen;
                                });
                              },
                              child: Container(
                                width: 320.w,
                                height: 48.h,
                                padding: EdgeInsets.only(left: 12.w, right: 16.w),
                                decoration: BoxDecoration(
                                  color: AppColors.gray50,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: FixedText(
                                        selectedZone ?? '구역을 선택해 주세요',
                                        style: AppFonts.b3_sb_long(
                                          context,
                                        ).copyWith(
                                          color: selectedZone != null
                                              ? AppColors.trans900
                                              : AppColors.gray300,
                                        ),
                                      ),
                                    ),
                                    Transform.rotate(
                                      angle: isZoneDropdownOpen ? 3.14159 : 0,
                                      child: SvgPicture.asset(
                                        AppImages.dropdown,
                                        width: 24.w,
                                        height: 24.h,
                                        color: AppColors.gray300,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                          // 정의되지 않은 구장: 텍스트필드
                            Container(
                              width: 320.w,
                              height: 48.h,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gray50,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: MediaQuery(
                                data: MediaQuery.of(
                                  context,
                                ).copyWith(textScaleFactor: 1.0),
                                child: TextField(
                                  controller: zoneController,
                                  decoration: InputDecoration.collapsed(
                                    hintText: '구역을 입력해 주세요',
                                    hintStyle: AppFonts.b3_sb_long(
                                      context,
                                    ).copyWith(color: AppColors.gray300),
                                  ),
                                  style: AppFonts.b3_sb_long(context).copyWith(
                                    color: AppColors.trans900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 블럭
                    Positioned(
                      top: 182.h,
                      left: 20.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              FixedText(
                                '블럭',
                                style: AppFonts.c1_b(
                                  context,
                                ).copyWith(color: AppColors.gray400),
                              ),
                              SizedBox(width: 2.w),
                              FixedText(
                                '*',
                                style: AppFonts.c1_b(
                                  context,
                                ).copyWith(color: AppColors.pri200),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          if (isDefinedStadium)
                          // 정의된 구장: 드롭다운
                            GestureDetector(
                              onTap: selectedZone == null
                                  ? null
                                  : () {
                                setState(() {
                                  isBlockDropdownOpen = !isBlockDropdownOpen;
                                });
                              },
                              child: Container(
                                width: 320.w,
                                height: 48.h,
                                padding: EdgeInsets.only(left: 12.w, right: 16.w),
                                decoration: BoxDecoration(
                                  color: AppColors.gray50,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: FixedText(
                                        selectedBlock ?? (selectedZone == null
                                            ? '구역을 먼저 선택해 주세요'
                                            : '블럭을 선택해 주세요'),
                                        style: AppFonts.b3_sb_long(
                                          context,
                                        ).copyWith(
                                          color: selectedBlock != null
                                              ? AppColors.trans900
                                              : AppColors.gray300,
                                        ),
                                      ),
                                    ),
                                    Transform.rotate(
                                      angle: isBlockDropdownOpen ? 3.14159 : 0,
                                      child: SvgPicture.asset(
                                        AppImages.dropdown,
                                        width: 24.w,
                                        height: 24.h,
                                        color: AppColors.gray300,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                          // 정의되지 않은 구장: 텍스트필드
                            Container(
                              width: 320.w,
                              height: 48.h,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gray50,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: MediaQuery(
                                data: MediaQuery.of(
                                  context,
                                ).copyWith(textScaleFactor: 1.0),
                                child: TextField(
                                  controller: blockController,
                                  decoration: InputDecoration.collapsed(
                                    hintText: '블럭을 입력해 주세요',
                                    hintStyle: AppFonts.b3_sb_long(
                                      context,
                                    ).copyWith(color: AppColors.gray300),
                                  ),
                                  style: AppFonts.b3_sb_long(context).copyWith(
                                    color: AppColors.trans900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 열 입력
                    Positioned(
                      top: 278.h,
                      left: 20.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FixedText(
                            '열',
                            style: AppFonts.c1_b(
                              context,
                            ).copyWith(color: AppColors.gray400),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            width: 154.w,
                            height: 52.h,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 15.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gray50,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: MediaQuery(
                              data: MediaQuery.of(
                                context,
                              ).copyWith(textScaleFactor: 1.0),
                              child: TextField(
                                controller: rowController,
                                decoration: InputDecoration.collapsed(
                                  hintText: '열',
                                  hintStyle: AppFonts.b3_sb_long(
                                    context,
                                  ).copyWith(color: AppColors.gray300),
                                ),
                                style: AppFonts.b3_sb_long(context).copyWith(
                                  color: AppColors.gray950,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 번호 입력
                    Positioned(
                      top: 278.h,
                      left: 186.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              FixedText(
                                '번호',
                                style: AppFonts.c1_b(
                                  context,
                                ).copyWith(color: AppColors.gray400),
                              ),
                              SizedBox(width: 2.w),
                              FixedText(
                                '*',
                                style: AppFonts.c1_b(
                                  context,
                                ).copyWith(color: AppColors.pri200),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            width: 154.w,
                            height: 52.h,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 15.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gray50,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: MediaQuery(
                              data: MediaQuery.of(
                                context,
                              ).copyWith(textScaleFactor: 1.0),
                              child: TextField(
                                controller: numController,
                                decoration: InputDecoration.collapsed(
                                  hintText: '번호',
                                  hintStyle: AppFonts.b3_sb_long(
                                    context,
                                  ).copyWith(color: AppColors.gray300),
                                ),
                                style: AppFonts.b3_sb_long(context).copyWith(
                                  color: AppColors.gray950,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    // 완료 버튼 활성화 상태 업데이트
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 완료 버튼
                    Positioned(
                      top: screenHeight * (425 / baseH),
                      left: 0,
                      right: 0,
                      height: 88.h,
                      child: Container(
                        width: 360.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: AppColors.gray20, width: 1),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 10.h),
                        child: SizedBox(
                          width: 320.w,
                          height: 54.h,
                          child: ElevatedButton(
                            onPressed: isComplete
                                ? () {
                              String seatText;
                              if (isDefinedStadium) {
                                // 정의된 구장: 드롭다운 값 사용
                                seatText = rowController.text.isEmpty
                                    ? '$selectedZone ${selectedBlock}블럭 ${numController.text}번'
                                    : '$selectedZone ${selectedBlock}블럭 ${rowController.text}열 ${numController.text}번';
                              } else {
                                // 정의되지 않은 구장: 텍스트필드 값 사용
                                seatText = rowController.text.isEmpty
                                    ? '${zoneController.text} ${blockController.text}블럭 ${numController.text}번'
                                    : '${zoneController.text} ${blockController.text}블럭 ${rowController.text}열 ${numController.text}번';
                              }
                              Navigator.pop(ctx, seatText);
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              isComplete
                                  ? AppColors.gray700
                                  : AppColors.gray200,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              padding: EdgeInsets.all(10.w),
                              elevation: 0,
                            ),
                            child: FixedText(
                              '완료',
                              style: AppFonts.b2_b(
                                context,
                              ).copyWith(color: AppColors.gray20),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 드롭다운 리스트들 (정의된 구장에서만 표시)
                    if (isDefinedStadium && isZoneDropdownOpen)
                      Positioned(
                        top: 160.h,
                        left: 20.w,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: 320.w,
                            constraints: BoxConstraints(
                              maxHeight: 220.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gray50,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: zones.length,
                              separatorBuilder: (context, index) {
                                return Container(
                                  height: 1,
                                  color: AppColors.gray100,
                                  margin: EdgeInsets.symmetric(horizontal: 12.w),
                                );
                              },
                              itemBuilder: (context, index) {
                                final zone = zones[index];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedZone = zone;
                                      selectedBlock = null; // 구역 변경시 블럭 초기화
                                      blocks = StadiumSeatInfo.getBlocks(mappedStadium ?? stadium, zone); // 블럭 목록 업데이트
                                      isZoneDropdownOpen = false;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 10.h,
                                      horizontal: 13.w,
                                    ),
                                    child: FixedText(
                                      zone,
                                      style: AppFonts.b3_sb_long(context).copyWith(
                                        color: AppColors.trans900,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                    // 블럭 드롭다운 리스트 (정의된 구장에서만 표시)
                    if (isDefinedStadium && isBlockDropdownOpen)
                      Positioned(
                        top: 256.h,
                        left: 20.w,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: 320.w,
                            constraints: BoxConstraints(
                              maxHeight: 220.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gray50,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: blocks.length,
                              separatorBuilder: (context, index) {
                                return Container(
                                  height: 1,
                                  color: AppColors.gray100,
                                  margin: EdgeInsets.symmetric(horizontal: 12.w),
                                );
                              },
                              itemBuilder: (context, index) {
                                final block = blocks[index];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedBlock = block;
                                      isBlockDropdownOpen = false;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 10.h,
                                      horizontal: 13.w,
                                    ),
                                    child: FixedText(
                                      block,
                                      style: AppFonts.b3_sb_long(context).copyWith(
                                        color: AppColors.trans900,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}