package ext_data_control

import (
	"github.com/AvengeMedia/DankMaterialShell/core/pkg/go-wayland/wayland/client"
	"golang.org/x/sys/unix"
)

const ExtDataControlManagerV1InterfaceName = "ext_data_control_manager_v1"

type ExtDataControlManagerV1 struct {
	client.BaseProxy
}

func NewExtDataControlManagerV1(ctx *client.Context) *ExtDataControlManagerV1 {
	m := &ExtDataControlManagerV1{}
	ctx.Register(m)
	return m
}

func (m *ExtDataControlManagerV1) CreateDataSource() (*ExtDataControlSourceV1, error) {
	id := NewExtDataControlSourceV1(m.Context())
	const opcode = 0
	const reqBufLen = 8 + 4
	var reqBuf [reqBufLen]byte
	l := 0
	client.PutUint32(reqBuf[l:4], m.ID())
	l += 4
	client.PutUint32(reqBuf[l:l+4], uint32(reqBufLen<<16|opcode&0x0000ffff))
	l += 4
	client.PutUint32(reqBuf[l:l+4], id.ID())
	l += 4
	err := m.Context().WriteMsg(reqBuf[:], nil)
	return id, err
}

func (m *ExtDataControlManagerV1) GetDataDevice(seat *client.Seat) (*ExtDataControlDeviceV1, error) {
	id := NewExtDataControlDeviceV1(m.Context())
	const opcode = 1
	const reqBufLen = 8 + 4 + 4
	var reqBuf [reqBufLen]byte
	l := 0
	client.PutUint32(reqBuf[l:4], m.ID())
	l += 4
	client.PutUint32(reqBuf[l:l+4], uint32(reqBufLen<<16|opcode&0x0000ffff))
	l += 4
	client.PutUint32(reqBuf[l:l+4], id.ID())
	l += 4
	client.PutUint32(reqBuf[l:l+4], seat.ID())
	l += 4
	err := m.Context().WriteMsg(reqBuf[:], nil)
	return id, err
}

func (m *ExtDataControlManagerV1) GetDataDeviceWithProxy(device *ExtDataControlDeviceV1, seat *client.Seat) error {
	const opcode = 1
	const reqBufLen = 8 + 4 + 4
	var reqBuf [reqBufLen]byte
	l := 0
	client.PutUint32(reqBuf[l:4], m.ID())
	l += 4
	client.PutUint32(reqBuf[l:l+4], uint32(reqBufLen<<16|opcode&0x0000ffff))
	l += 4
	client.PutUint32(reqBuf[l:l+4], device.ID())
	l += 4
	client.PutUint32(reqBuf[l:l+4], seat.ID())
	l += 4
	return m.Context().WriteMsg(reqBuf[:], nil)
}

func (m *ExtDataControlManagerV1) Destroy() error {
	defer m.MarkZombie()
	const opcode = 2
	const reqBufLen = 8
	var reqBuf [reqBufLen]byte
	l := 0
	client.PutUint32(reqBuf[l:4], m.ID())
	l += 4
	client.PutUint32(reqBuf[l:l+4], uint32(reqBufLen<<16|opcode&0x0000ffff))
	l += 4
	return m.Context().WriteMsg(reqBuf[:], nil)
}

const ExtDataControlDeviceV1InterfaceName = "ext_data_control_device_v1"

type ExtDataControlDeviceV1 struct {
	client.BaseProxy
	dataOfferHandler        ExtDataControlDeviceV1DataOfferHandlerFunc
	selectionHandler        ExtDataControlDeviceV1SelectionHandlerFunc
	finishedHandler         ExtDataControlDeviceV1FinishedHandlerFunc
	primarySelectionHandler ExtDataControlDeviceV1PrimarySelectionHandlerFunc
}

func NewExtDataControlDeviceV1(ctx *client.Context) *ExtDataControlDeviceV1 {
	d := &ExtDataControlDeviceV1{}
	ctx.Register(d)
	return d
}

func (d *ExtDataControlDeviceV1) SetSelection(source *ExtDataControlSourceV1) error {
	const opcode = 0
	const reqBufLen = 8 + 4
	var reqBuf [reqBufLen]byte
	l := 0
	client.PutUint32(reqBuf[l:4], d.ID())
	l += 4
	client.PutUint32(reqBuf[l:l+4], uint32(reqBufLen<<16|opcode&0x0000ffff))
	l += 4
	if source == nil {
		client.PutUint32(reqBuf[l:l+4], 0)
	} else {
		client.PutUint32(reqBuf[l:l+4], source.ID())
	}
	l += 4
	return d.Context().WriteMsg(reqBuf[:], nil)
}

func (d *ExtDataControlDeviceV1) Destroy() error {
	defer d.MarkZombie()
	const opcode = 1
	const reqBufLen = 8
	var reqBuf [reqBufLen]byte
	l := 0
	client.PutUint32(reqBuf[l:4], d.ID())
	l += 4
	client.PutUint32(reqBuf[l:l+4], uint32(reqBufLen<<16|opcode&0x0000ffff))
	l += 4
	return d.Context().WriteMsg(reqBuf[:], nil)
}

