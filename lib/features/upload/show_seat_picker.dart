import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/utils/size_utils.dart';

// 구장별 좌석 정보 매핑
class StadiumSeatInfo {
  static const Map<String, Map<String, List<String>>>stadiumSeats= {
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
      'SKY BOX': [],
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
      '휠체어석': [],
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
      '내야 패밀리석': [],
      'SKY 하단지정석': ['U-1구역', 'U-2구역', 'U-3구역', 'U-4구역', 'U-5구역', 'U-6구역', 'U-7구역', 'U-8구역', 'U-9구역', 'U-10구역', 'U-11구역', 'U-12구역', 'U-13구역', 'U-14구역', 'U-15구역', 'U-16구역', 'U-17구역', 'U-18구역', 'U-19구역', 'U-20구역', 'U-21구역', 'U-22구역', 'U-23구역', 'U-24구역', 'U-25구역', 'U-26구역', 'U-27구역', 'U-28구역', 'U-29구역', 'U-30구역', 'U-31구역'],
      '1루 SKY 상단지정석': ['U-1구역', 'U-2구역', 'U-3구역', 'U-4구역', 'U-5구역', 'U-6구역', 'U-7구역', 'U-8구역', 'U-9구역'],
      '중앙 SKY 상단지정석': ['U-10구역', 'U-11구역', 'U-12구역', 'U-13구역', 'U-14구역'],
      '3루 SKY 상단지정석': ['U-15구역', 'U-16구역', 'U-17구역', 'U-18구역', 'U-19구역', 'U-20구역', 'U-21구역', 'U-22구역', 'U-23구역', 'U-24구역', 'U-25구역', 'U-26구역', 'U-27구역', 'U-28구역', 'U-29구역', 'U-30구역', 'U-31구역'],
      '외야지정석': ['LF-1구역', 'LF-2구역', 'LF-3구역', 'LF-4구역', 'LF-5구역', 'LF-6구역', 'LF-7구역', 'LF-8구역', 'LF-9구역', 'LF-10구역', 'RF-1구역', 'RF-2구역', 'RF-3구역', 'RF-4구역', 'RF-5구역', 'RF-6구역', 'RF-7구역', 'RF-8구역', 'RF-9구역', 'RF-10구역'],
      '외야패밀리석': ['F-1구역', 'F-2구역'],
      '외야테이블석': ['TR-1구역', 'TR-2구역', 'TR-3구역', 'TR-4구역', 'TR-5구역', 'TR-6구역', 'TR-7구역'],
      '외야커플테이블석': ['MR-1구역', 'MR-2구역', 'MR-3구역', 'MR-4구역', 'MR-5구역', 'MR-6구역', 'MR-7구역', 'MR-8구역', 'MR-10구역', 'ML-1구역', 'ML-2구역', 'ML-3구역', 'ML-4구역', 'ML-5구역', 'ML-6구역', 'ML-7구역', 'ML-8구역', 'ML-10구역'],
      '루프탑 테이블석': [],
      '파티플로어 라이브석': [],
      '캠핑존': [],
      '잔디그린존': [],
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
      '챔피언석': [],
      '중앙테이블석': [],
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
      '외야석': [],
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
      '외야잔디/자유석': [],
      '외야 테이블석': ['501', '502', '503', '504', '505'],
      '위즈 캠핑존': ['4층', '5층'],
      '1루 휠체어석': ['111', '112', '113', '114', '115'],
      '3루 휠체어석': ['116', '117', '118', '119', '120', '121', '122', '123'],
    },
    '창원 NC파크': {
      '프리미엄석': ['112', '113', '114'],
      '1루 내야석': ['101', '102', '103', '104', '105', '106', '107', '108', '109', '110', '201', '202', '203', '204', '205', '206', '207', '208', '209', '210', '301', '302', '303', '304', '305', '306', '307', '401', '402', '403', '404'],
      '2루 내야석': ['115', '211', '212', '213', '214', '215', '308', '309', '310', '311', '325', '326'],
      '3루 내야석': ['116', '117', '118', '119', '120', '121', '122', '123', '124', '125', '216', '217', '218', '219', '220', '221', '222', '223', '312', '313', '314', '315', '316', '317', '318', '319', '320', '321', '322', '323', '324', '325', '326', '327', '328', '329', '330', '331', '332', '333', '425', '426', '431', '432', '433'],
      '미니테이블석': ['111', '118'],
      '테이블석': ['112', '113', '114', '115', '116', '117'],
      '피크닉테이블석': ['101', '102', '103', '104', '122', '123', '124', '125'],
      '라운드테이블석': ['219', '220', '221', '222', '223'],
      '외야잔디석(5인)': ['129'],
      '외야석': ['130', '131', '132', '133', '134', '135', '136', '137', '138'],
      '바베큐석': ['126', '127', '131', '132', '134', '135', '136'],
      '가족석(2인)': ['202', '203', '204', '205', '206', '207', '208', '209', '210', '211'],
      '불펜석': ['128'],
      '불펜가족석': ['128'],
      '휠체어석': ['105', '106', '107', '108', '109', '110', '111', '112', '113', '114', '115', '116', '117', '118', '119', '120', '121', '129', '130', '208', '209', '210', '211', '212', '213', '214', '215', '216', '217', '218', '219'],
      '스카이박스': ['416'],
      '노스피크캠프닉석(4인)': ['303', '304', '403', '404'],
      '노스피크캠프닉석(8인)': ['302', '402'],
      '카운터석': ['310', '311', '326', '409', '410', '411', '425', '426'],
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
      '그린존': [],
      '바비큐존': [],
      '외야파티덱': [],
      '외야패밀리존': [],
      '초가정자': [],
      '미니스카이박스': ['(M)SKY-L1', '(M)SKY-L2', '(M)SKY-L3', '(M)SKY-L4', '(M)SKY-R1', '(M)SKY-R2', '(M)SKY-R3', '(M)SKY-R4', '(M)SKY-R5', '(M)SKY-R6', '(M)SKY-R7', '(M)SKY-R8', '(M)SKY-R9', '(M)SKY-R10', '(M)SKY-R11', '(M)SKY-R12', '(M)SKY-R13', '(M)SKY-R14'],
      '스카이박스': ['SKY-L1', 'SKY-L2', 'SKY-L3', 'SKY-L4', 'SKY-L5', 'SKY-L6', 'SKY-L7', 'SKY-L8', 'SKY-L9', 'SKY-L10', 'SKY-L11', 'SKY-L12', 'SKY-L13', 'SKY-L14', 'SKY-L15', 'SKY-L16', 'SKY-L17', 'SKY-L18', 'SKY-R1', 'SKY-R2', 'SKY-R3', 'SKY-R4', 'SKY-R5', 'SKY-R6', 'SKY-R7', 'SKY-R8', 'SKY-R9', 'SKY-R10', 'SKY-R11', 'SKY-R12', 'SKY-R13', 'SKY-R14', 'SKY-R15', 'SKY-R16', 'SKY-R17', 'SKY-R18', 'SKY-VVIP', 'SKY-C1'],
    },
  };

  static String?mapOcrStadiumToSeatKey(String? ocrStadium) {
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
      if (cleaned.toLowerCase().contains(key.toLowerCase()) ||
          key.toLowerCase().contains(cleaned.toLowerCase())) {
        return key;
      }
    }

    // 매핑되지 않은 경우 null 반환
    return null;
  }

  static List<String>getZones(String? stadium) {
    // OCR 구장명을 먼저 매핑 시도
    final mappedStadium =mapOcrStadiumToSeatKey(stadium);
    final seatInfo =stadiumSeats[mappedStadium];
    if (seatInfo == null) return [];
    return seatInfo.keys.toList();
  }

  static List<String>getBlocks(String? stadium, String? zone) {
    if (zone == null) return [];
    // OCR 구장명을 먼저 매핑 시도
    final mappedStadium =mapOcrStadiumToSeatKey(stadium);
    final seatInfo =stadiumSeats[mappedStadium];
    if (seatInfo == null) return [];
    return seatInfo[zone] ?? [];
  }

  // 블럭이 있는지 찾는 함수
  static bool hasBlocks(String? stadium, String? zone) {
  final blocks = getBlocks(stadium, zone);
  return blocks.isNotEmpty;
  }
}

