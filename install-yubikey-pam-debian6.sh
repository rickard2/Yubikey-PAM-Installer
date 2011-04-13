#!/bin/bash

if [ ! `whoami` == "root" ]; then
	echo "Please run this script as root, either log on as root or run 'sudo $0'"
	exit 1
fi

echo "This script will do the following on your system: "
echo "1. Install the following debian packages: build-essential, libusb-dev, libcurl4-gnutls, libpam-dev, curl"
echo "2. Download libyubikey, ykpers, ykclient and pam_yubico. Compile and install them."
echo "3. Add Yubikey authentication configuration to PAM."
echo "4. Run 'pam-auth-update' which let's you choose to enable Yubikey authentication directly."
echo "5. Prompt you for a Yubikey OTP (One Time Password) and link the root account with your Yubikey."
echo ""
echo "If you're not fine with this script performing these changes to your system, please press CTRL+C now. Otherwise press enter and go find your Yubikey while I take care of the rest."

read continue

apt-get install -y build-essential libusb-dev libcurl4-gnutls-dev libpam-dev curl

cd /usr/src

if [ ! -f libyubikey-1.7.tar.gz ]; then
	curl -o libyubikey-1.7.tar.gz http://yubico-c.googlecode.com/files/libyubikey-1.7.tar.gz
fi

if [ ! -d libyubikey-1.7 ]; then
	tar zxvf libyubikey-1.7.tar.gz
fi

cd libyubikey-1.7
./configure
make all install
cd ..
rm -rf libyubikey-1.7 libyubikey-1.7.tar.gz

if [ ! -f ykpers-1.5.1.tar.gz ]; then
	curl -o ykpers-1.5.1.tar.gz http://yubikey-personalization.googlecode.com/files/ykpers-1.5.1.tar.gz
fi

if [ ! -d ykpers-1.5.1 ]; then
	tar zxvf ykpers-1.5.1.tar.gz
fi

cd ykpers-1.5.1
./configure
make all install
cd ..
rm -rf ykpers-1.5.1 ykpers-1.5.1.tar.gz

if [ ! -f ykclient-2.4.tar.gz ]; then
	curl -o ykclient-2.4.tar.gz http://yubico-c-client.googlecode.com/files/ykclient-2.4.tar.gz
fi

if [ ! -d ykclient-2.4 ]; then
	tar zxvf ykclient-2.4.tar.gz
fi

cd ykclient-2.4
./configure
make all install
cd ..
rm -rf ykclient-2.4 ykclient-2.4.tar.gz

if [ ! -f pam_yubico-2.6.tar.gz ]; then
	curl -o pam_yubico-2.6.tar.gz http://yubico-pam.googlecode.com/files/pam_yubico-2.6.tar.gz
fi

if [ ! -d pam_yubico-2.6 ]; then
	tar zxvf pam_yubico-2.6.tar.gz
fi 

cd pam_yubico-2.6
./configure
make all install
cd ..
rm -rf pam_yubico-2.6 pam_yubico-2.6.tar.gz

ln -s /usr/local/lib/security/pam_yubico.la /lib/security/pam_yubico.la
ln -s /usr/local/lib/security/pam_yubico.so /lib/security/pam_yubico.so

echo  "Name: Yubikey authentication
Default: yes
Priority: 512
Auth-Type: Primary
Auth:
        requisite pam_yubico.so id=xxxx authfile=/etc/yubikey" >> /usr/share/pam-configs/yubikey

pam-auth-update

echo "Please press your Yubikey to generate a OTP: "

read YUBICODE

echo "root:"`echo $YUBICODE | cut -c 1-12` > /etc/yubikey

echo "Done! You can now try logging in again by running the command 'login' and try out your new Yubikey sign on!"
echo "" 
echo "Please note that the root account is the only account which has a yubikey enabled. To add more users just edit /etc/yubikey with more users and their IDs"
echo "If you run in to some kind of trouble and want to disable authentication by yubikey, just run 'pam-auth-update' again and deselect yubikey authentication"
