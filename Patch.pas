unit Patch;

interface

function patchFFXP: Integer;

// Possible return values of the patch function.
const
  ErrorNotWritable    = 0;
  PatchSuccess        = 1;
  AlreadyPatched      = 2;
  StringTableNotFound = 3;

implementation

uses Windows, Classes, SerialUtil, Dialogs, SysUtils, Util, Math, StrUtils;

const
  // The resource id of the public key (might change for new versions of FlashFXP).
  ResourceId = 63563;
  // The beginning of the actual public key (so we can locate and replace it).
  PartialPubKey = '2216:1:7:71368161:465:49844';

type
  TStringTableEntry = record
    strings: array[1..16] of String;
    id: Cardinal;
  end;

var
  stringTableIds: TList;

// Copy the strings from the raw data pointer into the given record.
function parseStringTableEntry(dataPointer: PWideChar; var entry: TStringTableEntry): Boolean;
var
  i, len: Integer;
const
  langId = 0;
begin
  if Assigned(dataPointer) then
  begin
    for i := 1 to 16 do
    begin
      len := Integer(dataPointer^);
      Inc(dataPointer);
      entry.strings[i] := WideCharLenToString(dataPointer, len);
      Inc(dataPointer, len);
    end;

    result := True;
  end
  else result := False;
end;

// Locate the corresponding string table entry and return its contents.
function getStringTableEntry(module: HMODULE; resourceId: Integer; var entry: TStringTableEntry): Boolean;
var
  blockId : Integer;
  hRes    : HRSRC;
  hResData: HGLOBAL;
  data    : Pointer;
begin
  result := False;
  blockId := (resourceId div 16) + 1;
  hRes := FindResourceEx(module, RT_STRING, MAKEINTRESOURCE(blockId), 0);
  hResData := LoadResource(module, hRes);
  if hResData <> 0 then
  begin
    data := LockResource(hResData);
    entry.id := blockId;
    result := parseStringTableEntry(data, entry);
  end
end;

// Check whether one of the table entries starts with the given string.
function containsPartialString(entry: TStringTableEntry; str: String; var index: Integer): Boolean;
var
  i: Integer;
begin
  i := 1;
  result := False;
  while (not result) and (i < 17) do
  begin
    result := str = LeftStr(entry.strings[i], Length(str));
    Inc(i);
  end;
  if result then index := i - 1;
end;
  
// Callback for EnumNames API.
function EnumNamesFunc(hModule: HMODULE; lpType: PChar; lpName: PChar; lParam: Integer): Boolean; stdcall;
begin
  if not (Integer(lpType) and $FFFF0000 <> 0) then
  begin
    stringTableIds.Add(lpName);
  end;
  result := true;
end;

// Enumerate all existing resource ids in the string table.
function enumStringTableIds: Boolean;
var
  hInst: HMODULE;
begin
  result := false;
  stringTableIds.Clear;
  hInst := LoadLibrary(PChar(getFFXPExePath));
  if hInst <> 0 then
  begin
    EnumResourceNames(hInst, RT_STRING, @EnumNamesFunc, 0);
    FreeLibrary(hInst);
    result := true;
  end;
end;

// Search the whole list of resource ids for the given string.
function findString(hModule: HMODULE; str: String; resourceIds: TList; var index: Integer): Boolean;
var
  i: Integer;
  entry: TStringTableEntry;
begin
  result := false;
  for i := 0 to resourceIds.Count - 1 do
  begin
    getStringTableEntry(hModule, Integer(resourceIds.Items[i]), entry);
    if containsPartialString(entry, str, index) then
    begin
      result := true;
      break;
    end;
  end;
end;

// Create a new string table block which can be used to update the string table resources.
function buildNewStringBlock(srcEntry: TStringTableEntry; var newBlock: Pointer; var len: Integer): Boolean;
var
  block : PWideChar;
  i     : Integer;
  wStr  : WideString;
  wcPtr : PWideChar;
