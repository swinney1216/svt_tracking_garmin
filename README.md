# SVT Tracker — Garmin Widget

A Connect IQ widget for the Garmin Forerunner 255 Music (and compatible watches). One button to start, one to stop — same logic as the web app but built for the wrist.

## Button mapping

| Button | Idle | Active episode |
|--------|------|----------------|
| **SELECT** | Start episode | Stop → choose trigger |
| **BACK** | Exit widget | Discard confirm |
| **UP** | Open episode history | — |

## Trigger options

After tapping STOP, you'll pick from: None / Exercise / Stress / Caffeine / Alcohol / Spontaneous / Other.  
This replaces the free-text note from the web app — text input on a watch is impractical.

## Data storage

Episodes live in `Application.Storage` (Garmin's on-device key-value store — same concept as the web app's `localStorage`). Data persists across restarts. It is **not** synced to the web app or to Garmin Connect.

## Setup

### 1. Install the Connect IQ SDK

1. Download **VS Code** + the **Monkey C** extension from Garmin: [developer.garmin.com/connect-iq](https://developer.garmin.com/connect-iq/sdk/)
2. Install the SDK via the extension's command palette: `Monkey C: Install SDK`
3. Accept the developer agreement and log in with your Garmin account

### 2. Add your device SDK

In VS Code command palette: `Monkey C: Build for Device` → select **Forerunner 255S Music**. The extension will prompt you to download the device SDK if not already installed.

### 3. Run in the simulator

The simulator must be launched manually before deploying to it:

1. Open the simulator app from the SDK:
   ```
   open ~/Library/Application\ Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2/bin/ConnectIQ.app
   ```
2. Build the project: VS Code command palette → `Monkey C: Build for Device` → `fr255m`
3. Deploy to the running simulator:
   ```
   ~/Library/Application\ Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2/bin/monkeydo svt_tracking_garmin.prg fr255m
   ```

The widget will appear in the simulator. Use the on-screen buttons to test.

### 4. Sideload to your watch (USB)

1. Connect your 255S via USB (charge cable)
2. Command palette → `Monkey C: Build for Device` → `fr255m`
3. Copy the generated `.prg` file from the project root to the `GARMIN/APPS/` folder on the watch
4. Eject and disconnect — the widget appears in your widget loop

### 5. Publish to Connect IQ Store (optional)

If you want to install via the Garmin Connect app (no USB), you can publish to the Connect IQ Store at [apps.garmin.com](https://apps.garmin.com). Requires a free developer account.

## Notes

- The `manifest.xml` lists the 255 Music as the primary device with several others for sharing. Trim `<iq:products>` to just `<iq:product id="fr255m"/>` if you want a minimal build.
- Episode history is read-only on the watch (no CSV export — use the web app for analysis).
- If you clear the watch's application data via Garmin Connect, episodes will be lost.
