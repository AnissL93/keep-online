PREFIX ?= /usr/local
UNIT_DIR ?= /etc/systemd/system

.PHONY: install uninstall test

test:
	bash test_keep_online.sh

install:
	@test -n "$(PEERS)" || { echo 'usage: sudo make install PEERS="100.x.y.z 100.a.b.c"'; exit 1; }
	install -m 755 keep-online.sh $(PREFIX)/sbin/keep-online.sh
	sed 's|@PEERS@|$(PEERS)|' keep-online.service > $(UNIT_DIR)/keep-online.service
	systemctl daemon-reload
	systemctl enable keep-online
	systemctl restart keep-online

uninstall:
	-systemctl disable --now keep-online
	rm -f $(UNIT_DIR)/keep-online.service $(PREFIX)/sbin/keep-online.sh
	systemctl daemon-reload
