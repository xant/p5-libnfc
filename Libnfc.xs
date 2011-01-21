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

// nfc_target_info_t is an union , part of the nfc_target_t structure
// so we don't need to map the structure providing a constructor.
// We only need accessors to be defined
#define RFID__Libnfc__TargetInfo nfc_target_info_t *
// nfc_iso14443a_info_t is part of the nfc_target_info_t union
// and the same consideration applies (we never need to create them directly)
#define RFID__Libnfc__ISO14443AInfo nfc_iso14443a_info_t *


/* The following three structures are instead fully mapped to perl.
 * Since we need to create and release instances from the perl side */
typedef struct {
    nfc_device_t *device;
    bool free;
} * RFID__Libnfc__Device;

typedef struct {
    nfc_target_t *target;
    bool free;
} * RFID__Libnfc__Target;

typedef struct {
    nfc_modulation_t *modulation;
    bool free;
} * RFID__Libnfc__Modulation;


/*
typedef struct {
    // Put Global Data in here 
    int dummy; // you can access this elsewhere as MY_CXT.dummy 
} my_cxt_t;

START_MY_CXT
*/

#include "const-c.inc"

MODULE = RFID::Libnfc::ISO14443AInfo        PACKAGE = RFID::Libnfc::ISO14443AInfo

SV *
abtAtqa(THIS, __value = NO_INIT)
    RFID::Libnfc::ISO14443AInfo THIS
    PROTOTYPE: $
    CODE:
    RETVAL = newSVpv((const char *)&THIS->abtAtqa, 2);
    OUTPUT:
    RETVAL

byte_t
abtAtqa1(THIS, __value = NO_INIT)
    RFID::Libnfc::ISO14443AInfo THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->abtAtqa[0];
    OUTPUT:
    RETVAL

byte_t
abtAtqa2(THIS, __value = NO_INIT)
    RFID::Libnfc::ISO14443AInfo THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->abtAtqa[1];
    OUTPUT:
    RETVAL

byte_t
btSak(THIS, __value = NO_INIT)
    RFID::Libnfc::ISO14443AInfo THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->btSak;
    OUTPUT:
    RETVAL

uint32_t
szUidLen(THIS, __value = NO_INIT)
    RFID::Libnfc::ISO14443AInfo THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->szUidLen;
    OUTPUT:
    RETVAL

char *
abtUid(THIS, __value = NO_INIT)
    RFID::Libnfc::ISO14443AInfo THIS
    PROTOTYPE: $
    CODE:
    RETVAL = (char *)THIS->abtUid;
    OUTPUT:
    RETVAL

uint32_t
uiAtsLen(THIS, __value = NO_INIT)
    RFID::Libnfc::ISO14443AInfo THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->szAtsLen;
    OUTPUT:
    RETVAL

char *
abtAts(THIS, __value = NO_INIT)
    RFID::Libnfc::ISO14443AInfo THIS
    PROTOTYPE: $
    CODE:
    RETVAL = (char *)THIS->abtAts;
    OUTPUT:
    RETVAL

MODULE = RFID::Libnfc::TargetInfo        PACKAGE = RFID::Libnfc::TargetInfo

RFID::Libnfc::ISO14443AInfo
nai(THIS)
    RFID::Libnfc::TargetInfo THIS
    PROTOTYPE: $
    CODE:
    RETVAL = &THIS->nai;
    OUTPUT:
    RETVAL


MODULE = RFID::Libnfc::Device        PACKAGE = RFID::Libnfc::Device

SV *
new(SV *CLASS)
    PROTOTYPE: $
    CODE:
    RFID__Libnfc__Device self;
    SV *self_ref;
    const char *pkg;
    if (SvROK(CLASS)) {
        pkg = sv_reftype(SvRV(CLASS), TRUE);
    } else {
        pkg = SvPV(CLASS, PL_na);
    }

    // allocate the memory for the structure storage
    Newz(0, self, 1, RFID__Libnfc__Device);
    self->device = calloc(1, sizeof(nfc_device_t));
    self->free = true;
    //self_ref = newRV_noinc((SV *)self);
    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, pkg, (void *)self);
    OUTPUT:
    RETVAL

