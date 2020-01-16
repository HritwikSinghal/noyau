/*
 * TeeJee.Process.vala
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

using GLib;

public class ProcessHelper : GLib.Object {

    /* Convenience functions for executing commands and managing processes */

    public static string TEMP_DIR;

    public ProcessHelper () {
    }

    // execute process ---------------------------------

    public void init_tmp (string subdir_name) {
        MiscHelper misc_helper = new MiscHelper ();
        FileHelper file_helper = new FileHelper ();
        LoggingHelper logging_helper = new LoggingHelper ();

        string std_out, std_err;

        TEMP_DIR = Environment.get_tmp_dir () + "/" + subdir_name + "/" + misc_helper.random_string ();
        file_helper.dir_create (TEMP_DIR);

        exec_script_sync ("echo 'ok'", out std_out, out std_err, true);
        if ((std_out == null) || (std_out.strip () != "ok")) {
            TEMP_DIR = Environment.get_home_dir () + "/.temp/" + subdir_name + "/" + misc_helper.random_string ();
            exec_sync ("rm -rf '%s'".printf (TEMP_DIR), null, null);
            file_helper.dir_create (TEMP_DIR);
        }

        logging_helper.log_debug ("TEMP_DIR=" + TEMP_DIR);
    }

    public string create_temp_subdir (string base_dir = "") {
        MiscHelper misc_helper = new MiscHelper ();
        FileHelper file_helper = new FileHelper ();

        var temp = "%s/%s".printf ((base_dir.length > 0) ? base_dir : TEMP_DIR, misc_helper.random_string ());
        file_helper.dir_create (temp);
        return temp;
    }

    public int exec_sync (string cmd, out string ? std_out = null, out string ? std_err = null) {

        /* Executes single command synchronously.
         * Pipes and multiple commands are not supported.
         * std_out, std_err can be null. Output will be written to terminal if null. */

        LoggingHelper logging_helper = new LoggingHelper ();

        try {
            int status;
            Process.spawn_command_line_sync (cmd, out std_out, out std_err, out status);
            return status;
        } catch (Error e) {
            logging_helper.log_error (e.message);
            return -1;
        }
    }

    public int exec_script_sync (string script,
                                 out string ? std_out = null, out string ? std_err = null,
                                 bool supress_errors = false, bool run_as_admin = false,
                                 bool cleanup_tmp = true, bool print_to_terminal = false) {

        /* Executes commands synchronously.
         * Pipes and multiple commands are fully supported.
         * Commands are written to a temporary bash script and executed.
         * std_out, std_err can be null. Output will be written to terminal if null.
         * */

        FileHelper file_helper = new FileHelper ();
        LoggingHelper logging_helper = new LoggingHelper ();

        string sh_file = save_bash_script_temp (script, null, true, supress_errors);
        string sh_file_admin = "";

        if (run_as_admin) {

            var script_admin = "#!/bin/bash\n";
            script_admin += "pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY";
            script_admin += " '%s'".printf (file_helper.escape_single_quote (sh_file));

            sh_file_admin = GLib.Path.build_filename (file_helper.file_parent (sh_file), "script-admin.sh");

            save_bash_script_temp (script_admin, sh_file_admin, true, supress_errors);
        }

        try {
            string[] argv = new string[1];
            if (run_as_admin) {
                argv[0] = sh_file_admin;
            } else {
                argv[0] = sh_file;
            }

            string[] env = Environ.get ();

            int exit_code;

            if (print_to_terminal) {

                Process.spawn_sync (
                    TEMP_DIR, // working dir
                    argv, // argv
                    env, // environment
                    SpawnFlags.SEARCH_PATH,
                    null, // child_setup
                    null,
                    null,
                    out exit_code
                );
            } else {

                Process.spawn_sync (
                    TEMP_DIR, // working dir
                    argv, // argv
                    env, // environment
                    SpawnFlags.SEARCH_PATH,
                    null, // child_setup
                    out std_out,
                    out std_err,
                    out exit_code
                );
            }

            if (cleanup_tmp) {
                file_helper.file_delete (sh_file);
                if (run_as_admin) {
                    file_helper.file_delete (sh_file_admin);
                }
            }

            return exit_code;
        } catch (Error e) {
            if (!supress_errors) {
                logging_helper.log_error (e.message);
            }
            return -1;
        }
    }

    public int exec_script_async (string script) {

        /* Executes commands synchronously.
         * Pipes and multiple commands are fully supported.
         * Commands are written to a temporary bash script and executed.
         * Return value indicates if script was started successfully.
         *  */

        LoggingHelper logging_helper = new LoggingHelper ();

        try {

            string scriptfile = save_bash_script_temp (script);

            string[] argv = new string[1];
            argv[0] = scriptfile;

            string[] env = Environ.get ();

            Pid child_pid;
            Process.spawn_async_with_pipes (
                TEMP_DIR, // working dir
                argv, // argv
                env, // environment
                SpawnFlags.SEARCH_PATH,
                null,
                out child_pid);

            return 0;
        } catch (Error e) {
            logging_helper.log_error (e.message);
            return 1;
        }
    }

    public string ? save_bash_script_temp (string commands, string ? script_path = null,
                                           bool force_locale = true, bool supress_errors = false) {

        string sh_path = script_path;

        /* Creates a temporary bash script with given commands
         * Returns the script file path */

        FileHelper file_helper = new FileHelper ();
        LoggingHelper logging_helper = new LoggingHelper ();

        var script = new StringBuilder ();
        script.append ("#!/bin/bash\n");
        script.append ("\n");
        if (force_locale) {
            script.append ("LANG=C\n");
        }
        script.append ("\n");
        script.append ("%s\n".printf (commands));
        script.append ("\n\nexitCode=$?\n");
        script.append ("echo ${exitCode} > ${exitCode}\n");
        script.append ("echo ${exitCode} > status\n");

        if ((sh_path == null) || (sh_path.length == 0)) {
            sh_path = get_temp_file_path () + ".sh";
        }

        try {
            // write script file
            var file = File.new_for_path (sh_path);
            if (file.query_exists ()) {
                file.delete ();
            }

            var file_stream = file.create (FileCreateFlags.REPLACE_DESTINATION);
            var data_stream = new DataOutputStream (file_stream);
            data_stream.put_string (script.str);
            data_stream.close ();

            // set execute permission
            file_helper.chmod (sh_path, "u+x");

            return sh_path;
        } catch (Error e) {
            if (!supress_errors) {
                logging_helper.log_error (e.message);
            }
        }

        return null;
    }

    /* Generates temporary file path */
    public string get_temp_file_path () {
        MiscHelper misc_helper = new MiscHelper ();
        return TEMP_DIR + "/" + misc_helper.timestamp_numeric () + (new Rand ()).next_int ().to_string ();
    }

    // find process -------------------------------

    // dep: which
    public string get_cmd_path (string cmd_tool) {

        /* Returns the full path to a command */

        LoggingHelper logging_helper = new LoggingHelper ();

        try {
            int exitCode;
            string stdout, stderr;
            Process.spawn_command_line_sync ("which " + cmd_tool, out stdout, out stderr, out exitCode);
            return stdout;
        } catch (Error e) {
            logging_helper.log_error (e.message);
            return "";
        }
    }

    // dep: pidof, TODO: Rewrite using /proc
    public int get_pid_by_name (string name) {

        /* Get the process ID for a process with given name */

        string std_out, std_err;
        exec_sync ("pidof \"%s\"".printf (name), out std_out, out std_err);

        if (std_out != null) {
            string[] arr = std_out.split ("\n");
            if (arr.length > 0) {
                return int.parse (arr[0]);
            }
        }

        return -1;
    }

    // dep: ps TODO: Rewrite using /proc
    public int[] get_process_children (Pid parent_pid) {

        /* Returns the list of child processes spawned by given process */

        string std_out, std_err;
        exec_sync ("ps --ppid %d".printf (parent_pid), out std_out, out std_err);

        int pid;
        int[] procList = {};
        string[] arr;

        foreach (string line in std_out.split ("\n")) {
            arr = line.strip ().split (" ");
            if (arr.length < 1) {
                continue;
            }

            pid = 0;
            pid = int.parse (arr[0]);

            if (pid != 0) {
                procList += pid;
            }
        }
        return procList;
    }

    // manage process ---------------------------------

    public void process_quit (Pid process_pid, bool killChildren = true) {

        /* Kills specified process and its children (optional).
         * Sends signal SIGTERM to the process to allow it to quit gracefully.
         * */

        int[] child_pids = get_process_children (process_pid);
        Posix.kill (process_pid, Posix.Signal.TERM);

        if (killChildren) {
            Pid childPid;
            foreach (long pid in child_pids) {
                childPid = (Pid) pid;
                Posix.kill (childPid, Posix.Signal.TERM);
            }
        }
    }

    // dep: kill
    public int process_pause (Pid procID) {

        /* Pause/Freeze a process */

        return exec_sync ("kill -STOP %d".printf (procID), null, null);
    }

    // dep: kill
    public int process_resume (Pid procID) {

        /* Resume/Un-freeze a process*/

        return exec_sync ("kill -CONT %d".printf (procID), null, null);
    }

    // process priority ---------------------------------------

    public void process_set_priority (Pid procID, int prio) {

        /* Set process priority */

        if (Posix.getpriority (Posix.PRIO_PROCESS, procID) != prio)
            Posix.setpriority (Posix.PRIO_PROCESS, procID, prio);
    }
}
