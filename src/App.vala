/*
 * App.vala
 *
 * Copyright 2012-2019 Tony George <teejee2008@gmail.com>
 * Copyright 2019 Joshua Dowding <joshuadowding@outlook.com>
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
    public const int STARTUP_DELAY = 300;

    public static string APP_CONFIG_FILE = "";
    public static string STARTUP_SCRIPT_FILE = "";
    public static string STARTUP_DESKTOP_FILE = "";

    public static string command = "list";
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
    }

    protected override void activate () {
        gtk_helper = new GtkHelper ();
        json_helper = new JsonHelper ();
        system_helper = new SystemHelper ();
        logging_helper = new LoggingHelper ();
        process_helper = new ProcessHelper ();

        // check_if_admin ();

        Package.initialize ();
        LinuxKernel.initialize ();

        init_paths ();
        load_app_config ();
        set_locale ();

        logging_helper.log_msg ("%s v%s".printf (App.APP_NAME_SHORT, App.APP_VERSION));
        process_helper.init_tmp ("ukuu");

        // LOG_TIMESTAMP = false;

        // check dependencies
        string message;
        if (!check_dependencies (out message)) {
            gtk_helper.gtk_messagebox ("", message, null, true);
            exit (0);
        }

        // create main window --------------------------------------

        var window = new MainWindow ();

        window.destroy.connect (() => {
            logging_helper.log_debug ("MainWindow destroyed");
            Gtk.main_quit ();
        });

        window.delete_event.connect ((event) => {
            logging_helper.log_debug ("MainWindow closed");
            Gtk.main_quit ();
            return true;
        });

        window.show_all ();

        // start event loop -------------------------------------

        Gtk.main ();
        save_app_config ();
    }

    public static int main (string[] args) {
        // parse_arguments (args);
        Gtk.init (ref args);

        var app = new App ();
        return app.run (args);
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
        STARTUP_SCRIPT_FILE = user_home + "/.config/ukuu-notify.sh";
        STARTUP_DESKTOP_FILE = user_home + "/.config/autostart/ukuu.desktop";

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

        update_notification_files ();
    }

    private static void update_notification_files () {
        update_startup_script ();
        update_startup_desktop_file ();
    }

    private void load_app_config () {
        var f = File.new_for_path (APP_CONFIG_FILE);

        if (!f.query_exists ()) {
            // initialize static
            LinuxKernel.hide_unstable = true;
            LinuxKernel.hide_older = true;
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
        // LinuxKernel.show_grub_menu = json_get_bool(config, "show_grub_menu", true);
        LinuxKernel.grub_timeout = json_helper.json_get_int (config, "grub_timeout", 2);
        LinuxKernel.update_grub_timeout = json_helper.json_get_bool (config, "update_grub_timeout", false);

        message_shown = json_helper.json_get_bool (config, "message_shown", false);

        logging_helper.log_debug ("Load config file: %s".printf (APP_CONFIG_FILE));
    }

    public static void exit_app (int exit_code) {
        save_app_config ();
        exit (exit_code);
    }

    // begin ------------

    private static void update_startup_script () {
        FileHelper _file_helper = new FileHelper ();

        int count = notify_interval_value;
        string suffix = "h";

        switch (notify_interval_unit) {
            case 0: // hour
                suffix = "h";
                break;
            case 1: // day
                suffix = "d";
                break;
            case 2: // week
                suffix = "d";
                count = notify_interval_value * 7;
                break;
        }

        // count = 20;
        // suffix = "s";

        string txt = "";
        txt += "sleep %ds\n".printf (STARTUP_DELAY);
        txt += "while true\n";
        txt += "do\n";
        txt += "  ukuu --notify ; sleep %d%s \n".printf (count, suffix);
        txt += "done\n";

        if (_file_helper.file_exists (STARTUP_SCRIPT_FILE)) {
            _file_helper.file_delete (STARTUP_SCRIPT_FILE);
        }

        if (notify_minor || notify_major) {
            _file_helper.file_write (
                STARTUP_SCRIPT_FILE,
                txt);
        } else {
            _file_helper.file_write (
                STARTUP_SCRIPT_FILE,
                "# Notifications are disabled\n\nexit 0"); // write dummy script
        }

        _file_helper.chown (STARTUP_SCRIPT_FILE, user_login, user_login);
    }

    private static void update_startup_desktop_file () {
        FileHelper _file_helper = new FileHelper ();

        if (notify_minor || notify_major) {
            string txt =
                """
                [Desktop Entry]
                Type=Application
                Exec={command}
                Hidden=false
                NoDisplay=false
                X-GNOME-Autostart-enabled=true
                Name[en_IN]=Ukuu Notification
                Name=Ukuu Notification
                Comment[en_IN]=Ukuu Notification
                Comment=Ukuu Notification
                """;

            txt = txt.replace ("{command}", "sh \"%s\"".printf (STARTUP_SCRIPT_FILE));

            _file_helper.file_write (STARTUP_DESKTOP_FILE, txt);

            _file_helper.chown (STARTUP_DESKTOP_FILE, user_login, user_login);
        } else {
            _file_helper.file_delete (STARTUP_DESKTOP_FILE);
        }
    }

    private static void set_locale () {
        Intl.setlocale (GLib.LocaleCategory.MESSAGES, "ukuu");
        Intl.textdomain (App.GETTEXT_PACKAGE);
        Intl.bind_textdomain_codeset (App.GETTEXT_PACKAGE, "utf-8");
        Intl.bindtextdomain (App.GETTEXT_PACKAGE, App.LOCALE_DIR);
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

            exit (1);
        }
    }

    private static bool parse_arguments (string[] args) {
        LoggingHelper _logging_helper = new LoggingHelper ();

        _logging_helper.log_msg (_("Cache") + ": %s".printf (LinuxKernel.CACHE_DIR));
        // _logging_helper.log_msg (_("Temp") + ": %s".printf (TEMP_DIR));

        command = "list";

        // parse options
        for (int k = 1; k < args.length; k++) { // Oth arg is app path
            switch (args[k].down ()) {

                case "--debug":
                    // LOG_DEBUG = true;
                    break;

                case "--help":
                case "--h":
                case "-h":
                    _logging_helper.log_msg (help_message ());
                    exit (0);
                    return true;
            }
        }

        for (int k = 1; k < args.length; k++) { // Oth arg is app path
            switch (args[k].down ()) {

                // commands ------------------------------------

                case "--install":
                    command = "install";
                    requested_version = args[++k];
                    break;

                case "--notify":
                    command = "notify";
                    break;

                // options without argument --------------------------

                case "--help":
                case "--h":
                case "-h":
                case "--debug":
                    // already handled - do nothing
                    break;

                // options with argument --------------------------

                case "--user":
                    k += 1;
                    // already handled - do nothing
                    break;

                default:
                    // unknown option - show help and exit
                    _logging_helper.log_error (_("Unknown option") + ": %s".printf (args[k]));
                    _logging_helper.log_msg (help_message ());
                    return false;
            }
        }

        return true;
    }

    private static string help_message () {
        string msg = "\n" + App.APP_NAME + " v" + App.APP_VERSION + " by Tony George (teejeetech@gmail.com)" + "\n";
        msg += "\n";
        msg += _("Syntax") + ": ukuu-gtk [options]\n";
        msg += "\n";
        msg += _("Options") + ":\n";
        msg += "\n";
        msg += "  --debug      " + _("Print debug information") + "\n";
        msg += "  --h[elp]     " + _("Show all options") + "\n";
        msg += "\n";
        return msg;
    }
}
