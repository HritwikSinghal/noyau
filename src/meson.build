config_data = configuration_data()
config_data.set_quoted('PROJECT_NAME', meson.project_name())
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_data.set_quoted('_VERSION', meson.project_version())
config_data.set_quoted('PACKAGE_DATADIR', join_paths(get_option('prefix'), join_paths(get_option('datadir'), 'ukuu')))

config_header = configure_file(
    output : 'config.h',
    configuration : config_data
)

project_files = files(
    'Common/Main.vala',
    'Common/LinuxKernel.vala',
    'Common/DownloadManager.vala',
    'Common/Package.vala',

    'Gtk/AboutWindow.vala',
    'Gtk/AppGtk.vala',
    'Gtk/MainWindow.vala',
    'Gtk/ProgressWindow.vala',
    'Gtk/SettingsDialog.vala',
    'Gtk/TerminalWindow.vala',
    'Gtk/UpdateNotificationDialog.vala',

    'Utility/Gtk/GtkHelper.vala',

    'Utility/AppLock.vala',
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

project_files_cli = files(
    'Common/Main.vala',
    'Common/LinuxKernel.vala',
    'Common/DownloadManager.vala',
    'Common/Package.vala',

    'Console/AppConsole.vala',

    'Utility/AppLock.vala',
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

executable(
    meson.project_name() + '-cli',
    project_files_cli,
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
    install: true
)
