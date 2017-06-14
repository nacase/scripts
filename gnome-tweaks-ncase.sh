# Automated script to set Gnome desktop preferences so I don't have to 
# tweak a ton of things every time I install a new system
#
# Author: Nate Case

# $1: name, e.g., "custom-name0", $2: shortcut, e.g., "<Control><Alt>t"
# $3: command, e.g., "gnome-terminal"
add_cust_kb_shortcut() {
    name="$1"
    shortcut="$2"
    cmd="$3"
    MEDIA_KEYS_SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
    MEDIA_KEYS_PATH="/org/gnome/settings-daemon/plugins/media-keys"
    
    # Check if keybinding already exists
    # e.g., ['/org/blah/blah/custom-X/', '/org/blah/blah/custom-Y/'
    # (last bracket stripped)
    EXISTING_KEYS=$(gsettings get ${MEDIA_KEYS_SCHEMA} custom-keybindings | grep -oE "\[[^]]*")
    echo "${EXISTING_KEYS}" | grep -qE "${name}"
    if [ $? = 0 ] ; then
        echo "Custom keybinding '${name}' already present.  Skipping"
	return 0
    fi
    
    # Add new keybindings (
    if [ "${EXISTING_KEYS}" = "[" ] ; then
        CKB_NEW_VAL="['${MEDIA_KEYS_PATH}/custom-keybindings/${name}/']"
    else
        CKB_NEW_VAL="${EXISTING_KEYS},'${MEDIA_KEYS_PATH}/custom-keybindings/${name}/']"
    fi
    echo "Adding custom keybinding '${name}'"
    gsettings set ${MEDIA_KEYS_SCHEMA} custom-keybindings "${CKB_NEW_VAL}"
    gsettings set ${MEDIA_KEYS_SCHEMA}.custom-keybinding:${MEDIA_KEYS_PATH}/custom-keybindings/${name}/ name "${name}"
    gsettings set ${MEDIA_KEYS_SCHEMA}.custom-keybinding:${MEDIA_KEYS_PATH}/custom-keybindings/${name}/ command "${cmd}"
    gsettings set ${MEDIA_KEYS_SCHEMA}.custom-keybinding:${MEDIA_KEYS_PATH}/custom-keybindings/${name}/ binding "${shortcut}"
}

# CTRL-ALT-T for terminal
add_cust_kb_shortcut "custom-term0" "<Control><Alt>t" "gnome-terminal"
# CTRL-ALT-P for interactive Python calculator
add_cust_kb_shortcut "custom-calc0" "<Control><Alt>p" "gnome-terminal --name=\"Python calculator\" -e /home/$USER/bin/cmpe.py"
# F12 to mute headphones
add_cust_kb_shortcut "custom-mute0" "F12" "/home/$USER/bin/mute.sh"
# F9/F10 for volume down/up
add_cust_kb_shortcut "custom-voldown0" "F9" "/home/$USER/bin/voldown.sh"
add_cust_kb_shortcut "custom-volup0" "F10" "/home/$USER/bin/volup.sh"


# Lock screen with F11
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "F11"

# Workspace / virtual desktop preferences
gsettings set org.gnome.shell.overrides workspaces-only-on-primary true
gsettings set org.gnome.mutter workspaces-only-on-primary true
gsettings set org.gnome.shell.overrides dynamic-workspaces false
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces "5"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['F1']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['F2']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['F3']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['F4']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['F5']"

# Use okular as default PDF viewer
cp /usr/share/applications/kde4/okular.desktop ~/.local/share/applications/
xdg-mime default okular.desktop application/pdf

# Disable unwanted window animations
gsettings set org.gnome.desktop.interface enable-animations false

# gnome-terminal tweaks
gtprof=$(gsettings get org.gnome.Terminal.ProfilesList default)
gtprof=${gtprof:1:-1} # remove leading and trailing single quotes
gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$gtprof/" use-theme-colors false
gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$gtprof/" background-color "rgb(0,0,0)"
gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$gtprof/" foreground-color "rgb(170,170,170)"
gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$gtprof/" scrollback-lines 100000

