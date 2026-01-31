# UI Engineering Notes

## Overview

This document explains the design decisions, UX philosophy, and implementation rationale for the minimal, calm Flutter UI built for the finance app.

---

## === ENGINEERING NOTES ===

### 1. UI Decisions

#### 1.1 Theme System (`CalmTheme`)

**Color Palette - Soft & Trustworthy**

| Purpose | Color | Hex | Rationale |
|---------|-------|-----|-----------|
| Primary | Soft Indigo | `#6366F1` | Conveys trust & professionalism without coldness |
| Success | Sage Green | `#10B981` | Positive feedback without high-energy excitement |
| Danger | Soft Coral | `#F87171` | Warning without alarm (not aggressive red) |
| Neutrals | Warm Grays | `#1C1917` - `#FAFAFA` | Friendlier than cool grays, easier on eyes |

**Design Rationale:**
- Financial apps often use cold blues and aggressive reds which can trigger anxiety
- Our palette uses muted, warm tones that feel calm and trustworthy
- Color coding is semantic: green = positive balance, coral = deficit

**Typography - Large & Scannable**

```
Display Large: 56px (Hero numbers)
Display Small: 36px (Section totals)  
Headline Large: 32px (Page titles)
Title Medium: 18px (Card headers)
Body Large: 18px (Primary content)
```

**Rationale:**
- Financial numbers should be instantly readable
- Large type reduces eye strain and cognitive load
- Generous line height (1.5) improves readability

**Spacing System - Generous Breathing Room**

```
Page Padding: 24px horizontal, 32px vertical
Card Padding: 24px all sides
Section Spacing: 32px between sections
```

**Rationale:**
- Whitespace reduces visual noise
- Generous padding prevents cramped feeling
- Consistent rhythm creates visual harmony

---

### 2. How UX Reduces Mental Load

#### 2.1 One Main Message Per Screen

Each screen has ONE primary purpose:

| Screen | Main Message | Everything Else |
|--------|-------------|-----------------|
| Dashboard | "Here's what you have left" | Supporting context |
| Contracts List | "Here are your commitments" | Simple, scannable list |
| Contract Detail | "Here's everything about this" | Organized details |

**Implementation:**
- Dashboard: Free Balance is the HERO (56px, color-coded)
- Everything else is visually secondary

#### 2.2 Progressive Disclosure

Information is revealed in layers:

```
Layer 1 (Dashboard): Free Balance → "Am I okay this month?"
Layer 2 (Dashboard): Income/Outflow → "How did I get here?"
Layer 3 (Dashboard): Next 3 Months → "What's coming?"
Layer 4 (Contracts): Full list → "What are my commitments?"
Layer 5 (Detail): Deep dive → "Tell me everything"
```

**Benefit:** User only processes information they need.

#### 2.3 Visual Hierarchy Reduces Scanning Time

**Dashboard Example:**

```
┌─────────────────────────────────────┐
│ January 2026                        │  ← Context (where am I?)
│ Financial Overview                  │
├─────────────────────────────────────┤
│                                     │
│     ₹45,000                         │  ← HERO (the answer)
│     Free Balance                    │
│     ● Excellent savings rate        │  ← Health status
│                                     │
├─────────────────────────────────────┤
│ ↓ Income      │ ↑ Mandatory         │  ← Supporting detail
│   ₹1,20,000   │   ₹75,000           │
├─────────────────────────────────────┤
│ Looking Ahead                       │  ← Future context
│ Feb 2026  ₹42,000                   │
│ Mar 2026  ₹38,000                   │
│ Apr 2026  ₹40,000                   │
└─────────────────────────────────────┘
```

**Key Principle:** Eyes flow from largest to smallest, most important to least.

#### 2.4 Immediate Understanding Through Color

```dart
// Color instantly communicates state
static Color getBalanceColor(double balance) {
  if (balance > 0) return success;  // Green = good
  if (balance < 0) return danger;   // Coral = attention needed
  return textPrimary;               // Neutral = zero
}
```

