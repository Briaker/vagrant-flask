# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
    config.vm.box = "ubuntu-trusty-64"
    config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"

    config.vm.network :forwarded_port, guest: 80, host: 8080, auto_correct: true
    config.vm.network :forwarded_port, guest: 8000, host: 8888, auto_correct: true
    config.vm.network "public_network", bridge: "eth0"

    config.vm.synced_folder "www/", "/var/www", create: true, group: "www-data", owner: "vagrant"

    config.vm.provider :virtualbox do |v|
        v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
        v.customize ["modifyvm", :id, "--nictype1", "virtio"]
        v.name = "myApp"
        v.memory = 4096
        v.cpus = 4
        v.gui = false
    end

    config.vm.provision "shell" do |s|
       s.path = "www/provision/setup.sh"

       # Required arguments:
       #    arg1: root dir in the guest machine
       #    arg2: the name of your app
       s.args = "'/var/www' 'myApp'"
    end
end
