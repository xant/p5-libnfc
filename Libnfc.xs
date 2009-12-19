#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifdef LIBNFC_DEV
#include <nfc/nfc.h>
#else
#include <libnfc/libnfc.h>
#endif

/* Global Data */

#define MY_CXT_KEY "RFID::Libnfc::_guts" XS_VERSION
typedef dev_info * dev_infoPtr;

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
nfc_configure(pdi, dco, bEnable)
        dev_info *        pdi
        dev_config_option        dco
        _Bool        bEnable

dev_info *
nfc_connect()
    CODE:
#ifdef LIBNFC_DEV
        RETVAL=nfc_connect(NULL);
#else
        RETVAL=nfc_connect();
#endif
    OUTPUT:
        RETVAL

void
nfc_disconnect(pdi)
        dev_info *        pdi

_Bool
nfc_initiator_deselect_tag(pdi)
        dev_info *        pdi

_Bool
nfc_initiator_init(pdi)
        dev_info *        pdi

_Bool
nfc_initiator_mifare_cmd(pdi, mc, ui8Block, pmp)
        dev_info *        pdi
        unsigned char          mc
        uint8_t        ui8Block
        mifare_param *        pmp

_Bool
nfc_initiator_select_tag(pdi, im, pbtInitData, uiInitDataLen, pti)
        dev_info *        pdi
        init_modulation        im
        byte_t *        pbtInitData
        uint32_t        uiInitDataLen
        tag_info *        pti

SV *
nfc_initiator_transceive_bits(pdi, pbtTx, uiTxBits)
        dev_info *        pdi
        byte_t *        pbtTx
        uint32_t        uiTxBits
    PREINIT:
        int             rc;            
        uint32_t        len;
        byte_t *        pbtRx;
#ifdef LIBNFC_DEV
        size_t          puiRxBits = 0;
#else
        uint32_t        puiRxBits = 0;
#endif
        byte_t          *rbuf;
        SV              *sv = &PL_sv_undef;
    CODE:
        rbuf = malloc(MAX_FRAME_LEN);
        // TODO - handle parity
        if (nfc_initiator_transceive_bits(pdi, pbtTx, uiTxBits,  NULL, rbuf, &puiRxBits, NULL))
            sv = newSVpv((char *)rbuf, puiRxBits/8);
        else 
            sv = newSV(0);
        free(rbuf);
        RETVAL = sv;
    OUTPUT:
        RETVAL



SV *
nfc_initiator_transceive_bytes(pdi, pbtTx, uiTxLen)
        dev_info *        pdi
        byte_t *        pbtTx
        uint32_t        uiTxLen
    PREINIT:
        int             rc;            
        uint32_t        len;
        byte_t *        pbtRx;
#ifdef LIBNFC_DEV
        size_t          puiRxLen = 0;
#else
        uint32_t        puiRxLen = 0;
#endif
        byte_t          *rbuf;
        SV              *sv = &PL_sv_undef;
    CODE:
        rbuf = malloc(MAX_FRAME_LEN);
        if (nfc_initiator_transceive_bytes(pdi, pbtTx, uiTxLen,  rbuf, &puiRxLen))
            sv = newSVpv((char *)rbuf, puiRxLen);
        else 
            sv = newSV(0);
        free(rbuf);
        RETVAL = sv;
    OUTPUT:
        RETVAL


SV *
nfc_target_init(pdi)
        dev_info *        pdi
    PREINIT:
        SV *            sv;
        byte_t *        pbtRx;
#ifdef LIBNFC_DEV
        size_t          uiRxBits;
#else
        uint32_t        uiRxBits;
#endif
    CODE:
        pbtRx = malloc(MAX_FRAME_LEN);
        if (nfc_target_init(pdi, pbtRx, &uiRxBits))
            sv = newSVpv((char *)pbtRx, uiRxBits/8+1);
        else 
            sv = newSV(0);
        free(pbtRx);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
nfc_target_receive_bits(pdi)
        dev_info *      pdi
    PREINIT:
        SV *            sv;
        byte_t *        pbtRx;
        byte_t          btRxPar;
#ifdef LIBNFC_DEV
        size_t          uiRxBits;
#else
        uint32_t        uiRxBits;
#endif
    CODE:
        pbtRx = malloc(MAX_FRAME_LEN);
        if (nfc_target_receive_bits(pdi, pbtRx, &uiRxBits, &btRxPar))
            sv = newSVpv((char *)pbtRx, uiRxBits/8+1);
        else 
            sv = newSV(0);
        free(pbtRx);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
