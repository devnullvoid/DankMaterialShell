package shm

import (
	"fmt"

	"golang.org/x/sys/unix"
)

type PixelFormat uint32

const (
	FormatARGB8888 PixelFormat = 0
	FormatXRGB8888 PixelFormat = 1
	FormatABGR8888 PixelFormat = 0x34324241
	FormatXBGR8888 PixelFormat = 0x34324258
)

type Buffer struct {
	fd     int
	data   []byte
	size   int
	Width  int
	Height int
	Stride int
	Format PixelFormat
}

func CreateBuffer(width, height, stride int) (*Buffer, error) {
	size := stride * height

	fd, err := unix.MemfdCreate("dms-shm", 0)
	if err != nil {
		return nil, fmt.Errorf("memfd_create: %w", err)
	}

	if err := unix.Ftruncate(fd, int64(size)); err != nil {
		unix.Close(fd)
		return nil, fmt.Errorf("ftruncate: %w", err)
	}

	data, err := unix.Mmap(fd, 0, size, unix.PROT_READ|unix.PROT_WRITE, unix.MAP_SHARED)
	if err != nil {
		unix.Close(fd)
		return nil, fmt.Errorf("mmap: %w", err)
	}

	return &Buffer{
		fd:     fd,
		data:   data,
		size:   size,
		Width:  width,
		Height: height,
		Stride: stride,
	}, nil
}

func (b *Buffer) Fd() int      { return b.fd }
func (b *Buffer) Size() int    { return b.size }
func (b *Buffer) Data() []byte { return b.data }

func (b *Buffer) Close() error {
	var firstErr error

	if b.data != nil {
		if err := unix.Munmap(b.data); err != nil && firstErr == nil {
			firstErr = fmt.Errorf("munmap: %w", err)
		}
		b.data = nil
	}

	if b.fd >= 0 {
		if err := unix.Close(b.fd); err != nil && firstErr == nil {
			firstErr = fmt.Errorf("close: %w", err)
		}
		b.fd = -1
	}

	return firstErr
}

func (b *Buffer) GetPixelRGBA(x, y int) (r, g, b2, a uint8) {
	if x < 0 || x >= b.Width || y < 0 || y >= b.Height {
		return
	}

	off := y*b.Stride + x*4
	if off+3 >= len(b.data) {
		return
	}

	return b.data[off+2], b.data[off+1], b.data[off], b.data[off+3]
}

func (b *Buffer) GetPixelBGRA(x, y int) (b2, g, r, a uint8) {
	if x < 0 || x >= b.Width || y < 0 || y >= b.Height {
		return
	}

	off := y*b.Stride + x*4
	if off+3 >= len(b.data) {
		return
	}

	return b.data[off], b.data[off+1], b.data[off+2], b.data[off+3]
}

func (b *Buffer) ConvertBGRAtoRGBA() {
	for y := 0; y < b.Height; y++ {
		rowOff := y * b.Stride
		for x := 0; x < b.Width; x++ {
			off := rowOff + x*4
			if off+3 >= len(b.data) {
				continue
			}
			b.data[off], b.data[off+2] = b.data[off+2], b.data[off]
		}
	}
}

func (b *Buffer) FlipVertical() {
	tmp := make([]byte, b.Stride)
	for y := 0; y < b.Height/2; y++ {
		topOff := y * b.Stride
		botOff := (b.Height - 1 - y) * b.Stride
		copy(tmp, b.data[topOff:topOff+b.Stride])
		copy(b.data[topOff:topOff+b.Stride], b.data[botOff:botOff+b.Stride])
		copy(b.data[botOff:botOff+b.Stride], tmp)
	}
}

func (b *Buffer) Clear() {
	for i := range b.data {
		b.data[i] = 0
	}
}

func (b *Buffer) CopyFrom(src *Buffer) {
	copy(b.data, src.data)
}
