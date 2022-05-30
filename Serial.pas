unit Serial;

interface

uses Windows;

function writeKeyFile(path: String; name: String; email: String): Boolean;

implementation

uses Classes, SysUtils, Registry, Narf, Base64, FGInt, dialogs, Hash, SerialUtil, HKStreamRoutines, Util, Crc32;

// The header used by the encrypted keyfile.
type TKeyfileHeader = record
  Name: array[1..7] of char;
  Unkn1: Cardinal;
  Unkn2: Cardinal;
  FileSize: Cardinal;
  Checksum: Cardinal;
end;

const
  KeyfileEncryptionKey = '4EBDBB45064D7B3387329D66D2771121C2E6F418';
  Company              = 'N/A';
  NumberOfSeats        = '99999999';
  LicenseDate          = '12-24-2010';

function getLicenseString(name: String; email: String): String;
begin
  result := name + Company + email + NumberOfSeats + LicenseDate;
end;

// Shuffle the given string in the same manner as FlashFXP.
function getMixedString(source: String): String;
var tmp    : String;
    i, j, k: Integer;
begin
  // padd string so length is multiple of 4
  source := source + char($80);
  for j := 4 - Length(source) mod 4 downto 1 do source := source + char($0);

  result := '';
  // process 4 chars a time
  for i := 0 to (Length(source) div 4)-1 do
  begin
    tmp := Copy(source, (4*i)+1, 4);
    for k := 0 to 3 do result := result + tmp[4-k];
  end;
end;

// Creates a shuffled/padded memory block based on the input string.
// The memory block is then hashed lateron.
function createHashInput(source: String; var len: Integer): PChar;
var tmpResult  : PChar;
    mixedString: String;
    i, r       : Integer;
begin
  mixedString := getMixedString(source);
  // length of input string must be multiple of $40
  len := Length(source);
  r := $40 - (len mod $40);
  len := len + r;
  if (r <= 8) then len := len + $40;

  Getmem(tmpResult, len);
  FillChar(tmpResult^, len, 0);
  for i := 0 to Length(mixedString)-1 do tmpResult[i] := mixedString[i+1];

  // we need to append length in bits
  (PInteger(@tmpResult[len-4]))^ := Length(source) * 8;
  result := tmpResult;
end;

// Sign the given hash with RSA and return result as PGPBase64 string
function doRSA(hashString: String): String;
var modulus    : TFGInt;
    exp        : TFGInt;
    rsaResult  : TFGInt;
    result256  : String;
    cryptBuffer: String;
    message    : TFGInt;
begin
  // we need to crypt the HEX-STRING as raw bytes!!!
  // hash starts at char 9 so we fill up with '1'
  cryptBuffer := '11111111' + hashString;
  Base256StringToFGInt(cryptBuffer, message);

  // read in our modulus and private exponent
  Base10StringToFGInt(getPublicKey, modulus);
  Base10StringToFGInt(getPrivateKey, exp);

  // RSA
  FGIntModExp(message, exp, modulus, rsaResult);

  // now convert result to PGP64 string
  FGIntToBase256String(rsaResult, result256);
  PGPConvertBase256to64(result256, result);
end;

function scramble(value: Cardinal): Cardinal; register;
begin
  asm
    rol     eax, 1
    add     eax, $139A1FC4
    mov     result, eax
  end
end;

// Generate a pseudo-random stream which is xored with the input string.
// Uses the volume serial as the initialization vector.
function scrambleData(data: String): String;
var
  i: Integer;
  b: Byte;
  s: Cardinal;
  tmp: Char;
begin
  getVolumeSerial(s);
  SetLength(result, Length(data));
  for i := 1 to Length(data) do
  begin
    b := Byte(data[i]);
    tmp := Char(b xor s);
    s := scramble(s);
    result[i] := tmp;
  end
end;

// Generate the raw ffxp auth block in base256 consisting of the RSA signature
// and the other authorization data.
function generateAuthBlock(name: String; email: String): String;
var
  authBlock         : String;
  scrambledAuthBlock: String;
  hashVal           : array[0..19] of char;
  mixStr            : PChar;
  len               : Integer;
  hashString        : String;
  base64Signature   : String;
  base64Data        : String;