// 좌석 매핑 기반 파싱 함수
Map<String, String>? parseSeatStringWithMapping(String? text, {String? stadium}) {
  if (text == null || text.isEmpty || stadium == null) return null;

  print('🎫 좌석 파싱 시작: "$text", 구장: "$stadium"');

  // 구장의 모든 구역과 블럭 정보 가져오기
  final zones = StadiumSeatInfo.getZones(stadium);

  // 가장 긴 구역명부터 매칭 시도 (더 구체적인 매칭 우선)
  final sortedZones = List<String>.from(zones)
    ..sort((a, b) => b.length.compareTo(a.length));

  String? foundZone;
  String? foundBlock;
  String? foundRow;
  String? foundNum;

  // 1. 구역 찾기 (정확한 매칭)
  for (final zone in sortedZones) {
    if (text.contains(zone)) {
      foundZone = zone;
      print('✅ 구역 발견: $foundZone');

      // 해당 구역의 블럭들 가져오기
      final blocks = StadiumSeatInfo.getBlocks(stadium, zone);

      // 블럭이 있는 경우 블럭 찾기
      if (blocks.isNotEmpty) {
        // 가장 긴 블럭명부터 매칭 시도
        final sortedBlocks = List<String>.from(blocks)
          ..sort((a, b) => b.length.compareTo(a.length));

        for (final block in sortedBlocks) {
          if (text.contains(block)) {
            foundBlock = block;
            print('✅ 블럭 발견: $foundBlock');
            break;
          }
        }
      }

      // 정의된 블럭을 찾지 못한 경우, 블럭 앞 텍스트를 직접 추출
      if (foundBlock == null) {
        print('🔍 정의된 블럭을 찾지 못함. 블럭 앞 텍스트 추출 시도...');

        // "XXX블럭" 패턴에서 XXX 추출
        final blockPattern = RegExp(r'(\S+)블럭');
        final match = blockPattern.firstMatch(text);

        if (match != null) {
          foundBlock = match.group(1);
          print('✅ 블럭 앞 텍스트로 블럭 발견: $foundBlock');
        }
      }

      break;
    }
  }

  // 2. 열 찾기
  final rowPatterns = [
    r'(\d+)열',
    r'(\d+)row',
    r'([A-Z])열',
    r'([A-Z])row',
  ];

  for (final pattern in rowPatterns) {
    final regex = RegExp(pattern, caseSensitive: false);
    final match = regex.firstMatch(text);
    if (match != null) {
      foundRow = match.group(1);
      print('✅ 열 발견: $foundRow');
      break;
    }
  }

  // 3. 번호 찾기
  final numberPatterns = [
    r'(\d+)번',
    r'(\d+)호',
    r'(\d+)seat',
    r'No\.?\s*(\d+)',
  ];

  for (final pattern in numberPatterns) {
    final regex = RegExp(pattern, caseSensitive: false);
    final match = regex.firstMatch(text);
    if (match != null) {
      foundNum = match.group(1);
      print('✅ 번호 발견: $foundNum');
      break;
    }
  }

  // 번호를 찾지 못한 경우 마지막 숫자를 번호로 간주
  if (foundNum == null) {
    final simpleNumber = RegExp(r'\b(\d{1,4})\b');
    final matches = simpleNumber.allMatches(text);
    if (matches.isNotEmpty) {
      foundNum = matches.last.group(1);
      print('✅ 마지막 숫자를 번호로 인식: $foundNum');
    }
  }

  // 결과 반환
  final result = <String, String>{};
  if (foundZone != null) result['zone'] = foundZone;
  if (foundBlock != null) result['block'] = foundBlock;
  if (foundRow != null) result['row'] = foundRow;
  if (foundNum != null) result['num'] = foundNum;

  print('🎫 파싱 결과: $result');
  return result.isNotEmpty ? result : null;
}


