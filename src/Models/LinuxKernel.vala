/*
 * LinuxKernel.vala
 *
 * Copyright 2015-2019 Tony George <teejee2008@gmail.com>
 * Copyright 2019-2020 Joshua Dowding <joshuadowding@outlook.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 */

using Gee;
using GLib;

public class LinuxKernel : GLib.Object, Gee.Comparable<LinuxKernel> {
    public string name = "";
    public string version = "";
    public string version_main = "";
    public string version_extra = "";
    public string version_package = "";
    public string type = "";
    public string page_uri = "";

    public int version_maj = -1;
    public int version_min = -1;
    public int version_point = -1;

    public Gee.HashMap<string, string> deb_list = new Gee.HashMap<string, string>();
    public Gee.HashMap<string, string> apt_pkg_list = new Gee.HashMap<string, string>();

    public static Gee.HashMap<string, Package> pkg_list_installed;

    public bool is_installed = false;
    public bool is_running = false;
    public bool is_mainline = false;
    public bool is_mainline_package = false; // TODO: remove this

    public string deb_header = "";
    public string deb_header_all = "";
    public string deb_image = "";
    public string deb_image_extra = "";
    public string deb_modules = "";

    // static

    public static string URI_KERNEL_UBUNTU_MAINLINE = "https://kernel.ubuntu.com/~kernel-ppa/mainline/";
    public static string CACHE_DIR = "/var/cache/ukuu";
    public static string NATIVE_ARCH;
    public static string LINUX_DISTRO;
    public static string RUNNING_KERNEL;
    public static string CURRENT_USER;
    public static string CURRENT_USER_HOME;

    public static bool hide_older;
    public static bool hide_unstable;

    public static int grub_timeout;
    public static bool update_grub_timeout;

    public static LinuxKernel kernel_active;
    public static LinuxKernel kernel_update_major;
    public static LinuxKernel kernel_update_minor;
    public static LinuxKernel kernel_latest_stable;

    public static Gee.ArrayList<LinuxKernel> kernel_list = new Gee.ArrayList<LinuxKernel>();

    public static Regex rex_header = null;
    public static Regex rex_header_all = null;
    public static Regex rex_image = null;
    public static Regex rex_image_extra = null;
    public static Regex rex_modules = null;

    // global progress  ------------
    public static string status_line;
    public static int64 progress_total;
    public static int64 progress_count;
    public static bool cancelled;
    public static bool task_is_running;
    public static bool _temp_refresh;

    private LoggingHelper logging_helper;
    private ProcessHelper process_helper;
    private SystemHelper system_helper;
    private FileHelper file_helper;
    private MiscHelper misc_helper;

    // class initialize

    public static void initialize () {
        new LinuxKernel ("", false); // instance must be created before setting static members

        LINUX_DISTRO = check_distribution ();
        NATIVE_ARCH = check_package_architecture ();
        RUNNING_KERNEL = check_running_kernel ();
        initialize_regex ();
    }

    // dep: lsb_release
    public static string check_distribution () {
        LoggingHelper _logging_helper = new LoggingHelper ();
        ProcessHelper _process_helper = new ProcessHelper ();
        string dist = "";

        string std_out, std_err;
        int status = _process_helper.exec_sync ("lsb_release -sd", out std_out, out std_err);
        if ((status == 0) && (std_out != null)) {
            dist = std_out.strip ();
            _logging_helper.log_msg (_("Distribution") + ": %s".printf (dist));
        }

        return dist;
    }

    // dep: dpkg
    public static string check_package_architecture () {
        LoggingHelper _logging_helper = new LoggingHelper ();
        ProcessHelper _process_helper = new ProcessHelper ();
        string arch = "";

        string std_out, std_err;
        int status = _process_helper.exec_sync ("dpkg --print-architecture", out std_out, out std_err);
        if ((status == 0) && (std_out != null)) {
            arch = std_out.strip ();
            _logging_helper.log_msg (_("Architecture") + ": %s".printf (arch));
        }

        return arch;
    }

    // dep: uname
    public static string check_running_kernel () {
        LoggingHelper _logging_helper = new LoggingHelper ();
        ProcessHelper _process_helper = new ProcessHelper ();
        MiscHelper _misc_helper = new MiscHelper ();

        string ver = "";
        string std_out;
        _process_helper.exec_sync ("uname -r", out std_out, null);
        _logging_helper.log_debug (std_out);

        ver = std_out.strip ().replace ("\n", "");
        _logging_helper.log_msg ("Running kernel" + ": %s".printf (ver));

        _process_helper.exec_sync ("uname -a", out std_out, null);
        _logging_helper.log_debug (std_out);

        string[] arr = std_out.split (ver);
        if (arr.length > 0) {
            string[] parts = arr[1].strip ().split_set (" -_~");
            string partnum = parts[0].strip ();
            if (partnum.has_prefix ("#")) {
                partnum = partnum[1 : partnum.length];
                if (_misc_helper.is_numeric (partnum) && (partnum.length <= 3)) {
                    var kern = new LinuxKernel.from_version (ver);
                    ver = "%s.%s".printf (kern.version_main, partnum);
                }
            }
        }

        _logging_helper.log_msg ("Kernel version" + ": %s".printf (ver));

        return ver;
    }