begin
  mixStr := createHashInput(getLicenseString(name, email), len);
  //Fillchar(hashVal, 20, 1);
  calcHash(PChar(mixStr), len, hashVal);
  Freemem(mixStr);

  // now convert hash to hex string
  hashString := bytesToHex(hashVal, 20);
  // sign hash with RSA and put PGPBase64 output in lines 6-8!
  base64Signature := doRSA(hashString);

  authBlock := name + sLineBreak + Company + sLineBreak + email + sLineBreak + NumberOfSeats + sLineBreak + LicenseDate + sLineBreak + base64Signature;
  authBlock := '-------- FlashFXP Registration Data START --------' + sLineBreak + authBlock + sLineBreak + '-------- FlashFXP Registration Data END --------' + sLineBreak;

  scrambledAuthBlock := scrambleData(authBlock);
  // Note: modified base64 conversion!
  PGPConvertBase256to64(scrambledAuthBlock, base64Data);

  result := base64Data;
end;

// Calculate the CRC32 value of the authorization string.
function getAuthStringCRC(name: String; email: String): Cardinal;
var
  crcInput: String;
begin
  crcInput := getLicenseString(name, email);
  result := getCRC32(PChar(crcInput), Length(crcInput));
end;

// Generate the keyfile serials. CRC32 of the auth string is used to xor over
// the SHA-1 hash over the input which was signed via RSA.
procedure generateSerial(name: String; email: String; var serialStr: String; var invertedSerialStr: String);
var
  crc32    : Cardinal;
  hash     : array[0..19] of char;
  hashInput: PChar;
  i, len   : Integer;
  serial   : Cardinal;
begin
  crc32 := getAuthStringCRC(name, email);
  hashInput := createHashInput(getLicenseString(name, email), len);

  calcHash(hashInput, len, hash);
  serial := crc32;
  for i := 0 to 4 do
  begin
    serial := serial xor PCardinal(@hash[i*4])^;
  end;
  
  serialStr := IntToStr(serial);
  invertedSerialStr := IntToStr(not serial);
end;

// The plain keyfile content consists of the authorization block as well as a serial block.
function generateKeyFileContent(name: String; email: String): String;
var
  authBlock     : String;
  serial        : String;
  invertedSerial: String;
begin
  authBlock := generateAuthBlock(name, email);
  result := '[4]' + sLineBreak + getVolumeSerial + '=' + authBlock + sLineBreak + sLineBreak;

  generateSerial(name, email, serial, invertedSerial);
  result := result + '[' + invertedSerial + ']' + sLineBreak + serial + '=' + serial;
end;

function writeKeyFile(path: String; name: String; email: String): Boolean;
var
  header : TKeyfileHeader;
  ms     : TMemoryStream;
  fs     : TFileStream;
  content: String;
const
  pad   : array[0..1] of char = #0;
begin
  result := False;
  try
    ms := TMemoryStream.Create;
    fs := TFileStream.Create(path, fmCreate);
    try
      content := generateKeyFileContent(name, email);
      ms.Write(Pointer(content)^, Length(content));
      // Pad with zeros (padding in HKStreamRoutines has been removed!)
      while (ms.Size mod 8 <> 0) do ms.WriteBuffer(pad, 1);

      header.FileSize := ms.Size;
      header.Checksum := getKeyFileChecksum(ms.Memory, ms.Size);
      header.Name := 'ESTREAM';
      header.Unkn1 := $20000;
      header.Unkn2 := $100;

      EncryptStream(ms, KeyfileEncryptionKey);

      fs.WriteBuffer(Pointer(@header)^, sizeof(header));
      ms.SaveToStream(fs);
      result := True;
    finally
      ms.Free;
      fs.Free;
    end
  except
    on e: Exception do errorDialog('Unable to write keyfile: ' + e.Message);
  end

end;

end.

