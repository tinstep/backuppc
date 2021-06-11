#!/bin/bash
# update passwoird and 2x keys
BUCLIENTUSER=backup-login-user
BURSYNCCMD=`command -v rsync`
BUSUDOERS="/etc/sudoers"
BUSUDOENTRY="$BUCLIENTUSER ALL=NOPASSWD: /usr/bin/rsync --server  --sender * /n backuppc ALL=NOPASSWD: /usr/bin/rsync --server --transmitter * "

BUHOMEDIR=home

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "WARN: This script must be run as root" 1>&2; exit 1
fi


# Check for backuppc user and create if needed
if id "$BUCLIENTUSER" >/dev/null 2>&1; then
        echo "INFO: user exists, continuing..."
else
        echo "INFO: user does not exist, creating user..."
        pass=$(perl -e 'print crypt("password", "password");')
        useradd -d /$BUHOMEDIR/$BUCLIENTUSER -m $BUCLIENTUSER -p "$pass" -s /bin/bash
fi


# Make sure rsync is installed
command -v rsync >/dev/null 2>&1 || { echo >&2 "WARN: I require rsync but it's not installed.  Aborting."; exit 1; }

if [ -f $BUSUDOERS ]; then
   echo "INFO: ''$BUSUDOERS'' file found."
   echo "INFO: checking file to determine if patching is required."
   if [ `cat $BUSUDOERS | grep $BUCLIENTUSER | wc -l` -eq 0 ]; then
        echo "$BUSUDOENTRY" >> $BUSUDOERS
        echo "INFO: $BUSUDOERS has been patched"
   else
        echo "INFO: $BUCLIENTUSER exists in $BUSUDOERS, no changes, continuing ..."
   fi
else
        echo "WARN: $BUSUDOERS does not exist, aborting"; exit 1
fi


# Setup ssh keys
echo "INFO: Check for ssh folder"
if [ -f /$BUHOMEDIR/$BUCLIENTUSER/.ssh ]; then
        echo "INFO: Found .ssh folder"
        touch /$BUHOMEDIR/$BUCLIENTUSER/.ssh/authorized_keys
        echo "INFO: Checking for backuppc public key"
        if [ `cat $BUSUDOERS | grep backuppc@omv | wc -l` -eq 0 ]; then
                echo "Patching file to add public key"
                cat > /$BUHOMEDIR/$BUCLIENTUSER/.ssh/authorized_keys <<EOF
add auth key here
EOF
                echo "Public key for backuppc add to authorized_keys"
        else
                echo "INFO: found public key - no changes"
        fi
else
        echo "INFO: Creating .ssh folder and ''authorized_keys'' file in the folder /$BUHOMEDIR/$BUCLIENTUSER/"
        mkdir -p /$BUHOMEDIR/$BUCLIENTUSER/.ssh
        touch /$BUHOMEDIR/$BUCLIENTUSER/.ssh/authorized_keys
        cat > /$BUHOMEDIR/$BUCLIENTUSER/.ssh/authorized_keys <<EOF
add auth keys here
fi

# Ensure correct perms for ssh authorized_keys file
echo "INFO: Changing perms so ssh works correctly"
chown -R $BUCLIENTUSER /$BUHOMEDIR/$BUCLIENTUSER/.ssh
chmod 600 /$BUHOMEDIR/$BUCLIENTUSER/.ssh/authorized_keys
echo "INFO: All done - any errors?"