    public static void initialize_regex () {
        LoggingHelper _logging_helper = new LoggingHelper ();

        try {
            // linux-headers-3.4.75-030475-generic_3.4.75-030475.201312201255_amd64.deb
            rex_header = new Regex ("""linux-headers-[a-zA-Z0-9.\-_]*generic_[a-zA-Z0-9.\-]*_""" + NATIVE_ARCH + ".deb");

            // linux-headers-3.4.75-030475_3.4.75-030475.201312201255_all.deb
            rex_header_all = new Regex ("""linux-headers-[a-zA-Z0-9.\-_]*_all.deb""");

            // linux-image-3.4.75-030475-generic_3.4.75-030475.201312201255_amd64.deb
            rex_image = new Regex ("""linux-image-[a-zA-Z0-9.\-_]*generic_([a-zA-Z0-9.\-]*)_""" + NATIVE_ARCH + ".deb");

            // linux-image-extra-3.4.75-030475-generic_3.4.75-030475.201312201255_amd64.deb
            rex_image_extra = new Regex ("""linux-image-extra-[a-zA-Z0-9.\-_]*generic_[a-zA-Z0-9.\-]*_""" + NATIVE_ARCH + ".deb");

            // linux-image-extra-3.4.75-030475-generic_3.4.75-030475.201312201255_amd64.deb
            rex_modules = new Regex ("""linux-modules-[a-zA-Z0-9.\-_]*generic_[a-zA-Z0-9.\-]*_""" + NATIVE_ARCH + ".deb");
        } catch (Error e) {
            _logging_helper.log_error (e.message);
        }
    }

    public static bool check_if_initialized () {
        LoggingHelper _logging_helper = new LoggingHelper ();
        bool ok = (NATIVE_ARCH.length > 0);
        if (!ok) {
            _logging_helper.log_error ("LinuxKernel: Class should be initialized before use!");
            exit (1);
        }
        return ok;
    }

    public static void clean_cache () {
        LoggingHelper _logging_helper = new LoggingHelper ();
        FileHelper _file_helper = new FileHelper ();

        if (_file_helper.dir_exists (CACHE_DIR)) {
            bool ok = _file_helper.dir_delete (CACHE_DIR);
            if (ok) {
                _logging_helper.log_msg ("Removed cached files in '%s'".printf (CACHE_DIR));
            }
        }
    }

    // contructor

    public LinuxKernel (string _name, bool _is_mainline) {
        process_helper = new ProcessHelper ();
        logging_helper = new LoggingHelper ();
        system_helper = new SystemHelper ();
        misc_helper = new MiscHelper ();
        file_helper = new FileHelper ();

        if (_name.has_suffix ("/")) {
            this.name = _name[0 : _name.length - 1];
        } else {
            this.name = _name;
        }

        // parse version string ---------

        version = this.name;

        // remove "v"
        if (version.has_prefix ("v")) {
            version = version[1 : version.length];
        }

        split_version_string (version, out version_main, out version_extra);

        // set page URI -----------

        page_uri = "%s%s".printf (URI_KERNEL_UBUNTU_MAINLINE, _name);

        is_mainline = _is_mainline;
    }

    public LinuxKernel.from_version (string _version) {
        process_helper = new ProcessHelper ();
        logging_helper = new LoggingHelper ();
        system_helper = new SystemHelper ();
        misc_helper = new MiscHelper ();
        file_helper = new FileHelper ();

        version = _version;
        name = "v" + version;
        split_version_string (version, out version_main, out version_extra);
        page_uri = "";
    }

    // static

    public static void query (bool wait) {
        LoggingHelper _logging_helper = new LoggingHelper ();
        SystemHelper _system_helper = new SystemHelper ();

        check_if_initialized ();

        try {
            task_is_running = true;
            cancelled = false;
            Thread.create<void>(query_thread, true);
        } catch (ThreadError e) {
            task_is_running = false;
            _logging_helper.log_error (e.message);
        }

        if (wait) {
            while (task_is_running) {
                _system_helper.sleep (500); // wait
            }
        }
    }

