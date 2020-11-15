install_data(
    join_paths(meson.project_name() + '.desktop'),
    install_dir: join_paths(get_option('datadir'), 'applications')
)

install_data(
    join_paths(meson.project_name() + '.appdata.xml'),
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

install_data(
    join_paths(meson.project_name() + '.pkexec.policy'),
    install_dir: join_paths(get_option('datadir'), 'polkit-1', 'actions')
)

subdir('images')
subdir('pixmaps')

