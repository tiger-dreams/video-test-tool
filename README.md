# 🎥 Video Conference Test Tool

개인적으로 사용할 수 있는 화상회의 서비스 연결 테스트 도구입니다.

## 🚀 주요 기능

- **다중 서비스 지원**: Agora, LiveKit, Zoom, LINE Planet 등 주요 화상회의 서비스
- **동적 설정 폼**: 선택한 서비스에 따라 필요한 인증 정보 입력 폼이 자동으로 변경
- **실시간 연결 테스트**: 입력한 정보로 실제 화상회의 서비스 연결 테스트
- **상세한 결과 표시**: 연결 지연시간, 품질, 참가자 수 등 상세 정보 제공
- **반응형 UI**: 데스크톱과 모바일에서 모두 사용 가능

## 🛠️ 지원하는 화상회의 서비스

### 1. Agora RTC
- **필요한 정보**: App ID, App Certificate, Channel Name, Token (선택사항)
- **추천 패키지**: `agora-rtc-sdk-ng`
```bash
npm install agora-rtc-sdk-ng
```

### 2. LiveKit
- **필요한 정보**: Server URL, API Key, API Secret, Room Name, Participant Name
- **추천 패키지**: `livekit-client`, `livekit-server-sdk`
```bash
npm install livekit-client livekit-server-sdk
```

### 3. Zoom SDK
- **필요한 정보**: API Key, API Secret, Meeting Number, Password (선택사항), User Name
- **추천 패키지**: `@zoom/videosdk`
```bash
npm install @zoom/videosdk
```

### 4. LINE Planet
- **필요한 정보**: Channel ID, Channel Secret, Room ID, User ID
- **추천 패키지**: LINE Planet SDK (공식 문서 참조)

## 🏗️ 프로젝트 구조

```
src/
├── components/          # React 컴포넌트
│   ├── ServiceSelector.tsx     # 서비스 선택 컴포넌트
│   ├── ConfigForm.tsx          # 동적 설정 폼
│   ├── TestResults.tsx         # 테스트 결과 표시
│   └── VideoTestTool.tsx       # 메인 컴포넌트
├── services/           # 서비스 추상화 레이어
│   ├── BaseVideoService.ts     # 기본 서비스 클래스
│   ├── AgoraService.ts         # Agora 구현체
│   ├── LiveKitService.ts       # LiveKit 구현체
│   ├── ZoomService.ts          # Zoom 구현체
│   ├── LinePlanetService.ts    # LINE Planet 구현체
│   └── index.ts               # 서비스 팩토리
├── hooks/              # React 훅
│   └── useVideoService.ts      # 비디오 서비스 상태 관리
├── types/              # TypeScript 타입 정의
│   └── index.ts               # 전체 타입 정의
└── utils/              # 유틸리티 함수 (확장 예정)
```

## 🎯 설계 특징

### 확장 가능한 아키텍처
- **Strategy Pattern**: 각 화상회의 서비스를 독립적인 구현체로 분리
- **Factory Pattern**: 서비스 타입에 따른 인스턴스 생성 관리
- **React Hooks**: 상태 관리와 비즈니스 로직 분리

### 타입 안전성
- **TypeScript**: 전체 프로젝트에 타입 시스템 적용
- **Interface 기반**: 각 서비스별 설정 타입 정의
- **Generic Types**: 재사용 가능한 타입 구조

### 사용자 경험
- **즉시 피드백**: 실시간 연결 상태 표시
- **직관적 UI**: 서비스별 설정 항목 자동 변경
- **상세한 결과**: 연결 품질과 성능 정보 제공

## 🚀 시작하기

### 1. 개발 서버 실행
```bash
npm start
```

### 2. 빌드
```bash
npm run build
```

### 3. 테스트
```bash
npm test
```

## 📦 실제 서비스 연동을 위한 추가 패키지

현재는 모킹된 연결 테스트만 제공합니다. 실제 서비스와 연동하려면 다음 패키지들을 설치하세요:

### Agora 연동
```bash
npm install agora-rtc-sdk-ng agora-token
```

### LiveKit 연동
```bash
npm install livekit-client livekit-server-sdk jsonwebtoken
```

### Zoom 연동
```bash
npm install @zoom/videosdk jsrsasign
```

### 추가 유틸리티
```bash
npm install axios lodash moment
```

## 🔧 커스터마이징

### 새로운 서비스 추가

1. **타입 정의** (`src/types/index.ts`)
2. **서비스 구현체 작성** (`src/services/NewService.ts`)
3. **팩토리에 등록** (`src/services/index.ts`)

자세한 내용은 소스 코드의 기존 구현체를 참고하세요.

## 📝 라이선스

이 프로젝트는 개인 사용을 위한 도구입니다.