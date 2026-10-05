import qs.DCommon.Widgets as DCommon
import qs.Services

DCommon.DDropdown {
    // Hyprland drops a focus grab when a whitelisted popup takes its own xdg grab
    popupGrabsFocus: !(CompositorService.useHyprlandFocusGrab && transientSurfaceTracker)
}
