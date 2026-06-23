# SVT Tracker — Garmin Widget

A Connect IQ widget for the Garmin Forerunner 255 Music (and compatible watches). One button to start, one to stop — logs SVT episodes with duration and trigger directly on the wrist.

## Button mapping

| Button | Idle | Active episode |
|--------|------|----------------|
| **SELECT** | Start episode | Stop → choose trigger |
| **BACK** | Exit widget | Discard confirm |
| **UP** | Open episode history | — |

## Trigger options

After tapping STOP, pick from: None / Exercise / Stress / Caffeine / Alcohol / Spontaneous / Other.

## Data storage

Episodes live in `Application.Storage` (Garmin's on-device key-value store). Data persists across restarts and watch reboots. Use **Sync to Sheet** (see below) to export for analysis.

## Setup

### 1. Install the Connect IQ SDK

1. Download **VS Code** + the **Monkey C** extension from Garmin: [developer.garmin.com/connect-iq](https://developer.garmin.com/connect-iq/sdk/)
2. Install the SDK via the extension's command palette: `Monkey C: Install SDK`
3. Accept the developer agreement and log in with your Garmin account

### 2. Set up the Google Sheet sync (optional but recommended)

This step wires up the **Sync to Sheet** feature so you can export episode data for analysis in R.

**Create the Apps Script:**

1. Create a new Google Sheet
2. Open **Extensions → Apps Script**
3. Replace the default code with:

```javascript
function doPost(e) {
  var data    = JSON.parse(e.postData.contents);
  var sheet   = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();

  // Build a set of existing episode IDs to skip duplicates on re-sync
  var existingIds = {};
  var lastRow = sheet.getLastRow();
  if (lastRow >= 2) {
    sheet.getRange(2, 5, lastRow - 1, 1).getValues()
      .forEach(function(r) { existingIds[r[0]] = true; });
  }

  data.episodes.forEach(function(ep) {
    if (existingIds[ep.id]) { return; }
    sheet.appendRow([
      new Date(ep.start * 1000),   // A: start (datetime)
      new Date(ep.stop  * 1000),   // B: stop  (datetime)
      ep.stop - ep.start,          // C: duration_sec
      ep.trigger || "None",        // D: trigger
      ep.id                        // E: id (hidden dedup key)
    ]);
  });

  return ContentService
    .createTextOutput(JSON.stringify({status: "ok"}))
    .setMimeType(ContentService.MimeType.JSON);
}
```

4. Click **Deploy → New deployment**
   - Type: **Web app**
   - Execute as: **Me**
   - Who has access: **Anyone**
5. Copy the deployment URL
6. Paste it into `source/SVTTrackerApp.mc`, replacing `"PASTE_YOUR_APPS_SCRIPT_URL_HERE"`

### 3. Build the app

In the VS Code command palette: `Monkey C: Build for Device` → select **fr255m** → choose **debug** (simulator) or **release** (watch).

The compiled file is written to:
```
svt_tracking_garmin.prg
```

### 4. Run in the simulator

The simulator must be launched before deploying to it:

1. Open the simulator:
   ```
   open ~/Library/Application\ Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2/bin/ConnectIQ.app
   ```
2. Build: `Monkey C: Build for Device` → `fr255m`
3. Deploy to the running simulator:
   ```
   ~/Library/Application\ Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2/bin/monkeydo svt_tracking_garmin.prg fr255m
   ```

### 5. Sideload to your watch (USB)

1. Connect the watch via USB (charge cable)
2. Build: `Monkey C: Build for Device` → `fr255m` → **release**
3. Copy `svt_tracking_garmin.prg` to the `GARMIN/APPS/` folder on the watch
   - If `APPS/` doesn't exist, create it
4. Eject and disconnect — the widget appears in your widget loop

## Syncing data to Google Sheets

Requires the Apps Script setup above and the watch to be connected to your phone via Bluetooth with Garmin Connect running.

1. Press **UP** from the main screen to open episode history
2. Scroll down and select **-- Sync to Sheet --**
3. The watch posts all episodes to your Google Sheet

Each episode appears as one row: **start datetime, stop datetime, duration (seconds), trigger**. Column E holds an internal ID used for deduplication — re-syncing will not create duplicate rows.

### Reading the data in R

```r
library(googlesheets4)

gs4_auth()
sheet_url <- "https://docs.google.com/spreadsheets/d/YOUR_SHEET_ID"
df <- read_sheet(sheet_url, col_names = c("start", "stop", "duration_sec", "trigger", "id"))
df$start <- as.POSIXct(df$start)
df$stop  <- as.POSIXct(df$stop)
```

## Notes

- `manifest.xml` lists the 255 Music as the primary device with several compatible devices for sharing. Trim `<iq:products>` to just `<iq:product id="fr255m"/>` for a minimal build.
- If you clear the watch's application data via Garmin Connect, on-device episodes will be lost. Sync before clearing.
