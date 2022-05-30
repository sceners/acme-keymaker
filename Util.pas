unit Util;

interface

function bytesToHex(input: PChar; len: Integer): String;
function isWriteable(path: String): Boolean;
procedure errorDialog(msg: String);

implementation

uses Dialogs, SysUtils, Classes;

procedure errorDialog(msg: String);
begin
  MessageDlg(msg, mtError, [mbOk], 0);
end;

// Convert byte buffer to hex.
function bytesToHex(input: PChar; len: Integer): String;
var
  i: Integer;
begin
  result := '';
  for i := 0 to len-1 do result := result + IntToHex(Integer(input[i]), 2);
end;

// Check if given file is writable (quite hackish).
function isWriteable(path: String): Boolean;
var
  fs: TFileStream;
begin
  try
    fs := TFileStream.Create(path, fmOpenReadWrite);
    fs.Free;
    result := true;
  except
    result := false;
  end;
end;

end.
 