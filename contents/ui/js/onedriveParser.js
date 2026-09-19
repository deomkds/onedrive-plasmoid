// onedriveParser.js - Utility functions to parse OneDrive CLI & journalctl outputs
.pragma library

function formatBytes(bytes) {
    if (bytes === 0 || isNaN(bytes)) return '0 B';
    var k = 1024;
    var sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function parseQuota(output) {
    var result = {
        valid: false,
        totalBytes: 0,
        usedBytes: 0,
        remainingBytes: 0,
        totalFormatted: "0 GB",
        usedFormatted: "0 GB",
        remainingFormatted: "0 GB",
        percentUsed: 0.0,
        state: "normal"
    };

    if (!output || typeof output !== 'string') {
        return result;
    }

    var lines = output.split('\n');
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim();
        var match;

        if (line.indexOf("Total:") === 0) {
            match = line.match(/Total:\s+([0-9.]+)\s+([A-Za-z]+)\s+\((\d+)\s+bytes\)/i);
            if (match) {
                result.totalFormatted = match[1] + " " + match[2];
                result.totalBytes = parseInt(match[3], 10);
            }
        } else if (line.indexOf("Used:") === 0) {
            match = line.match(/Used:\s+([0-9.]+)\s+([A-Za-z]+)\s+\((\d+)\s+bytes\)/i);
            if (match) {
                result.usedFormatted = match[1] + " " + match[2];
                result.usedBytes = parseInt(match[3], 10);
            }
        } else if (line.indexOf("Remaining:") === 0) {
            match = line.match(/Remaining:\s+([0-9.]+)\s+([A-Za-z]+)\s+\((\d+)\s+bytes\)/i);
            if (match) {
                result.remainingFormatted = match[1] + " " + match[2];
                result.remainingBytes = parseInt(match[3], 10);
            }
        } else if (line.indexOf("State:") === 0) {
            result.state = line.replace("State:", "").trim();
        }
    }

    if (result.totalBytes > 0) {
        result.percentUsed = Math.min(1.0, Math.max(0.0, result.usedBytes / result.totalBytes));
        result.valid = true;
    }

    return result;
}

function parseSyncStatus(output) {
    var result = {
        synced: true,
        accountType: "",
        freeSpace: "",
        details: ""
    };

    if (!output || typeof output !== 'string') {
        return result;
    }

    if (output.indexOf("There are no pending changes") !== -1 ||
        output.indexOf("Sync with OneDrive is complete") !== -1 ||
        output.indexOf("matches the data online") !== -1) {
        result.synced = true;
        result.details = "No pending changes";
    } else if (output.indexOf("pending changes") !== -1 ||
               output.indexOf("out of sync") !== -1 ||
               output.indexOf("data to download") !== -1 ||
               output.indexOf("data to upload") !== -1 ||
               output.indexOf("Downloading") !== -1 ||
               output.indexOf("Uploading") !== -1) {
        result.synced = false;
        result.details = "Changes pending";
    }

    var accountMatch = output.match(/Account Type:\s+([a-zA-Z0-9_-]+)/i);
    if (accountMatch) {
        result.accountType = accountMatch[1];
    }

    var freeMatch = output.match(/Remaining Free Space:\s+([0-9.]+\s+[A-Za-z]+)/i);
    if (freeMatch) {
        result.freeSpace = freeMatch[1];
    }

    return result;
}