nfc_target_receive_bytes(pdi, pbtRx)
        dev_info *        pdi
        byte_t *        pbtRx
    PREINIT:
        _Bool           rc;            
        uint32_t        len;
#ifdef LIBNFC_DEV
        size_t          puiRxLen;
#else
        uint32_t        puiRxLen;
#endif
        byte_t          *rbuf;
        SV              *sv;
    CODE:
        rbuf = malloc(MAX_FRAME_LEN);
        rc = nfc_target_receive_bytes(pdi, rbuf, &puiRxLen);
        if (rc)
            sv = newSVpv((char *)rbuf, puiRxLen);
        else
            sv = newSV(0);
        free(rbuf);
        RETVAL = sv;
    OUTPUT:
        RETVAL

_Bool
nfc_target_send_bits(pdi, pbtTx, uiTxBits, pbtTxPar)
        dev_info *        pdi
        byte_t *        pbtTx
        uint32_t        uiTxBits
        byte_t *        pbtTxPar

_Bool
nfc_target_send_bytes(pdi, pbtTx, uiTxLen)
        dev_info *        pdi
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

MODULE = RFID::Libnfc        PACKAGE = tag_info

tag_info *
_to_ptr(THIS)
    tag_info THIS = NO_INIT
    PROTOTYPE: $
    CODE:
    if (sv_derived_from(ST(0), "tag_info")) {
        STRLEN len;
        char *s = SvPV((SV*)SvRV(ST(0)), len);
        if (len != sizeof(THIS))
        croak("Size %d of packed data != expected %d",
            len, sizeof(THIS));
        RETVAL = (tag_info *)s;
    }
    else
        croak("THIS is not of type tag_info");
    OUTPUT:
    RETVAL

tag_info
new(CLASS)
    char *CLASS = NO_INIT
    PROTOTYPE: $
    CODE:
    Zero((void*)&RETVAL, sizeof(RETVAL), char);
    OUTPUT:
    RETVAL

MODULE = RFID::Libnfc        PACKAGE = tag_infoPtr

SV *
abtAtqa(THIS, __value = NO_INIT)
    tag_info *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = newSVpv((const char *)&THIS->tia.abtAtqa, 2);
    OUTPUT:
    RETVAL

byte_t
abtAtqa1(THIS, __value = NO_INIT)
    tag_info *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->tia.abtAtqa[0];
    OUTPUT:
    RETVAL

byte_t
abtAtqa2(THIS, __value = NO_INIT)
    tag_info *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->tia.abtAtqa[1];
    OUTPUT:
    RETVAL

byte_t
btSak(THIS, __value = NO_INIT)
    tag_info *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->tia.btSak;
    OUTPUT:
    RETVAL

uint32_t
uiUidLen(THIS, __value = NO_INIT)
    tag_info *THIS
    PROTOTYPE: $
    CODE:
#ifdef LIBNFC_DEV
    RETVAL = THIS->tia.szUidLen;
#else
    RETVAL = THIS->tia.uiUidLen;
#endif
    OUTPUT:
    RETVAL

char *
abtUid(THIS, __value = NO_INIT)
    tag_info *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = (char *)THIS->tia.abtUid;
    OUTPUT:
    RETVAL

uint32_t
uiAtsLen(THIS, __value = NO_INIT)
    tag_info *THIS
    PROTOTYPE: $
    CODE:
#ifdef LIBNFC_DEV
    RETVAL = THIS->tia.szAtsLen;
#else
    RETVAL = THIS->tia.uiAtsLen;
#endif
    OUTPUT:
    RETVAL

char *
abtAts(THIS, __value = NO_INIT)
    tag_info *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = (char *)THIS->tia.abtAts;
    OUTPUT:
    RETVAL

MODULE = RFID::Libnfc        PACKAGE = dev_info

dev_info *
_to_ptr(THIS)
    dev_info THIS = NO_INIT
    PROTOTYPE: $
    CODE:
    if (sv_derived_from(ST(0), "dev_info")) {
        STRLEN len;
        char *s = SvPV((SV*)SvRV(ST(0)), len);
        if (len != sizeof(THIS))
        croak("Size %d of packed data != expected %d",
            len, sizeof(THIS));
        RETVAL = (dev_info *)s;
    }
    else
        croak("THIS is not of type dev_info");
    OUTPUT:
    RETVAL

