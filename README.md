```
               __   __   __     __  __     ______     ______     __  __     ______  
              /\ \ / /  /\ \   /\ \/\ \   /\  ___\   /\  == \   /\ \/\ \   /\  == \ 
              \ \ \'/   \ \ \  \ \ \_\ \  \ \ \__ \  \ \  __<   \ \ \_\ \  \ \  _-/ 
               \ \__|    \ \_\  \ \_____\  \ \_____\  \ \_\ \_\  \ \_____\  \ \_\   
                \/_/      \/_/   \/_____/   \/_____/   \/_/ /_/   \/_____/   \/_/ 
```                                                                      
                                                                      
                                                                      
## Installation
ViugrUp is only avaible on Linux systems, you will need to install the following:
- Ruby (development): https://www.ruby-lang.org/en/
- Vagrant: http://www.vagrantup.com/
- Virtual Box: https://www.virtualbox.org/
- Docker: https://www.docker.com/

Git clone Viugrup to a directory of your choosing, such as /home/user/bin/viugrup , N.B = don't install in /opt
Then install gems:
```sh
cd /home/user/bin/viugrup
bundle install
```

In order to ensure the wrapper to works properly, allow your user to use all the functionality of Docker.
Follow this guide,in particular the paragraph about "Manage Docker as a non-root user": https://docs.docker.com/install/linux/linux-postinstall/


## How Use Xml Scenario
N.B = Use the labs in the `/labs` dir as a starting point to create your own.
1. Create a file .xml and place it in the `/labs` dir of the  project folder. Choose an unused name to avoid
conflict
2. Add a tag `<scenario></scenario>` that is the base tag which will contain the scenario description and the list of machines to be created.
3. [OPTIONAL] Inside the scenario's tag add a tag `<description></description>` which is useful for an immediate understanding of the scenario
4. Choose if create a VirtualBox VM or a Docker Container

### VirtualBox VM
1. Add a tag `<machine></machine>`,  inside the tag you will have to enter all the settings of the machine, in a single file it is possible to create more machines.
2. Inside the machine's tag add a tag `<machine_base></machine_base>` between the tag put the OS of the VM that you want to use.
3. [OPTIONAL] Inside the machine's tag add a tag `<version></version>` between the tag put the version of the OS.
4. Inside the machine's tag add a tag `<provider>VirtualBox</provider>` this will serve the wrapper to manage the creation of the machine.
5. Define the network's interface of the machine, you can define 0 or more interfaces

### Docker Container
1. Add a tag `<machine></machine>`,  inside the tag you will have to enter all the settings of the machine, in a single file it is possible to create more machines.
2. Inside the machine's tag add a tag `<machine_base></machine_base>` between the tag put the OS of the VM that you want to use.
3. [OPTIONAL] Inside the machine's tag add a tag `<version></version>` between the tag put the version of the OS.
4. Inside the machine's tag add a tag `<provider>Docker</provider>` this will serve the wrapper to manage the creation of the machine.
5. Define the network's interface of the machine, you can define 0 or more interfaces

#### Network Interfaces
Between the machine's tag of the selected machine you can add:
- Public Network: an interface that will make the machine accessible anywhere (LAN,...).

  Add a tag `<public_network></public_network>`:
  1. Inside the public_network's tag add a tag `<ip></ip>`, between you can insert the a custom ip (ex 192.168.1.24) or you can insert
     `dhcp` to leave at the wrapper the the burden of choice.
  N.B = The use of `dhcp` is recommended.on windows
  
 
- Private Network: an interface that will make the machine accessible only by the host and the other machines in same network.

  Add a tag `<private_network></private_network>`:
  1. [OPTIONAL] If you are using a scenario with different VirtualBox VM and you want to isolate a group of them for each machine
     add a tag `<network_name></network_name>` Inside this tag write the name of the network (ex: net1), add it to
     all the machines that you want isolate together.
      N.B = Use this tag only for the communication between VirtualBox VM and Docker Container
  2. Inside the private_network's tag add a tag `<ip></ip>`, between you can insert the a custom ip (ex 172.17.0.12) or you can insert
     `dhcp` to leave at the wrapper the the burden of choice.
  N.B = The use of `dhcp` is recommended.
