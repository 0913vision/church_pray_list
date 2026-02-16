# Prayer List v2 - Flutter Migration Guide for AI Agents

## 프로젝트 개요

이 프로젝트는 React Native로 작성된 Prayer List 앱을 Flutter로 재작성하는 마이그레이션 프로젝트입니다.

### 목표
- 모든 기능과 UI/UX를 동일하게 유지
- Flutter의 최적화된 성능 활용
- 깨끗하고 유지보수 가능한 코드 작성
- 단계별 구현 및 테스트

---

## 중요 원칙

### 1. React Native 로직을 그대로 옮기지 마라
- React의 패턴(Context, useEffect, useState 등)을 Flutter로 직역하지 말 것
- Flutter의 방식으로 같은 **기능**을 구현할 것
- 예: DeviceEventEmitter → Navigator.pop(context, result)

### 2. 기능 중심으로 접근하라
- "어떻게"가 아닌 "무엇을" 구현해야 하는지에 집중
- 레거시 코드는 참고용일 뿐, 복사 대상이 아님

### 3. Flutter 베스트 프랙티스를 따르라
- 상태 관리: Riverpod 사용 (선택사항: setState + InheritedWidget도 가능)
- 라우팅: go_router 사용
- 비동기: async/await, Future, Stream
- UI: Material Design 3

---

## 레거시 앱 분석 요약

### 위치
`/Users/kim-yoochan/coding/pray_list_web/`

### 주요 기능
1. **기도제목 조회**
   - 캐시 먼저 로드 → 서버 데이터로 업데이트
   - Pull-to-Refresh
   - 폰트 크기 조절 (80-200%)
   - 다크/라이트 테마

2. **기도제목 편집** (작성자만)
   - 이전 기도제목 불러오기
   - Section/Item/Subsection 구조로 편집
   - 유효성 검사
   - Supabase에 저장

3. **배경음악**
   - 자동 재생 (모바일)
   - Fade in/out (1초)
   - Edit 화면 진입 시 중단, 이탈 시 재개

4. **인증/권한**
   - 카카오 로그인
   - Supabase allowed_users 테이블로 권한 체크
   - 작성자/뷰어 구분

5. **버전 관리**
   - 앱 시작 시 버전 체크
   - 최소 요구 버전보다 낮으면 강제 업데이트

### 데이터 구조

```typescript
interface PrayerData {
  title: string;              // "2025년 1월 4일 기도제목"
  sections: PrayerSection[];
}

interface PrayerSection {
  name: string;                // 이름/주제
  items?: string[];            // 공통 기도제목
  subsections?: PrayerSubsection[];
}

interface PrayerSubsection {
  name: string;                // 세부 주제
  items: string[];             // 세부 기도제목
}
```

### 색상 (정확히 보존)
- Primary Light: `#4B5563` (gray-600)
- Primary Dark: `#FCD34D` (amber-300)
- Background Light: `#FFFFFF`
- Background Dark: `#171717` (neutral-900)
- Text Primary Light: `#000000`
- Text Primary Dark: `#FFFFFF`

---

## 구현 단계

### 진행 방식
1. 각 단계별 문서(`docs/STEP_XX_*.md`)를 **순서대로** 읽고 구현
2. 한 단계의 "완료 조건"을 모두 충족한 후 다음 단계로 진행
3. 각 단계 완료 후 반드시 테스트

### 단계 목록

