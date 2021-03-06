/*
 * DownloadHelper.vala
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

using Gee;

public class DownloadHelper : AsyncTask {

    // settings
    public bool status_in_kb = false;
    public int connect_timeout_secs = 60;
    public int timeout_secs = 60;
    public int concurrent_downloads = 20;

    // download lists
    private Gee.ArrayList<DownloadItem> downloads;
    private Gee.HashMap<string, DownloadItem> map;

    private Gee.HashMap<string, Regex> regex = null;
    private static Version tool_version = null;

    public DownloadHelper () {
        base ();

        LoggingHelper logging_helper = new LoggingHelper ();

        downloads = new Gee.ArrayList<DownloadItem>();
        map = new Gee.HashMap<string, DownloadItem>();

        regex = new Gee.HashMap<string, Regex>();

        try {
            // Sample:
            // [#4df0c7 19283968B/45095814B(42%) CN:1 DL:105404B ETA:4m4s]
            regex["file-progress"] = new Regex ("""^\[#([^ \t]+)[ \t]+([0-9]+)B\/([0-9]+)B\(([0-9]+)%\)[ \t]+[^ \t]+[ \t]+DL\:([0-9]+)B[ \t]+ETA\:([^ \]]+)\]""");

            // 12/03 21:15:33 [NOTICE] Download complete: /home/teejee/.cache/noyau/v4.7.8/CHANGES
            regex["file-complete"] = new Regex ("""[0-9A-Z\/: ]*\[NOTICE\] Download complete\: (.*)""");

            // 8ae3a3|OK  |    16KiB/s|/home/teejee/.cache/noyau/v4.0.7-wily/index.html
            // bea740|OK  |        n/a|/home/teejee/.cache/noyau/v4.0.9-wily/CHANGES
            regex["file-status"] = new Regex ("""^([0-9A-Za-z]+)\|(OK|ERR)[ ]*\|[ ]*(n\/a|[0-9.]+[A-Za-z\/]+)\|(.*)""");
        } catch (Error e) {
            logging_helper.log_error (e.message);
        }

        check_tool_version ();
    }

    public void check_tool_version () {
        LoggingHelper logging_helper = new LoggingHelper ();
        ProcessHelper process_helper = new ProcessHelper ();

        if (tool_version != null) {
            return;
        }

        logging_helper.log_debug ("DownloadHelper: check_tool_version()");

        string std_out, std_err;
        string cmd = "aria2c --version";

        logging_helper.log_debug (cmd);

        process_helper.exec_script_sync (cmd, out std_out, out std_err);

        string line = std_out.split ("\n")[0];
        var arr = line.split (" ");
        if (arr.length >= 3) {
            string part = arr[2].strip ();
            tool_version = new Version (part);
            logging_helper.log_msg ("aria2c version: %s".printf (tool_version.version));
        } else {
            tool_version = new Version ("1.19"); // assume
        }
    }

    // execution ----------------------------

    public void add_to_queue (DownloadItem item) {
        MiscHelper misc_helper = new MiscHelper ();

        item.task = this;
        downloads.add (item);

        // set gid - 16 character hex string in lowercase

        do {
            item.gid = misc_helper.random_string (16, "0123456789abcdef").down ();
        } while (map.has_key (item.gid_key));

        map[item.gid_key] = item;
    }

    public void clear_queue () {
        downloads.clear ();
        map.clear ();
    }

    public void execute () {
        prepare ();
        begin ();

        if (status == AppStatus.RUNNING) {
        }
    }

    public void prepare () {
        ProcessHelper process_helper = new ProcessHelper ();
        string script_text = build_script ();
        process_helper.save_bash_script_temp (script_text, script_file);
    }

    private string build_script () {
        LoggingHelper logging_helper = new LoggingHelper ();
        ProcessHelper process_helper = new ProcessHelper ();
        FileHelper file_helper = new FileHelper ();

        string cmd = "";
        var command = "wget";
        var cmd_path = process_helper.get_cmd_path ("aria2c");

        if ((cmd_path != null) && (cmd_path.length > 0)) {
            command = "aria2c";
        }

        if (command == "aria2c") {
            string list = "";
            string list_file = file_helper.path_combine (working_dir, "download.list");
            foreach (var item in downloads) {
                list += "%s\n".printf (item.source_uri);
                list += "  gid=%s\n".printf (item.gid);
                list += "  dir=%s\n".printf (item.partial_dir);
                list += "  out=%s\n".printf (item.file_name);
            }

            file_helper.file_write (list_file, list);
            logging_helper.log_debug ("saved download list: %s".printf (list_file));

            cmd += "aria2c";
            cmd += " -i '%s'".printf (file_helper.escape_single_quote (list_file));
            cmd += " --show-console-readout=false";
            cmd += " --summary-interval=1";
            cmd += " --auto-save-interval=1"; // save aria2 control file every sec
            cmd += " --human-readable=false";

            if (tool_version.is_minimum ("1.19")) {
                cmd += " --enable-color=false"; // enabling color breaks the output parsing
            }

            cmd += " --allow-overwrite";
            cmd += " --connect-timeout=%d".printf (connect_timeout_secs);
            cmd += " --timeout=%d".printf (timeout_secs);
            cmd += " --max-concurrent-downloads=%d".printf (concurrent_downloads);
            // cmd += " --continue"; // never use - this is for continuing files downloaded sequentially by web browser and other programs
            // cmd += " --optimize-concurrent-downloads=true"; // not supported by all versions
            // cmd += " -l download.log"; // too much logging
            // cmd += " --direct-file-mapping=false"; // not required
            // cmd += " --dry-run";
        }

        logging_helper.log_debug (cmd);

        return cmd;
    }

    public override void parse_stdout_line (string out_line) {
        if (is_terminated) {
            return;
        }

        update_progress_parse_console_output (out_line);
    }

    public override void parse_stderr_line (string err_line) {
        if (is_terminated) {
            return;
        }

        update_progress_parse_console_output (err_line);
    }

    public bool update_progress_parse_console_output (string line) {
        if ((line == null) || (line.length == 0)) {
            return true;
        }

        // log_debug(line);

        MatchInfo match;

        if (regex["file-complete"].match (line, 0, out match)) {
            // log_debug("match: file-complete: " + line);
            prg_count++;
        } else if (regex["file-status"].match (line, 0, out match)) {

            // 8ae3a3|OK  |    16KiB/s|/home/teejee/.cache/noyau/v4.0.7-wily/index.html

            // log_debug("match: file-status: " + line);

            // always display
            // log_debug(line);

            string gid_key = match.fetch (1).strip ();
            string status = match.fetch (2).strip ();
            int64 rate = int64.parse (match.fetch (3).strip ());
            // string file = match.fetch(4).strip();

            if (map.has_key (gid_key)) {
                map[gid_key].rate = rate;
                map[gid_key].status = status;
            }
        } else if (regex["file-progress"].match (line, 0, out match)) {

            // log_debug("match: file-progress: " + line);

            // Note: HTML files don't have content length, so bytes_total will be 0

            var gid_key = match.fetch (1).strip ();
            var received = int64.parse (match.fetch (2).strip ());
            var total = int64.parse (match.fetch (3).strip ());
            // var percent = double.parse(match.fetch(4).strip());
            var rate = int64.parse (match.fetch (5).strip ());
            var eta = match.fetch (6).strip ();

            if (map.has_key (gid_key)) {
                var item = map[gid_key];
                item.bytes_received = received;
                if (item.bytes_total == 0) {
                    item.bytes_total = total;
                }
                item.rate = rate;
                item.eta = eta;
                item.status = "RUNNING";

                status_line = item.status_line ();
            }

            // log_debug(status_line);
        } else {
            // log_debug("unmatched: '%s'".printf(line));
        }

        return true;
    }

    protected override void finish_task () {
        FileHelper file_helper = new FileHelper ();
        verify ();
        file_helper.dir_delete (working_dir);
    }

    private void verify () {
        LoggingHelper logging_helper = new LoggingHelper ();
        FileHelper file_helper = new FileHelper ();

        logging_helper.log_debug ("verify()");

        foreach (var item in downloads) {

            if (!file_helper.file_exists (item.file_path_partial)) {
                logging_helper.log_debug ("verify: file_path_partial not found: %s".printf (item.file_path_partial));
                continue;
            }

            // log_msg("status=%s".printf(item.status));

            if (item.status == "OK") {
                file_helper.file_move (item.file_path_partial, item.file_path);
            } else {
                file_helper.file_delete (item.file_path_partial);
            }
        }
    }

    public int read_status () {
        FileHelper file_helper = new FileHelper ();

        var status_file = working_dir + "/status";
        var f = File.new_for_path (status_file);
        if (f.query_exists ()) {
            var txt = file_helper.file_read (status_file);
            return int.parse (txt);
        }
        return -1;
    }
}
