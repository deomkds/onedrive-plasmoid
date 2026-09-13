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

    Plasmoid.icon: plasmoid.configuration.iconStyle === "color"
        ? Qt.resolvedUrl("../../images/OneDrive.svg")
        : "cloud"

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

    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : compactRepresentation
    compactRepresentation: CompactRepresentation {
        mainRoot: root
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
            text: root.syncStatus === "suspended" ? i18n("Resume Synchronization") : i18n("Pause Synchronization")
            icon.name: root.syncStatus === "suspended" ? "media-playback-start" : "media-playback-pause"
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

    // Status checking
    function checkStatus() {
        if (plasmoid.configuration.serviceMode === "systemd") {
            var service = plasmoid.configuration.systemdService || "onedrive.service";
            execute("systemctl --user is-active " + service, function(data) {
                var stdout = (data["stdout"] || "").trim();
                if (stdout === "active") {
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
                } else if (stdout === "inactive" || stdout === "deactivating") {
                    root.syncStatus = "suspended";
                    root.statusDescription = i18n("Paused / Suspended");
                } else if (stdout === "failed") {
                    root.syncStatus = "error";
                    root.statusDescription = i18n("Service Error");
                } else {
                    root.syncStatus = "offline";
                    root.statusDescription = i18n("Stopped (%1)", stdout || "inactive");
                }
            });
        } else {
            // Standalone CLI mode
            execute("pgrep -x " + (plasmoid.configuration.onedriveBin || "onedrive"), function(data) {
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
        var cmd = "journalctl --user -u " + service + " -n 35 --output=short-iso --no-pager";

        execute(cmd, function(data) {
            if (data && data["stdout"]) {
                var entries = OneDriveParser.parseLogEntries(data["stdout"]);
                if (entries.length > 0) {
                    for (var i = entries.length - 1; i >= 0; i--) {
                        var e = entries[i];
                        // Check if already in model
                        var exists = false;
                        for (var j = 0; j < Math.min(10, root.activityModel.count); j++) {
                            var current = root.activityModel.get(j);
                            if (current && current.fileName === e.fileName && current.type === e.type) {
                                exists = true;
                                break;
                            }
                        }
                        if (!exists) {
                            root.activityModel.insert(0, e);
                        }
                    }
                    // Limit model size
                    while (root.activityModel.count > 40) {
                        root.activityModel.remove(root.activityModel.count - 1);
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
            execute("systemctl --user start " + service, function(data) {
                root.isBusy = false;
                checkStatus();
            });
        } else {
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

    function openFileOrFolder(fileName) {
        if (!fileName) {
            openFolder();
            return;
        }
        var fullPath = root.resolvedSyncDir + "/" + fileName;
        execute("dolphin --select \"" + fullPath + "\" || xdg-open \"" + root.resolvedSyncDir + "\"");
    }

    function openWeb() {
        var url = plasmoid.configuration.webUrl || "https://onedrive.live.com";
        execute("xdg-open \"" + url + "\"");
    }

    function viewLogs() {
        var service = plasmoid.configuration.systemdService || "onedrive.service";
        execute("konsole -e journalctl --user -u " + service + " -f || xdg-open \"journalctl --user -u " + service + "\"");
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