    private static void query_thread () {
        LoggingHelper _logging_helper = new LoggingHelper ();
        SystemHelper _system_helper = new SystemHelper ();
        FileHelper _file_helper = new FileHelper ();

        _logging_helper.log_debug ("query: hide_older: %s".printf (hide_older.to_string ()));
        _logging_helper.log_debug ("query: hide_unstable: %s".printf (hide_unstable.to_string ()));

        // DownloadManager.reset_counter();

        bool refresh = false;
        var one_hour_before = (new DateTime.now_local ()).add_hours (-1);
        if (last_refreshed_date.compare (one_hour_before) < 0) {
            refresh = true;
            _logging_helper.log_debug (_("Index is stale"));
        } else {
            _logging_helper.log_debug (_("Index is fresh"));
        }

        bool is_connected = _system_helper.check_internet_connectivity ();

        if (refresh) {
            download_index ();
        }

        load_index ();

        // TODO: Implement locking for multiple download threads

        var kern_4 = new LinuxKernel.from_version ("4.0");

        status_line = "";
        progress_total = 0;
        progress_count = 0;
        foreach (var kern in kernel_list) {
            if (hide_older && (kern.compare_to (kern_4) < 0)) {
                continue;
            }

            if (hide_unstable && kern.is_unstable) {
                continue;
            }

            if (kern.is_valid && !kern.cached_page_exists) {
                progress_total += 2;
            }
        }


        var downloads = new Gee.ArrayList<DownloadItem>();
        var kernels_to_update = new Gee.ArrayList<LinuxKernel>();

        foreach (var kern in kernel_list) {
            if (cancelled) {
                break;
            }

            if (kern.cached_page_exists) {
                // log_debug("cached page exists: %s".printf(kern.version_main));
                kern.load_cached_page ();
                continue;
            }

            if (!kern.is_valid) {
                // log_debug("invalid: %s".printf(kern.version_main));
                continue;
            }

            if (hide_older && (kern.compare_to (kern_4) < 0)) {
                // log_debug("older than 4.0: %s".printf(kern.version_main));
                continue;
            }

            if (hide_unstable && kern.is_unstable) {
                // log_debug("not stable: %s".printf(kern.version_main));
                continue;
            }

            if (!kern.cached_page_exists) {

                var item = new DownloadItem (
                    kern.cached_page_uri,
                    _file_helper.file_parent (kern.cached_page),
                    _file_helper.file_basename (kern.cached_page));

                downloads.add (item);

                item = new DownloadItem (
                    kern.changes_file_uri,
                    _file_helper.file_parent (kern.changes_file),
                    _file_helper.file_basename (kern.changes_file));

                downloads.add (item);
                kernels_to_update.add (kern);
            }
        }

        if ((downloads.size > 0) && is_connected) {
            var mgr = new DownloadHelper ();

            foreach (var item in downloads) {
                mgr.add_to_queue (item);
            }

            mgr.status_in_kb = true;
            mgr.prg_count_total = progress_total;
            mgr.execute ();

            MiscHelper.print_progress_bar_start (_("Fetching index..."));

            while (mgr.is_running ()) {
                progress_count = mgr.prg_count;
                MiscHelper.print_progress_bar ((progress_count * 1.0) / progress_total);
                _system_helper.sleep (300);
            }

            MiscHelper.print_progress_bar_finish ();

            foreach (var kern in kernels_to_update) {
                kern.load_cached_page ();
            }
        }

        check_installed ();
        check_updates ();
        // check_available();

        task_is_running = false;
    }

    private static bool download_index () {
        LoggingHelper _logging_helper = new LoggingHelper ();
        SystemHelper _system_helper = new SystemHelper ();
        FileHelper _file_helper = new FileHelper ();

        check_if_initialized ();

        // fetch index.html --------------------------------------

        _file_helper.dir_create (_file_helper.file_parent (index_page));

        if (_file_helper.file_exists (index_page)) {
            _file_helper.file_delete (index_page);
        }

        var item = new DownloadItem (URI_KERNEL_UBUNTU_MAINLINE, CACHE_DIR, "index.html");
        var mgr = new DownloadHelper ();
        mgr.add_to_queue (item);
        mgr.status_in_kb = true;
        mgr.execute ();

        var msg = _("Fetching index from kernel.ubuntu.com...");
        _logging_helper.log_msg (msg);
        status_line = msg.strip ();

        while (mgr.is_running ()) {
            _system_helper.sleep (500);
        }

        // log_debug(index_page);

        if (_file_helper.file_exists (index_page)) {
            _logging_helper.log_msg ("OK");
            return true;
        } else {
            _logging_helper.log_error ("ERR");
            return false;
        }
    }

    private static void load_index () {
        LoggingHelper _logging_helper = new LoggingHelper ();
        FileHelper _file_helper = new FileHelper ();

        var list = new Gee.ArrayList<LinuxKernel>();

        if (!_file_helper.file_exists (index_page)) {
            return;
        }

        string txt = _file_helper.file_read (index_page);

        // parse index.html --------------------------

        try {
            // <a href="v3.0.16-oneiric/">v3.0.16-oneiric/</a>
            var rex = new Regex ("""<a href="([a-zA-Z0-9\-._\/]+)">([a-zA-Z0-9\-._]+)[\/]*<\/a>""");

            MatchInfo match;

            foreach (string line in txt.split ("\n")) {
                if (rex.match (line, 0, out match)) {
                    if (!match.fetch (2).has_prefix ("v")) {
                        continue;
                    }

                    var kern = new LinuxKernel (match.fetch (1), true);
                    list.add (kern);
                }
            }

            list.sort ((a, b) => {
                return a.compare_to (b) * -1;
            });
        } catch (Error e) {
            _logging_helper.log_error (e.message);
        }

        kernel_list = list;
    }

