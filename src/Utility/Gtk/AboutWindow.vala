/*
 * AboutWindow.vala
 *
 * Copyright 2016 Tony George <teejeetech@gmail.com>
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
 *
 *
 */

using Gtk;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JsonHelper;
using TeeJee.ProcessHelper;
using TeeJee.GtkHelper;
using TeeJee.System;
using TeeJee.Misc;

public class AboutWindow : AboutDialog {
	public AboutWindow() {
		this.title = Main.AppName;
		this.program_name = Main.AppName;
		this.comments = _("A graphical utility for managing kernels on Ubuntu.");
		//this.logo_icon_name = get_app_icon(128);
		this.version = Main.AppVersion;
		this.website = "https://joshuadowding.github.io";

		this.authors = {
			"Joshua Dowding:joshuadowding@outlook.com",
			"Tony George:teejeetech@gmail.com"
		};

		this.translator_credits = _("translator-credits");
		this.copyright = "Copyright © 2019 Joshua Dowding (%s)".printf(Main.AppAuthorEmail);
		this.license_type = Gtk.License.GPL_3_0;

		this.destroy_with_parent = true;
		this.modal = true;

		this.response.connect (() => {
			this.destroy ();
		});
	}
}

/*
 * 	Translators:
 * 	"Åke Engelbrektson (Swedish):eson@svenskasprakfiler.se",
	"Иннусик (Russian):slavusik1988@gmail.com",
	"Waldemar Konik (Polish):valdi74@github",
	"gogo (Croatian):trebelnik2@gmail.com",
	"Adolfo Jayme Barrientos (Spanish):fitojb@ubuntu.com",
	"yolateng0 (French):github.com/yolateng0",
	"Hugo Posnic (French):hugo.posnic@gmail.com"
 */

