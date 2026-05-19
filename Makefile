CC      := /c/msys64/mingw64/bin/gcc.exe
EFIINC  := /c/msys64/usr/include/efi
EFILIB  := /c/msys64/usr/lib

CFLAGS  := -ffreestanding -O2 -Wall -Wno-unused-parameter -Wno-pointer-sign \
           -fshort-wchar -fno-stack-protector -fno-strict-aliasing \
           -mno-red-zone -mno-stack-arg-probe \
           -DGNU_EFI_USE_MS_ABI -DHAVE_USE_MS_ABI=1 \
           -I$(EFIINC) -I$(EFIINC)/x86_64 -I.

LDFLAGS := -nostdlib -Wl,--subsystem,10 -Wl,--entry,efi_main \
           -Wl,--strip-all -L$(EFILIB)

LIBS    := -lefi -lgcc

TARGET  := MemForge2.efi
SRC     := MemForge2.src.c
OBJ     := $(SRC:.c=.o)

.PHONY: all clean

all: $(TARGET)

%.o: %.c MemForge2.mp.h
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET): $(OBJ)
	$(CC) $(LDFLAGS) -o $@ $(OBJ) $(LIBS)

clean:
	rm -f $(OBJ) $(TARGET)
