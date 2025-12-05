package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/AvengeMedia/DankMaterialShell/core/internal/screenshot"
	"github.com/spf13/cobra"
)

var (
	ssOutputName    string
	ssIncludeCursor bool
	ssFormat        string
	ssQuality       int
	ssOutputDir     string
	ssFilename      string
	ssNoClipboard   bool
	ssNoFile        bool
	ssNoNotify      bool
	ssStdout        bool
)

var screenshotCmd = &cobra.Command{
	Use:   "screenshot",
	Short: "Capture screenshots",
	Long: `Capture screenshots from Wayland displays.

Modes:
  region      - Select a region interactively (default)
  full        - Capture the focused output
  all         - Capture all outputs combined
  output      - Capture a specific output by name
  last        - Capture the last selected region

Output format (--format):
  png         - PNG format (default)
  jpg/jpeg    - JPEG format
  ppm         - PPM format

Examples:
  dms screenshot                     # Region select, save file + clipboard
  dms screenshot full                # Full screen of focused output
  dms screenshot all                 # All screens combined
  dms screenshot output -o DP-1      # Specific output
  dms screenshot last                # Last region (pre-selected)
  dms screenshot --no-clipboard      # Save file only
  dms screenshot --no-file           # Clipboard only
  dms screenshot --cursor            # Include cursor
  dms screenshot -f jpg -q 85        # JPEG with quality 85`,
}

var ssRegionCmd = &cobra.Command{
	Use:   "region",
	Short: "Select a region interactively",
	Run:   runScreenshotRegion,
}

var ssFullCmd = &cobra.Command{
	Use:   "full",
	Short: "Capture the focused output",
	Run:   runScreenshotFull,
}

var ssAllCmd = &cobra.Command{
	Use:   "all",
	Short: "Capture all outputs combined",
	Run:   runScreenshotAll,
}

var ssOutputCmd = &cobra.Command{
	Use:   "output",
	Short: "Capture a specific output",
	Run:   runScreenshotOutput,
}

var ssLastCmd = &cobra.Command{
	Use:   "last",
	Short: "Capture the last selected region",
	Long: `Capture the previously selected region without interactive selection.
If no previous region exists, falls back to interactive selection.`,
	Run: runScreenshotLast,
}

var ssListCmd = &cobra.Command{
	Use:   "list",
	Short: "List available outputs",
	Run:   runScreenshotList,
}

var notifyActionCmd = &cobra.Command{
	Use:    "notify-action",
	Hidden: true,
	Run: func(cmd *cobra.Command, args []string) {
		screenshot.RunNotifyActionListener(args)
	},
}

func init() {
	screenshotCmd.PersistentFlags().StringVarP(&ssOutputName, "output", "o", "", "Output name for 'output' mode")
	screenshotCmd.PersistentFlags().BoolVar(&ssIncludeCursor, "cursor", false, "Include cursor in screenshot")
	screenshotCmd.PersistentFlags().StringVarP(&ssFormat, "format", "f", "png", "Output format (png, jpg, ppm)")
	screenshotCmd.PersistentFlags().IntVarP(&ssQuality, "quality", "q", 90, "JPEG quality (1-100)")
	screenshotCmd.PersistentFlags().StringVarP(&ssOutputDir, "dir", "d", "", "Output directory")
	screenshotCmd.PersistentFlags().StringVar(&ssFilename, "filename", "", "Output filename (auto-generated if empty)")
	screenshotCmd.PersistentFlags().BoolVar(&ssNoClipboard, "no-clipboard", false, "Don't copy to clipboard")
	screenshotCmd.PersistentFlags().BoolVar(&ssNoFile, "no-file", false, "Don't save to file")
	screenshotCmd.PersistentFlags().BoolVar(&ssNoNotify, "no-notify", false, "Don't show notification")
	screenshotCmd.PersistentFlags().BoolVar(&ssStdout, "stdout", false, "Output image to stdout (for piping to swappy, etc.)")

	screenshotCmd.AddCommand(ssRegionCmd)
	screenshotCmd.AddCommand(ssFullCmd)
	screenshotCmd.AddCommand(ssAllCmd)
	screenshotCmd.AddCommand(ssOutputCmd)
	screenshotCmd.AddCommand(ssLastCmd)
	screenshotCmd.AddCommand(ssListCmd)

	screenshotCmd.Run = runScreenshotRegion
}

func getScreenshotConfig(mode screenshot.Mode) screenshot.Config {
	config := screenshot.DefaultConfig()
	config.Mode = mode
	config.OutputName = ssOutputName
	config.IncludeCursor = ssIncludeCursor
	config.Clipboard = !ssNoClipboard
	config.SaveFile = !ssNoFile
	config.Notify = !ssNoNotify
	config.Stdout = ssStdout

	if ssOutputDir != "" {
		config.OutputDir = ssOutputDir
	}
	if ssFilename != "" {
		config.Filename = ssFilename
	}

	switch strings.ToLower(ssFormat) {
	case "jpg", "jpeg":
		config.Format = screenshot.FormatJPEG
	case "ppm":
		config.Format = screenshot.FormatPPM
	default:
		config.Format = screenshot.FormatPNG
	}

	if ssQuality < 1 {
		ssQuality = 1
	}
	if ssQuality > 100 {
		ssQuality = 100
	}
	config.Quality = ssQuality

	return config
}

