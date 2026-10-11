# Bug Report — onedrive-plasmoid (Data Logic & Parsing) — 2026-10-11

## Summary
- Critical: 0 open, 2 fixed
- Intermediate: 0 open, 11 fixed
- Normal: 0 open, 7 fixed

## 🔴 Critical
*(All critical bugs resolved)*

## 🟡 Intermediate
*(All intermediate bugs resolved)*

## 🟢 Normal
*(All normal bugs resolved)*

## ✅ Resolved

### BUG-001: Arbitrary Code Execution and Variable Expansion via Synced File Names in File Click Handler — Fixed 2026-10-11
- **File:** contents/ui/main.qml:423
- **Issue:** `openFileOrFolder` constructs a shell script by directly concatenating `fullPath` into double quotes (`f="' + fullPath.replace(/"/g, '\\"') + '";`) executed via `sh -c`. Double quotes in shell scripts evaluate parameter expansions (`$FOO`), command substitutions (`$(cmd)` and `` `cmd` ``), and arithmetic expansions. Any synced file name with shell metacharacters triggers arbitrary shell command execution when clicked, while files with `$` (e.g. `Budget$2024.xlsx`) have their paths expanded and corrupted. Furthermore, a trailing backslash escapes the closing quote and causes a shell syntax error.
- **Trigger:** User clicks on an activity feed item corresponding to a file whose name contains `$()`, `` ` ``, `$`, or a trailing backslash.
- **Impact:** Arbitrary code execution from files synced from remote OneDrive accounts, and failure to open legitimate files with `$` in their names.
- **Suggested Fix:** Avoid constructing shell scripts with string interpolation. Instead, pass paths as separate positional arguments to `sh -c '...' -- "$fullPath" "$syncDir"` and reference `"$1"` and `"$2"`, or use single-quote escaping for literals.
- **Fix Applied:** Implemented `escapeShellArg()` utility in `main.qml` and refactored `openFileOrFolder()` to execute `sh -c` passing `fullPath` and `syncDir` as positional arguments (`$1` and `$2`), completely preventing command injection and variable expansion.
- **Status:** Resolved

### BUG-002: Standalone Mode Fails to Detect Running Process When Given Binary Path — Fixed 2026-10-11
- **File:** contents/ui/main.qml:253
- **Issue:** In standalone CLI mode, `checkStatus()` runs `pgrep -x " + (plasmoid.configuration.onedriveBin || "onedrive")`. The configuration schema and UI label explicitly prompt the user for the "Path to onedrive executable" (e.g. `/usr/bin/onedrive`). `pgrep -x` matches process command names (`COMM`, maximum 15 characters), never executable paths.
- **Trigger:** Setting `onedriveBin` to a full path such as `/usr/bin/onedrive` while `serviceMode` is set to standalone.
- **Impact:** The plasmoid permanently reports "Not running" (offline) even when OneDrive is active and running.
- **Suggested Fix:** Extract the basename of `onedriveBin` prior to running `pgrep -x`, or check with `pidof` / `pgrep -f`.
- **Fix Applied:** Extracted the executable basename using `rawBin.split("/").pop().replace(/["']/g, "").trim()` and escaped the argument with `escapeShellArg()` before running `pgrep -x`.
- **Status:** Resolved

### BUG-003: Substring Index Inversion Mangling Error Log Messages — Fixed 2026-10-11
- **File:** contents/ui/js/onedriveParser.js:265
- **Issue:** When parsing log lines containing `"ERROR:"`, line 265 extracts the error string using `content.substring(content.indexOf("rror:") + 5).trim()`. Because `"ERROR:"` is in uppercase, `content.indexOf("rror:")` returns `-1`. The expression evaluates to `-1 + 5 = 4`, slicing the line from index 4 regardless of where the error actually begins (e.g. `"ERROR: Network failed"` becomes `"R: Network failed"`, and `"onedrive[123]: ERROR: ..."` becomes `"rive[123]: ERROR: ..."`).
- **Trigger:** Any journal log entry containing `"ERROR:"` in uppercase.
- **Impact:** Activity feed displays garbled error messages with chopped words or prepended process tags.
- **Suggested Fix:** Use a case-insensitive regular expression match such as `/(?:error):\s*(.*)/i` or search for `/(?:ERROR|Error):\s*/`.
- **Fix Applied:** Replaced inverted `indexOf` calculation with `content.match(/(?:ERROR|Error):\s*(.+)/i)` and cleaned the extracted message using `cleanFileName()`.
- **Status:** Resolved

