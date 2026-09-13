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
    if (cleaned.endsWith(" ...")) {
        cleaned = cleaned.substring(0, cleaned.length - 4);
    }
    return cleaned;
}

function parseLogEntries(logOutput) {
    var entries = [];
    if (!logOutput || typeof logOutput !== 'string') {
        return entries;
    }

    var lines = logOutput.split('\n');
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim();
        if (!line) continue;

        var timestamp = "";
        var content = line;

        // If line has ISO timestamp e.g. 2026-09-13T18:50:00+0000 hostname onedrive[123]: message
        var isoMatch = line.match(/^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[^\s]*)\s+[^:]+:\s*(.*)$/);
        if (isoMatch) {
            var d = new Date(isoMatch[1]);
            if (!isNaN(d.getTime())) {
                timestamp = d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            }
            content = isoMatch[2];
        }

        if (!timestamp) {
            var now = new Date();
            timestamp = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        }

        if (content.match(/Downloading (?:new |modified )?file\s+(.+)/i)) {
            var dlMatch = content.match(/Downloading (?:new |modified )?file\s+(.+)/i);
            var dlPath = cleanFileName(dlMatch[1]);
            entries.push({
                type: "download",
                title: "Downloaded",
                fileName: dlPath,
                filePath: dlPath,
                time: timestamp,
                icon: "download"
            });
        } else if (content.match(/Uploading (?:new |modified )?file\s+(.+)/i)) {
            var upMatch = content.match(/Uploading (?:new |modified )?file\s+(.+)/i);
            var upPath = cleanFileName(upMatch[1]);
            entries.push({
                type: "upload",
                title: "Uploaded",
                fileName: upPath,
                filePath: upPath,
                time: timestamp,
                icon: "upload"
            });
        } else if (content.match(/Deleting (?:item from OneDrive:|item)\s+(.+)/i)) {
            var delMatch = content.match(/Deleting (?:item from OneDrive:|item)\s+(.+)/i);
            var delPath = cleanFileName(delMatch[1]);
            entries.push({
                type: "delete",
                title: "Deleted",
                fileName: delPath,
                filePath: "",
                time: timestamp,
                icon: "edit-delete"
            });
        } else if (content.match(/^Moving\s+(.+)\s+to\s+(.+)$/i)) {
            var moveMatch = content.match(/^Moving\s+(.+)\s+to\s+(.+)$/i);
            var srcPath = cleanFileName(moveMatch[1]);
            var dstPath = cleanFileName(moveMatch[2]);
            entries.push({
                type: "move",
                title: "Moved/Renamed",
                fileName: srcPath + " → " + dstPath,
                filePath: dstPath,
                time: timestamp,
                icon: "edit-rename"
            });
        } else if (content.match(/Creating local directory:\s+(.+)/i)) {
            var mkdirMatch = content.match(/Creating local directory:\s+(.+)/i);
            var dirPath = cleanFileName(mkdirMatch[1]);
            entries.push({
                type: "folder",
                title: "Directory created",
                fileName: dirPath,
                filePath: dirPath,
                time: timestamp,
                icon: "folder-new"
            });
        } else if (content.match(/Successfully created the remote directory\s+(.+?)(?:\s+on OneDrive)?$/i)) {
            var rdirMatch = content.match(/Successfully created the remote directory\s+(.+?)(?:\s+on OneDrive)?$/i);
            var rPath = cleanFileName(rdirMatch[1]);
            entries.push({
                type: "folder",
                title: "Remote directory created",
                fileName: rPath,
                filePath: rPath,
                time: timestamp,
                icon: "folder-cloud"
            });
        } else if (content.indexOf("ERROR:") !== -1 || content.indexOf("Error:") !== -1) {
            entries.push({
                type: "error",
                title: "Error",
                fileName: content.substring(content.indexOf("rror:") + 5).trim(),
                filePath: "",
                time: timestamp,
                icon: "dialog-error"
            });
        }
    }

    return entries;
}
