project_files = files(
    'App.vala',

    'Gtk/AboutWindow.vala',
    'Gtk/MainWindow.vala',
    'Gtk/ProgressWindow.vala',
    'Gtk/SettingsDialog.vala',
    'Gtk/TerminalWindow.vala',
    'Gtk/UpdateNotificationDialog.vala',

    'Utility/Gtk/GtkHelper.vala',

    'Utility/LinuxKernel.vala',
    'Utility/DownloadManager.vala',
    'Utility/Package.vala',
    'Utility/AsyncTask.vala',
    'Utility/JsonHelper.vala',
    'Utility/OSDNotify.vala',
    'Utility/TeeJee.FileSystem.vala',
    'Utility/TeeJee.Logging.vala',
    'Utility/TeeJee.Misc.vala',
    'Utility/TeeJee.Process.vala',
    'Utility/TeeJee.System.vala',
    'Utility/Version.vala'
)

executable(
    meson.project_name(),
    project_files,
    dependencies: [
        dependency('gtk+-3.0'),
        dependency('gio-unix-2.0'),
        dependency('glib-2.0'),
        dependency('gee-0.8'),
        dependency('json-glib-1.0'),
        dependency('libsoup-2.4'),
        dependency('vte-2.91'),
        meson.get_compiler('vala').find_library('posix'),
        meson.get_compiler('c').find_library('m')
    ],
    c_args: [
        '-lm',
        '-ldl',
        '-pthread',
        '-lresolv'
    ],
    install: true
)