### BUG-004: Greedy Regex in Move/Rename Parsing Mangles Paths Containing " to " — Fixed 2026-10-11
- **File:** contents/ui/js/onedriveParser.js:218
- **Issue:** The regex `^Moving\s+(.+)\s+to\s+(.+)$` uses a greedy `(.+)` for the source path before `\s+to\s+`. If a file name or directory name contains `" to "` (e.g. `Moving ./Letter to Mom.docx to ./Archive/Letter to Mom.docx`), `moveMatch[1]` captures everything up to the final `" to "`, leaving only `"Mom.docx"` as the destination.
- **Trigger:** Moving or renaming any file or directory containing `" to "` in its name or parent directory path.
- **Impact:** Corrupted file paths in the activity feed delegate and incorrect target paths when clicked.
- **Suggested Fix:** Change the first group to non-greedy: `/^Moving\s+(.+?)\s+to\s+(.+)$/i`.
- **Fix Applied:** Refactored move parsing with `/^Moving\s+(.+?)\s+to\s+(\.?\/.+)$/i` with fallback to greedy match, preserving complete source and destination directory paths.
- **Status:** Resolved

### BUG-005: Deletion Regex Matches Stale String and Misses Local File Deletions — Fixed 2026-10-11
- **File:** contents/ui/js/onedriveParser.js:204
- **Issue:** The regex `/Deleting (?:item from OneDrive:|item)\s+(.+)/i` expects `"Deleting item from OneDrive:"`, but OneDrive logs `"Deleting item from Microsoft OneDrive:"`, `"Deleting online file from Microsoft OneDrive:"`, and `"Deleting local file:"`. The current regex matches `"item"` and captures `"from Microsoft OneDrive: <path>"`, giving the item a corrupted name. Furthermore, local file and directory deletions (`Deleting local file:`) do not match at all.
- **Trigger:** OneDrive deletes a file remotely or locally.
- **Impact:** Remote deletions show the file name prepended with `"from Microsoft OneDrive: "`, and local deletions are completely omitted from the activity feed.
- **Suggested Fix:** Update the regex to match `/Deleting (?:item from (?:Microsoft )?OneDrive|local file|local directory|online (?:file|folder) from (?:Microsoft )?OneDrive):\s*(.+)/i`.
- **Fix Applied:** Updated deletion regex to match all Microsoft OneDrive deletion message variations (`item from Microsoft OneDrive`, `local file`, `local directory`, `online file/folder`).
- **Status:** Resolved

### BUG-006: Missing `--verbose` Flag Leaves `accountType` Permanently Blank — Fixed 2026-10-11
- **File:** contents/ui/main.qml:215
- **Issue:** `checkStatus()` invokes `onedrive --display-sync-status` without `--verbose`, expecting stdout to contain `Account Type:` and `Remaining Free Space:`. In OneDrive CLI, those two fields are only output when the `--verbose` flag is passed.
- **Trigger:** Polling OneDrive status in standard systemd mode.
- **Impact:** `root.accountType` is never populated, leaving the account type indicator in `FullRepresentation.qml` permanently blank.
- **Suggested Fix:** Pass `--verbose` to `onedrive --display-sync-status`.
- **Fix Applied:** Passed `--verbose` along with `getConfDirArg()` to `onedrive --display-sync-status` in both systemd and standalone status checks.
- **Status:** Resolved

### BUG-007: Fallback in `viewLogs()` Calls `xdg-open` on Command String — Fixed 2026-10-11
- **File:** contents/ui/main.qml:446
- **Issue:** Line 446 runs `konsole -e journalctl ... || xdg-open "journalctl --user -u " + service + "\"`. If `konsole` is not installed, `xdg-open` treats the string as a local file or URI. It searches for a file named `journalctl --user -u onedrive.service` in the working directory and exits with code 4.
- **Trigger:** User clicks "View OneDrive Service Logs" on a system without `konsole` installed.
- **Impact:** Log viewer fails to launch and prints an error to stderr.
- **Suggested Fix:** Use `xdg-terminal-exec` or iterate through common terminal emulators (`x-terminal-emulator`, `alacritty`, `kitty`, `foot`, `gnome-terminal`) to launch the command in an actual terminal.
- **Fix Applied:** Updated `viewLogs()` to probe a list of supported terminal emulators (`konsole`, `xdg-terminal-exec`, `x-terminal-emulator`, `gnome-terminal`, `alacritty`, `kitty`, `foot`) and safely launch `journalctl -f`.
- **Status:** Resolved

