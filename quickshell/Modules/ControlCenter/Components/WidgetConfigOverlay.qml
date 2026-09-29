pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.Modules.ControlCenter
import qs.Modules.ControlCenter.Widgets
import qs.Modules.DankBar.Widgets
import qs.Modules.DankDash
import qs.Modules.Settings.Widgets
import "../utils/widgets.js" as WidgetUtils
import qs.Services
import qs.Widgets

Item {
    id: root

    property int widgetIndex: -1
    property var transientSurfaceTracker: null
    property Item _anchor: null

    readonly property var widgetData: {
        if (widgetIndex < 0)
            return null;
        const widgets = SettingsData.controlCenterWidgets || [];
        return widgets[widgetIndex] || null;
    }
    readonly property string widgetId: String(widgetData?.id ?? "")
    readonly property bool isPlugin: widgetId.startsWith("plugin_")
    readonly property bool isDisk: widgetId === "diskUsage"
    readonly property bool isIdleInhibitor: widgetId === "idleInhibitor"
    readonly property bool isUser: widgetId === "userCard"
    readonly property bool isQuickActions: widgetId === "quickActions"
    readonly property var quickActions: isQuickActions ? WidgetUtils.quickActions(widgetData) : []

    visible: widgetIndex >= 0 || contextMenu.renderActive

    function open(index, data, anchorItem) {
        widgetIndex = index;
        _anchor = anchorItem;
        // Placement needs the final menu height, which settles after widgetIndex propagates.
        Qt.callLater(() => {
            const window = root.QsWindow.window;
            const screen = window?.screen;
            if (root.widgetIndex !== index || !anchorItem || !screen)
                return;
            const pos = anchorItem.mapToGlobal(0, 0);
            const x = pos.x - screen.x;
            const y = pos.y - screen.y;
            const menuX = I18n.isRtl ? x : x + anchorItem.width - contextMenu.effectiveMenuWidth;
            const aboveY = () => y - contextMenu.effectiveMenuHeight - Theme.spacingS;
            if (aboveY() < Theme.spacingS) {
                contextMenu.open(screen, menuX, y + anchorItem.height + Theme.spacingS, false);
                return;
            }
            contextMenu.open(screen, menuX, aboveY(), false);
            contextMenu.anchorY = Qt.binding(aboveY);
        });
    }

    function close() {
        if (!contextMenu.renderActive) {
            widgetIndex = -1;
            _anchor = null;
            return;
        }
        contextMenu.hide();
    }

    function toggleAction(id, enabled) {
        persistOption("actions", quickActions.map(action => action.id === id ? Object.assign({}, action, {
                "enabled": enabled
            }) : action));
    }

    function persistOption(key, value) {
        const widgets = (SettingsData.controlCenterWidgets || []).slice();
        if (widgetIndex < 0 || widgetIndex >= widgets.length)
            return;
        widgets[widgetIndex] = Object.assign({}, widgets[widgetIndex], {
            [key]: value
        });
        SettingsData.set("controlCenterWidgets", widgets);
    }

    DankContextMenu {
        id: contextMenu
        layerNamespace: "dms:control-center-widget-options"
        minMenuWidth: CcMetrics.configMenuWidth
        customContentWidth: CcMetrics.configMenuWidth
        keyboardNavigable: true
        transientSurfaceTracker: root.transientSurfaceTracker

        onOpenStateChanged: {
            if (openState)
                return;
            root.widgetIndex = -1;
            if (root._anchor?.visible && root._anchor.enabled)
                root._anchor.forceActiveFocus();
            root._anchor = null;
        }

        customContent: Component {
            CcGroup {
                CcListRow {
                    visible: root.isPlugin
                    iconName: "settings"
                    title: I18n.tr("Plugin settings")
                    clickable: true
                    onClicked: {
                        PopoutService.openSettingsWithTab(SettingsTabs.pluginPrefix + root.widgetId.replace("plugin_", ""));
                        root.close();
                    }
                }

                Repeater {
                    model: root.isUser ? DashRegistry.sheetOptionSpecs("user") : []

                    CcToggleRow {
                        required property var modelData

                        text: modelData.text
                        checked: DashRegistry.optionValue(modelData, root.widgetData?.[modelData.key])
                        onToggled: checked => root.persistOption(modelData.key, checked)
                    }
                }

                SettingsReorderList {
                    id: actionList

                    visible: root.isQuickActions
                    model: root.quickActions
                    onReordered: indices => root.persistOption("actions", indices.map(i => root.quickActions[i]))

                    delegate: SettingsReorderRow {
                        required property var modelData
                        readonly property bool locked: modelData.id === "edit"

                        reorderList: actionList
                        paddingH: CcMetrics.rowPaddingH
                        paddingV: CcMetrics.rowPaddingV
                        rowColor: dragging ? Theme.blend(CcMetrics.rowColor, Theme.onSurface, Theme.stateLayerDrag) : CcMetrics.rowColor
                        iconName: WidgetUtils.quickActionIcon(modelData.id)
                        title: I18n.tr(WidgetUtils.quickActionLabel(modelData.id))
                        clickable: !locked
                        onClicked: root.toggleAction(modelData.id, !modelData.enabled)

                        DankToggle {
                            hideText: true
                            text: parent.title
                            activeFocusOnTab: false
                            checked: modelData.enabled
                            enabled: !locked
                            onToggled: value => root.toggleAction(modelData.id, value)
                        }
                    }
                }

                CcToggleRow {
                    visible: root.isUser || root.isQuickActions
                    text: I18n.tr("Background")
                    checked: root.isUser ? root.widgetData?.background !== false : root.widgetData?.background === true
                    onToggled: checked => root.persistOption("background", checked)
                }

                CcToggleRow {
                    visible: root.isQuickActions && root.widgetData?.background === true
                    text: I18n.tr("Button backgrounds")
                    checked: root.widgetData?.buttonBackgrounds === true
                    onToggled: checked => root.persistOption("buttonBackgrounds", checked)
                }

                CcToggleRow {
                    visible: root.isQuickActions
                    text: I18n.tr("Highlight power", "toggle that gives the control center power button the error color")
                    checked: root.widgetData?.powerAccent === true
                    onToggled: checked => root.persistOption("powerAccent", checked)
                }

                CcToggleRow {
                    visible: root.isDisk
                    text: I18n.tr("Show mount path", "toggle in control center disk usage widget to turn mount path display on or off")
                    checked: root.widgetData?.showMountPath !== false
                    onToggled: checked => root.persistOption("showMountPath", checked)
                }

                CcListRow {
                    visible: root.isIdleInhibitor
                    iconName: "timer"
                    title: I18n.tr("Duration")
                    body: DankDropdown {
                        readonly property var presets: IdleInhibitPresets.presetOptions

                        compactMode: true
                        dropdownWidth: parent.width
                        transientSurfaceTracker: contextMenu.transientSurfaceTracker
                        currentValue: presets.find(p => p.minutes === (root.widgetData?.durationMinutes ?? 0))?.label ?? ""
                        options: presets.map(p => p.label)
                        onValueChanged: value => {
                            const preset = presets.find(p => p.label === value);
                            if (preset)
                                root.persistOption("durationMinutes", preset.minutes);
                        }
                    }
                }
            }
        }
    }
}
