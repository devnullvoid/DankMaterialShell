package colorpicker

import "github.com/AvengeMedia/DankMaterialShell/core/internal/wayland/shm"

type ShmBuffer = shm.Buffer

func CreateShmBuffer(width, height, stride int) (*ShmBuffer, error) {
	return shm.CreateBuffer(width, height, stride)
}

func GetPixelColor(buf *ShmBuffer, x, y int) Color {
	return GetPixelColorWithFormat(buf, x, y, FormatARGB8888)
}

func GetPixelColorWithFormat(buf *ShmBuffer, x, y int, format PixelFormat) Color {
	if x < 0 || x >= buf.Width || y < 0 || y >= buf.Height {
		return Color{}
	}

	data := buf.Data()
	offset := y*buf.Stride + x*4
	if offset+3 >= len(data) {
		return Color{}
	}

	if format == FormatABGR8888 || format == FormatXBGR8888 {
		return Color{
			R: data[offset],
			G: data[offset+1],
			B: data[offset+2],
			A: data[offset+3],
		}
	}
	return Color{
		B: data[offset],
		G: data[offset+1],
		R: data[offset+2],
		A: data[offset+3],
	}
}
