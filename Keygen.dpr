program Keygen;

uses
  SysUtils,
  Windows,
  Messages,
  Classes,
  MMSystem,
  MPlayer,
  Graphics,
  Math,
  Dialogs,
  Serial in 'Serial.pas',
  Patch in 'Patch.pas',
  Base64 in 'Base64.pas',
  Crc32 in 'Crc32.pas',
  FGInt in 'FGInt.pas',
  Hash in 'Hash.pas',
  HKStreamRoutines in 'HKStreamRoutines.pas',
  narf in 'Narf.pas',
  SerialUtil in 'SerialUtil.pas',
  Util in 'Util.pas',
  MP3Player in 'MP3Player.pas',
  SkinUtil in 'SkinUtil.pas';

{$R KEYGEN.res}
{$R rsa_params.res}

{ Keygen }

procedure playResWaveFile(identifier: String);
var
  resStream: TResourceStream;
begin
  resStream := TResourceStream.Create(HInstance, identifier, 'WAVE');
  sndPlaySound(resStream.Memory, SND_ASYNC or SND_NODEFAULT or SND_MEMORY);
  resStream.Free;
end;

procedure infoDialog(msg: String);
begin
  playResWaveFile('LAUGH');
  MessageDlg(msg, mtInformation, [mbOk], 0);
end;

procedure errorDialog(msg: String);
begin
  playResWaveFile('NARF');
  MessageDlg(msg, mtError, [mbOk], 0);
end;

// Write keyfile and patch FlashFXP.exe.
procedure doKeygenAction(name: String);
var
  patchResult: Integer;
begin
  if writeKeyFile(getFFXPKeyFile, name, 'narf1337@zort.com') then
  begin
    patchResult := patchFFXP;
    case patchResult of
      ErrorNotWritable: errorDialog('Unable patch executable: ' + getFFXPExePath);
      AlreadyPatched: infoDialog('FlashFXP is already patched');
      PatchSuccess: infoDialog('Successfully generated the keyfile and patched the executable');
      StringTableNotFound: errorDialog('Unable to locate string table entry of public key (wrong keygen for this version?)');
    end;
  end
  else
  begin
    errorDialog('Unable to write keyfile');
  end;
end;

procedure showInfoMessage(hDialog: HWND);
var
  msg: string;
begin
  playResWaveFile('LAUGH');
  msg := 'Enjoy this fine release with full source code :)' + sLineBreak + 'Btw: we are looking for talented crackers - contact us at acme@hotmail.ru';
  MessageBox(hDialog, PChar(msg), 'Team ACME', MB_ICONINFORMATION);
end;

{ Window handling }

// TODO: refactor crappy skin code

var hEdtBmpBrush    : HBRUSH;
    mainSkin        : TBitmap;
    genButton       : TBitmap;
    bmpInfoBtnHot   : TBitmap;
    bmpCloseBtnHot  : TBitmap;
    mainCloseOver   : Boolean;
    mainInfoOver    : Boolean;
    isGenBtnDown    : Boolean;
    mp3             : TMP3Player;

const
  genBtnRect   : TRect = (Left: 105; Top: 200; Right: 162; Bottom: 268);
  genBtnUpdRect: TRect = (Left: 93; Top: 187; Right: 169; Bottom: 275);
  closeBtnRect : TRect = (Left: 355; Top: 57; Right: 355+13; Bottom: 57+14);
  infoBtnRect  : TRect = (Left: 333; Top: 59; Right: 333+16; Bottom: 59+15);

