# Growvest Prototype

Interactive prototypes for **Growvest**, an app for discovering and investing in promising businesses. The flows are built from the Growvest Figma designs, and each one can be played end to end.

The repo holds two prototypes:

| Folder | What it is |
|---|---|
| [`ios/`](ios) | The main prototype: a native SwiftUI iPhone app with every flow below |
| [`app/`](app) | An earlier web version of the buy-shares flow (React + Vite) |

## Flows (iOS)

The app opens on **Growvest Flows**, a launcher listing each flow. Use the back button inside a flow to return to it.

- **Home:** the dashboard, with an Investor / Business Owner switch. Investor shows portfolio value, portfolio distribution and a filterable watchlist; Business Owner shows funds raised, stats and listings with funding progress. You can hide the balance. SwiftHarvest's portfolio card opens Sell and its watchlist row opens Buy. Tap the profile photo to return to the flow list.
- **Buy Shares:** enter an amount in naira or a number of shares (tap the pill under the big number to switch), pick a payment method, review, enter your PIN or use Face ID, then see the success screen.
- **Sell Shares:** the same steps for selling from your holding (40 shares at ₦2,500). You can't sell more than you hold, and you must tick a risk acknowledgement before confirming.
- **Verify Identity (KYC):** a checklist covering ID card scan, face verification and residential address, then submit for review.
- **Profile Setup:** the role you pick sets the path, and the progress bar follows it:
  - Investor: profile → investor profile → experience → success
  - Business owner: profile → business profile → success
  - Both: profile → investor profile → experience → business profile → success

## Running the iOS app

**Requirements:** Xcode 26 or later. The app targets iOS 18.0 and later.

1. Open `ios/Growvest.xcodeproj` in Xcode.
2. Choose the **Growvest** scheme and an iPhone simulator (or your own iPhone).
3. Press **Run** (⌘R).

Or from the command line:

```sh
cd ios
xcodebuild -project Growvest.xcodeproj -scheme Growvest \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

### Tips

- **The number pad doesn't appear in the Simulator:** the Simulator treats your Mac keyboard as a hardware keyboard and hides the on-screen one. Press **⌘K** to toggle it, or **⇧⌘K** to disconnect the hardware keyboard.
- **Haptics** (the risk slider, PIN entry, success screens) only play on a real iPhone.

### Demo launch arguments (Debug builds)

Launch arguments jump straight to a screen, which helps with screenshots and recordings. Set them in Xcode (*Product → Scheme → Edit Scheme → Run → Arguments*) or pass them to `simctl`:

```sh
xcrun simctl launch booted com.growvest.prototype -demoAmount 100000 -demoStep review
```

| Argument | Values |
|---|---|
| `-demoFlow` | `home`, `sell`, `kyc`, `profile` |
| `-demoHome` | `business`, `hidden`, `listing` (an offer still raising), `listing-trading` (a sold-out listing) |
| `-demoListingTab` | `overview`, `investors`, `updates`, `documents` (with `-demoHome listing…`) |
| `-demoReport` | `uploaded`, `submitted`: this month’s report on a listing (with `-demoHome listing…`) |
| `-demoRefresh` | `YES`: plays a pull-to-refresh two seconds after Home opens |
| `-demoAmount` | An amount to pre-type, e.g. `25000` |
| `-demoStep` (buy/sell) | `payment`, `review`, `pin`, `success`, `swap`, `typing`, `tour` |
| `-demoKYC` | `idcard`, `face`, `address`, `ready`, `submitted` |
| `-demoProfile` | `filled`, `investor`, `experience`, `experienceblank`, `businessowner`, `both`, `success`, `businesssuccess` |

## Project structure (iOS)

```
ios/Growvest/
├── GrowvestApp.swift          App entry, bundled font registration
├── FlowLauncherView.swift     The flow launcher; add new flows to PrototypeFlow
├── HomeView.swift             Home dashboard: investor and business owner modes, tab bars
├── TradeView.swift            Buy/sell amount screen: keypad, value swap, quick picks
├── InvestmentFlow.swift       Buy/sell state and rules (TradeKind: .buy / .sell)
├── InvestmentSheet.swift      Floating sheet: payment → review → PIN → success
├── KYCFlow.swift              KYC checklist and review sheet
├── KYCIDScanView.swift        ID card capture
├── KYCFaceScanView.swift      Face verification
├── KYCAddressView.swift       Residential address form
├── ProfileSetupFlow.swift     Profile setup: role-based paths, risk slider, success
├── FormFields.swift           Shared text field and dropdown
├── Components.swift           Summary cards, sheet header and other shared UI
├── Theme.swift                Fonts, colours, motion curves, button styles
├── AnimatedSealCheck.swift    Animated success seal (with ConfettiBurst.swift)
├── FloatingSheet.swift        Reusable floating bottom sheet
└── Assets.xcassets            Icons and colours exported from Figma
```

## Running the web prototype

**Requirements:** Node.js 20 or later.

```sh
cd app
npm install
npm run dev
```

Then open the URL that Vite prints (usually http://localhost:5173). `npm run build` creates a production build in `app/dist`.

## Fonts

The bundled fonts are [Inter](https://rsms.me/inter/), [Inter Tight](https://github.com/rsms/inter) and [Playfair Display](https://github.com/clauseggers/Playfair), all under the [SIL Open Font License](https://openfontlicense.org).
