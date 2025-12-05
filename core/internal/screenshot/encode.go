package screenshot

import (
	"bufio"
	"fmt"
	"image"
	"image/jpeg"
	"image/png"
	"io"
	"os"
	"path/filepath"
	"time"
)

func BufferToImage(buf *ShmBuffer) *image.RGBA {
	img := image.NewRGBA(image.Rect(0, 0, buf.Width, buf.Height))
	data := buf.Data()
	for y := 0; y < buf.Height; y++ {
		srcOff := y * buf.Stride
		dstOff := y * img.Stride
		for x := 0; x < buf.Width; x++ {
			si := srcOff + x*4
			di := dstOff + x*4
			if si+3 >= len(data) || di+3 >= len(img.Pix) {
				continue
			}
			img.Pix[di+0] = data[si+2] // R
			img.Pix[di+1] = data[si+1] // G
			img.Pix[di+2] = data[si+0] // B
			img.Pix[di+3] = 255        // A
		}
	}
	return img
}

func EncodePNG(w io.Writer, img image.Image) error {
	enc := png.Encoder{CompressionLevel: png.BestSpeed}
	return enc.Encode(w, img)
}

func EncodeJPEG(w io.Writer, img image.Image, quality int) error {
	return jpeg.Encode(w, img, &jpeg.Options{Quality: quality})
}

func EncodePPM(w io.Writer, img *image.RGBA) error {
	bw := bufio.NewWriter(w)
	bounds := img.Bounds()
	if _, err := fmt.Fprintf(bw, "P6\n%d %d\n255\n", bounds.Dx(), bounds.Dy()); err != nil {
		return err
	}
	for y := bounds.Min.Y; y < bounds.Max.Y; y++ {
		for x := bounds.Min.X; x < bounds.Max.X; x++ {
			off := (y-bounds.Min.Y)*img.Stride + (x-bounds.Min.X)*4
			if err := bw.WriteByte(img.Pix[off+0]); err != nil {
				return err
			}
			if err := bw.WriteByte(img.Pix[off+1]); err != nil {
				return err
			}
			if err := bw.WriteByte(img.Pix[off+2]); err != nil {
				return err
			}
		}
	}
	return bw.Flush()
}

func GenerateFilename(format Format) string {
	t := time.Now()
	ext := "png"
	switch format {
	case FormatJPEG:
		ext = "jpg"
	case FormatPPM:
		ext = "ppm"
	}
	return fmt.Sprintf("screenshot_%s.%s", t.Format("2006-01-02_15-04-05"), ext)
}

func GetOutputDir() string {
	if dir := os.Getenv("DMS_SCREENSHOT_DIR"); dir != "" {
		return dir
	}

	if xdgPics := getXDGPicturesDir(); xdgPics != "" {
		screenshotDir := filepath.Join(xdgPics, "Screenshots")
		if err := os.MkdirAll(screenshotDir, 0755); err == nil {
			return screenshotDir
		}
		return xdgPics
	}

	if home := os.Getenv("HOME"); home != "" {
		return home
	}
	return "."
}

func getXDGPicturesDir() string {
	configDir := os.Getenv("XDG_CONFIG_HOME")
	if configDir == "" {
		home := os.Getenv("HOME")
		if home == "" {
			return ""
		}
		configDir = filepath.Join(home, ".config")
	}

	userDirsFile := filepath.Join(configDir, "user-dirs.dirs")
	data, err := os.ReadFile(userDirsFile)
	if err != nil {
		return ""
	}

	for _, line := range splitLines(string(data)) {
		if len(line) == 0 || line[0] == '#' {
			continue
		}
		const prefix = "XDG_PICTURES_DIR="
		if len(line) > len(prefix) && line[:len(prefix)] == prefix {
			path := line[len(prefix):]
			path = trimQuotes(path)
			path = expandHome(path)
			return path
		}
	}
	return ""
}

func splitLines(s string) []string {
	var lines []string
	start := 0
	for i := 0; i < len(s); i++ {
		if s[i] == '\n' {
			lines = append(lines, s[start:i])
			start = i + 1
		}
	}
	if start < len(s) {
		lines = append(lines, s[start:])
	}
	return lines
}

func trimQuotes(s string) string {
	if len(s) >= 2 && s[0] == '"' && s[len(s)-1] == '"' {
		return s[1 : len(s)-1]
	}
	return s
}

func expandHome(path string) string {
	if len(path) >= 5 && path[:5] == "$HOME" {
		home := os.Getenv("HOME")
		return home + path[5:]
	}
	if len(path) >= 1 && path[0] == '~' {
		home := os.Getenv("HOME")
		return home + path[1:]
	}
	return path
}

func WriteToFile(buf *ShmBuffer, path string, format Format, quality int) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()

	img := BufferToImage(buf)
	switch format {
	case FormatJPEG:
		return EncodeJPEG(f, img, quality)
	case FormatPPM:
		return EncodePPM(f, img)
	default:
		return EncodePNG(f, img)
	}
}
