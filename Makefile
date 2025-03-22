.PHONY: iso burn

WORKDIR   := $(dir $(lastword $(MAKEFILE_LIST)))

ISOFILE   := "nixos-minimal-25.11.20251206.d9bc5c7-x86_64-linux.iso"

FLASHDISK := "/dev/sda"

iso:
	@echo "Generate livecd iso image $(ISOFILE)"
	@ rm -f $(WORKDIR)/result
	@nix build ".#nixosConfigurations.installer.config.system.build.isoImage"
	@echo

burn: iso
	@echo "Write iso file to $(FLASHDISK)"
	@[[ -e $(FLASHDISK) ]] && sudo dd if=$(WORKDIR)/result/iso/$(ISOFILE) of=$(FLASHDISK) bs=2048 status=progress conv=sync,noerror
	@[[ -e $(FLASHDISK) ]] && sudo eject $(FLASHDISK)
	@echo "Done...!"
