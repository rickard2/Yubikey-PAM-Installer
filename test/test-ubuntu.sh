#!/bin/bash

chmod +x install-yubikey-pam-ubuntu.sh

yes | sudo ./install-yubikey-pam-ubuntu.sh

if [ ! $? -eq 0 ]; then
    exit 1
fi

if [ ! -f /etc/yubikey ]; then
    exit 1
fi

if [ ! -f /usr/share/pam-configs/yubikey ]; then
    exit 1
fi

if [ ! -f /lib/security/pam_yubico.la ]; then
    exit 1
fi

fi [ ! -f /lib/security/pam_yubico.so ]; then
    exit 1
fi

if [ ! -s /usr/local/lib/security/pam_yubico.la ]; then
    exit 1
fi

if [ ! -s /usr/local/lib/security/pam_yubico.so ]; then
    exit 1
fi