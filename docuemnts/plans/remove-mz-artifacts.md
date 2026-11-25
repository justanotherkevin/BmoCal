# Remove "MZ" (Mazookie) Naming Artifacts

## Context
The codebase contains legacy "MZ" prefixes inherited from the original creator. These appear in:
- Class names (`MZAlertBoxViewController`, `MZAboutBoxViewController`)
- Storyboard file names and identifiers
- Code references throughout the app

Removing these artifacts will improve code clarity by using names that reflect functionality rather than creator initials.

## Scope Analysis

### Phase 1: AboutPanel Refactor (Starting Point)
Files to rename (2 total):
1. `BmoCal/MZAboutBox.storyboard` → `AboutPanel.storyboard`
2. `BmoCal/MZAboutBoxViewController.swift` → `AboutPanelViewController.swift`

### Phase 2: EventNotificationAlert Refactor (After Phase 1 validation)
Files to rename (2 total):
1. `BmoCal/MZAlertBox.storyboard` → `EventNotificationAlert.storyboard`
2. `BmoCal/MZAlertBoxViewController.swift` → `EventNotificationAlert.swift`

### Phase 1: Classes to Rename (1 total)
1. `MZAboutBoxViewController` → `AboutPanelViewController`

### Phase 2: Classes to Rename (2 total)
1. `MZAlertBoxWindowController` → `EventNotificationAlertWindowController`
2. `MZAlertBoxViewController` → `EventNotificationAlertViewController`

### Phase 1: Storyboard Identifiers to Update
**AboutPanel.storyboard** (4 identifiers):
- `"MZ About Box"` (window) → `"AboutPanel"`
- `"MZ AboutBox Controller"` → `"AboutPanelViewController"`
- `storyboardIdentifier` attributes
- customClass name: `MZAboutBoxViewController` → `AboutPanelViewController`

### Phase 2: Storyboard Identifiers to Update
**EventNotificationAlert.storyboard** (5 identifiers):
- `"MZ Alert Box Window Controller"` → `"EventNotificationAlertWindowController"`
- `"MZ Alert Box"` (window) → `"EventNotificationAlert"`
- `"MZ Alert Box Controller"` → `"EventNotificationAlertViewController"`
- `userLabel="MZ Alert Box Controller"` → `userLabel="EventNotificationAlertViewController"`
- `storyboardIdentifier` attributes

### Phase 1: Code Files to Update
1. **AppDelegate.swift** (5 references):
   - Variable `aboutBoxView: MZAboutBoxViewController` → `AboutPanelViewController`
   - Storyboard load: `name: "MZAboutBox"` → `name: "AboutPanel"`
   - Identifier: `"MZ About Box"` → `"AboutPanel"`
   - Identifier: `"MZ AboutBox Controller"` → `"AboutPanelViewController"`
   - Type cast: `as? MZAboutBoxViewController` → `as? AboutPanelViewController`

### Phase 2: Code Files to Update
1. **NextEventViewController.swift** (8 references):
   - Variable `alertBoxWindow: MZAlertBoxWindowController` → `EventNotificationAlertWindowController`
   - Variable `alertBoxView: MZAlertBoxViewController` → `EventNotificationAlertViewController`
   - Storyboard load: `name: "MZAlertBox"` → `name: "EventNotificationAlert"`
   - Identifier: `"MZ Alert Box Window Controller"` → `"EventNotificationAlertWindowController"`
   - Identifier: `"MZ Alert Box Controller"` → `"EventNotificationAlertViewController"`
   - Type casts (2x): `as? MZAlertBoxWindowController` and `as? MZAlertBoxViewController`

### Phase 1 Changes (AboutPanel)
- **2 file renames** (1 Swift, 1 Storyboard)
- **1 class rename** (in 1 file)
- **4 storyboard identifiers** to update
- **5 code references** to update in AppDelegate.swift
- **~12 total text replacements** (minimal, low-risk warm-up)

### Phase 2 Changes (EventNotificationAlert)
- **2 file renames** (1 Swift, 1 Storyboard)
- **2 class renames** (in 1 file)
- **5 storyboard identifiers** to update
- **8 code references** to update in NextEventViewController.swift
- **~20 total text replacements**

## Implementation Strategy

### Phase 1: AboutPanel Refactor (12 replacements, ~30 min)
1. **Rename files in Xcode**:
   - `MZAboutBox.storyboard` → `AboutPanel.storyboard`
   - `MZAboutBoxViewController.swift` → `AboutPanelViewController.swift`
   
2. **Update AppDelegate.swift** (5 references):
   - Use Xcode Find & Replace for class name and identifiers
   - Update variable type: `MZAboutBoxViewController` → `AboutPanelViewController`
   - Update storyboard name: `"MZAboutBox"` → `"AboutPanel"`
   - Update identifiers: `"MZ About Box"` and `"MZ AboutBox Controller"`

3. **Update AboutPanel.storyboard** (4 identifiers):
   - Open in Interface Builder
   - Update window identifier: `"MZ About Box"` → `"AboutPanel"`
   - Update controller identifier and class: `"MZ AboutBox Controller"` → `"AboutPanelViewController"`

4. **Validation**:
   - Build (`⌘B`) — must compile
   - Test About box UI opens and displays correctly
   - No errors or warnings in build log

### Phase 2: EventNotificationAlert Refactor (20 replacements, ~45 min)
After Phase 1 validation passes:
1. **Rename files in Xcode**:
   - `MZAlertBox.storyboard` → `EventNotificationAlert.storyboard`
   - `MZAlertBoxViewController.swift` → `EventNotificationAlert.swift`

2. **Update NextEventViewController.swift** (8 references):
   - Use Xcode Find & Replace for both class names and identifiers
   - Update variable types and type casts
   - Update storyboard load name and all identifiers

3. **Update EventNotificationAlert.storyboard** (5 identifiers):
   - Window and controller identifiers
   - Custom class assignments

4. **Validation**:
   - Build (`⌘B`) — must compile
   - Run tests (`⌘U`) — all tests pass
   - Trigger event notification to verify modal appears and functions correctly

## Risk Assessment
**Low Risk** — These are self-contained UI components with no shared dependencies. The changes are mechanical string replacements with no logic changes.

**Mitigation:** 
- Xcode's refactoring tools help catch most references
- Storyboards are XML-based and can be validated by building
- Contained scope means fewer ripple effects

## Naming Rationale
- `EventNotificationAlert` — clearly describes the purpose (notification modal for calendar events)
- `AboutPanel` — standard macOS pattern for "About" dialogs
- Names reflect function, not creator initials

## Decisions Made
✓ **Phase approach**: Start with simpler AboutPanel, validate, then EventNotificationAlert
✓ **Naming**: `AboutPanel` and `EventNotificationAlert`
✓ **Strategy**: Two separate commits (one per phase) for clean git history

## Next Steps
1. Implement Phase 1: AboutPanel refactor
2. Build, test, and validate
3. Implement Phase 2: EventNotificationAlert refactor
4. Final build, tests, and manual validation
5. Create commits with clear messages about artifact removal
