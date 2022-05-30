unit Hash;

interface

procedure calcHash(input: PChar; len: Integer; output: PChar);

implementation

procedure rippedHash;
  label loc_479E33;
  label loc_479BBF;
  label loc_479C91;
  label loc_479BE1;
  label loc_479C25;
  label loc_479CF9;
  label loc_479D68;
begin
  asm
                push    ebp
                mov     ebp, esp   
                add     esp, 4294967260
                pusha              
                mov     eax, [ebp+8]
                mov     [ebp-4], eax
                mov     eax, [ebp+12]
                mov     [ebp-8], eax
                mov     eax, [ebp+16]
                mov     [ebp-12], eax
                push    64         
                pop     ebx        
                xor     edx, edx   
                div     ebx        
                test    edx, edx   
                jnz     loc_479E33 
                mov     [ebp-16], eax
                mov     edi, [ebp-8]
                mov     dword ptr [edi], 1732584193
                mov     dword ptr [edi+4], 4023233417
                mov     dword ptr [edi+8], 2562383102
                mov     dword ptr [edi+12], 271733878
                mov     dword ptr [edi+16], 3285377520
                mov     edi, [ebp-4]
                  
loc_479BBF:
                mov     esi, [ebp-8]
                mov     eax, [esi]
                mov     ebx, [esi+4]
                mov     ecx, [esi+8]
                mov     edx, [esi+12]
                mov     esi, [esi+16]
                mov     [ebp-20], eax
                mov     [ebp-24], ebx
                mov     [ebp-28], ecx
                mov     [ebp-32], edx
                mov     [ebp-36], esi
                xor     esi, esi   
                  
loc_479BE1:
                mov     eax, [ebp-20]
                rol     eax, 5     
                mov     ebx, [ebp-32]
                mov     edx, ebx   
                xor     edx, [ebp-28]
                and     edx, [ebp-24]
                xor     ebx, edx   
                add     ebx, [ebp-36]
                lea     ebx, [ebx+eax+1518500249]
                add     ebx, [edi+esi*4]
                mov     eax, [ebp-32]
                mov     [ebp-36], eax
                mov     eax, [ebp-28]
                mov     [ebp-32], eax
                mov     eax, [ebp-24]
                ror     eax, 2     
                mov     [ebp-28], eax
                mov     eax, [ebp-20]
                mov     [ebp-24], eax
                mov     [ebp-20], ebx
                inc     esi        
                cmp     esi, 16    
                jnz     loc_479BE1
                  
loc_479C25:
                mov     eax, [ebp-20]
                rol     eax, 5
                mov     ebx, [ebp-32]
                mov     edx, ebx   
                xor     edx, [ebp-28]
                and     edx, [ebp-24]
                xor     ebx, edx   
                add     ebx, [ebp-36]
                lea     ebx, [ebx+eax+1518500249]
                lea     edx, [esi] 
                and     edx, 15    
                lea     ecx, [edi+edx*4]
                mov     eax, [ecx] 
                lea     edx, [esi+2]
                and     edx, 15    
                xor     eax, [edi+edx*4]
                lea     edx, [esi+8]
                and     edx, 15    
                xor     eax, [edi+edx*4]
                lea     edx, [esi+13]
                and     edx, 15    
                xor     eax, [edi+edx*4]
                rol     eax, 1     
                mov     [ecx], eax 
                add     ebx, eax   
                mov     eax, [ebp-32]
                mov     [ebp-36], eax
                mov     eax, [ebp-28]
                mov     [ebp-32], eax
                mov     eax, [ebp-24]
                ror     eax, 2     
                mov     [ebp-28], eax
                mov     eax, [ebp-20]
                mov     [ebp-24], eax
                mov     [ebp-20], ebx
                inc     esi        
                cmp     esi, 20
                jnz     loc_479C25

loc_479C91:
                mov     eax, [ebp-20]
                rol     eax, 5     
                mov     ebx, [ebp-24]
                xor     ebx, [ebp-28]
                xor     ebx, [ebp-32]
                add     ebx, [ebp-36]
                lea     ebx, [ebx+eax+1859775393]
                lea     edx, [esi] 
                and     edx, 15    
                lea     ecx, [edi+edx*4]
                mov     eax, [ecx] 
                lea     edx, [esi+2]
                and     edx, 15    
                xor     eax, [edi+edx*4]
                lea     edx, [esi+8]
                and     edx, 15    
                xor     eax, [edi+edx*4]
                lea     edx, [esi+13]
                and     edx, 15    
                xor     eax, [edi+edx*4]
                rol     eax, 1     
                mov     [ecx], eax 
                add     ebx, eax   
                mov     eax, [ebp-32]
                mov     [ebp-36], eax
                mov     eax, [ebp-28]
                mov     [ebp-32], eax
                mov     eax, [ebp-24]
                ror     eax, 2     
                mov     [ebp-28], eax
                mov     eax, [ebp-20]
                mov     [ebp-24], eax
                mov     [ebp-20], ebx
                inc     esi        
                cmp     esi, 40    
                jnz     loc_479C91
                  
