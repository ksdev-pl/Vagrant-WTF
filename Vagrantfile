# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.network :private_network, ip: "192.168.33.10"
  config.vm.provision :shell, :path => "nginx.sh"
  config.vm.synced_folder ".", "/var/www/vagrant.dev/",
      owner: "vagrant",
      group: "www-data",
      mount_options: ["dmode=775,fmode=664"]
end
