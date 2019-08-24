### Ubuntu Kernel Update Utility (Ukuu)
A graphical utility for managing kernels on Ubuntu.

### Features

*   Fetches list of kernels from [kernel.ubuntu.com](http://kernel.ubuntu.com/~kernel-ppa/mainline/)
*   Displays notifications when a new kernel update is available.
*   Downloads and installs packages automatically

### Screenshot
#### Ubuntu (Yaru)
![screenshot-2](https://raw.githubusercontent.com/joshuadowding/ukuu/master/src/share/ukuu/screenshots/main-ubuntu-1.png)

#### GNOME (Adwaita)
![screenshot-1](https://raw.githubusercontent.com/joshuadowding/ukuu/master/src/share/ukuu/screenshots/main-gnome-1.png)


### Installation

#### Ubuntu-based Distributions (Ubuntu, Linux Mint, Elementary, etc)
Packages are available in Launchpad PPA for supported Ubuntu releases.

    sudo apt-add-repository ppa:teejee2008/ppa
    sudo apt-get update
    sudo apt-get install ukuu

Ukuu should not be used on older Ubuntu systems as upgrading to very new kernels can break older systems.


#### Debian & Other Linux Distributions
This application fetches kernels from [kernel.ubuntu.com](http://kernel.ubuntu.com/~kernel-ppa/mainline/) which are provided by Canonical and meant for installation on Ubuntu-based distributions. These should not be used on Debian and other non-Ubuntu distributions such as Arch Linux, Fedora, etc.


### Downloads & Source Code 
Ukuu is written using Vala and GTK3 toolkit. Source code and binaries are available from the [GitHub project page](https://github.com/joshuadowding/ukuu.git).

### Build Instructions

#### Ubuntu-based Distributions (Ubuntu, Linux Mint, Elementary, etc.)

    sudo apt-get install libgee-0.8-dev libjson-glib-dev libvte-2.91-dev valac aria2 aptitude curl
    git clone https://github.com/joshuadowding/ukuu.git
    cd ukuu
    make all
    sudo make install