loc_479CF9:
                mov     eax, [ebp-20]
                rol     eax, 5
                mov     ebx, [ebp-24]
                mov     edx, ebx   
                and     ebx, [ebp-28]
                or      edx, [ebp-28]
                and     edx, [ebp-32]
                or      ebx, edx   
                lea     ebx, [ebx+eax-1894007588]
                add     ebx, [ebp-36]
                lea     edx, [esi] 
                and     edx, 15    
                lea     ecx, [edi+edx*4]
                mov     eax, [ecx] 
                lea     edx, [esi+2]
                and     edx, 15    
                xor     eax, [edi+edx*4]
                lea     edx, [esi+8]
                and     edx, 15
                xor     eax, [edi+edx*4]
                lea     edx, [esi+13]
                and     edx, 15    
                xor     eax, [edi+edx*4]
                rol     eax, 1     
                mov     [ecx], eax 
                add     ebx, eax   
                mov     eax, [ebp-32]
                mov     [ebp-36], eax
                mov     eax, [ebp-28]
                mov     [ebp-32], eax
                mov     eax, [ebp-24]
                ror     eax, 2     
                mov     [ebp-28], eax
                mov     eax, [ebp-20]
                mov     [ebp-24], eax
                mov     [ebp-20], ebx
                inc     esi
                cmp     esi, 60    
                jnz     loc_479CF9
                  
loc_479D68:
                mov     eax, [ebp-20]
                rol     eax, 5     
                mov     ebx, [ebp-24]
                xor     ebx, [ebp-28]
                xor     ebx, [ebp-32]
                add     ebx, [ebp-36]
                lea     ebx, [ebx+eax-899497514]

                lea     edx, [esi] 
                and     edx, 15    
                lea     ecx, [edi+edx*4]
                mov     eax, [ecx] 
                lea     edx, [esi+2]
                and     edx, 15    
                xor     eax, [edi+edx*4]
                lea     edx, [esi+8]
                and     edx, 15
                xor     eax, [edi+edx*4]
                lea     edx, [esi+13]
                and     edx, 15    
                xor     eax, [edi+edx*4]
                rol     eax, 1     
                mov     [ecx], eax 
                add     ebx, eax   
                mov     eax, [ebp-32]
                mov     [ebp-36], eax
                mov     eax, [ebp-28]
                mov     [ebp-32], eax
                mov     eax, [ebp-24]
                ror     eax, 2     
                mov     [ebp-28], eax
                mov     eax, [ebp-20]
                mov     [ebp-24], eax
                mov     [ebp-20], ebx
                inc     esi
                cmp     esi, 80    
                jnz     loc_479D68
                mov     ebx, [ebp-8]
                mov     eax, [ebp-20]
                add     [ebx], eax 
                mov     eax, [ebp-24]
                add     [ebx+4], eax
                mov     eax, [ebp-28]
                add     [ebx+8], eax
                mov     eax, [ebp-32]
                add     [ebx+12], eax
                mov     eax, [ebp-36]
                add     [ebx+16], eax
                add     edi, 64    
                dec     dword ptr [ebp-16]
                jnz     loc_479BBF 
                mov     eax, [ebx] 
                bswap   eax        
                mov     [ebx], eax 
                mov     eax, [ebx+4]
                bswap   eax
                mov     [ebx+4], eax
                mov     eax, [ebx+8]
                bswap   eax        
                mov     [ebx+8], eax
                mov     eax, [ebx+12]
                bswap   eax        
                mov     [ebx+12], eax
                mov     eax, [ebx+16]
                bswap   eax        
                mov     [ebx+16], eax
                xor     eax, eax   
                mov     [ebp-20], eax
                mov     [ebp-24], eax
                mov     [ebp-28], eax
                mov     [ebp-32], eax
                mov     [ebp-36], eax
                  
loc_479E33:
                popa               
                mov     esp, ebp   
                pop     ebp        
                // delphi inline asm lacks retn 12 so the CALLER hs to cleanup the stack
                retn

  end;
end;

// Wrapper around the ripped hash.
procedure calcHash(input: PChar; len: Integer; output: PChar);
begin
  asm
    // save EBX
    push    esi
    push    ebx
    // length
    push    edx
    // dest
    push    ecx
    // source
    push    eax
  end;
  rippedHash;
  asm
    add     esp, 12
    // and restore again so delphi compiler optimizations dont make us crash
    pop     ebx
    pop     esi
  end;
end;

end.
