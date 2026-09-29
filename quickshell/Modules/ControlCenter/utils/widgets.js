.import qs.Common as Common
.import qs.Services as Services
.import qs.Modules.ControlCenter as ControlCenter
.import "../../../Common/GridLayout.js" as GridLayout

var OPTION_IDS = ["diskUsage", "brightnessSlider", "idleInhibitor", "user"];
var ACTION_IDS = ["settings", "lock", "power"];
var USER_SHAPES = ["circle", "cookie4", "cookie7", "cookie12", "clover4", "clover8", "sunny", "pentagon", "arch", "slanted", "gem", "square"];

function isSliderWidget(id) {
    return id === "volumeSlider" || id === "brightnessSlider" || id === "inputVolumeSlider";
}

function isShown(widget) {
    switch (widget?.id) {
    case "battery":
        return Services.BatteryService.batteryAvailable || Services.PowerProfileWatcher.available;
    case "diskUsage":
        return Services.DgopService.dgopAvailable;
    default:
        return true;
    }
}

function isUnplaced(widget) {
    return !Number.isFinite(widget?.col) || !Number.isFinite(widget?.row);
}

function hasOptions(id) {
    return OPTION_IDS.includes(id) || String(id ?? "").startsWith("plugin_");
}

function filterWidgets(widgets, query) {
    const needle = query.trim().toLowerCase();
    if (!needle)
        return widgets;
    return widgets.filter(widget => [widget.text, widget.description, widget.id].some(value => (value || "").toLowerCase().includes(needle)));
}

function nextUserShape(shape) {
    return USER_SHAPES[(USER_SHAPES.indexOf(shape) + 1) % USER_SHAPES.length];
}

function defaultWidget(id, columns) {
    return Object.assign({
        "id": id,
        "enabled": true
    }, clampSize({
        "id": id
    }, columns));
}

function sizeSpec(widget, columns, rows = Infinity) {
    const spec = {
        "w": 4,
        "h": 1,
        "minW": 1,
        "maxW": columns,
        "minH": 1,
        "maxH": rows,
        "step": ControlCenter.CcMetrics.gridStep
    };
    if (widget?.id === "user")
        spec.w = (Number.isFinite(columns) ? columns : ControlCenter.CcMetrics.defaultColumns) - ACTION_IDS.length;
    if (ACTION_IDS.includes(widget?.id))
        spec.w = 1;
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
    if (index < 0 || index >= widgets.length)
        return;
    widgets.splice(index, 1);
    Common.SettingsData.set("controlCenterWidgets", widgets);
}

function setOption(index, key, value) {
    const widgets = Common.SettingsData.controlCenterWidgets.slice();
    if (index < 0 || index >= widgets.length)
        return;
    widgets[index] = Object.assign({}, widgets[index], {
        [key]: value
    });
    Common.SettingsData.set("controlCenterWidgets", widgets);
}

function setLayout(widgets) {
    Common.SettingsData.set("controlCenterWidgets", widgets);
}

function resetToDefault() {
    Common.SettingsData.resetToDefault(["controlCenterWidgets", "controlCenterColumns"]);
}

function clearAll() {
    Common.SettingsData.set("controlCenterWidgets", []);
}
