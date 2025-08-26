#!/bin/bash

echo "🍅 뽀모도로 앱 릴리즈 빌드 시작..."

# 프로젝트 정리
echo "📁 빌드 폴더 정리 중..."
rm -rf build/
mkdir -p build/

# Archive 빌드
echo "🔨 Archive 빌드 중..."
xcodebuild archive \
    -project Pomodoro.xcodeproj \
    -scheme Pomodoro \
    -configuration Release \
    -archivePath build/Pomodoro.xcarchive

# App 추출
echo "📦 .app 파일 추출 중..."
xcodebuild -exportArchive \
    -archivePath build/Pomodoro.xcarchive \
    -exportPath build/ \
    -exportOptionsPlist ExportOptions.plist

# 압축 파일 생성
echo "🗜️  배포용 압축 파일 생성 중..."
cd build/
zip -r "Pomodoro-v$(date +%Y%m%d).zip" Pomodoro.app
cd ..

echo "✅ 릴리즈 빌드 완료!"
echo "📁 파일 위치: build/Pomodoro-v$(date +%Y%m%d).zip"
echo ""
echo "🚀 GitHub Releases에 업로드할 준비 완료!"