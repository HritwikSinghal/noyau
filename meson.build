project(
    'noyau',
    'vala', 'c',
    version: '19.10',
    meson_version: '>=0.40.1',
    license : 'GPLv2'
)

add_project_arguments([
        '-DGETTEXT_PACKAGE="noyau"',
        '-D VTE_291'
    ],
    language: 'c'
)

config_data = configuration_data()
config_data.set('EXEC_NAME', meson.project_name())
config_data.set_quoted('PROJECT_NAME', meson.project_name())
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_data.set_quoted('VERSION', meson.project_version())
config_data.set_quoted('PACKAGE_DATADIR', join_paths(get_option('prefix'), join_paths(get_option('datadir'), 'noyau')))

config_header = configure_file(
    output : 'config.h',
    configuration : config_data
)

subdir('data')
subdir('po')
subdir('src')

meson.add_install_script('meson/post_install.py')
