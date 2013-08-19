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

// nfc_target_info is an union , part of the nfc_target structure
// so we don't need to map the structure providing a constructor.
// We only need accessors to be defined
#define RFID__Libnfc__TargetInfo nfc_target_info *
// nfc_iso14443a_info is part of the nfc_target_info union
// and the same consideration applies (we never need to create them directly)
#define RFID__Libnfc__ISO14443AInfo nfc_iso14443a_info *


/* The following three structures are instead fully mapped to perl.
 * Since we need to create and release instances from the perl side */
typedef struct RFID__Libnfc__Device {
    nfc_context *context;
    nfc_device *device;
    bool free;
} * RFID__Libnfc__Device;

typedef struct RFID__Libnfc__Target {
    nfc_target *target;
    bool free;
} * RFID__Libnfc__Target;

typedef struct RFID__Libnfc__Modulation {
    nfc_modulation *modulation;
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

uint8_t
abtAtqa1(THIS, __value = NO_INIT)
    RFID::Libnfc::ISO14443AInfo THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->abtAtqa[0];
    OUTPUT:
    RETVAL

uint8_t
abtAtqa2(THIS, __value = NO_INIT)
    RFID::Libnfc::ISO14443AInfo THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->abtAtqa[1];
    OUTPUT:
    RETVAL

uint8_t
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

SV *
abtUid(THIS, __value = NO_INIT)
    RFID::Libnfc::ISO14443AInfo THIS
    PROTOTYPE: $
    CODE:
    RETVAL = newSVpv((char *)THIS->abtUid, THIS->szUidLen);
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
    Newz(0, self, 1, struct RFID__Libnfc__Device);
    //Newz(0, self->device, 1, nfc_device);
    nfc_init(&self->context);
    if (self->context == NULL) {
        // TODO - Error Messages
    }
    self->device = nfc_open(self->context, NULL); // TODO - provide connect string
    self->free = true;
    //self_ref = newRV_noinc((SV *)self);
    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, pkg, (void *)self);
    OUTPUT:
    RETVAL

char *
name(THIS)
    RFID::Libnfc::Device THIS
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->device
           ? (char *)nfc_device_get_name(THIS->device)
           : NULL;
    OUTPUT:
    RETVAL

void
DESTROY(THIS)
    RFID::Libnfc::Device THIS
    CODE:
    if (THIS->free) {
        Safefree(THIS->device);
        nfc_close(THIS->device);
        nfc_exit(THIS->context);
    }
    Safefree(THIS);

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
    Newz(0, self, 1, struct RFID__Libnfc__Modulation );
    Newz(0, self->modulation, 1, nfc_modulation);
    self->free = true;
    //self_ref = newRV_noinc((SV *)self);
    RETVAL = newSV(0); /* This gets mortalized automagically */
    sv_setref_pv(RETVAL, pkg, (void *)self);
    OUTPUT:
    RETVAL


nfc_modulation_type
nmt(THIS, __value = NO_INIT)
    RFID::Libnfc::Modulation THIS
    uint8_t __value
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->modulation->nmt; // old value will be returned
    if (items > 1)
        THIS->modulation->nmt = __value;
    OUTPUT:
    RETVAL

nfc_baud_rate
nbr(THIS, __value = NO_INIT)
    RFID::Libnfc::Modulation THIS
    uint8_t __value
    PROTOTYPE: $
    CODE:
    RETVAL = THIS->modulation->nbr;
    if (items > 1)
        THIS->modulation->nbr = __value;
    OUTPUT:
    RETVAL

void
DESTROY(THIS)
    RFID::Libnfc::Modulation THIS
    CODE:
    if (THIS->free)
        Safefree(THIS->modulation);
    Safefree(THIS);

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
    Newz(0, self, 1, struct RFID__Libnfc__Target );
    Newz(0, self->target, 1, nfc_target);
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
    /* XXX - don't allow to change the modulation stored in the target description (for now)
    if (items > 1) {
        memcpy(&THIS->target->nm, __value->modulation, sizeof(nfc_modulation));
    }
    */
    Newz(0, obj, 1, struct RFID__Libnfc__Modulation);
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
        Safefree(THIS->target);
    Safefree(THIS);

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
        uint8_t *        pbtData
        uint32_t        uiLen

_Bool
nfc_device_set_property_int(pnd, property, value)
        RFID::Libnfc::Device pnd
        nfc_property property
        int          value
    CODE:
       RETVAL = (pnd && pnd->device)
              ? (nfc_device_set_property_int(pnd->device, property, value) == 0)
              : false;
    OUTPUT:
        RETVAL

_Bool 
nfc_device_set_property_bool(pnd, property, bEnable)
        RFID::Libnfc::Device pnd
        nfc_property property
        _Bool        bEnable
    CODE:
       RETVAL = (pnd && pnd->device)
              ? (nfc_device_set_property_bool(pnd->device, property, bEnable) == 0)
              : false;
    OUTPUT:
        RETVAL

