#!/bin/bash
#
# This script will automate the process of installing the Yubikey PAM library
# and configure your server to use it for authentication. 
#
# Rickard Andersson <rickard@0x539.se>
#

if [ ! `whoami` == "root" ]; then
	echo "Please run this script as root, either log on as root or run 'sudo $0'"
	exit 1
fi

LIBYUBIKEY="libyubikey-1.8"
YKPERS="ykpers-1.8.0"
YKCLIENT="ykclient-2.9"
PAM_YUBICO="pam_yubico-2.12"

clear

echo ""
echo "This script will do the following on your system: "
echo "1. Install some packages needed for the installation."
echo "2. Download libyubikey, ykpers, ykclient and pam_yubico from Google Code."
echo "3. Configure, compile and install the packages."
echo "4. Add Yubikey authentication configuration to PAM."
echo "5. Ask you if you want to enable Yubikey authentication."
echo "6. Prompt you for a Yubikey OTP and link the root account."
echo ""
echo "If you're not fine with this script performing these actions,"
echo "please press CTRL+C now to abort the installation. Otherwise press ENTER,"
echo "go find your Yubikey and we'll continue this installation together."

read continue

clear 

echo "You'll have to get an API key to be able to use the Yubico authentication "
echo "service. Please visit https://upgrade.yubico.com/getapikey/ and use your "
echo "Yubikey to get a API key. You need to have one before installation can begin."
echo ""
echo -n "Please enter your Client ID obtained from the API key request site: "

read client_id

clear 

echo "(1/26) ==> Installing missing debian packages (if any) ... "

apt-get install -qq -y build-essential libusb-dev libcurl4-gnutls-dev libpam-dev curl

cd /usr/src

if [ ! -f $LIBYUBIKEY.tar.gz ]; then
	echo "(2/26) ==> Downloading $LIBYUBIKEY from googlecode.com ..."
	curl -s -o $LIBYUBIKEY.tar.gz http://yubico-c.googlecode.com/files/$LIBYUBIKEY.tar.gz
fi

if [ ! -d $LIBYUBIKEY ]; then
	echo "(3/26) ==> Extracting archive ..."
	tar zxf $LIBYUBIKEY.tar.gz
fi

cd $LIBYUBIKEY
echo "(4/26) ==> Configuring package ..."
./configure > /dev/null
echo "(5/26) ==> Compiling and installing ..."
make all install > /dev/null
cd ..
echo "(6/26) ==> Cleaning up ..."
rm -rf $LIBYUBIKEY $LIBYUBIKEY.tar.gz

if [ ! -f $YKPERS.tar.gz ]; then
	echo "(7/26) ==> Downloading $YKPERS from googlecode.com ..."
	curl -s -o $YKPERS.tar.gz http://yubikey-personalization.googlecode.com/files/$YKPERS.tar.gz
fi

if [ ! -d $YKPERS ]; then
	echo "(8/26) ==> Extracting archive ..."
	tar zxf $YKPERS.tar.gz
fi

cd $YKPERS
echo "(9/26) ==> Configuring package ..."
./configure > /dev/null
echo "(10/26) ==> Compiling and installing ..."
make all install > /dev/null
cd ..
echo "(11/26) ==> Cleaning up ..."
rm -rf $YKPERS $YKPERS.tar.gz

if [ ! -f $YKCLIENT.tar.gz ]; then
	echo "(12/26) ==> Downloading $YKCLIENT from googlecode.com ..."
	curl -s -o $YKCLIENT.tar.gz http://yubico-c-client.googlecode.com/files/$YKCLIENT.tar.gz
fi

if [ ! -d $YKCLIENT ]; then
	echo "(13/26) ==> Extracing archive ..."
	tar zxf $YKCLIENT.tar.gz
fi

cd $YKCLIENT
echo "(14/26) ==> Configuring package ..."
./configure > /dev/null
echo "(15/26) ==> Compiling and installing ..."
make all install > /dev/null
cd ..
echo "(16/26) ==> Cleaning up ..."
rm -rf $YKCLIENT $YKCLIENT.tar.gz

if [ ! -f $PAM_YUBICO.tar.gz ]; then
	echo "(17/26) ==> Downloading $PAM_YUBICO from googlecode.com ..."
	curl -s -o $PAM_YUBICO.tar.gz http://yubico-pam.googlecode.com/files/$PAM_YUBICO.tar.gz
fi

if [ ! -d $PAM_YUBICO ]; then
	echo "(18/26) ==> Extracting archive ..."
	tar zxf $PAM_YUBICO.tar.gz
fi 

cd $PAM_YUBICO
echo "(19/26) ==> Configuring package ..."
./configure > /dev/null
echo "(20/26) ==> Compiling and installing ..."
make all install > /dev/null
cd ..
echo "(21/26) ==> Cleaning up ..."
rm -rf $PAM_YUBICO $PAM_YUBICO.tar.gz

echo "(22/26) ==> Linking pam modules ..."
ln -s /usr/local/lib/security/pam_yubico.la /lib/security/pam_yubico.la
ln -s /usr/local/lib/security/pam_yubico.so /lib/security/pam_yubico.so

echo "(23/26) ==> Generating config ..."

echo "Name: Yubikey authentication
Default: yes
Priority: 512
Auth-Type: Primary
Auth:
        requisite pam_yubico.so id=$client_id authfile=/etc/yubikey" >> /usr/share/pam-configs/yubikey

echo "(24/26) ==> Running pam-auth-update ..."

pam-auth-update

echo -n "(25/26) ==> Please press your Yubikey to generate a OTP: "

read YUBICODE

echo "(26/26) ==> Configuring root account with your Yubikey ..."

echo "root:"`echo $YUBICODE | cut -c 1-12` > /etc/yubikey

echo ""

echo "Done!"
echo "If you choose to enable Yubikey authentication in pam-auth-update, you can"
echo "now try to sign in using your Yubikey by running the command 'login'."
echo "It's highly recommended that you try this out before you sign out, since "
echo "a misconfiguration can lead to you not being able to access your server."
echo "" 
echo "If you want to sign in to your account with SSH you need to first enter "
echo "your regular password and then, without pressing enter, push the button "
echo "on your yubikey to generate an OTP. This will send your regular password "
echo "and the OTP as one password to SSH. But when signing in locally you'll "
echo "still be prompted for both the password and OTP separately."
echo "" 
echo "Please note that the root account is the only account which has a Yubikey "
echo "enabled. To add more users just edit /etc/yubikey with more users and their"
echo "IDs. You really have to do this if your server doesn't permit remote logins"
echo "with the root account, so be sure to configure your regular account with"
echo "Yubkey as well, _before_ you close this session. If you run in to some kind"
echo "of trouble and want to disable authentication by yubikey, just run"
echo "'pam-auth-update' again and deselect yubikey authentication."
echo ""
echo "NOTE: The Yubikey ID is the first 12 characters of any OTP generated "
echo "by the Yubikey device."