func (d *ExtDataControlDeviceV1) SetPrimarySelection(source *ExtDataControlSourceV1) error {
	const opcode = 2
	const reqBufLen = 8 + 4
	var reqBuf [reqBufLen]byte
	l := 0
	client.PutUint32(reqBuf[l:4], d.ID())
	l += 4
	client.PutUint32(reqBuf[l:l+4], uint32(reqBufLen<<16|opcode&0x0000ffff))
	l += 4
	if source == nil {
		client.PutUint32(reqBuf[l:l+4], 0)
	} else {
		client.PutUint32(reqBuf[l:l+4], source.ID())
	}
	l += 4
	return d.Context().WriteMsg(reqBuf[:], nil)
}

type ExtDataControlDeviceV1DataOfferEvent struct {
	Id *ExtDataControlOfferV1
}
type ExtDataControlDeviceV1DataOfferHandlerFunc func(ExtDataControlDeviceV1DataOfferEvent)

func (d *ExtDataControlDeviceV1) SetDataOfferHandler(f ExtDataControlDeviceV1DataOfferHandlerFunc) {
	d.dataOfferHandler = f
}

type ExtDataControlDeviceV1SelectionEvent struct {
	Id      *ExtDataControlOfferV1
	OfferId uint32
}
type ExtDataControlDeviceV1SelectionHandlerFunc func(ExtDataControlDeviceV1SelectionEvent)

func (d *ExtDataControlDeviceV1) SetSelectionHandler(f ExtDataControlDeviceV1SelectionHandlerFunc) {
	d.selectionHandler = f
}

type ExtDataControlDeviceV1FinishedEvent struct{}
type ExtDataControlDeviceV1FinishedHandlerFunc func(ExtDataControlDeviceV1FinishedEvent)

func (d *ExtDataControlDeviceV1) SetFinishedHandler(f ExtDataControlDeviceV1FinishedHandlerFunc) {
	d.finishedHandler = f
}

type ExtDataControlDeviceV1PrimarySelectionEvent struct {
	Id      *ExtDataControlOfferV1
	OfferId uint32
}
type ExtDataControlDeviceV1PrimarySelectionHandlerFunc func(ExtDataControlDeviceV1PrimarySelectionEvent)

func (d *ExtDataControlDeviceV1) SetPrimarySelectionHandler(f ExtDataControlDeviceV1PrimarySelectionHandlerFunc) {
	d.primarySelectionHandler = f
}

func (d *ExtDataControlDeviceV1) Dispatch(opcode uint32, fd int, data []byte) {
	switch opcode {
	case 0:
		if d.dataOfferHandler == nil {
			return
		}
		l := 0
		newID := client.Uint32(data[l : l+4])
		l += 4

		ctx := d.Context()
		offer := &ExtDataControlOfferV1{}
		offer.SetContext(ctx)
		offer.SetID(newID)
		ctx.RegisterWithID(offer, newID)

		d.dataOfferHandler(ExtDataControlDeviceV1DataOfferEvent{Id: offer})
	case 1:
		if d.selectionHandler == nil {
			return
		}
		l := 0
		objID := client.Uint32(data[l : l+4])
		l += 4

		var offer *ExtDataControlOfferV1
		if objID != 0 {
			if p := d.Context().GetProxy(objID); p != nil {
				offer = p.(*ExtDataControlOfferV1)
			}
		}
		d.selectionHandler(ExtDataControlDeviceV1SelectionEvent{Id: offer, OfferId: objID})
	case 2:
		if d.finishedHandler == nil {
			return
		}
		d.finishedHandler(ExtDataControlDeviceV1FinishedEvent{})
	case 3:
		if d.primarySelectionHandler == nil {
			return
		}
		l := 0
		objID := client.Uint32(data[l : l+4])
		l += 4

		var offer *ExtDataControlOfferV1
		if objID != 0 {
			if p := d.Context().GetProxy(objID); p != nil {
				offer = p.(*ExtDataControlOfferV1)
			}
		}
		d.primarySelectionHandler(ExtDataControlDeviceV1PrimarySelectionEvent{Id: offer, OfferId: objID})
	}
}

const ExtDataControlSourceV1InterfaceName = "ext_data_control_source_v1"

type ExtDataControlSourceV1 struct {
	client.BaseProxy
	sendHandler      ExtDataControlSourceV1SendHandlerFunc
	cancelledHandler ExtDataControlSourceV1CancelledHandlerFunc
}

func NewExtDataControlSourceV1(ctx *client.Context) *ExtDataControlSourceV1 {
	s := &ExtDataControlSourceV1{}
	ctx.Register(s)
	return s
}

