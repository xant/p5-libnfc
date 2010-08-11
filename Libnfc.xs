#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <nfc/nfc.h>

#ifndef MAX_FRAME_LEN
#define MAX_FRAME_LEN 264
#endif

/* Global Data */

#define MY_CXT_KEY "RFID::Libnfc::_guts" XS_VERSION
typedef nfc_device_t * nfc_device_tPtr;

typedef struct {
    /* Put Global Data in here */
    int dummy;                /* you can access this elsewhere as MY_CXT.dummy */
} my_cxt_t;

START_MY_CXT

#include "const-c.inc"

MODULE = RFID::Libnfc                PACKAGE = RFID::Libnfc                

INCLUDE: const-xs.inc

BOOT:
{
    MY_CXT_INIT;
    /* If any of the fields in the my_cxt_t struct need
       to be initialised, do it here.
     */
}


void
append_iso14443a_crc(pbtData, uiLen)
        byte_t *        pbtData
        uint32_t        uiLen

byte_t
mirror(bt)
        byte_t        bt

uint32_t
mirror32(ui32Bits)
        uint32_t        ui32Bits

uint64_t
mirror64(ui64Bits)
        uint64_t        ui64Bits

_Bool
nfc_configure(pnd, ndo, bEnable)
        nfc_device_t *        pnd
        nfc_device_option_t   ndo
        _Bool        bEnable

nfc_device_t *
nfc_connect()
    CODE:
        RETVAL=nfc_connect(NULL);
    OUTPUT:
        RETVAL

void
nfc_disconnect(pnd)
        nfc_device_t *        pnd

_Bool
nfc_initiator_deselect_target(pnd)
        nfc_device_t *        pnd
    CODE:
#ifndef NFC_DEPRECATED
        RETVAL=nfc_initiator_deselect_target(pnd);
#else
        RETVAL=nfc_initiator_deselect_tag(pnd);
#endif
    OUTPUT:
        RETVAL

_Bool
nfc_initiator_select_passive_target(pnd, nmInitModulation, pbtInitData, uiInitDataLen, pti)
        nfc_device_t *        pnd
        nfc_modulation_t      nmInitModulation
        byte_t *        pbtInitData
        uint32_t        uiInitDataLen
        nfc_target_info_t *        pti
    CODE:
#ifndef NFC_DEPRECATED
        RETVAL=nfc_initiator_select_passive_target(pnd, nmInitModulation, pbtInitData, uiInitDataLen, pti);
#else
        RETVAL=nfc_initiator_select_tag(pnd, nmInitModulation, pbtInitData, uiInitDataLen, pti);
#endif
    OUTPUT:
        RETVAL

_Bool
nfc_initiator_init(pnd)
        nfc_device_t *        pnd

SV *
nfc_initiator_transceive_dep_bytes(pnd, pbtTx, szTxLen)
        nfc_device_t *  pnd
        byte_t *        pbtTx
        size_t          szTxLen
    PREINIT:
        byte_t *        pbtRx;
        size_t          szRxLen;
        SV *            sv = &PL_sv_undef;
    CODE:
        pbtRx = malloc(MAX_FRAME_LEN);
        if (nfc_initiator_transceive_dep_bytes(pnd, pbtTx, szTxLen,  pbtRx, &szRxLen))
            sv = newSVpv((char *)pbtRx, szRxLen);
        else 
            sv = newSV(0);
        free(pbtRx);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
nfc_initiator_transceive_bits(pnd, pbtTx, uiTxBits)
        nfc_device_t *        pnd
        byte_t *        pbtTx
        uint32_t        uiTxBits
    PREINIT:
        int             rc;            
        uint32_t        len;
        size_t          puiRxBits = 0;
        byte_t          *pbtRx;
        SV              *sv = &PL_sv_undef;
    CODE:
        pbtRx = malloc(MAX_FRAME_LEN);
        // TODO - handle parity
        if (nfc_initiator_transceive_bits(pnd, pbtTx, uiTxBits,  NULL, pbtRx, &puiRxBits, NULL))
            sv = newSVpv((char *)pbtRx, puiRxBits/8);
        else 
            sv = newSV(0);
        free(pbtRx);
        RETVAL = sv;
    OUTPUT:
        RETVAL



SV *
nfc_initiator_transceive_bytes(pnd, pbtTx, uiTxLen)
        nfc_device_t *  pnd
        byte_t *        pbtTx
        uint32_t        uiTxLen
    PREINIT:
        int             rc;            
        uint32_t        len;
        byte_t *        pbtRx;
        size_t          puiRxLen = 0;
        SV              *sv = &PL_sv_undef;
    CODE:
        pbtRx = malloc(MAX_FRAME_LEN);
        if (nfc_initiator_transceive_bytes(pnd, pbtTx, uiTxLen,  pbtRx, &puiRxLen))
            sv = newSVpv((char *)pbtRx, puiRxLen);
        else 
            sv = newSV(0);
        free(pbtRx);
        RETVAL = sv;
    OUTPUT:
        RETVAL


