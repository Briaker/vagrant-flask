# vagrant-flask
Vagrant [ubuntu-trusty-64] 

Provisioned:
Venv,
Python 2.6,
NodeJS,
Ruby
NGINX,
uWSGI (emperor),
Flask,
MongoDB,
Sass

*Inculdes a flask-mvc boilerplate

Open VagratnFile and under config.vm.provision change arg2 to your apps' name.

Everytime the provision script is run and an existsing directory with the same app name is found, a backup of the app folder will be made (env and the ini/config files in the root dir will be deleted)