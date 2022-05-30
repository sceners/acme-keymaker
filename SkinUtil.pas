unit SkinUtil;

interface

uses Windows, Graphics;

function createBackgroundBrush(hWindow: HWND; nID: UINT; hBmBk: HBITMAP): HBRUSH;
function isPointInside(lParam: LPARAM; rect: TRect): Boolean;
function BitmapToRegion(bmp: TBitmap; TransparentColor: TColor=clGreen; RedTol: Byte=1; GreenTol: Byte=1; BlueTol: Byte=1): HRGN;

implementation

uses SysUtils, Math;

// Extract coordinates from lParam to dialog procedure and check if point is within TRECT.
function isPointInside(lParam: LPARAM; rect: TRect): Boolean;
var x, y: Integer;
begin
  x := lParam and $FFFF;
  y := lParam shr 16;
  if ((x >= rect.Left) and (x <= rect.Right) and (y >= rect.Top) and (y <= rect.Bottom)) then
    result := true
  else result := false;
end;

// Get bitmap brush for control backgrounds.
function createBackgroundBrush(hWindow: HWND; nID: UINT; hBmBk: HBITMAP): HBRUSH;
var
  hWndCtrl: HWND;
  hBrushCtrl: HBRUSH;
  hBmOldBk: HBITMAP;
  hBmOldCtrl: HBITMAP;
  hBmCtrl: HBITMAP;
  hMemDCCtrl: HDC;
  hMemDCBk: HDC;
  dc: HDC;
  rcCtrl: TRECT;
  width, height: Integer;
  pt: TPoint;
begin
	hWndCtrl := GetDlgItem(hWindow, nID);
	hBrushCtrl := 0;

	if(hWndCtrl <> 0) then
	begin
		GetWindowRect(hWndCtrl, rcCtrl);
    pt := rcCtrl.TopLeft;
    ScreenToClient(hWindow, pt);
    rcCtrl.Left := pt.X;
    rcCtrl.Top := pt.Y;

    pt := rcCtrl.BottomRight;
    ScreenToClient(hWindow, pt);
    rcCtrl.BottomRight := pt;

    width := rcCtrl.Right - rcCtrl.Left;;
    height := rcCtrl.Bottom - rcCtrl.Top;

		dc := GetDC(hWindow);
		hMemDCBk := CreateCompatibleDC(dc);
		hMemDCCtrl := CreateCompatibleDC(dc);

		hBmCtrl := CreateCompatibleBitmap(dc, width, height);

		hBmOldBk := HBITMAP(SelectObject(hMemDCBk, hBmBk));
		hBmOldCtrl := HBITMAP(SelectObject(hMemDCCtrl, hBmCtrl));

    BitBlt(hMemDCCtrl, 0, 0, width, height, hMemDCBk, rcCtrl.Left, rcCtrl.Top, SRCCOPY);

		SelectObject(hMemDCCtrl, hBmOldCtrl);
		SelectObject(hMemDCBk, hBmOldBk);

		hBrushCtrl := CreatePatternBrush(hBmCtrl);

		DeleteObject(hBmCtrl);
		DeleteDC(hMemDCBk);
		DeleteDC(hMemDCCtrl);
		ReleaseDC(hWindow, DC);
	end;

	result := hBrushCtrl;
end;

function BitmapToRegion(bmp: TBitmap; TransparentColor: TColor=clGreen;
  RedTol: Byte=1; GreenTol: Byte=1; BlueTol: Byte=1): HRGN;
const
  AllocUnit = 100;
type
  PRectArray = ^TRectArray;
  TRectArray = Array[0..(MaxInt div SizeOf(TRect))-1] of TRect;
var
  pr: PRectArray;    // used to access the rects array of RgnData by index
  h: HRGN;           // Handles to regions
  RgnData: PRgnData; // Pointer to structure RGNDATA used to create regions
  lr, lg, lb, hr, hg, hb: Byte; // values for lowest and hightest trans. colors
  x,y, x0: Integer;  // coordinates of current rect of visible pixels
  b: PByteArray;     // used to easy the task of testing the byte pixels (R,G,B)
  ScanLinePtr: Pointer; // Pointer to current ScanLine being scanned
  ScanLineInc: Integer; // Offset to next bitmap scanline (can be negative)
  maxRects: Cardinal;   // Number of rects to realloc memory by chunks of AllocUnit