function cleanFileName(raw) {
    if (!raw) return "";
    var cleaned = raw.trim();
    // Strip trailing "... done" or "...done" or "..."
    cleaned = cleaned.replace(/\s*\.\.\.\s*done$/i, "");
    cleaned = cleaned.replace(/\s*\.\.\.$/, "");
    // Strip leading "./"
    cleaned = cleaned.replace(/^\.\//, "");
    // Strip surrounding quotes if any
    cleaned = cleaned.replace(/^["']|["']$/g, "");
    return cleaned.trim();
}

function parseLogEntries(logOutput) {
    var entries = [];
    var entryMap = {}; // key: type + ":" + filePath -> entry index in entries
    if (!logOutput || typeof logOutput !== 'string') {
        return entries;
    }

    var lines = logOutput.split('\n');
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim();
        if (!line) continue;

        var timestamp = "";
        var content = line;

        // 1. Match ISO timestamp e.g. 2026-09-18T22:49:10-0300 hostname onedrive[123]: message
        var isoMatch = line.match(/^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[^\s]*)\s+[^:]+:\s*(.*)$/);
        if (isoMatch) {
            var d = new Date(isoMatch[1]);
            if (!isNaN(d.getTime())) {
                timestamp = d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            }
            content = isoMatch[2];
        } else {
            // 2. Match standard syslog format e.g. set 18 22:49:09 host proc[pid]: message or Sep 18 22:49:09 ...
            var syslogMatch = line.match(/^[A-Za-zÀ-ÿ]+(?:\.?)\s+\d+\s+(\d{2}:\d{2}(?::\d{2})?)\s+[^:]+:\s*(.*)$/);
            if (syslogMatch) {
                var tParts = syslogMatch[1].split(':');
                timestamp = tParts[0] + ":" + tParts[1];
                content = syslogMatch[2];
            } else {
                // 3. Match process tag without timestamp e.g. onedrive[5485]: message
                var procMatch = line.match(/^[^:\s]+\[\d+\]:\s*(.*)$/);
                if (procMatch) {
                    content = procMatch[1];
                }
            }
        }

        if (!timestamp) {
            var now = new Date();
            timestamp = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        }

        var entry = null;

        // Progress line: Uploading / Downloading: <path> ... <pct>% | ETA <eta> (or | DONE in <duration>)
        var progressMatch = content.match(/^(Uploading|Downloading):\s+(.+?)\s+\.\.\.\s+(\d+)%\s*(?:\|\s*(?:ETA\s+([^\s]+)|DONE(?:\s+in\s+([^\s]+))?))?/i);
        // Completion line: Uploading / Downloading [new|modified] file: <path> ... done
        var doneMatch = content.match(/^(Uploading|Downloading)\s+(?:new\s+|modified\s+)?file:\s*(.+)/i);

        if (progressMatch) {
            var dir = progressMatch[1].toLowerCase();
            var pType = (dir === "uploading") ? "upload" : "download";
            var pPath = cleanFileName(progressMatch[2]);
            var pct = parseInt(progressMatch[3], 10);
            var pEta = progressMatch[4] || "";
            var pDoneIn = progressMatch[5] || "";
            var pDone = (pct >= 100 || !!pDoneIn);

            entry = {
                type: pType,
                title: pDone ? (pType === "upload" ? "Uploaded" : "Downloaded") : (pType === "upload" ? "Uploading (" + pct + "%)" : "Downloading (" + pct + "%)"),
                fileName: pPath,
                filePath: pPath,
                time: timestamp,
                icon: pType,
                progress: pct,
                status: pDone ? "completed" : "in_progress",
                eta: pDone ? "" : pEta
            };
        } else if (doneMatch) {
            var dDir = doneMatch[1].toLowerCase();
            var dType = (dDir === "uploading") ? "upload" : "download";
            var dPath = cleanFileName(doneMatch[2]);
            entry = {
                type: dType,
                title: (dType === "upload") ? "Uploaded" : "Downloaded",
                fileName: dPath,
                filePath: dPath,
                time: timestamp,
                icon: dType,
                progress: 100,
                status: "completed",
                eta: ""
            };
        } else if (content.match(/Deleting (?:item from OneDrive:|item)\s+(.+)/i)) {
            var delMatch = content.match(/Deleting (?:item from OneDrive:|item)\s+(.+)/i);
            var delPath = cleanFileName(delMatch[1]);
            entry = {
                type: "delete",
                title: "Deleted",
                fileName: delPath,
                filePath: "",
                time: timestamp,
                icon: "edit-delete",
                progress: -1,
                status: "completed",
                eta: ""
            };
        } else if (content.match(/^Moving\s+(.+)\s+to\s+(.+)$/i)) {
            var moveMatch = content.match(/^Moving\s+(.+)\s+to\s+(.+)$/i);
            var srcPath = cleanFileName(moveMatch[1]);
            var dstPath = cleanFileName(moveMatch[2]);
            entry = {
                type: "move",
                title: "Moved/Renamed",
                fileName: srcPath + " → " + dstPath,
                filePath: dstPath,
                time: timestamp,
                icon: "edit-rename",
                progress: -1,
                status: "completed",
                eta: ""
            };
        } else if (content.match(/Creating local directory:\s+(.+)/i)) {
            var mkdirMatch = content.match(/Creating local directory:\s+(.+)/i);
            var dirPath = cleanFileName(mkdirMatch[1]);
            entry = {
                type: "folder",
                title: "Directory created",
                fileName: dirPath,
                filePath: dirPath,
                time: timestamp,
                icon: "folder-new",
                progress: -1,
                status: "completed",
                eta: ""
            };
        } else if (content.match(/Successfully created the remote directory\s+(.+?)(?:\s+on\s+(?:Microsoft\s+)?OneDrive)?$/i)) {
            var rdirMatch = content.match(/Successfully created the remote directory\s+(.+?)(?:\s+on\s+(?:Microsoft\s+)?OneDrive)?$/i);
            var rPath = cleanFileName(rdirMatch[1]);
            entry = {
                type: "folder",
                title: "Remote directory created",
                fileName: rPath,
                filePath: rPath,
                time: timestamp,
                icon: "folder-cloud",
                progress: -1,
                status: "completed",
                eta: ""
            };
        } else if (content.indexOf("ERROR:") !== -1 || content.indexOf("Error:") !== -1) {
            entry = {
                type: "error",
                title: "Error",
                fileName: content.substring(content.indexOf("rror:") + 5).trim(),
                filePath: "",
                time: timestamp,
                icon: "dialog-error",
                progress: -1,
                status: "error",
                eta: ""
            };
        }

        if (entry) {
            var key = entry.type + ":" + (entry.filePath || entry.fileName);
            if (entryMap.hasOwnProperty(key)) {
                var existingIdx = entryMap[key];
                entries[existingIdx] = entry;
            } else {
                entryMap[key] = entries.length;
                entries.push(entry);
            }
        }
    }

    return entries;
}
