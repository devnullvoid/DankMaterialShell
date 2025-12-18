import QtQuick
import qs.Common
import qs.Modules.ControlCenter.Widgets

CompoundPill {
    id: root

    property var colorPickerModal: null

    isActive: true
    iconName: "palette"
    iconColor: Theme.primary
    primaryText: I18n.tr("Color Picker")
    secondaryText: I18n.tr("Choose a color")

    onToggled: {
        console.log("ColorPickerPill toggled, modal:", colorPickerModal);
        if (colorPickerModal) {
            colorPickerModal.show();
        }
    }

    onExpandClicked: {
        console.log("ColorPickerPill expandClicked, modal:", colorPickerModal);
        if (colorPickerModal) {
            colorPickerModal.show();
        }
    }
}
