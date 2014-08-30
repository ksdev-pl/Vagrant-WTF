# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "chef/debian-7.6"
  config.vm.network :private_network, ip: "192.168.33.10"
  config.vm.provision :shell, :path => "vagrant.sh"
  config.vm.synced_folder ".", "/var/www/"
end