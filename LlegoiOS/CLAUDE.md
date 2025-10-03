# iOS App - CLAUDE.md

This file provides guidance for working with the iOS SwiftUI portion of the Llego app.

## Project Structure

```
iosApp/iosApp/
├── iOSApp.swift              # App entry point (@main)
├── ContentView.swift          # Main TabView navigation container
├── Info.plist                 # iOS app configuration
├── Assets.xcassets/           # Images and assets
├── helpers/
│   └── OnboardingHelper.swift # Manages onboarding state
└── ui/
    ├── theme/
    │   ├── Theme.swift              # Color palette and design tokens
    │   └── shapes/
    │       ├── CounterControlsShape.swift
    │       └── CurvedBottomShape.swift
    ├── screens/
    │   ├── HomeView.swift
    │   ├── SearchTabContent.swift
    │   ├── CategorySelectionView.swift
    │   ├── CheckoutView.swift
    │   ├── ProfileView.swift
    │   ├── OrderConfirmationView.swift
    │   └── OnboardingView.swift
    └── components/
        ├── atoms/
        │   ├── LlegoCartButton.swift
        │   └── CategoryItem.swift
        ├── molecules/
        │   ├── ProductCard.swift
        │   ├── StoreCard.swift
        │   ├── LlegoSearchBar.swift
        │   └── OrderTrackingCard.swift
        ├── organisms/
        │   ├── ProductSection.swift
        │   ├── StoreSection.swift
        │   ├── SemicircularSlider.swift
        │   └── HomeHeaderExample.swift
        └── background/
            └── CurvedBackground.swift
```

## Architecture

### Atomic Design Pattern
The UI follows atomic design principles for better component reusability:

- **Atoms** (`ui/components/atoms/`): Basic building blocks
  - `LlegoCartButton.swift` - Reusable cart button with badge
  - `CategoryItem.swift` - Category selector items

- **Molecules** (`ui/components/molecules/`): Composite components
  - `ProductCard.swift` - Product display card with image, price, controls
  - `StoreCard.swift` - Store information card with ETA
  - `LlegoSearchBar.swift` - Search input with icon
  - `OrderTrackingCard.swift` - Order status display

- **Organisms** (`ui/components/organisms/`): Complex sections
  - `ProductSection.swift` - Product grid/list section
  - `StoreSection.swift` - Store listing section
  - `SemicircularSlider.swift` - Custom semicircular category slider
  - `HomeHeaderExample.swift` - Home screen header

- **Background** (`ui/components/background/`): Layout components
  - `CurvedBackground.swift` - Decorative curved background shapes

### Navigation Structure

**Main Navigation** (`ContentView.swift`):
- TabView with 5 tabs:
  1. **Home** (`house` icon) → `HomeView.swift`
  2. **Search** (`magnifyingglass` icon) → `SearchTabContent.swift`
  3. **Cart** (`cart` icon) → Cart view
  4. **Checkout** (`truck.box` icon) → `CheckoutView.swift`
  5. **Profile** (`person` icon) → `ProfileView.swift`

**Onboarding Flow**:
- Managed by `OnboardingHelper.swift` using UserDefaults
- Displays `OnboardingView.swift` on first launch
- Shows `ContentView.swift` on subsequent launches

## Design System

### Theme (`ui/theme/Theme.swift`)

#### Color Extensions
```swift
extension Color {
    static let llegoPrimary = Color(red: 2/255, green: 49/255, blue: 51/255)      // Dark teal
    static let llegoSecondary = Color(red: 225/255, green: 199/255, blue: 142/255) // Warm beige
    static let llegoTertiary = Color(red: 124/255, green: 65/255, blue: 43/255)    // Brown
    static let llegoAccent = Color(red: 178/255, green: 214/255, blue: 154/255)    // Light green
    static let llegoBackground = Color(red: 243/255, green: 243/255, blue: 243/255) // Light gray
    static let llegoSurface = Color.white
    static let llegoOnBackground = Color(red: 27/255, green: 27/255, blue: 27/255)  // Dark text
}
```

### Design Tokens

#### Corner Radius
- **Large cards**: 18-20pt
- **Medium elements**: 14-16pt
- **Small elements**: 12pt
- **Buttons**: 28pt (pill shape)

#### Shadows
```swift
.shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)  // Standard card
.shadow(color: Color.llegoAccent.opacity(0.4), radius: 12, x: 0, y: 6)  // Accent button
```

#### Typography
```swift
// Headers
.font(.system(size: 28, weight: .bold, design: .rounded))

// Subheaders
.font(.system(size: 20, weight: .semibold, design: .rounded))

// Body
.font(.system(size: 16, weight: .medium))

// Captions
.font(.system(size: 14, weight: .medium))
```

#### Spacing
- **Horizontal padding**: 20-24pt
- **Vertical padding**: 16-20pt
- **Section spacing**: 24-32pt
- **Item spacing**: 12-16pt

### Animations

#### Spring Animations
```swift
.animation(.spring(response: 0.6, dampingFraction: 0.8), value: someState)
```

#### Easing
```swift
withAnimation(.easeInOut(duration: 0.3)) {
    // State changes
}
```

#### Staggered Lists
```swift
.animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.1), value: isVisible)
```

