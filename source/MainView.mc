import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

// Trigger labels — index stored as menu item id, label stored in episode dict
const TRIGGERS as Array<String> = [
    "None", "Exercise", "Stress", "Caffeine", "Alcohol", "Spontaneous", "Other"
];

// ── Main view ────────────────────────────────────────────────────────────────
//
// Two visual states:
//   Idle:   green START prompt, UP hint for history
//   Active: red EPISODE header, live elapsed timer, STOP prompt

class MainView extends WatchUi.View {

    private var _ticker as Timer.Timer;

    function initialize() {
        View.initialize();
        _ticker = new Timer.Timer();
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onShow() as Void {
        if (getActiveStart() != null) {
            _ticker.start(method(:onTick), 1000, true);
        }
    }

    function onHide() as Void {
        _ticker.stop();
    }

    function onTick() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (getActiveStart() != null) {
            drawActive(dc, cx, h);
        } else {
            drawIdle(dc, cx, h);
        }
    }

    // ── Idle state ───────────────────────────────────────────────────────────

    private function drawIdle(dc as Graphics.Dc, cx as Number, h as Number) as Void {
        // "SVT TRACK" header
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 14 / 100,
            Graphics.FONT_SMALL, "SVT TRACK",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Heart indicator circle
        dc.setColor(0xCC2200, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, h * 40 / 100, h * 13 / 100);

        // Heart symbol
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 40 / 100,
            Graphics.FONT_MEDIUM, "o",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // START label
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 65 / 100,
            Graphics.FONT_LARGE, "START",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Hints
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 81 / 100,
            Graphics.FONT_TINY, "SELECT = start",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, h * 91 / 100,
            Graphics.FONT_TINY, "UP = history",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ── Active state ─────────────────────────────────────────────────────────

    private function drawActive(dc as Graphics.Dc, cx as Number, h as Number) as Void {
        var start   = getActiveStart() as Number;
        var elapsed = Time.now().value().toNumber() - start;

        // "EPISODE" header
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 14 / 100,
            Graphics.FONT_SMALL, "EPISODE",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Elapsed timer — large numeric font
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 42 / 100,
            Graphics.FONT_NUMBER_MEDIUM, fmtElapsed(elapsed),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // STOP label
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 68 / 100,
            Graphics.FONT_LARGE, "STOP",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Hints
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 81 / 100,
            Graphics.FONT_TINY, "SELECT = save",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, h * 91 / 100,
            Graphics.FONT_TINY, "BACK = discard",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

// ── Main delegate ────────────────────────────────────────────────────────────

class MainDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    // SELECT: start episode, or open trigger picker to stop
    function onSelect() as Boolean {
        if (getActiveStart() == null) {
            setActiveStart(Time.now().value().toNumber());
            WatchUi.requestUpdate();
        } else {
            openTriggerMenu();
        }
        return true;
    }

    // BACK: if active → confirm discard; if idle → exit widget
    function onBack() as Boolean {
        if (getActiveStart() != null) {
            openDiscardConfirm();
            return true;
        }
        return false; // system handles back → exits widget
    }

    // UP: open episode history
    function onPreviousPage() as Boolean {
        openEpisodesMenu();
        return true;
    }

    private function openTriggerMenu() as Void {
        var menu = new WatchUi.Menu2({:title => "Trigger?"});
        for (var i = 0; i < TRIGGERS.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(TRIGGERS[i], null, i, {}));
        }
        WatchUi.pushView(menu, new TriggerMenuDelegate(), WatchUi.SLIDE_UP);
    }

    private function openDiscardConfirm() as Void {
        var menu = new WatchUi.Menu2({:title => "Discard episode?"});
        menu.addItem(new WatchUi.MenuItem("Discard",       null, :discard, {}));
        menu.addItem(new WatchUi.MenuItem("Keep recording", null, :keep,    {}));
        WatchUi.pushView(menu, new DiscardMenuDelegate(), WatchUi.SLIDE_UP);
    }
}

// ── Discard confirmation ─────────────────────────────────────────────────────

class DiscardMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :discard) {
            clearActiveStart();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.requestUpdate();
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }
}

// ── Trigger selection (shown after tapping STOP) ─────────────────────────────

class TriggerMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var start   = getActiveStart() as Number;
        var stop    = Time.now().value().toNumber();
        var trigIdx = item.getId() as Number;
        var trigger = TRIGGERS[trigIdx] as String;

        // Save episode
        var episodes = getEpisodes();
        episodes.add({
            "id"      => stop,
            "start"   => start,
            "stop"    => stop,
            "trigger" => trigger
        });
        persistEpisodes(episodes);
        clearActiveStart();

        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.requestUpdate();
    }

    // BACK on the trigger menu cancels the stop — episode keeps running
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