    public static void check_installed () {
        LoggingHelper _logging_helper = new LoggingHelper ();
        _logging_helper.log_debug ("check_installed");

        _logging_helper.log_msg (string.nfill (70, '-'));

        foreach (var kern in kernel_list) {
            kern.is_installed = false;
            kern.is_running = false;
        }

        pkg_list_installed = Package.query_installed_packages ();

        var pkg_versions = new Gee.ArrayList<string>();

        foreach (var pkg in pkg_list_installed.values) {
            if (pkg.name.contains ("linux-image")) {
                if (!pkg_versions.contains (pkg.version_installed)) {

                    pkg_versions.add (pkg.version_installed);
                    _logging_helper.log_msg ("Found installed" + ": %s".printf (pkg.version_installed));

                    string kern_name = "v%s".printf (pkg.version_installed);
                    var kern = new LinuxKernel (kern_name, false);
                    kern.is_installed = true;
                    kern.set_apt_pkg_list ();

                    if (kern.is_mainline_package) {
                        continue;
                    }

                    bool found = false;
                    foreach (var kernel in kernel_list) {
                        if (kernel.version_main == kern.version_main) {
                            found = true;
                            kernel.apt_pkg_list = kern.apt_pkg_list;
                            break;
                        }
                    }

                    if (!found) {
                        kernel_list.add (kern);
                    }
                }
            }
        }

        foreach (string pkg_version in pkg_versions) {
            foreach (var kern in kernel_list) {
                if (kern.version_package == pkg_version) {
                    kern.is_installed = true;
                }
            }
        }

        // Find and tag the running kernel in list ------------------

        // Running: 4.2.7-040207-generic
        // Package: 4.2.7-040207.201512091533

        // Running: 4.4.0-28-generic
        // Package: 4.4.0-28.47

        string ver_running = RUNNING_KERNEL.replace ("-generic", "");
        var kern_running = new LinuxKernel.from_version (ver_running);
        kernel_active = null;

        foreach (var kern in kernel_list) {
            if (!kern.is_valid) {
                continue;
            }

            // check mainline kernels only
            if (!kern.is_mainline) {
                continue;
            }

            // compare version_package strings for mainline kernels
            if (kern.version_package.length > 0) {
                string ver_pkg_short = kern.version_package[0 : kern.version_package.last_index_of (".")];

                if (ver_pkg_short == ver_running) {
                    kern.is_running = true;
                    kern.is_installed = true;
                    kernel_active = kern;
                    break;
                }
            }
        }

        if (kernel_active == null) {
            foreach (var kern in kernel_list) {
                if (!kern.is_valid) {
                    continue;
                }

                // check ubuntu kernels only
                if (kern.is_mainline) {
                    continue;
                }

                if (kern_running.version_main == kern.version_main) {
                    kern.is_running = true;
                    kern.is_installed = true;
                    kernel_active = kern;
                    break;
                }
            }
        }

        kernel_list.sort ((a, b) => {
            return a.compare_to (b) * -1;
        });

        _logging_helper.log_msg (string.nfill (70, '-'));
    }

    public static void check_available () {
        LoggingHelper _logging_helper = new LoggingHelper ();
        _logging_helper.log_debug ("check_available");

        var list = Package.query_available_packages ("^linux-image");

        var pkg_versions = new Gee.ArrayList<string>();

        foreach (var pkg in list.values) {
            if (pkg.name.contains ("linux-image")) {
                if (!pkg_versions.contains (pkg.version_installed)) {

                    pkg_versions.add (pkg.version_installed);
                    _logging_helper.log_msg ("Found upgrade" + ": %s".printf (pkg.version_installed));

                    string kern_name = "v%s".printf (pkg.version_installed);
                    var kern = new LinuxKernel (kern_name, false);
                    kern.is_installed = false;

                    if (kern.is_mainline_package) {
                        continue;
                    }

                    bool found = false;
                    foreach (var kernel in kernel_list) {
                        if (kernel.version_main == kern.version_main) {
                            found = true;
                            break;
                        }
                    }

                    if (!found) {
                        kernel_list.add (kern);
                    }
                }
            }
        }

        kernel_list.sort ((a, b) => {
            return a.compare_to (b) * -1;
        });
    }

    public static void check_updates () {
        LoggingHelper _logging_helper = new LoggingHelper ();
        _logging_helper.log_debug ("check_updates");

        kernel_update_major = null;
        kernel_update_minor = null;
        kernel_latest_stable = null;

        var kern_running = new LinuxKernel.from_version (LinuxKernel.RUNNING_KERNEL);
        foreach (var kern in LinuxKernel.kernel_list) {
            // skip invalid
            if (!kern.is_valid) {
                continue;
            }

            // skip unstable
            if (hide_unstable && kern.is_unstable) {
                continue;
            }

            if (kernel_latest_stable == null) {
                kernel_latest_stable = kern;
                _logging_helper.log_debug ("latest stable kernel -> %s".printf (kern.version_main));
            }

            // skip installed
            if (kern.is_installed) {
                continue;
            }

            // log_msg("check: %s".printf(kern.version_main));

            bool major_available = false;
            bool minor_available = false;

            if (kern.version_maj > kern_running.version_maj) {
                major_available = true;
            } else if (kern.version_maj == kern_running.version_maj) {
                if (kern.version_min > kern_running.version_min) {
                    major_available = true;
                } else if (kern.version_min == kern_running.version_min) {
                    if (kern.version_point > kern_running.version_point) {
                        minor_available = true;
                    }
                }
            }

            if (major_available && (kernel_update_major == null)) {
                kernel_update_major = kern;
                _logging_helper.log_debug ("major update -> %s".printf (kern.version_main));
            }

            if (minor_available && (kernel_update_minor == null)) {
                kernel_update_minor = kern;
                _logging_helper.log_debug ("minor update -> %s".printf (kern.version_main));
            }

            if ((kernel_update_major != null)
                && (kernel_update_minor != null)
                && (kernel_latest_stable != null)) {

                break;
            }
        }
    }