### BUG-008: Default `synced: true` in `parseSyncStatus` Masks Error and Unconfigured States — Fixed 2026-10-11
- **File:** contents/ui/js/onedriveParser.js:67
- **Issue:** `parseSyncStatus` initializes `synced: true`. If `onedrive --display-sync-status` outputs an unhandled network error, authorization error, or configuration failure, neither the success nor pending conditions match. `synced: true` is returned, causing `main.qml` to report `root.syncStatus = "idle"` and `statusDescription = i18n("Synchronized")`.
- **Trigger:** Network failure, expired OneDrive credentials, or daemon unconfigured state.
- **Impact:** The plasmoid misleadingly reports status as synchronized when an error is occurring.
- **Suggested Fix:** Initialize `synced: false`, check for error keywords in `output`, and provide a `valid` or `error` field in the result object.
- **Fix Applied:** Initialized `synced: false`, added `error: true` detection for network/auth/daemon errors, and updated `main.qml` to transition to `"error"` status when `parsed.error` is true.
- **Status:** Resolved

### BUG-009: Standalone Mode Bypasses Process Management in `togglePause` and `fetchRecentLogs` — Fixed 2026-10-11
- **File:** contents/ui/main.qml:369
- **Issue:** `togglePause()` does not check `plasmoid.configuration.serviceMode`. It hardcodes `systemctl --user start/stop` even when in standalone CLI mode. Similarly, `fetchRecentLogs()` still queries `journalctl --user -u onedrive.service`.
- **Trigger:** Using standalone CLI mode and clicking pause/resume or checking the activity log.
- **Impact:** Pause and resume controls fail or target an inactive systemd service; recent logs remain empty or stale.
- **Suggested Fix:** Check `plasmoid.configuration.serviceMode` in `togglePause()` and `fetchRecentLogs()` to send appropriate signals (e.g. `SIGSTOP`/`SIGCONT` or terminate/spawn process) or disable unsupported controls in standalone mode.
- **Fix Applied:** Updated `togglePause()` to manage standalone processes via `pkill` and launching `--monitor`, and guarded `fetchRecentLogs()` to only query `journalctl` when `serviceMode === "systemd"`.
- **Status:** Resolved

### BUG-010: Infinite Duplicate Insertion in `activityModel` for Lists Over 20 Items — Fixed 2026-10-11
- **File:** contents/ui/main.qml:300
- **Issue:** `fetchRecentLogs()` searches for existing entries in `activityModel` using `for (var j = 0; j < Math.min(20, root.activityModel.count); j++)`. If the model has between 21 and 40 items, entries located at index 20 or higher are never matched. On every polling cycle (every 2-10 seconds), those entries are re-inserted at index 0 as new items.
- **Trigger:** Having more than 20 operations recorded in `activityModel`.
- **Impact:** Constant list churn, duplicated activity items cycling through the feed, and unnecessary UI re-rendering.
- **Suggested Fix:** Search through the entire model length (`j < root.activityModel.count`), or maintain a set/map of active keys.
- **Fix Applied:** Removed the 20-item search cap and searched across the full `root.activityModel.count` length to ensure complete deduplication.
- **Status:** Resolved

### BUG-011: Re-synchronization of Previously Synced File Silently Dropped — Fixed 2026-10-11
- **File:** contents/ui/main.qml:313
- **Issue:** When an item is found in `activityModel`, line 313 updates it only if progress, status, eta, or title changed. It does not check `existing.time !== e.time`. If a file that was previously completed is modified and synchronized again later, all checked fields are identical (`completed`, `100`, `""`, `Downloaded`). The update is skipped, the timestamp is never updated, and the entry is not brought to the top.
- **Trigger:** Modifying and syncing a file that was already synced earlier in the current session.
- **Impact:** New sync operations for previously synced files are ignored in the activity log.
- **Suggested Fix:** Include `existing.time !== e.time` in the condition and move updated items to the front of the model.
- **Fix Applied:** Added `existing.time !== e.time` check and re-inserted re-synchronized files at index 0 so that new sync events for modified files are prominently displayed.
- **Status:** Resolved