func (s *ExtDataControlSourceV1) Offer(mimeType string) error {
	const opcode = 0
	mimeTypeLen := client.PaddedLen(len(mimeType) + 1)
	reqBufLen := 8 + (4 + mimeTypeLen)
	reqBuf := make([]byte, reqBufLen)
	l := 0
	client.PutUint32(reqBuf[l:4], s.ID())
	l += 4
	client.PutUint32(reqBuf[l:l+4], uint32(reqBufLen<<16|opcode&0x0000ffff))
	l += 4
	client.PutString(reqBuf[l:l+(4+mimeTypeLen)], mimeType)
	l += (4 + mimeTypeLen)
	return s.Context().WriteMsg(reqBuf, nil)
}

func (s *ExtDataControlSourceV1) Destroy() error {
	defer s.MarkZombie()
	const opcode = 1
	const reqBufLen = 8
	var reqBuf [reqBufLen]byte
	l := 0
	client.PutUint32(reqBuf[l:4], s.ID())
	l += 4
	client.PutUint32(reqBuf[l:l+4], uint32(reqBufLen<<16|opcode&0x0000ffff))
	l += 4
	return s.Context().WriteMsg(reqBuf[:], nil)
}

type ExtDataControlSourceV1SendEvent struct {
	MimeType string
	Fd       int
}
type ExtDataControlSourceV1SendHandlerFunc func(ExtDataControlSourceV1SendEvent)

func (s *ExtDataControlSourceV1) SetSendHandler(f ExtDataControlSourceV1SendHandlerFunc) {
	s.sendHandler = f
}

type ExtDataControlSourceV1CancelledEvent struct{}
type ExtDataControlSourceV1CancelledHandlerFunc func(ExtDataControlSourceV1CancelledEvent)

func (s *ExtDataControlSourceV1) SetCancelledHandler(f ExtDataControlSourceV1CancelledHandlerFunc) {
	s.cancelledHandler = f
}

func (s *ExtDataControlSourceV1) Dispatch(opcode uint32, fd int, data []byte) {
	switch opcode {
	case 0:
		if s.sendHandler == nil {
			if fd != -1 {
				unix.Close(fd)
			}
			return
		}
		l := 0
		mimeTypeLen := client.PaddedLen(int(client.Uint32(data[l : l+4])))
		l += 4
		mimeType := client.String(data[l : l+mimeTypeLen])
		l += mimeTypeLen

		s.sendHandler(ExtDataControlSourceV1SendEvent{MimeType: mimeType, Fd: fd})
	case 1:
		if s.cancelledHandler == nil {
			return
		}
		s.cancelledHandler(ExtDataControlSourceV1CancelledEvent{})
	}
}

const ExtDataControlOfferV1InterfaceName = "ext_data_control_offer_v1"

type ExtDataControlOfferV1 struct {
	client.BaseProxy
	offerHandler ExtDataControlOfferV1OfferHandlerFunc
}

func NewExtDataControlOfferV1(ctx *client.Context) *ExtDataControlOfferV1 {
	o := &ExtDataControlOfferV1{}
	ctx.Register(o)
	return o
}

func (o *ExtDataControlOfferV1) Receive(mimeType string, fd int) error {
	const opcode = 0
	mimeTypeLen := client.PaddedLen(len(mimeType) + 1)
	reqBufLen := 8 + (4 + mimeTypeLen)
	reqBuf := make([]byte, reqBufLen)
	l := 0
	client.PutUint32(reqBuf[l:4], o.ID())
	l += 4
	client.PutUint32(reqBuf[l:l+4], uint32(reqBufLen<<16|opcode&0x0000ffff))
	l += 4
	client.PutString(reqBuf[l:l+(4+mimeTypeLen)], mimeType)
	l += (4 + mimeTypeLen)
	oob := unix.UnixRights(fd)
	return o.Context().WriteMsg(reqBuf, oob)
}

func (o *ExtDataControlOfferV1) Destroy() error {
	defer o.MarkZombie()
	const opcode = 1
	const reqBufLen = 8
	var reqBuf [reqBufLen]byte
	l := 0
	client.PutUint32(reqBuf[l:4], o.ID())
	l += 4
	client.PutUint32(reqBuf[l:l+4], uint32(reqBufLen<<16|opcode&0x0000ffff))
	l += 4
	return o.Context().WriteMsg(reqBuf[:], nil)
}

type ExtDataControlOfferV1OfferEvent struct {
	MimeType string
}
type ExtDataControlOfferV1OfferHandlerFunc func(ExtDataControlOfferV1OfferEvent)

func (o *ExtDataControlOfferV1) SetOfferHandler(f ExtDataControlOfferV1OfferHandlerFunc) {
	o.offerHandler = f
}

func (o *ExtDataControlOfferV1) Dispatch(opcode uint32, fd int, data []byte) {
	switch opcode {
	case 0:
		if o.offerHandler == nil {
			return
		}
		l := 0
		mimeTypeLen := client.PaddedLen(int(client.Uint32(data[l : l+4])))
		l += 4
		mimeType := client.String(data[l : l+mimeTypeLen])
		l += mimeTypeLen

		o.offerHandler(ExtDataControlOfferV1OfferEvent{MimeType: mimeType})
	}
}
