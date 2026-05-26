#ifndef MEMFORGE_MP_H
#define MEMFORGE_MP_H

/* MSYS2 gnu-efi includes EFI_MP_SERVICES_PROTOCOL via <efimp.h>.
   The Ubuntu/Debian package omits that header, so we define the protocol
   here directly from the UEFI Platform Initialisation spec (Vol. 2). */
#ifndef EFI_MP_SERVICES_PROTOCOL_GUID

#define EFI_MP_SERVICES_PROTOCOL_GUID \
    { 0x3fdda605, 0xa76e, 0x4f46, {0xad, 0x29, 0x12, 0xf4, 0x53, 0x1b, 0x3d, 0x08} }

#define PROCESSOR_AS_BSP_BIT         0x00000001
#define PROCESSOR_ENABLED_BIT        0x00000002
#define PROCESSOR_HEALTH_STATUS_BIT  0x00000004

typedef VOID (*EFI_AP_PROCEDURE)(VOID *ProcedureArgument);

typedef struct {
    UINT32  Package;
    UINT32  Core;
    UINT32  Thread;
} EFI_CPU_PHYSICAL_LOCATION;

typedef struct {
    UINT64                    ProcessorId;
    UINT32                    StatusFlag;
    EFI_CPU_PHYSICAL_LOCATION Location;
} EFI_PROCESSOR_INFORMATION;

typedef struct _EFI_MP_SERVICES_PROTOCOL EFI_MP_SERVICES_PROTOCOL;

struct _EFI_MP_SERVICES_PROTOCOL {
    EFI_STATUS (EFIAPI *GetNumberOfProcessors)(
        IN  EFI_MP_SERVICES_PROTOCOL *This,
        OUT UINTN                    *NumberOfProcessors,
        OUT UINTN                    *NumberOfEnabledProcessors);
    EFI_STATUS (EFIAPI *GetProcessorInfo)(
        IN  EFI_MP_SERVICES_PROTOCOL  *This,
        IN  UINTN                      ProcessorNumber,
        OUT EFI_PROCESSOR_INFORMATION *ProcessorInfoBuffer);
    EFI_STATUS (EFIAPI *StartupAllAPs)(
        IN  EFI_MP_SERVICES_PROTOCOL *This,
        IN  EFI_AP_PROCEDURE          Procedure,
        IN  BOOLEAN                   SingleThread,
        IN  EFI_EVENT                 WaitEvent,
        IN  UINTN                     TimeoutInMicroseconds,
        IN  VOID                     *ProcedureArgument,
        OUT UINTN                   **FailedCpuList);
    EFI_STATUS (EFIAPI *StartupThisAP)(
        IN  EFI_MP_SERVICES_PROTOCOL *This,
        IN  EFI_AP_PROCEDURE          Procedure,
        IN  UINTN                     ProcessorNumber,
        IN  EFI_EVENT                 WaitEvent,
        IN  UINTN                     TimeoutInMicroseconds,
        IN  VOID                     *ProcedureArgument,
        OUT BOOLEAN                  *Finished);
    EFI_STATUS (EFIAPI *SwitchBSP)(
        IN EFI_MP_SERVICES_PROTOCOL *This,
        IN UINTN                     ProcessorNumber,
        IN BOOLEAN                   EnableOldBSP);
    EFI_STATUS (EFIAPI *EnableDisableAP)(
        IN    EFI_MP_SERVICES_PROTOCOL *This,
        IN    UINTN                     ProcessorNumber,
        IN    BOOLEAN                   EnableAP,
        IN OUT UINT32                  *HealthFlag);
    EFI_STATUS (EFIAPI *WhoAmI)(
        IN  EFI_MP_SERVICES_PROTOCOL *This,
        OUT UINTN                    *ProcessorNumber);
};

#endif /* EFI_MP_SERVICES_PROTOCOL_GUID */
#endif /* MEMFORGE_MP_H */