//===========================================================================================
//===========================================================================================
/// 좌석 선택용 BottomSheet - 완전한 버전
Future<String?> showSeatInputDialog(
    BuildContext context, {
      String? initial,
      String? stadium,
      String? previousStadium, // 이전 구장 정보 추가
    }) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.trans700.withOpacity(0.7),
    useSafeArea: false,
    builder: (_) => _SeatInputBottomSheet(
      currentStadium: stadium,
      previousStadium: previousStadium,
      initialSeatString: initial,
    ),
  );
}

class _SeatInputBottomSheet extends StatefulWidget {
  final String? currentStadium;
  final String? previousStadium;
  final String? initialSeatString;

  const _SeatInputBottomSheet({
    required this.currentStadium,
    required this.previousStadium,
    required this.initialSeatString,
  });

  @override
  State<_SeatInputBottomSheet> createState() => _SeatInputBottomSheetState();
}

class _SeatInputBottomSheetState extends State<_SeatInputBottomSheet> {
  // FocusNodes
  late FocusNode _zoneTextFocusNode;
  late FocusNode _blockTextFocusNode;
  late FocusNode _rowFocusNode;
  late FocusNode _numFocusNode;

  // Controllers
  late TextEditingController _zoneController;
  late TextEditingController _blockController;
  late TextEditingController _rowController;
  late TextEditingController _numController;

