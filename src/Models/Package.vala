/*
 * Package.vala
 *
 * Copyright 2012-2019 Tony George <teejeetech@gmail.com>
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

using GLib;

public class Package : GLib.Object {

    public FileHelper file_utils;

    public string id = "";
    public string name = "";
    public string description = "";
    public string repo = "";
    public string arch = "";
    public string status = "";
    public string version = "";
    public string version_installed = "";

    public bool is_installed = false;
    public bool is_automatic = false;

    public static string NATIVE_ARCH = "";

    private LoggingHelper logging_helper;
    private ProcessHelper process_helper;

    public Package (string _name) {
        name = _name;
        file_utils = new FileHelper ();
        process_helper = new ProcessHelper ();
        logging_helper = new LoggingHelper ();
    }

    public static void initialize () {
        ProcessHelper _process_helper = new ProcessHelper ();
        string std_out, std_err;
        int status = _process_helper.exec_sync ("dpkg --print-architecture", out std_out, out std_err);
        if ((status == 0) && (std_out != null)) {
            NATIVE_ARCH = std_out.strip ();
        }
    }

    public bool is_foreign () {
        if (check_if_foreign (arch)) {
            return true;
        } else {
            return false;
        }
    }

    public static string get_id (string _name, string _arch) {
        string str = "";
        str = "%s".printf (_name);
        if (check_if_foreign (_arch)) {
            str = str + ":%s".printf (_arch); // make it unique
        }
        return str;
    }

    public static bool check_if_foreign (string architecture) {
        if ((architecture.length > 0) && (architecture != NATIVE_ARCH) && (architecture != "all") && (architecture != "any")) {
            return true;
        } else {
            return false;
        }
    }

    public static Gee.HashMap<string, Package> query_installed_packages () {
        ProcessHelper _process_helper = new ProcessHelper ();
        LoggingHelper _logging_helper = new LoggingHelper ();
        FileHelper _file_utils = new FileHelper ();

        var list = new Gee.HashMap<string, Package>();
        string temp_file = _process_helper.get_temp_file_path ();

        // get installed packages from aptitude --------------

        string std_out, std_err;
        _process_helper.exec_sync ("aptitude search --disable-columns -F '%p|%v|%M|%d' '?installed'", out std_out, out std_err);
        _file_utils.file_write (temp_file, std_out);

        // parse ------------------------

        try {
            string line;
            var file = File.new_for_path (temp_file);
            if (file.query_exists ()) {
                var dis = new DataInputStream (file.read ());
                while ((line = dis.read_line (null)) != null) {
                    string[] arr = line.split ("|");
                    if (arr.length != 4) {
                        continue;
                    }

                    string name = arr[0].strip ();
                    string arch = (name.contains (":")) ? name.split (":")[1].strip () : "";
                    if (name.contains (":")) {
                        name = name.split (":")[0];
                    }
                    string version = arr[1].strip ();
                    string auto = arr[2].strip ();
                    string desc = arr[3].strip ();

                    string id = Package.get_id (name, arch);

                    Package pkg = null;
                    if (!list.has_key (id)) {
                        pkg = new Package (name);
                        pkg.arch = arch;
                        pkg.description = desc;
                        pkg.id = Package.get_id (pkg.name, pkg.arch);
                        list[pkg.id] = pkg;
                    }

                    if (pkg != null) {
                        pkg.is_installed = true;
                        pkg.is_automatic = (auto == "A");
                        pkg.version_installed = version;
                    }
                }
            } else {
                _logging_helper.log_error (_("File not found: %s").printf (temp_file));
            }
        } catch (Error e) {
            _logging_helper.log_error (e.message);
        }

        return list;
    }

    public static Gee.HashMap<string, Package> query_available_packages (string search_string) {
        ProcessHelper _process_helper = new ProcessHelper ();
        LoggingHelper _logging_helper = new LoggingHelper ();
        FileHelper _file_utils = new FileHelper ();

        var list = new Gee.HashMap<string, Package>();
        string temp_file = _process_helper.get_temp_file_path ();

        // get installed packages from aptitude --------------

        string std_out, std_err;
        string cmd = "aptitude search --disable-columns -F '%%p|%%v|%%M|%%d' '!installed ?architecture(native) %s'".printf (search_string);
        _process_helper.exec_sync (cmd, out std_out, out std_err);
        _file_utils.file_write (temp_file, std_out);

        // parse ------------------------

        try {
            string line;
            var file = File.new_for_path (temp_file);
            if (file.query_exists ()) {
                var dis = new DataInputStream (file.read ());
                while ((line = dis.read_line (null)) != null) {
                    string[] arr = line.split ("|");
                    if (arr.length != 4) {
                        continue;
                    }

                    string name = arr[0].strip ();
                    string arch = (name.contains (":")) ? name.split (":")[1].strip () : "";
                    if (name.contains (":")) {
                        name = name.split (":")[0];
                    }
                    string version = arr[1].strip ();
                    string auto = arr[2].strip ();
                    string desc = arr[3].strip ();

                    string id = Package.get_id (name, arch);

                    Package pkg = null;
                    if (!list.has_key (id)) {
                        pkg = new Package (name);
                        pkg.arch = arch;
                        pkg.description = desc;
                        pkg.id = Package.get_id (pkg.name, pkg.arch);
                        list[pkg.id] = pkg;
                    }

                    if (pkg != null) {
                        pkg.is_installed = true;
                        pkg.is_automatic = (auto == "A");
                        pkg.version_installed = version;
                    }
                }
            } else {
                _logging_helper.log_error (_("File not found: %s").printf (temp_file));
            }
        } catch (Error e) {
            _logging_helper.log_error (e.message);
        }

        return list;
    }
}
