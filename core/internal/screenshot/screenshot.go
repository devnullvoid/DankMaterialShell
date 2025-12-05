package screenshot

import (
	"fmt"
	"sync"

	"github.com/AvengeMedia/DankMaterialShell/core/internal/log"
	"github.com/AvengeMedia/DankMaterialShell/core/internal/proto/wlr_screencopy"
	wlhelpers "github.com/AvengeMedia/DankMaterialShell/core/internal/wayland/client"
	"github.com/AvengeMedia/DankMaterialShell/core/pkg/go-wayland/wayland/client"
)

type WaylandOutput struct {
	wlOutput   *client.Output
	globalName uint32
	name       string
	x, y       int32
	width      int32
	height     int32
	scale      int32
	transform  int32
}

type CaptureResult struct {
	Buffer    *ShmBuffer
	Region    Region
	YInverted bool
}

type Screenshoter struct {
	config Config

	display  *client.Display
	registry *client.Registry
	ctx      *client.Context

	compositor *client.Compositor
	shm        *client.Shm
	screencopy *wlr_screencopy.ZwlrScreencopyManagerV1

	outputs   map[uint32]*WaylandOutput
	outputsMu sync.Mutex
}

func New(config Config) *Screenshoter {
	return &Screenshoter{
		config:  config,
		outputs: make(map[uint32]*WaylandOutput),
	}
}

func (s *Screenshoter) Run() (*CaptureResult, error) {
	if err := s.connect(); err != nil {
		return nil, fmt.Errorf("wayland connect: %w", err)
	}
	defer s.cleanup()

	if err := s.setupRegistry(); err != nil {
		return nil, fmt.Errorf("registry setup: %w", err)
	}

	if err := s.roundtrip(); err != nil {
		return nil, fmt.Errorf("roundtrip: %w", err)
	}

	if s.screencopy == nil {
		return nil, fmt.Errorf("compositor does not support wlr-screencopy-unstable-v1")
	}

	if err := s.roundtrip(); err != nil {
		return nil, fmt.Errorf("roundtrip: %w", err)
	}

	switch s.config.Mode {
	case ModeLastRegion:
		return s.captureLastRegion()
	case ModeRegion:
		return s.captureRegion()
	case ModeOutput:
		return s.captureOutput(s.config.OutputName)
	case ModeFullScreen:
		return s.captureFullScreen()
	case ModeAllScreens:
		return s.captureAllScreens()
	default:
		return s.captureRegion()
	}
}

func (s *Screenshoter) captureLastRegion() (*CaptureResult, error) {
	lastRegion := GetLastRegion()
	if lastRegion.IsEmpty() {
		return s.captureRegion()
	}

	output := s.findOutputForRegion(lastRegion)
	if output == nil {
		return s.captureRegion()
	}

	return s.captureRegionOnOutput(output, lastRegion)
}

func (s *Screenshoter) captureRegion() (*CaptureResult, error) {
	selector := NewRegionSelector(s)
	region, cancelled, err := selector.Run()
	if err != nil {
		return nil, fmt.Errorf("region selection: %w", err)
	}
	if cancelled {
		return nil, nil
	}

	output := s.findOutputForRegion(region)
	if output == nil {
		return nil, fmt.Errorf("no output found for region")
	}

	if err := SaveLastRegion(region); err != nil {
		log.Debug("failed to save last region", "err", err)
	}

	return s.captureRegionOnOutput(output, region)
}

func (s *Screenshoter) captureFullScreen() (*CaptureResult, error) {
	output := s.findFocusedOutput()
	if output == nil {
		s.outputsMu.Lock()
		for _, o := range s.outputs {
			output = o
			break
		}
		s.outputsMu.Unlock()
	}

	if output == nil {
		return nil, fmt.Errorf("no output available")
	}

	return s.captureWholeOutput(output)
}

func (s *Screenshoter) captureOutput(name string) (*CaptureResult, error) {
	s.outputsMu.Lock()
	var output *WaylandOutput
	for _, o := range s.outputs {
		if o.name == name {
			output = o
			break
		}
	}
	s.outputsMu.Unlock()

	if output == nil {
		return nil, fmt.Errorf("output %q not found", name)
	}

	return s.captureWholeOutput(output)
}