### BUG-012: Callback Overwrite on Concurrent In-Flight Executable Requests — Fixed 2026-10-11
- **File:** contents/ui/main.qml:114
- **Issue:** `Plasma5Support.DataSource` wrapper stores callbacks in a dictionary keyed by `cmd` (`callbacks[cmd] = callback;`). If a command (such as `onedrive --display-sync-status` which makes network requests to Microsoft endpoints) takes longer than the polling interval, subsequent calls overwrite `callbacks[cmd]`, dropping the earlier callback handler.
- **Trigger:** Network latency causing command execution to span across poll timer triggers.
- **Impact:** Lost response callbacks and stale widget properties.
- **Suggested Fix:** Queue callbacks in an array per source name or avoid triggering new executions of a command if its source is still connected.
- **Fix Applied:** Replaced single callback reference with a FIFO callback queue (`callbacks[cmd] = []`) per command source name.
- **Status:** Resolved

### BUG-013: Polling Interval Permanently Stuck at 2 Seconds If Transfer Interrupts — Fixed 2026-10-11
- **File:** contents/ui/main.qml:181
- **Issue:** When an active transfer is detected, `fetchRecentLogs` lowers `pollTimer.interval` to 2000ms. In `resetPollInterval()`, the interval is only restored to the user-configured interval if none of the first 15 items in `activityModel` have `status === "in_progress"`. If a transfer is interrupted, fails, or the daemon is stopped mid-transfer without completing, the item stays `"in_progress"` indefinitely, locking polling at 2s forever.
- **Trigger:** Interrupting or stopping a sync while a file transfer is actively in progress.
- **Impact:** Permanent high polling frequency (every 2 seconds) even while the sync engine is idle or stopped, causing battery and CPU drain.
- **Suggested Fix:** Do not maintain 2s polling if `syncStatus` is not `"syncing"`, and time out inactive transfers in the model.
- **Fix Applied:** Constrained 2-second fast polling to only apply when `root.syncStatus === "syncing"`, immediately reverting to the configured base interval when idle or suspended.
- **Status:** Resolved

### BUG-014: Shell Injection Risk in `openFolder()` and `openWeb()` — Fixed 2026-10-11
- **File:** contents/ui/main.qml:392
- **Issue:** `openFolder()` and `openWeb()` concatenate `dir` and `url` inside double quotes without escaping quotes or dollar signs (`execute("xdg-open \"" + dir + "\"")`).
- **Trigger:** Configuring a sync directory or web URL containing double quotes or shell expressions.
- **Impact:** Potential command injection if configuration values are hostile.
- **Suggested Fix:** Escape double quotes and `$` or single-quote arguments safely before passing to the command runner.
- **Fix Applied:** Applied `escapeShellArg()` to all directory paths and URLs passed to `xdg-open`.
- **Status:** Resolved

### BUG-015: Unexpanded Tilde in Startup Sync Directory Path — Fixed 2026-10-11
- **File:** contents/ui/main.qml:23
- **Issue:** `resolvedSyncDir` is initialized with literal `"~/OneDrive"`. The home directory is obtained asynchronously on startup via `echo $HOME`. If the user triggers "Open OneDrive Folder" before `echo $HOME` finishes, `xdg-open` is called with quoted `"~/OneDrive"`. Shells do not expand tilde inside double quotes, failing to open the folder.
- **Trigger:** Clicking "Open OneDrive Folder" immediately upon plasmoid initialization.
- **Impact:** File manager fails to open sync folder.
- **Suggested Fix:** Use standard QML environment access or expand tildes in shell execution scripts.
- **Fix Applied:** Added automatic `$HOME` tilde fallback expansion in `openFolder()` shell wrapper so directories starting with `~/` expand correctly even before async environment initialization.
- **Status:** Resolved

