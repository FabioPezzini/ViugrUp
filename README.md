# ViugrUp

## Installation
- Ruby (development): https://www.ruby-lang.org/en/
- Vagrant: http://www.vagrantup.com/
- Virtual Box: https://www.virtualbox.org/
- [OPTIONAL] Docker: https://www.docker.com/

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
2. Inside the machine's tag add a tag `<docker_image></docker_image>` between the tag put image of the OS that you want to use (by DockerHub).
3. Inside the machine's tag add a tag `<provider>Docker</provider>` this will serve the wrapper to manage the creation of the machine.
4. Define the network's interface of the machine, you can define 0 or more interfaces

#### Network Interfaces
Between the machine's tag of the selected machine you can add:
- Public Network: an interface that will make the machine accessible anywhere (LAN,...).

  Add a tag `<public_network></public_network>`:
  1. [OPTIONAL] If you are using a scenario with different VirtualBox VM and Docker Container and you want them to be able to communicate through their public ip,
  inside previous tag add a tag `<network_name></network_name>` Inside this tag write the name of the network (ex: net1), add it to
  all the machines that you prefer.
  N.B = Use this tag only for the communication between VirtualBox VM and Docker Container
  2. Inside the public_network's tag add a tag `<ip></ip>`, between you can insert the a custom ip (ex 192.168.1.24) or you can insert
  `dhcp` to leave at the wrapper the the burden of choice.
  N.B = The use of `dhcp` is recommended.
 
- Private Network: an interface that will make the machine accessible only by the host and the other machines in same network.

  Add a tag `<private_network></private_network>`:
   1. [OPTIONAL] If you are using a scenario with different VirtualBox VM and you want to isolate a group of them for each machine
   add a tag `<network_name></network_name>` Inside this tag write the name of the network (ex: net1), add it to
   all the machines that you want isolate together.
   2. [OPTIONAL] If you want to allow the machine to communicate with the host add a tag `<host></host>` and write Y inside it
   3. Inside the private_network's tag add a tag `<ip></ip>`, between you can insert the a custom ip (ex 172.17.0.12) or you can insert
    `dhcp` to leave at the wrapper the the burden of choice.
    N.B = The use of `dhcp` is recommended.