func (s *Screenshoter) captureAllScreens() (*CaptureResult, error) {
	s.outputsMu.Lock()
	outputs := make([]*WaylandOutput, 0, len(s.outputs))
	var minX, minY, maxX, maxY int32
	first := true

	for _, o := range s.outputs {
		outputs = append(outputs, o)
		right := o.x + o.width
		bottom := o.y + o.height

		if first {
			minX, minY = o.x, o.y
			maxX, maxY = right, bottom
			first = false
			continue
		}

		if o.x < minX {
			minX = o.x
		}
		if o.y < minY {
			minY = o.y
		}
		if right > maxX {
			maxX = right
		}
		if bottom > maxY {
			maxY = bottom
		}
	}
	s.outputsMu.Unlock()

	if len(outputs) == 0 {
		return nil, fmt.Errorf("no outputs available")
	}

	if len(outputs) == 1 {
		return s.captureWholeOutput(outputs[0])
	}

	totalW := maxX - minX
	totalH := maxY - minY

	compositeStride := int(totalW) * 4
	composite, err := CreateShmBuffer(int(totalW), int(totalH), compositeStride)
	if err != nil {
		return nil, fmt.Errorf("create composite buffer: %w", err)
	}

	composite.Clear()

	for _, output := range outputs {
		result, err := s.captureWholeOutput(output)
		if err != nil {
			log.Warn("failed to capture output", "name", output.name, "err", err)
			continue
		}

		s.blitBuffer(composite, result.Buffer, int(output.x-minX), int(output.y-minY), result.YInverted)
		result.Buffer.Close()
	}

	return &CaptureResult{
		Buffer: composite,
		Region: Region{X: minX, Y: minY, Width: totalW, Height: totalH},
	}, nil
}

func (s *Screenshoter) blitBuffer(dst, src *ShmBuffer, dstX, dstY int, yInverted bool) {
	srcData := src.Data()
	dstData := dst.Data()

	for srcY := 0; srcY < src.Height; srcY++ {
		actualSrcY := srcY
		if yInverted {
			actualSrcY = src.Height - 1 - srcY
		}

		dy := dstY + srcY
		if dy < 0 || dy >= dst.Height {
			continue
		}

		srcRowOff := actualSrcY * src.Stride
		dstRowOff := dy * dst.Stride

		for srcX := 0; srcX < src.Width; srcX++ {
			dx := dstX + srcX
			if dx < 0 || dx >= dst.Width {
				continue
			}

			si := srcRowOff + srcX*4
			di := dstRowOff + dx*4

			if si+3 >= len(srcData) || di+3 >= len(dstData) {
				continue
			}

			dstData[di+0] = srcData[si+0]
			dstData[di+1] = srcData[si+1]
			dstData[di+2] = srcData[si+2]
			dstData[di+3] = srcData[si+3]
		}
	}
}

func (s *Screenshoter) captureWholeOutput(output *WaylandOutput) (*CaptureResult, error) {
	cursor := int32(0)
	if s.config.IncludeCursor {
		cursor = 1
	}

	frame, err := s.screencopy.CaptureOutput(cursor, output.wlOutput)
	if err != nil {
		return nil, fmt.Errorf("capture output: %w", err)
	}

	return s.processFrame(frame, Region{
		X:      output.x,
		Y:      output.y,
		Width:  output.width,
		Height: output.height,
		Output: output.name,
	})
}

func (s *Screenshoter) captureRegionOnOutput(output *WaylandOutput, region Region) (*CaptureResult, error) {
	localX := region.X - output.x
	localY := region.Y - output.y

	cursor := int32(0)
	if s.config.IncludeCursor {
		cursor = 1
	}

	frame, err := s.screencopy.CaptureOutputRegion(
		cursor,
		output.wlOutput,
		localX, localY,
		region.Width, region.Height,
	)
	if err != nil {
		return nil, fmt.Errorf("capture region: %w", err)
	}

	return s.processFrame(frame, region)
}

