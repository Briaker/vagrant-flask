#!/bin/bash
echo "Provisioning virtual machine..."

# Workaround for 'dpkg-preconfigure: unable to re-open stdin' errors
export DEBIAN_FRONTEND=onninteractive

APP_NAME=$2
APP_ROOT=$1
APP_PROVISION="$APP_ROOT/provision"
USER="www-data"
USERGROUP="www-data"
UWSGI_LOG_PATH="/var/log/$APP_NAME"
UWSGI_RUN_PATH="/var/run/$APP_NAME"
UWSGI_ETC_PATH="/etc/$APP_NAME"

footer() {
    echo -e "Done.\n"
}

ensureSymlink () {
    target=$1
    symlink=$2
    if ! [ -L "$symlink" ];
    then
        sudo ln -s $target $symlink
        echo "Created symlink $symlink that references $target"
        return 1
    else
        return 0
    fi
}

cpEdit() {
    SOURCE=$1
    DESTINATION=$2
    FILENAME=$3

    if [ -f $FILE ];
    then
        sudo cp $SOURCE/$FILENAME $DESTINATION
        sudo sed -i -e "s|{APP_NAME}|$APP_NAME|g" "$DESTINATION/$FILENAME"
        sudo sed -i -e "s|{APP_ROOT}|$APP_ROOT|g" "$DESTINATION/$FILENAME"
        sudo sed -i -e "s|{USER}|$USER|g" "$DESTINATION/$FILENAME"
        sudo sed -i -e "s|{USERGROUP}|$USERGROUP|g" "$DESTINATION/$FILENAME"
        sudo sed -i -e "s|{UWSGI_LOG_PATH}|$UWSGI_LOG_PATH|g" "$DESTINATION/$FILENAME"
        sudo sed -i -e "s|{UWSGI_RUN_PATH}|$UWSGI_RUN_PATH|g" "$DESTINATION/$FILENAME"
        sudo sed -i -e "s|{UWSGI_ETC_PATH}|$UWSGI_ETC_PATH|g" "$DESTINATION/$FILENAME"
    fi
}

backup() {
    TARGET=$1
    NAME=$2
    if [ -d $TARGET ];
    then
        DATE=`date +%Y-%m-%d.%H:%M:%S`

        sudo mkdir -p $TARGET/../backup/$NAME$DATE

        rsync -a $TARGET $TARGET/../backup/$NAME$DATE
        sudo rm -rf $TARGET
    fi
}

# Backing up and cleaning
backup "$APP_ROOT/$APP_NAME" "$APP_NAME"

if [ -f "$APP_ROOT/nginx.conf" ];
then
    sudo rm -rf $APP_ROOT/nginx.conf
fi

if [ -f "$APP_ROOT/uwsgi.ini" ];
then
    sudo rm -rf $APP_ROOT/uwsgi.ini
fi

if [ -f "$APP_ROOT/uwsgi.ini" ];
then
    sudo rm -rf $APP_ROOT/emperor.conf
fi

if [ -f "$APP_ROOT/uwsgi_params" ];
then
    sudo rm -rf $APP_ROOT/uwsgi_params
fi

if [ -d "$APP_ROOT/env" ];
then
    sudo rm -rf $APP_ROOT/env
fi

if [ -d "/var/provision/resources/packages/temp" ];
then
    sudo rm -rf /var/provision/resources/packages/temp
fi
# ==============================

# Create app root directory
sudo mkdir -p $APP_ROOT/$APP_NAME

# Apply permisions
sudo chown -R $USER:$USERGROUP $APP_ROOT/$APP_NAME


echo "Updating Ubuntu..."
{
    # Add shh key for mongodb
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
    # Add mongodb repo to sources
    echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list

    sudo apt-get update
    sudo apt-get upgrade -y
} &> /dev/null
footer

echo "Installing Python..." 
{
    sudo apt-get install build-essential -y python-dev -y libmysqlclient-dev -y libffi-dev -y libssl-dev -y
    sudo apt-get install libfreetype6 -y libfreetype6-dev -y zlib1g-dev -y
    sudo apt-get install python-imaging -y

    # Install pip via python script
    curl https://bootstrap.pypa.io/get-pip.py | sudo python

    # libjpeg must be installed manually (temporary fix)
    cd $APP_PROVISION/resources/packages
    bash libjpeg-install.sh

    sudo apt-get install libjpeg-dev -y

} &> /dev/null
footer

