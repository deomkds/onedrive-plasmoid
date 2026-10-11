import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import "js/onedriveParser.js" as OneDriveParser

PlasmoidItem {
    id: root

    // Global exposed properties for child representations
    property string syncStatus: "idle" // "idle", "syncing", "suspended", "offline", "error"
    property string statusDescription: i18n("Ready")
    property string accountType: ""
    property string quotaTotal: "0 GB"
    property string quotaUsed: "0 GB"
    property string quotaRemaining: ""
    property real quotaPercent: 0.0
    property string lastSyncTime: ""
    property bool isBusy: false
    property string userHome: ""
    property string resolvedSyncDir: "~/OneDrive"

    property var activityModel: ListModel {}

    Plasmoid.icon: {
        var style = plasmoid.configuration.iconStyle || "onedrive";
        if (style === "onedrive-monochrome") {
            return Qt.resolvedUrl("assets/onedrive-monochrome.svg");
        }
        if (style === "folder-onedrive-symbolic") {
            return "folder-onedrive-symbolic";
        }
        if (style === "cloudstatus" || style === "cloud") {
            return "cloudstatus";
        }
        if (style === "folder-onedrive") {
            return "folder-onedrive";
        }
        return "onedrive";
    }

    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    readonly property bool inPanel: [
        PlasmaCore.Types.TopEdge,
        PlasmaCore.Types.RightEdge,
        PlasmaCore.Types.BottomEdge,
        PlasmaCore.Types.LeftEdge,
    ].includes(Plasmoid.location)

    toolTipTextFormat: Text.PlainText
    toolTipMainText: i18n("Microsoft OneDrive")
    toolTipSubText: {
        var text = i18n("Status: %1", root.statusDescription);
        if (root.quotaRemaining !== "") {
            text += "\n" + i18n("Free space: %1", root.quotaRemaining);
        }
        if (root.lastSyncTime !== "") {
            text += "\n" + i18n("Last updated: %1", root.lastSyncTime);
        }
        return text;
    }

    compactRepresentation: CompactRepresentation {
        plasmoidItem: root
    }
    fullRepresentation: FullRepresentation {
        mainRoot: root
        Plasmoid.backgroundHints: root.inPanel ? PlasmaCore.Types.NoBackground : PlasmaCore.Types.DefaultBackground
    }

    // Context menu actions for right-click on panel icon
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Open OneDrive Folder")
            icon.name: "folder-open"
            onTriggered: root.openFolder()
        },
        PlasmaCore.Action {
            text: i18n("Sync Now")
            icon.name: "state-sync"
            enabled: !root.isBusy && root.syncStatus !== "syncing"
            onTriggered: root.triggerSync()
        },
        PlasmaCore.Action {
            text: (root.syncStatus === "suspended" || root.syncStatus === "offline") ? i18n("Resume Synchronization") : i18n("Pause Synchronization")
            icon.name: (root.syncStatus === "suspended" || root.syncStatus === "offline") ? "media-playback-start" : "media-playback-pause"
            enabled: !root.isBusy
            onTriggered: root.togglePause()
        },
        PlasmaCore.Action {
            text: i18n("Open OneDrive on Web")
            icon.name: "internet-services"
            onTriggered: root.openWeb()
        },
        PlasmaCore.Action {
            text: i18n("Refresh Status")
            icon.name: "view-refresh"
            onTriggered: root.refreshAll()
        }
    ]

    // DataSource engine for executing CLI commands
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        property var callbacks: ({})

        onNewData: function(sourceName, data) {
            var cb = callbacks[sourceName];
            if (cb) {
                cb(data);
                delete callbacks[sourceName];
            }
            disconnectSource(sourceName);
        }

        function run(cmd, callback) {
            if (callback) {
                callbacks[cmd] = callback;
            }
            connectSource(cmd);
        }
    }

    function execute(cmd, callback) {
        executable.run(cmd, callback);
    }

    // Helper to safely escape arguments for shell execution
    function escapeShellArg(arg) {
        if (!arg) return "''";
        return "'" + ("" + arg).replace(/'/g, "'\\''") + "'";
    }

    // Helper to resolve ~ in paths
    function resolvePath(p) {
        if (!p) return "";
        if (p.indexOf("~/") === 0 && root.userHome !== "") {
            return root.userHome + p.substring(1);
        }
        return p;
    }

    // Initialize user environment and directories
    Component.onCompleted: {
        execute("echo $HOME", function(data) {
            if (data && data["stdout"]) {
                root.userHome = data["stdout"].trim();
                root.updateResolvedSyncDir();
            }
            root.refreshAll();
        });
    }

    Connections {
        target: plasmoid.configuration
        function onSyncDirChanged() {
            root.updateResolvedSyncDir();
        }
        function onPollIntervalChanged() {
            pollTimer.interval = Math.max(5, plasmoid.configuration.pollInterval) * 1000;
        }
        function onQuotaIntervalChanged() {
            quotaTimer.interval = Math.max(60, plasmoid.configuration.quotaInterval) * 1000;
        }
    }

    function updateResolvedSyncDir() {
        var raw = plasmoid.configuration.syncDir || "~/OneDrive";
        root.resolvedSyncDir = resolvePath(raw);
    }

    // Comprehensive refresh
    function refreshAll() {
        checkStatus();
        fetchQuota();
        fetchRecentLogs();
    }

    function resetPollInterval() {
        // If there are active file transfers, keep faster polling
        for (var a = 0; a < Math.min(15, root.activityModel.count); a++) {
            var it = root.activityModel.get(a);
            if (it && it.status === "in_progress") {
                if (pollTimer.interval !== 2000) {
                    pollTimer.interval = 2000;
                    pollTimer.restart();
                }
                return;
            }
        }
        var baseInterval = Math.max(5, plasmoid.configuration.pollInterval || 10) * 1000;
        if (pollTimer.interval !== baseInterval) {
            pollTimer.interval = baseInterval;
        }
    }

    // Status checking
    function checkStatus() {
        if (plasmoid.configuration.serviceMode === "systemd") {
            var service = plasmoid.configuration.systemdService || "onedrive.service";
            execute("systemctl --user is-active " + service, function(data) {
                var stdout = (data["stdout"] || "").trim();
                if (stdout === "active") {
                    resetPollInterval();

                    // Immediately update status if we were activating/offline/paused
                    if (root.syncStatus !== "syncing") {
                        root.syncStatus = "idle";
                        if (root.statusDescription.indexOf("Stopped") !== -1 || root.statusDescription.indexOf("Starting") !== -1) {
                            root.statusDescription = i18n("Active");
                        }
                    }

                    // Service is running, query status details
                    execute((plasmoid.configuration.onedriveBin || "onedrive") + " --display-sync-status", function(statusData) {
                        var out = (statusData["stdout"] || "");
                        var parsed = OneDriveParser.parseSyncStatus(out);
                        if (parsed.accountType) root.accountType = parsed.accountType;
                        if (parsed.freeSpace) root.quotaRemaining = parsed.freeSpace;

                        if (parsed.synced) {
                            root.syncStatus = "idle";
                            root.statusDescription = i18n("Synchronized");
                        } else {
                            root.syncStatus = "syncing";
                            root.statusDescription = i18n("Synchronizing...");
                        }
                        root.lastSyncTime = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
                    });
                } else if (stdout === "activating" || stdout === "reloading") {
                    root.syncStatus = "syncing";
                    root.statusDescription = stdout === "reloading" ? i18n("Reloading...") : i18n("Starting...");
                    // Poll faster while service is activating so plasmoid quickly reflects success
                    pollTimer.interval = 2000;
                    pollTimer.restart();
                } else if (stdout === "inactive" || stdout === "deactivating") {
                    resetPollInterval();
                    root.syncStatus = "suspended";
                    root.statusDescription = stdout === "deactivating" ? i18n("Stopping...") : i18n("Paused / Suspended");
                } else if (stdout === "failed") {
                    resetPollInterval();
                    root.syncStatus = "error";
                    root.statusDescription = i18n("Service Error");
                } else {
                    resetPollInterval();
                    root.syncStatus = "offline";
                    root.statusDescription = i18n("Not running (%1)", stdout || "inactive");
                }
            });
        } else {
            resetPollInterval();
            // Standalone CLI mode
            var rawBin = (plasmoid.configuration.onedriveBin || "onedrive").trim();
            var binName = rawBin.split("/").pop().replace(/["']/g, "").trim() || "onedrive";
            execute("pgrep -x " + escapeShellArg(binName), function(data) {
                var pid = (data["stdout"] || "").trim();
                if (pid !== "") {
                    root.syncStatus = "idle";
                    root.statusDescription = i18n("Running (PID %1)", pid);
                } else {
                    root.syncStatus = "offline";
                    root.statusDescription = i18n("Not running");
                }
            });
        }
    }

    // Storage quota query
    function fetchQuota() {
        var bin = plasmoid.configuration.onedriveBin || "onedrive";
        execute(bin + " --display-quota", function(data) {
            if (data && data["stdout"]) {
                var quota = OneDriveParser.parseQuota(data["stdout"]);
                if (quota.valid) {
                    root.quotaTotal = quota.totalFormatted;
                    root.quotaUsed = quota.usedFormatted;
                    root.quotaRemaining = quota.remainingFormatted;
                    root.quotaPercent = quota.percentUsed;
                }
            }
        });
    }

    // Recent activity log reading
    function fetchRecentLogs() {
        var service = plasmoid.configuration.systemdService || "onedrive.service";
        var cmd = "journalctl --user -u " + service + " -n 50 --output=short-iso --no-pager";

        execute(cmd, function(data) {
            if (data && data["stdout"]) {
                var entries = OneDriveParser.parseLogEntries(data["stdout"]);
                if (entries.length > 0) {
                    var hasActiveTransfers = false;
                    for (var i = 0; i < entries.length; i++) {
                        var e = entries[i];
                        if (e.status === "in_progress") {
                            hasActiveTransfers = true;
                        }

                        // Check if already in model
                        var foundIndex = -1;
                        for (var j = 0; j < Math.min(20, root.activityModel.count); j++) {
                            var current = root.activityModel.get(j);
                            if (current && (current.fileName === e.fileName || (current.filePath && current.filePath === e.filePath)) && current.type === e.type) {
                                foundIndex = j;
                                break;
                            }
                        }

                        if (foundIndex !== -1) {
                            var existing = root.activityModel.get(foundIndex);
                            if (existing.status === "completed" && e.status === "in_progress") {
                                root.activityModel.remove(foundIndex);
                                root.activityModel.insert(0, e);
                            } else if (existing.progress !== e.progress || existing.status !== e.status || existing.eta !== e.eta || existing.title !== e.title) {
                                root.activityModel.setProperty(foundIndex, "progress", e.progress);
                                root.activityModel.setProperty(foundIndex, "status", e.status);
                                root.activityModel.setProperty(foundIndex, "eta", e.eta);
                                root.activityModel.setProperty(foundIndex, "title", e.title);
                                root.activityModel.setProperty(foundIndex, "time", e.time);
                            }
                        } else {
                            root.activityModel.insert(0, e);
                        }
                    }

                    // Limit model size
                    while (root.activityModel.count > 40) {
                        root.activityModel.remove(root.activityModel.count - 1);
                    }

                    if (hasActiveTransfers) {
                        if (root.syncStatus !== "syncing") {
                            root.syncStatus = "syncing";
                            root.statusDescription = i18n("Synchronizing...");
                        }
                        if (pollTimer.interval > 2000) {
                            pollTimer.interval = 2000;
                            pollTimer.restart();
                        }
                    }
                }
            }
        });
    }

    // User Actions
    function triggerSync() {
        root.isBusy = true;
        root.syncStatus = "syncing";
        root.statusDescription = i18n("Syncing...");

        if (plasmoid.configuration.serviceMode === "systemd") {
            var service = plasmoid.configuration.systemdService || "onedrive.service";
            execute("systemctl --user restart " + service, function(data) {
                root.isBusy = false;
                checkStatus();
                fetchRecentLogs();
            });
        } else {
            var bin = plasmoid.configuration.onedriveBin || "onedrive";
            execute(bin + " --sync", function(data) {
                root.isBusy = false;
                checkStatus();
                fetchRecentLogs();
                fetchQuota();
            });
        }
    }

    function togglePause() {
        root.isBusy = true;
        var service = plasmoid.configuration.systemdService || "onedrive.service";

        if (root.syncStatus === "suspended" || root.syncStatus === "offline") {
            root.syncStatus = "syncing";
            root.statusDescription = i18n("Starting service...");
            execute("systemctl --user start " + service, function(data) {
                root.isBusy = false;
                checkStatus();
            });
        } else {
            root.statusDescription = i18n("Stopping service...");
            execute("systemctl --user stop " + service, function(data) {
                root.isBusy = false;
                root.syncStatus = "suspended";
                root.statusDescription = i18n("Paused / Suspended");
            });
        }
    }

    function openFolder() {
        var dir = root.resolvedSyncDir || "~/OneDrive";
        execute("xdg-open \"" + dir + "\"");
    }

    function openFileOrFolder(target) {
        if (!target) {
            openFolder();
            return;
        }

        var cleanTarget = ("" + target).trim();
        // If string contains move/rename indicator ("src → dst" or "src -> dst"), extract destination
        if (cleanTarget.indexOf("→") !== -1 || cleanTarget.indexOf("->") !== -1) {
            var parts = cleanTarget.split(/\s*(?:→|->)\s*/);
            cleanTarget = parts[parts.length - 1].trim();
        }

        // Remove surrounding quotes, relative ./ prefix, and accidental leading slashes
        cleanTarget = cleanTarget.replace(/^["']|["']$/g, "").replace(/^\.\//, "").replace(/^\/+/, "");

        var syncDir = root.resolvedSyncDir;
        var fullPath = "";
        if (cleanTarget.indexOf(syncDir) === 0) {
            fullPath = cleanTarget;
        } else {
            fullPath = syncDir + "/" + cleanTarget;
        }

        // Smart shell script:
        // 1. If file exists, select it with dolphin
        // 2. If file missing but parent directory exists, open directory
        // 3. If neither exists, fallback cleanly to sync directory
        // Positional parameters $1 (fullPath) and $2 (syncDir) prevent arbitrary shell code execution
        var script = 'f="$1"; s="$2"; ' +
                     'if [ -e "$f" ]; then ' +
                     '  dolphin --select "$f" 2>/dev/null || xdg-open "$f" 2>/dev/null || xdg-open "$s" 2>/dev/null; ' +
                     'else ' +
                     '  d="$(dirname "$f")"; ' +
                     '  if [ -d "$d" ]; then ' +
                     '    xdg-open "$d" 2>/dev/null || xdg-open "$s" 2>/dev/null; ' +
                     '  else ' +
                     '    xdg-open "$s" 2>/dev/null; ' +
                     '  fi; ' +
                     'fi';

        execute("sh -c " + escapeShellArg(script) + " _ " + escapeShellArg(fullPath) + " " + escapeShellArg(syncDir));
    }

    function openWeb() {
        var url = plasmoid.configuration.webUrl || "https://onedrive.live.com";
        execute("xdg-open \"" + url + "\"");
    }

    function viewLogs() {
        var service = plasmoid.configuration.systemdService || "onedrive.service";
        execute("konsole -e journalctl --user -u " + service + " -f || xdg-open \"journalctl --user -u " + service + "\"");
    }

    function openConfiguration() {
        var action = null;
        if (typeof plasmoid !== "undefined" && typeof plasmoid.internalAction === "function") {
            action = plasmoid.internalAction("configure");
        }
        if (!action && typeof Plasmoid !== "undefined" && typeof Plasmoid.internalAction === "function") {
            action = Plasmoid.internalAction("configure");
        }
        if (!action && typeof plasmoid !== "undefined" && typeof plasmoid.action === "function") {
            action = plasmoid.action("configure");
        }
        if (!action && typeof Plasmoid !== "undefined" && typeof Plasmoid.action === "function") {
            action = Plasmoid.action("configure");
        }

        if (action) {
            root.expanded = false;
            action.trigger();
        }
    }

    function clearActivityLog() {
        root.activityModel.clear();
    }

    // Periodic timers
    Timer {
        id: pollTimer
        interval: Math.max(5, plasmoid.configuration.pollInterval || 10) * 1000
        running: true
        repeat: true
        onTriggered: {
            checkStatus();
            fetchRecentLogs();
        }
    }

    Timer {
        id: quotaTimer
        interval: Math.max(60, plasmoid.configuration.quotaInterval || 900) * 1000
        running: true
        repeat: true
        onTriggered: {
            fetchQuota();
        }
    }
}
