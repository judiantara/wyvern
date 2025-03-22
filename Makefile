MAKEFLAGS += --always-make --no-print-directory --silent

WORKDIR   := $(PWD)
VERSION   := 26.05
BASENAME  := Wyvern
ISOFILE   := $(BASENAME)-$(VERSION).iso
FLASHDISK := /dev/disk/by-id/usb-KIOXIA_TransMemory_0022CFF6BD8EC8410322FD9A-0\:0
VENTOY    := /run/media/judiantara/Ventoy

export SSH_HOST_KEY_PATH = /home/judiantara/Workspaces/personal/nix/atelier/source/machine-persisted/wyvern/etc/ssh

commit:
	git al && git cia "Wyvern easy install mark VI" && git fp

iso: commit
	echo "Generate livecd iso image $(ISOFILE) with SSH keypair from ${SSH_HOST_KEY_PATH} "
	 rm -f $(WORKDIR)/result
	nix flake update
	nix build --impure ".#nixosConfigurations.installer.config.system.build.isoImage"
	ls -alh $(WORKDIR)/result/iso/
	echo

ventoy: iso
	[[ -e "$(VENTOY)" ]] && echo "Copy iso file to $(VENTOY)" && cp -vf $(WORKDIR)/result/iso/$(ISOFILE) "$(VENTOY)/iso/$(BASENAME) $(VERSION).iso"
	sudo umount $(VENTOY)
	sudo eject $(FLASHDISK)
	echo "Done...!"

#
# burn: iso
# 	echo "Write iso file to $(FLASHDISK)"
# 	[[ -e "$(FLASHDISK)" ]] && sudo dd if=$(WORKDIR)/result/iso/$(ISOFILE) of=$(FLASHDISK) bs=2048 status=progress conv=sync,noerror
# 	[[ -e "$(FLASHDISK)" ]] && sudo eject $(FLASHDISK)
# 	echo "Done...!"
