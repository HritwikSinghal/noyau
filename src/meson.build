project_files = files(
    'App.vala',

    'Models/DownloadItem.vala',
    'Models/LinuxKernel.vala',
    'Models/OSDNotify.vala',
    'Models/Package.vala',
    'Models/Version.vala',
    'Models/AsyncTask.vala',

    'Views/AboutWindow.vala',
    'Views/MainWindow.vala',
    'Views/ProgressWindow.vala',
    'Views/SettingsDialog.vala',
    'Views/TerminalWindow.vala',
    'Views/UpdateNotificationDialog.vala',

    'Helpers/GtkHelper.vala',
    'Helpers/DownloadHelper.vala',
    'Helpers/JsonHelper.vala',
    'Helpers/FileHelper.vala',
    'Helpers/LoggingHelper.vala',
    'Helpers/MiscHelper.vala',
    'Helpers/ProcessHelper.vala',
    'Helpers/SystemHelper.vala'
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

