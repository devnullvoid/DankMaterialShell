package screenshot

import "github.com/AvengeMedia/DankMaterialShell/core/internal/wayland/shm"

type PixelFormat = shm.PixelFormat

const (
	FormatARGB8888 = shm.FormatARGB8888
	FormatXRGB8888 = shm.FormatXRGB8888
	FormatABGR8888 = shm.FormatABGR8888
	FormatXBGR8888 = shm.FormatXBGR8888
)

type ShmBuffer = shm.Buffer

func CreateShmBuffer(width, height, stride int) (*ShmBuffer, error) {
	return shm.CreateBuffer(width, height, stride)
}