    public static void purge_old_kernels (bool confirm) {
        LoggingHelper _logging_helper = new LoggingHelper ();
        check_installed ();

        var list = new Gee.ArrayList<LinuxKernel>();
        var kern_running = new LinuxKernel.from_version (LinuxKernel.RUNNING_KERNEL);
        bool found_running_kernel = false;

        foreach (var kern in LinuxKernel.kernel_list) {

            // skip invalid
            if (!kern.is_valid) {
                continue;
            }

            // skip not installed
            if (!kern.is_installed) {
                continue;
            }

            // skip running kernel
            if (kern.version_main == kern_running.version_main) {
                found_running_kernel = true;
                continue;
            }

            // skip newer kernels
            if (kern.compare_to (kern_running) > 0) {
                continue;
            }

            list.add (kern);
        }

        if (!found_running_kernel) {
            _logging_helper.log_error (_("Could not find running kernel in list!"));
            _logging_helper.log_msg (string.nfill (70, '-'));
            return;
        }

        if (list.size == 0) {
            _logging_helper.log_msg (_("Could not find any kernels to remove"));
            _logging_helper.log_msg (string.nfill (70, '-'));
            return;
        }

        // confirm -------------------------------

        if (confirm) {
            var message = "\n%s:\n".printf (_("Following kernels will be removed"));

            foreach (var kern in list) {
                message += " ▰ v%s\n".printf (kern.version_main);
            }

            message += "\n%s (y/n): ".printf (_("Continue ?"));

            stdout.printf (message);
            stdout.flush ();

            int ch = stdin.getc ();

            if (ch != 'y') {
                return;
            }
        }

        // remove --------------------------------

        foreach (var kern in list) {
            kern.remove (true);
        }
    }

    public static void install_latest (bool point_update, bool confirm) {
        LoggingHelper _logging_helper = new LoggingHelper ();
        query (true);

        check_updates ();

        var kern_major = LinuxKernel.kernel_update_major;

        if ((kern_major != null) && !point_update) {

            var message = "%s: %s".printf (_("Latest update"), kern_major.version_main);
            _logging_helper.log_msg (message);

            install_update (kern_major, confirm);
            return;
        }

        var kern_minor = LinuxKernel.kernel_update_minor;

        if (kern_minor != null) {

            var message = "%s: %s".printf (_("Latest point update"), kern_minor.version_main);
            _logging_helper.log_msg (message);

            install_update (kern_minor, confirm);
            return;
        }

        if ((kern_major == null) && (kern_minor == null)) {
            _logging_helper.log_msg (_("No updates found"));
        }

        _logging_helper.log_msg (string.nfill (70, '-'));
    }

    public static void install_update (LinuxKernel kern, bool confirm) {
        if (confirm) {

            var message = "\n" + _("Install Linux v%s ? (y/n): ").printf (kern.version_main);
            stdout.printf (message);
            stdout.flush ();

            int ch = stdin.getc ();

            if (ch != 'y') {
                return;
            }
        }

        kern.install (true);
    }

    // helpers

    public void split_version_string (string _version_string, out string ver_main, out string ver_extra) {
        ver_main = "";
        ver_extra = "";
        version_maj = 0;
        version_min = 0;
        version_point = 0;

        if (_version_string.length == 0) {
            return;
        }

        var version_string = _version_string.split ("~")[0];
        var match = misc_helper.regex_match ("""[v]*([0-9]+|r+c+)""", version_string);
        int index = -1;

        while (match != null) {
            string ? num = match.fetch (1);

            if (num != null) {
                index++;

                if (num == "rc") {
                    ver_main += ".0-rc";
                } else {

                    if (num.length <= 3) {
                        if ((ver_main.length > 0) && !ver_main.has_suffix ("rc")) {
                            ver_main += ".";
                        }

                        ver_main += num;
                    }

                    switch (index) {
                        case 0:
                            version_maj = int.parse (num);
                            break;
                        case 1:
                            version_min = int.parse (num);
                            break;
                        case 2:
                            version_point = int.parse (num);
                            break;
                    }

                    if (num.length >= 12) {
                        is_mainline = true;
                    }
                }
            }

            try {
                if (!match.next ()) {
                    break;
                }
            } catch (Error e) {
                break;
            }
        }

        // log_debug("split: %s, version_main: %s, maj/min/point: %d,%d,%d".printf(version_string, ver_main, version_maj, version_min, version_point));
    }

