import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import qs.Common
import qs.Modals
import qs.Services
import qs.Widgets
pragma ComponentBehavior

Item {
    id: root

    property string passwordBuffer: ""
    property bool demoMode: false
    property bool unlocking: false
    property var powerModal: null
    property string confirmAction: ""
    property var facts: ["Light takes 100,000 years to escape the Sun's core, then just 8 minutes to reach us.", "A teaspoon of neutron star matter would weigh a billion tons here on Earth.", "Right now, 100 trillion solar neutrinos are passing through your body every second.", "The Sun burns 4 million tons of itself into pure energy every second.", "The universe still glows with leftover heat from the Big Bang—just 2.7 degrees above absolute zero.", "There's a nebula out there that's actually colder than empty space itself.", "We've detected black holes crashing together by measuring spacetime stretch by less than 1/10,000th the width of a proton.", "Some cosmic radio bursts release more energy in milliseconds than our Sun does in days.", "Our galaxy might be crawling with billions of rogue planets drifting alone in the dark.", "Distant galaxies can move away from us faster than light because space itself is stretching.", "The edge of what we can see is 46.5 billion light-years away, even though the universe is only 13.8 billion years old.", "The universe is mostly invisible: 5% regular matter, 27% dark matter, 68% dark energy.", "A day on Venus lasts longer than its entire year around the Sun.", "On Mercury, the time between sunrises is 176 Earth days long.", "In about 4.5 billion years, our galaxy will smash into Andromeda.", "Most of the gold in your jewelry was forged when neutron stars collided somewhere in space.", "A black hole the mass of our Sun would take longer to evaporate than the current age of the universe... times a trillion trillion trillion trillion trillion.", "The fastest spinning star we know rotates 716 times per second.", "Cosmic rays create particles that shouldn't make it to Earth's surface, but time dilation lets them sneak through.", "Jupiter's magnetic field is so huge that if we could see it, it would look bigger than the Moon in our sky."]
    property string randomFact: ""

    signal unlockRequested()

    function pickRandomFact() {
        randomFact = facts[Math.floor(Math.random() * facts.length)];
    }

    Component.onCompleted: {
        pickRandomFact();
        WeatherService.addRef();
        UserInfoService.refreshUserInfo();
    }
    onDemoModeChanged: {
        if (demoMode)
            pickRandomFact();

    }
    Component.onDestruction: {
        WeatherService.removeRef();
    }

    Image {
        id: wallpaperBackground

        anchors.fill: parent
        source: SessionData.wallpaperPath || ""
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        cache: true
        visible: source !== ""
        layer.enabled: true

        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 0.8
            blurMax: 32
            blurMultiplier: 1
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.standardEasing
            }

        }

    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.4
    }

    SystemClock {
        id: systemClock

        precision: SystemClock.Seconds
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Item {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -100
            width: 400
            height: 140

            StyledText {
                id: clockText

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                text: SettingsData.use24HourClock ? Qt.formatTime(systemClock.date, "H:mm") : Qt.formatTime(systemClock.date, "h:mm AP")
                font.pixelSize: 120
                font.weight: Font.Light
                color: "white"
                lineHeight: 0.8
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: clockText.bottom
                anchors.topMargin: -20
                text: Qt.formatDate(systemClock.date, SettingsData.lockDateFormat)
                font.pixelSize: Theme.fontSizeXLarge
                color: "white"
                opacity: 0.9
            }

        }

        ColumnLayout {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 50
            spacing: Theme.spacingM
            width: 380

            RowLayout {
                spacing: Theme.spacingL
                Layout.fillWidth: true

                Item {
                    id: avatarContainer

                    property bool hasImage: profileImageLoader.status === Image.Ready

                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 60

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.color: Theme.primary
                        border.width: 1
                        visible: parent.hasImage
                    }

                    Image {
                        id: profileImageLoader

                        source: {
                            if (PortalService.profileImage === "")
                                return "";

                            if (PortalService.profileImage.startsWith("/"))
                                return "file://" + PortalService.profileImage;

                            return PortalService.profileImage;
                        }
                        smooth: true
                        asynchronous: true
                        mipmap: true
                        cache: true
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: parent
                        anchors.margins: 5
                        source: profileImageLoader
                        maskEnabled: true
                        maskSource: circularMask
                        visible: avatarContainer.hasImage
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1
                    }

                    Item {
                        id: circularMask

                        width: 60 - 10
                        height: 60 - 10
                        layer.enabled: true
                        layer.smooth: true
                        visible: false

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "black"
                            antialiasing: true
                        }

                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Theme.primary
                        visible: !parent.hasImage

                        DankIcon {
                            anchors.centerIn: parent
                            name: "person"
                            size: Theme.iconSize + 4
                            color: Theme.primaryText
                        }

                    }

                    DankIcon {
                        anchors.centerIn: parent
                        name: "warning"
                        size: Theme.iconSize + 4
                        color: Theme.primaryText
                        visible: PortalService.profileImage !== "" && profileImageLoader.status === Image.Error
                    }

                }

                Rectangle {
                    property bool showPassword: false

                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: Theme.cornerRadius
                    color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.9)
                    border.color: passwordField.activeFocus ? Theme.primary : Qt.rgba(1, 1, 1, 0.3)
                    border.width: passwordField.activeFocus ? 2 : 1

                    DankIcon {
                        id: lockIcon

                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        name: "lock"
                        size: 20
                        color: passwordField.activeFocus ? Theme.primary : Theme.surfaceVariantText
                    }

                    TextInput {
                        id: passwordField

                        anchors.fill: parent
                        anchors.leftMargin: lockIcon.width + Theme.spacingM * 2
                        anchors.rightMargin: (revealButton.visible ? revealButton.width + Theme.spacingM : 0) + (enterButton.visible ? enterButton.width + Theme.spacingM : 0) + (loadingSpinner.visible ? loadingSpinner.width + Theme.spacingM : Theme.spacingM)
                        opacity: 0
                        focus: !demoMode
                        enabled: !demoMode
                        echoMode: parent.showPassword ? TextInput.Normal : TextInput.Password
                        onTextChanged: {
                            if (!demoMode)
                                root.passwordBuffer = text;

                        }
                        onAccepted: {
                            if (!demoMode && root.passwordBuffer.length > 0 && !pam.active) {
                                console.log("Enter pressed, starting PAM authentication");
                                pam.start();
                            }
                        }
                        Keys.onPressed: (event) => {
                            if (demoMode)
                                return ;

                            if (pam.active) {
                                console.log("PAM is active, ignoring input");
                                event.accepted = true;
                                return ;
                            }
                        }

                        Timer {
                            id: focusTimer

                            interval: 100
                            running: !demoMode
                            onTriggered: passwordField.forceActiveFocus()
                        }

                    }

                    StyledText {
                        id: placeholder

                        property string pamState: ""

                        anchors.left: lockIcon.right
                        anchors.leftMargin: Theme.spacingM
                        anchors.right: (revealButton.visible ? revealButton.left : (enterButton.visible ? enterButton.left : (loadingSpinner.visible ? loadingSpinner.left : parent.right)))
                        anchors.rightMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (demoMode)
                                return "";

                            if (root.unlocking)
                                return "Unlocking...";

                            if (pam.active)
                                return "Authenticating...";

                            return "hunter2";
                        }
                        color: root.unlocking ? Theme.primary : (pam.active ? Theme.primary : Theme.outline)
                        font.pixelSize: Theme.fontSizeMedium
                        opacity: (demoMode || root.passwordBuffer.length === 0) ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.mediumDuration
                                easing.type: Theme.standardEasing
                            }

                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.shortDuration
                                easing.type: Theme.standardEasing
                            }

                        }

                    }

                    StyledText {
                        anchors.left: lockIcon.right
                        anchors.leftMargin: Theme.spacingM
                        anchors.right: (revealButton.visible ? revealButton.left : (enterButton.visible ? enterButton.left : (loadingSpinner.visible ? loadingSpinner.left : parent.right)))
                        anchors.rightMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (demoMode)
                                return "••••••••";
                            else if (parent.showPassword)
                                return root.passwordBuffer;
                            else
                                return "•".repeat(Math.min(root.passwordBuffer.length, 25));
                        }
                        color: Theme.surfaceText
                        font.pixelSize: parent.showPassword ? Theme.fontSizeMedium : Theme.fontSizeLarge
                        opacity: (demoMode || root.passwordBuffer.length > 0) ? 1 : 0
                        elide: Text.ElideRight

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.mediumDuration
                                easing.type: Theme.standardEasing
                            }

                        }

                    }

                    DankActionButton {
                        id: revealButton

                        anchors.right: enterButton.visible ? enterButton.left : (loadingSpinner.visible ? loadingSpinner.left : parent.right)
                        anchors.rightMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        iconName: parent.showPassword ? "visibility_off" : "visibility"
                        buttonSize: 32
                        visible: !demoMode && root.passwordBuffer.length > 0 && !pam.active && !root.unlocking
                        enabled: visible
                        onClicked: parent.showPassword = !parent.showPassword
                    }

                    Rectangle {
                        id: loadingSpinner

                        anchors.right: enterButton.visible ? enterButton.left : parent.right
                        anchors.rightMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        height: 24
                        radius: 12
                        color: "transparent"
                        visible: !demoMode && (pam.active || root.unlocking)

                        DankIcon {
                            anchors.centerIn: parent
                            name: "check_circle"
                            size: 20
                            color: Theme.primary
                            visible: root.unlocking

                            SequentialAnimation on scale {
                                running: root.unlocking

                                NumberAnimation {
                                    from: 0
                                    to: 1.2
                                    duration: Anims.durShort
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Anims.emphasizedDecel
                                }

                                NumberAnimation {
                                    from: 1.2
                                    to: 1
                                    duration: Anims.durShort
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Anims.emphasizedAccel
                                }

                            }

                        }

                        Item {
                            anchors.fill: parent
                            visible: pam.active && !root.unlocking

                            Rectangle {
                                width: 20
                                height: 20
                                radius: 10
                                anchors.centerIn: parent
                                color: "transparent"
                                border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3)
                                border.width: 2
                            }

                            Rectangle {
                                width: 20
                                height: 20
                                radius: 10
                                anchors.centerIn: parent
                                color: "transparent"
                                border.color: Theme.primary
                                border.width: 2

                                Rectangle {
                                    width: parent.width
                                    height: parent.height / 2
                                    anchors.top: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.9)
                                }

                                RotationAnimation on rotation {
                                    running: pam.active && !root.unlocking
                                    loops: Animation.Infinite
                                    duration: Anims.durLong
                                    from: 0
                                    to: 360
                                }

                            }

                        }

                    }

                    DankActionButton {
                        id: enterButton

                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        iconName: "keyboard_return"
                        buttonSize: 36
                        visible: (demoMode || (root.passwordBuffer.length > 0 && !pam.active && !root.unlocking))
                        enabled: !demoMode
                        onClicked: {
                            if (!demoMode) {
                                console.log("Enter button clicked, starting PAM authentication");
                                pam.start();
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.shortDuration
                                easing.type: Theme.standardEasing
                            }

                        }

                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Theme.shortDuration
                            easing.type: Theme.standardEasing
                        }

                    }

                }

            }

            StyledText {
                Layout.fillWidth: true
                Layout.preferredHeight: placeholder.pamState ? 20 : 0
                text: {
                    if (placeholder.pamState === "error")
                        return "Authentication error - try again";

                    if (placeholder.pamState === "max")
                        return "Too many attempts - locked out";

                    if (placeholder.pamState === "fail")
                        return "Incorrect password - try again";

                    return "";
                }
                color: Theme.error
                font.pixelSize: Theme.fontSizeSmall
                horizontalAlignment: Text.AlignHCenter
                visible: placeholder.pamState !== ""
                opacity: placeholder.pamState !== "" ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }

                }

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }

                }

            }

        }

        StyledText {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: Theme.spacingXL
            text: "DEMO MODE - Click anywhere to exit"
            font.pixelSize: Theme.fontSizeSmall
            color: "white"
            opacity: 0.7
            visible: demoMode
        }

        StyledText {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Theme.spacingXL
            text: WeatherService.weather.available && WeatherService.weather.city && WeatherService.weather.city !== "Unknown" ? `${WeatherService.weather.city} ${(SettingsData.useFahrenheit ? WeatherService.weather.tempF : WeatherService.weather.temp)}°${(SettingsData.useFahrenheit ? "F" : "C")}` : ""
            font.pixelSize: Theme.fontSizeMedium
            color: "white"
            horizontalAlignment: Text.AlignRight
            visible: text !== ""
        }

        StyledText {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: Theme.spacingXL
            text: BatteryService.batteryAvailable ? `Battery: ${BatteryService.batteryLevel}%` : ""
            font.pixelSize: Theme.fontSizeMedium
            color: "white"
            visible: text !== ""
        }

        Row {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.margins: Theme.spacingXL
            spacing: Theme.spacingL

            DankActionButton {
                iconName: "power_settings_new"
                iconColor: Theme.error
                buttonSize: 40
                onClicked: {
                    if (demoMode)
                        console.log("Demo: Power");
                    else
                        powerDialog.open();
                }
            }

            DankActionButton {
                iconName: "refresh"
                buttonSize: 40
                onClicked: {
                    if (demoMode)
                        console.log("Demo: Reboot");
                    else
                        rebootDialog.open();
                }
            }

            DankActionButton {
                iconName: "logout"
                buttonSize: 40
                onClicked: {
                    if (demoMode)
                        console.log("Demo: Logout");
                    else
                        logoutDialog.open();
                }
            }

        }

        StyledText {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: Theme.spacingL
            width: Math.min(parent.width - Theme.spacingXL * 2, implicitWidth)
            text: randomFact
            font.pixelSize: Theme.fontSizeSmall
            color: "white"
            opacity: 0.8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.NoWrap
            visible: randomFact !== ""
        }

    }

    FileView {
        id: pamConfigWatcher

        path: "/etc/pam.d/dankshell"
        printErrors: false
    }

    PamContext {
        id: pam

        config: pamConfigWatcher.loaded ? "dankshell" : "login"
        onResponseRequiredChanged: {
            if (demoMode)
                return ;

            console.log("PAM response required:", responseRequired);
            if (!responseRequired)
                return ;

            console.log("Responding to PAM with password buffer length:", root.passwordBuffer.length);
            respond(root.passwordBuffer);
        }
        onCompleted: (res) => {
            if (demoMode)
                return ;

            console.log("PAM authentication completed with result:", res);
            if (res === PamResult.Success) {
                console.log("Authentication successful, unlocking");
                root.unlocking = true;
                passwordField.text = "";
                root.passwordBuffer = "";
                root.unlockRequested();
                return ;
            }
            console.log("Authentication failed:", res);
            if (res === PamResult.Error)
                placeholder.pamState = "error";
            else if (res === PamResult.MaxTries)
                placeholder.pamState = "max";
            else if (res === PamResult.Failed)
                placeholder.pamState = "fail";
            placeholderDelay.restart();
        }
    }

    Timer {
        id: placeholderDelay

        interval: 4000
        onTriggered: placeholder.pamState = ""
    }

    MouseArea {
        anchors.fill: parent
        enabled: demoMode
        onClicked: root.unlockRequested()
    }

    Rectangle {
        id: powerDialog

        function open() {
            visible = true;
        }

        function close() {
            visible = false;
        }

        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.8)
        visible: false
        z: 1000

        Rectangle {
            anchors.centerIn: parent
            width: 320
            height: 180
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            border.color: Theme.outline
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: Theme.spacingXL

                DankIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "power_settings_new"
                    size: 32
                    color: Theme.error
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Power off this computer?"
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacingM

                    Rectangle {
                        width: 100
                        height: 40
                        radius: Theme.cornerRadius
                        color: cancelMouse1.pressed ? Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.7) : cancelMouse1.containsMouse ? Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.9) : Theme.surfaceVariant

                        StyledText {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                        }

                        MouseArea {
                            id: cancelMouse1

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: powerDialog.close()
                        }

                    }

                    Rectangle {
                        width: 100
                        height: 40
                        radius: Theme.cornerRadius
                        color: powerMouse.pressed ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.8) : powerMouse.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 1) : Theme.error

                        StyledText {
                            anchors.centerIn: parent
                            text: "Power Off"
                            color: "white"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: powerMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                powerDialog.close();
                                Quickshell.execDetached(["systemctl", "poweroff"]);
                            }
                        }

                    }

                }

            }

        }

    }

    Rectangle {
        id: rebootDialog

        function open() {
            visible = true;
        }

        function close() {
            visible = false;
        }

        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.8)
        visible: false
        z: 1000

        Rectangle {
            anchors.centerIn: parent
            width: 320
            height: 180
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            border.color: Theme.outline
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: Theme.spacingXL

                DankIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "refresh"
                    size: 32
                    color: Theme.primary
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Restart this computer?"
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacingM

                    Rectangle {
                        width: 100
                        height: 40
                        radius: Theme.cornerRadius
                        color: cancelMouse2.pressed ? Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.7) : cancelMouse2.containsMouse ? Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.9) : Theme.surfaceVariant

                        StyledText {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                        }

                        MouseArea {
                            id: cancelMouse2

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rebootDialog.close()
                        }

                    }

                    Rectangle {
                        width: 100
                        height: 40
                        radius: Theme.cornerRadius
                        color: rebootMouse.pressed ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.8) : rebootMouse.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 1) : Theme.primary

                        StyledText {
                            anchors.centerIn: parent
                            text: "Restart"
                            color: "white"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: rebootMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                rebootDialog.close();
                                Quickshell.execDetached(["systemctl", "reboot"]);
                            }
                        }

                    }

                }

            }

        }

    }

    Rectangle {
        id: logoutDialog

        function open() {
            visible = true;
        }

        function close() {
            visible = false;
        }

        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.8)
        visible: false
        z: 1000

        Rectangle {
            anchors.centerIn: parent
            width: 320
            height: 180
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            border.color: Theme.outline
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: Theme.spacingXL

                DankIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "logout"
                    size: 32
                    color: Theme.primary
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "End this session?"
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacingM

                    Rectangle {
                        width: 100
                        height: 40
                        radius: Theme.cornerRadius
                        color: cancelMouse3.pressed ? Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.7) : cancelMouse3.containsMouse ? Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.9) : Theme.surfaceVariant

                        StyledText {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                        }

                        MouseArea {
                            id: cancelMouse3

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: logoutDialog.close()
                        }

                    }

                    Rectangle {
                        width: 100
                        height: 40
                        radius: Theme.cornerRadius
                        color: logoutMouse.pressed ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.8) : logoutMouse.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 1) : Theme.primary

                        StyledText {
                            anchors.centerIn: parent
                            text: "Log Out"
                            color: "white"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: logoutMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                logoutDialog.close();
                                NiriService.quit();
                            }
                        }

                    }

                }

            }

        }

    }

}
