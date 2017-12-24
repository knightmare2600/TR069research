# TR069research

This repo contains information on setting up a FreeACS server with ibvirt  and a Mikrotik x86 demo system,.

## Background 

This guide and repo allows research into TR-069 as covered by [@info_doz] (https://twitter.com/@info_dox) at B-Slides Edinburgh. This repo is for others who wish to wargame out, or build upon his excellent work.


More information on that, and a video of his talk, can be found [here](https://www.youtube.com/watch?v=rGIVx0HNOfk&list=PLhZJ3xYqiM4iyBXQVcFC7mO5Xstg6IwBN&index=12)


## Prerequisites

To begin, you will need to collect some files:

* ubuntu-14.04.5-server-amd64.iso		SHA256: DDE07D37647A1D2D9247E33F14E91ACB10445A97578384896B4E1D985F754CC1
* all_packages-x86-6.39.3.zip			SHA256: 5BAC1EA32BFCA56822FA2C902C31B3E27349E4F22B6F9E3482BA870184DA6BA8
* mikrotik-6.39.3.iso				SHA256: 22D6B47F15FA8B0E15728C49086390AF30FE1C476847F0F1878A8FB624DB022E
* FreeACS files - a copy is included in this repo
* Virtual platform of choice. Ill be using VMWare ESXi here
* A demo Mikrotik license key [from here] (https://wiki.mikrotik.com/wiki/Manual:License)

A fair bit of this information was cleaned from the user TheKitchen on the [mikrotik](https://forum.mikrotik.com) forums so thank you to him/her.

## Infrastructure Setup

### Ubutu FreeACS VM

Create a VM of reasonable size. I went with:

* 1GB RAM
* 10GB SCSI HDD
* 1 x VMXNET3 NIC
* hostname ```free-acs.example.com``` on ```192.168.10.9``` provisioned with a fixed lease in DHCP.

Do a basic Ubuntu install, my preference is to use LVM, as this makes splitting out /var /tmp /home, etc. much easier.

#### Package Selections

When prompted which package selections to install, select:

```
* Basic Ubuntu Server
* OpenSSH Server
* Tomcat Java Server
* Virtual Machine Host
```

#### User Setup

I created a user called ```busby / phormulateaplan``` and let the installation complete.

#### Post Install Setup

I always like to have an environment with the corect tools so now run

```
sudo apt-get install curl git grc lynx links nmap open-vm-tools tmux telnet vim-nox
```

I have installed three text-mode browsers as this allows testing while setting up.

### Installing FreeACS

Having now set up our environment, I suggesting cloning this repo to your VM.

Now, let us install the FreeACS software:

```
busby@gpo-isp:[~]$ wget http://freeacs.com/download/install-or-update-freeacs-ubuntu.sh
busby@gpo-isp:[~]$ chmod 755 install-or-update-freeacs-ubuntu.sh
## Ensure the script isn't doing anything malicious
busby@gpo-isp:[~]$ view install-or-update-freeacs-ubuntu.sh
busby@gpo-isp:[~]$ sudo ./install-or-update-freeacs-ubuntu.sh
```

The script will prompt for a root MySQL password. I went for ```redframewhitelight```. The script will additionaly ask for a password for the FreeACS database user. For this, I went with ```twilightzone``` as that's where we're heading.

After some time, the script will complete and we can proceed to the post-install fixes.


#### Post Install fixes

As outlined in the talk, one could easily make these edits via a sed or two. I'll do this manually for posterity.

First, edit ```/var/lib/tomcat7/conf/catalina.properties``` and find the string ```common.loader``` then append ```,${catalina.base}/common,${catalina.base}/common/*.properties``` save the file and exit

Second, edit ```/etc/init.d/tomcat7``` appending the line so it reads ```# Required-Start:    $local_fs $remote_fs $network $mysql``` then save the file and exit.

Third, edit ```/var/lib/tomcat7/common/xaps-stun.properties``` and set the ```primary.ip``` value so it reads ```primary.ip = 0.0.0.0``` save and exit the file.

NB: If you are not running this on a test LAN behind a firewall, you would change that to something else. Perhaps ```192.168.88.1``` if you intend only using the libvirt interface to administer CPE.

Lastly, restart tomcat for the changes to take effect: ```sudo service tomcat7 restart```

The default login will now be availble at ```http://freeacs.example.com``` where the login ```admin / xaps``` can be used.


### Pre Mikrotik Prep Work

For this part, we need a device which will run a TR-069 client. If you have routers to hand, connect them up. I am going to walk through the process of building a Mikrotik x86 router using KVM/libvirt.

Before we begin, ssh to Ubuntu host, and accept the SSH key. This allows the use of virt-manager remotely.

At this point, sign up for a free Mikrotik account. 

### Mikrotik Router VM x86

Using virt-manager, create a VM with the following specs:

* 128MB RAM
* 50M HDD
* NIC#1 ```RTL8139``` connected to ```macvtap0``` which gives this node a ```192.168.10.10/24``` IP from you DHCP server
* NIC#2 ```e1000```   connected to ```vnet0``` switch ```192.168.88.254/24``` the green (LAN) interface of the rotuer node
* CD-ROM connected to ```mikrotik-6.39.3.iso``` 
* Boot Order ```CD-ROM -> HDD```
* VM set to start on boot

NB: A good way to remember which NIC is which, is to remember the three R's: Realtek NIC / Red Interface / Routable to the internet

#### Setting up Mikrotek

On first boot, the VM will show a console. Log in with ```admin / <blank password>``` and copy the software ID:

```
MikroTik v6.39.3 (bugfix)
Login: admin
Password:

  MMM      MMM       KKK                          TTTTTTTTTTT      KKK
  MMMM    MMMM       KKK                          TTTTTTTTTTT      KKK
  MMM MMMM MMM  III  KKK  KKK  RRRRRR     OOOOOO      TTT     III  KKK  KKK
  MMM  MM  MMM  III  KKKKK     RRR  RRR  OOO  OOO     TTT     III  KKKKK
  MMM      MMM  III  KKK KKK   RRRRRR    OOO  OOO     TTT     III  KKK KKK
  MMM      MMM  III  KKK  KKK  RRR  RRR   OOOOOO      TTT     III  KKK  KKK

  MikroTik RouterOS 6.39.3 (c) 1999-2017       http://www.mikrotik.com/

ROUTER HAS NO SOFTWARE KEY
----------------------------
You have 23h49m to configure the router to be remotely accessible,
and to enter the key by pasting it in a Telnet window or in Winbox.
Turn off the device to stop the timer.
See www.mikrotik.com/key for more details.

Current installation "software ID": ABCD-E12F
Please press "Enter" to continue! <<enter>>
```

On the Mikrotik page, request a demo key, and be sure to copy and paste the software ID exactly as shown.

A key will be generated, which can be installed with winbox.exe or via telnet. I'll use telnet.

#### Initial Setup

Our next step is to configure the router for inital setup. Laziness being the mother of invention, I simply typed ```system reset-configuration``` which will bring the router up with a factory configuration, including DHCP on the red interface.

iAfter reboot, we can check the IP of the device:

```
[admin@MikroTik] > ip address print
Flags: X - disabled, I - invalid, D - dynamic
 #   ADDRESS            NETWORK         INTERFACE
 0 D 192.168.10.10/24   192.168.10.0    ether1
 1   ;;; defconf
     192.168.88.1/24    192.168.88.0    ether2
```

#### applying License

Now that the VM has an IP, telnet to it and paste the license into the console:

```
[admin@MikroTik] >-----BEGIN MIKROTIK SOFTWARE KEY------------
[admin@MikroTik] >OTBmNDVlMjgtMzg1Zi00NWE3LWI2OTctMzU2OTYxY2Q0
[admin@MikroTik] >MtMz1Zi0NWE3LWI2OY2Q0NDdlDI105ZDQxLTZjVZIK==
[admin@MikroTik] >-----END MIKROTIK SOFTWARE KEY--------------

You must reboot before new key takes effect. Reboot? [y/N]: y
```

NB: The key above is not a valid software license, it's the output of uuidgen piped into base64

After another reboot, confirm that the key is installed correctly:

```
  MMM      MMM       KKK                          TTTTTTTTTTT      KKK
  MMMM    MMMM       KKK                          TTTTTTTTTTT      KKK
  MMM MMMM MMM  III  KKK  KKK  RRRRRR     OOOOOO      TTT     III  KKK  KKK
  MMM  MM  MMM  III  KKKKK     RRR  RRR  OOO  OOO     TTT     III  KKKKK
  MMM      MMM  III  KKK KKK   RRRRRR    OOO  OOO     TTT     III  KKK KKK
  MMM      MMM  III  KKK  KKK  RRR  RRR   OOOOOO      TTT     III  KKK  KKK

  MikroTik RouterOS 6.39.3 (c) 1999-2017       http://www.mikrotik.com/


UPGRADE NOW FOR FULL SUPPORT
----------------------------
FULL SUPPORT benefits:
- receive technical support
- one year feature support
- free software upgrades
    (avoid re-installation and re-configuring your router)
To upgrade, register your license "software ID"
 on our account server www.mikrotik.com

Current installation "software ID": ABCD-E12F

Please press "Enter" to continue!

[admin@MikroTik] > system license print
  software-id: ABCD-E12F
       nlevel: 1
     features:
```
Notice the subtle chnage in the output regarding the key and support. Now we can install the TR-069 client. Which is, after all, the point of going to all this trouble.

#### TR-069 Client Install

Before we install the TR-069 package, run a free resources check:

```
[admin@MikroTik] > system resource print
                   uptime: 2m32s
                  version: 6.39.3 (bugfix)
               build-time: Oct/12/2017 11:24:56
              free-memory: 105.3MiB
             total-memory: 122.6MiB
                      cpu: QEMU
                cpu-count: 1
            cpu-frequency: 3515MHz
                 cpu-load: 8%
           free-hdd-space: 21.8MiB
          total-hdd-space: 52.1MiB
  write-sect-since-reboot: 472
         write-sect-total: 472
        architecture-name: x86
               board-name: x86
                 platform: MikroTik
```

We can see 21MB of space, which is more than enough for a 900KB TR-069 agent. This is uploaded via FTP:

#### Upload TR-069 package

```
ftp 192.168.10.10
Connected to 192.168.10.10.
220 MikroTik FTP server (MikroTik 6.39.3) ready
500 'OPTS': command not understood
User (192.168.10.10:(none)): admin
331 Password required for admin
Password:
230 User admin logged in
ftp> hash
Hash mark printing On  ftp: (2048 bytes/hash mark) .
ftp> bin
200 Type set to I
ftp> put tr069-client-6.39.3.npk
200 PORT command successful
150 Opening BINARY mode data connection for '/tr069-client-6.39.3.npk'
############################################
226 BINARY transfer complete
ftp: 90193 bytes sent in 0.01Seconds 18038.60Kbytes/sec.
ftp> bye
221 Closing
```

Once the package is uploaded, go back to the telnet session and confirm the file is there:

```
[admin@MikroTik] > /file print
 # NAME                                       TYPE                         SIZE      CREATION-TIME
 0 skins                                      directory                              dec/24/2017 12:14:22
 1 user-manager                               directory                              dec/24/2017 12:53:36
 2 user-manager/sqldb                         file                         80.0KiB   dec/24/2017 12:14:57
 3 user-manager/logsqldb                      file                          6.0KiB   dec/24/2017 12:14:55
 4 um-before-migration.tar                    .tar file                    15.5KiB   dec/24/2017 12:14:58
 5 auto-before-reset.backup                   backup                        9.7KiB   dec/24/2017 12:21:13
 6 tr069-client-6.39.3.npk                    package                     128.1KiB   dec/24/2017 12:59:43

[admin@MikroTik] > /system reboot
Reboot, yes? [y/N]:
y
system will reboot shortly
Connection closed by foreign host.
```

On reboot:

```
[admin@MikroTik] > /system package print
Flags: X - disabled
 #   NAME                                     VERSION                           SCHEDULED
 0   dhcp                                     6.39.3
 1   security                                 6.39.3
 2   mpls                                     6.39.3
 3   hotspot                                  6.39.3
 4   ntp                                      6.39.3
 5   gps                                      6.39.3
 6   lcd                                      6.39.3
 7   tr069-client                             6.39.3
 8   calea                                    6.39.3
 9   kvm                                      6.39.3
10   system                                   6.39.3
11   user-manager                             6.39.3
12   routing                                  6.39.3
```

#### Enable TR-069 on client router

The following Script will allow the Mikrotek to check in with the server freeacs.example.com

### Set TR069 Username to Ether1 mac address

```
[admin@MikroTik] /system script
add name=identity owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive source="delay 10;\
\n:local macaddress [/interface get ether1 mac-address]\
\n:local tidymac\
\n\
\n:for i from=0 to=([:len \$macaddress] - 1) do={ \
\n :local char [:pick \$macaddress \$i]\
\n :if (\$char = \":\") do={\
\n :set \$char \"\"\
\n }\
\n :set tidymac (\$tidymac . \$char) \
\n}\
\n:put \$tidymac; /tr069-client set acs-url=http://192.168.10.10/tr069 enabled=yes password=xaps periodic-inform-enabled=yes periodic-inform-interval=30s username=\$tidymac"

[admin@MikroTik] /system scheduler
add name=UnitID on-event=identity policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-time=startup

[admin@MikroTik] /system scheduler
add interval=5s name=Poll on-event=Inter start-time=startup

[admin@MikroTik] reboot
```

When the Mikrotek comes back up, it will then start checking in with freeacs.example.com

#### Managing Routers

Login to FreeACS, click support > search amd click the search button.

The Mikrotek will show up with the MAC Address as the unit ID. The device can be managed via TR-069.

Create profiles by clicking Easy provisioning > profile for customer configs using TR-069 parameters. Profiles can be pushed to the CPE by clicking Support > search > Unit Configuration

#### Running Router OS Scripts

##### Via the RouterOS CLI

This can be done by creating the desired configuration via the routerOS CLI, then exporting to a text file named, for example, ABCD-E12F.alter. Then upload the file via Files & Scripts in FreeACS, upload and save the file using the TR-069_Script as the file type.

##### From Advanced Provisioning

Go to advanced provisioning > Job > Create New Job

Type: TR069 Script
Group: All profiles (or create a customer group via advanced provisioning group)
Script: (the script you just uploaded)

##### Via Direct Push

Click Advanced provisioning > Job > Job overview, select the newly created job and click start, this will now push the RouterOS CLI to your Mikrotek

### Wrap-up

A final suggestion from me, as with all thse sortso f security VMs, be they form @vulnhub or @HTB or wherever, set the disk to non-persistent so yo can knock them down over and over again...

On that note, my thanks to Darren Martyn for an interesting talk, as well as Mikrotik for giving dmeo licenses at no cost, and all the community out there hacking, breaking and security things.