  // State variables
  String? selectedZone;
  String? selectedBlock;
  bool isZoneDropdownOpen = false;
  bool isBlockDropdownOpen = false;

  late List<String> zones;
  late List<String> blocks;
  late bool isDefinedStadium;
  bool hasBlocksForSelectedZone = false;

  // 구장 변경 감지를 위한 변수
  bool wasStadiumChanged = false;

  @override
  void initState() {
    super.initState();

    // FocusNodes 초기화
    _zoneTextFocusNode = FocusNode();
    _blockTextFocusNode = FocusNode();
    _rowFocusNode = FocusNode();
    _numFocusNode = FocusNode();

    // 구장 변경 감지 (이전 구장과 현재 구장 비교)
    wasStadiumChanged = widget.previousStadium != null &&
        widget.previousStadium != widget.currentStadium;

    print('🏟️ 구장 변경 여부: $wasStadiumChanged (${widget.previousStadium} → ${widget.currentStadium})');

    // 초기화
    _initializeSeatData();

    // 포커스 리스너 추가
    _zoneTextFocusNode.addListener(() {
      if (_zoneTextFocusNode.hasFocus) _closeDropdowns();
    });
    _blockTextFocusNode.addListener(() {
      if (_blockTextFocusNode.hasFocus) _closeDropdowns();
    });
    _rowFocusNode.addListener(() {
      if (_rowFocusNode.hasFocus) _closeDropdowns();
    });
    _numFocusNode.addListener(() {
      if (_numFocusNode.hasFocus) _closeDropdowns();
    });
  }

  void _initializeSeatData() {
    final mappedStadium = StadiumSeatInfo.mapOcrStadiumToSeatKey(widget.currentStadium);

    // 구장 변경되지 않았다면 기존 좌석 정보 파싱 (재매칭)
    // 구장이 변경되었다면 좌석 정보 초기화
    Map<String, String>? parsed;
    if (!wasStadiumChanged && widget.initialSeatString != null) {
      parsed = parseSeatStringWithMapping(widget.initialSeatString, stadium: mappedStadium);
      print('🎫 좌석 재매칭 수행: ${widget.initialSeatString} → $parsed');
    } else if (wasStadiumChanged) {
      print('🏟️ 구장 변경으로 인한 좌석 정보 초기화');
    }

    // Controllers 초기화
    _zoneController = TextEditingController(text: parsed?['zone'] ?? '');
    _blockController = TextEditingController(text: parsed?['block'] ?? '');
    _rowController = TextEditingController(text: parsed?['row'] ?? '');
    _numController = TextEditingController(text: parsed?['num'] ?? '');

    // 초기 상태 설정
    selectedZone = parsed?['zone'];
    selectedBlock = parsed?['block'];

    zones = StadiumSeatInfo.getZones(mappedStadium ?? widget.currentStadium);
    blocks = StadiumSeatInfo.getBlocks(mappedStadium ?? widget.currentStadium, selectedZone);
    isDefinedStadium = mappedStadium != null && StadiumSeatInfo.stadiumSeats.containsKey(mappedStadium);

    print('🏟️ mappedStadium: $mappedStadium');
    print('🏟️ isDefinedStadium: $isDefinedStadium');

    _updateBlocksForZone();
  }

