import QtQuick
import Quickshell
import qs.Common
import qs.Widgets

Item {
    id: clipboardContent

    required property var modal
    required property var clearConfirmDialog

    property alias searchField: searchField
    property alias clipboardListView: clipboardListView

    anchors.fill: parent

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingL
        spacing: Theme.spacingL
        focus: false

        ClipboardHeader {
            id: header
            width: parent.width
            totalCount: modal.totalCount
            showKeyboardHints: modal.showKeyboardHints
            onKeyboardHintsToggled: modal.showKeyboardHints = !modal.showKeyboardHints
            onClearAllClicked: {
                clearConfirmDialog.show(I18n.tr("Clear All History?"), I18n.tr("This will permanently delete all clipboard history."), function () {
                    modal.clearAll();
                    modal.hide();
                }, function () {});
            }
            onCloseClicked: modal.hide()
        }

        DankTextField {
            id: searchField
            width: parent.width
            placeholderText: ""
            leftIconName: "search"
            showClearButton: true
            focus: true
            ignoreTabKeys: true
            keyForwardTargets: [modal.modalFocusScope]
            onTextChanged: {
                modal.searchText = text;
                modal.updateFilteredModel();
            }
            Keys.onEscapePressed: function (event) {
                modal.hide();
                event.accepted = true;
            }
            Component.onCompleted: {
                Qt.callLater(function () {
                    forceActiveFocus();
                });
            }

            Connections {
                target: modal
                function onOpened() {
                    Qt.callLater(function () {
                        searchField.forceActiveFocus();
                    });
                }
            }
        }

        Rectangle {
            width: parent.width
            height: parent.height - ClipboardConstants.headerHeight - 70
            radius: Theme.cornerRadius
            color: "transparent"
            clip: true

            DankListView {
                id: clipboardListView
                anchors.fill: parent
                model: ScriptModel {
                    values: clipboardContent.modal.clipboardEntries
                    objectProp: "id"
                }

                currentIndex: clipboardContent.modal ? clipboardContent.modal.selectedIndex : 0
                spacing: Theme.spacingXS
                interactive: true
                flickDeceleration: 1500
                maximumFlickVelocity: 2000
                boundsBehavior: Flickable.DragAndOvershootBounds
                boundsMovement: Flickable.FollowBoundsBehavior
                pressDelay: 0
                flickableDirection: Flickable.VerticalFlick

                function ensureVisible(index) {
                    if (index < 0 || index >= count) {
                        return;
                    }
                    const itemHeight = ClipboardConstants.itemHeight + spacing;
                    const itemY = index * itemHeight;
                    const itemBottom = itemY + itemHeight;
                    if (itemY < contentY) {
                        contentY = itemY;
                    } else if (itemBottom > contentY + height) {
                        contentY = itemBottom - height;
                    }
                }

                onCurrentIndexChanged: {
                    if (clipboardContent.modal?.keyboardNavigationActive && currentIndex >= 0) {
                        ensureVisible(currentIndex);
                    }
                }

                StyledText {
                    text: I18n.tr("No clipboard entries found")
                    anchors.centerIn: parent
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                    visible: clipboardContent.modal.clipboardEntries.length === 0
                }

                delegate: ClipboardEntry {
                    required property int index
                    required property var modelData

                    width: clipboardListView.width
                    height: ClipboardConstants.itemHeight
                    entry: modelData
                    entryIndex: index + 1
                    itemIndex: index
                    isSelected: clipboardContent.modal?.keyboardNavigationActive && index === clipboardContent.modal.selectedIndex
                    modal: clipboardContent.modal
                    listView: clipboardListView
                    onCopyRequested: clipboardContent.modal.copyEntry(modelData)
                    onDeleteRequested: clipboardContent.modal.deleteEntry(modelData)
                }
            }
        }

        Item {
            width: parent.width
            height: modal.showKeyboardHints ? ClipboardConstants.keyboardHintsHeight + Theme.spacingL : 0

            Behavior on height {
                NumberAnimation {
                    duration: Theme.shortDuration
                    easing.type: Theme.standardEasing
                }
            }
        }
    }

    ClipboardKeyboardHints {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacingL
        visible: modal.showKeyboardHints
    }
}
