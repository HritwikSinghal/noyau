/*
 * GtkHelper.vala
 *
 * Copyright 2012-2019 Tony George <teejeetech@gmail.com>
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
using GLib;

using JsonHelper;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.ProcessHelper;
using TeeJee.System;
using TeeJee.Misc;

public class GtkHelper : GLib.Object {

    public static int CSS_AUTO_CLASS_INDEX = 0;

    // messages ----------------------------------------

    public void gtk_do_events () {

        /* Do pending events */

        while (Gtk.events_pending ())
            Gtk.main_iteration ();
    }

    public void gtk_messagebox (string title, string message, Gtk.Window ? parent_win, bool is_error = false) {
        var type = Gtk.MessageType.INFO;

        if (is_error) {
            type = Gtk.MessageType.ERROR;
        } else {
            type = Gtk.MessageType.INFO;
        }

        var dlg = new Gtk.MessageDialog.with_markup (parent_win, Gtk.DialogFlags.MODAL, type, Gtk.ButtonsType.OK, message);
        dlg.title = title;
        dlg.set_default_size (200, -1);

        if (parent_win != null) {
            dlg.set_transient_for (parent_win);
            dlg.set_modal (true);
        }

        dlg.run ();
        dlg.destroy ();
    }

    // icon ----------------------------------------------

    public Gdk.Pixbuf ? get_app_icon (int icon_size, string format = ".png") {
        var img_icon = get_shared_icon (Consts.APP_NAME_SHORT, Consts.APP_NAME_SHORT + format, icon_size, "pixmaps");
        if (img_icon != null) {
            return img_icon.pixbuf;
        } else {
            return null;
        }
    }

    public Gtk.Image ? get_shared_icon (
        string icon_name,
        string fallback_icon_file_name,
        int icon_size,
        string icon_directory = Consts.APP_NAME_SHORT + "/images") {

        Gdk.Pixbuf pix_icon = null;
        Gtk.Image img_icon = null;

        try {
            Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default ();

            pix_icon = icon_theme.load_icon_for_scale (
                icon_name, Gtk.IconSize.MENU, icon_size, Gtk.IconLookupFlags.FORCE_SIZE);
        } catch (Error e) {
            log_error (e.message);
        }

        string fallback_icon_file_path = "/usr/share/%s/%s".printf (icon_directory, fallback_icon_file_name);

        if (pix_icon == null) {
            try {
                pix_icon = new Gdk.Pixbuf.from_file_at_size (fallback_icon_file_path, icon_size, icon_size);
            } catch (Error e) {
                log_error (e.message);
            }
        }

        if (pix_icon == null) {
            log_error (_("Missing Icon") + ": '%s', '%s'".printf (icon_name, fallback_icon_file_path));
        } else {
            img_icon = new Gtk.Image.from_pixbuf (pix_icon);
        }

        return img_icon;
    }

    public Gdk.Pixbuf ? get_shared_icon_pixbuf (string icon_name,
                                                string fallback_file_name,
                                                int icon_size,
                                                string icon_directory = Consts.APP_NAME_SHORT + "/images") {

        var img = get_shared_icon (icon_name, fallback_file_name, icon_size, icon_directory);
        var pixbuf = (img == null) ? null : img.pixbuf;
        return pixbuf;
    }

    // treeview -----------------

    public int gtk_treeview_model_count (TreeModel model) {
        int count = 0;
        TreeIter iter;
        if (model.get_iter_first (out iter)) {
            count++;
            while (model.iter_next (ref iter)) {
                count++;
            }
        }
        return count;
    }
}
