/*
 * AboutWindow.vala
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

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.ProcessHelper;
using TeeJee.System;
using TeeJee.Misc;

public class AboutWindow : AboutDialog {

    public GtkHelper gtk_helper;

    public AboutWindow () {
        gtk_helper = new GtkHelper ();

        this.title = App.APP_NAME;
        this.program_name = App.APP_NAME_SHORT;
        this.comments = _("A graphical utility for managing kernels on Ubuntu.");
        this.version = App.APP_VERSION;
        this.website = App.APP_AUTHOR_WEBSITE;

        this.logo = gtk_helper.get_app_icon (64);
        this.modal = true;
        this.destroy_with_parent = true;

        this.authors = {
            "Joshua Dowding (joshuadowding@outlook.com)",
            "Tony George (teejeetech@gmail.com)"
        };

        this.translator_credits = _("translator-credits");

        this.copyright = "Copyright © 2019 " + App.APP_AUTHOR + " (" + App.APP_AUTHOR_EMAIL + ")";
        this.license_type = Gtk.License.GPL_3_0;
        this.wrap_license = true;

        this.response.connect (() => {
            this.destroy ();
        });
    }
}