## Component Guidelines

### Creating New Components

1. **Choose the right level**:
   - Atoms: Simple, reusable UI elements
   - Molecules: Combinations of atoms
   - Organisms: Complex, feature-specific sections

2. **Follow naming conventions**:
   - Prefix shared components with "Llego" (e.g., `LlegoCartButton`)
   - Use descriptive names (e.g., `ProductCard`, not `Card`)

3. **Use theme colors**:
   ```swift
   .foregroundColor(.llegoPrimary)
   .background(Color.llegoSurface)
   ```

4. **Apply consistent styling**:
   ```swift
   // Card style
   .background(
       RoundedRectangle(cornerRadius: 18)
           .fill(Color.white)
           .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
   )
   ```

### Custom Shapes (`ui/theme/shapes/`)

- `CurvedBottomShape.swift` - Curved bottom edge for backgrounds
- `CounterControlsShape.swift` - Custom shape for quantity controls

Create new shapes here when needed for consistent geometry.

## Screen Development

### Screen Template
```swift
import SwiftUI

struct NewScreenView: View {
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Screen content
                }
                .padding(.horizontal, 20)
            }
            .background(Color.llegoBackground.ignoresSafeArea())
            .navigationTitle("Screen Title")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    NewScreenView()
}
```

### Navigation Patterns

**Push Navigation**:
```swift
NavigationLink(destination: DetailView()) {
    // Link content
}
```

**Back Button Customization**:
```swift
.navigationBarBackButtonHidden(true)
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        Button(action: { /* back action */ }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.llegoPrimary)
        }
    }
}
```

## Asset Management

### Images (`Assets.xcassets/`)

Current category images:
- `batidos_y_cocteles.imageset` - Smoothies and cocktails
- `bebidas_enlatadas.imageset` - Canned drinks
- `botellas.imageset` - Bottles
- `italiana.imageset` - Italian food
- `platos_fuertes.imageset` - Main dishes
- `vegetariana.imageset` - Vegetarian

**Adding new assets**:
1. Add image to `Assets.xcassets/`
2. Use in code: `Image("asset_name")`
3. For SF Symbols: `Image(systemName: "symbol.name")`

## State Management

### UserDefaults (via helpers/)
```swift
// OnboardingHelper.swift pattern
static var hasSeenOnboarding: Bool {
    get { UserDefaults.standard.bool(forKey: "hasSeenOnboarding") }
    set { UserDefaults.standard.set(newValue, forKey: "hasSeenOnboarding") }
}
```

### @State and @Binding
```swift
// Local state
@State private var selectedTab = 0

// Pass to child
ChildView(isSelected: $selectedTab)

// In child
@Binding var isSelected: Int
```

## Best Practices

### Performance
- Use `LazyVStack` and `LazyHStack` for long lists
- Optimize images with `.resizable().scaledToFit()`
- Avoid heavy computations in `body`

### Accessibility
- Add `.accessibilityLabel()` to meaningful UI elements
- Use semantic colors that respect dark mode
- Ensure touch targets are at least 44x44pt

### Code Organization
- Keep views under 200 lines - extract into components
- Use computed properties for complex view logic
- Group related modifiers together

### SwiftUI Conventions
- Use `.background()` before `.cornerRadius()`
- Apply `.frame()` before size-dependent modifiers
- Use `.padding()` last for outer spacing

## Common Tasks

### Adding a New Tab
1. Add case to tab enum in `ContentView.swift`
2. Create screen view in `ui/screens/`
3. Add tab item with icon and label
4. Update tab selection logic

### Creating a Reusable Component
1. Determine atomic level (atom/molecule/organism)
2. Create file in appropriate `ui/components/` subfolder
3. Define component with proper parameters
4. Add preview for development
5. Document usage in comments

### Implementing a Feature Screen
1. Create view file in `ui/screens/`
2. Build with existing components from `ui/components/`
3. Add navigation from `ContentView.swift` or relevant parent
4. Implement state management (local @State or shared)
5. Add animations and polish

## Troubleshooting

### Common Issues

**Images not showing**:
- Verify asset name matches exactly (case-sensitive)
- Check image is in correct `.imageset` folder
- Rebuild project (Cmd+Shift+K, then Cmd+B)

**Layout issues**:
- Use `.frame()` to constrain sizes
- Check `.layoutPriority()` for competing constraints
- Use `GeometryReader` for complex layouts

**State not updating**:
- Ensure property is marked `@State`, `@Binding`, or `@Published`
- Check view is using `$` for two-way bindings
- Verify parent view is passing binding correctly

## Testing

### Preview Variants
```swift
#Preview("Light Mode") {
    HomeView()
}

#Preview("Dark Mode") {
    HomeView()
        .preferredColorScheme(.dark)
}

#Preview("With Data") {
    HomeView(products: mockProducts)
}
```

### Running on Simulator
- Select target: `iosApp`
- Choose simulator from device list
- Press Cmd+R to build and run
- Use Cmd+Shift+H for home button
- Use Cmd+Shift+1,2,3 to change device orientation

## Related Documentation

For overall project architecture and Kotlin Multiplatform integration, see `/CLAUDE.md` in the project root.