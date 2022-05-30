unit MP3Player;

interface

uses
  SysUtils, Classes, MPlayer, Windows;

type
  TMP3Player = class(TObject)
  private
    { Private declarations }
    player  : TMediaPlayer;
    rsMusic : TResourceStream;
    tempPath: String;
    procedure MediaPlayerNotify(Sender: TObject);
    function getTempFile: string;

  public
    { Public declarations }
    constructor create(resName: String; resType: String);
    destructor Destroy; override;
    procedure Play(hWnd: HWND);
  end;

implementation

constructor TMP3Player.create(resName, resType: String);
begin
  inherited Create;
  tempPath := getTempFile;
  rsMusic := TResourceStream.Create(HInstance, resName, PAnsiChar(resType));
  rsMusic.SaveToFile(tempPath);
  rsMusic.Free;
end;

destructor TMP3Player.Destroy;
begin
  player.Free;
  DeleteFile(PAnsiChar(tempPath));
  inherited;
end;

// Callback method - play mp3 in endless loop.
procedure TMP3Player.MediaPlayerNotify(Sender: TObject);
begin
  with Sender as TMediaPlayer do
  begin
    if (Position = Length) then
    begin
      Rewind;
      Play;
    end;
  end;
end;

function TMP3Player.getTempFile: string;
var
  buffer: array[0..MAX_PATH] of Char;
begin
  GetTempPath(SizeOf(buffer) - 1, buffer);
  GetTempFileName(buffer, '~', 0, buffer);
  Result := string(buffer) + 'narf.mp3';
end;

// Extract mp3, save it to temporary file and play.
procedure TMP3Player.Play(hWnd: HWND);
begin
  try
    player := TMediaPlayer.CreateParented(hwnd);
    player.FileName := tempPath;
    player.Notify := true;
    player.OnNotify := MediaPlayerNotify;
    player.Open;
    player.Play;
  except
    on EMCIDeviceError do player.Notify := false;
  end;
end;

end.
 