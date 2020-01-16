/*
 * ProgressWindow.vala
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

public class ProgressWindow : Gtk.Dialog {

    private Gtk.Box vbox_main;
    private Gtk.Spinner spinner;
    private Gtk.Label lbl_msg;
    private Gtk.Label lbl_status;
    private ProgressBar progressbar;
    private Gtk.Button btn_cancel;

    private uint tmr_init = 0;
    private uint tmr_close = 0;
    private int def_width = 400;
    private int def_height = 50;

    private string status_message;
    private bool allow_cancel = false;
    private bool allow_close = false;

    public GtkHelper gtk_helper;

    // init

    public ProgressWindow.with_parent (Window parent, string message, bool allow_cancel = false) {
        gtk_helper = new GtkHelper ();

        this.set_transient_for (parent);
        this.set_modal (true);
        this.set_skip_taskbar_hint (true);
        this.set_skip_pager_hint (true);
        this.set_type_hint (Gdk.WindowTypeHint.DIALOG);
        this.window_position = WindowPosition.CENTER;

        this.set_default_size (def_width, def_height);

        App.status_line = "";
        App.progress_count = 0;
        App.progress_total = 0;

        status_message = message;
        this.allow_cancel = allow_cancel;

        App.cancelled = false;

        this.delete_event.connect (close_window);

        init_window ();
    }

    private bool close_window () {
        if (allow_close) {
            // allow window to close
            return false;
        } else {
            // do not allow window to close
            return true;
        }
    }

    public void init_window () {
        this.title = App.APP_NAME;
        this.icon = gtk_helper.get_app_icon (16);
        this.resizable = false;
        this.set_deletable (false);

        var content_area = this.get_content_area ();

        // vbox_main
        vbox_main = new Gtk.Box (Orientation.VERTICAL, 6);
        vbox_main.margin = 12;
        content_area.add (vbox_main);

        var hbox_msg = new Gtk.Box (Orientation.HORIZONTAL, 6);
        vbox_main.add (hbox_msg);

        spinner = new Gtk.Spinner ();
        spinner.active = true;
        hbox_msg.add (spinner);

        // lbl_msg
        lbl_msg = new Gtk.Label (status_message);
        lbl_msg.halign = Align.START;
        lbl_msg.ellipsize = Pango.EllipsizeMode.END;
        lbl_msg.max_width_chars = 40;
        hbox_msg.add (lbl_msg);

        var hbox = new Gtk.Box (Orientation.HORIZONTAL, 6);
        vbox_main.add (hbox);

        // progressbar
        progressbar = new Gtk.ProgressBar ();
        progressbar.width_request = 300;
        progressbar.hexpand = true;
        progressbar.fraction = 0.1;
        hbox.add (progressbar);

        var hbox_status = new Gtk.Box (Orientation.HORIZONTAL, 6);
        vbox_main.add (hbox_status);

        // lbl_status
        lbl_status = new Gtk.Label ("");
        lbl_status.halign = Align.START;
        lbl_status.ellipsize = Pango.EllipsizeMode.END;
        lbl_status.max_width_chars = 40;
        hbox_status.add (lbl_status);

        // box
        var box = new Gtk.Box (Orientation.HORIZONTAL, 6);
        box.set_homogeneous (true);
        vbox_main.add (box);

        // btn
        var button = new Gtk.Button.with_label (_("Cancel"));
        button.margin_top = 6;
        box.pack_start (button, false, false, 0);

        button.clicked.connect (() => {
            App.cancelled = true;
            btn_cancel.sensitive = false;
        });

        btn_cancel = button;
        btn_cancel.sensitive = allow_cancel;

        this.show_all ();
    }

    // common

    public void update_message (string msg) {
        if (msg.length > 0) {
            lbl_msg.label = msg;
        }
    }

    public void update_status_line (bool clear = false) {
        if (clear) {
            lbl_status.label = "";
        } else {
            lbl_status.label = App.status_line;
        }
    }

    public void update_progressbar () {
        double fraction = App.progress_count / (App.progress_total * 1.0);

        if (fraction > 1.0) {
            fraction = 1.0;
        }

        progressbar.fraction = fraction;
    }

    public void finish (string message = "") {
        btn_cancel.sensitive = false;

        progressbar.fraction = 1.0;

        lbl_msg.label = message;
        lbl_status.label = "";

        spinner.visible = false;

        gtk_helper.gtk_do_events ();
        auto_close_window ();
    }

    private void auto_close_window () {
        tmr_close = Timeout.add (2000, () => {
            if (tmr_init > 0) {
                Source.remove (tmr_init);
                tmr_init = 0;
            }

            allow_close = true;
            this.close ();
            return false;
        });
    }
}
