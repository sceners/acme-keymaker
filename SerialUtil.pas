unit SerialUtil;

interface

function getVolumeSerial(var serial: Cardinal): Boolean; overload;
function getVolumeSerial: String; overload;
function getFFXPExePath: String;
function getFFXPKeyFile: String;
function getKeyFileChecksum(content: Pointer; len: Cardinal): Cardinal;
function getPublicKey: String;
function getPrivateKey: String;
function getFFXPDataDir: String;
function getFFXPIniFile: String;

implementation

uses Windows, Registry, Classes, SysUtils, Crc32, Util;

const
  regKey = '\SOFTWARE\FlashFXP\4';
  installPathVal = 'Install Path';
  installDataPathVal = 'InstallerDataPath';

// Load string from resource section.
function loadResString(id: Integer; name: String): String;
var
  rs: TResourceStream;
begin
  try
    rs := TResourceStream.CreateFromID(0, id, PChar(name));
    try
      SetString(result, PChar(rs.Memory), rs.Size);
    finally
      rs.Free;
    end;
  except
    on e: Exception do errorDialog('Unable to load string from resource: ' + e.Message);
  end;
end;

function getPublicKey: String;
begin
  result := loadResString(101, 'PUB_KEY');
end;

function getPrivateKey: String;
begin
  result := loadResString(102, 'PRIV_KEY');
end;

// Check if FlashFXP.exe exists in given directory.
function ffxpExists(path: String): Boolean;
begin
  result := fileExists(path + '\FlashFXP.exe');
end;

// Check if the given file is exists and is writable.
function fileExists(path: String): Boolean;
var
  fs: TFileStream;
begin
  fs := nil;
  try
    try
      fs := TFileStream.Create(path, fmOpenReadWrite);
      result := true;
    except
      result := false;
    end;
  finally
    if (Assigned(fs)) then fs.Free;
  end;
end;

// Return absolute path to FlashFXP.exe.
function getFFXPExePath: String;
var
  reg : TRegistry;
begin
  result := '';
  // check registry
  reg := TRegistry.Create;
  reg.RootKey := HKEY_LOCAL_MACHINE;
  reg.OpenKeyReadOnly(regKey);
  result := reg.ReadString(installPathVal);
  reg.Free;
  result := result + '\FlashFXP.exe'
end;

function getFFXPDataDir: String;
var
  reg: TRegistry;
begin
  reg := TRegistry.Create;
  reg.RootKey := HKEY_LOCAL_MACHINE;
  reg.OpenKeyReadOnly(regKey);
  result := reg.ReadString(installDataPathVal);
  reg.Free;
end;

// Return absolute path to flashfxp.key.
function getFFXPKeyFile: String;
begin
  result := getFFXPDataDir + '\flashfxp.key';
end;

// Return absolute path to FlashFXP.ini.
function getFFXPIniFile: String;
begin
  result := getFFXPDataDir + '\FlashFXP.ini';
end;

// Return the volume serial of the drive where FlashFXP.exe is installed.
function getVolumeSerial(var serial: Cardinal): Boolean; overload;
var
  fileInfo: TByHandleFileInformation;
  h: THandle;
begin
  result := False;
  h := CreateFile(PChar(getFFXPExePath), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, FILE_ATTRIBUTE_NORMAL);
  if GetFileInformationByHandle(h, fileInfo) then
  begin
    serial := fileInfo.dwVolumeSerialNumber;
    result := True;
  end;
  CloseHandle(h);
end;

// Return the volume serial of the driver where FlashFXP is installed as a string
function getVolumeSerial: String; overload;
var
  serial   : Cardinal;
  strSerial: String;
begin
  if getVolumeSerial(serial) then
  begin
    strSerial := IntToStr(serial);
    result := IntToStr(getCRC32(PChar(strSerial), Length(strSerial)));
  end
  else result := '';
end;

// Calculate the checksum over the contents of the keyfile.
function getKeyFileChecksum(content: Pointer; len: Cardinal): Cardinal;
begin
  result := getModifiedCRC32(content, len);
end;

end.
