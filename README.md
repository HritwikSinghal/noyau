<p align="center">
    <img width="64" height="64" src="data/images/noyau.png">
</p>

<h1 align="center">
    <b>Noyau</b>
</h1>

<p align="center">
    A graphical utility for managing kernels on Ubuntu-based platforms.
</p>

<br />

<p align="center">
    <img width="720" height="570" src="data/screenshots/main-ubuntu.png">
</p>

<br />

[![CodeFactor](https://www.codefactor.io/repository/github/joshuadowding/noyau/badge)](https://www.codefactor.io/repository/github/joshuadowding/noyau)


<h2>Features</h2>
<ul>
    <li>Download and install kernel packages automatically.</li>
    <li>Purge all installed kernels except the running kernel.</li>
    <li>View kernel release changelogs with your default text editor.</li>
</ul>


<h2>Changes Since 18.9.1</h2>
<h3>19.10</h3>
<ul>
    <li>Refreshed user interface using the Gtk.HeaderBar.</li>
    <li>Transitioned to the meson build system.</li>
    <li>Merge the GUI and CLI program entry-points into one unified entry-point.</li>
    <li>Download over HTTPS instead of plain HTTP.</li>
    <li>Split toggles for displaying kernels older than 4.x and 5.x.</li>
    <li>Removed intrusive prompts and donation links.</li>
    <li>Removed scripted notifications.</li>
    <li>Serious code refactoring and clean-up.</li>
    <li>Fixed numerous build issues.</li>
</ul>


<h2>Confirmed Compatibility</h2>
<ul>
    <li>Ubuntu 20.04.x LTS</li>
    <li>Ubuntu 19.10</li>
    <li>Ubuntu 19.04</li>
    <li>Ubuntu 18.04.x LTS (inc. elementary OS 5.x)</li>
</ul>

<h2>Confirmed Incompatibility</h2>
<ul>
    <li>Ubuntu 16.04.x LTS</li>
</ul>


<h2>Source Code</h2>
<h3>Build Instructions</h3>

    sudo apt install valac meson libgtk-3-dev libgee-0.8-dev libjson-glib-dev libvte-2.91-dev libsoup2.4-dev
    git clone https://github.com/joshuadowding/noyau.git && cd noyau
    meson build --prefix=/usr
    cd build && ninja
    sudo ninja install

<h3>Packaging Dependencies</h3>

    sudo apt install pbuilder debootstrap devscripts debhelper dh-make autotools-dev

<h3>Runtime Dependencies</h3>

    sudo apt install rsync aria2 aptitude curl