    public int compare_to (LinuxKernel b) {
        LinuxKernel a = this;
        string[] arr_a = a.version_main.split_set (".-_");
        string[] arr_b = b.version_main.split_set (".-_");

        int i = 0;
        int x, y;

        // while both arrays have an element
        while ((i < arr_a.length) && (i < arr_b.length)) {

            // continue if equal
            if (arr_a[i] == arr_b[i]) {
                i++;
                continue;
            }

            // check if number
            x = int.parse (arr_a[i]);
            y = int.parse (arr_b[i]);
            if ((x > 0) && (y > 0)) {
                // both are numbers
                return (x - y);
            } else if ((x == 0) && (y == 0)) {
                // both are strings
                return strcmp (arr_a[i], arr_b[i]);
            } else {
                if (x > 0) {
                    return 1;
                } else {
                    return -1;
                }
            }
        }

        // one array has less parts than the other and all corresponding parts are equal

        if (i < arr_a.length) {
            x = int.parse (arr_a[i]);
            if (x > 0) {
                return 1;
            } else {
                return -1;
            }
        }

        if (i < arr_b.length) {
            y = int.parse (arr_b[i]);
            if (y > 0) {
                return -1;
            } else {
                return 1;
            }
        }

        return (arr_a.length - arr_b.length) * -1; // smaller array is larger version
    }

    public void mark_invalid () {
        string file = "%s/invalid".printf (cache_subdir);
        if (!file_helper.file_exists (file)) {
            file_helper.file_write (file, "1");
        }
    }

    public void set_apt_pkg_list () {
        foreach (var pkg in pkg_list_installed.values) {
            if (!pkg.name.has_prefix ("linux-")) {
                continue;
            }
            if (pkg.version_installed == version) {
                apt_pkg_list[pkg.name] = pkg.name;
                logging_helper.log_debug ("Package: %s".printf (pkg.name));
            }
        }
    }

    // properties

    public bool is_rc {
        get {
            return version.contains ("-rc");
        }
    }

    public bool is_unstable {
        get {
            return version.contains ("-rc") || version.contains ("-unstable");
        }
    }

    public bool is_valid {
        get {
            return !file_helper.file_exists ("%s/invalid".printf (cache_subdir));
        }
    }

    public static string index_page{
        owned get {
            return "%s/index.html".printf (CACHE_DIR);
        }
    }

    public static DateTime last_refreshed_date{
        owned get {
            FileHelper _file_helper = new FileHelper ();

            if (_file_helper.file_get_size (index_page) < 300000) {
                return (new DateTime.now_local ()).add_years (-1);
            } else {
                return _file_helper.file_get_modified_date (index_page);
            }
        }
    }

    public string cache_subdir{
        owned get {
            return "%s/%s".printf (CACHE_DIR, name);
        }
    }

    public string cached_page{
        owned get {
            return "%s/index.html".printf (cache_subdir);
        }
    }

    public string cached_page_uri{
        owned get {
            return page_uri;
        }
    }

    public string changes_file{
        owned get {
            return "%s/CHANGES".printf (cache_subdir);
        }
    }

    public string changes_file_uri{
        owned get {
            return "%s%s".printf (page_uri, "CHANGES");
        }
    }

    public bool cached_page_exists {
        get {
            return file_helper.file_exists (cached_page);
        }
    }

    public string major_version{
        owned get {
            string[] parts = version_main.split (".");
            if (parts.length >= 2) {
                return "%s.%s".printf (parts[0], parts[1]);
            }
            return version_main;
        }
    }

    public string minor_version{
        owned get {
            string[] parts = version_main.split (".");
            if (parts.length >= 3) {
                return "%s.%s.%s".printf (parts[0], parts[1], parts[2]);
            }
            return version_main;
        }
    }

    public string tooltip_text () {
        string txt = "";

        string list = "";
        foreach (string deb in deb_list.keys) {
            list += "\n%s".printf (deb);
        }
        if (list.length > 0) {
            txt += "<b>%s</b>\n%s".printf (_("Packages Available (DEB)"), list);
        }

        list = "";
        foreach (string deb in apt_pkg_list.keys) {
            list += "\n%s".printf (deb);
        }
        if (list.length > 0) {
            txt += "<b>%s</b>\n%s".printf (_("Packages Installed"), list);
        }

        return txt;
    }

    // load