echo "Installing MongoDB..." 
{
    sudo apt-get install mongodb-org -y
} &> /dev/null
footer

echo "Installing virtualenv..." 
{
    sudo pip install virtualenv
    cd $APP_ROOT
    virtualenv env --always-copy
    source env/bin/activate
} &> /dev/null
footer

echo "Installing Flask..." 
{
    pip install -r $APP_PROVISION/requirements.txt

    # Copy boilerplate
    cp -a "$APP_PROVISION/resources/boilerplates/flask-mvc/." $APP_ROOT/$APP_NAME

    deactivate
} &> /dev/null
footer

echo "Installing NodeJs..." 
{
    sudo apt-get install nodejs-legacy -y
    sudo apt-get install npm -y
    sudo npm install -g gulp
} &> /dev/null
footer

echo "Installing Ruby and Sass..." 
{
    sudo apt-get install ruby-full -y
    sudo su -c "gem install sass"
} &> /dev/null
footer

echo "Installing NGINX..." 
{
    sudo apt-get install nginx -y uwsgi-plugin-python -y
} &> /dev/null
footer

echo "Installing uWSGI..." 
{
    sudo pip install uwsgi

    # Clean then make uwsgi log directory
    if [ -d $UWSGI_LOG_PATH ];
    then
         sudo rm -rf $UWSGI_LOG_PATH
    fi

    sudo mkdir -p $UWSGI_LOG_PATH

    sudo chown -R www-data:www-data $UWSGI_LOG_PATH

    # Clean then make uwsgi run directory
    if [ -d $UWSGI_RUN_PATH ];
    then
        sudo rm -rf $UWSGI_RUN_PATH
    fi

    sudo mkdir -p $UWSGI_RUN_PATH
    sudo chown -R www-data:www-data $UWSGI_RUN_PATH

    # Clean then make uwsgi etc directory
    if [ -d $UWSGI_ETC_PATH ];
    then
        sudo rm -rf $UWSGI_ETC_PATH
    fi

    sudo mkdir $UWSGI_ETC_PATH
    sudo chown -R www-data:www-data $UWSGI_ETC_PATH

} &> /dev/null
footer

echo "Configuring Web Server..." 
{
    cpEdit "$APP_PROVISION/server" "$APP_ROOT" "nginx.conf"
    cpEdit "$APP_PROVISION/server" "$APP_ROOT" "uwsgi.ini"
    cpEdit "$APP_PROVISION/server" "$APP_ROOT" "uwsgi_params"
    
    # Emperor setup

    # UpStart service
    cpEdit "$APP_PROVISION/server" "/etc/init" "emperor.conf"
    
    if [ ! -d $UWSGI_ETC_PATH/vassals ];
    then
        sudo mkdir -p $UWSGI_ETC_PATH/vassals
    fi
    
    # End of Emperor setup


    # Enable App
    ensureSymlink $APP_ROOT/uwsgi.ini $UWSGI_ETC_PATH/vassals/uwsgi.ini

    # Enable Site
    ensureSymlink $APP_ROOT/nginx.conf /etc/nginx/sites-enabled/nginx.conf

    # Remove default nginx site
    sudo rm /etc/nginx/sites-enabled/default

    # Reapply permissions
    sudo chown -R www-data:www-data $APP_ROOT/$APP_NAME/

    # Restart nginx service
    sudo service nginx stop

    # Remove init.d service
    sudo update-rc.d -f nginx remove

    # Add upstart service
    sudo cp $APP_PROVISION/server/upstart/nginx.conf /etc/init/

    # Workaround for Vagrant enviroment, restarts nginx service after mount
    sudo cp $APP_PROVISION/server/upstart/vvv.conf /etc/init/

    sudo service nginx start

    # Restart emperor service
    sudo service emperor stop
    sudo service emperor start
} &> /dev/null
footer
echo "Finished Provisioning"