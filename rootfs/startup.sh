#!/bin/bash

USER=$(whoami)

if [ -n "$VNC_PASSWORD" ]; then
    sudo /bin/bash -c 'echo -n "$VNC_PASSWORD" > /.password1'
    sudo x11vnc -storepasswd $(cat /.password1) /.password2
    sudo chmod 400 /.password*
    sudo sed -i 's/^command=x11vnc.*/& -rfbauth \/.password2/' /etc/supervisor/conf.d/supervisord.conf
    sudo export VNC_PASSWORD=
fi

if [ -n "$X11VNC_ARGS" ]; then
    sudo sed -i "s/^command=x11vnc.*/& ${X11VNC_ARGS}/" /etc/supervisor/conf.d/supervisord.conf
fi

if [ -n "$OPENBOX_ARGS" ]; then
    sudo sed -i "s#^command=/usr/bin/openbox\$#& ${OPENBOX_ARGS}#" /etc/supervisor/conf.d/supervisord.conf
fi

sudo rm /usr/local/bin/xvfb.sh
sudo /bin/bash -c 'echo -e "#!/bin/sh \\n exec /usr/bin/Xvfb :1 -screen 0 1024x768x24" > /usr/local/bin/xvfb.sh'
if [ -n "$RESOLUTION" ]; then
    sudo sed -i "s/1024x768/$RESOLUTION/" /usr/local/bin/xvfb.sh
fi
sudo chmod +x /usr/local/bin/xvfb.sh

#USER=${USER:-root}
HOME=/home/$USER
if [ "$USER" != "root" ]; then
    echo "* enable custom user: $USER"
    # #useradd --create-home --shell /bin/bash --user-group --groups adm,sudo $USER
    # if [ -z "$PASSWORD" ]; then
    #     echo "  set default password to \"ubuntu\""
    #     PASSWORD=ubuntu
    # fi
    HOME=/home/$USER
    # echo "$USER:$PASSWORD" | chpasswd
    sudo cp -r /root/{.config,.gtkrc-2.0,.asoundrc} ${HOME} 2>/dev/null
    [ -d "/dev/snd" ] && sudo chgrp -R adm /dev/snd
fi

sudo sed -i -e "s|%USER%|$USER|" -e "s|%HOME%|$HOME|" /etc/supervisor/conf.d/supervisord.conf
sudo sed -i -e "s|/root|$HOME|" /etc/supervisor/conf.d/supervisord.conf
sudo sed -i -e "s|root|$USER|" /etc/supervisor/conf.d/supervisord.conf

# home folder
if [ ! -x "$HOME/.config/pcmanfm/LXDE/" ]; then
    mkdir -p $HOME/.config/pcmanfm/LXDE/
    sudo ln -sf /usr/local/share/doro-lxde-wallpapers/desktop-items-0.conf $HOME/.config/pcmanfm/LXDE/
fi

# nginx workers
sudo sed -i 's|worker_processes .*|worker_processes 1;|' /etc/nginx/nginx.conf

# nginx ssl
if [ -n "$SSL_PORT" ] && [ -e "/etc/nginx/ssl/nginx.key" ]; then
    echo "* enable SSL"
        sudo sed -i 's|#_SSL_PORT_#\(.*\)443\(.*\)|\1'$SSL_PORT'\2|' /etc/nginx/sites-enabled/default
        sudo sed -i 's|#_SSL_PORT_#||' /etc/nginx/sites-enabled/default
fi

# nginx http base authentication
if [ -n "$HTTP_PASSWORD" ]; then
    echo "* enable HTTP base authentication"
    sudo htpasswd -bc /etc/nginx/.htpasswd $USER $HTTP_PASSWORD
    sudo sed -i 's|#_HTTP_PASSWORD_#||' /etc/nginx/sites-enabled/default
fi

# dynamic prefix path renaming
if [ -n "$RELATIVE_URL_ROOT" ]; then
    echo "* enable RELATIVE_URL_ROOT: $RELATIVE_URL_ROOT"
        sudo sed -i 's|#_RELATIVE_URL_ROOT_||' /etc/nginx/sites-enabled/default
        sudo sed -i 's|_RELATIVE_URL_ROOT_|'$RELATIVE_URL_ROOT'|' /etc/nginx/sites-enabled/default
fi


sudo chown -R $USER:$USER ${HOME}/.cache
sudo chown -R $USER:$USER ${HOME}/.dbus
sudo chown -R $USER:$USER ${HOME}/.asoundrc
sudo chown -R $USER:$USER ${HOME}/.gtkrc-2.0
sudo chown -R $USER:$USER ${HOME}/.config

# clearup
PASSWORD=
HTTP_PASSWORD=

echo "============================================================================================"
echo "NOTE: --security-opt seccomp=unconfined flag is required to launch Ubuntu Jammy based image."
echo "See https://github.com/Tiryoh/docker-ubuntu-vnc-desktop/pull/1#issuecomment-1193352793"
echo "or https://github.com/Tiryoh/docker-ros2-desktop-vnc/pull/56"
echo "============================================================================================"

sudo /bin/tini -- supervisord -n -c /etc/supervisor/supervisord.conf