    private void load_cached_page () {
        var list = new Gee.HashMap<string, string>();

        if (!file_helper.file_exists (cached_page)) {
            // log_error("load_cached_page: " + _("File not found") + ": %s".printf(cached_page));
            return;
        }

        string txt = file_helper.file_read (cached_page);

        // parse index.html --------------------------

        try {
            // <a href="linux-headers-4.6.0-040600rc1-generic_4.6.0-040600rc1.201603261930_amd64.deb">//same deb name//</a>
            var rex = new Regex ("""<a href="([a-zA-Z0-9\-._]+)">([a-zA-Z0-9\-._]+)<\/a>""");
            MatchInfo match;

            foreach (string line in txt.split ("\n")) {
                if (rex.match (line, 0, out match)) {
                    string file_name = match.fetch (2);
                    string file_uri = "%s%s".printf (page_uri, match.fetch (1));

                    bool add = false;

                    if (rex_header.match (file_name, 0, out match)) {
                        deb_header = file_name;
                        add = true;
                    }

                    if (rex_header_all.match (file_name, 0, out match)) {
                        deb_header_all = file_name;
                        add = true;
                    }

                    if (rex_image.match (file_name, 0, out match)) {
                        deb_image = file_name;
                        add = true;

                        version_package = match.fetch (1);
                    }

                    if (rex_image_extra.match (file_name, 0, out match)) {
                        deb_image_extra = file_name;
                        add = true;
                    }

                    if (rex_modules.match (file_name, 0, out match)) {
                        deb_modules = file_name;
                        add = true;
                    }

                    if (add) {
                        list[file_name] = file_uri; // add to list
                    }
                }
            }

            if ((deb_header.length == 0) || (deb_header_all.length == 0) || (deb_image.length == 0)) {
                mark_invalid ();
            }
        } catch (Error e) {
            logging_helper.log_error (e.message);
        }


        deb_list = list;
    }

    // actions

    public static void print_list () {
        LoggingHelper _logging_helper = new LoggingHelper ();

        _logging_helper.log_msg ("");
        _logging_helper.log_draw_line ();
        _logging_helper.log_msg (_("Available Kernels"));
        _logging_helper.log_draw_line ();

        var kern_4 = new LinuxKernel.from_version ("4.0");
        foreach (var kern in kernel_list) {
            if (!kern.is_valid) {
                continue;
            }
            if (hide_unstable && kern.is_unstable) {
                continue;
            }
            if (hide_older && (kern.compare_to (kern_4) < 0)) {
                continue;
            }

            var extra = kern.version_extra;
            extra = extra.has_prefix ("-") ? extra[1 : extra.length] : extra;
            var desc = kern.is_running ? _("Running") : (kern.is_installed ? _("Installed") : "");

            _logging_helper.log_msg ("%-30s %-25s %s".printf (kern.name, kern.version_main, desc));
        }
    }

    public static bool download_kernels (Gee.ArrayList<LinuxKernel> selected_kernels) {
        foreach (var kern in selected_kernels) {
            kern.download_packages ();
        }
        return true;
    }

    // dep: aria2c
    public bool download_packages () {
        bool ok = true;

        check_if_initialized ();

        foreach (string file_name in deb_list.keys) {

            string file_path = "%s/%s/%s".printf (cache_subdir, NATIVE_ARCH, file_name);

            if (file_helper.file_exists (file_path) && !file_helper.file_exists (file_path + ".aria2c")) {
                continue;
            }

            file_helper.dir_create (file_helper.file_parent (file_path));

            stdout.printf ("\n" + _("Downloading") + ": '%s'... \n".printf (file_name));
            stdout.flush ();

            var item = new DownloadItem (deb_list[file_name], file_helper.file_parent (file_path), file_helper.file_basename (file_path));
            var mgr = new DownloadHelper ();
            mgr.add_to_queue (item);
            mgr.status_in_kb = true;
            mgr.execute ();

            while (mgr.is_running ()) {
                system_helper.sleep (200);

                stdout.printf ("\r%-60s".printf (mgr.status_line.replace ("\n", "")));
                stdout.flush ();
            }

            if (file_helper.file_exists (file_path)) {
                stdout.printf ("\r%-70s\n".printf (_("OK")));
                stdout.flush ();

                if (system_helper.get_user_id_effective () == 0) {
                    file_helper.chown (file_path, CURRENT_USER, CURRENT_USER);
                    file_helper.chmod (file_path, "a+rw");
                }
            } else {
                stdout.printf ("\r%-70s\n".printf (_("ERROR")));
                stdout.flush ();
                ok = false;
            }
        }

        return ok;
    }

    // dep: dpkg
    public bool install (bool write_to_terminal) {

        // check if installed
        if (is_installed) {
            logging_helper.log_error (_("This kernel is already installed."));
            return false;
        }

        bool ok = download_packages ();
        int status = -1;

        if (ok) {
            logging_helper.log_msg ("Preparing to install '%s'".printf (name));

            var cmd = "cd '%s/%s' && dpkg -i ".printf (cache_subdir, NATIVE_ARCH);

            foreach (string file_name in deb_list.keys) {
                cmd += "'%s' ".printf (file_name);
            }

            if (write_to_terminal) {
                logging_helper.log_msg ("");
                status = Posix.system (cmd); // execute
                logging_helper.log_msg ("");
            } else {
                status = process_helper.exec_script_sync (cmd); // execute
            }

            ok = (status == 0);

            update_grub_menu ();

            if (ok) {
                logging_helper.log_msg (_("Installation completed. A reboot is required to use the new kernel."));
            } else {
                logging_helper.log_error (_("Installation completed with errors"));
            }
        }

        return ok;
    }

