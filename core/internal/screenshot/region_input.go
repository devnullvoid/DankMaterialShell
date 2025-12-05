package screenshot

import (
	"github.com/AvengeMedia/DankMaterialShell/core/pkg/go-wayland/wayland/client"
)

func (r *RegionSelector) setupInput() {
	if r.seat == nil {
		return
	}

	r.seat.SetCapabilitiesHandler(func(e client.SeatCapabilitiesEvent) {
		if e.Capabilities&uint32(client.SeatCapabilityPointer) != 0 && r.pointer == nil {
			if pointer, err := r.seat.GetPointer(); err == nil {
				r.pointer = pointer
				r.setupPointerHandlers()
			}
		}
		if e.Capabilities&uint32(client.SeatCapabilityKeyboard) != 0 && r.keyboard == nil {
			if keyboard, err := r.seat.GetKeyboard(); err == nil {
				r.keyboard = keyboard
				r.setupKeyboardHandlers()
			}
		}
	})
}

func (r *RegionSelector) setupPointerHandlers() {
	r.pointer.SetEnterHandler(func(e client.PointerEnterEvent) {
		if r.cursorSurface != nil {
			_ = r.pointer.SetCursor(e.Serial, r.cursorSurface, 12, 12)
		}

		r.activeSurface = nil
		for _, os := range r.surfaces {
			if os.wlSurface.ID() == e.Surface.ID() {
				r.activeSurface = os
				break
			}
		}

		r.pointerX = e.SurfaceX
		r.pointerY = e.SurfaceY
	})

	r.pointer.SetMotionHandler(func(e client.PointerMotionEvent) {
		if r.activeSurface == nil {
			return
		}

		r.pointerX = e.SurfaceX
		r.pointerY = e.SurfaceY

		if r.selection.dragging {
			r.selection.currentX = e.SurfaceX
			r.selection.currentY = e.SurfaceY
			for _, os := range r.surfaces {
				r.redrawSurface(os)
			}
		}
	})

	r.pointer.SetButtonHandler(func(e client.PointerButtonEvent) {
		if r.activeSurface == nil {
			return
		}

		switch e.Button {
		case 0x110: // BTN_LEFT
			switch e.State {
			case 1: // pressed
				r.selection.hasSelection = true
				r.selection.dragging = true
				r.selection.anchorX = r.pointerX
				r.selection.anchorY = r.pointerY
				r.selection.currentX = r.pointerX
				r.selection.currentY = r.pointerY
				for _, os := range r.surfaces {
					r.redrawSurface(os)
				}
			case 0: // released
				r.selection.dragging = false
				for _, os := range r.surfaces {
					r.redrawSurface(os)
				}
			}
		default:
			r.cancelled = true
			r.running = false
		}
	})
}

func (r *RegionSelector) setupKeyboardHandlers() {
	r.keyboard.SetKeyHandler(func(e client.KeyboardKeyEvent) {
		if e.State != 1 {
			return
		}

		switch e.Key {
		case 1: // KEY_ESC
			r.cancelled = true
			r.running = false
		case 25: // KEY_P
			r.showCapturedCursor = !r.showCapturedCursor
			for _, os := range r.surfaces {
				r.redrawSurface(os)
			}
		case 28, 57: // KEY_ENTER, KEY_SPACE
			if r.selection.hasSelection {
				r.finishSelection()
			}
		}
	})
}

func (r *RegionSelector) finishSelection() {
	if r.activeSurface == nil {
		r.running = false
		return
	}

	os := r.activeSurface

	x1, y1 := r.selection.anchorX, r.selection.anchorY
	x2, y2 := r.selection.currentX, r.selection.currentY

	if x1 > x2 {
		x1, x2 = x2, x1
	}
	if y1 > y2 {
		y1, y2 = y2, y1
	}

	scaleX, scaleY := 1.0, 1.0
	if os.logicalW > 0 && os.screenBuf != nil {
		scaleX = float64(os.screenBuf.Width) / float64(os.logicalW)
		scaleY = float64(os.screenBuf.Height) / float64(os.logicalH)
	}

	bx1, by1 := int32(x1*scaleX), int32(y1*scaleY)
	bx2, by2 := int32(x2*scaleX), int32(y2*scaleY)

	w, h := bx2-bx1, by2-by1
	if w < 1 {
		w = 1
	}
	if h < 1 {
		h = 1
	}

	r.result = Region{
		X:      bx1 + os.output.x,
		Y:      by1 + os.output.y,
		Width:  w,
		Height: h,
		Output: os.output.name,
	}

	r.running = false
}
