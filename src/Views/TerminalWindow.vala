/*
 * TerminalWindow.vala
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

using Gtk;
using Gee;

public class TerminalWindow : Gtk.Window {

    private Gtk.Box vbox_main;
    private Vte.Terminal term;
    private Gtk.Button btn_cancel;
    private Gtk.Button btn_close;
    private Gtk.ScrolledWindow scroll_win;

    private int def_width = 1024;
    private int def_height = 600;

    private Pid child_pid;
    private Gtk.Window parent_win = null;

    public bool cancelled = false;
    public bool is_running = false;

    private GtkHelper gtk_helper;
    private ProcessHelper process_helper;
    private LoggingHelper logging_helper;
    private SystemHelper system_helper;
    private FileHelper file_helper;

    public signal void script_complete ();

    public TerminalWindow.with_parent (Gtk.Window ? parent, bool fullscreen = false, bool show_cancel_button = false) {
        gtk_helper = new GtkHelper ();
        process_helper = new ProcessHelper ();
        logging_helper = new LoggingHelper ();
        system_helper = new SystemHelper ();
        file_helper = new FileHelper ();

        if (parent != null) {
            set_transient_for (parent);
            parent_win = parent;
        }
        set_modal (true);
        window_position = WindowPosition.CENTER;

        if (fullscreen) {
            this.fullscreen ();
        }

        this.delete_event.connect (cancel_window_close);

        init_window ();

        show_all ();

        btn_cancel.visible = false;
        btn_close.visible = false;

        if (show_cancel_button) {
            allow_cancel ();
        }
    }

    public bool cancel_window_close () {
        return true; // Note: do not allow window to close
    }

    public void init_window () {
        title = App.APP_NAME;
        icon = gtk_helper.get_app_icon (16);
        resizable = true;
        deletable = false;

        // vbox_main ---------------

        vbox_main = new Gtk.Box (Orientation.VERTICAL, 0);
        vbox_main.set_size_request (def_width, def_height);
        add (vbox_main);

        // terminal ----------------------

        term = new Vte.Terminal ();
        term.expand = true;

        // sw_ppa
        scroll_win = new Gtk.ScrolledWindow (null, null);
        scroll_win.set_shadow_type (ShadowType.ETCHED_IN);
        scroll_win.add (term);
        scroll_win.expand = true;
        scroll_win.hscrollbar_policy = PolicyType.AUTOMATIC;
        scroll_win.vscrollbar_policy = PolicyType.AUTOMATIC;
        vbox_main.add (scroll_win);

        term.input_enabled = true;
        term.backspace_binding = Vte.EraseBinding.AUTO;
        term.cursor_blink_mode = Vte.CursorBlinkMode.SYSTEM;
        term.cursor_shape = Vte.CursorShape.UNDERLINE;
        term.rewrap_on_resize = true;

        term.scroll_on_keystroke = true;
        term.scroll_on_output = true;
        term.scrollback_lines = 100000;

        term.set_font_scale (1.0);

        // colors -----------------------------

        var color = Gdk.RGBA ();
        color.parse ("#FFFFFF");
        term.set_color_foreground (color);

        color.parse ("#404040");
        term.set_color_background (color);

        // grab focus ----------------

        term.grab_focus ();

        // add cancel button --------------

        var hbox = new Gtk.Box (Orientation.HORIZONTAL, 6);
        hbox.homogeneous = true;
        vbox_main.add (hbox);

        var label = new Gtk.Label ("");
        hbox.pack_start (label, true, true, 0);

        label = new Gtk.Label ("");
        hbox.pack_start (label, true, true, 0);

        // btn_cancel
        var button = new Gtk.Button.with_label (_("Cancel"));
        hbox.pack_start (button, true, true, 0);
        btn_cancel = button;

        btn_cancel.clicked.connect (() => {
            cancelled = true;
            terminate_child ();
        });

        // btn_close
        button = new Gtk.Button.with_label (_("Close"));
        hbox.pack_start (button, true, true, 0);
        btn_close = button;

        btn_close.clicked.connect (() => {
            this.destroy ();
        });

        label = new Gtk.Label ("");
        hbox.pack_start (label, true, true, 0);

        label = new Gtk.Label ("");
        hbox.pack_start (label, true, true, 0);
    }

    public void start_shell () {
        string[] argv = new string[1];
        argv[0] = "/bin/sh";

        string[] env = Environ.get ();

        try {
            is_running = true;

            term.spawn_sync (
                Vte.PtyFlags.DEFAULT, // pty_flags
                process_helper.get_temp_file_path (), // working_directory
                argv, // argv
                env, // env
                GLib.SpawnFlags.SEARCH_PATH, // spawn_flags
                null, // child_setup
                out child_pid,
                null
            );
        } catch (Error e) {
            logging_helper.log_error (e.message);
        }
    }

    public void terminate_child () {
        btn_cancel.sensitive = false;
        process_helper.process_quit (child_pid);
    }

    public void execute_command (string command) {
#if VALA_0_44
        term.feed_child (string_to_char_array (command));
#elif VALA_0_40
        term.feed_child (command, command.length);
#endif
    }

    public void execute_script (string script_path, bool wait = false) {
        string[] argv = new string[1];
        argv[0] = script_path;

        string[] env = Environ.get ();

        try {
            is_running = true;

            term.spawn_sync (
                Vte.PtyFlags.DEFAULT, // pty_flags
                process_helper.get_temp_file_path (), // working_directory
                argv, // argv
                env, // env
                GLib.SpawnFlags.SEARCH_PATH | GLib.SpawnFlags.DO_NOT_REAP_CHILD, // spawn_flags
                null, // child_setup
                out child_pid,
                null
            );

            term.watch_child (child_pid);
            term.child_exited.connect (script_exit);

            if (wait) {
                while (is_running) {
                    system_helper.sleep (200);
                    gtk_helper.gtk_do_events ();
                }
            }
        } catch (Error e) {
            logging_helper.log_error (e.message);
        }
    }

    public void script_exit (int status) {
        is_running = false;

        Process.close_pid (child_pid); // required on Windows, doesn't do anything on Unix

        btn_cancel.visible = false;
        btn_close.visible = true;

        script_complete ();
    }

    public void allow_window_close (bool allow = true) {
        if (allow) {
            this.delete_event.disconnect (cancel_window_close);
            this.deletable = true;
        } else {
            this.delete_event.connect (cancel_window_close);
            this.deletable = false;
        }
    }

    public void allow_cancel (bool allow = true) {
        if (allow) {
            btn_cancel.visible = true;
            vbox_main.margin = 3;
        } else {
            btn_cancel.sensitive = false;
            vbox_main.margin = 3;
        }
    }

    // Adapted from: https://kuikie.com/snippet/85-8/vala/strings/vala-convert-string-to-char-array/
    private char[] string_to_char_array (string str) {
        char[] char_array = new char[str.length];

        for (int i = 0; i < str.length; i++) {
            char_array[i] = (char) str.get_char (str.index_of_nth_char (i));
        }

        return char_array;
    }
}

