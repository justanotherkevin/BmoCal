# CLAUDE.md

## Test
`xcodebuild test` fails because of sandbox restrictions. Build and run the tests in two steps:

    xcodebuild build-for-testing -project BmoCal.xcodeproj -scheme BmoCal -configuration Debug -derivedDataPath ./DerivedData -destination 'platform=macOS,arch=arm64'
    xcrun xctest ./DerivedData/Build/Products/Debug/BmoCal.app/Contents/PlugIns/BmoCalTests.xctest

## Don't change
- The `print` in CalendarTools.swift (around line 79). Removing it makes `event.calendar` return nil.
- Storyboard `customModule` must stay "BmoCal". The old value "NextEvent" crashes at launch.

## Ignore
- `BmoCal/widget/` holds unused duplicate files.
- The settings fields useFlash, useFlashBlue, showSeconds, leadingZeros, useFuzzyTime, showTitle, useTitleLimit and showTime have no effect. They stay so old config files still load.
