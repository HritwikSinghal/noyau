/*
 * App.vala
 *
 * Copyright 2012-2019 Tony George <teejee2008@gmail.com>
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

using Gtk;
using Gee;
using GLib;
using Json;

extern void exit (int exit_code);

public class App : Gtk.Application {

    public const string APP_NAME = @"Ubuntu Kernel Update Utility";
    public const string APP_NAME_SHORT = @"ukuu";
    public const string APP_VERSION = @"18.10";
    public const string APP_AUTHOR = @"Joshua Dowding";
    public const string APP_AUTHOR_EMAIL = @"joshuadowding@outlook.com";
    public const string APP_AUTHOR_WEBSITE = @"https://joshuadowding.github.io";

    public const string GETTEXT_PACKAGE = @"";
    public const string LOCALE_DIR = @"/usr/share/locale";

    public static string APP_CONFIG_FILE = "";

    public static bool LOG_DEBUG = false;
    public static bool LOG_TIMESTAMP = false;
    public static bool NO_GUI = false;

    public static GLib.List<string> commands;
    public static string command_versions;

    public static bool notify_major = true;
    public static bool notify_minor = true;
    public static bool notify_bubble = true;
    public static bool notify_dialog = true;
    public static int notify_interval_unit = 0;
    public static int notify_interval_value = 2;
    public static bool message_shown = false;
    public static string user_login = "";
    public static string status_line = "";
    public static int64 progress_total = 0;
    public static int64 progress_count = 0;
    public static bool cancelled = false;
    public static string requested_version = "";

    private GtkHelper gtk_helper;
    private JsonHelper json_helper;
    private SystemHelper system_helper;
    private LoggingHelper logging_helper;
    private ProcessHelper process_helper;

    public App () {
        GLib.Object (
            application_id: "com.github.joshuadowding.ukuu",
            flags : ApplicationFlags.FLAGS_NONE
        );

        gtk_helper = new GtkHelper ();
        json_helper = new JsonHelper ();
        system_helper = new SystemHelper ();
        logging_helper = new LoggingHelper ();
        process_helper = new ProcessHelper ();

        check_if_admin ();

        Package.initialize ();
        LinuxKernel.initialize ();

        init_paths ();
        load_app_config ();
        set_locale ();

        logging_helper.log_msg ("%s v%s".printf (App.APP_NAME_SHORT, App.APP_VERSION));
        process_helper.init_tmp ("ukuu");

        string message;
        if (!check_dependencies (out message)) {
            gtk_helper.gtk_messagebox ("ukuu", message, null, true);
            exit_app (1);
        }
    }

    protected override void activate () {
        if (NO_GUI == false) {
            var window = new MainWindow ();

            window.destroy.connect (() => {
                logging_helper.log_debug ("MainWindow destroyed");
                LinuxKernel.clean_cache ();
                Gtk.main_quit ();
            });

            window.delete_event.connect ((event) => {
                logging_helper.log_debug ("MainWindow closed");
                LinuxKernel.clean_cache ();
                Gtk.main_quit ();
                return true;
            });

            window.show_all ();
            Gtk.main ();
        }

        save_app_config ();
    }

    public static int main (string[] args) {
        var app = new App ();

        if (parse_arguments (args)) {
            if (NO_GUI == false) {
                Gtk.init (ref args);
            }

            return app.run (args);
        } else {
            return 0;
        }
    }

    // helpers ------------

    private bool check_dependencies (out string msg) {
        string[] dependencies = { "aptitude", "apt-get", "aria2c", "dpkg", "uname", "lsb_release", "ping", "curl" };
        msg = "";
        string path;

        foreach (string cmd_tool in dependencies) {
            path = process_helper.get_cmd_path (cmd_tool);
            if ((path == null) || (path.length == 0)) {
                msg += " * " + cmd_tool + "\n";
            }
        }

        if (msg.length > 0) {
            msg = _("Commands listed below are not available on this system") + ":\n\n" + msg + "\n";
            msg += _("Please install required packages and try again");
            logging_helper.log_msg (msg);
            return false;
        } else {
            return true;
        }
    }

    private void init_paths (string custom_user_login = "") {
        string user_home = "";

        // user info
        user_login = system_helper.get_username ();

        if (custom_user_login.length > 0) {
            user_login = custom_user_login;
        }

        user_home = system_helper.get_user_home (user_login);

        // app config files
        APP_CONFIG_FILE = user_home + "/.config/ukuu.json";

        LinuxKernel.CACHE_DIR = user_home + "/.cache/ukuu";
        LinuxKernel.CURRENT_USER = user_login;
        LinuxKernel.CURRENT_USER_HOME = user_home;
    }

    public static void save_app_config () {
        LoggingHelper _logging_helper = new LoggingHelper ();
        FileHelper _file_helper = new FileHelper ();

        var config = new Json.Object ();
        config.set_string_member ("notify_major", notify_major.to_string ());
        config.set_string_member ("notify_minor", notify_minor.to_string ());
        config.set_string_member ("notify_bubble", notify_bubble.to_string ());
        config.set_string_member ("notify_dialog", notify_dialog.to_string ());
        config.set_string_member ("hide_unstable", LinuxKernel.hide_unstable.to_string ());
        config.set_string_member ("hide_older", LinuxKernel.hide_older.to_string ());
        config.set_string_member ("hide_older_4", LinuxKernel.hide_older_4.to_string ());
        config.set_string_member ("notify_interval_unit", notify_interval_unit.to_string ());
        config.set_string_member ("notify_interval_value", notify_interval_value.to_string ());
        // config.set_string_member("show_grub_menu", LinuxKernel.show_grub_menu.to_string());
        config.set_string_member ("grub_timeout", LinuxKernel.grub_timeout.to_string ());
        config.set_string_member ("update_grub_timeout", LinuxKernel.update_grub_timeout.to_string ());

        config.set_string_member ("message_shown", message_shown.to_string ());

        var json = new Json.Generator ();
        json.pretty = true;
        json.indent = 2;

        var node = new Json.Node (NodeType.OBJECT);
        node.set_object (config);
        json.set_root (node);

        try {
            json.to_file (APP_CONFIG_FILE);
        } catch (Error e) {
            _logging_helper.log_error (e.message);
        }

        _logging_helper.log_debug ("Saved config file: %s".printf (APP_CONFIG_FILE));

        // change owner to current user so that ukuu can access in normal mode
        _file_helper.chown (APP_CONFIG_FILE, user_login, user_login);
    }

    private void load_app_config () {
        var f = File.new_for_path (APP_CONFIG_FILE);

        if (!f.query_exists ()) {
            // initialize static
            LinuxKernel.hide_unstable = true;
            LinuxKernel.hide_older = true;
            LinuxKernel.hide_older_4 = true;
            LinuxKernel.update_grub_timeout = false;
            LinuxKernel.grub_timeout = 2;
            return;
        }

        var parser = new Json.Parser ();

        try {
            parser.load_from_file (APP_CONFIG_FILE);
        } catch (Error e) {
            logging_helper.log_error (e.message);
        }

        var node = parser.get_root ();
        var config = node.get_object ();

        notify_major = json_helper.json_get_bool (config, "notify_major", true);
        notify_minor = json_helper.json_get_bool (config, "notify_minor", true);
        notify_bubble = json_helper.json_get_bool (config, "notify_bubble", true);
        notify_dialog = json_helper.json_get_bool (config, "notify_dialog", true);
        notify_interval_unit = json_helper.json_get_int (config, "notify_interval_unit", 0);
        notify_interval_value = json_helper.json_get_int (config, "notify_interval_value", 2);

        LinuxKernel.hide_unstable = json_helper.json_get_bool (config, "hide_unstable", true);
        LinuxKernel.hide_older = json_helper.json_get_bool (config, "hide_older", true);
        LinuxKernel.hide_older_4 = json_helper.json_get_bool (config, "hide_older_4", true);
        // LinuxKernel.show_grub_menu = json_get_bool(config, "show_grub_menu", true);
        LinuxKernel.grub_timeout = json_helper.json_get_int (config, "grub_timeout", 2);
        LinuxKernel.update_grub_timeout = json_helper.json_get_bool (config, "update_grub_timeout", false);

        if (LinuxKernel.hide_older == true) {
            LinuxKernel.hide_older_4 = true;
        }

        message_shown = json_helper.json_get_bool (config, "message_shown", false);

        logging_helper.log_debug ("Load config file: %s".printf (APP_CONFIG_FILE));
    }

    public static void exit_app (int exit_code) {
        save_app_config ();
        exit (exit_code);
    }

    private static bool parse_arguments (string[] args) {
        LoggingHelper _logging_helper = new LoggingHelper ();
        _logging_helper.log_msg (_("Cache") + ": %s".printf (LinuxKernel.CACHE_DIR));

        commands = new GLib.List<string> ();
        command_versions = "";

        for (int k = 1; k < args.length; k++) {
            switch (args[k].down ()) {
                case "--no-gui":
                    NO_GUI = true;
                    break;

                case "--debug":
                    LOG_DEBUG = true;
                    LOG_TIMESTAMP = true;
                    break;

                case "--list":
                case "--list-installed":
                case "--check":
                case "--notify":
                case "--install-latest":
                case "--install-point":
                case "--purge-old-kernels":
                case "--clean-cache":
                    commands.append (args[k].down ());
                    break;

                case "--help":
                case "--h":
                case "-h":
                    _logging_helper.log_msg (help_message ());
                    exit_app (0);
                    return true;

                case "--download":
                case "--install":
                case "--remove":
                    commands.append (args[k].down ());

                    if (++k < args.length) {
                        command_versions = args[k];
                    }
                    break;

                default:
                    _logging_helper.log_error (_("Unknown option") + ": %s".printf (args[k]));
                    _logging_helper.log_msg (help_message ());
                    return false;
            }
        }

        for (int i = 0; i < commands.length (); i++) {
            string command = commands.nth_data (i);

            switch (command) {
                case "--list":
                    check_if_internet_is_active (true);
                    LinuxKernel.query (true);
                    LinuxKernel.print_list ();
                    LinuxKernel.clean_cache ();
                    exit_app (0);
                    break;

                case "--list-installed":
                    LinuxKernel.check_installed ();
                    exit_app (0);
                    break;

                case "--check":
                    check_if_internet_is_active (true);
                    print_updates ();
                    LinuxKernel.clean_cache ();
                    exit_app (0);
                    break;

                case "--notify":
                    check_if_internet_is_active (true);
                    notify_user ();
                    LinuxKernel.clean_cache ();
                    exit_app (0);
                    break;

                case "--install-latest":
                    check_if_admin ();
                    check_if_internet_is_active (true);
                    LinuxKernel.install_latest (false, true);
                    LinuxKernel.clean_cache ();
                    exit_app (0);
                    break;

                case "--install-point":
                    check_if_admin ();
                    check_if_internet_is_active (true);
                    LinuxKernel.install_latest (true, true);
                    LinuxKernel.clean_cache ();
                    exit_app (0);
                    break;

                case "--purge-old-kernels":
                    check_if_admin ();
                    LinuxKernel.purge_old_kernels (true);
                    LinuxKernel.clean_cache ();
                    exit_app (0);
                    break;

                case "--clean-cache":
                    check_if_admin ();
                    LinuxKernel.clean_cache ();
                    exit_app (0);
                    break;

                case "--install":
                    check_if_admin ();
                    check_if_internet_is_active (true);

                    LinuxKernel.query (true);

                    if (command_versions.length == 0) {
                        _logging_helper.log_error (_("No kernels specified"));
                        exit_app (1);
                    }

                    string[] requested_versions = command_versions.split (",");
                    if (requested_versions.length > 1) {
                        _logging_helper.log_error (_("Multiple kernels selected for installation. Select only one."));
                        exit_app (1);
                    }

                    var list = new Gee.ArrayList<LinuxKernel>();

                    foreach (string requested_version in requested_versions) {
                        LinuxKernel kern_requested = null;

                        foreach (var kern in LinuxKernel.kernel_list) {
                            if (kern.name == requested_version) {
                                kern_requested = kern;
                                break;
                            }
                        }

                        if (kern_requested == null) {
                            var msg = _("Could not find requested version");
                            msg += ": %s".printf (requested_version);
                            _logging_helper.log_error (msg);
                            _logging_helper.log_error (_("Run 'ukuu --list' and use the version string listed in first column"));
                            exit_app (1);
                        }

                        list.add (kern_requested);
                    }

                    if (list.size == 0) {
                        _logging_helper.log_error (_("No kernels specified"));
                        exit_app (1);
                    }

                    LinuxKernel.clean_cache ();
                    return list[0].install (true);

                case "--download":
                    check_if_admin ();
                    check_if_internet_is_active (true);

                    LinuxKernel.query (true);

                    if (command_versions.length == 0) {
                        _logging_helper.log_error (_("No kernels specified"));
                        exit_app (1);
                    }

                    var list = new Gee.ArrayList<LinuxKernel>();
                    string[] requested_versions = command_versions.split (",");

                    foreach (string requested_version in requested_versions) {
                        LinuxKernel kern_requested = null;

                        foreach (var kern in LinuxKernel.kernel_list) {
                            if (kern.name == requested_version) {
                                kern_requested = kern;
                                break;
                            }
                        }

                        if (kern_requested == null) {
                            var msg = _("Could not find requested version");
                            msg += ": %s".printf (requested_version);
                            _logging_helper.log_error (msg);
                            _logging_helper.log_error (_("Run 'ukuu --list' and use the version string listed in first column"));
                            exit_app (1);
                        }

                        list.add (kern_requested);
                    }

                    if (list.size == 0) {
                        _logging_helper.log_error (_("No kernels specified"));
                        exit_app (1);
                    }

                    LinuxKernel.clean_cache ();
                    return LinuxKernel.download_kernels (list);

                case "--remove":
                    check_if_admin ();
                    LinuxKernel.query (true);

                    if (command_versions.length == 0) {
                        _logging_helper.log_error (_("No kernels specified"));
                        exit_app (1);
                    }

                    var list = new Gee.ArrayList<LinuxKernel>();
                    string[] requested_versions = command_versions.split (",");

                    foreach (string requested_version in requested_versions) {
                        LinuxKernel kern_requested = null;

                        foreach (var kern in LinuxKernel.kernel_list) {
                            if (kern.name == requested_version) {
                                kern_requested = kern;
                                break;
                            }
                        }

                        if (kern_requested == null) {
                            var msg = _("Could not find requested version");
                            msg += ": %s".printf (requested_version);
                            _logging_helper.log_error (msg);
                            _logging_helper.log_error (_("Run 'ukuu --list' and use the version string listed in first column"));
                            exit_app (1);
                        }

                        list.add (kern_requested);
                    }

                    if (list.size == 0) {
                        _logging_helper.log_error (_("No kernels specified"));
                        exit_app (1);
                    }

                    LinuxKernel.clean_cache ();
                    return LinuxKernel.remove_kernels (list);

                default:
                    _logging_helper.log_error (_("Command not specified"));
                    _logging_helper.log_error (_("Run 'ukuu --help' to list all commands"));
                    exit_app (1);
                    break;
            }
        }

        return true;
    }

    private static string help_message () {
        string msg = "\n" + App.APP_NAME + " v" + App.APP_VERSION + " by " + App.APP_AUTHOR + " (" + App.APP_AUTHOR_EMAIL + ") " + "\n";
        msg += "\n";
        msg += _("Syntax") + ": ukuu <command> [options]\n";
        msg += "\n";
        msg += _("Commands") + ":\n";
        msg += "\n";
        msg += "  --debug             " + _("Print debug information") + "\n";
        msg += "  --h[elp]            " + _("Show all options") + "\n";
        msg += "  --check             " + _("Check for kernel updates") + "\n";
        msg += "  --notify            " + _("Check for kernel updates and notify current user") + "\n";
        msg += "  --list              " + _("List all available mainline kernels") + "\n";
        msg += "  --list-installed    " + _("List installed kernels") + "\n";
        msg += "  --install-latest    " + _("Install latest mainline kernel") + "\n";
        msg += "  --install-point     " + _("Install latest point update for current series") + "\n";
        msg += "  --install <name>    " + _("Install specified mainline kernel") + "\n";
        msg += "  --remove <name>     " + _("Remove specified kernel") + "\n";
        msg += "  --purge-old-kernels " + _("Remove installed kernels older than running kernel") + "\n";
        msg += "  --download <name>   " + _("Download packages for specified kernel") + "\n";
        msg += "  --clean-cache       " + _("Remove files from application cache") + "\n";
        msg += "\n";
        msg += _("Options") + ":\n";
        msg += "\n";
        msg += "  --clean-cache     " + _("Remove files from application cache") + "\n";
        msg += "\n";
        msg += "Notes:\n";
        msg += "1. Comma separated list of version strings can be specified for --remove and --download\n";
        return msg;
    }

    private static void check_if_admin () {
        LoggingHelper _logging_helper = new LoggingHelper ();
        SystemHelper _system_helper = new SystemHelper ();

        if (_system_helper.get_user_id_effective () != 0) {
            _logging_helper.log_msg (string.nfill (70, '-'));

            string msg = _("Admin access is required to run this application.");
            _logging_helper.log_error (msg);

            msg = _("Run the application as admin with pkexec or sudo.");
            _logging_helper.log_error (msg);

            exit_app (1);
        }
    }

    public static void check_if_internet_is_active (bool exit = true) {
        if (!check_internet_connectivity ()) {
            if (exit) {
                exit_app (1);
            }
        }
    }

    private static bool check_internet_connectivity () {
        ProcessHelper _process_helper = new ProcessHelper ();
        LoggingHelper _logging_helper = new LoggingHelper ();

        string std_err, std_out;
        string cmd = "url='https://www.google.com' \n";

        // Note: minimum of 3 seconds is required for timeout, to avoid wrong results
        cmd += "httpCode=$(curl -o /dev/null --silent --max-time 5 --head --write-out '%{http_code}\n' $url) \n";
        cmd += "test $httpCode -lt 400 -a $httpCode -gt 0 \n";
        cmd += "exit $?";

        int status = _process_helper.exec_script_sync (cmd, out std_out, out std_err, false);

        if (std_err.length > 0) {
            _logging_helper.log_error (std_err);
        }

        if (status != 0) {
            _logging_helper.log_error (_("Internet connection is not active"));
        }

        return (status == 0);
    }

    private static void print_updates () {
        LoggingHelper _logging_helper = new LoggingHelper ();

        LinuxKernel.query (true);
        LinuxKernel.check_updates ();

        var kern_major = LinuxKernel.kernel_update_major;

        if (kern_major != null) {
            var message = "%s: %s".printf (_("Latest update"), kern_major.version_main);
            _logging_helper.log_msg (message);
        }

        var kern_minor = LinuxKernel.kernel_update_minor;

        if (kern_minor != null) {
            var message = "%s: %s".printf (_("Latest point update"), kern_minor.version_main);
            _logging_helper.log_msg (message);
        }

        if ((kern_major == null) && (kern_minor == null)) {
            _logging_helper.log_msg (_("No updates found"));
        }

        _logging_helper.log_msg (string.nfill (70, '-'));
    }

    private static void notify_user () {
        LoggingHelper _logging_helper = new LoggingHelper ();
        ProcessHelper _process_helper = new ProcessHelper ();

        LinuxKernel.query (true);
        LinuxKernel.check_updates ();

        var kern = LinuxKernel.kernel_update_major;

        if ((kern != null) && App.notify_major) {

            var title = "Linux v%s Available".printf (kern.version_main);
            var message = "Major update available for installation";

            if (App.notify_bubble) {
                OSDNotify osd_notify = new OSDNotify ();
                osd_notify.notify_send (title, message, 3000, "normal", "info");
            }

            _logging_helper.log_msg (title);
            _logging_helper.log_msg (message);

            if (App.notify_dialog) {
                _process_helper.exec_script_async ("ukuu-gtk --notify");
                exit_app (0);
            }

            return;
        }

        kern = LinuxKernel.kernel_update_minor;

        if ((kern != null) && App.notify_minor) {

            var title = "Linux v%s Available".printf (kern.version_main);
            var message = "Minor update available for installation";

            if (App.notify_bubble) {
                OSDNotify osd_notify = new OSDNotify ();
                osd_notify.notify_send (title, message, 3000, "normal", "info");
            }

            _logging_helper.log_msg (title);
            _logging_helper.log_msg (message);

            if (App.notify_dialog) {
                _process_helper.exec_script_async ("ukuu-gtk --notify");
                exit_app (0);
            }

            return;
        }
    }

    private static void set_locale () {
        Intl.setlocale (GLib.LocaleCategory.MESSAGES, "ukuu");
        Intl.textdomain (App.GETTEXT_PACKAGE);
        Intl.bind_textdomain_codeset (App.GETTEXT_PACKAGE, "utf-8");
        Intl.bindtextdomain (App.GETTEXT_PACKAGE, App.LOCALE_DIR);
    }
}