**Benefit:** No need to read - color tells the story.

#### 2.5 Reduced Decision Fatigue

**Contract List Design:**
- No inline actions (edit, delete buttons)
- Simple tap to navigate
- Filters are optional, not required
- Default view shows everything

**Rationale:** Every choice requires mental energy. We minimize choices.

---

### 3. Information Hierarchy Rationale

#### 3.1 Dashboard Hierarchy

```
Priority 1: FREE BALANCE
├── Why: This is THE number that answers "Am I okay?"
├── Design: Largest text, color-coded, prominent card
└── Position: Above the fold, center of attention

Priority 2: INCOME & OUTFLOW
├── Why: Explains HOW we got to free balance
├── Design: Medium cards, subdued icons
└── Position: Secondary row, supportive

Priority 3: NEXT 3 MONTHS
├── Why: Reduces worry about future
├── Design: Simple list, minimal detail
└── Position: Scrollable, doesn't compete with hero

Priority 4: CONTRACTS SUMMARY
├── Why: Gateway to details, not primary info
├── Design: Compact card, action-oriented
└── Position: Bottom, invites exploration
```

#### 3.2 Contracts List Hierarchy

```
Priority 1: CONTRACT NAME
├── Why: Primary identifier
├── Design: Title weight, full width
└── Position: Left-aligned, first thing eyes hit

Priority 2: TYPE ICON
├── Why: Instant categorization
├── Design: Color-coded icons (↑↓─)
└── Position: Leading, before text

Priority 3: MONTHLY AMOUNT
├── Why: Core metric for each contract
├── Design: Right-aligned, consistent position
└── Position: Trailing, easy to scan column

Priority 4: STATUS
├── Why: Only relevant if not active
├── Design: Small pill, only shown if paused/closed
└── Position: Inline with name, subtle
```

#### 3.3 Contract Detail Hierarchy

```
Priority 1: NAME & STATUS
├── Why: Confirm what we're looking at
├── Design: Header with back navigation
└── Position: Top, anchors the page

Priority 2: MONTHLY AMOUNT
├── Why: The core commitment
├── Design: Prominent card, branded background
└── Position: Hero position, colored card

Priority 3: TYPE-SPECIFIC DETAILS
├── Why: Relevant context for this contract type
├── Design: Clean key-value pairs
└── Position: Main content area

Priority 4: TIMELINE
├── Why: Historical and future context
├── Design: Simple info rows
└── Position: Below details

Priority 5: ACTIONS
├── Why: Infrequent operations
├── Design: Minimal buttons, dangerous action in red
└── Position: Bottom, requires scroll (intentional friction)
```

---

### 4. Bloc/Cubit Architecture

#### 4.1 Strict UI/Logic Separation

```
┌─────────────────────────────────────────────────────┐
│                    PRESENTATION                      │
├─────────────────────────────────────────────────────┤
│  Screen (Widget)     │  Cubit          │  State     │
│  ─────────────────   │  ─────────────  │  ───────   │
│  • Renders UI        │  • Emits state  │  • Data    │
│  • Handles gestures  │  • Calls repos  │  • Flags   │
│  • Navigates         │  • No UI logic  │  • Computed│
│  • NO business logic │  • Testable     │  • Immutable│
└─────────────────────────────────────────────────────┘
```

#### 4.2 State Design Principles

**Sealed Classes for Exhaustive Handling:**

```dart
sealed class DashboardState extends Equatable {
  const DashboardState();
}

final class DashboardInitial extends DashboardState { ... }
final class DashboardLoading extends DashboardState { ... }
final class DashboardLoaded extends DashboardState { ... }
final class DashboardError extends DashboardState { ... }
```

**Benefits:**
- Compiler ensures all states are handled
- No runtime surprises
- Clear state transitions

**Computed Properties in State:**