SV *
nfc_open()
    CODE:
        RFID__Libnfc__Device obj;
        Newz(0, obj, 1, struct RFID__Libnfc__Device);
        obj->free = false;
        nfc_init(&obj->context);
        obj->device = nfc_open(obj->context, NULL); // TODO - provide connect string
        if (obj->device) {
            RETVAL = newSV(0); /* This gets mortalized automagically */
            sv_setref_pv(RETVAL, "RFID::Libnfc::Device", (void*)obj);
        } else {
            nfc_exit(obj->context);
            Safefree(obj);
            RETVAL = &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

void
nfc_close(pnd)
        RFID::Libnfc::Device        pnd
    CODE:
        // NOTE: the DESTROY method will be called for the RFID::Libnfc::Device
        //       so cleanup will happen there (both closing/exiting from nfc 
        //       and releasing the underlying RFID__Libnfc__Device structure
        //nfc_close(pnd->device);
        //nfc_exit(pnd->context);
        //Safefree(pnd);

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
        uint8_t *        pbtInitData
        uint32_t        uiInitDataLen
        RFID::Libnfc::Target        pt
    CODE:
        RETVAL = (pnd && pnd->device)
               ? nfc_initiator_select_passive_target(pnd->device,
                                                     *nmInitModulation->modulation,
                                                     pbtInitData,
                                                     uiInitDataLen,
                                                     pt->target)
               : false;
    OUTPUT:
        RETVAL

_Bool
nfc_initiator_init(pnd)
        RFID::Libnfc::Device pnd
    CODE:
        RETVAL = (pnd && pnd->device)
               ? nfc_initiator_init(pnd->device)
               : false;
    OUTPUT:
        RETVAL

SV *
nfc_initiator_transceive_bits(pnd, pbtTx, uiTxBits)
        RFID::Libnfc::Device        pnd
        uint8_t *        pbtTx
        uint32_t        uiTxBits
    PREINIT:
        int             rc;            
        uint32_t        len;
        uint8_t         abtRx[MAX_FRAME_LEN];
        size_t          szRxBits = 0;
        SV              *sv = &PL_sv_undef;
    CODE:
        // TODO - handle parity
        szRxBits = nfc_initiator_transceive_bits(pnd->device, pbtTx, uiTxBits,  NULL, abtRx, sizeof(abtRx), NULL);
        if (szRxBits)
            sv = newSVpv((char *)abtRx, szRxBits/8);
        else
            sv = newSVpv("", 0);
        RETVAL = sv;
    OUTPUT:
        RETVAL


SV *
nfc_initiator_transceive_bytes(pnd, pbtTx, uiTxLen)
        RFID::Libnfc::Device  pnd
        uint8_t *        pbtTx
        uint32_t        uiTxLen
    PREINIT:
        int             rc;            
        uint32_t        len;
        uint8_t         abtRx[MAX_FRAME_LEN];
        size_t          szRxBits = 0;
        SV              *sv = &PL_sv_undef;
    CODE:
        /* TODO - support timeout */
        szRxBits = nfc_initiator_transceive_bytes(pnd->device, pbtTx, uiTxLen,  abtRx, sizeof(abtRx), 2);
        if (szRxBits)
            sv = newSVpv((char *)abtRx, szRxBits);
        else
            sv = newSVpv("", 0);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
nfc_target_init(pnd, pnt)
        RFID::Libnfc::Device  pnd
        RFID::Libnfc::Target pnt
    PREINIT:
        SV *            sv;
        uint8_t         abtRx[MAX_FRAME_LEN];
        size_t          szRxBits;
    CODE:
        sv = newSV(0);
        /* TODO - support timeout */
        szRxBits = nfc_target_init(pnd->device, pnt->target, abtRx, sizeof(abtRx), 2);
        sv_setpvn(sv, (char *)abtRx, szRxBits/8+1);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
nfc_target_receive_bits(pnd)
        RFID::Libnfc::Device      pnd
    PREINIT:
        SV *            sv;
        uint8_t          abtRx[MAX_FRAME_LEN];
        uint8_t          btRxPar;
        size_t           szRxBits;
    CODE:
        sv = newSV(0);
        szRxBits = nfc_target_receive_bits(pnd->device, abtRx, sizeof(abtRx), &btRxPar);
            sv_setpvn(sv, (char *)abtRx, szRxBits/8+1);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
nfc_target_receive_bytes(pnd, pbtRx)
        RFID::Libnfc::Device        pnd
    PREINIT:
        _Bool           rc;            
        uint32_t        len;
        size_t          szRxLen;
        uint8_t         abtRx[MAX_FRAME_LEN];
        SV              *sv;
    CODE:
        sv = newSV(0);
        /* TODO - support timeout */
        szRxLen = nfc_target_receive_bytes(pnd->device, abtRx, sizeof(abtRx), 2);
        sv_setpvn(sv, (char *)abtRx, szRxLen);
        RETVAL = sv;
    OUTPUT:
        RETVAL

_Bool
nfc_target_send_bits(pnd, pbtTx, uiTxBits, pbtTxPar)
        RFID::Libnfc::Device  pnd
        uint8_t *        pbtTx
        uint32_t        uiTxBits
        uint8_t *        pbtTxPar
    CODE:
        RETVAL = nfc_target_send_bits(pnd->device, pbtTx, uiTxBits, pbtTxPar);
    OUTPUT:
        RETVAL

_Bool
nfc_target_send_bytes(pnd, pbtTx, uiTxLen)
        RFID::Libnfc::Device        pnd
        uint8_t *        pbtTx
        uint32_t        uiTxLen
    CODE:
        /* TODO - support timeout */
        RETVAL = nfc_target_send_bytes(pnd->device, pbtTx, uiTxLen, 2);
    OUTPUT:
        RETVAL

void
print_hex(__data, uiLen = NO_INIT)
        SV *__data
        STRLEN uiLen
    PREINIT:
        uint8_t *        pbtData = NULL;
    CODE:
        // TODO - allow to specify an offset as well
        if (SvPOK(__data)) {
            int i;
            if (items > 1) 
                pbtData = (uint8_t *)SvPV_nolen(__data);
            else
                pbtData = (uint8_t *)SvPV(__data, uiLen);
            for (i = 0; i < uiLen; i++) {
                printf("%02x ", pbtData[i]);
            }
            printf("\n");
        }