dev_info
new(CLASS)
    char *CLASS = NO_INIT
    PROTOTYPE: $
    CODE:
    Zero((void*)&RETVAL, sizeof(RETVAL), char);
    OUTPUT:
    RETVAL

MODULE = RFID::Libnfc        PACKAGE = dev_infoPtr

char *
acName(THIS, __value = NO_INIT)
    dev_info *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->acName;
    OUTPUT:
    RETVAL

chip_type
ct(THIS, __value = NO_INIT)
    dev_info *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->ct;
    OUTPUT:
    RETVAL

dev_spec 
ds(THIS, __value = NO_INIT)
    dev_info *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->ds;
    OUTPUT:
    RETVAL

bool
bActive(THIS, __value = NO_INIT)
    dev_info *THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->bActive;
    OUTPUT:
    RETVAL

bool
bCrc(THIS, __value = NO_INIT)
    dev_info *THIS
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
    dev_info *THIS
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
    dev_info *THIS
    uint8_t __value
    PROTOTYPE: $;$
    CODE:
    if (items > 1) {
        THIS->ui8TxBits = __value;
    }
    RETVAL = THIS->ui8TxBits;
    OUTPUT:
    RETVAL

MODULE = RFID::Libnfc        PACKAGE = mifare_param

mifare_param *
_to_ptr(THIS)
    mifare_param THIS = NO_INIT
    PROTOTYPE: $
    CODE:
    if (sv_derived_from(ST(0), "mifare_param")) {
        STRLEN len;
        char *s = SvPV((SV*)SvRV(ST(0)), len);
        if (len != sizeof(THIS))
        croak("Size %d of packed data != expected %d",
            len, sizeof(THIS));
        RETVAL = (mifare_param *)s;
    }
    else
        croak("THIS is not of type mifare_param");
    OUTPUT:
    RETVAL

mifare_param
new(CLASS)
    char *CLASS = NO_INIT
    PROTOTYPE: $
    CODE:
    Zero((void*)&RETVAL, sizeof(RETVAL), char);
    OUTPUT:
    RETVAL

MODULE = RFID::Libnfc        PACKAGE = mifare_paramPtr

char *
mpa(THIS, __key = NO_INIT, __uid = NO_INIT)
    mifare_param *THIS
    SV *__key
    SV *__uid
    PROTOTYPE: $;$;$
    CODE:
    if (items > 1) {
        STRLEN len = 0;
        if (SvPOK(__key)) {
            len = SvCUR(__key);
            if (len == 6) {
                char *k = SvPV(__key, len);
                memcpy(&THIS->mpa.abtKey, k, len);
            } else {
                croak("Size %d of packed data != expected 6 for __key", len);
            }
        }
        if (SvPOK(__uid)) {
            len = SvCUR(__uid);
            if (len == 4) {
                char *u = SvPV(__uid, len);
                memcpy(&THIS->mpa.abtUid, u, len);
            } else {
                croak("Size %d of packed data != expected 4 for __uid", len);
            }
        }
    }
    RETVAL = (char *)&THIS->mpa;
    OUTPUT:
    RETVAL


SV *
mpd(THIS, __value = NO_INIT)
    mifare_param *THIS
    SV *__value
    PROTOTYPE: $;$
    CODE:
    if (items > 1) {
        STRLEN len = 0;
        if (SvPOK(__value)) {
            len = SvCUR(__value);
            if (len <= 16) {
                char *v = SvPV(__value, len);
                memcpy(&THIS->mpd.abtData, v, len);
            } else {
                croak("Size %d of packed data != expected 16 for __value", len);
            }
        }
    }
    RETVAL = newSVpv((char *)&THIS->mpd, 16);
    OUTPUT:
    RETVAL

char *
mpv(THIS, __value = NO_INIT)
    mifare_param *THIS
    SV *__value
    PROTOTYPE: $;$
    CODE:
    if (items > 1) {
        STRLEN len = 0;
        if (SvPOK(__value)) {
            len = SvCUR(__value);
            if (len <= 4) {
                memcpy(&THIS->mpv.abtValue, SvPV(__value, len), len);
            } else {
                croak("Size %d of packed data != expected 6 for __value", len);
            }
        }
    }
    RETVAL = (char *)&THIS->mpv;
    OUTPUT:
    RETVAL