func runScreenshot(config screenshot.Config) {
	sc := screenshot.New(config)
	result, err := sc.Run()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	if result == nil {
		os.Exit(0)
	}

	defer result.Buffer.Close()

	if result.YInverted {
		result.Buffer.FlipVertical()
	}

	if config.Stdout {
		if err := writeImageToStdout(result.Buffer, config.Format, config.Quality); err != nil {
			fmt.Fprintf(os.Stderr, "Error writing to stdout: %v\n", err)
			os.Exit(1)
		}
		return
	}

	var filePath string

	if config.SaveFile {
		outputDir := config.OutputDir
		if outputDir == "" {
			outputDir = screenshot.GetOutputDir()
		}

		filename := config.Filename
		if filename == "" {
			filename = screenshot.GenerateFilename(config.Format)
		}

		filePath = filepath.Join(outputDir, filename)
		if err := screenshot.WriteToFile(result.Buffer, filePath, config.Format, config.Quality); err != nil {
			fmt.Fprintf(os.Stderr, "Error writing file: %v\n", err)
			os.Exit(1)
		}
		fmt.Println(filePath)
	}

	if config.Clipboard {
		if err := copyImageToClipboard(result.Buffer, config.Format, config.Quality); err != nil {
			fmt.Fprintf(os.Stderr, "Error copying to clipboard: %v\n", err)
			os.Exit(1)
		}
		if !config.SaveFile {
			fmt.Println("Copied to clipboard")
		}
	}

	if config.Notify {
		thumbData, thumbW, thumbH := bufferToRGBThumbnail(result.Buffer, 256)
		screenshot.SendNotification(screenshot.NotifyResult{
			FilePath:  filePath,
			Clipboard: config.Clipboard,
			ImageData: thumbData,
			Width:     thumbW,
			Height:    thumbH,
		})
	}
}

func copyImageToClipboard(buf *screenshot.ShmBuffer, format screenshot.Format, quality int) error {
	var mimeType string
	var data bytes.Buffer

	img := screenshot.BufferToImage(buf)

	switch format {
	case screenshot.FormatJPEG:
		mimeType = "image/jpeg"
		if err := screenshot.EncodeJPEG(&data, img, quality); err != nil {
			return err
		}
	default:
		mimeType = "image/png"
		if err := screenshot.EncodePNG(&data, img); err != nil {
			return err
		}
	}

	cmd := exec.Command("wl-copy", "--type", mimeType)
	cmd.Stdin = &data
	return cmd.Run()
}

func writeImageToStdout(buf *screenshot.ShmBuffer, format screenshot.Format, quality int) error {
	img := screenshot.BufferToImage(buf)

	switch format {
	case screenshot.FormatJPEG:
		return screenshot.EncodeJPEG(os.Stdout, img, quality)
	default:
		return screenshot.EncodePNG(os.Stdout, img)
	}
}

func bufferToRGBThumbnail(buf *screenshot.ShmBuffer, maxSize int) ([]byte, int, int) {
	srcW, srcH := buf.Width, buf.Height
	scale := 1.0
	if srcW > maxSize || srcH > maxSize {
		if srcW > srcH {
			scale = float64(maxSize) / float64(srcW)
		} else {
			scale = float64(maxSize) / float64(srcH)
		}
	}

	dstW := int(float64(srcW) * scale)
	dstH := int(float64(srcH) * scale)
	if dstW < 1 {
		dstW = 1
	}
	if dstH < 1 {
		dstH = 1
	}

	data := buf.Data()
	rgb := make([]byte, dstW*dstH*3)

	for y := 0; y < dstH; y++ {
		srcY := int(float64(y) / scale)
		if srcY >= srcH {
			srcY = srcH - 1
		}
		for x := 0; x < dstW; x++ {
			srcX := int(float64(x) / scale)
			if srcX >= srcW {
				srcX = srcW - 1
			}
			si := srcY*buf.Stride + srcX*4
			di := (y*dstW + x) * 3
			if si+2 < len(data) {
				rgb[di+0] = data[si+2] // R
				rgb[di+1] = data[si+1] // G
				rgb[di+2] = data[si+0] // B
			}
		}
	}
	return rgb, dstW, dstH
}

func runScreenshotRegion(cmd *cobra.Command, args []string) {
	config := getScreenshotConfig(screenshot.ModeRegion)
	runScreenshot(config)
}

func runScreenshotFull(cmd *cobra.Command, args []string) {
	config := getScreenshotConfig(screenshot.ModeFullScreen)
	runScreenshot(config)
}

func runScreenshotAll(cmd *cobra.Command, args []string) {
	config := getScreenshotConfig(screenshot.ModeAllScreens)
	runScreenshot(config)
}

func runScreenshotOutput(cmd *cobra.Command, args []string) {
	if ssOutputName == "" && len(args) > 0 {
		ssOutputName = args[0]
	}
	if ssOutputName == "" {
		fmt.Fprintln(os.Stderr, "Error: output name required (use -o or provide as argument)")
		os.Exit(1)
	}
	config := getScreenshotConfig(screenshot.ModeOutput)
	runScreenshot(config)
}

func runScreenshotLast(cmd *cobra.Command, args []string) {
	config := getScreenshotConfig(screenshot.ModeLastRegion)
	runScreenshot(config)
}

func runScreenshotList(cmd *cobra.Command, args []string) {
	outputs, err := screenshot.ListOutputs()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	for _, o := range outputs {
		fmt.Printf("%s: %dx%d+%d+%d (scale: %d)\n",
			o.Name, o.Width, o.Height, o.X, o.Y, o.Scale)
	}
}
