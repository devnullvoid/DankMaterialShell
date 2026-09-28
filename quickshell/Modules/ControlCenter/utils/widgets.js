.import qs.Common as Common
.import qs.Modules.ControlCenter as ControlCenter
.import "../../../Common/GridLayout.js" as GridLayout

var PINNED_IDS = ["userCard", "quickActions"];
var OPTION_IDS = ["diskUsage", "brightnessSlider", "idleInhibitor", "userCard", "quickActions"];
var QUICK_ACTIONS = [{
        "id": "lock",
        "icon": "lock",
        "label": "Lock"
    }, {
        "id": "power",
        "icon": "power_settings_new",
        "label": "Power"
    }, {
        "id": "settings",
        "icon": "settings",
        "label": "Settings"
    }, {
        "id": "edit",
        "icon": "edit",
        "label": "Edit"
    }];
var QUICK_ACTION_IDS = QUICK_ACTIONS.map(action => action.id);

function isSliderWidget(id) {
    return id === "volumeSlider" || id === "brightnessSlider" || id === "inputVolumeSlider";
}

function isPinned(id) {
    return PINNED_IDS.includes(id);
}

function hasOptions(id) {
    return OPTION_IDS.includes(id) || String(id ?? "").startsWith("plugin_");
}

// Saved order wins, unknown ids drop, missing ones append so new actions show up without a migration.
function quickActions(widgetData) {
    const saved = Array.isArray(widgetData?.actions) ? widgetData.actions : [];
    const out = saved.filter(action => QUICK_ACTION_IDS.includes(action?.id)).map(action => ({
                "id": action.id,
                "enabled": action.id === "edit" || action.enabled !== false
            }));
    for (const id of QUICK_ACTION_IDS) {
        if (!out.some(action => action.id === id))
            out.push({
                "id": id,
                "enabled": true
            });
    }
    return out;
}

var QUICK_ACTION_ROLES = ["primary", "primaryContainer", "secondary", "surfaceVariant", "surfaceText"];

function quickActionRole(widgetData) {
    return QUICK_ACTION_ROLES.includes(widgetData?.buttonColor) ? widgetData.buttonColor : "default";
}

function quickActionIcon(id) {
    return QUICK_ACTIONS.find(action => action.id === id)?.icon ?? "";
}

// Untranslated catalog term; callers wrap it in I18n.tr.
function quickActionLabel(id) {
    return QUICK_ACTIONS.find(action => action.id === id)?.label ?? "";
}

function defaultWidget(id, columns) {
    return Object.assign({
        "id": id,
        "enabled": true
    }, clampSize({
        "id": id
    }, columns));
}

function pinnedWidgets(columns) {
    return PINNED_IDS.map(id => defaultWidget(id, columns));
}

function sizeSpec(widget, columns, rows = Infinity) {
    const id = widget?.id || "";
    const spec = {
        "w": 4,
        "h": 1,
        "minW": 1,
        "maxW": columns,
        "minH": 1,
        "maxH": rows,
        "step": ControlCenter.CcMetrics.gridStep
    };
    switch (id) {
    case "userCard":
        spec.w = Number.isFinite(columns) ? Math.max(1, columns - 4) : 4;
        spec.maxH = Math.min(2, rows);
        break;
    case "quickActions":
        spec.minW = Math.min(ControlCenter.CcMetrics.quickActionsMinColumns(quickActions(widget).filter(action => action.enabled).length), columns);
        spec.w = Math.max(spec.minW, 4);
        spec.maxH = Math.min(2, rows);
        break;
    }
    return spec;
}

function clampSize(widget, columns, rows = Infinity) {
    const spec = sizeSpec(widget, columns, rows);
    const size = {
        "w": GridLayout.dimension(widget.w, spec.minW, spec.maxW, spec.w, spec.step),
        "h": GridLayout.dimension(widget.h, spec.minH, spec.maxH, spec.h, spec.step)
    };
    if (!isSliderWidget(widget.id) || size.w >= 2 || size.h >= 2)
        return size;
    if (rows > 1)
        return {
            "w": 1,
            "h": 2
        };
    return {
        "w": Math.min(2, columns),
        "h": 1
    };
}

function addWidget(widgetId, columns) {
    const widgets = Common.SettingsData.controlCenterWidgets.slice();
    const widget = defaultWidget(widgetId, columns);

    if (widgetId === "diskUsage") {
        widget.instanceId = generateUniqueId();
        widget.mountPath = "/";
        widget.showMountPath = true;
    }

    if (widgetId === "brightnessSlider") {
        widget.instanceId = generateUniqueId();
        widget.deviceName = "";
    }

    widgets.push(widget);
    Common.SettingsData.set("controlCenterWidgets", widgets);
}

function generateUniqueId() {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
}

function removeWidget(index) {
    const widgets = Common.SettingsData.controlCenterWidgets.slice();
    if (index < 0 || index >= widgets.length || isPinned(widgets[index]?.id))
        return;
    widgets.splice(index, 1);
    Common.SettingsData.set("controlCenterWidgets", widgets);
}

function setLayout(widgets) {
    Common.SettingsData.set("controlCenterWidgets", widgets);
}

function resetToDefault(columns) {
    const ids = ["volumeSlider", "brightnessSlider", "wifi", "bluetooth", "audioOutput", "audioInput", "nightMode", "darkMode"];
    Common.SettingsData.set("controlCenterWidgets", pinnedWidgets(columns).concat(ids.map(id => defaultWidget(id, columns))));
}

function clearAll(columns) {
    Common.SettingsData.set("controlCenterWidgets", pinnedWidgets(columns));
}
