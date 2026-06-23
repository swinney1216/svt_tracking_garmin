import Toybox.Lang;
import Toybox.WatchUi;

// ── Episodes history ─────────────────────────────────────────────────────────
//
// Accessed via UP button from the main screen.
// Shows a scrollable Menu2 list — most recent episode first.
// Selecting an episode opens a delete confirmation.
// "Delete All" item at the bottom clears everything.

function openEpisodesMenu() as Void {
    var episodes = getEpisodes();
    var menu     = new WatchUi.Menu2({:title => "Episodes"});

    if (episodes.size() == 0) {
        menu.addItem(new WatchUi.MenuItem("No episodes yet", null, :empty, {}));
    } else {
        // Most recent first (episodes stored chronologically, iterate backwards)
        for (var i = episodes.size() - 1; i >= 0; i--) {
            var ep      = episodes[i] as Dictionary;
            var start   = ep["start"] as Number;
            var stop    = ep["stop"]  as Number;
            var trigger = ep.hasKey("trigger") ? ep["trigger"] as String : "None";
            var label   = fmtTimestamp(start);
            var sub     = fmtDuration(stop - start);
            if (!trigger.equals("None")) {
                sub = sub + " - " + trigger;
            }
            menu.addItem(new WatchUi.MenuItem(label, sub, i, {}));
        }
        menu.addItem(new WatchUi.MenuItem("-- Delete All --", null, :deleteAll, {}));
    }

    WatchUi.pushView(menu, new EpisodesMenuDelegate(), WatchUi.SLIDE_UP);
}

// ── Episodes list delegate ───────────────────────────────────────────────────

class EpisodesMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();

        if (id == :empty) {
            // Nothing to act on — close
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :deleteAll) {
            openDeleteAllConfirm();
        } else {
            // id is the original array index of the episode
            openDeleteEpisodeConfirm(id as Number);
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    private function openDeleteEpisodeConfirm(idx as Number) as Void {
        var episodes = getEpisodes();
        var ep       = episodes[idx] as Dictionary;
        var label    = fmtTimestamp(ep["start"] as Number);
        var menu     = new WatchUi.Menu2({:title => label});
        menu.addItem(new WatchUi.MenuItem("Delete episode", null, :confirm, {}));
        menu.addItem(new WatchUi.MenuItem("Cancel",         null, :cancel,  {}));
        WatchUi.pushView(menu, new DeleteEpisodeDelegate(idx), WatchUi.SLIDE_UP);
    }

    private function openDeleteAllConfirm() as Void {
        var count = getEpisodes().size();
        var title = "Delete all " + count.format("%d") + "?";
        var menu  = new WatchUi.Menu2({:title => title});
        menu.addItem(new WatchUi.MenuItem("Confirm", null, :confirm, {}));
        menu.addItem(new WatchUi.MenuItem("Cancel",  null, :cancel,  {}));
        WatchUi.pushView(menu, new DeleteAllDelegate(), WatchUi.SLIDE_UP);
    }
}

// ── Delete single episode ────────────────────────────────────────────────────

class DeleteEpisodeDelegate extends WatchUi.Menu2InputDelegate {

    private var _idx as Number;

    function initialize(idx as Number) {
        Menu2InputDelegate.initialize();
        _idx = idx;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :confirm) {
            var episodes = getEpisodes();
            var newEps   = [] as Array;
            for (var i = 0; i < episodes.size(); i++) {
                if (i != _idx) {
                    newEps.add(episodes[i]);
                }
            }
            persistEpisodes(newEps);
            // Pop delete confirm + episodes list → back to main
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }
}

// ── Delete all episodes ──────────────────────────────────────────────────────

class DeleteAllDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :confirm) {
            persistEpisodes([] as Array);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }
}
