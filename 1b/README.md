# Assignment 1B - Local Development Environment

Docker Compose를 사용한 로컬 블록체인 개발 환경입니다.

## 🚀 Quick Start

### 1. 환경 설정

```bash
# .env 파일 생성
cp .env.example .env
# .env 파일을 편집하여 본인의 설정값 입력
```

### 2. 필수 설정값

- `DEPLOYER_PRIVATE_KEY`: 본인의 지갑 개인키
- `DEPLOYER_ADDRESS`: 본인의 지갑 주소  
- `NGROK_DOMAIN`: ngrok에서 발급받은 도메인
- `NGROK_AUTHTOKEN`: ngrok 인증 토큰

### 3. 서비스 시작

```bash
# 메인 서비스 시작
docker compose up -d

# Blockscout 시작 (별도 터미널)
cd blockscout/docker-compose
docker compose -f geth.yml up -d
```

## 🌐 접근 가능한 엔드포인트

모든 서비스는 ngrok을 통해 접근 가능합니다:

- **Smart Contracts Deployment**: `https://your-domain.ngrok-free.app/deployment`
- **Blockchain Explorer**: `https://your-domain.ngrok-free.app/explorer`
- **EVM RPC**: `https://your-domain.ngrok-free.app/rpc`
- **GraphQL Playground**: `https://your-domain.ngrok-free.app/graph-playground`

## 🏗️ 아키텍처

- **Caddy**: 리버스 프록시
- **ngrok**: 터널링
- **Geth**: 로컬 EVM 노드
- **Smart Contract Deployer**: 1a 과제 자동 배포
- **Blockscout**: 블록체인 익스플로러
- **Graph Stack**: IPFS, PostgreSQL, Redis, Graph Node

## 📝 참고사항

- Apple Silicon 사용자: Graph Node가 Rosetta 2를 통해 실행됩니다
- 브라우저 콘솔의 일부 에러는 정상적인 개발 환경에서 발생하는 것입니다
