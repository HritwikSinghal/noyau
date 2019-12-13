/*
 * Consts.vala
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

using GLib;

public class Consts : GLib.Object {
    public const string APP_NAME = @"Ubuntu Kernel Update Utility";
    public const string APP_NAME_SHORT = @"ukuu";
    public const string APP_VERSION = @"18.10";
    public const string APP_AUTHOR = @"Joshua Dowding";
    public const string APP_AUTHOR_EMAIL = @"joshuadowding@outlook.com";
    public const string APP_AUTHOR_WEBSITE = @"https://joshuadowding.github.io";

    public const string GETTEXT_PACKAGE = @"";
    public const string LOCALE_DIR = @"/usr/share/locale";
}
