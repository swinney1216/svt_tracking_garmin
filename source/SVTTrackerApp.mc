import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// ── App entry point ─────────────────────────────────────────────────────────

class SVTTrackerApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [new MainView(), new MainDelegate()];
    }
}

// ── Storage helpers ──────────────────────────────────────────────────────────
//
// Episodes are stored as an Array of Dictionaries:
//   { "id" => Number, "start" => Number, "stop" => Number, "trigger" => String }
// where start/stop are Unix timestamps (seconds).
// active_start holds the timestamp of an in-progress episode (null when idle).

function getEpisodes() as Array {
    var stored = Application.Storage.getValue("episodes");
    return stored != null ? stored : ([] as Array);
}

function persistEpisodes(eps as Array) as Void {
    Application.Storage.setValue("episodes", eps);
}

function getActiveStart() as Number? {
    return Application.Storage.getValue("active_start") as Number?;
}

function setActiveStart(ts as Number) as Void {
    Application.Storage.setValue("active_start", ts);
}

function clearActiveStart() as Void {
    Application.Storage.setValue("active_start", null);
}

// ── Format helpers ───────────────────────────────────────────────────────────

// "04:23" or "1:02:45"
function fmtElapsed(secs as Number) as String {
    if (secs < 0) { secs = 0; }
    var h   = secs / 3600;
    var m   = (secs % 3600) / 60;
    var s   = secs % 60;
    if (h > 0) {
        return h.format("%d") + ":" + m.format("%02d") + ":" + s.format("%02d");
    }
    return m.format("%02d") + ":" + s.format("%02d");
}

// "45s", "12m 3s", "1h 4m"
function fmtDuration(secs as Number) as String {
    if (secs < 0) { secs = 0; }
    if (secs < 60) {
        return secs.format("%d") + "s";
    }
    var m   = secs / 60;
    var rem = secs % 60;
    if (m < 60) {
        return rem > 0
            ? m.format("%d") + "m " + rem.format("%d") + "s"
            : m.format("%d") + "m";
    }
    return (m / 60).format("%d") + "h " + (m % 60).format("%d") + "m";
}

// "6/23 14:30" in local time
function fmtTimestamp(ts as Number) as String {
    var moment = new Time.Moment(ts);
    var info   = Time.Gregorian.info(moment, Time.FORMAT_SHORT);
    var month  = (info.month as Number).format("%d");
    var day    = (info.day   as Number).format("%d");
    var hour   = (info.hour  as Number).format("%02d");
    var min    = (info.min   as Number).format("%02d");
    return month + "/" + day + " " + hour + ":" + min;
}