func (s *Screenshoter) processFrame(frame *wlr_screencopy.ZwlrScreencopyFrameV1, region Region) (*CaptureResult, error) {
	var buf *ShmBuffer
	var format PixelFormat
	var yInverted bool
	ready := false
	failed := false

	frame.SetBufferHandler(func(e wlr_screencopy.ZwlrScreencopyFrameV1BufferEvent) {
		var err error
		buf, err = CreateShmBuffer(int(e.Width), int(e.Height), int(e.Stride))
		if err != nil {
			log.Error("failed to create buffer", "err", err)
			return
		}
		format = PixelFormat(e.Format)
		buf.Format = format
	})

	frame.SetFlagsHandler(func(e wlr_screencopy.ZwlrScreencopyFrameV1FlagsEvent) {
		yInverted = (e.Flags & 1) != 0
	})

	frame.SetBufferDoneHandler(func(e wlr_screencopy.ZwlrScreencopyFrameV1BufferDoneEvent) {
		if buf == nil {
			return
		}

		pool, err := s.shm.CreatePool(buf.Fd(), int32(buf.Size()))
		if err != nil {
			log.Error("failed to create pool", "err", err)
			return
		}

		wlBuf, err := pool.CreateBuffer(0, int32(buf.Width), int32(buf.Height), int32(buf.Stride), uint32(format))
		if err != nil {
			pool.Destroy()
			log.Error("failed to create wl_buffer", "err", err)
			return
		}

		if err := frame.Copy(wlBuf); err != nil {
			log.Error("failed to copy frame", "err", err)
		}

		pool.Destroy()
	})

	frame.SetReadyHandler(func(e wlr_screencopy.ZwlrScreencopyFrameV1ReadyEvent) {
		ready = true
	})

	frame.SetFailedHandler(func(e wlr_screencopy.ZwlrScreencopyFrameV1FailedEvent) {
		failed = true
	})

	for !ready && !failed {
		if err := s.ctx.Dispatch(); err != nil {
			frame.Destroy()
			return nil, fmt.Errorf("dispatch: %w", err)
		}
	}

	frame.Destroy()

	if failed {
		if buf != nil {
			buf.Close()
		}
		return nil, fmt.Errorf("frame capture failed")
	}

	return &CaptureResult{
		Buffer:    buf,
		Region:    region,
		YInverted: yInverted,
	}, nil
}

func (s *Screenshoter) findOutputForRegion(region Region) *WaylandOutput {
	s.outputsMu.Lock()
	defer s.outputsMu.Unlock()

	cx := region.X + region.Width/2
	cy := region.Y + region.Height/2

	for _, o := range s.outputs {
		if cx >= o.x && cx < o.x+o.width && cy >= o.y && cy < o.y+o.height {
			return o
		}
	}

	for _, o := range s.outputs {
		if region.X >= o.x && region.X < o.x+o.width &&
			region.Y >= o.y && region.Y < o.y+o.height {
			return o
		}
	}

	return nil
}

func (s *Screenshoter) findFocusedOutput() *WaylandOutput {
	s.outputsMu.Lock()
	defer s.outputsMu.Unlock()
	for _, o := range s.outputs {
		return o
	}
	return nil
}

func (s *Screenshoter) connect() error {
	display, err := client.Connect("")
	if err != nil {
		return err
	}
	s.display = display
	s.ctx = display.Context()
	return nil
}

func (s *Screenshoter) roundtrip() error {
	return wlhelpers.Roundtrip(s.display, s.ctx)
}

func (s *Screenshoter) setupRegistry() error {
	registry, err := s.display.GetRegistry()
	if err != nil {
		return err
	}
	s.registry = registry

	registry.SetGlobalHandler(func(e client.RegistryGlobalEvent) {
		s.handleGlobal(e)
	})

	registry.SetGlobalRemoveHandler(func(e client.RegistryGlobalRemoveEvent) {
		s.outputsMu.Lock()
		delete(s.outputs, e.Name)
		s.outputsMu.Unlock()
	})

	return nil
}

