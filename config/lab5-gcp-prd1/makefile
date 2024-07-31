.ONESHELL:
.SILENT:
.EXPORT_ALL_VARIABLES:

MAKEFLAGS += --no-builtin-rules --no-builtin-variables

###############################################################################
# Settings
###############################################################################

GPG_ID ?= $(word 1,$(file < .gpg_id))

ifeq ($(GPG_ID),)
$(error "GPG_ID is not set. Create `.gpg_id` file, or pass via env var GPG_ID")
endif

txt := $(shell ls -1 | grep -vE 'makefile|.asc|.gpg_id|.tfvars' | tr '\n' ' ')
asc := $(addsuffix .asc,$(txt))

###############################################################################
# Targets
###############################################################################

.PHONY: help decrypt encrypt clean

help: .gitignore .gpg_id
	$(call header,Settings)
	$(call var,GPG_ID,$(GPG_ID))
	$(call header,Help)
	$(call help,make decrypt,Decrypt all secrets)
	$(call help,make encrypt,Encrypt all secrets)
	$(call help,make clean,Remove unencrypted secrets)

.gpg_id:
	echo "$(GPG_ID)" > $@

.gitignore:
	cat << EOF > $@
	**
	!.gitignore
	!.gpg_id
	!*.asc
	!makefile
	!*.tfvars
	EOF

decrypt:
	$(call header,Decrypting secrets)
	$(foreach file,$(wildcard *.asc),gpg $(file) && touch $(file) && chmod 600 $(file:%.asc=%);)

encrypt:
	$(call header,Encrypting secrets)
	$(foreach file,$(txt),gpg -aer $(GPG_ID) $(file);)

$(asc): $(txt)
	$(call header,Encrypting $@)
	gpg -aer $(GPG_ID) $(@:%.asc=%)

clean:
	$(call header,Removing unencrypted secrets)
	$(foreach file,$(txt),shred -uf $(file);)

###############################################################################
# Colors and Headers
###############################################################################

TERM := xterm-256color

black := $$(tput setaf 0)
red := $$(tput setaf 1)
green := $$(tput setaf 2)
yellow := $$(tput setaf 3)
blue := $$(tput setaf 4)
magenta := $$(tput setaf 5)
cyan := $$(tput setaf 6)
white := $$(tput setaf 7)
reset := $$(tput sgr0)

define header
echo "$(blue)==> $(1) <==$(reset)"
endef

define help
echo "$(green)$(1)$(reset) - $(white)$(2)$(reset)"
endef

define var
echo "$(magenta)$(1)$(reset): $(yellow)$(2)$(reset)"
endef
