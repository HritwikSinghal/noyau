project(
    'ukuu',
    'vala', 'c',
    version: '18.10',
    meson_version: '>=0.46.0'
)

add_project_arguments([
        '-X',
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
        '-D VTE_291'
    ],
    language: 'c'
)

subdir('data')
subdir('docs')
subdir('po')
subdir('src')