SV *
nfc_target_init(pnd)
        nfc_device_t *  pnd
    PREINIT:
        SV *            sv;
        byte_t *        pbtRx;
        size_t          uiRxBits;
    CODE:
        pbtRx = malloc(MAX_FRAME_LEN);
        if (nfc_target_init(pnd, pbtRx, &uiRxBits))
            sv = newSVpv((char *)pbtRx, uiRxBits/8+1);
        else 
            sv = newSV(0);
        free(pbtRx);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
nfc_target_receive_bits(pnd)
        nfc_device_t *      pnd
    PREINIT:
        SV *            sv;
        byte_t *        pbtRx;
        byte_t          btRxPar;
        size_t          uiRxBits;
    CODE:
        pbtRx = malloc(MAX_FRAME_LEN);
        if (nfc_target_receive_bits(pnd, pbtRx, &uiRxBits, &btRxPar))
            sv = newSVpv((char *)pbtRx, uiRxBits/8+1);
        else 
            sv = newSV(0);
        free(pbtRx);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
nfc_target_receive_bytes(pnd, pbtRx)
        nfc_device_t *        pnd
    PREINIT:
        _Bool           rc;            
        uint32_t        len;
        size_t          puiRxLen;
        byte_t *        pbtRx;
        SV              *sv;
    CODE:
        pbtRx = malloc(MAX_FRAME_LEN);
        rc = nfc_target_receive_bytes(pnd, pbtRx, &puiRxLen);
        if (rc)
            sv = newSVpv((char *)pbtRx, puiRxLen);
        else
            sv = newSV(0);
        free(pbtRx);
        RETVAL = sv;
    OUTPUT:
        RETVAL

_Bool
nfc_target_send_bits(pnd, pbtTx, uiTxBits, pbtTxPar)
        nfc_device_t *  pnd
        byte_t *        pbtTx
        uint32_t        uiTxBits
        byte_t *        pbtTxPar

_Bool
nfc_target_send_bytes(pnd, pbtTx, uiTxLen)
        nfc_device_t *        pnd
        byte_t *        pbtTx
        uint32_t        uiTxLen

byte_t
oddparity(bt)
        byte_t        bt

void
print_hex(__data, uiLen = NO_INIT)
        SV *__data
        STRLEN uiLen
    PREINIT:
        byte_t *        pbtData = NULL;
    CODE:
        // TODO - allow to specify an offset as well
        if (SvPOK(__data)) {
            if (items > 1) 
                pbtData = (byte_t *)SvPV_nolen(__data);
            else
                pbtData = (byte_t *)SvPV(__data, uiLen);
            print_hex(pbtData, uiLen);
        }


void
print_hex_bits(pbtData, uiBits)
        byte_t *        pbtData
        uint32_t        uiBits

void
print_hex_par(pbtData, uiBits, pbtDataPar)
        byte_t *        pbtData
        uint32_t        uiBits
        byte_t *        pbtDataPar

uint32_t
swap_endian32(pui32)
        void *        pui32

uint64_t
swap_endian64(pui64)
        void *        pui64

MODULE = RFID::Libnfc        PACKAGE = nfc_iso14443a_info_t

nfc_iso14443a_info_t *
_to_ptr(THIS)
    nfc_iso14443a_info_t THIS = NO_INIT
    PROTOTYPE: $
    CODE:
    if (sv_derived_from(ST(0), "nfc_iso14443a_info_t")) {
        STRLEN len;
        char *s = SvPV((SV*)SvRV(ST(0)), len);
        if (len != sizeof(THIS))
        croak("Size %d of packed data != expected %d",
            len, sizeof(THIS));
        RETVAL = (nfc_iso14443a_info_t *)s;
    }
    else
        croak("THIS is not of type nfc_iso14443a_info_t");
    OUTPUT:
    RETVAL

nfc_iso14443a_info_t
new(CLASS)
    char *CLASS = NO_INIT
    PROTOTYPE: $
    CODE:
    Zero((void*)&RETVAL, sizeof(RETVAL), char);
    OUTPUT:
    RETVAL

MODULE = RFID::Libnfc        PACKAGE = nfc_iso14443a_info_tPtr

SV *
abtAtqa(THIS, __value = NO_INIT)
    nfc_iso14443a_info_t *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = newSVpv((const char *)&THIS->abtAtqa, 2);
    OUTPUT:
    RETVAL

byte_t
abtAtqa1(THIS, __value = NO_INIT)
    nfc_iso14443a_info_t *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->abtAtqa[0];
    OUTPUT:
    RETVAL