| 단계 | 문서 | 설명 |
|------|------|------|
| 0 | `STEP_00_PROJECT_INIT.md` | 프로젝트 초기화, 폴더 구조, 의존성 |
| 1 | `STEP_01_CONFIGURATION.md` | 색상, 테마, Provider (오디오, 폰트, 테마) |
| 2 | `STEP_02_MAIN_SCREEN.md` | Main Screen UI, PTR, TopBar |
| 3 | `STEP_03_EDIT_SCREEN.md` | Edit Screen UI, 오디오 중단/재개 |
| 4 | `STEP_04_SUPABASE_CONNECTION.md` | Supabase 클라이언트, Repository |
| 5 | `STEP_05_MAIN_SUPABASE.md` | Main Screen 데이터 연결, 캐싱 |
| 6 | `STEP_06_EDIT_SUPABASE.md` | Edit Screen 로드/저장, 유효성 검사 |
| 7 | `STEP_07_LOADING_SCREEN.md` | 로딩 스크린 (1초 후 분기) |
| 8 | `STEP_08_LOGIN_SCREEN.md` | 로그인 창 (임시 버튼) |
| 9 | `STEP_09_UNAUTHORIZED_SCREEN.md` | 권한 없음 화면 |
| 10 | `STEP_10_UPDATE_REQUIRED_SCREEN.md` | 업데이트 필수 화면 |
| 11 | `STEP_11_KAKAO_API.md` | 카카오 SDK 연동 |
| 12 | `STEP_12_KAKAO_LOGIN_INTEGRATION.md` | 카카오 로그인 통합, 세션 관리 |

---

## 핵심 구현 요구사항

### 1. 캐시 우선 전략 (Cache-First)

**로직:**
```dart
// 1. SharedPreferences에서 즉시 로드
final cached = await localStorage.getCachedPrayer();
if (cached != null) {
  setState(() => prayerData = cached);
}

// 2. 서버에서 최신 데이터 가져오기
final fresh = await repository.fetchLatestPrayer();
if (fresh != null) {
  await localStorage.cachePrayer(fresh);
  setState(() => prayerData = fresh);
}
```

**적용 위치:**
- Main Screen 초기 로드
- PTR (Pull-to-Refresh)

### 2. 자동 PTR 실행

**시점:**
1. 앱 시작 후 Main Screen 진입 시 (1회)
2. Edit Screen에서 저장 성공 후 Main Screen 복귀 시 (1회)

**구현:**
```dart
// Main Screen
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _handleRefresh(); // 자동 PTR
  });
}

// Edit Screen에서 저장 후
context.pop(true); // true = 저장 성공

// Main Screen에서
void _navigateToEdit() {
  context.push('/edit').then((result) {
    if (result == true) {
      _handleRefresh(); // 자동 PTR
    }
  });
}
```

### 3. 오디오 상태 관리

**요구사항:**
- Edit Screen 진입 시: 현재 재생 상태 저장 → 재생 중이면 중단
- Edit Screen 이탈 시: 원래 재생 중이었으면 다시 재생

**구현:**
```dart
// Edit Screen
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final isPlaying = ref.read(audioProvider);
    ref.read(previousAudioStateProvider.notifier).state = isPlaying;

    if (isPlaying) {
      ref.read(audioProvider.notifier).pause();
    }
  });
}

@override
void dispose() {
  final wasPlaying = ref.read(previousAudioStateProvider);
  if (wasPlaying) {
    ref.read(audioProvider.notifier).play();
  }
  super.dispose();
}
```

### 4. 인증 흐름

**Loading Screen에서 순서대로 체크:**
```
1. 저장된 세션 불러오기 (SharedPreferences)
   ↓
2. 로그인 여부 체크
   - 없으면 → Login Screen
   ↓
3. 권한 체크 (allowed_users)
   - 없으면 → Unauthorized Screen
   ↓
4. 버전 체크 (app_config)
   - 낮으면 → Update Required Screen
   ↓
5. Main Screen
```

### 5. 데이터 유효성 검사 (Edit Screen)

**규칙:**
1. 최소 1개의 Section 필요
2. 모든 Section의 name은 필수
3. 각 Section은 최소 1개의 item 또는 subsection 필요
4. Subsection이 있으면 name은 필수

