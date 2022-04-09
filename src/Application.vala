/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021-2022 Ryo Nakano <ryonakaknock3@gmail.com>
 */

public class Application : Gtk.Application {
    public static bool IS_ON_PANTHEON {
        get {
            return GLib.Environment.get_variable ("XDG_CURRENT_DESKTOP") == "Pantheon";
        }
    }

    public static Settings settings;
    public MainWindow window { get; private set; }

    public Application () {
        Object (
            application_id: Constants.PROJECT_NAME,
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    construct {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (Constants.PROJECT_NAME, Constants.LOCALEDIR);
        Intl.bind_textdomain_codeset (Constants.PROJECT_NAME, "UTF-8");
        Intl.textdomain (Constants.PROJECT_NAME);
    }

    static construct {
        settings = new Settings (Constants.PROJECT_NAME);
    }

    protected override void activate () {
        if (window != null) { // The app is already launched
            window.present ();
            return;
        }

        window = new MainWindow ();
        window.set_application (this);

        int window_x, window_y, window_width, window_height;
        settings.get ("window-position", "(ii)", out window_x, out window_y);
        settings.get ("window-size", "(ii)", out window_width, out window_height);

        if (Application.settings.get_boolean ("window-maximized")) {
            window.maximize ();
        }

        if (window_x != -1 || window_y != -1) { // Not a first time launch
            window.move (window_x, window_y);
        } else { // First time launch
            window.window_position = Gtk.WindowPosition.CENTER;
        }

        window.resize (window_width, window_height);
    }

    public static int main (string[] args) {
        return new Application ().run ();
    }
}
