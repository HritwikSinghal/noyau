/*
 * DownloadItem.vala
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

using GLib;

public class DownloadItem : GLib.Object {
    /* File is downloaded to 'partial_dir' and moved to 'download_dir'
     * after successful completion. File will always be saved with
     * the specified name 'file_name' instead of the source file name.
     * */

    public string file_name = "";
    public string download_dir = "";
    public string partial_dir = "";
    public string source_uri = "";

    public string gid = ""; // ID
    public int64 bytes_total = 0;
    public int64 bytes_received = 0;
    public int64 rate = 0;
    public string eta = "";
    public string status = "";

    public DownloadHelper task = null;
    private FileHelper file_helper;
    private ProcessHelper process_helper;

    public DownloadItem (string _source_uri, string _download_dir, string _file_name) {
        file_helper = new FileHelper ();
        process_helper = new ProcessHelper ();

        file_name = _file_name;
        download_dir = _download_dir;
        partial_dir = process_helper.create_temp_subdir ();
        source_uri = _source_uri;
    }

    public string file_path{
        owned get {
            return file_helper.path_combine (download_dir, file_name);
        }
    }

    public string file_path_partial{
        owned get {
            return file_helper.path_combine (partial_dir, file_name);
        }
    }

    public string gid_key{
        owned get {
            return gid.substring (0, 6);;
        }
    }

    public string status_line () {
        if (task.status_in_kb) {
            return "%s / %s, %s/s (%s)".printf (
                file_helper.format_file_size (bytes_received, false, "", true, 1),
                file_helper.format_file_size (bytes_total, false, "", true, 1),
                file_helper.format_file_size (rate, false, "", true, 1),
                eta).replace ("\n", "");
        } else {
            return "%s / %s, %s/s (%s)".printf (
                file_helper.format_file_size (bytes_received),
                file_helper.format_file_size (bytes_total),
                file_helper.format_file_size (rate),
                eta).replace ("\n", "");
        }
    }
}