char *
acName(THIS, __value = NO_INIT)
    RFID::Libnfc::Device THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->device->acName;
    OUTPUT:
    RETVAL

nfc_chip_t
nc(THIS, __value = NO_INIT)
    RFID::Libnfc::Device THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->device->nc;
    OUTPUT:
    RETVAL

nfc_device_spec_t 
nds(THIS, __value = NO_INIT)
    RFID::Libnfc::Device THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->device->nds;
    OUTPUT:
    RETVAL

bool
bActive(THIS, __value = NO_INIT)
    RFID::Libnfc::Device THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->device->bActive;
    OUTPUT:
    RETVAL

bool
bCrc(THIS, __value = NO_INIT)
    RFID::Libnfc::Device THIS
    bool __value
    PROTOTYPE: $;$
    CODE:
    if (items > 1) {
        THIS->device->bCrc = __value;
    }
    RETVAL = THIS->device->bCrc;
    OUTPUT:
    RETVAL

bool
bPar(THIS, __value = NO_INIT)
    RFID::Libnfc::Device THIS
    bool __value
    PROTOTYPE: $;$
    CODE:
    if (items > 1) {
        THIS->device->bPar = __value;
    }
    RETVAL = THIS->device->bPar;
    OUTPUT:
    RETVAL

uint8_t
ui8TxBits(THIS, __value = NO_INIT)
    RFID::Libnfc::Device THIS
    uint8_t __value
    PROTOTYPE: $;$
    CODE:
    if (items > 1) {
        THIS->device->ui8TxBits = __value;
    }
    RETVAL = THIS->device->ui8TxBits;
    OUTPUT:
    RETVAL

void
DESTROY(THIS)
    RFID::Libnfc::Device THIS
    CODE:
    if (THIS->free)
        free(THIS->device);

MODULE = RFID::Libnfc::Modulation        PACKAGE = RFID::Libnfc::Modulation

SV *
new(SV *CLASS)
    PROTOTYPE: $
    CODE:
    RFID__Libnfc__Modulation self;
    SV *self_ref;
    const char *pkg;
    if (SvROK(CLASS)) {
        pkg = sv_reftype(SvRV(CLASS), TRUE);
    } else {
        pkg = SvPV(CLASS, PL_na);
    }

    // allocate the memory for the structure storage
    Newz(0, self, 1, RFID__Libnfc__Modulation );
    self->modulation = calloc(1, sizeof(nfc_modulation_t));
    self->free = true;
    //self_ref = newRV_noinc((SV *)self);
    RETVAL = newSV(0); /* This gets mortalized automagically */
    sv_setref_pv(RETVAL, pkg, (void *)self);
    OUTPUT:
    RETVAL


nfc_modulation_type_t
nmt(THIS, __value = NO_INIT)
    RFID::Libnfc::Modulation THIS
    uint8_t __value
    PROTOTYPE: $
    CODE:
    if (items > 1) {
        THIS->modulation->nmt = __value;
    }
    RETVAL = THIS->modulation->nmt;
    OUTPUT:
    RETVAL

nfc_baud_rate_t
nbr(THIS, __value = NO_INIT)
    RFID::Libnfc::Modulation THIS
    uint8_t __value
    PROTOTYPE: $
    CODE:
    if (items > 1) {
        THIS->modulation->nbr = __value;
    }
    RETVAL = THIS->modulation->nbr;
    OUTPUT:
    RETVAL

void
DESTROY(THIS)
    RFID::Libnfc::Modulation THIS
    CODE:
    if (THIS->free)
        free(THIS->modulation);

MODULE = RFID::Libnfc::Target        PACKAGE = RFID::Libnfc::Target