begin
  result := False;
  len := 0;
  newBlock := nil;

  for i := 1 to 16 do
  begin
    len := len + (Length(srcEntry.strings[i]) + 1) * SizeOf(WideChar);
  end;

  GetMem(block, len);
  newBlock := block;
  if Assigned(block) then
  begin
    for i := 1 to 16 do
    begin
      block^ := WideChar(Length(srcEntry.strings[i]));
      Inc(block);
      wStr := srcEntry.strings[i];
      wcPtr := PWideChar(wStr);
      Move(wcPtr^, block^, Length(srcEntry.strings[i]) * SizeOf(WideChar));
      Inc(block, Length(srcEntry.strings[i]));
    end;
    result := True;
  end;
end;

function writeStringTableEntry(module: HMODULE; resourceId: Integer; entry: TStringTableEntry): Boolean;
var
  hResource: THandle;
  blockId  : Integer;
  newBlock : Pointer;
  len: Integer;
  fxp: PChar;
begin
  result := False;
  fxp := PChar(getFFXPExePath);
  hResource := BeginUpdateResource(fxp, False);
  if hResource <> 0 then
  begin
    blockId := (resourceId div 16) + 1;
    buildNewStringBlock(entry, newBlock, len);
    if Assigned(newBlock) then
    begin
      if UpdateResource(hResource, RT_STRING, MAKEINTRESOURCE(blockId), 0, newBlock, len) then
      begin
        result := EndUpdateResource(hResource, False);
      end
      else
      begin
        EndUpdateResource(hResource, False);
      end;
    end;
  end;
end;

// FlashFXP descrambles the public key so we need to scramble our own key as well.
function scrambleKey(key: String): String;
var
  i: Integer;
begin
  SetLength(result, Length(key));
  for i := 1 to Length(key) do
  begin
    result[i] := Chr(Ord(key[i]) + 1);
  end;
end;

// Reset the checksum in the PE header so FlashFXP doesn't complain about being corrupted.
function fixPEChecksum: Boolean;
var
  dosHeader : PImageDosHeader;
  ntHeader  : PImageNtHeaders;
  hFile     : THandle;
  hMapping  : THandle;
  mappedExe : Pointer;
begin
  result := false;
  hFile := CreateFile(PChar(getFFXPExePath), GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
  if hFile <> INVALID_HANDLE_VALUE then
  begin
    hMapping := CreateFileMapping(hFile, nil, PAGE_READWRITE, 0, 0, nil);
    if hMapping <> INVALID_HANDLE_VALUE then
    begin
      mappedExe := MapViewOfFile(hMapping, FILE_MAP_ALL_ACCESS, 0, 0, 0);
      if Assigned(mappedExe) then
      begin
        dosHeader := PImageDosHeader(mappedExe);
        ntHeader := PImageNtHeaders(Cardinal(mappedExe) + Cardinal(dosHeader^._lfanew));
        ntHeader^.OptionalHeader.CheckSum := 0;
        result := true;
        UnmapViewOfFile(mappedExe);
      end;
      CloseHandle(hMapping);
    end;

    CloseHandle(hFile);
  end;
end;

// Locate resource entry of public key in string table and replace it with our key.
// Also, disable live update so we do not phone home.
function patchFFXP: Integer;
var
  hInst: HMODULE;
  entry: TStringTableEntry;
  index: Integer;
begin
  result := ErrorNotWritable;
  if fixPEChecksum then
  begin
    WritePrivateProfileString('LiveUpdate', 'check', '0', PChar(getFFXPIniFile));
    hInst := LoadLibraryEx(PChar(getFFXPExePath), 0, DONT_RESOLVE_DLL_REFERENCES or LOAD_LIBRARY_AS_DATAFILE);
    if getStringTableEntry(hInst, ResourceId, entry) then
    begin
      FreeLibrary(hInst);
      if containsPartialString(entry, PartialPubKey, index) then
      begin
        entry.strings[index] := scrambleKey(getPublicKey);
        result := IfThen(writeStringTableEntry(hInst, ResourceId, entry), PatchSuccess, ErrorNotWritable);
      end
      else
      begin
        // TODO: explicitly search for our public key to make sure
        // that FlashFXP is actually patched.
        result := AlreadyPatched;
      end;
    end
    else
    begin
      FreeLibrary(hInst);
      result := StringTableNotFound;
    end;
  end;
end;

begin
  stringTableIds := TList.Create;
end.