func (s *Screenshoter) handleGlobal(e client.RegistryGlobalEvent) {
	switch e.Interface {
	case client.CompositorInterfaceName:
		comp := client.NewCompositor(s.ctx)
		if err := s.registry.Bind(e.Name, e.Interface, e.Version, comp); err == nil {
			s.compositor = comp
		}

	case client.ShmInterfaceName:
		shm := client.NewShm(s.ctx)
		if err := s.registry.Bind(e.Name, e.Interface, e.Version, shm); err == nil {
			s.shm = shm
		}

	case client.OutputInterfaceName:
		output := client.NewOutput(s.ctx)
		version := e.Version
		if version > 4 {
			version = 4
		}
		if err := s.registry.Bind(e.Name, e.Interface, version, output); err == nil {
			s.outputsMu.Lock()
			s.outputs[e.Name] = &WaylandOutput{
				wlOutput:   output,
				globalName: e.Name,
				scale:      1,
			}
			s.outputsMu.Unlock()
			s.setupOutputHandlers(e.Name, output)
		}

	case wlr_screencopy.ZwlrScreencopyManagerV1InterfaceName:
		sc := wlr_screencopy.NewZwlrScreencopyManagerV1(s.ctx)
		version := e.Version
		if version > 3 {
			version = 3
		}
		if err := s.registry.Bind(e.Name, e.Interface, version, sc); err == nil {
			s.screencopy = sc
		}
	}
}

func (s *Screenshoter) setupOutputHandlers(name uint32, output *client.Output) {
	output.SetGeometryHandler(func(e client.OutputGeometryEvent) {
		s.outputsMu.Lock()
		if o, ok := s.outputs[name]; ok {
			o.x, o.y = e.X, e.Y
			o.transform = int32(e.Transform)
		}
		s.outputsMu.Unlock()
	})

	output.SetModeHandler(func(e client.OutputModeEvent) {
		if e.Flags&uint32(client.OutputModeCurrent) == 0 {
			return
		}
		s.outputsMu.Lock()
		if o, ok := s.outputs[name]; ok {
			o.width, o.height = e.Width, e.Height
		}
		s.outputsMu.Unlock()
	})

	output.SetScaleHandler(func(e client.OutputScaleEvent) {
		s.outputsMu.Lock()
		if o, ok := s.outputs[name]; ok {
			o.scale = e.Factor
		}
		s.outputsMu.Unlock()
	})

	output.SetNameHandler(func(e client.OutputNameEvent) {
		s.outputsMu.Lock()
		if o, ok := s.outputs[name]; ok {
			o.name = e.Name
		}
		s.outputsMu.Unlock()
	})
}

func (s *Screenshoter) cleanup() {
	if s.screencopy != nil {
		s.screencopy.Destroy()
	}
	if s.display != nil {
		s.ctx.Close()
	}
}

func (s *Screenshoter) GetOutputs() []*WaylandOutput {
	s.outputsMu.Lock()
	defer s.outputsMu.Unlock()
	out := make([]*WaylandOutput, 0, len(s.outputs))
	for _, o := range s.outputs {
		out = append(out, o)
	}
	return out
}

func ListOutputs() ([]Output, error) {
	sc := New(DefaultConfig())
	if err := sc.connect(); err != nil {
		return nil, err
	}
	defer sc.cleanup()

	if err := sc.setupRegistry(); err != nil {
		return nil, err
	}
	if err := sc.roundtrip(); err != nil {
		return nil, err
	}
	if err := sc.roundtrip(); err != nil {
		return nil, err
	}

	sc.outputsMu.Lock()
	defer sc.outputsMu.Unlock()

	result := make([]Output, 0, len(sc.outputs))
	for _, o := range sc.outputs {
		result = append(result, Output{
			Name:   o.name,
			X:      o.x,
			Y:      o.y,
			Width:  o.width,
			Height: o.height,
			Scale:  o.scale,
		})
	}
	return result, nil
}
