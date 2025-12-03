pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root

    property var bindData: ({})
    property bool isExpanded: false
    property var panelWindow: null
    property bool recording: false
    property bool isNew: false

    property int editingKeyIndex: -1
    property string editKey: ""
    property string editAction: ""
    property string editDesc: ""
    property bool hasChanges: false
    property string _actionType: ""
    property bool addingNewKey: false
    property bool useCustomCompositor: false

    readonly property var keys: bindData.keys || []
    readonly property bool hasOverride: {
        for (let i = 0; i < keys.length; i++) {
            if (keys[i].isOverride)
                return true;
        }
        return false;
    }
    readonly property string _originalKey: editingKeyIndex >= 0 && editingKeyIndex < keys.length ? keys[editingKeyIndex].key : ""

    signal toggleExpand
    signal saveBind(string originalKey, var newData)
    signal removeBind(string key)
    signal cancelEdit

    implicitHeight: contentColumn.implicitHeight
    height: implicitHeight

    onIsExpandedChanged: {
        if (isExpanded)
            resetEdits();
    }

    onEditActionChanged: {
        _actionType = KeybindsService.getActionType(editAction);
    }

    function resetEdits() {
        addingNewKey = false;
        editingKeyIndex = keys.length > 0 ? 0 : -1;
        editKey = editingKeyIndex >= 0 ? keys[editingKeyIndex].key : "";
        editAction = bindData.action || "";
        editDesc = bindData.desc || "";
        hasChanges = false;
        _actionType = KeybindsService.getActionType(editAction);
        useCustomCompositor = _actionType === "compositor" && !isKnownCompositorAction(editAction);
    }

    function isKnownCompositorAction(action) {
        if (!action)
            return false;
        const cats = KeybindsService.getCompositorCategories();
        for (const cat of cats) {
            const actions = KeybindsService.getCompositorActions(cat);
            for (const act of actions) {
                if (act.id === action)
                    return true;
            }
        }
        return false;
    }

    function startAddingNewKey() {
        addingNewKey = true;
        editingKeyIndex = -1;
        editKey = "";
        hasChanges = true;
    }

    function selectKeyForEdit(index) {
        if (index < 0 || index >= keys.length)
            return;
        addingNewKey = false;
        editingKeyIndex = index;
        editKey = keys[index].key;
        hasChanges = false;
    }

    function updateEdit(changes) {
        if (changes.key !== undefined)
            editKey = changes.key;
        if (changes.action !== undefined)
            editAction = changes.action;
        if (changes.desc !== undefined)
            editDesc = changes.desc;
        const origKey = editingKeyIndex >= 0 && editingKeyIndex < keys.length ? keys[editingKeyIndex].key : "";
        hasChanges = editKey !== origKey || editAction !== (bindData.action || "") || editDesc !== (bindData.desc || "");
    }

    function canSave() {
        if (!editKey)
            return false;
        if (!KeybindsService.isValidAction(editAction))
            return false;
        return true;
    }

    function doSave() {
        if (!canSave())
            return;
        const origKey = addingNewKey ? "" : _originalKey;
        let desc = editDesc;
        if (expandedLoader.item?.currentTitle !== undefined)
            desc = expandedLoader.item.currentTitle;
        saveBind(origKey, {
            key: editKey,
            action: editAction,
            desc: desc
        });
        hasChanges = false;
        addingNewKey = false;
    }

    function startRecording() {
        recording = true;
    }

    function stopRecording() {
        recording = false;
    }

    function modsFromEvent(mods) {
        const result = [];
        if (mods & Qt.ControlModifier)
            result.push("Ctrl");
        if (mods & Qt.ShiftModifier)
            result.push("Shift");
        const hasAlt = mods & Qt.AltModifier;
        const hasSuper = mods & Qt.MetaModifier;
        if (hasAlt && hasSuper) {
            result.push("Mod");
        } else {
            if (hasAlt)
                result.push("Alt");
            if (hasSuper)
                result.push("Super");
        }
        return result;
    }

    function normalizeKeyCombo(keyCombo) {
        return keyCombo.toLowerCase().replace(/\bmod\b/g, "super").replace(/\bsuper\b/g, "super");
    }

    function getConflictingBinds(keyCombo) {
        if (!keyCombo)
            return [];
        const conflicts = [];
        const allBinds = KeybindsService.getFlatBinds();
        const normalizedKey = normalizeKeyCombo(keyCombo);
        for (let i = 0; i < allBinds.length; i++) {
            const bind = allBinds[i];
            if (bind.action === bindData.action)
                continue;
            for (let k = 0; k < bind.keys.length; k++) {
                if (normalizeKeyCombo(bind.keys[k].key) === normalizedKey) {
                    conflicts.push({
                        action: bind.action,
                        desc: bind.desc || bind.action
                    });
                    break;
                }
            }
        }
        return conflicts;
    }

    readonly property var _conflicts: editKey ? getConflictingBinds(editKey) : []
    readonly property bool hasConflict: _conflicts.length > 0

    readonly property var _keyMap: ({
            [Qt.Key_Left]: "Left",
            [Qt.Key_Right]: "Right",
            [Qt.Key_Up]: "Up",
            [Qt.Key_Down]: "Down",
            [Qt.Key_Comma]: "Comma",
            [Qt.Key_Period]: "Period",
            [Qt.Key_Slash]: "Slash",
            [Qt.Key_Semicolon]: "Semicolon",
            [Qt.Key_Apostrophe]: "Apostrophe",
            [Qt.Key_BracketLeft]: "BracketLeft",
            [Qt.Key_BracketRight]: "BracketRight",
            [Qt.Key_Backslash]: "Backslash",
            [Qt.Key_Minus]: "Minus",
            [Qt.Key_Equal]: "Equal",
            [Qt.Key_QuoteLeft]: "grave",
            [Qt.Key_Space]: "space",
            [Qt.Key_Print]: "Print",
            [Qt.Key_Return]: "Return",
            [Qt.Key_Enter]: "Return",
            [Qt.Key_Tab]: "Tab",
            [Qt.Key_Backspace]: "BackSpace",
            [Qt.Key_Delete]: "Delete",
            [Qt.Key_Insert]: "Insert",
            [Qt.Key_Home]: "Home",
            [Qt.Key_End]: "End",
            [Qt.Key_PageUp]: "Page_Up",
            [Qt.Key_PageDown]: "Page_Down",
            [Qt.Key_Escape]: "Escape",
            [Qt.Key_CapsLock]: "Caps_Lock",
            [Qt.Key_NumLock]: "Num_Lock",
            [Qt.Key_ScrollLock]: "Scroll_Lock",
            [Qt.Key_Pause]: "Pause",
            [Qt.Key_VolumeUp]: "XF86AudioRaiseVolume",
            [Qt.Key_VolumeDown]: "XF86AudioLowerVolume",
            [Qt.Key_VolumeMute]: "XF86AudioMute",
            [Qt.Key_MicMute]: "XF86AudioMicMute",
            [Qt.Key_MediaPlay]: "XF86AudioPlay",
            [Qt.Key_MediaPause]: "XF86AudioPause",
            [Qt.Key_MediaStop]: "XF86AudioStop",
            [Qt.Key_MediaNext]: "XF86AudioNext",
            [Qt.Key_MediaPrevious]: "XF86AudioPrev",
            [Qt.Key_MediaRecord]: "XF86AudioRecord",
            [Qt.Key_MonBrightnessUp]: "XF86MonBrightnessUp",
            [Qt.Key_MonBrightnessDown]: "XF86MonBrightnessDown",
            [Qt.Key_KeyboardBrightnessUp]: "XF86KbdBrightnessUp",
            [Qt.Key_KeyboardBrightnessDown]: "XF86KbdBrightnessDown",
            [Qt.Key_PowerOff]: "XF86PowerOff",
            [Qt.Key_Sleep]: "XF86Sleep",
            [Qt.Key_WakeUp]: "XF86WakeUp",
            [Qt.Key_Eject]: "XF86Eject",
            [Qt.Key_Calculator]: "XF86Calculator",
            [Qt.Key_Explorer]: "XF86Explorer",
            [Qt.Key_HomePage]: "XF86HomePage",
            [Qt.Key_Search]: "XF86Search",
            [Qt.Key_LaunchMail]: "XF86Mail",
            [Qt.Key_Launch0]: "XF86Launch0",
            [Qt.Key_Launch1]: "XF86Launch1",
            [Qt.Key_Exclam]: "1",
            [Qt.Key_At]: "2",
            [Qt.Key_NumberSign]: "3",
            [Qt.Key_Dollar]: "4",
            [Qt.Key_Percent]: "5",
            [Qt.Key_AsciiCircum]: "6",
            [Qt.Key_Ampersand]: "7",
            [Qt.Key_Asterisk]: "8",
            [Qt.Key_ParenLeft]: "9",
            [Qt.Key_ParenRight]: "0",
            [Qt.Key_Less]: "Comma",
            [Qt.Key_Greater]: "Period",
            [Qt.Key_Question]: "Slash",
            [Qt.Key_Colon]: "Semicolon",
            [Qt.Key_QuoteDbl]: "Apostrophe",
            [Qt.Key_BraceLeft]: "BracketLeft",
            [Qt.Key_BraceRight]: "BracketRight",
            [Qt.Key_Bar]: "Backslash",
            [Qt.Key_Underscore]: "Minus",
            [Qt.Key_Plus]: "Equal",
            [Qt.Key_AsciiTilde]: "grave"
        })

    function xkbKeyFromQtKey(qk) {
        if (qk >= Qt.Key_A && qk <= Qt.Key_Z)
            return String.fromCharCode(qk);
        if (qk >= Qt.Key_0 && qk <= Qt.Key_9)
            return String.fromCharCode(qk);
        if (qk >= Qt.Key_F1 && qk <= Qt.Key_F35)
            return "F" + (qk - Qt.Key_F1 + 1);
        return _keyMap[qk] || "";
    }

    function formatToken(mods, key) {
        return (mods.length ? mods.join("+") + "+" : "") + key;
    }

    Column {
        id: contentColumn
        width: parent.width
        spacing: 0

        Rectangle {
            id: collapsedRect
            width: parent.width
            height: Math.max(52, keysColumn.implicitHeight + Theme.spacingM * 2)
            radius: root.isExpanded ? 0 : Theme.cornerRadius
            topLeftRadius: Theme.cornerRadius
            topRightRadius: Theme.cornerRadius
            color: root.hasOverride ? Theme.surfaceContainer : Theme.surfaceContainerHighest
            border.color: root.hasOverride ? Theme.outlineVariant : "transparent"
            border.width: root.hasOverride ? 1 : 0

            RowLayout {
                id: collapsedContent
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingM
                anchors.rightMargin: Theme.spacingM
                spacing: Theme.spacingM

                Column {
                    id: keysColumn
                    Layout.preferredWidth: 140
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Theme.spacingXS

                    Repeater {
                        model: root.keys

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            property bool isSelected: root.isExpanded && root.editingKeyIndex === index && !root.addingNewKey

                            width: 140
                            height: 28
                            radius: 6
                            color: isSelected ? Theme.primary : Theme.surfaceVariant

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: chipArea.pressed ? Theme.surfaceTextHover : (chipArea.containsMouse ? Theme.surfaceTextHover : "transparent")
                            }

                            StyledText {
                                id: keyChipText
                                text: modelData.key
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: isSelected ? Font.Medium : Font.Normal
                                isMonospace: true
                                color: isSelected ? Theme.primaryText : Theme.surfaceVariantText
                                anchors.centerIn: parent
                                width: parent.width - Theme.spacingS
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                id: chipArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectKeyForEdit(index);
                                    if (!root.isExpanded)
                                        root.toggleExpand();
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    StyledText {
                        text: root.bindData.desc || root.bindData.action || I18n.tr("No action")
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: Theme.spacingS
                        Layout.fillWidth: true

                        StyledText {
                            text: root.bindData.category || ""
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            visible: text.length > 0
                        }

                        Rectangle {
                            width: 4
                            height: 4
                            radius: 2
                            color: Theme.surfaceVariantText
                            visible: root.hasOverride && (root.bindData.category ?? "")
                        }

                        StyledText {
                            text: I18n.tr("Override")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.primary
                            visible: root.hasOverride
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }

                DankIcon {
                    name: root.isExpanded ? "expand_less" : "expand_more"
                    size: 20
                    color: Theme.surfaceVariantText
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.leftMargin: 140 + Theme.spacingM * 2
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleExpand()
            }
        }

        Loader {
            id: expandedLoader
            width: parent.width
            active: root.isExpanded
            visible: status === Loader.Ready
            asynchronous: true
            sourceComponent: expandedComponent
        }
    }

    Component {
        id: expandedComponent

        Rectangle {
            id: expandedRect
            width: parent ? parent.width : 0
            height: expandedContent.implicitHeight + Theme.spacingL * 2
            color: Theme.surfaceContainerHigh
            border.color: root.hasOverride ? Theme.outlineVariant : "transparent"
            border.width: root.hasOverride ? 1 : 0
            bottomLeftRadius: Theme.cornerRadius
            bottomRightRadius: Theme.cornerRadius

            property alias currentTitle: titleField.text

            ShortcutInhibitor {
                id: shortcutInhibitor
                enabled: root.recording
                window: root.panelWindow
            }

            ColumnLayout {
                id: expandedContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM
                    visible: root.keys.length > 1 || root.addingNewKey

                    StyledText {
                        text: I18n.tr("Keys")
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceVariantText
                        Layout.preferredWidth: 60
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: Theme.spacingXS

                        Repeater {
                            model: root.keys

                            delegate: Rectangle {
                                required property var modelData
                                required property int index

                                property bool isSelected: root.editingKeyIndex === index && !root.addingNewKey

                                width: editKeyChipText.implicitWidth + Theme.spacingM
                                height: 28
                                radius: 6
                                color: isSelected ? Theme.primary : Theme.surfaceVariant

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: editKeyChipArea.pressed ? Theme.surfaceTextHover : (editKeyChipArea.containsMouse && !isSelected ? Theme.surfaceTextHover : "transparent")
                                }

                                StyledText {
                                    id: editKeyChipText
                                    text: modelData.key
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: isSelected ? Font.Medium : Font.Normal
                                    isMonospace: true
                                    color: isSelected ? Theme.primaryText : Theme.surfaceVariantText
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: editKeyChipArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectKeyForEdit(index)
                                }
                            }
                        }

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 6
                            color: root.addingNewKey ? Theme.primary : Theme.surfaceVariant
                            visible: !root.isNew

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: addKeyArea.pressed ? Theme.surfaceTextHover : (addKeyArea.containsMouse && !root.addingNewKey ? Theme.surfaceTextHover : "transparent")
                            }

                            DankIcon {
                                name: "add"
                                size: 16
                                color: root.addingNewKey ? Theme.primaryText : Theme.surfaceVariantText
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: addKeyArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.startAddingNewKey()
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM

                    StyledText {
                        text: root.addingNewKey ? I18n.tr("New Key") : I18n.tr("Key")
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceVariantText
                        Layout.preferredWidth: 60
                    }

                    FocusScope {
                        id: captureScope
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        focus: root.recording

                        Component.onCompleted: {
                            if (root.recording)
                                forceActiveFocus();
                        }

                        Connections {
                            target: root
                            function onRecordingChanged() {
                                if (root.recording)
                                    captureScope.forceActiveFocus();
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.cornerRadius
                            color: root.recording ? Theme.primaryContainer : Theme.surfaceContainer
                            border.color: root.recording ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
                            border.width: root.recording ? 2 : 1

                            Row {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Theme.spacingS
                                spacing: Theme.spacingS

                                StyledText {
                                    text: root.editKey || (root.recording ? I18n.tr("Press key...") : I18n.tr("Click to capture"))
                                    font.pixelSize: Theme.fontSizeMedium
                                    isMonospace: root.editKey ? true : false
                                    color: root.editKey ? Theme.surfaceText : Theme.surfaceVariantText
                                    width: parent.width - recordBtn.width - parent.spacing
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                }

                                DankActionButton {
                                    id: recordBtn
                                    width: 28
                                    height: 28
                                    anchors.verticalCenter: parent.verticalCenter
                                    circular: false
                                    iconName: root.recording ? "close" : "radio_button_checked"
                                    iconSize: 16
                                    iconColor: root.recording ? Theme.error : Theme.primary
                                    onClicked: root.recording ? root.stopRecording() : root.startRecording()
                                }
                            }
                        }

                        Keys.onPressed: event => {
                            if (!root.recording)
                                return;
                            if (event.key === Qt.Key_Escape) {
                                root.stopRecording();
                                event.accepted = true;
                                return;
                            }

                            switch (event.key) {
                            case Qt.Key_Control:
                            case Qt.Key_Shift:
                            case Qt.Key_Alt:
                            case Qt.Key_Meta:
                                event.accepted = true;
                                return;
                            }

                            const mods = [];
                            if (event.modifiers & Qt.ControlModifier)
                                mods.push("Ctrl");
                            if (event.modifiers & Qt.ShiftModifier)
                                mods.push("Shift");
                            if ((event.modifiers & Qt.AltModifier) && (event.modifiers & Qt.MetaModifier)) {
                                mods.push("Mod");
                            } else {
                                if (event.modifiers & Qt.AltModifier)
                                    mods.push("Alt");
                                if (event.modifiers & Qt.MetaModifier)
                                    mods.push("Super");
                            }

                            const key = root.xkbKeyFromQtKey(event.key);
                            if (key) {
                                root.updateEdit({
                                    key: root.formatToken(mods, key)
                                });
                                root.stopRecording();
                                event.accepted = true;
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.recording
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.startRecording()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: Theme.cornerRadius
                        color: root.addingNewKey ? Theme.primary : Theme.surfaceVariant
                        visible: root.keys.length === 1 && !root.isNew

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: singleAddKeyArea.pressed ? Theme.surfaceTextHover : (singleAddKeyArea.containsMouse && !root.addingNewKey ? Theme.surfaceTextHover : "transparent")
                        }

                        DankIcon {
                            name: "add"
                            size: 18
                            color: root.addingNewKey ? Theme.primaryText : Theme.surfaceVariantText
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: singleAddKeyArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.startAddingNewKey()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingS
                    visible: root.hasConflict
                    Layout.leftMargin: 60 + Theme.spacingM

                    DankIcon {
                        name: "warning"
                        size: 16
                        color: Theme.warning
                    }

                    StyledText {
                        text: I18n.tr("Conflicts with: %1").arg(root._conflicts.map(c => c.desc).join(", "))
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.warning
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM

                    StyledText {
                        text: I18n.tr("Type")
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceVariantText
                        Layout.preferredWidth: 60
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingS

                        Repeater {
                            model: KeybindsService.actionTypes

                            delegate: Rectangle {
                                id: typeDelegate
                                required property var modelData
                                required property int index

                                readonly property var tooltipTexts: ({
                                        "dms": I18n.tr("DMS shell actions (launcher, clipboard, etc.)"),
                                        "compositor": I18n.tr("Niri compositor actions (focus, move, etc.)"),
                                        "spawn": I18n.tr("Run a program (e.g., firefox, kitty)"),
                                        "shell": I18n.tr("Run a shell command (e.g., notify-send)")
                                    })

                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: Theme.cornerRadius
                                color: root._actionType === modelData.id ? Theme.surfaceContainerHighest : Theme.surfaceContainer
                                border.color: root._actionType === modelData.id ? Theme.outline : (typeArea.containsMouse ? Theme.outlineVariant : "transparent")
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingXS

                                    DankIcon {
                                        name: typeDelegate.modelData.icon
                                        size: 16
                                        color: root._actionType === typeDelegate.modelData.id ? Theme.surfaceText : Theme.surfaceVariantText
                                    }

                                    StyledText {
                                        text: typeDelegate.modelData.label
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: root._actionType === typeDelegate.modelData.id ? Theme.surfaceText : Theme.surfaceVariantText
                                        visible: typeDelegate.width > 100
                                    }
                                }

                                MouseArea {
                                    id: typeArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeDelegate.modelData.id === "dms") {
                                            root.updateEdit({
                                                action: KeybindsService.dmsActions[0].id,
                                                desc: KeybindsService.dmsActions[0].label
                                            });
                                        } else if (typeDelegate.modelData.id === "compositor") {
                                            root.updateEdit({
                                                action: "close-window",
                                                desc: "Close Window"
                                            });
                                        } else if (typeDelegate.modelData.id === "spawn") {
                                            root.updateEdit({
                                                action: "spawn ",
                                                desc: ""
                                            });
                                        } else if (typeDelegate.modelData.id === "shell") {
                                            root.updateEdit({
                                                action: "spawn sh -c \"\"",
                                                desc: ""
                                            });
                                        }
                                    }
                                    onContainsMouseChanged: {
                                        if (containsMouse) {
                                            typeTooltip.show(typeDelegate.tooltipTexts[typeDelegate.modelData.id], typeDelegate, 0, 0, "bottom");
                                        } else {
                                            typeTooltip.hide();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    DankTooltipV2 {
                        id: typeTooltip
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM
                    visible: root._actionType === "dms"

                    StyledText {
                        text: I18n.tr("Action")
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceVariantText
                        Layout.preferredWidth: 60
                    }

                    DankDropdown {
                        Layout.fillWidth: true
                        compactMode: true
                        currentValue: KeybindsService.getActionLabel(root.editAction) || I18n.tr("Select...")
                        options: KeybindsService.getDmsActions().map(a => a.label)
                        enableFuzzySearch: true
                        maxPopupHeight: 300
                        onValueChanged: value => {
                            const actions = KeybindsService.getDmsActions();
                            for (const act of actions) {
                                if (act.label === value) {
                                    root.updateEdit({
                                        action: act.id,
                                        desc: act.label
                                    });
                                    return;
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM
                    visible: root._actionType === "compositor" && !root.useCustomCompositor

                    StyledText {
                        text: I18n.tr("Action")
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceVariantText
                        Layout.preferredWidth: 60
                    }

                    DankDropdown {
                        id: compositorCatDropdown
                        Layout.preferredWidth: 120
                        compactMode: true
                        currentValue: {
                            const action = root.editAction;
                            const cats = KeybindsService.getCompositorCategories();
                            for (const cat of cats) {
                                const actions = KeybindsService.getCompositorActions(cat);
                                for (const act of actions) {
                                    if (act.id === action)
                                        return cat;
                                }
                            }
                            return cats[0] || "Window";
                        }
                        options: KeybindsService.getCompositorCategories()
                    }

                    DankDropdown {
                        Layout.fillWidth: true
                        compactMode: true
                        currentValue: KeybindsService.getActionLabel(root.editAction) || I18n.tr("Select...")
                        options: KeybindsService.getCompositorActions(compositorCatDropdown.currentValue).map(a => a.label)
                        enableFuzzySearch: true
                        maxPopupHeight: 300
                        onValueChanged: value => {
                            const actions = KeybindsService.getCompositorActions(compositorCatDropdown.currentValue);
                            for (const act of actions) {
                                if (act.label === value) {
                                    root.updateEdit({
                                        action: act.id,
                                        desc: act.label
                                    });
                                    return;
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: Theme.cornerRadius
                        color: Theme.surfaceVariant

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: customToggleArea.pressed ? Theme.surfaceTextHover : (customToggleArea.containsMouse ? Theme.surfaceTextHover : "transparent")
                        }

                        DankIcon {
                            name: "edit"
                            size: 18
                            color: Theme.surfaceVariantText
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: customToggleArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.useCustomCompositor = true
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM
                    visible: root._actionType === "compositor" && root.useCustomCompositor

                    StyledText {
                        text: I18n.tr("Custom")
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceVariantText
                        Layout.preferredWidth: 60
                    }

                    DankTextField {
                        id: customCompositorField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        placeholderText: I18n.tr("e.g., focus-workspace 3, resize-column -10")
                        text: root._actionType === "compositor" ? root.editAction : ""
                        onEditingFinished: {
                            if (root._actionType !== "compositor")
                                return;
                            if (text.trim())
                                root.updateEdit({
                                    action: text.trim()
                                });
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: Theme.cornerRadius
                        color: Theme.surfaceVariant

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: presetToggleArea.pressed ? Theme.surfaceTextHover : (presetToggleArea.containsMouse ? Theme.surfaceTextHover : "transparent")
                        }

                        DankIcon {
                            name: "list"
                            size: 18
                            color: Theme.surfaceVariantText
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: presetToggleArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.useCustomCompositor = false;
                                root.updateEdit({
                                    action: "close-window",
                                    desc: "Close Window"
                                });
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM
                    visible: root._actionType === "spawn"

                    StyledText {
                        text: I18n.tr("Command")
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceVariantText
                        Layout.preferredWidth: 60
                    }

                    DankTextField {
                        id: spawnTextField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        placeholderText: I18n.tr("e.g., firefox, kitty --title foo")
                        readonly property var _parsed: root._actionType === "spawn" ? KeybindsService.parseSpawnCommand(root.editAction) : null
                        text: _parsed ? (_parsed.command + " " + _parsed.args.join(" ")).trim() : ""
                        onEditingFinished: {
                            if (root._actionType !== "spawn")
                                return;
                            const parts = text.trim().split(" ").filter(p => p);
                            if (parts.length === 0)
                                return;
                            const changes = {
                                action: "spawn " + parts.join(" ")
                            };
                            if (!root.editDesc)
                                changes.desc = parts[0];
                            root.updateEdit(changes);
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM
                    visible: root._actionType === "shell"

                    StyledText {
                        text: I18n.tr("Shell")
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceVariantText
                        Layout.preferredWidth: 60
                    }

                    DankTextField {
                        id: shellTextField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        placeholderText: I18n.tr("e.g., notify-send 'Hello' && sleep 1")
                        text: root._actionType === "shell" ? KeybindsService.parseShellCommand(root.editAction) : ""
                        onEditingFinished: {
                            if (root._actionType !== "shell")
                                return;
                            if (text.trim()) {
                                root.updateEdit({
                                    action: KeybindsService.buildShellAction(text.trim())
                                });
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM

                    StyledText {
                        text: I18n.tr("Title")
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceVariantText
                        Layout.preferredWidth: 60
                    }

                    DankTextField {
                        id: titleField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        placeholderText: I18n.tr("Hotkey overlay title (optional)")
                        text: root.editDesc
                        onEditingFinished: root.updateEdit({
                            desc: text
                        })
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM

                    DankActionButton {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        circular: false
                        iconName: "delete"
                        iconSize: Theme.iconSize - 4
                        iconColor: Theme.error
                        visible: root.editingKeyIndex >= 0 && root.editingKeyIndex < root.keys.length && root.keys[root.editingKeyIndex].isOverride && !root.isNew
                        onClicked: root.removeBind(root._originalKey)
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: !root.canSave() ? I18n.tr("Set key and action to save") : (root.hasChanges ? I18n.tr("Unsaved changes") : I18n.tr("No changes"))
                        font.pixelSize: Theme.fontSizeSmall
                        color: root.hasChanges ? Theme.surfaceText : Theme.surfaceVariantText
                        visible: !root.isNew
                    }

                    DankButton {
                        text: I18n.tr("Cancel")
                        buttonHeight: 32
                        backgroundColor: Theme.surfaceContainer
                        textColor: Theme.surfaceText
                        visible: root.hasChanges || root.isNew
                        onClicked: {
                            if (root.isNew) {
                                root.cancelEdit();
                            } else {
                                root.resetEdits();
                                root.toggleExpand();
                            }
                        }
                    }

                    DankButton {
                        text: root.isNew ? I18n.tr("Add") : I18n.tr("Save")
                        buttonHeight: 32
                        enabled: root.canSave()
                        visible: root.hasChanges || root.isNew
                        onClicked: root.doSave()
                    }
                }
            }
        }
    }
}