SV *
new(SV *CLASS)
    PROTOTYPE: $
    CODE:
    RFID__Libnfc__Target self;
    SV *self_ref;
    const char *pkg;
    if (SvROK(CLASS)) {
        pkg = sv_reftype(SvRV(CLASS), TRUE);
    } else {
        pkg = SvPV(CLASS, PL_na);
    }

    // allocate the memory for the structure storage
    Newz(0, self, 1, RFID__Libnfc__Target );
    self->target = calloc(1, sizeof(nfc_target_t));
    self->free = true;
    //self_ref = newRV_noinc((SV *)self);
    RETVAL = newSV(0); /* This gets mortalized automagically */
    sv_setref_pv(RETVAL, pkg, (void *)self);
    OUTPUT:
    RETVAL


RFID::Libnfc::TargetInfo
nti(THIS)
    RFID::Libnfc::Target  THIS
    PROTOTYPE: $
    CODE:
    RETVAL = &THIS->target->nti;
    OUTPUT:
    RETVAL

SV *
nm(THIS, __value = NO_INIT)
    RFID::Libnfc::Target  THIS
    RFID::Libnfc::Modulation __value
    PROTOTYPE: $
    CODE:
    RFID__Libnfc__Modulation obj;
    if (items > 1) {
        memcpy(&THIS->target->nm, __value->modulation, sizeof(nfc_modulation_t));
    }
    Newz(0, obj, 1, RFID__Libnfc__Modulation);
    obj->modulation = &THIS->target->nm;
    obj->free = false;
    RETVAL = newSV(0); /* This gets mortalized automagically */
    sv_setref_pv(RETVAL, "RFID::Libnfc::Modulation", (void*)obj);
    OUTPUT:
    RETVAL

void
DESTROY(THIS)
    RFID::Libnfc::Target THIS
    CODE:
    if (THIS->free)
        free(THIS->target);

MODULE = RFID::Libnfc                PACKAGE = RFID::Libnfc                

INCLUDE: const-xs.inc

BOOT:
/*
{
    MY_CXT_INIT;
    // If any of the fields in the my_cxt_t struct need
    // to be initialised, do it here.
}
*/


void
iso14443a_crc_append(pbtData, uiLen)
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
        RFID::Libnfc::Device pnd
        nfc_device_option_t   ndo
        _Bool        bEnable
    CODE:
       return nfc_configure(pnd->device, ndo, bEnable); 

SV *
nfc_connect()
    CODE:
        RFID__Libnfc__Device obj;
        nfc_device_t *pnd = nfc_connect(NULL);
        Newz(0, obj, 1, RFID__Libnfc__Device);
        obj->device = pnd;
        obj->free = false;
        RETVAL = newSV(0); /* This gets mortalized automagically */
        sv_setref_pv(RETVAL, "RFID::Libnfc::Device", (void*)obj);
    OUTPUT:
        RETVAL

void
nfc_disconnect(pnd)
        RFID::Libnfc::Device        pnd
    CODE:
        nfc_disconnect(pnd->device);

_Bool
nfc_initiator_deselect_target(pnd)
        RFID::Libnfc::Device        pnd
    CODE:
        RETVAL=nfc_initiator_deselect_target(pnd->device);
    OUTPUT:
        RETVAL

_Bool
nfc_initiator_select_passive_target(pnd, nmInitModulation, pbtInitData, uiInitDataLen, pt)
        RFID::Libnfc::Device        pnd
        RFID::Libnfc::Modulation    nmInitModulation
        byte_t *        pbtInitData
        uint32_t        uiInitDataLen
        RFID::Libnfc::Target        pt
    CODE:
        RETVAL=nfc_initiator_select_passive_target(pnd->device, *nmInitModulation->modulation, pbtInitData, uiInitDataLen, pt->target);
    OUTPUT:
        RETVAL

