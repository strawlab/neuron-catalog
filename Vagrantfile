# Vagrantfile to create a development neuron catalog server.

# This file was tested with Vagrant 1.6.5 using Virtual Box 4.3.14 on
# Mac OS X.

# CHANGE THESE SETTINGS TO CONFIGURE. ------------------------------------------------
settings = <<-EOF
    echo ' "DefaultUserRoles": ["read","write"],' >>  /neuron-catalog/server/config.json
EOF
# ------------------------------------------------------------------------------------


VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "neuron-catalog-demo"
  config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/"\
                      "trusty-server-cloudimg-amd64-vagrant-disk1.box"

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", 2000]
    vb.customize ["modifyvm", :id, "--cpus", 2]
  end

  config.vm.network "forwarded_port", guest: 3450, host: 3450
  config.vm.provision "shell", inline: "apt-get update"
  config.vm.provision "shell", inline: "apt-get install --yes ansible"

  # MongoDB does not like running on shared disk, so don't. We want to
  # copy /vagrant to /neuron-catalog while excluding /vagrant/.meteor/local
  config.vm.provision "shell", inline: "mkdir -p /neuron-catalog/server && "\
    "tar -c --exclude ./.meteor/local -C /vagrant . | tar -x -C /neuron-catalog"

  config.vm.provision "shell", inline: settings

  # Let ansible provision everything else
  config.vm.provision "shell", inline: "cd /neuron-catalog/server/ansible && "\
    "ansible-playbook -i 'localhost ansible_connection=local,' playbook.yml"
end