**구현:**
```dart
bool _validate() {
  if (_editData.sections.isEmpty) {
    _showError('최소 하나의 이름/주제를 추가해주세요.');
    return false;
  }

  for (final section in _editData.sections) {
    if (section.name.trim().isEmpty) {
      _showError('모든 이름/주제를 입력해주세요.');
      return false;
    }

    final validItems = section.items.where((item) =>
      item.content.trim().isNotEmpty).length;
    final validSubsections = section.subsections.where((sub) =>
      sub.name.trim().isNotEmpty).length;

    if (validItems == 0 && validSubsections == 0) {
      _showError('"${section.name}" 이름/주제에 최소 하나의 기도제목을 추가해주세요.');
      return false;
    }
  }

  return true;
}
```

---

## 환경 변수 설정

### 필수 환경 변수
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
KAKAO_APP_KEY=your-kakao-native-app-key
```

### 실행 명령어
```bash
flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=KAKAO_APP_KEY=$KAKAO_APP_KEY
```

---

## 데이터베이스 스키마 (Supabase)

### prayers 테이블
```sql
CREATE TABLE prayers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  content JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**content JSONB 구조:**
```json
{
  "sections": [
    {
      "name": "김철수",
      "items": ["건강을 위해", "가족을 위해"],
      "subsections": [
        {
          "name": "직장",
          "items": ["프로젝트 성공", "동료들과의 관계"]
        }
      ]
    }
  ]
}
```

### allowed_users 테이블
```sql
CREATE TABLE allowed_users (
  kakao_id TEXT PRIMARY KEY,
  nickname TEXT,
  email TEXT,
  is_author BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### denied_users 테이블
```sql
CREATE TABLE denied_users (
  kakao_id TEXT PRIMARY KEY,
  nickname TEXT,
  email TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### app_config 테이블
```sql
CREATE TABLE app_config (
  platform TEXT PRIMARY KEY, -- 'android' or 'ios'
  min_version TEXT NOT NULL,
  min_version_code INTEGER NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## 코드 작성 가이드

### 1. 파일 생성 전 체크
- 해당 단계의 문서를 먼저 읽을 것
- 폴더 구조를 확인하고 정확한 경로에 생성

### 2. 모델 클래스
```dart
// 간단한 모델은 일반 클래스 사용
class PrayerData {
  final String title;
  final List<PrayerSection> sections;

  const PrayerData({
    required this.title,
    required this.sections,
  });
}

// JSON 직렬화가 필요하면 toJson/fromJson 수동 구현
// Freezed는 선택사항 (복잡도에 따라)
```

### 3. Provider 패턴
```dart
// StateProvider - 단순 상태
final fontSizeProvider = StateProvider<int>((ref) => 100);

// StateNotifierProvider - 복잡한 상태 + 로직
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier()
);

