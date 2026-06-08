# SmartSpend Copilot UI/UX Engineering Guidelines

## Role and Mindset

Act as a senior Flutter 2026 SaaS UI architect, fintech product designer, and performance-focused frontend engineer.

Modernize SmartSpend using a design-system-first approach. The app must feel like a premium, modern, scalable fintech SaaS product.

The final product should feel:

- Minimal
- Premium
- Clean
- Fast
- Calm
- Intelligent
- Consistent
- Investor-ready
- Production-grade

## Core UI/UX Stack

Use the following stack and design mindset across the entire app.

### 1. Material 3 Foundation

Use Material 3 as the foundation for:

- Theme structure
- Buttons
- Inputs
- Navigation
- Dialogs
- Bottom sheets
- Accessibility
- Motion patterns
- Surface hierarchy

Material 3 should provide the base system, but the final interface should feel more custom, premium, and SaaS-like.

### 2. ShadCN-Inspired Flutter Components

Build reusable Flutter equivalents inspired by ShadCN UI.

Create and consistently use:

- `AppCard`
- `AppButton`
- `AppInput`
- `AppDropdown`
- `AppSheet`
- `AppDialog`
- `AppBadge`
- `AppTabs`
- `AppToast`
- `AppEmptyState`
- `AppCommandMenu`
- `AppActionMenu`
- `AppMetricTile`
- `AppInsightCard`
- `AppFormSheet`
- `AppSkeletonLoader`

All screens must reuse these components instead of creating one-off UI.

### 3. flutter_animate

Use `flutter_animate` for subtle microinteractions only.

Use it for:

- Fade in
- Slide in
- Scale on tap
- Card entrance
- Sheet entrance
- List item reveal
- Button feedback
- Insight card reveal

Avoid excessive animation. Animation must improve usability, not decorate the UI unnecessarily.

### 4. LottieFiles Animations

Use Lottie animations only where they add meaningful feedback.

Use Lottie for:

- Empty states
- Loading states
- Success confirmations
- Error states
- Biometric authentication
- Report generation
- AI/copilot insight states
- Offline state
- Notification state

Rules:

- Keep animations lightweight
- Store assets locally under `assets/animations/`
- Respect reduced motion settings
- Always provide text fallback
- Do not loop animations unnecessarily
- Do not use Lottie inside every small component

### 5. Glassmorphism

Use glassmorphism carefully and only where it improves perceived intelligence and premium feel.

Use glassmorphism for:

- Financial insight cards
- AI Copilot cards
- Decision snapshot cards
- Portfolio summary cards
- Scenario Lab result cards

Do not use glassmorphism for:

- Normal forms
- List rows
- Settings rows
- Transaction items
- Basic buttons
- Every card in the app

Glassmorphism should feel subtle, readable, and performant.

### 6. Interactive Charts

Use interactive charts for:

- Spending trends
- Burn rate
- Budget usage
- Savings growth
- Subscription load
- Forecast comparison
- Scenario simulation
- Financial health score
- Reports and exports

Charts should be:

- Compact
- Readable
- Touch-friendly
- Animated subtly
- Useful for decisions
- Accessible where possible

Do not add large decorative charts that do not help users decide what to do.

### 7. AI-Copilot-Style Panels

Use AI-copilot-style panels for:

- Financial Copilot
- Scenario Lab
- Recommendations
- Smart insights
- Risk alerts
- Decision summaries
- Monthly summaries

Every AI/copilot panel should clearly show:

- Insight
- Reason
- Impact
- Recommended action
- CTA

Example structure:

```text
Insight: Subscriptions are increasing fixed costs.
Reason: Monthly subscription load is above your normal baseline.
Impact: Kz 12,578/month committed.
Action: Review optional subscriptions.
CTA: Review subscriptions
```

## Global Design Rules

Follow these rules everywhere.

### Visual Style

Use:

- Soft cards
- Minimal surfaces
- Subtle shadows
- Rounded components
- Pastel gradients
- Clean typography
- Semantic colors
- Spacious layouts
- Modern bottom sheets
- Compact metric cards
- AI-style insight panels
- Elegant empty states

Avoid:

- Harsh borders
- Heavy shadows
- Oversized cards
- Visual clutter
- Saturated colors
- Inconsistent forms
- Old widgets
- Decorative animations without purpose
- Random component styles
- Duplicate UI patterns

### Color Usage

Use semantic colors intentionally:

- Green: income, success, healthy, positive
- Red: expense, error, risk, critical
- Orange: warning, attention, near limit
- Blue: information, neutral insights
- Purple: AI, intelligence, portfolio/summary identity

Do not use color without meaning.

### Shadows

Prefer subtle shadows instead of visible borders.

Recommended shadow:

```dart
BoxShadow(
  color: Colors.black.withOpacity(0.035),
  blurRadius: 18,
  offset: Offset(0, 8),
)
```

Use visible borders only for:

- Destructive states
- Warning states
- Input focus states
- Semantic alerts

### Border Radius

Use consistent radius values:

- Small controls: 12–16
- Inputs/buttons: 16–18
- Cards: 24–32
- Hero insight cards: 28–32
- Pills/badges: 999

### Spacing

Use consistent spacing values:

- 4
- 8
- 12
- 16
- 20
- 24
- 32

Avoid random spacing values.

### Typography

Use clear hierarchy.

- Page titles: large and bold
- Section titles: semibold
- Financial values: bold, prominent, easy to scan
- Supporting text: muted and short
- Insight copy: concise and actionable

Avoid long paragraphs inside cards.

## Screen Coverage

Apply this guideline to every screen and component:

- Home
- Transactions
- Budgets
- Savings
- Subscriptions
- Reports & Export
- Financial Copilot
- Scenario Lab
- Recurring Balance Sheet
- Settings
- Authentication screens
- Add/edit transaction
- Add/edit budget
- Add/edit savings goal
- Add/edit subscription
- All dropdowns
- All modals
- All bottom sheets
- All empty states
- All loading states
- All charts
- All notifications
- All toast messages

## Component Consistency Requirements

No screen should use old, inconsistent widgets.

Every screen must use shared app components:

- Cards must use the shared card system
- Forms must use shared input components
- Dropdowns must use the modern dropdown system
- Modals must use the shared form sheet pattern
- Toasts must use the shared feedback system
- Empty states must use shared empty-state components
- Loading states must use skeletons or Lottie where useful
- Insight cards must follow the same minimal portfolio/decision pattern

## Financial Insight Card Rules

Insight cards should be minimal and decision-focused.

Every insight card should include:

- Small icon
- Clear title
- One short insight sentence
- Three to five key metrics maximum
- Optional status chip
- Optional CTA

Do not overload insight cards with too many mini-cards.

Use screen-specific meaning:

### Transactions

Focus on:

- Income
- Spent
- Net Flow
- Top Category
- Recurring count

### Budgets

Focus on:

- Remaining
- Spent
- At Risk
- Days Left
- Total Limit

### Savings

Focus on:

- Saved
- Target
- Monthly Surplus
- At Risk
- Goals

### Subscriptions

Focus on:

- Monthly Load
- Active
- Next Renewal
- Optional Savings
- Critical

### Reports

Focus on:

- Generated
- This Month
- Last Export
- Available Types

### Financial Copilot

Focus on:

- Risk level
- Impact
- Confidence
- Recommended action
- Related CTA

## Feedback and Motion Rules

Every meaningful user action must provide feedback.

Use toast/snackbar for:

- Saved successfully
- Updated successfully
- Deleted successfully
- Exported successfully
- Network error
- Validation issue
- Sync failure
- Permission result
- Notification status

Use Lottie for:

- Larger empty states
- Loading flows
- Biometric authentication
- Report generation
- Major success/failure states

Prevent duplicate feedback. Do not show multiple competing feedback elements for the same action.

## Form and Modal Rules

