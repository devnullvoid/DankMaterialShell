pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Modules.ControlCenter
import qs.Widgets
import "../utils/widgets.js" as WidgetUtils

DankBottomSheet {
    id: root

    property var widgets: []
    readonly property string query: searchField.text.trim()
    readonly property var matches: WidgetUtils.filterWidgets(widgets, query)
    readonly property var categories: [
        {
            "id": "user",
            "title": I18n.tr("User")
        },
        {
            "id": "network",
            "title": I18n.tr("Network")
        },
        {
            "id": "audio",
            "title": I18n.tr("Audio")
        },
        {
            "id": "display",
            "title": I18n.tr("Display")
        },
        {
            "id": "system",
            "title": I18n.tr("System")
        },
        {
            "id": "plugins",
            "title": I18n.tr("Plugins")
        }
    ]
    readonly property var shownCategories: categories.filter(category => widgets.some(widget => (widget.category ?? "plugins") === category.id))

    signal chosen(string widgetId)
    signal clearRequested

    title: I18n.tr("Widgets")
    initialFocusItem: searchField

    onOpenedChanged: {
        if (opened)
            searchField.text = "";
    }

    headerActions: [
        DankActionButton {
            buttonSize: Theme.buttonHeightS
            iconName: "clear_all"
            iconColor: Theme.error
            tooltipText: I18n.tr("Clear All")
            onClicked: root.clearRequested()
        }
    ]

    component PreviewGrid: Grid {
        id: grid

        property var entries: []

        signal chosen(string widgetId)

        columns: Math.max(1, Math.floor((width + spacing) / (CcMetrics.previewMinWidth + spacing)))
        spacing: Theme.spacingS

        Repeater {
            model: grid.entries

            StyledButton {
                id: preview

                required property var modelData
                readonly property bool isUser: modelData.id === "user"
                readonly property bool available: modelData.enabled !== false

                width: (grid.width - grid.spacing * (grid.columns - 1)) / grid.columns
                height: CcMetrics.previewTileHeight + Theme.spacingXS + label.implicitHeight + Theme.spacingS * 2
                radius: Theme.cornerRadiusL
                Accessible.name: modelData.text
                Accessible.description: modelData.warning ?? modelData.description ?? ""
                onClicked: {
                    if (!available)
                        return;
                    grid.chosen(modelData.id);
                }

                Rectangle {
                    id: miniTile
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Theme.spacingS
                    width: preview.isUser ? height : parent.width - Theme.spacingS * 2
                    height: CcMetrics.previewTileHeight
                    radius: Theme.fullRadius(width, height)
                    color: preview.available ? CcMetrics.tileInactiveColor : Theme.onSurface_12
                    border.width: Theme.layerOutlineWidth
                    border.color: Theme.outlineMedium

                    DankIcon {
                        anchors.centerIn: parent
                        name: preview.modelData.icon
                        size: CcMetrics.iconBoxIconSize
                        color: preview.available ? CcMetrics.tileInactiveIcon : Theme.onSurface_38
                    }
                }

                StyledText {
                    id: label
                    anchors.top: miniTile.bottom
                    anchors.topMargin: Theme.spacingXS
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - Theme.spacingXS * 2
                    text: preview.modelData.text
                    font.pixelSize: Theme.fontSizeSmall
                    color: preview.available ? Theme.surfaceText : Theme.onSurface_38
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                FocusRing {
                    visible: preview.visualFocus
                }

                StateLayer {
                    control: preview
                    tooltipText: preview.modelData.warning ?? ""
                }
            }
        }
    }

    DankSearchField {
        id: searchField
        width: parent.width
        height: Theme.fieldHeightLarge
        placeholderText: I18n.tr("Search widgets...")
        onAccepted: {
            const first = root.matches.find(widget => widget.enabled !== false);
            if (first)
                root.chosen(first.id);
        }
    }

    Repeater {
        model: root.query === "" ? root.shownCategories : []

        DankCollapsibleSection {
            id: section

            required property var modelData
            required property int index

            width: parent?.width ?? 0
            title: modelData.title
            expanded: index === 0

            PreviewGrid {
                Layout.fillWidth: true
                entries: root.widgets.filter(widget => (widget.category ?? "plugins") === section.modelData.id)
                onChosen: widgetId => root.chosen(widgetId)
            }
        }
    }

    PreviewGrid {
        width: parent.width
        visible: root.query !== ""
        entries: root.query !== "" ? root.matches : []
        onChosen: widgetId => root.chosen(widgetId)
    }

    StyledText {
        width: parent.width
        visible: root.matches.length === 0
        topPadding: Theme.spacingL
        bottomPadding: Theme.spacingL
        text: I18n.tr("No widgets available")
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.surfaceVariantText
        horizontalAlignment: Text.AlignHCenter
    }
}