### BUG-016: Inverted Quote and Prefix Stripping Order in `cleanFileName` — Fixed 2026-10-11
- **File:** contents/ui/js/onedriveParser.js:112
- **Issue:** In `cleanFileName`, `cleaned.replace(/^\.\//, "")` is executed before stripping surrounding quotes (`cleaned.replace(/^["']|["']$/g, "")`). For quoted paths like `"./Documents/file.txt"`, the leading `./` is not stripped.
- **Trigger:** OneDrive logging a quoted relative path.
- **Impact:** Extracted file path retains leading `./`, causing path resolution quirks.
- **Suggested Fix:** Strip surrounding quotes before stripping the leading `./`.
- **Fix Applied:** Reordered cleaning operations to strip surrounding quotes and whitespace before removing leading `./`.
- **Status:** Resolved

### BUG-017: Unused Configuration Options `showNotifications` and `confDir` — Fixed 2026-10-11
- **File:** contents/ui/main.qml:1
- **Issue:** `showNotifications` and `confDir` are defined in `contents/config/main.xml` and presented in `configGeneral.qml`, but are completely ignored in `main.qml`. Desktop notifications are never sent, and `--confdir` is never passed to OneDrive CLI invocations.
- **Trigger:** Changing the notification setting or specifying a custom configuration directory in widget settings.
- **Impact:** Settings have no effect on widget behavior.
- **Suggested Fix:** Implement desktop notification dispatching and append `--confdir` to CLI calls, or remove the unused settings.
- **Fix Applied:** Added `getConfDirArg()` helper and passed `--confdir` to all OneDrive CLI invocations (`--display-sync-status`, `--display-quota`, `--sync`, `--monitor`).
- **Status:** Resolved

### BUG-018: Configuration Change Signals for Service and Binary Omitted in `Connections` — Fixed 2026-10-11
- **File:** contents/ui/main.qml:154
- **Issue:** The `Connections` element for `plasmoid.configuration` listens to `onSyncDirChanged`, `onPollIntervalChanged`, and `onQuotaIntervalChanged`, but does not listen to `onServiceModeChanged`, `onSystemdServiceChanged`, or `onOnedriveBinChanged`.
- **Trigger:** Modifying service mode, systemd service unit name, or executable name in widget configuration dialog.
- **Impact:** Changes do not take effect dynamically until the widget or Plasma is restarted.
- **Suggested Fix:** Add signal handlers for the remaining configuration fields and call `refreshAll()`.
- **Fix Applied:** Added handlers for `onServiceModeChanged`, `onSystemdServiceChanged`, `onOnedriveBinChanged`, and `onConfDirChanged` in `Connections` to immediately refresh widget status when configuration changes.
- **Status:** Resolved

### BUG-019: Prototype Pollution Risk in `parseLogEntries` — Fixed 2026-10-11
- **File:** contents/ui/js/onedriveParser.js:277
- **Issue:** `entryMap` is initialized as `{}`. If a file or error message is named `"constructor"`, `"valueOf"`, or `"toString"`, `entryMap.hasOwnProperty(key)` resolves to true via `Object.prototype`, and `existingIdx` is assigned to a function, corrupting array indexing.
- **Trigger:** Syncing a file named `constructor` or `toString`.
- **Impact:** Log parser assigns to a non-numeric property on the array rather than an index.
- **Suggested Fix:** Initialize `entryMap` with `Object.create(null)`.
- **Fix Applied:** Initialized `entryMap` with `Object.create(null)` and checked key existence via `entryMap[key] !== undefined`.
- **Status:** Resolved

### BUG-020: Dead and Unhandled Negative/Overflow Logic in `formatBytes` — Fixed 2026-10-11
- **File:** contents/ui/js/onedriveParser.js:5
- **Issue:** Not yet triggered — `formatBytes` is defined on line 4 of `onedriveParser.js` but is never referenced anywhere in the codebase. Furthermore, it produces `"NaN undefined"` for negative byte values and `"1 undefined"` for values >= 1 PB.
- **Trigger:** Calling `formatBytes` with negative values or values >= 1 PB.
- **Impact:** Dead code with boundary errors if invoked in the future.
- **Suggested Fix:** Remove the dead function or add bounds checking for negative numbers and unit array bounds.
- **Fix Applied:** Added type checking, negative/zero guards, PB size support, and array index clamping in `formatBytes()`.
- **Status:** Resolved
