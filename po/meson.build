 i18n = import('i18n')

langs = ['de','fr','lt','pt_PT']

# Stolen from gnome-twitch
i18n.gettext('budgie-calendar-applet', languages: langs, args: [
    '--from-code=UTF-8',
    '--add-comments',

    '--keyword=_',
    '--keyword=N_',
    '--keyword=C_:1c,2',
    '--keyword=NC_:1c,2',
    '--keyword=g_dcgettext:2',
    '--keyword=g_dngettext:2,3',
    '--keyword=g_dpgettext2:2c,3'
])