// FutureProvider - 비동기 데이터
final fetchPrayerProvider = FutureProvider.autoDispose<PrayerData?>((ref) async {
  // ...
});
```

### 4. 에러 처리
```dart
try {
  final result = await repository.fetchData();
  if (result == null) {
    // 실패 처리
    return;
  }
  // 성공 처리
} catch (e) {
  print('Error: $e');
  // 에러 처리
}
```

### 5. UI 컴포넌트
```dart
class MyWidget extends ConsumerWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fontSize = ref.watch(fontSizeProvider);

    return Container(
      color: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: Text(
        'Hello',
        style: TextStyle(
          fontSize: fontSize.toDouble(),
          color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}
```

---

## 테스트 가이드

### 각 단계 완료 후 확인 사항

**STEP 01 완료 후:**
- [ ] 앱 실행 시 에러 없음
- [ ] 테마 전환 동작 확인
- [ ] 폰트 크기 조절 동작 확인
- [ ] 오디오 재생/중단 동작 확인

**STEP 02 완료 후:**
- [ ] Main Screen UI 정상 표시
- [ ] Skeleton 데이터 정상 표시
- [ ] PTR 애니메이션 동작
- [ ] 최초 로딩 시 자동 PTR 1회 실행
- [ ] TopBar 버튼들 모두 동작

**STEP 03 완료 후:**
- [ ] Edit 버튼 클릭 시 Edit Screen 이동
- [ ] Edit Screen 진입 시 오디오 중단
- [ ] Edit Screen 이탈 시 오디오 재개 (원래 재생 중이었으면)
- [ ] Section/Item 추가/삭제 동작
- [ ] 저장 버튼 클릭 시 디버그 출력 확인

**STEP 05 완료 후:**
- [ ] 앱 시작 시 캐시 데이터 즉시 표시
- [ ] 서버 데이터로 업데이트
- [ ] PTR로 최신 데이터 가져오기
- [ ] 네트워크 끊었을 때 캐시 데이터 사용

**STEP 12 완료 후:**
- [ ] 카카오 로그인 동작
- [ ] Supabase 권한 체크 동작
- [ ] 세션 저장 및 자동 로그인
- [ ] 권한 없는 사용자 Unauthorized Screen 이동
- [ ] 전체 인증 흐름 정상 동작

---

## 주의사항

### 하지 말아야 할 것
1. ❌ React Native 코드를 직역하지 말 것
2. ❌ Context API 패턴을 그대로 옮기지 말 것
3. ❌ DeviceEventEmitter 같은 RN 전용 패턴 사용하지 말 것
4. ❌ 단계를 건너뛰지 말 것
5. ❌ 완료 조건 확인 없이 다음 단계로 진행하지 말 것

### 해야 할 것
1. ✅ Flutter의 방식으로 같은 기능 구현
2. ✅ 각 단계 문서를 정확히 따를 것
3. ✅ 완료 조건을 모두 체크할 것
4. ✅ 색상을 정확히 보존할 것
5. ✅ 데이터 구조를 정확히 보존할 것

---

## 문제 해결

### 빌드 에러 발생 시
1. `flutter pub get` 실행
2. `flutter clean` 후 다시 빌드
3. 환경 변수가 제대로 전달되었는지 확인

### 카카오 로그인 안 되는 경우
1. Android/iOS 네이티브 설정 재확인
2. 카카오 개발자 콘솔에서 패키지명/번들ID 확인
3. 앱 키가 정확한지 확인

### Supabase 연결 안 되는 경우
1. URL과 Anon Key가 정확한지 확인
2. Supabase 프로젝트가 활성화되어 있는지 확인
3. 네트워크 연결 확인

---

## 완성 후 체크리스트

- [ ] 모든 화면이 정상 동작
- [ ] 다크/라이트 테마 전환 정상 동작
- [ ] 카카오 로그인 정상 동작
- [ ] 기도제목 조회/편집/저장 정상 동작
- [ ] 캐시 동작 정상 (앱 재시작 시 즉시 로드)
- [ ] 오디오 재생/중단 정상 동작
- [ ] 폰트 크기 조절 정상 동작
- [ ] PTR 정상 동작
- [ ] 버전 체크 정상 동작
- [ ] 권한 체크 정상 동작
- [ ] 모든 에러 처리 정상 동작

---

## 추가 개선 사항 (선택)

1. 단위 테스트 작성
2. 위젯 테스트 작성
3. 통합 테스트 작성
4. 성능 최적화
5. 접근성 개선
6. 국제화(i18n) 지원
7. 오프라인 모드 개선
8. 에러 추적 시스템 (Sentry)
9. 애널리틱스 추가

---

## 참고 자료

- Flutter 공식 문서: https://docs.flutter.dev
- Riverpod 문서: https://riverpod.dev
- go_router 문서: https://pub.dev/packages/go_router
- Supabase Flutter: https://supabase.com/docs/guides/getting-started/tutorials/with-flutter
- Kakao SDK: https://developers.kakao.com/docs/latest/en/kakaologin/flutter

---

**이 문서를 정확히 따라 구현하면, React Native 앱과 동일한 기능을 가진 최적화된 Flutter 앱을 완성할 수 있습니다.**
