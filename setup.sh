#!/bin/bash

if [[ "$EUID" -eq 0 ]]; then
    echo "Please do **NOT** run as root."
    exit 1
fi

## invalidate any cached sudo, prompt for password
sudo -kk
sudo whoami >/dev/null
## actually checks if sudo credentials were cached successfully
if [[ $(sudo whoami) == 'root' ]]
then
    printf '\nGreat! User has sudo, continue...\n\n'
else
    echo 'Seems like user does not have sudo!'
    echo 'Please visit this page to read how to grant permissions to user:'
    echo 'https://www.digitalocean.com/community/articles/how-to-edit-the-sudoers-file-on-ubuntu-and-centos'
    exit 1
fi

RESOLUTION=${1:-"2048x1280x24"}
USERNAME=${2:-"mahmoud"}


function setup_user() {
    useradd -m -d /home/${USERNAME} -s /bin/bash ${USERNAME}
    usermod -a -G admin ${USERNAME}
    echo "${USERNAME}" | passwd --stdin
    cp -pR ~ubuntu/.ssh ~${USERNAME}
    chown -R ${USERNAME}: ~${USERNAME}/.ssh/
}


function start_xfce4() {
    COOKIE=$(ps -ef | md5sum | cut -f 1 -d " ")
    AUTHFILE=${HOME}/Xvfb-0.auth
    xauth add :0 MIT-MAGIC-COOKIE-1 ${COOKIE}
    # or custom resolution
    Xvfb :0 -auth ${AUTHFILE} -screen 0 ${RESOLUTION} &
    DISPLAY=:0 nohup /etc/X11/Xsession startxfce4 &
}


function install_nomachine() {
    wget http://download.nomachine.com/download/4.6/Linux/nomachine_4.6.4_13_amd64.deb
    dpkg -i nomachine_4.6.4_13_amd64.deb
    echo 'DefaultDesktopCommand "/usr/bin/X11/startxfce4"' >> /usr/NX/etc/server.cfg
    echo "PhysicalDesktopAuthorization 0" >> /usr/NX/etc/server.cfg
    echo "VirtualDesktopAuthorization 0"  >> /usr/NX/etc/server.cfg
    service nxserver restart
    /usr/NX/bin/nxserver --install --setup-nomachine-key
    /usr/NX/bin/nxserver --useradd ${USERNAME}
}

function install_splashtop() {
    wget http://d17kmd0va0f0mp.cloudfront.net/linux/Splashtop_Streamer_Ubuntu_14.04_v2.2.5.1-4_amd64.deb
    dpkg -i Splashtop_Streamer_Ubuntu_14.04_v2.2.5.1-4_amd64.deb
    # Edit $HOME/.config/splashtop-streamer/.SplashtopStreamer.rc
    # Modify field “Port” to configure listened port number.
    # Add fields “SharpFPS” and “SmoothFPS” to configure frame rate per second.
}

function install_intellij() {
    wget http://download.jetbrains.com/idea/ideaIU-14.1.4.tar.gz
    tar xzf iideaIU-14.1.4.tar.gz
    mv ideaIU-14.1.4 intellij-idea
}

function install_xrdp () {
    sudo apt-get install
}

function main() {
    # setup java
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true \
        | debconf-set-selections
    add-apt-repository -y ppa:webupd8team/java

    apt-get -qq update
    apt-get install -y oracle-java8-installer xfce4 xvfb

#    start_xfce4
    setup_user
#    install_splashtop
    install_xrdp
    install_intellij
}

main
if [ $? -ne 0 ]; then
    echo "install failed. try again."
    exit -1
fi

cd intellij-idea
JAVA_HOME/usr/lib/jvm/java-8-oracle ./bin/idea.sh