All add/edit flows must share the same form pattern.

Use the same modal/bottom sheet style for:

- Add Transaction
- Update Transaction
- Add Budget
- Update Budget
- Add Savings Goal
- Update Savings Goal
- Add Subscription
- Update Subscription

Requirements:

- Rounded top corners
- Drag handle
- SafeArea
- Keyboard-safe
- Scroll-safe
- Sticky actions
- Shared inputs
- Shared dropdowns
- Shared validation
- Same button styles
- Friendly errors
- Loading states
- Success feedback

Do not create separate form styles for different modules.

## Dropdown Rules

All dropdowns must use the unified modern dropdown system.

Requirements:

- Rounded 16
- Soft shadow
- No harsh border
- 150ms animation
- Icon support
- Keyboard accessible
- Screen-reader accessible
- Mobile-friendly
- Bottom-sheet fallback on small screens
- Destructive action support
- Separator support
- Search support where option lists are long

Do not leave old dropdown implementations in the app.

## Notification Rules

Notifications must be dynamic and connected.

Support:

- Budget threshold alerts
- Subscription renewal alerts
- Savings milestones
- Report generation completion
- Security alerts
- Monthly summaries
- Recurring balance warnings
- Scenario recommendations

Every notification should support:

- Read/unread state
- Badge count
- Tap-to-navigate
- Mark as read
- Mark all as read
- Archive/dismiss where appropriate

Push notifications must use the approved notification service architecture and respect user preferences.

## Engineering Rules

Preserve existing backend logic unless a targeted change is required.

Do:

- Keep components reusable
- Keep business logic out of widgets
- Use pure engines for financial calculations
- Use typed models
- Use derived view models
- Use memoized summaries where needed
- Isolate rebuilds
- Use const widgets where possible
- Dispose controllers
- Respect offline behavior
- Avoid duplicate API calls
- Keep animations lightweight
- Keep files focused and maintainable

Do not:

- Calculate insights inside `build()`
- Trigger repeated API calls during UI interactions
- Duplicate form logic
- Duplicate dropdown logic
- Create monolithic widgets
- Hardcode financial values
- Add packages without purpose
- Break existing routes
- Break existing authentication
- Break existing database contracts
- Leave old UI widgets in the app

## Performance Requirements

The app must remain fast as it scales.

Avoid:

- Heavy rebuilds
- Large widget trees
- Expensive chart redraws
- Repeated full transaction scans
- Repeated filtering in `build()`
- Large Lottie files
- Unnecessary loops
- Polling without reason

Use:

- Cached summaries
- Derived view models
- Selectors/listeners
- Lazy lists
- Pagination where needed
- Debouncing for search/filter inputs
- Lightweight animations
- Optimized charts

## Accessibility Requirements

Ensure:

- Touch targets are large enough
- Text has sufficient contrast
- Reduced motion is respected
- Lottie animations have labels/fallbacks
- Inputs have labels
- Dropdowns support keyboard navigation
- Modals are accessible
- Toasts are readable
- Error messages are understandable

## Testing and Validation

After every implementation:

```bash
flutter analyze
flutter test
```

Fix:

- All warnings
- All errors
- All failed tests
- All layout overflows
- All keyboard overlap issues
- All bottom nav overlap issues

Test:

- Small screens
- Large screens
- Keyboard behavior
- Bottom sheets
- Dropdowns
- Forms
- Empty states
- Loading states
- Lottie fallback
- Toast feedback
- Notification flows
- Chart rendering
- Swipe actions
- Insight cards

## Final Product Standard

SmartSpend must feel like a modern 2026 SaaS-grade fintech app built with:

- Material 3
- ShadCN-inspired Flutter components
- Subtle `flutter_animate` microinteractions
- Lottie feedback states
- Glassmorphism financial insight cards
- Interactive charts
- AI-copilot-style insight panels
- Dynamic notifications
- Consistent forms and dropdowns
- Production-grade performance

Every screen must feel intentional, cohesive, premium, and ready for real users.