  @override
  void dispose() {
    _zoneTextFocusNode.dispose();
    _blockTextFocusNode.dispose();
    _rowFocusNode.dispose();
    _numFocusNode.dispose();
    _zoneController.dispose();
    _blockController.dispose();
    _rowController.dispose();
    _numController.dispose();
    super.dispose();
  }

  void _closeDropdowns() {
    if (mounted) {
      setState(() {
        isZoneDropdownOpen = false;
        isBlockDropdownOpen = false;
      });
    }
  }

  void _updateBlocksForZone() {
    final mappedStadium = StadiumSeatInfo.mapOcrStadiumToSeatKey(widget.currentStadium);
    if (isDefinedStadium && selectedZone != null) {
      hasBlocksForSelectedZone = StadiumSeatInfo.hasBlocks(mappedStadium ?? widget.currentStadium, selectedZone);
      blocks = StadiumSeatInfo.getBlocks(mappedStadium ?? widget.currentStadium, selectedZone);
    } else {
      hasBlocksForSelectedZone = false;
      blocks = [];
    }
  }

  bool get isComplete {
    if (isDefinedStadium) {
      if (hasBlocksForSelectedZone) {
        return selectedZone != null && selectedBlock != null && _numController.text.isNotEmpty;
      } else {
        return selectedZone != null && _numController.text.isNotEmpty;
      }
    } else {
      return _zoneController.text.isNotEmpty && _numController.text.isNotEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: keyboardHeight * 0.5),
      child: Container(
        height: scaleHeight(537),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(scaleHeight(20)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: GestureDetector(
            onTap: () {
              _closeDropdowns();
              FocusScope.of(context).unfocus();
            },
            child: Stack(
              children: [
                Column(
                  children: [
                    // 헤더 영역
                    Container(
                      height: scaleHeight(60),
                      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: SvgPicture.asset(
                                AppImages.backBlack,
                                width: scaleWidth(24),
                                height: scaleHeight(24),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Center(
                            child: FixedText(
                              '좌석',
                              style: AppFonts.suite.head_sm_700(context).copyWith(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 폼 영역
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          SizedBox(height: scaleHeight(26)),

                          // 구역 레이블
                          Padding(
                            padding: EdgeInsets.only(left: scaleWidth(20)),
                            child: Row(
                              children: [
                                FixedText('구역', style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray600,),),
                                SizedBox(width: scaleWidth(2)),
                                FixedText('*', style: AppFonts.suite.c1_b(context).copyWith(color: AppColors.pri700,),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: scaleHeight(4)),
                          // 구역 입력 필드
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                            child: isDefinedStadium
                                ? _buildZoneDropdown()
                                : _buildZoneTextField(),
                          ),

                          SizedBox(height: scaleHeight(28)),

                          // 블럭 레이블
                          Padding(
                            padding: EdgeInsets.only(left: scaleWidth(20)),
                            child: Row(
                              children: [
                                FixedText('블럭', style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray600,),),
                                SizedBox(width: scaleWidth(2)),
                                if (isDefinedStadium && hasBlocksForSelectedZone)
                                  FixedText('*', style: AppFonts.suite.c1_b(context).copyWith(color: AppColors.pri700,),),
                              ],
                            ),
                          ),
                          SizedBox(height: scaleHeight(4)),
                          // 블럭 입력 필드
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                            child: isDefinedStadium && hasBlocksForSelectedZone
                                ? _buildBlockDropdown()
                                : _buildBlockTextField(),
                          ),

                          SizedBox(height: scaleHeight(28)),

                          // 열/번호
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      FixedText('열', style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray600,),),
                                      SizedBox(height: scaleHeight(4)),
                                      _buildRowTextField(),
                                    ],
                                  ),
                                ),
                                SizedBox(width: scaleWidth(12)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          FixedText('번호', style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray600,),),
                                          SizedBox(width: scaleWidth(2)),
                                          FixedText('*', style: AppFonts.suite.c1_b(context).copyWith(color: AppColors.pri700,),),
                                        ],
                                      ),
                                      SizedBox(height: scaleHeight(4)),
                                      _buildNumberTextField(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 완료 버튼 영역
                    Container(
                      width: double.infinity,
                      height: scaleHeight(88),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppColors.gray20,
                            width: 1,
                          ),
                        ),
                      ),
                      padding: EdgeInsets.only(
                        top: scaleHeight(24),
                        right: scaleWidth(20),
                        bottom: scaleHeight(10),
                        left: scaleWidth(20),
                      ),
                      child: ElevatedButton(
                        onPressed: isComplete
                            ? () {
                          String seatText = _buildSeatText();
                          Navigator.pop(context, seatText);
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isComplete
                              ? AppColors.gray700
                              : AppColors.gray200,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(scaleHeight(16)),),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: Center(
                          child: FixedText(
                            '완료',
                            style: AppFonts.suite.head_sm_700(context).copyWith(color: AppColors.gray20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (isDefinedStadium && isZoneDropdownOpen) _buildZoneDropdownOverlay(),
                if (isDefinedStadium && isBlockDropdownOpen && hasBlocksForSelectedZone) _buildBlockDropdownOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 구역 컨테이너
  Widget _buildZoneDropdown() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isZoneDropdownOpen = !isZoneDropdownOpen;
          if (isZoneDropdownOpen) {
            isBlockDropdownOpen = false;
          }
        });
        FocusScope.of(context).unfocus();
      },
      child: Container(
        height: scaleHeight(52),
        padding: EdgeInsets.only(
          top: scaleHeight(15),
          right: scaleWidth(16),
          bottom: scaleHeight(15),
          left: scaleWidth(16),
        ),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(scaleHeight(8)),
          border: Border.all(
            color: isZoneDropdownOpen ? AppColors.pri700 : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FixedText(
                selectedZone ?? '구역을 선택해 주세요',
                style: AppFonts.pretendard.body_sm_400(context).copyWith(
                  color: isZoneDropdownOpen
                      ? AppColors.gray900
                      : (selectedZone != null ? AppColors.gray900 : AppColors.gray300),
                ),
              ),
            ),
            Transform.rotate(
              angle: isZoneDropdownOpen ? 3.14159 : 0,
              child: SvgPicture.asset(
                AppImages.dropdown,
                width: scaleWidth(24),
                height: scaleHeight(24),
                color: AppColors.gray300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //구역 텍스트필드일 때
  Widget _buildZoneTextField() {
    return Container(
      height: scaleHeight(52),
      padding: EdgeInsets.only(
        top: scaleHeight(15),
        right: scaleWidth(16),
        bottom: scaleHeight(15),
        left: scaleWidth(16),
      ),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(scaleHeight(8)),
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: TextField(
          controller: _zoneController,
          focusNode: _zoneTextFocusNode,
          decoration: InputDecoration.collapsed(
            hintText: '구역을 입력해 주세요',
            hintStyle: AppFonts.pretendard.body_sm_400(context).copyWith(
              color: AppColors.gray300,
            ),
          ),
          style: AppFonts.pretendard.body_sm_400(context).copyWith(
            color: AppColors.gray900,
          ),
          onChanged: (value) => setState(() {}),
        ),
      ),
    );
  }

  /// 블럭 컨테이너
  Widget _buildBlockDropdown() {
    return GestureDetector(
      onTap: () {
        if (selectedZone == null) {
          _showSnackBar('구역을 먼저 선택해 주세요');
          return;
        }

        setState(() {
          isBlockDropdownOpen = !isBlockDropdownOpen;
          if (isBlockDropdownOpen) {
            isZoneDropdownOpen = false;
          }
        });
        FocusScope.of(context).unfocus();
      },
      child: Container(
        height: scaleHeight(52),
        padding: EdgeInsets.only(
          top: scaleHeight(15),
          right: scaleWidth(16),
          bottom: scaleHeight(15),
          left: scaleWidth(16),
        ),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(scaleHeight(8)),
          border: Border.all(
            color: isBlockDropdownOpen ? AppColors.pri700 : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FixedText(
                selectedBlock ?? '블럭을 선택해 주세요',
                style: AppFonts.pretendard.body_sm_400(context).copyWith(
                  color: isBlockDropdownOpen
                      ? AppColors.gray900
                      : (selectedBlock != null ? AppColors.gray900 : AppColors.gray300),
                ),
              ),
            ),
            Transform.rotate(
              angle: isBlockDropdownOpen ? 3.14159 : 0,
              child: SvgPicture.asset(
                AppImages.dropdown,
                width: scaleWidth(24),
                height: scaleHeight(24),
                color: AppColors.gray300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //블럭 텍스트필드일 때
  Widget _buildBlockTextField() {
    return Container(
      height: scaleHeight(52),
      padding: EdgeInsets.only(
        top: scaleHeight(15),
        right: scaleWidth(16),
        bottom: scaleHeight(15),
        left: scaleWidth(16),
      ),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(scaleHeight(8)),
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: TextField(
          controller: _blockController,
          focusNode: _blockTextFocusNode,
          decoration: InputDecoration.collapsed(
            hintText: '블럭을 입력해 주세요',
            hintStyle: AppFonts.pretendard.body_sm_400(context).copyWith(
              color: AppColors.gray300,
            ),
          ),
          style: AppFonts.pretendard.body_sm_400(context).copyWith(
            color: AppColors.trans900,
          ),
          onChanged: (value) => setState(() {}),
        ),
      ),
    );
  }

  /// 열 텍스트필드
  Widget _buildRowTextField() {
    return Container(
      height: scaleHeight(52),
      padding: EdgeInsets.only(
        top: scaleHeight(15),
        right: scaleWidth(16),
        bottom: scaleHeight(15),
        left: scaleWidth(16),
      ),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(scaleHeight(8)),
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: TextField(
          controller: _rowController,
          focusNode: _rowFocusNode,
          decoration: InputDecoration.collapsed(
            hintText: '열',
            hintStyle: AppFonts.pretendard.body_sm_400(context).copyWith(
              color: AppColors.gray300,
            ),
          ),
          style: AppFonts.pretendard.body_sm_400(context).copyWith(
            color: AppColors.gray900,
          ),
          onChanged: (value) => setState(() {}),
        ),
      ),
    );
  }

  /// 번호 텍스트필드
  Widget _buildNumberTextField() {
    return Container(
      height: scaleHeight(52),
      padding: EdgeInsets.only(
        top: scaleHeight(15),
        right: scaleWidth(16),
        bottom: scaleHeight(15),
        left: scaleWidth(16),
      ),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(scaleHeight(8)),
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: TextField(
          controller: _numController,
          focusNode: _numFocusNode,
          decoration: InputDecoration.collapsed(
            hintText: '번호',
            hintStyle: AppFonts.pretendard.body_sm_400(context).copyWith(
              color: AppColors.gray300,
            ),
          ),
          style: AppFonts.pretendard.body_sm_400(context).copyWith(
            color: AppColors.gray900,
          ),
          onChanged: (value) => setState(() {}),
        ),
      ),
    );
  }

  /// 좌석 키워드 매칭
  String _buildSeatText() {
    String cleanText(String text, String keyword) {
      return text.replaceAll(RegExp('$keyword\$'), '').trim();
    }

    if (isDefinedStadium) {
      if (hasBlocksForSelectedZone) {
        final cleanBlock = cleanText(_blockController.text.isEmpty ? selectedBlock ?? '' : _blockController.text, '블럭');
        final cleanRow = cleanText(_rowController.text, '열');
        final cleanNum = cleanText(_numController.text, '번');

        return cleanRow.isEmpty
            ? '$selectedZone ${cleanBlock}블럭 ${cleanNum}번'
            : '$selectedZone ${cleanBlock}블럭 ${cleanRow}열 ${cleanNum}번';
      } else {
        final cleanBlock = cleanText(_blockController.text, '블럭');
        final cleanRow = cleanText(_rowController.text, '열');
        final cleanNum = cleanText(_numController.text, '번');

        if (cleanBlock.isNotEmpty) {
          return cleanRow.isEmpty
              ? '$selectedZone ${cleanBlock}블럭 ${cleanNum}번'
              : '$selectedZone ${cleanBlock}블럭 ${cleanRow}열 ${cleanNum}번';
        } else {
          return cleanRow.isEmpty
              ? '$selectedZone ${cleanNum}번'
              : '$selectedZone ${cleanRow}열 ${cleanNum}번';
        }
      }
    } else {
      final cleanZone = cleanText(_zoneController.text, '석');
      final cleanBlock = cleanText(_blockController.text, '블럭');
      final cleanRow = cleanText(_rowController.text, '열');
      final cleanNum = cleanText(_numController.text, '번');

      if (cleanBlock.isNotEmpty) {
        return cleanRow.isEmpty
            ? '${cleanZone} ${cleanBlock}블럭 ${cleanNum}번'
            : '${cleanZone} ${cleanBlock}블럭 ${cleanRow}열 ${cleanNum}번';
      } else {
        return cleanRow.isEmpty
            ? '${cleanZone} ${cleanNum}번'
            : '${cleanZone} ${cleanRow}열 ${cleanNum}번';
      }
    }
  }

  /// 구역 드롭다운
  Widget _buildZoneDropdownOverlay() {
    final topPosition = scaleHeight(60 + 26 + 18 + 4 + 52 + 8);

    return Positioned(
      top: topPosition,
      left: scaleWidth(20),
      right: scaleWidth(20),
      child: Container(
        constraints: BoxConstraints(maxHeight: scaleHeight(200)),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(scaleHeight(8)),
        ),
        padding: EdgeInsets.only(
          top: scaleHeight(8),
          right: scaleWidth(20),
          bottom: scaleHeight(8),
          left: scaleWidth(20),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: zones.length,
          itemBuilder: (context, index) {
            final zone = zones[index];
            final isLast = index == zones.length - 1;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedZone = zone;
                  selectedBlock = null;
                  blocks = StadiumSeatInfo.getBlocks(
                      StadiumSeatInfo.mapOcrStadiumToSeatKey(widget.currentStadium) ?? widget.currentStadium,
                      zone
                  );
                  isZoneDropdownOpen = false;
                  _updateBlocksForZone();
                });
              },
              child: Container(
                height: scaleHeight(48),
                color: AppColors.gray50,
                child: Column(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FixedText(
                          zone,
                          style: AppFonts.pretendard.body_sm_500(context).copyWith(
                            color: AppColors.gray900,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast) ...[
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      SizedBox(height: scaleHeight(6)),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 블럭 드롭다운
  Widget _buildBlockDropdownOverlay() {
    final topPosition = scaleHeight(60 + 26 + 18 + 4 + 52 + 28 + 18 + 4 + 52 + 8);

    return Positioned(
      top: topPosition,
      left: scaleWidth(20),
      right: scaleWidth(20),
      child: Container(
        constraints: BoxConstraints(maxHeight: scaleHeight(200)),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(scaleHeight(8)),
        ),
        padding: EdgeInsets.only(
          top: scaleHeight(8),
          right: scaleWidth(20),
          bottom: scaleHeight(8),
          left: scaleWidth(20),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: blocks.length,
          itemBuilder: (context, index) {
            final block = blocks[index];
            final isLast = index == blocks.length - 1;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedBlock = block;
                  isBlockDropdownOpen = false;
                });
              },
              child: Container(
                height: scaleHeight(48),
                color: AppColors.gray50,
                child: Column(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FixedText(
                          block,
                          style: AppFonts.pretendard.body_sm_500(context).copyWith(
                            color: AppColors.gray900,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast) ...[
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      SizedBox(height: scaleHeight(6)),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 20,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Color(0xFF323232),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              message,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}