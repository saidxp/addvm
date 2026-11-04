# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Configurable Base Box name (default: debian13-local)
  box_name = ENV.fetch("VAGRANT_BOX", "debian13-local")
  config.vm.box = box_name

  # i was add manual in box to this va

  config.vm.hostname = "vbox"

# VirtualBox Provider Settings
  config.vm.provider "virtualbox" do |vb|
    vb.name = "debian13-vagrant"
    vb.memory = 2048
    vb.cpus = 2
    vb.gui = false
  end

    config.vm.synced_folder "provision", "/vagrant/provision"

config.vm.provision "shell",
  inline: "bash /vagrant/provision/provision.sh"
end
