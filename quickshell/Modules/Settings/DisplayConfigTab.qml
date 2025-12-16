import QtCore
import QtQuick
import qs.Common
import qs.Modals
import qs.Services
import qs.Widgets

Item {
    id: root

    readonly property bool hasOutputBackend: WlrOutputService.wlrOutputAvailable
    readonly property var wlrOutputs: WlrOutputService.outputs
    property var outputs: ({})
    property var savedOutputs: ({})
    property var allOutputs: buildAllOutputsMap()

    property var includeStatus: ({
            "exists": false,
            "included": false
        })
    property bool checkingInclude: false
    property bool fixingInclude: false

    function buildAllOutputsMap() {
        const result = {};
        for (const name in savedOutputs) {
            result[name] = Object.assign({}, savedOutputs[name], {
                "connected": false
            });
        }
        for (const name in outputs) {
            result[name] = Object.assign({}, outputs[name], {
                "connected": true
            });
        }
        return result;
    }

    onOutputsChanged: allOutputs = buildAllOutputsMap()
    onSavedOutputsChanged: allOutputs = buildAllOutputsMap()

    Connections {
        target: WlrOutputService
        function onStateChanged() {
            root.outputs = buildOutputsMap();
            reloadSavedOutputs();
        }
    }

    Component.onCompleted: {
        outputs = buildOutputsMap();
        reloadSavedOutputs();
        checkIncludeStatus();
    }

    function reloadSavedOutputs() {
        const paths = getConfigPaths();
        if (!paths) {
            savedOutputs = {};
            return;
        }

        Proc.runCommand("load-saved-outputs", ["cat", paths.outputsFile], (content, exitCode) => {
            if (exitCode !== 0 || !content.trim()) {
                savedOutputs = {};
                return;
            }
            const parsed = parseOutputsConfig(content);
            const filtered = filterDisconnectedOnly(parsed);
            savedOutputs = filtered;
        });
    }

    function filterDisconnectedOnly(parsedOutputs) {
        const result = {};
        const liveNames = Object.keys(outputs);
        const liveByIdentifier = {};
        for (const name of liveNames) {
            const o = outputs[name];
            if (o?.make && o?.model) {
                const serial = o.serial || "Unknown";
                const id = (o.make + " " + o.model + " " + serial).trim();
                liveByIdentifier[id] = true;
                liveByIdentifier[o.make + " " + o.model] = true;
            }
            liveByIdentifier[name] = true;
        }

        for (const savedName in parsedOutputs) {
            const trimmed = savedName.trim();
            if (!liveByIdentifier[trimmed]) {
                result[savedName] = parsedOutputs[savedName];
            }
        }
        return result;
    }

    function parseOutputsConfig(content) {
        switch (CompositorService.compositor) {
        case "niri":
            return parseNiriOutputs(content);
        case "hyprland":
            return parseHyprlandOutputs(content);
        case "dwl":
            return parseMangoOutputs(content);
        default:
            return {};
        }
    }

    function parseNiriOutputs(content) {
        const result = {};
        const outputRegex = /output\s+"([^"]+)"\s*\{([^}]*)\}/g;
        let match;
        while ((match = outputRegex.exec(content)) !== null) {
            const name = match[1];
            const body = match[2];

            const modeMatch = body.match(/mode\s+"(\d+)x(\d+)@([\d.]+)"/);
            const posMatch = body.match(/position\s+x=(-?\d+)\s+y=(-?\d+)/);
            const scaleMatch = body.match(/scale\s+([\d.]+)/);
            const transformMatch = body.match(/transform\s+"([^"]+)"/);
            const vrrMatch = body.match(/variable-refresh-rate(?:\s+on)?/);

            result[name] = {
                "name": name,
                "logical": {
                    "x": posMatch ? parseInt(posMatch[1]) : 0,
                    "y": posMatch ? parseInt(posMatch[2]) : 0,
                    "scale": scaleMatch ? parseFloat(scaleMatch[1]) : 1.0,
                    "transform": transformMatch ? transformMatch[1] : "Normal"
                },
                "modes": modeMatch ? [
                    {
                        "width": parseInt(modeMatch[1]),
                        "height": parseInt(modeMatch[2]),
                        "refresh_rate": Math.round(parseFloat(modeMatch[3]) * 1000)
                    }
                ] : [],
                "current_mode": 0,
                "vrr_enabled": !!vrrMatch,
                "vrr_supported": true
            };
        }
        return result;
    }

    function parseHyprlandOutputs(content) {
        const result = {};
        const lines = content.split("\n");
        for (const line of lines) {
            const match = line.match(/^\s*monitor\s*=\s*([^,]+),\s*(\d+)x(\d+)@([\d.]+),\s*(-?\d+)x(-?\d+),\s*([\d.]+)(?:,\s*transform,\s*(\d+))?(?:,\s*vrr,\s*(\d+))?/);
            if (!match)
                continue;
            const name = match[1].trim();
            result[name] = {
                "name": name,
                "logical": {
                    "x": parseInt(match[5]),
                    "y": parseInt(match[6]),
                    "scale": parseFloat(match[7]),
                    "transform": hyprlandToTransform(parseInt(match[8] || "0"))
                },
                "modes": [
                    {
                        "width": parseInt(match[2]),
                        "height": parseInt(match[3]),
                        "refresh_rate": Math.round(parseFloat(match[4]) * 1000)
                    }
                ],
                "current_mode": 0,
                "vrr_enabled": match[9] === "1",
                "vrr_supported": true
            };
        }
        return result;
    }

    function hyprlandToTransform(value) {
        switch (value) {
        case 0:
            return "Normal";
        case 1:
            return "90";
        case 2:
            return "180";
        case 3:
            return "270";
        case 4:
            return "Flipped";
        case 5:
            return "Flipped90";
        case 6:
            return "Flipped180";
        case 7:
            return "Flipped270";
        default:
            return "Normal";
        }
    }

    function parseMangoOutputs(content) {
        const result = {};
        const lines = content.split("\n");
        for (const line of lines) {
            const match = line.match(/^\s*monitorrule=([^,]+),([^,]+),([^,]+),([^,]+),(\d+),([\d.]+),(-?\d+),(-?\d+),(\d+),(\d+),(\d+)/);
            if (!match)
                continue;
            const name = match[1].trim();
            result[name] = {
                "name": name,
                "logical": {
                    "x": parseInt(match[7]),
                    "y": parseInt(match[8]),
                    "scale": parseFloat(match[6]),
                    "transform": mangoToTransform(parseInt(match[5]))
                },
                "modes": [
                    {
                        "width": parseInt(match[9]),
                        "height": parseInt(match[10]),
                        "refresh_rate": parseInt(match[11]) * 1000
                    }
                ],
                "current_mode": 0,
                "vrr_enabled": false,
                "vrr_supported": false
            };
        }
        return result;
    }

    function mangoToTransform(value) {
        switch (value) {
        case 0:
            return "Normal";
        case 1:
            return "90";
        case 2:
            return "180";
        case 3:
            return "270";
        case 4:
            return "Flipped";
        case 5:
            return "Flipped90";
        case 6:
            return "Flipped180";
        case 7:
            return "Flipped270";
        default:
            return "Normal";
        }
    }

    function getConfigPaths() {
        const configDir = Paths.strip(StandardPaths.writableLocation(StandardPaths.ConfigLocation));
        switch (CompositorService.compositor) {
        case "niri":
            return {
                "configFile": configDir + "/niri/config.kdl",
                "outputsFile": configDir + "/niri/dms/outputs.kdl",
                "grepPattern": 'include.*"dms/outputs.kdl"',
                "includeLine": 'include "dms/outputs.kdl"'
            };
        case "hyprland":
            return {
                "configFile": configDir + "/hypr/hyprland.conf",
                "outputsFile": configDir + "/hypr/dms/outputs.conf",
                "grepPattern": 'source.*dms/outputs.conf',
                "includeLine": "source = ./dms/outputs.conf"
            };
        case "dwl":
            return {
                "configFile": configDir + "/mango/config.conf",
                "outputsFile": configDir + "/mango/dms/outputs.conf",
                "grepPattern": 'source.*dms/outputs.conf',
                "includeLine": "source=./dms/outputs.conf"
            };
        default:
            return null;
        }
    }

    function checkIncludeStatus() {
        const paths = getConfigPaths();
        if (!paths) {
            includeStatus = {
                "exists": false,
                "included": false
            };
            return;
        }

        checkingInclude = true;
        Proc.runCommand("check-outputs-include", ["sh", "-c", `exists=false; included=false; ` + `[ -f "${paths.outputsFile}" ] && exists=true; ` + `[ -f "${paths.configFile}" ] && grep -v '^[[:space:]]*\\(//\\|#\\)' "${paths.configFile}" | grep -q '${paths.grepPattern}' && included=true; ` + `echo "$exists $included"`], (output, exitCode) => {
            checkingInclude = false;
            const parts = output.trim().split(" ");
            includeStatus = {
                "exists": parts[0] === "true",
                "included": parts[1] === "true"
            };
        });
    }

    function fixOutputsInclude() {
        const paths = getConfigPaths();
        if (!paths)
            return;
        fixingInclude = true;
        const outputsDir = paths.outputsFile.substring(0, paths.outputsFile.lastIndexOf("/"));
        const unixTime = Math.floor(Date.now() / 1000);
        const backupFile = paths.configFile + ".backup" + unixTime;

        Proc.runCommand("fix-outputs-include", ["sh", "-c", `cp "${paths.configFile}" "${backupFile}" 2>/dev/null; ` + `mkdir -p "${outputsDir}" && ` + `touch "${paths.outputsFile}" && ` + `if ! grep -v '^[[:space:]]*\\(//\\|#\\)' "${paths.configFile}" 2>/dev/null | grep -q '${paths.grepPattern}'; then ` + `echo '' >> "${paths.configFile}" && ` + `echo '${paths.includeLine}' >> "${paths.configFile}"; fi`], (output, exitCode) => {
            fixingInclude = false;
            if (exitCode !== 0)
                return;
            checkIncludeStatus();
            WlrOutputService.requestState();
        });
    }

    function buildOutputsMap() {
        const map = {};
        for (const output of wlrOutputs) {
            const normalizedModes = (output.modes || []).map(m => ({
                        "id": m.id,
                        "width": m.width,
                        "height": m.height,
                        "refresh_rate": m.refresh,
                        "preferred": m.preferred ?? false
                    }));
            map[output.name] = {
                "name": output.name,
                "make": output.make || "",
                "model": output.model || "",
                "serial": output.serialNumber || "",
                "modes": normalizedModes,
                "current_mode": normalizedModes.findIndex(m => m.id === output.currentMode?.id),
                "vrr_supported": output.adaptiveSync !== undefined,
                "vrr_enabled": output.adaptiveSync === 1,
                "logical": {
                    "x": output.x ?? 0,
                    "y": output.y ?? 0,
                    "width": output.currentMode?.width ?? 1920,
                    "height": output.currentMode?.height ?? 1080,
                    "scale": output.scale ?? 1.0,
                    "transform": mapWlrTransform(output.transform)
                }
            };
        }
        return map;
    }

    function mapWlrTransform(wlrTransform) {
        switch (wlrTransform) {
        case 0:
            return "Normal";
        case 1:
            return "90";
        case 2:
            return "180";
        case 3:
            return "270";
        case 4:
            return "Flipped";
        case 5:
            return "Flipped90";
        case 6:
            return "Flipped180";
        case 7:
            return "Flipped270";
        default:
            return "Normal";
        }
    }

    function mapTransformToWlr(transform) {
        switch (transform) {
        case "Normal":
            return 0;
        case "90":
            return 1;
        case "180":
            return 2;
        case "270":
            return 3;
        case "Flipped":
            return 4;
        case "Flipped90":
            return 5;
        case "Flipped180":
            return 6;
        case "Flipped270":
            return 7;
        default:
            return 0;
        }
    }

    function backendFetchOutputs() {
        WlrOutputService.requestState();
    }

    function backendWriteOutputsConfig(outputsData) {
        switch (CompositorService.compositor) {
        case "niri":
            NiriService.generateOutputsConfig(outputsData);
            break;
        case "hyprland":
            HyprlandService.generateOutputsConfig(outputsData);
            break;
        case "dwl":
            DwlService.generateOutputsConfig(outputsData);
            break;
        }
    }

    function normalizeOutputPositions(outputsData) {
        const names = Object.keys(outputsData);
        if (names.length === 0)
            return outputsData;

        let minX = Infinity;
        let minY = Infinity;

        for (const name of names) {
            const output = outputsData[name];
            if (!output.logical)
                continue;
            minX = Math.min(minX, output.logical.x);
            minY = Math.min(minY, output.logical.y);
        }

        if (minX === Infinity || (minX === 0 && minY === 0))
            return outputsData;

        const normalized = JSON.parse(JSON.stringify(outputsData));
        for (const name of names) {
            if (!normalized[name].logical)
                continue;
            normalized[name].logical.x -= minX;
            normalized[name].logical.y -= minY;
        }

        return normalized;
    }

    function buildOutputsWithPendingChanges() {
        const result = {};

        for (const outputName in savedOutputs) {
            if (!outputs[outputName])
                result[outputName] = JSON.parse(JSON.stringify(savedOutputs[outputName]));
        }

        for (const outputName in outputs) {
            result[outputName] = JSON.parse(JSON.stringify(outputs[outputName]));
        }

        for (const outputName in pendingChanges) {
            if (!result[outputName])
                continue;
            const changes = pendingChanges[outputName];
            if (changes.position && result[outputName].logical) {
                result[outputName].logical.x = changes.position.x;
                result[outputName].logical.y = changes.position.y;
            }
            if (changes.mode !== undefined && result[outputName].modes) {
                for (var i = 0; i < result[outputName].modes.length; i++) {
                    if (formatMode(result[outputName].modes[i]) === changes.mode) {
                        result[outputName].current_mode = i;
                        break;
                    }
                }
            }
            if (changes.scale !== undefined && result[outputName].logical)
                result[outputName].logical.scale = changes.scale;
            if (changes.transform !== undefined && result[outputName].logical)
                result[outputName].logical.transform = changes.transform;
            if (changes.vrr !== undefined)
                result[outputName].vrr_enabled = changes.vrr;
        }
        return normalizeOutputPositions(result);
    }

    function backendUpdateOutputPosition(outputName, x, y) {
        if (!outputs || !outputs[outputName])
            return;
        const updatedOutputs = {};
        for (const name in outputs) {
            const output = outputs[name];
            if (name === outputName && output.logical) {
                updatedOutputs[name] = JSON.parse(JSON.stringify(output));
                updatedOutputs[name].logical.x = x;
                updatedOutputs[name].logical.y = y;
            } else {
                updatedOutputs[name] = output;
            }
        }
        outputs = updatedOutputs;
    }

    function backendUpdateOutputScale(outputName, scale) {
        if (!outputs || !outputs[outputName])
            return;
        const updatedOutputs = {};
        for (const name in outputs) {
            const output = outputs[name];
            if (name === outputName && output.logical) {
                updatedOutputs[name] = JSON.parse(JSON.stringify(output));
                updatedOutputs[name].logical.scale = scale;
            } else {
                updatedOutputs[name] = output;
            }
        }
        outputs = updatedOutputs;
    }

    property var pendingChanges: ({})
    property var pendingNiriChanges: ({})
    property var originalNiriSettings: null
    property var originalOutputs: null
    property string originalDisplayNameMode: ""
    property bool formatChanged: originalDisplayNameMode !== "" && originalDisplayNameMode !== SettingsData.displayNameMode
    property bool hasPendingChanges: Object.keys(pendingChanges).length > 0 || Object.keys(pendingNiriChanges).length > 0 || formatChanged

    function getOutputDisplayName(output, outputName) {
        if (SettingsData.displayNameMode === "model" && output?.make && output?.model) {
            if (CompositorService.isNiri) {
                const serial = output.serial || "Unknown";
                return output.make + " " + output.model + " " + serial;
            }
            return output.make + " " + output.model;
        }
        return outputName;
    }

    function getNiriOutputIdentifier(output, outputName) {
        if (SettingsData.displayNameMode === "model" && output?.make && output?.model) {
            const serial = output.serial || "Unknown";
            return output.make + " " + output.model + " " + serial;
        }
        return outputName;
    }

    function getNiriSetting(output, outputName, key, defaultValue) {
        if (!CompositorService.isNiri)
            return defaultValue;
        const identifier = getNiriOutputIdentifier(output, outputName);
        const pending = pendingNiriChanges[identifier];
        if (pending && pending[key] !== undefined)
            return pending[key];
        return SettingsData.getNiriOutputSetting(identifier, key, defaultValue);
    }

    function setNiriSetting(output, outputName, key, value) {
        if (!CompositorService.isNiri)
            return;
        initOriginalNiriSettings();
        const identifier = getNiriOutputIdentifier(output, outputName);
        const newPending = JSON.parse(JSON.stringify(pendingNiriChanges));
        if (!newPending[identifier])
            newPending[identifier] = {};
        newPending[identifier][key] = value;
        pendingNiriChanges = newPending;
    }

    function initOriginalNiriSettings() {
        if (originalNiriSettings)
            return;
        originalNiriSettings = JSON.parse(JSON.stringify(SettingsData.niriOutputSettings));
    }

    function initOriginalOutputs() {
        if (!originalOutputs)
            originalOutputs = JSON.parse(JSON.stringify(outputs));
    }

    function setPendingChange(outputName, key, value) {
        initOriginalOutputs();
        const newPending = JSON.parse(JSON.stringify(pendingChanges));
        if (!newPending[outputName])
            newPending[outputName] = {};
        newPending[outputName][key] = value;
        pendingChanges = newPending;

        if (key === "scale") {
            recalculateAdjacentPositions(outputName, value);
            backendUpdateOutputScale(outputName, value);
        }
    }

    function recalculateAdjacentPositions(changedOutput, newScale) {
        const output = outputs[changedOutput];
        if (!output?.logical)
            return;
        const oldPhys = getPhysicalSize(output);
        const oldLogicalW = Math.round(oldPhys.w / (output.logical.scale || 1.0));
        const newLogicalW = Math.round(oldPhys.w / newScale);

        const changedX = getPendingValue(changedOutput, "position")?.x ?? output.logical.x;
        const changedY = getPendingValue(changedOutput, "position")?.y ?? output.logical.y;

        for (const name in outputs) {
            if (name === changedOutput)
                continue;
            const other = outputs[name];
            if (!other?.logical)
                continue;
            const otherX = getPendingValue(name, "position")?.x ?? other.logical.x;
            const otherY = getPendingValue(name, "position")?.y ?? other.logical.y;
            const otherSize = getLogicalSize(other);
            const otherRight = otherX + otherSize.w;

            if (Math.abs(changedX - otherRight) < 5) {
                const newX = otherRight;
                const newPending = JSON.parse(JSON.stringify(pendingChanges));
                if (!newPending[changedOutput])
                    newPending[changedOutput] = {};
                newPending[changedOutput].position = {
                    "x": newX,
                    "y": changedY
                };
                pendingChanges = newPending;
                backendUpdateOutputPosition(changedOutput, newX, changedY);
                return;
            }

            const changedRight = changedX + oldLogicalW;
            if (Math.abs(otherX - changedRight) < 5) {
                const newOtherX = changedX + newLogicalW;
                const newPending = JSON.parse(JSON.stringify(pendingChanges));
                if (!newPending[name])
                    newPending[name] = {};
                newPending[name].position = {
                    "x": newOtherX,
                    "y": otherY
                };
                pendingChanges = newPending;
                backendUpdateOutputPosition(name, newOtherX, otherY);
            }
        }
    }

    function getPendingValue(outputName, key) {
        if (!pendingChanges[outputName])
            return undefined;
        return pendingChanges[outputName][key];
    }

    function getEffectiveValue(outputName, key, originalValue) {
        const pending = getPendingValue(outputName, key);
        return pending !== undefined ? pending : originalValue;
    }

    function clearPendingChanges() {
        pendingChanges = {};
        pendingNiriChanges = {};
        originalOutputs = null;
        originalNiriSettings = null;
        originalDisplayNameMode = "";
    }

    function discardChanges() {
        if (originalDisplayNameMode !== "") {
            SettingsData.displayNameMode = originalDisplayNameMode;
            SettingsData.saveSettings();
        }
        backendFetchOutputs();
        clearPendingChanges();
    }

    property bool validatingConfig: false
    property string validationError: ""

    function applyChanges() {
        if (!hasPendingChanges)
            return;
        const changeDescriptions = [];

        if (formatChanged) {
            const formatLabel = SettingsData.displayNameMode === "model" ? I18n.tr("Model") : I18n.tr("Name");
            changeDescriptions.push(I18n.tr("Config Format") + " → " + formatLabel);
        }

        for (const outputName in pendingChanges) {
            const changes = pendingChanges[outputName];
            if (changes.position)
                changeDescriptions.push(outputName + ": " + I18n.tr("Position") + " → " + changes.position.x + ", " + changes.position.y);
            if (changes.mode)
                changeDescriptions.push(outputName + ": " + I18n.tr("Mode") + " → " + changes.mode);
            if (changes.scale !== undefined)
                changeDescriptions.push(outputName + ": " + I18n.tr("Scale") + " → " + changes.scale);
            if (changes.transform)
                changeDescriptions.push(outputName + ": " + I18n.tr("Transform") + " → " + getTransformLabel(changes.transform));
            if (changes.vrr !== undefined)
                changeDescriptions.push(outputName + ": " + I18n.tr("VRR") + " → " + (changes.vrr ? I18n.tr("Enabled") : I18n.tr("Disabled")));
        }

        for (const outputId in pendingNiriChanges) {
            const changes = pendingNiriChanges[outputId];
            if (changes.disabled !== undefined)
                changeDescriptions.push(outputId + ": " + I18n.tr("Disabled") + " → " + (changes.disabled ? I18n.tr("Yes") : I18n.tr("No")));
            if (changes.vrrOnDemand !== undefined)
                changeDescriptions.push(outputId + ": " + I18n.tr("VRR On-Demand") + " → " + (changes.vrrOnDemand ? I18n.tr("Enabled") : I18n.tr("Disabled")));
            if (changes.focusAtStartup !== undefined)
                changeDescriptions.push(outputId + ": " + I18n.tr("Focus at Startup") + " → " + (changes.focusAtStartup ? I18n.tr("Yes") : I18n.tr("No")));
            if (changes.hotCorners !== undefined)
                changeDescriptions.push(outputId + ": " + I18n.tr("Hot Corners") + " → " + I18n.tr("Modified"));
            if (changes.layout !== undefined)
                changeDescriptions.push(outputId + ": " + I18n.tr("Layout") + " → " + I18n.tr("Modified"));
        }

        if (CompositorService.isNiri) {
            validateAndApplyNiriConfig(changeDescriptions);
            return;
        }

        confirmationModal.changes = changeDescriptions;
        confirmationModal.open();

        if (formatChanged)
            SettingsData.saveSettings();

        const mergedOutputs = buildOutputsWithPendingChanges();
        backendWriteOutputsConfig(mergedOutputs);
    }

    function validateAndApplyNiriConfig(changeDescriptions) {
        validatingConfig = true;
        validationError = "";

        const mergedOutputs = buildOutputsWithPendingChanges();
        const mergedNiriSettings = buildMergedNiriSettings();
        const configContent = generateNiriOutputsKdl(mergedOutputs, mergedNiriSettings);

        const configDir = Paths.strip(StandardPaths.writableLocation(StandardPaths.ConfigLocation));
        const tempFile = configDir + "/niri/dms/.outputs-validate-tmp.kdl";

        Proc.runCommand("niri-validate-write-tmp", ["sh", "-c", `mkdir -p "$(dirname "${tempFile}")" && cat > "${tempFile}" << 'EOF'\n${configContent}EOF`], (output, writeExitCode) => {
            if (writeExitCode !== 0) {
                validatingConfig = false;
                validationError = I18n.tr("Failed to write temp file for validation");
                ToastService.showError(I18n.tr("Config validation failed"), validationError, "", "display-config");
                return;
            }
            Proc.runCommand("niri-validate-config", ["niri", "validate", "-c", tempFile], (validateOutput, validateExitCode) => {
                validatingConfig = false;
                Proc.runCommand("niri-validate-cleanup", ["rm", "-f", tempFile], () => {});
                if (validateExitCode !== 0) {
                    validationError = validateOutput.trim() || I18n.tr("Invalid configuration");
                    ToastService.showError(I18n.tr("Config validation failed"), validationError, "", "display-config");
                    return;
                }
                confirmationModal.changes = changeDescriptions;
                confirmationModal.open();
                if (formatChanged)
                    SettingsData.saveSettings();
                commitNiriSettingsChanges();
                backendWriteOutputsConfig(mergedOutputs);
            });
        });
    }

    function buildMergedNiriSettings() {
        const merged = JSON.parse(JSON.stringify(SettingsData.niriOutputSettings));
        for (const outputId in pendingNiriChanges) {
            if (!merged[outputId])
                merged[outputId] = {};
            for (const key in pendingNiriChanges[outputId]) {
                merged[outputId][key] = pendingNiriChanges[outputId][key];
            }
        }
        return merged;
    }

    function commitNiriSettingsChanges() {
        for (const outputId in pendingNiriChanges) {
            for (const key in pendingNiriChanges[outputId]) {
                SettingsData.setNiriOutputSetting(outputId, key, pendingNiriChanges[outputId][key]);
            }
        }
    }

    function generateNiriOutputsKdl(outputsData, niriSettings) {
        let kdlContent = `// Auto-generated by DMS - do not edit manually\n\n`;
        for (const outputName in outputsData) {
            const output = outputsData[outputName];
            const identifier = getNiriOutputIdentifier(output, outputName);
            const settings = niriSettings[identifier] || {};
            kdlContent += `output "${identifier}" {\n`;
            if (settings.disabled) {
                kdlContent += `    off\n}\n\n`;
                continue;
            }
            if (output.current_mode !== undefined && output.modes && output.modes[output.current_mode]) {
                const mode = output.modes[output.current_mode];
                kdlContent += `    mode "${mode.width}x${mode.height}@${(mode.refresh_rate / 1000).toFixed(3)}"\n`;
            }
            if (output.logical) {
                if (output.logical.scale && output.logical.scale !== 1.0)
                    kdlContent += `    scale ${output.logical.scale}\n`;
                if (output.logical.transform && output.logical.transform !== "Normal") {
                    const transformMap = {
                        "Normal": "normal",
                        "90": "90",
                        "180": "180",
                        "270": "270",
                        "Flipped": "flipped",
                        "Flipped90": "flipped-90",
                        "Flipped180": "flipped-180",
                        "Flipped270": "flipped-270"
                    };
                    kdlContent += `    transform "${transformMap[output.logical.transform] || "normal"}"\n`;
                }
                if (output.logical.x !== undefined && output.logical.y !== undefined)
                    kdlContent += `    position x=${output.logical.x} y=${output.logical.y}\n`;
            }
            if (output.vrr_enabled) {
                const vrrOnDemand = settings.vrrOnDemand ?? false;
                kdlContent += vrrOnDemand ? `    variable-refresh-rate on-demand=true\n` : `    variable-refresh-rate\n`;
            }
            if (settings.focusAtStartup)
                kdlContent += `    focus-at-startup\n`;
            if (settings.backdropColor)
                kdlContent += `    backdrop-color "${settings.backdropColor}"\n`;
            kdlContent += generateHotCornersBlockLocal(settings);
            kdlContent += generateLayoutBlockLocal(settings);
            kdlContent += `}\n\n`;
        }
        return kdlContent;
    }

    function generateHotCornersBlockLocal(settings) {
        if (!settings.hotCorners)
            return "";
        const hc = settings.hotCorners;
        if (hc.off)
            return `    hot-corners {\n        off\n    }\n`;
        const corners = hc.corners || [];
        if (corners.length === 0)
            return "";
        let block = `    hot-corners {\n`;
        for (const corner of corners)
            block += `        ${corner}\n`;
        block += `    }\n`;
        return block;
    }

    function generateLayoutBlockLocal(settings) {
        if (!settings.layout)
            return "";
        const layout = settings.layout;
        const hasSettings = layout.gaps !== undefined || layout.defaultColumnWidth || layout.presetColumnWidths || layout.alwaysCenterSingleColumn !== undefined;
        if (!hasSettings)
            return "";
        let block = `    layout {\n`;
        if (layout.gaps !== undefined)
            block += `        gaps ${layout.gaps}\n`;
        if (layout.defaultColumnWidth?.type === "proportion")
            block += `        default-column-width { proportion ${layout.defaultColumnWidth.value}; }\n`;
        if (layout.presetColumnWidths && layout.presetColumnWidths.length > 0) {
            block += `        preset-column-widths {\n`;
            for (const preset of layout.presetColumnWidths) {
                if (preset.type === "proportion")
                    block += `            proportion ${preset.value}\n`;
            }
            block += `        }\n`;
        }
        if (layout.alwaysCenterSingleColumn !== undefined)
            block += layout.alwaysCenterSingleColumn ? `        always-center-single-column\n` : `        always-center-single-column false\n`;
        block += `    }\n`;
        return block;
    }

    function confirmChanges() {
        clearPendingChanges();
    }

    function revertChanges() {
        const hadFormatChange = originalDisplayNameMode !== "";
        const hadNiriChanges = originalNiriSettings !== null;

        if (hadFormatChange) {
            SettingsData.displayNameMode = originalDisplayNameMode;
            SettingsData.saveSettings();
        }

        if (hadNiriChanges) {
            SettingsData.niriOutputSettings = JSON.parse(JSON.stringify(originalNiriSettings));
            SettingsData.saveSettings();
        }

        if (!originalOutputs && !hadNiriChanges) {
            if (hadFormatChange)
                backendWriteOutputsConfig(buildOutputsWithPendingChanges());
            clearPendingChanges();
            return;
        }

        const original = originalOutputs ? JSON.parse(JSON.stringify(originalOutputs)) : buildOutputsWithPendingChanges();
        backendWriteOutputsConfig(original);
        clearPendingChanges();
        if (originalOutputs)
            outputs = original;
    }

    function getOutputBounds() {
        if (!allOutputs || Object.keys(allOutputs).length === 0)
            return {
                "minX": 0,
                "minY": 0,
                "maxX": 1920,
                "maxY": 1080,
                "width": 1920,
                "height": 1080
            };

        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;

        for (const name in allOutputs) {
            const output = allOutputs[name];
            if (!output.logical)
                continue;
            const x = output.logical.x;
            const y = output.logical.y;
            const size = getLogicalSize(output);
            minX = Math.min(minX, x);
            minY = Math.min(minY, y);
            maxX = Math.max(maxX, x + size.w);
            maxY = Math.max(maxY, y + size.h);
        }

        if (minX === Infinity)
            return {
                "minX": 0,
                "minY": 0,
                "maxX": 1920,
                "maxY": 1080,
                "width": 1920,
                "height": 1080
            };
        return {
            "minX": minX,
            "minY": minY,
            "maxX": maxX,
            "maxY": maxY,
            "width": maxX - minX,
            "height": maxY - minY
        };
    }

    function isRotated(transform) {
        switch (transform) {
        case "90":
        case "270":
        case "Flipped90":
        case "Flipped270":
            return true;
        default:
            return false;
        }
    }

    function getPhysicalSize(output) {
        if (!output)
            return {
                "w": 1920,
                "h": 1080
            };

        let w = 1920, h = 1080;
        if (output.modes && output.current_mode !== undefined) {
            const mode = output.modes[output.current_mode];
            if (mode) {
                w = mode.width || 1920;
                h = mode.height || 1080;
            }
        } else if (output.logical) {
            const scale = output.logical.scale || 1.0;
            w = Math.round((output.logical.width || 1920) * scale);
            h = Math.round((output.logical.height || 1080) * scale);
        }

        if (output.logical && isRotated(output.logical.transform))
            return {
                "w": h,
                "h": w
            };
        return {
            "w": w,
            "h": h
        };
    }

    function getLogicalSize(output) {
        if (!output)
            return {
                "w": 1920,
                "h": 1080
            };

        const phys = getPhysicalSize(output);
        const scale = output.logical?.scale || 1.0;

        return {
            "w": Math.round(phys.w / scale),
            "h": Math.round(phys.h / scale)
        };
    }

    function checkOverlap(testName, testX, testY, testW, testH) {
        for (const name in outputs) {
            if (name === testName)
                continue;
            const output = outputs[name];
            if (!output.logical)
                continue;
            const x = output.logical.x;
            const y = output.logical.y;
            const size = getLogicalSize(output);
            if (!(testX + testW <= x || testX >= x + size.w || testY + testH <= y || testY >= y + size.h))
                return true;
        }
        return false;
    }

    function snapToEdges(testName, posX, posY, testW, testH) {
        const snapThreshold = 200;
        let snappedX = posX;
        let snappedY = posY;
        let bestXDist = snapThreshold;
        let bestYDist = snapThreshold;

        for (const name in outputs) {
            if (name === testName)
                continue;
            const output = outputs[name];
            if (!output.logical)
                continue;
            const x = output.logical.x;
            const y = output.logical.y;
            const size = getLogicalSize(output);

            const rightEdge = x + size.w;
            const bottomEdge = y + size.h;
            const testRight = posX + testW;
            const testBottom = posY + testH;

            const xSnaps = [
                {
                    "val": rightEdge,
                    "dist": Math.abs(posX - rightEdge)
                },
                {
                    "val": x - testW,
                    "dist": Math.abs(testRight - x)
                },
                {
                    "val": x,
                    "dist": Math.abs(posX - x)
                },
                {
                    "val": rightEdge - testW,
                    "dist": Math.abs(testRight - rightEdge)
                }
            ];

            const ySnaps = [
                {
                    "val": bottomEdge,
                    "dist": Math.abs(posY - bottomEdge)
                },
                {
                    "val": y - testH,
                    "dist": Math.abs(testBottom - y)
                },
                {
                    "val": y,
                    "dist": Math.abs(posY - y)
                },
                {
                    "val": bottomEdge - testH,
                    "dist": Math.abs(testBottom - bottomEdge)
                }
            ];

            for (const snap of xSnaps) {
                if (snap.dist < bestXDist) {
                    bestXDist = snap.dist;
                    snappedX = snap.val;
                }
            }

            for (const snap of ySnaps) {
                if (snap.dist < bestYDist) {
                    bestYDist = snap.dist;
                    snappedY = snap.val;
                }
            }
        }

        if (checkOverlap(testName, snappedX, snappedY, testW, testH)) {
            if (!checkOverlap(testName, snappedX, posY, testW, testH))
                return Qt.point(snappedX, posY);
            if (!checkOverlap(testName, posX, snappedY, testW, testH))
                return Qt.point(posX, snappedY);
            return Qt.point(posX, posY);
        }
        return Qt.point(snappedX, snappedY);
    }

    function findBestSnapPosition(testName, posX, posY, testW, testH) {
        const outputNames = Object.keys(outputs).filter(n => n !== testName);

        if (outputNames.length === 0)
            return Qt.point(posX, posY);

        let bestPos = null;
        let bestDist = Infinity;

        for (const name of outputNames) {
            const output = outputs[name];
            if (!output.logical)
                continue;
            const x = output.logical.x;
            const y = output.logical.y;
            const size = getLogicalSize(output);

            const candidates = [
                {
                    "px": x + size.w,
                    "py": y
                },
                {
                    "px": x - testW,
                    "py": y
                },
                {
                    "px": x,
                    "py": y + size.h
                },
                {
                    "px": x,
                    "py": y - testH
                },
                {
                    "px": x + size.w,
                    "py": y + size.h - testH
                },
                {
                    "px": x - testW,
                    "py": y + size.h - testH
                },
                {
                    "px": x + size.w - testW,
                    "py": y + size.h
                },
                {
                    "px": x + size.w - testW,
                    "py": y - testH
                }
            ];

            for (const c of candidates) {
                if (checkOverlap(testName, c.px, c.py, testW, testH))
                    continue;
                const dist = Math.hypot(c.px - posX, c.py - posY);
                if (dist < bestDist) {
                    bestDist = dist;
                    bestPos = Qt.point(c.px, c.py);
                }
            }
        }

        return bestPos || Qt.point(posX, posY);
    }

    function formatMode(mode) {
        if (!mode)
            return "";
        return mode.width + "x" + mode.height + "@" + (mode.refresh_rate / 1000).toFixed(3);
    }

    function getTransformLabel(transform) {
        switch (transform) {
        case "Normal":
            return I18n.tr("Normal");
        case "90":
            return I18n.tr("90°");
        case "180":
            return I18n.tr("180°");
        case "270":
            return I18n.tr("270°");
        case "Flipped":
            return I18n.tr("Flipped");
        case "Flipped90":
            return I18n.tr("Flipped 90°");
        case "Flipped180":
            return I18n.tr("Flipped 180°");
        case "Flipped270":
            return I18n.tr("Flipped 270°");
        default:
            return I18n.tr("Normal");
        }
    }

    function getTransformValue(label) {
        if (label === I18n.tr("Normal"))
            return "Normal";
        if (label === I18n.tr("90°"))
            return "90";
        if (label === I18n.tr("180°"))
            return "180";
        if (label === I18n.tr("270°"))
            return "270";
        if (label === I18n.tr("Flipped"))
            return "Flipped";
        if (label === I18n.tr("Flipped 90°"))
            return "Flipped90";
        if (label === I18n.tr("Flipped 180°"))
            return "Flipped180";
        if (label === I18n.tr("Flipped 270°"))
            return "Flipped270";
        return "Normal";
    }

    DankFlickable {
        anchors.fill: parent
        clip: true
        contentHeight: mainColumn.height + Theme.spacingXL
        contentWidth: width

        Column {
            id: mainColumn

            width: Math.min(550, parent.width - Theme.spacingL * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spacingXL

            StyledRect {
                id: includeWarningBox
                width: parent.width
                height: includeWarningSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius

                readonly property bool showError: root.includeStatus.exists && !root.includeStatus.included
                readonly property bool showSetup: !root.includeStatus.exists && !root.includeStatus.included

                color: (showError || showSetup) ? Theme.withAlpha(Theme.primary, 0.15) : "transparent"
                border.color: (showError || showSetup) ? Theme.withAlpha(Theme.primary, 0.3) : "transparent"
                border.width: 1
                visible: (showError || showSetup) && hasOutputBackend && !root.checkingInclude

                Column {
                    id: includeWarningSection
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "warning"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - Theme.iconSize - (includeFixButton.visible ? includeFixButton.width + Theme.spacingM : 0) - Theme.spacingM
                            spacing: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                text: {
                                    if (includeWarningBox.showSetup)
                                        return I18n.tr("First Time Setup");
                                    if (includeWarningBox.showError)
                                        return I18n.tr("Outputs Include Missing");
                                    return "";
                                }
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.primary
                            }

                            StyledText {
                                text: {
                                    if (includeWarningBox.showSetup)
                                        return I18n.tr("Click 'Setup' to create the outputs config and add include to your compositor config.");
                                    if (includeWarningBox.showError)
                                        return I18n.tr("dms/outputs config exists but is not included in your compositor config. Display changes won't persist.");
                                    return "";
                                }
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }

                        DankButton {
                            id: includeFixButton
                            visible: includeWarningBox.showError || includeWarningBox.showSetup
                            text: {
                                if (root.fixingInclude)
                                    return I18n.tr("Fixing...");
                                if (includeWarningBox.showSetup)
                                    return I18n.tr("Setup");
                                return I18n.tr("Fix Now");
                            }
                            backgroundColor: Theme.primary
                            textColor: Theme.primaryText
                            enabled: !root.fixingInclude
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: root.fixOutputsInclude()
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: monitorConfigSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 0
                visible: hasOutputBackend

                Column {
                    id: monitorConfigSection
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "monitor"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - Theme.iconSize - Theme.spacingM - (displayFormatColumn.visible ? displayFormatColumn.width + Theme.spacingM : 0)
                            spacing: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                text: I18n.tr("Monitor Configuration")
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: I18n.tr("Arrange displays and configure resolution, refresh rate, and VRR")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }

                        Column {
                            id: displayFormatColumn
                            visible: !CompositorService.isDwl
                            spacing: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                text: I18n.tr("Config Format")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            DankButtonGroup {
                                id: displayFormatGroup
                                model: [I18n.tr("Name"), I18n.tr("Model")]
                                currentIndex: SettingsData.displayNameMode === "model" ? 1 : 0
                                onSelectionChanged: (index, selected) => {
                                    if (!selected)
                                        return;
                                    const newMode = index === 1 ? "model" : "system";
                                    if (root.originalDisplayNameMode === "")
                                        root.originalDisplayNameMode = SettingsData.displayNameMode;
                                    SettingsData.displayNameMode = newMode;
                                }

                                Connections {
                                    target: SettingsData
                                    function onDisplayNameModeChanged() {
                                        displayFormatGroup.currentIndex = SettingsData.displayNameMode === "model" ? 1 : 0;
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 280
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHighest
                        border.color: Theme.outline
                        border.width: 1

                        Item {
                            id: monitorCanvas
                            anchors.fill: parent
                            anchors.margins: Theme.spacingL

                            property var bounds: root.getOutputBounds()
                            property real scaleFactor: {
                                if (bounds.width === 0 || bounds.height === 0)
                                    return 0.1;
                                const padding = Theme.spacingL * 2;
                                const scaleX = (width - padding) / bounds.width;
                                const scaleY = (height - padding) / bounds.height;
                                return Math.min(scaleX, scaleY);
                            }
                            property point offset: Qt.point((width - bounds.width * scaleFactor) / 2 - bounds.minX * scaleFactor, (height - bounds.height * scaleFactor) / 2 - bounds.minY * scaleFactor)

                            Connections {
                                target: root
                                function onAllOutputsChanged() {
                                    monitorCanvas.bounds = root.getOutputBounds();
                                }
                            }

                            Repeater {
                                model: allOutputs ? Object.keys(allOutputs) : []

                                delegate: Rectangle {
                                    id: monitorRect
                                    required property string modelData
                                    property var outputData: allOutputs[modelData]
                                    property bool isConnected: outputData?.connected ?? false
                                    property bool isDragging: false
                                    property point originalLogical: Qt.point(0, 0)
                                    property point snappedLogical: Qt.point(0, 0)
                                    property bool isValidPosition: true

                                    property var physSize: root.getPhysicalSize(outputData)
                                    property var logicalSize: root.getLogicalSize(outputData)

                                    x: isDragging ? x : (outputData?.logical?.x ?? 0) * monitorCanvas.scaleFactor + monitorCanvas.offset.x
                                    y: isDragging ? y : (outputData?.logical?.y ?? 0) * monitorCanvas.scaleFactor + monitorCanvas.offset.y
                                    width: logicalSize.w * monitorCanvas.scaleFactor
                                    height: logicalSize.h * monitorCanvas.scaleFactor
                                    radius: Theme.cornerRadius
                                    opacity: isConnected ? 1.0 : 0.5
                                    color: {
                                        if (!isConnected)
                                            return Theme.surfaceContainerHighest;
                                        if (!isValidPosition)
                                            return Theme.withAlpha(Theme.error, 0.3);
                                        if (isDragging)
                                            return Theme.withAlpha(Theme.primary, 0.4);
                                        if (dragArea.containsMouse)
                                            return Theme.withAlpha(Theme.primary, 0.2);
                                        return Theme.surfaceContainerHigh;
                                    }
                                    border.color: {
                                        if (!isConnected)
                                            return Theme.outline;
                                        if (!isValidPosition)
                                            return Theme.error;
                                        if (isDragging)
                                            return Theme.primary;
                                        if (CompositorService.getFocusedScreen()?.name === modelData)
                                            return Theme.primary;
                                        return Theme.outline;
                                    }
                                    border.width: isDragging ? 3 : 2
                                    z: isDragging ? 100 : (isConnected ? 1 : 0)

                                    Rectangle {
                                        id: snapPreview
                                        visible: monitorRect.isDragging && monitorRect.isValidPosition
                                        x: monitorRect.snappedLogical.x * monitorCanvas.scaleFactor + monitorCanvas.offset.x - monitorRect.x
                                        y: monitorRect.snappedLogical.y * monitorCanvas.scaleFactor + monitorCanvas.offset.y - monitorRect.y
                                        width: parent.width
                                        height: parent.height
                                        radius: Theme.cornerRadius
                                        color: "transparent"
                                        border.color: Theme.primary
                                        border.width: 2
                                        opacity: 0.6
                                    }

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 2

                                        DankIcon {
                                            name: monitorRect.isConnected ? "desktop_windows" : "desktop_access_disabled"
                                            size: Math.min(24, Math.min(monitorRect.width * 0.3, monitorRect.height * 0.25))
                                            color: monitorRect.isConnected ? (monitorRect.isValidPosition ? Theme.primary : Theme.error) : Theme.surfaceVariantText
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }

                                        StyledText {
                                            text: root.getOutputDisplayName(monitorRect.outputData, modelData)
                                            font.pixelSize: Math.max(10, Math.min(14, monitorRect.width * 0.12))
                                            font.weight: Font.Medium
                                            color: monitorRect.isConnected ? Theme.surfaceText : Theme.surfaceVariantText
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            elide: Text.ElideMiddle
                                            width: Math.min(implicitWidth, monitorRect.width - 8)
                                        }

                                        StyledText {
                                            text: monitorRect.isConnected ? (monitorRect.physSize.w + "x" + monitorRect.physSize.h) : I18n.tr("Disconnected")
                                            font.pixelSize: Math.max(8, Math.min(11, monitorRect.width * 0.09))
                                            color: Theme.surfaceVariantText
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: dragArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: monitorRect.isConnected
                                        cursorShape: !monitorRect.isConnected ? Qt.ArrowCursor : (monitorRect.isDragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
                                        drag.target: monitorRect.isConnected ? monitorRect : null
                                        drag.axis: Drag.XAndYAxis
                                        drag.threshold: 0

                                        onPressed: mouse => {
                                            if (!monitorRect.isConnected)
                                                return;
                                            monitorRect.isDragging = true;
                                            monitorRect.originalLogical = Qt.point(outputData?.logical?.x ?? 0, outputData?.logical?.y ?? 0);
                                            monitorRect.snappedLogical = monitorRect.originalLogical;
                                            monitorRect.isValidPosition = true;
                                        }

                                        onPositionChanged: mouse => {
                                            if (!monitorRect.isDragging || !monitorRect.isConnected)
                                                return;
                                            let posX = Math.round((monitorRect.x - monitorCanvas.offset.x) / monitorCanvas.scaleFactor);
                                            let posY = Math.round((monitorRect.y - monitorCanvas.offset.y) / monitorCanvas.scaleFactor);

                                            const size = root.getLogicalSize(outputData);

                                            const snapped = root.snapToEdges(modelData, posX, posY, size.w, size.h);
                                            monitorRect.snappedLogical = snapped;
                                            monitorRect.isValidPosition = !root.checkOverlap(modelData, snapped.x, snapped.y, size.w, size.h);
                                        }

                                        onReleased: {
                                            if (!monitorRect.isDragging || !monitorRect.isConnected)
                                                return;
                                            monitorRect.isDragging = false;

                                            const size = root.getLogicalSize(outputData);
                                            const finalX = monitorRect.snappedLogical.x;
                                            const finalY = monitorRect.snappedLogical.y;

                                            if (root.checkOverlap(modelData, finalX, finalY, size.w, size.h)) {
                                                monitorRect.isValidPosition = true;
                                                return;
                                            }

                                            if (finalX === monitorRect.originalLogical.x && finalY === monitorRect.originalLogical.y)
                                                return;
                                            root.initOriginalOutputs();
                                            backendUpdateOutputPosition(modelData, finalX, finalY);
                                            root.setPendingChange(modelData, "position", {
                                                "x": finalX,
                                                "y": finalY
                                            });
                                        }
                                    }

                                    Drag.active: dragArea.drag.active && monitorRect.isConnected
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        Repeater {
                            model: allOutputs ? Object.keys(allOutputs) : []

                            delegate: StyledRect {
                                id: outputCard
                                required property string modelData
                                property var outputData: allOutputs[modelData]
                                property bool isConnected: outputData?.connected ?? false
                                property bool niriExpanded: false

                                width: parent.width
                                height: outputSettingsCol.implicitHeight + Theme.spacingM * 2
                                radius: Theme.cornerRadius
                                color: Theme.withAlpha(Theme.surfaceContainerHigh, isConnected ? 0.5 : 0.3)
                                border.color: Theme.withAlpha(Theme.outline, 0.3)
                                border.width: 1
                                opacity: isConnected ? 1.0 : 0.7

                                Column {
                                    id: outputSettingsCol
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingM
                                    spacing: Theme.spacingS

                                    Row {
                                        width: parent.width
                                        spacing: Theme.spacingM

                                        DankIcon {
                                            name: isConnected ? "desktop_windows" : "desktop_access_disabled"
                                            size: Theme.iconSize - 4
                                            color: isConnected ? Theme.primary : Theme.surfaceVariantText
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Column {
                                            width: parent.width - Theme.iconSize - Theme.spacingM - (disconnectedBadge.visible ? disconnectedBadge.width + Theme.spacingS : 0)
                                            spacing: 2

                                            StyledText {
                                                text: root.getOutputDisplayName(outputData, modelData)
                                                font.pixelSize: Theme.fontSizeMedium
                                                font.weight: Font.Medium
                                                color: isConnected ? Theme.surfaceText : Theme.surfaceVariantText
                                            }

                                            StyledText {
                                                text: (outputData?.model ?? "") + (outputData?.make ? " - " + outputData.make : "")
                                                font.pixelSize: Theme.fontSizeSmall
                                                color: Theme.surfaceVariantText
                                            }
                                        }

                                        Rectangle {
                                            id: disconnectedBadge
                                            visible: !isConnected
                                            width: disconnectedText.implicitWidth + Theme.spacingM
                                            height: disconnectedText.implicitHeight + Theme.spacingXS
                                            radius: height / 2
                                            color: Theme.withAlpha(Theme.outline, 0.3)
                                            anchors.verticalCenter: parent.verticalCenter

                                            StyledText {
                                                id: disconnectedText
                                                text: I18n.tr("Disconnected")
                                                font.pixelSize: Theme.fontSizeSmall
                                                color: Theme.surfaceVariantText
                                                anchors.centerIn: parent
                                            }
                                        }
                                    }

                                    DankDropdown {
                                        width: parent.width
                                        text: I18n.tr("Resolution & Refresh")
                                        visible: isConnected
                                        currentValue: {
                                            const pendingMode = root.getPendingValue(modelData, "mode");
                                            if (pendingMode)
                                                return pendingMode;
                                            const data = root.outputs[modelData];
                                            if (!data?.modes || data?.current_mode === undefined)
                                                return "Auto";
                                            const mode = data.modes[data.current_mode];
                                            return mode ? root.formatMode(mode) : "Auto";
                                        }
                                        options: {
                                            const data = root.outputs[modelData];
                                            if (!data?.modes)
                                                return ["Auto"];
                                            const opts = [];
                                            for (var i = 0; i < data.modes.length; i++) {
                                                opts.push(root.formatMode(data.modes[i]));
                                            }
                                            return opts;
                                        }
                                        onValueChanged: value => root.setPendingChange(modelData, "mode", value)
                                    }

                                    StyledText {
                                        visible: !isConnected
                                        text: I18n.tr("Configuration will be preserved when this display reconnects")
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceVariantText
                                        wrapMode: Text.WordWrap
                                        width: parent.width
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: Theme.spacingM
                                        visible: isConnected

                                        Column {
                                            width: (parent.width - Theme.spacingM) / 2
                                            spacing: Theme.spacingXS

                                            StyledText {
                                                text: I18n.tr("Scale")
                                                font.pixelSize: Theme.fontSizeSmall
                                                color: Theme.surfaceVariantText
                                            }

                                            Item {
                                                width: parent.width
                                                height: scaleDropdown.visible ? scaleDropdown.height : scaleInput.height

                                                property bool customMode: false
                                                property string currentScale: {
                                                    const pendingScale = root.getPendingValue(modelData, "scale");
                                                    if (pendingScale !== undefined)
                                                        return parseFloat(pendingScale.toFixed(2)).toString();
                                                    const scale = root.outputs[modelData]?.logical?.scale ?? 1.0;
                                                    return parseFloat(scale.toFixed(2)).toString();
                                                }

                                                DankDropdown {
                                                    id: scaleDropdown
                                                    width: parent.width
                                                    dropdownWidth: parent.width
                                                    visible: !parent.customMode
                                                    currentValue: parent.currentScale
                                                    options: {
                                                        const standard = ["0.5", "0.75", "1", "1.25", "1.5", "1.75", "2", "2.5", "3", I18n.tr("Custom...")];
                                                        const current = parent.currentScale;
                                                        if (standard.slice(0, -1).includes(current))
                                                            return standard;
                                                        const opts = [...standard.slice(0, -1), current, standard[standard.length - 1]];
                                                        return opts.sort((a, b) => {
                                                            if (a === I18n.tr("Custom..."))
                                                                return 1;
                                                            if (b === I18n.tr("Custom..."))
                                                                return -1;
                                                            return parseFloat(a) - parseFloat(b);
                                                        });
                                                    }
                                                    onValueChanged: value => {
                                                        if (value === I18n.tr("Custom...")) {
                                                            parent.customMode = true;
                                                            scaleInput.text = parent.currentScale;
                                                            scaleInput.forceActiveFocus();
                                                            scaleInput.selectAll();
                                                            return;
                                                        }
                                                        root.setPendingChange(modelData, "scale", parseFloat(value));
                                                    }
                                                }

                                                DankTextField {
                                                    id: scaleInput
                                                    width: parent.width
                                                    height: 40
                                                    visible: parent.customMode
                                                    placeholderText: "0.5 - 4.0"

                                                    function applyValue() {
                                                        const val = parseFloat(text);
                                                        if (isNaN(val) || val < 0.25 || val > 4) {
                                                            text = parent.currentScale;
                                                            parent.customMode = false;
                                                            return;
                                                        }
                                                        root.setPendingChange(modelData, "scale", parseFloat(val.toFixed(2)));
                                                        parent.customMode = false;
                                                    }

                                                    onAccepted: applyValue()
                                                    onEditingFinished: applyValue()
                                                    Keys.onEscapePressed: {
                                                        text = parent.currentScale;
                                                        parent.customMode = false;
                                                    }
                                                }
                                            }
                                        }

                                        Column {
                                            width: (parent.width - Theme.spacingM) / 2
                                            spacing: Theme.spacingXS

                                            StyledText {
                                                text: I18n.tr("Transform")
                                                font.pixelSize: Theme.fontSizeSmall
                                                color: Theme.surfaceVariantText
                                            }

                                            DankDropdown {
                                                width: parent.width
                                                dropdownWidth: parent.width
                                                currentValue: {
                                                    const pendingTransform = root.getPendingValue(modelData, "transform");
                                                    if (pendingTransform)
                                                        return root.getTransformLabel(pendingTransform);
                                                    const data = root.outputs[modelData];
                                                    return root.getTransformLabel(data?.logical?.transform ?? "Normal");
                                                }
                                                options: [I18n.tr("Normal"), I18n.tr("90°"), I18n.tr("180°"), I18n.tr("270°"), I18n.tr("Flipped"), I18n.tr("Flipped 90°"), I18n.tr("Flipped 180°"), I18n.tr("Flipped 270°")]
                                                onValueChanged: value => root.setPendingChange(modelData, "transform", root.getTransformValue(value))
                                            }
                                        }
                                    }

                                    DankToggle {
                                        width: parent.width
                                        text: I18n.tr("Variable Refresh Rate")
                                        visible: isConnected && !CompositorService.isDwl && (root.outputs[modelData]?.vrr_supported ?? false)
                                        checked: {
                                            const pendingVrr = root.getPendingValue(modelData, "vrr");
                                            if (pendingVrr !== undefined)
                                                return pendingVrr;
                                            return root.outputs[modelData]?.vrr_enabled ?? false;
                                        }
                                        onToggled: checked => root.setPendingChange(modelData, "vrr", checked)
                                    }

                                    DankToggle {
                                        width: parent.width
                                        text: I18n.tr("VRR On-Demand")
                                        description: I18n.tr("VRR activates only when applications request it")
                                        visible: isConnected && CompositorService.isNiri && (root.outputs[modelData]?.vrr_supported ?? false)
                                        checked: root.getNiriSetting(outputData, modelData, "vrrOnDemand", false)
                                        onToggled: checked => root.setNiriSetting(outputData, modelData, "vrrOnDemand", checked)
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: Theme.withAlpha(Theme.outline, 0.2)
                                        visible: isConnected && CompositorService.isNiri
                                    }

                                    Column {
                                        width: parent.width
                                        spacing: 0
                                        visible: isConnected && CompositorService.isNiri

                                        Rectangle {
                                            width: parent.width
                                            height: niriHeader.implicitHeight + Theme.spacingS * 2
                                            color: niriHeaderMouse.containsMouse ? Theme.withAlpha(Theme.primary, 0.1) : "transparent"
                                            radius: Theme.cornerRadius / 2

                                            Row {
                                                id: niriHeader
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.leftMargin: Theme.spacingS
                                                anchors.rightMargin: Theme.spacingS
                                                spacing: Theme.spacingS

                                                DankIcon {
                                                    name: outputCard.niriExpanded ? "expand_more" : "chevron_right"
                                                    size: Theme.iconSize
                                                    color: Theme.primary
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }

                                                StyledText {
                                                    text: I18n.tr("Compositor Settings")
                                                    font.pixelSize: Theme.fontSizeMedium
                                                    font.weight: Font.Medium
                                                    color: Theme.primary
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }

                                            MouseArea {
                                                id: niriHeaderMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: outputCard.niriExpanded = !outputCard.niriExpanded
                                            }
                                        }

                                        Column {
                                            width: parent.width
                                            spacing: Theme.spacingS
                                            visible: outputCard.niriExpanded
                                            topPadding: Theme.spacingS

                                            DankToggle {
                                                width: parent.width
                                                text: I18n.tr("Disable Output")
                                                checked: root.getNiriSetting(outputData, modelData, "disabled", false)
                                                onToggled: checked => root.setNiriSetting(outputData, modelData, "disabled", checked)
                                            }

                                            DankToggle {
                                                width: parent.width
                                                text: I18n.tr("Focus at Startup")
                                                checked: root.getNiriSetting(outputData, modelData, "focusAtStartup", false)
                                                onToggled: checked => root.setNiriSetting(outputData, modelData, "focusAtStartup", checked)
                                            }

                                            DankDropdown {
                                                width: parent.width
                                                text: I18n.tr("Hot Corners")
                                                addHorizontalPadding: true
                                                property var hotCornersData: root.getNiriSetting(outputData, modelData, "hotCorners", null)
                                                currentValue: {
                                                    if (!hotCornersData)
                                                        return I18n.tr("Inherit");
                                                    if (hotCornersData.off)
                                                        return I18n.tr("Off");
                                                    const corners = hotCornersData.corners || [];
                                                    if (corners.length === 0)
                                                        return I18n.tr("Inherit");
                                                    if (corners.length === 4)
                                                        return I18n.tr("All");
                                                    return I18n.tr("Select...");
                                                }
                                                options: [I18n.tr("Inherit"), I18n.tr("Off"), I18n.tr("All"), I18n.tr("Select...")]
                                                onValueChanged: value => {
                                                    switch (value) {
                                                    case I18n.tr("Inherit"):
                                                        root.setNiriSetting(outputData, modelData, "hotCorners", null);
                                                        break;
                                                    case I18n.tr("Off"):
                                                        root.setNiriSetting(outputData, modelData, "hotCorners", {
                                                            "off": true
                                                        });
                                                        break;
                                                    case I18n.tr("All"):
                                                        root.setNiriSetting(outputData, modelData, "hotCorners", {
                                                            "corners": ["top-left", "top-right", "bottom-left", "bottom-right"]
                                                        });
                                                        break;
                                                    case I18n.tr("Select..."):
                                                        root.setNiriSetting(outputData, modelData, "hotCorners", {
                                                            "corners": []
                                                        });
                                                        break;
                                                    }
                                                }
                                            }

                                            Item {
                                                width: parent.width
                                                height: hotCornersFlow.height
                                                visible: hotCornersFlow.visible

                                                Flow {
                                                    id: hotCornersFlow
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.leftMargin: Theme.spacingM
                                                    anchors.rightMargin: Theme.spacingM
                                                    spacing: Theme.spacingS
                                                    property string outName: modelData
                                                    property var outData: outputData
                                                    visible: {
                                                        const hcData = root.getNiriSetting(outData, outName, "hotCorners", null);
                                                        return hcData && !hcData.off && hcData.corners !== undefined;
                                                    }

                                                    Repeater {
                                                        model: ["top-left", "top-right", "bottom-left", "bottom-right"]

                                                        delegate: Rectangle {
                                                            id: cornerChip
                                                            required property string modelData
                                                            property var hcData: root.getNiriSetting(hotCornersFlow.outData, hotCornersFlow.outName, "hotCorners", null)
                                                            property bool isEnabled: hcData?.corners?.includes(modelData) ?? false

                                                            width: cornerLabel.implicitWidth + Theme.spacingM * 2
                                                            height: 28
                                                            radius: 14
                                                            color: isEnabled ? Theme.primary : Theme.surfaceContainerHighest
                                                            border.color: isEnabled ? Theme.primary : Theme.outline
                                                            border.width: 1

                                                            StyledText {
                                                                id: cornerLabel
                                                                anchors.centerIn: parent
                                                                text: cornerChip.modelData.split("-").map(s => s.charAt(0).toUpperCase() + s.slice(1)).join(" ")
                                                                font.pixelSize: Theme.fontSizeSmall
                                                                color: cornerChip.isEnabled ? Theme.primaryText : Theme.surfaceText
                                                            }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    const currentHc = root.getNiriSetting(hotCornersFlow.outData, hotCornersFlow.outName, "hotCorners", {
                                                                        "corners": []
                                                                    });
                                                                    const corners = currentHc?.corners ? [...currentHc.corners] : [];
                                                                    const idx = corners.indexOf(cornerChip.modelData);
                                                                    if (idx >= 0) {
                                                                        corners.splice(idx, 1);
                                                                    } else {
                                                                        corners.push(cornerChip.modelData);
                                                                    }
                                                                    root.setNiriSetting(hotCornersFlow.outData, hotCornersFlow.outName, "hotCorners", {
                                                                        "corners": corners
                                                                    });
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                width: parent.width
                                                height: 1
                                                color: Theme.withAlpha(Theme.outline, 0.15)
                                            }

                                            Item {
                                                width: parent.width
                                                height: layoutOverridesCol.implicitHeight

                                                Column {
                                                    id: layoutOverridesCol
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.leftMargin: Theme.spacingM
                                                    anchors.rightMargin: Theme.spacingM
                                                    spacing: Theme.spacingS

                                                    Column {
                                                        width: parent.width
                                                        spacing: Theme.spacingXS

                                                        StyledText {
                                                            text: I18n.tr("Layout Overrides")
                                                            font.pixelSize: Theme.fontSizeSmall
                                                            font.weight: Font.Medium
                                                            color: Theme.surfaceVariantText
                                                        }

                                                        StyledText {
                                                            text: I18n.tr("Override global layout settings for this output")
                                                            font.pixelSize: Theme.fontSizeSmall
                                                            color: Theme.withAlpha(Theme.surfaceVariantText, 0.7)
                                                            wrapMode: Text.WordWrap
                                                            width: parent.width
                                                        }
                                                    }

                                                    Row {
                                                        width: parent.width
                                                        spacing: Theme.spacingM

                                                        Column {
                                                            width: (parent.width - Theme.spacingM) / 2
                                                            spacing: Theme.spacingXS

                                                            StyledText {
                                                                text: I18n.tr("Window Gaps (px)")
                                                                font.pixelSize: Theme.fontSizeSmall
                                                                color: Theme.surfaceVariantText
                                                            }

                                                            DankTextField {
                                                                width: parent.width
                                                                height: 40
                                                                placeholderText: I18n.tr("Inherit")
                                                                text: {
                                                                    const layout = root.getNiriSetting(outputData, modelData, "layout", null);
                                                                    if (layout?.gaps === undefined)
                                                                        return "";
                                                                    return layout.gaps.toString();
                                                                }
                                                                onEditingFinished: {
                                                                    const layout = root.getNiriSetting(outputData, modelData, "layout", {}) || {};
                                                                    const trimmed = text.trim();
                                                                    if (!trimmed) {
                                                                        delete layout.gaps;
                                                                        root.setNiriSetting(outputData, modelData, "layout", Object.keys(layout).length > 0 ? layout : null);
                                                                        return;
                                                                    }
                                                                    const val = parseInt(trimmed);
                                                                    if (isNaN(val) || val < 0)
                                                                        return;
                                                                    layout.gaps = val;
                                                                    root.setNiriSetting(outputData, modelData, "layout", layout);
                                                                }
                                                            }
                                                        }

                                                        Column {
                                                            width: (parent.width - Theme.spacingM) / 2
                                                            spacing: Theme.spacingXS

                                                            StyledText {
                                                                text: I18n.tr("Default Width (%)")
                                                                font.pixelSize: Theme.fontSizeSmall
                                                                color: Theme.surfaceVariantText
                                                            }

                                                            DankTextField {
                                                                width: parent.width
                                                                height: 40
                                                                placeholderText: I18n.tr("Inherit")
                                                                text: {
                                                                    const layout = root.getNiriSetting(outputData, modelData, "layout", null);
                                                                    if (!layout?.defaultColumnWidth)
                                                                        return "";
                                                                    if (layout.defaultColumnWidth.type !== "proportion")
                                                                        return "";
                                                                    return Math.round(layout.defaultColumnWidth.value * 100).toString();
                                                                }
                                                                onEditingFinished: {
                                                                    const layout = root.getNiriSetting(outputData, modelData, "layout", {}) || {};
                                                                    const trimmed = text.trim().replace("%", "");
                                                                    if (!trimmed) {
                                                                        delete layout.defaultColumnWidth;
                                                                        root.setNiriSetting(outputData, modelData, "layout", Object.keys(layout).length > 0 ? layout : null);
                                                                        return;
                                                                    }
                                                                    const val = parseFloat(trimmed);
                                                                    if (isNaN(val) || val <= 0 || val > 100)
                                                                        return;
                                                                    layout.defaultColumnWidth = {
                                                                        "type": "proportion",
                                                                        "value": val / 100
                                                                    };
                                                                    root.setNiriSetting(outputData, modelData, "layout", layout);
                                                                }
                                                            }
                                                        }
                                                    }

                                                    Column {
                                                        width: parent.width
                                                        spacing: Theme.spacingXS

                                                        StyledText {
                                                            text: I18n.tr("Preset Widths (%)")
                                                            font.pixelSize: Theme.fontSizeSmall
                                                            color: Theme.surfaceVariantText
                                                        }

                                                        StyledText {
                                                            text: "e.g. 33, 50, 67"
                                                            font.pixelSize: Theme.fontSizeSmall
                                                            color: Theme.withAlpha(Theme.surfaceVariantText, 0.7)
                                                        }

                                                        DankTextField {
                                                            width: parent.width
                                                            height: 40
                                                            placeholderText: I18n.tr("Inherit")
                                                            text: {
                                                                const layout = root.getNiriSetting(outputData, modelData, "layout", null);
                                                                const presets = layout?.presetColumnWidths || [];
                                                                if (presets.length === 0)
                                                                    return "";
                                                                return presets.filter(p => p.type === "proportion").map(p => Math.round(p.value * 100)).join(", ");
                                                            }
                                                            onEditingFinished: {
                                                                const layout = root.getNiriSetting(outputData, modelData, "layout", {}) || {};
                                                                const trimmed = text.trim();
                                                                if (!trimmed) {
                                                                    delete layout.presetColumnWidths;
                                                                    root.setNiriSetting(outputData, modelData, "layout", Object.keys(layout).length > 0 ? layout : null);
                                                                    return;
                                                                }
                                                                const parts = trimmed.split(/[,\s]+/).filter(s => s);
                                                                const presets = [];
                                                                for (const part of parts) {
                                                                    const val = parseFloat(part.replace("%", ""));
                                                                    if (!isNaN(val) && val > 0 && val <= 100) {
                                                                        presets.push({
                                                                            "type": "proportion",
                                                                            "value": val / 100
                                                                        });
                                                                    }
                                                                }
                                                                if (presets.length === 0) {
                                                                    delete layout.presetColumnWidths;
                                                                    root.setNiriSetting(outputData, modelData, "layout", Object.keys(layout).length > 0 ? layout : null);
                                                                    return;
                                                                }
                                                                presets.sort((a, b) => a.value - b.value);
                                                                layout.presetColumnWidths = presets;
                                                                root.setNiriSetting(outputData, modelData, "layout", layout);
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            DankToggle {
                                                width: parent.width
                                                text: I18n.tr("Center Single Column")
                                                property var layoutData: root.getNiriSetting(outputData, modelData, "layout", null)
                                                checked: layoutData?.alwaysCenterSingleColumn ?? false
                                                onToggled: checked => {
                                                    const layout = root.getNiriSetting(outputData, modelData, "layout", {}) || {};
                                                    if (checked) {
                                                        layout.alwaysCenterSingleColumn = true;
                                                    } else {
                                                        delete layout.alwaysCenterSingleColumn;
                                                    }
                                                    root.setNiriSetting(outputData, modelData, "layout", Object.keys(layout).length > 0 ? layout : null);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingS
                        visible: root.hasPendingChanges
                        layoutDirection: Qt.RightToLeft

                        DankButton {
                            text: I18n.tr("Apply Changes")
                            iconName: "check"
                            onClicked: root.applyChanges()
                        }

                        DankButton {
                            text: I18n.tr("Discard")
                            backgroundColor: "transparent"
                            textColor: Theme.surfaceText
                            onClicked: root.discardChanges()
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: noBackendMessage.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 0
                visible: !hasOutputBackend

                Column {
                    id: noBackendMessage
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "monitor"
                            size: Theme.iconSize
                            color: Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - Theme.iconSize - Theme.spacingM
                            spacing: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                text: I18n.tr("Monitor Configuration")
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: I18n.tr("Display configuration is not available. WLR output management protocol not supported.")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }
                    }
                }
            }
        }
    }

    DisplayConfirmationModal {
        id: confirmationModal
        onConfirmed: root.confirmChanges()
        onReverted: root.revertChanges()
    }
}