_Bool
nfc_initiator_init(pnd)
        RFID::Libnfc::Device pnd
    CODE:
        return nfc_initiator_init(pnd->device);

SV *
nfc_initiator_transceive_bits(pnd, pbtTx, uiTxBits)
        RFID::Libnfc::Device        pnd
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
        if (nfc_initiator_transceive_bits(pnd->device, pbtTx, uiTxBits,  NULL, pbtRx, &puiRxBits, NULL))
            sv = newSVpv((char *)pbtRx, puiRxBits/8);
        else 
            sv = newSV(0);
        free(pbtRx);
        RETVAL = sv;
    OUTPUT:
        RETVAL



SV *
nfc_initiator_transceive_bytes(pnd, pbtTx, uiTxLen)
        RFID::Libnfc::Device  pnd
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
        if (nfc_initiator_transceive_bytes(pnd->device, pbtTx, uiTxLen,  pbtRx, &puiRxLen))
            sv = newSVpv((char *)pbtRx, puiRxLen);
        else {
            nfc_perror (pnd, "nfc_initiator_transceive_bytes");
            sv = newSV(0);
        }
        free(pbtRx);
        RETVAL = sv;
    OUTPUT:
        RETVAL


SV *
nfc_target_init(pnd, pnt)
        RFID::Libnfc::Device  pnd
        RFID::Libnfc::Target pnt
    PREINIT:
        SV *            sv;
        byte_t *        pbtRx;
        size_t          uiRxBits;
    CODE:
        pbtRx = malloc(MAX_FRAME_LEN);
        if (nfc_target_init(pnd->device, pnt->target, pbtRx, &uiRxBits))
            sv = newSVpv((char *)pbtRx, uiRxBits/8+1);
        else 
            sv = newSV(0);
        free(pbtRx);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
nfc_target_receive_bits(pnd)
        RFID::Libnfc::Device      pnd
    PREINIT:
        SV *            sv;
        byte_t *        pbtRx;
        byte_t          btRxPar;
        size_t          uiRxBits;
    CODE:
        pbtRx = malloc(MAX_FRAME_LEN);
        if (nfc_target_receive_bits(pnd->device, pbtRx, &uiRxBits, &btRxPar))
            sv = newSVpv((char *)pbtRx, uiRxBits/8+1);
        else 
            sv = newSV(0);
        free(pbtRx);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
nfc_target_receive_bytes(pnd, pbtRx)
        RFID::Libnfc::Device        pnd
    PREINIT:
        _Bool           rc;            
        uint32_t        len;
        size_t          puiRxLen;
        byte_t *        pbtRx;
        SV              *sv;
    CODE:
        pbtRx = malloc(MAX_FRAME_LEN);
        rc = nfc_target_receive_bytes(pnd->device, pbtRx, &puiRxLen);
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
        RFID::Libnfc::Device  pnd
        byte_t *        pbtTx
        uint32_t        uiTxBits
        byte_t *        pbtTxPar
    CODE:
        return nfc_target_send_bits(pnd->device, pbtTx, uiTxBits, pbtTxPar);

_Bool
nfc_target_send_bytes(pnd, pbtTx, uiTxLen)
        RFID::Libnfc::Device        pnd
        byte_t *        pbtTx
        uint32_t        uiTxLen
    CODE:
        return nfc_target_send_bytes(pnd->device, pbtTx, uiTxLen);

void
print_hex(__data, uiLen = NO_INIT)
        SV *__data
        STRLEN uiLen
    PREINIT:
        byte_t *        pbtData = NULL;
    CODE:
        // TODO - allow to specify an offset as well
        if (SvPOK(__data)) {
            int i;
            if (items > 1) 
                pbtData = (byte_t *)SvPV_nolen(__data);
            else
                pbtData = (byte_t *)SvPV(__data, uiLen);
            for (i = 0; i < uiLen; i++) {
                printf("%02x ", pbtData[i]);
            }
            printf("\n");
        }