    // dep: dpkg
    public static bool remove_kernels (Gee.ArrayList<LinuxKernel> selected_kernels) {
        LoggingHelper _logging_helper = new LoggingHelper ();

        bool ok = true;
        int status = -1;

        // check if running

        foreach (var kern in selected_kernels) {
            if (kern.is_running) {
                _logging_helper.log_error (_("Selected kernel is currently running and cannot be removed.\n Install another kernel before removing this one."));
                return false;
            }
        }

        _logging_helper.log_msg (_("Preparing to remove selected kernels"));

        var cmd = "dpkg -r ";

        foreach (var kern in selected_kernels) {

            if (kern.apt_pkg_list.size > 0) {
                foreach (var pkg_name in kern.apt_pkg_list.values) {
                    if (!pkg_name.has_prefix ("linux-tools")
                        && !pkg_name.has_prefix ("linux-libc")) {

                        cmd += "'%s' ".printf (pkg_name);
                    }
                }
            } else if (kern.deb_list.size > 0) {
                // get package names from deb file names
                foreach (string file_name in kern.deb_list.keys) {
                    cmd += "'%s' ".printf (file_name.split ("_")[0]);
                }
            } else {
                stdout.printf ("");
                _logging_helper.log_error ("Could not find the packages to remove!");
                return false;
            }
        }

        _logging_helper.log_msg ("");
        status = Posix.system (cmd); // execute
        _logging_helper.log_msg ("");

        ok = (status == 0);

        update_grub_menu ();

        if (ok) {
            _logging_helper.log_msg (_("Un-install completed"));
        } else {
            _logging_helper.log_error (_("Un-install completed with errors"));
        }

        return ok;
    }

    // dep: dpkg
    public bool remove (bool write_to_terminal) {
        bool ok = true;
        int status = -1;

        // check if running
        if (is_running) {
            logging_helper.log_error (_("This kernel is currently running and cannot be removed.\n Install another kernel before removing this one."));
            return false;
        }

        logging_helper.log_msg ("Preparing to remove '%s'".printf (name));

        var cmd = "dpkg -r ";

        if (apt_pkg_list.size > 0) {
            foreach (var pkg_name in apt_pkg_list.values) {
                if (!pkg_name.has_prefix ("linux-tools")
                    && !pkg_name.has_prefix ("linux-libc")) {

                    cmd += "'%s' ".printf (pkg_name);
                }
            }
        } else if (deb_list.size > 0) {
            // get package names from deb file names
            foreach (string file_name in deb_list.keys) {
                cmd += "'%s' ".printf (file_name.split ("_")[0]);
            }
        } else {
            stdout.printf ("");
            logging_helper.log_error ("Could not find the packages to remove!");
            return false;
        }

        if (write_to_terminal) {
            logging_helper.log_msg ("");
            status = Posix.system (cmd); // execute
            logging_helper.log_msg ("");
        } else {
            status = process_helper.exec_script_sync (cmd); // execute
        }
        ok = (status == 0);

        update_grub_menu ();

        if (ok) {
            logging_helper.log_msg (_("Un-install completed"));
        } else {
            logging_helper.log_error (_("Un-install completed with errors"));
        }

        return ok;
    }

    // dep: update-grub
    public static bool update_grub_menu () {
        FileHelper _file_helper = new FileHelper ();
        LoggingHelper _logging_helper = new LoggingHelper ();

        string grub_file = "/etc/default/grub";
        if (!_file_helper.file_exists (grub_file)) {
            return false;
        }

        string txt = "";
        bool file_changed = false;
        bool grub_timeout_found = false;

        foreach (var line in _file_helper.file_read (grub_file).split ("\n")) {

            if (line.up ().contains ("GRUB_HIDDEN_TIMEOUT=") && !line.strip ().has_prefix ("#")) {
                // comment the line
                txt += "#%s\n".printf (line);
                file_changed = true;
            } else if (line.up ().contains ("GRUB_TIMEOUT=")) {
                int64 seconds = 0;

                if (int64.try_parse (line.split ("=")[1], out seconds)) {
                    // value can be 0, > 0 or -1 (indefinite wait)
                    if (seconds == grub_timeout) {
                        txt += "%s\n".printf (line);
                    } else {
                        txt += "%s=%d\n".printf ("GRUB_TIMEOUT", grub_timeout);
                        file_changed = true;
                    }
                } else {
                    txt += "%s=%d\n".printf ("GRUB_TIMEOUT", grub_timeout);
                    file_changed = true;
                }
                grub_timeout_found = true;
            } else if (line.up ().contains ("GRUB_TIMEOUT_STYLE=") && !line.strip ().has_prefix ("#")) {
                // comment the line; same as setting value to 'menu'
                txt += "#%s\n".printf (line);
                file_changed = true;
            } else if (line.up ().contains ("GRUB_HIDDEN_TIMEOUT_QUIET=") && !line.strip ().has_prefix ("#")) {
                // comment the line; deprecated option
                txt += "#%s\n".printf (line);
                file_changed = true;
            } else {
                txt += "%s\n".printf (line);
            }
        }

        if (!grub_timeout_found) {
            txt += "%s=%d\n".printf ("GRUB_TIMEOUT", grub_timeout);
            file_changed = true;
        }

        if (file_changed && update_grub_timeout) {
            _file_helper.file_write (grub_file, txt);
        }

        _logging_helper.log_msg (_("Updating GRUB menu"));

        string cmd = "update-grub";
        Posix.system (cmd);

        return true;
    }
}