byte_t
abtAtqa2(THIS, __value = NO_INIT)
    nfc_iso14443a_info_t *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->abtAtqa[1];
    OUTPUT:
    RETVAL

byte_t
btSak(THIS, __value = NO_INIT)
    nfc_iso14443a_info_t *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->btSak;
    OUTPUT:
    RETVAL

uint32_t
uiUidLen(THIS, __value = NO_INIT)
    nfc_iso14443a_info_t *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->szUidLen;
    OUTPUT:
    RETVAL

char *
abtUid(THIS, __value = NO_INIT)
    nfc_iso14443a_info_t *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = (char *)THIS->abtUid;
    OUTPUT:
    RETVAL

uint32_t
uiAtsLen(THIS, __value = NO_INIT)
    nfc_iso14443a_info_t *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->szAtsLen;
    OUTPUT:
    RETVAL

char *
abtAts(THIS, __value = NO_INIT)
    nfc_iso14443a_info_t *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = (char *)THIS->abtAts;
    OUTPUT:
    RETVAL

MODULE = RFID::Libnfc        PACKAGE = nfc_target_info_t

nfc_target_info_t *
_to_ptr(THIS)
    nfc_target_info_t THIS = NO_INIT
    PROTOTYPE: $
    CODE:
    if (sv_derived_from(ST(0), "nfc_target_info_t")) {
        STRLEN len;
        char *s = SvPV((SV*)SvRV(ST(0)), len);
        if (len != sizeof(THIS))
        croak("Size %d of packed data != expected %d",
            len, sizeof(THIS));
        RETVAL = (nfc_target_info_t *)s;
    }
    else
        croak("THIS is not of type nfc_target_info_t");
    OUTPUT:
    RETVAL

nfc_target_info_t
new(CLASS)
    char *CLASS = NO_INIT
    PROTOTYPE: $
    CODE:
    Zero((void*)&RETVAL, sizeof(RETVAL), char);
    OUTPUT:
    RETVAL

MODULE = RFID::Libnfc        PACKAGE = nfc_target_info_tPtr

nfc_iso14443a_info_t *
nai(THIS)
    nfc_target_info_t *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = &THIS->nai;
    OUTPUT:
    RETVAL


MODULE = RFID::Libnfc        PACKAGE = nfc_device_t

nfc_device_t *
_to_ptr(THIS)
    nfc_device_t THIS = NO_INIT
    PROTOTYPE: $
    CODE:
    if (sv_derived_from(ST(0), "nfc_device_t")) {
        STRLEN len;
        char *s = SvPV((SV*)SvRV(ST(0)), len);
        if (len != sizeof(THIS))
        croak("Size %d of packed data != expected %d",
            len, sizeof(THIS));
        RETVAL = (nfc_device_t *)s;
    }
    else
        croak("THIS is not of type nfc_device_t");
    OUTPUT:
    RETVAL

nfc_device_t
new(CLASS)
    char *CLASS = NO_INIT
    PROTOTYPE: $
    CODE:
    Zero((void*)&RETVAL, sizeof(RETVAL), char);
    OUTPUT:
    RETVAL

MODULE = RFID::Libnfc        PACKAGE = nfc_device_tPtr

char *
acName(THIS, __value = NO_INIT)
    nfc_device_t *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->acName;
    OUTPUT:
    RETVAL

nfc_chip_t
nc(THIS, __value = NO_INIT)
    nfc_device_t *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->nc;
    OUTPUT:
    RETVAL

nfc_device_spec_t 
nds(THIS, __value = NO_INIT)
    nfc_device_t *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->nds;
    OUTPUT:
    RETVAL

bool
bActive(THIS, __value = NO_INIT)
    nfc_device_t *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->bActive;
    OUTPUT:
    RETVAL

bool
bCrc(THIS, __value = NO_INIT)
    nfc_device_t *THIS
    bool __value
    PROTOTYPE: $;$
    CODE:
    if (items > 1) {
        THIS->bCrc = __value;
    }
    RETVAL = THIS->bCrc;
    OUTPUT:
    RETVAL

bool
bPar(THIS, __value = NO_INIT)
    nfc_device_t *THIS
    bool __value
    PROTOTYPE: $;$
    CODE:
    if (items > 1) {
        THIS->bPar = __value;
    }
    RETVAL = THIS->bPar;
    OUTPUT:
    RETVAL

uint8_t
ui8TxBits(THIS, __value = NO_INIT)
    nfc_device_t *THIS
    uint8_t __value
    PROTOTYPE: $;$
    CODE:
    if (items > 1) {
        THIS->ui8TxBits = __value;
    }
    RETVAL = THIS->ui8TxBits;
    OUTPUT:
    RETVAL