function DialogProc(hDialog: HWND; Message: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  wndRegion   : HRGN;
  ps          : tagPAINTSTRUCT;
  nameBuf     : array[0..255] of char;
  len         : Integer;
  dc          : HDC;
  closeOverOld: Boolean;
  infoOverOld : Boolean;
begin
  result := 0;

  case Message of
    // Initialize skin, set window region and play mp3.
    WM_INITDIALOG:
    begin
      mainCloseOver := false;
      mainSkin := TBitmap.Create;
      mainSkin.LoadFromResourceName(HInstance, 'MAINSKIN');

      bmpCloseBtnHot := TBitmap.Create;
      bmpCloseBtnHot.LoadFromResourceName(HInstance, 'MAINCLOSEHOT');
      bmpInfoBtnHot := TBitmap.Create;
      bmpInfoBtnHot.LoadFromResourceName(HInstance, 'MAININFOHOT');

      hEdtBmpBrush := createBackgroundBrush(hDialog, 1000, mainSkin.Handle);
      wndRegion := BitmapToRegion(mainSkin, RGB(0,255,0));
      SetWindowRgn(hDialog, wndRegion, True);

      genButton := TBitmap.Create;
      genButton.LoadFromResourceName(HInstance, 'GENBUTTONDOWN');

      mp3 := TMP3Player.Create('MP3', 'MP3');
      mp3.Play(hDialog);
      SetDlgItemText(hDialog, 1000, 'ACME LABS');
      SendDlgItemMessage(hDialog, 1000, EM_SETLIMITTEXT , 30, 0);
      result := 1;
    end;

    // Reset flag for button drawing and trigger redraw.
    WM_LBUTTONUP:
    begin
      isGenBtnDown := false;
      InvalidateRect(hDialog, @genBtnUpdRect, TRUE);
    end;

    // Handle all button clicks and make sure we can drag the dialog window.
    WM_LBUTTONDOWN:
    begin
      if isPointInside(lParam, genBtnRect) then
      begin
        isGenBtnDown := true;
        dc := GetDC(hdialog);
        BitBlt(dc, genBtnUpdRect.Left, genBtnUpdRect.Top, genButton.Width, genButton.Height, genButton.Canvas.Handle, 0, 0, SRCCOPY);
        ReleaseDc(hDialog, dc);
        // get entered name and store it in global variable
        len := GetDlgItemText(hDialog, 1000, nameBuf, 256);
        if (len = 0) then nameBuf := 'TEAM ACME';
        doKeygenAction(nameBuf);
        // we might miss button up event if users releases the mouse above the messagebox, so we set the button state here
        isGenBtnDown := false;
        InvalidateRect(hDialog, @genBtnUpdRect, TRUE);
      end
      else if isPointInside(lParam, closeBtnRect) then
        EndDialog(hDialog, 0)
      else if isPointInside(lParam, infoBtnRect) then
        showInfoMessage(hDialog)
      else
        // Drag dialog by default.
        PostMessage(hDialog, WM_NCLBUTTONDOWN, HTCAPTION, lParam);
    end;

    // Handle hot-button drawing.
    WM_MOUSEMOVE:
    begin
      closeOverOld := mainCloseOver;
      mainCloseOver := isPointInside(lParam, closeBtnRect);
      infoOverOld := mainInfoOver;
      mainInfoOver := isPointInside(lParam, infoBtnRect);

      if mainCloseOver <> closeOverOld then
        InvalidateRect(hDialog, @closeBtnRect, false);
      if mainInfoOver <> infoOverOld then
        InvalidateRect(hDialog, @infoBtnRect, false);
    end;

    // Reduce flickering by preventing background erasure.
    WM_ERASEBKGND: result := 1;

    // Draw the skin bitmap on dialog window.
    WM_PAINT:
    begin
      BeginPaint(hDialog, ps);
      BitBlt(ps.hdc, 0, 0, mainSkin.Width, mainSkin.Height, mainSkin.Canvas.Handle, 0, 0, SRCCOPY);
      if isGenBtnDown then
        BitBlt(ps.hdc, genBtnUpdRect.Left, genBtnUpdRect.Top, genButton.Width, genButton.Height, genButton.Canvas.Handle, 0, 0, SRCCOPY);
      if mainCloseOver then
          BitBlt(ps.hdc, closeBtnRect.Left, closeBtnRect.Top, bmpCloseBtnHot.Width, bmpCloseBtnHot.Height, bmpCloseBtnHot.Canvas.Handle, 0, 0, SRCCOPY);
      if mainInfoOver then
        BitBlt(ps.hdc, infoBtnRect.Left, infoBtnRect.Top, bmpInfoBtnHot.Width, bmpInfoBtnHot.Height, bmpInfoBtnHot.Canvas.Handle, 0, 0, SRCCOPY);
      EndPaint(hDialog, ps);
    end;

    // Make lables transparent.
    WM_CTLCOLORSTATIC:
    begin
      SetBkMode(HDC(wParam), TRANSPARENT);
    end;

    // Make edit transparent.
    WM_CTLCOLOREDIT:
    begin
      SetBkMode(HDC(wParam), TRANSPARENT);
      result := LRESULT(hEdtBmpBrush);
    end;

    WM_COMMAND:
      begin
        // quit on ESC
        if (wParam = 2) then EndDialog(hDialog, 0);
      end;

    WM_CLOSE: EndDialog(hDialog, 0);

    WM_DESTROY:
    begin
      mainSkin.Free;
      genButton.Free;
      bmpCloseBtnHot.Free;
      bmpInfoBtnHot.Free;
      mp3.Free;
      DeleteObject(hEdtBmpBrush);
      PostQuitMessage(0);
    end;
  end;
end;

procedure WinMain;
begin
  DialogBox(HInstance, 'DIALOG', 0, @DialogProc);
end;

begin
  WinMain;
end.