```dart
final class DashboardLoaded extends DashboardState {
  // Raw data
  final MonthlySnapshot currentSnapshot;
  
  // Computed (derived from raw data)
  double get freeBalance => currentSnapshot.freeBalance;
  bool get isDeficit => freeBalance < 0;
  DashboardHealthStatus get healthStatus { ... }
}
```

**Benefits:**
- UI stays simple (just reads properties)
- Logic is testable (in state class)
- Single source of truth

#### 4.3 Cubit Responsibilities

```dart
class DashboardCubit extends Cubit<DashboardState> {
  // ✅ Load data from repositories
  Future<void> loadDashboard() async { ... }
  
  // ✅ Transform repository data to state
  emit(DashboardLoaded(
    currentSnapshot: snapshot,
    nextThreeMonths: projections,
  ));
  
  // ❌ Never formats data for display
  // ❌ Never knows about widgets
  // ❌ Never handles navigation
}
```

---

### 5. Component Design

#### 5.1 Reusable Widgets

| Widget | Purpose | Customization |
|--------|---------|---------------|
| `AmountDisplay` | Currency formatting | Size, color, sign |
| `CalmCard` | Content container | Padding, tap, elevation |
| `StatusPill` | Status indicators | Color, label, icon |
| `SectionHeader` | Section titles | Title, subtitle, action |
| `EmptyState` | No content states | Icon, message, action |
| `CalmLoading` | Loading indicator | Optional message |
| `CalmProgress` | Progress bars | Value, colors, label |

#### 5.2 Widget Composition Pattern

```dart
// Screen composes reusable widgets
class DashboardScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DashboardHeader(...),      // Local widget
        CalmCard(                   // Reusable
          child: AmountDisplay(...) // Reusable
        ),
        SectionHeader(...),         // Reusable
      ],
    );
  }
}
```

---

### 6. UX Patterns Implemented

#### 6.1 Pull-to-Refresh

Every list supports pull-to-refresh for user control.

#### 6.2 Loading States

Minimal, calm loading indicators with optional messages.

#### 6.3 Error States

Friendly error messages with retry actions.

#### 6.4 Empty States

Encouraging messages that guide next actions.

#### 6.5 Optimistic Updates

Contract actions show loading overlay, preventing double-taps.

---

### 7. Accessibility Considerations

- Large touch targets (44px minimum)
- Color is never the only indicator (icons + color)
- High contrast text ratios
- Semantic widget structure

---

### 8. Future Enhancements

1. **Dark Mode**: Theme already supports dark variant
2. **Animations**: Add subtle micro-interactions
3. **Haptic Feedback**: Confirm important actions
4. **Charts**: Visual spending trends
5. **Onboarding**: First-time user guidance

---

## File Structure

```
lib/presentation/
├── theme/
│   ├── app_theme.dart         # Original theme
│   └── calm_theme.dart        # New calm theme system
├── bloc/
│   ├── dashboard/
│   │   ├── dashboard_state.dart
│   │   ├── dashboard_cubit.dart
│   │   └── dashboard_barrel.dart
│   ├── contracts/
│   │   ├── contracts_state.dart
│   │   ├── contracts_cubit.dart
│   │   └── contracts_barrel.dart
│   ├── contract_detail/
│   │   ├── contract_detail_state.dart
│   │   ├── contract_detail_cubit.dart
│   │   └── contract_detail_barrel.dart
│   ├── base_cubit.dart
│   └── app_bloc_observer.dart
├── widgets/
│   ├── amount_display.dart
│   └── calm_components.dart
├── pages/
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   ├── contracts/
│   │   └── contracts_list_screen.dart
│   └── contract_detail/
│       └── contract_detail_screen.dart
└── presentation.dart          # Barrel exports
```

---

## Summary

This UI system prioritizes **mental calmness** over visual excitement. Every design decision serves one goal: **reduce cognitive load** so users can understand their finances at a glance without stress.

The implementation follows **strict separation** between UI and logic, making the codebase maintainable, testable, and scalable.