begin
  Result := 0;
  { Keep on hand lowest and highest values for the "transparent" pixels }
  lr := GetRValue(TransparentColor);
  lg := GetGValue(TransparentColor);
  lb := GetBValue(TransparentColor);
  hr := Min($ff, lr + RedTol);
  hg := Min($ff, lg + GreenTol);
  hb := Min($ff, lb + BlueTol);
  { ensures that the pixel format is 32-bits per pixel }
  bmp.PixelFormat := pf32bit;
  { alloc initial region data }
  maxRects := AllocUnit;
  GetMem(RgnData,SizeOf(RGNDATAHEADER) + (SizeOf(TRect) * maxRects));
  try
    with RgnData^.rdh do
    begin
      dwSize := SizeOf(RGNDATAHEADER);
      iType := RDH_RECTANGLES;
      nCount := 0;
      nRgnSize := 0;
      SetRect(rcBound, MAXLONG, MAXLONG, 0, 0);
    end;
    { scan each bitmap row - the orientation doesn't matter (Bottom-up or not) }
    ScanLinePtr := bmp.ScanLine[0];
    ScanLineInc := Integer(bmp.ScanLine[1]) - Integer(ScanLinePtr);
    for y := 0 to bmp.Height - 1 do
    begin
      x := 0;
      while x < bmp.Width do
      begin
        x0 := x;
        while x < bmp.Width do
        begin
          b := @PByteArray(ScanLinePtr)[x*SizeOf(TRGBQuad)];
          // BGR-RGB: Windows 32bpp BMPs are made of BGRa quads (not RGBa)
          if (b[2] >= lr) and (b[2] <= hr) and
             (b[1] >= lg) and (b[1] <= hg) and
             (b[0] >= lb) and (b[0] <= hb) then
            Break; // pixel is transparent
          Inc(x);
        end;
        { test to see if we have a non-transparent area in the image }
        if x > x0 then
        begin
          { increase RgnData by AllocUnit rects if we exceeds maxRects }
          if RgnData^.rdh.nCount >= maxRects then
          begin
            Inc(maxRects,AllocUnit);
            ReallocMem(RgnData,SizeOf(RGNDATAHEADER) + (SizeOf(TRect) * MaxRects));
          end;
          { Add the rect (x0, y)-(x, y+1) as a new visible area in the region }
          pr := @RgnData^.Buffer; // Buffer is an array of rects
          with RgnData^.rdh do
          begin
            SetRect(pr[nCount], x0, y, x, y+1);
            { adjust the bound rectangle of the region if we are "out-of-bounds" }
            if x0 < rcBound.Left then rcBound.Left := x0;
            if y < rcBound.Top then rcBound.Top := y;
            if x > rcBound.Right then rcBound.Right := x;
            if y+1 > rcBound.Bottom then rcBound.Bottom := y+1;
            Inc(nCount);
          end;
        end; // if x > x0
        { Need to create the region by muliple calls to ExtCreateRegion, 'cause }
        { it will fail on Windows 98 if the number of rectangles is too large   }
        if RgnData^.rdh.nCount = 2000 then
        begin
          h := ExtCreateRegion(nil, SizeOf(RGNDATAHEADER) + (SizeOf(TRect) * maxRects), RgnData^);
          if Result > 0 then
          begin // Expand the current region
            CombineRgn(Result, Result, h, RGN_OR);
            DeleteObject(h);
          end
          else  // First region, assign it to Result
            Result := h;
          RgnData^.rdh.nCount := 0;
          SetRect(RgnData^.rdh.rcBound, MAXLONG, MAXLONG, 0, 0);
        end;
        Inc(x);
      end; // scan every sample byte of the image
      Inc(Integer(ScanLinePtr), ScanLineInc);
    end;
    { need to call ExCreateRegion one more time because we could have left    }
    { a RgnData with less than 2000 rects, so it wasn't yet created/combined  }
    h := ExtCreateRegion(nil, SizeOf(RGNDATAHEADER) + (SizeOf(TRect) * MaxRects), RgnData^);
    if Result > 0 then
    begin
      CombineRgn(Result, Result, h, RGN_OR);
      DeleteObject(h);
    end
    else
      Result := h;
  finally
    FreeMem(RgnData,SizeOf(RGNDATAHEADER) + (SizeOf(TRect) * MaxRects));
  end;
end;

end.
