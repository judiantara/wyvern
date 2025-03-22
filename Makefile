MAKEFLAGS += --always-make

# WORKDIR   := $(dir $(lastword $(MAKEFILE_LIST)))

WORKDIR   := $(PWD)
ISOFILE   := nixos-minimal-26.05.20260611.a037402-x86_64-linux.iso
FLASHDISK := /dev/sda
VENTOY    := /run/media/judiantara/Ventoy

ventoy: iso
	@echo "Copy iso file to $(VENTOY)"
	@[[ -e "$(VENTOY)" ]] && cp -vf $(WORKDIR)/result/iso/$(ISOFILE) "$(VENTOY)/iso/Wyvern 26.05.iso"
	@sudo umount $(VENTOY)
	@echo "Done...!"

burn: iso
	@echo "Write iso file to $(FLASHDISK)"
	@[[ -e "$(FLASHDISK)" ]] && sudo dd if=$(WORKDIR)/result/iso/$(ISOFILE) of=$(FLASHDISK) bs=2048 status=progress conv=sync,noerror
	@[[ -e "$(FLASHDISK)" ]] && sudo eject $(FLASHDISK)
	@echo "Done...!"

iso:
	@echo "Generate livecd iso image $(ISOFILE)"
	@ rm -f $(WORKDIR)/result
	@nix build ".#nixosConfigurations.installer.config.system.build.isoImage"
	@echo
