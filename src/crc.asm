;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; CRC16 algorithm.
;-----------------------------------------------------------------------------

; Description: Calculate the CRC16-CCITT of the byte array pointed by DE, of
; length BC.
;
; Input:
;   BC: length of byte array, can be 0
;   HL: pointer to data
; Output:
;   DE: new CRC value
; Destroys: A, BC, DE, HL
;
; The CRC16-CCITT algorithm was generated from the pycrc script at
; https://pycrc.org/models.html. The CRC parameters are:
;
; Width   16
; Poly    0x1021
; Reflect In  False
; XOR In  0x1d0f
; Reflect Out False
; XOR Out 0x0000
; Short command   pycrc.py --model crc-16-ccitt
; Extended command    pycrc.py --width 16 --poly 0x1021 --reflect-in False
; --xor-in 0x1d0f --reflect-out False --xor-out 0x0000
; Check   0xe5cc
;
; The generated C code for the bit-by-bit version looks like this:
;
; crc_t crc_update(crc_t crc, const void *data, size_t data_len)
; {
;    const unsigned char *d = (const unsigned char *)data;
;    uint8_t i;
;    crc_t bit;
;    unsigned char c;
;
;    while (data_len--) {
;        c = *d++;
;        for (i = 0x80; i > 0; i >>= 1) {
;            bit = (crc & 0x80) ^ ((c & i) ? 0x80 : 0);
;            crc <<= 1;
;            if (bit) {
;                crc ^= 0x07;
;            }
;        }
;        crc &= 0xff;
;    }
;    return crc & 0xff;
; }
crc16ccitt:
    ex de, hl ; DE=pointer to data
    ld hl, $1D0F
    jr crc16ccitt_char_next
crc16ccitt_char_loop:
    ld a, (de) ; A=(DE)=char
    inc de
crc16ccitt_bit_setup:
    push bc
    ld b, 8
    ; The formula above calculates the XOR of bit7 one at a time, bit7=(crc &
    ; 0x8000) ^ ((c & i) ? 0x8000 : 0). But an XOR operation is associative and
    ; commutative, so we can factor out the XOR, and pre-calculate it for all 8
    ; bits before entering the loop. Credit to
    ; https://www.tomdalby.com/other/crc.html for this trick.
    xor h
    ld h, a
crc16ccitt_bit_loop:
    add hl, hl ; crc<<=1; CF=bit7
    jr nc, crc16ccitt_bit_next
    ld a, l
    xor $21
    ld l, a
    ld a, h
    xor $10
    ld h, a ; HL^=$1021
crc16ccitt_bit_next:
    djnz crc16ccitt_bit_loop
    pop bc
    dec bc ; does not affect flags
crc16ccitt_char_next:
    ld a, b
    or c ; if BC==0: ZF=1
    jr nz, crc16ccitt_char_loop
    ex de, hl ; DE=CRC16
    ret
