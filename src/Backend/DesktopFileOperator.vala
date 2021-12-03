/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 Ryo Nakano <ryonakaknock3@gmail.com>
 *
 * Inspired from:
 * - elementary/switchboard-plug-keyboard, #374
 * - pantheon-tweaks/pantheon-tweaks, src/Settings/ThemeSettings.vala
 */

public class DesktopFileOperator : GLib.Object {
    public signal void file_updated ();

    private string DESTINATION_PATH {
        get;
        default = "/home/%s/.local/share/applications".printf (Environment.get_user_name ());
    }

    private string UNSAVED_FILE_PATH {
        get;
        default = "%s/unsaved.desktop".printf (Environment.get_user_cache_dir ());
    }

    private Gee.ArrayList<DesktopFile> _files = new Gee.ArrayList<DesktopFile> ();
    public Gee.ArrayList<DesktopFile> files {
        get {
            _files.clear ();

            try {
                var emumerator = desktop_dir.enumerate_children (FileAttribute.STANDARD_NAME, FileQueryInfoFlags.NONE);
                FileInfo file_info = null;
                while ((file_info = emumerator.next_file ()) != null) {
                    string name = file_info.get_name ();
                    if (!name.has_suffix (".desktop")) {
                        continue;
                    }

                    var desktop_file = load_from_file (Path.build_filename (DESTINATION_PATH, name));
                    _files.add (desktop_file);
                }
            } catch (Error e) {
                warning (e.message);
            }

            return _files;
        }
    }

    private string preferred_language;
    private File desktop_dir;

    private static DesktopFileOperator _instance;
    public static DesktopFileOperator get_default () {
        if (_instance == null) {
            _instance = new DesktopFileOperator ();
        }

        return _instance;
    }

    private DesktopFileOperator () {
        var languages = Intl.get_language_names ();
        preferred_language = languages[0];

        desktop_dir = File.new_for_path (DESTINATION_PATH);
        if (!FileUtils.test (DESTINATION_PATH, FileTest.EXISTS)) {
            try {
                desktop_dir.make_directory_with_parents ();
            } catch (Error e) {
                warning (e.message);
                return;
            }
        }
    }

    public void write_to_file (DesktopFile desktop_file, bool is_unsaved_file = false) {
        // Add exec permission to the exec file
        Posix.chmod (desktop_file.exec_file, 0700);

        var keyfile = new KeyFile ();
        keyfile.set_locale_string (
            KeyFileDesktop.GROUP, KeyFileDesktop.KEY_NAME, preferred_language, desktop_file.app_name
        );
        keyfile.set_locale_string (
            KeyFileDesktop.GROUP, KeyFileDesktop.KEY_COMMENT, preferred_language, desktop_file.comment
        );
        keyfile.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_EXEC, desktop_file.exec_file);
        keyfile.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_ICON, desktop_file.icon_file);
        keyfile.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_CATEGORIES, desktop_file.categories);
        keyfile.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_TYPE, "Application");
        keyfile.set_boolean (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_TERMINAL, desktop_file.is_cli);

        string path;
        if (is_unsaved_file) {
            path = UNSAVED_FILE_PATH;
        } else {
            path = Path.build_filename (DESTINATION_PATH, desktop_file.file_name + ".desktop");
        }

        // Create or update desktop file
        try {
            FileUtils.set_contents (path, keyfile.to_data ());
        } catch (Error e) {
            warning ("Could not write to file %s: %s", path, e.message);
        }

        file_updated ();
    }

    public DesktopFile load_from_file (string path) {
        string file_name = "";
        string app_name = "";
        string comment = "";
        string exec_file = "";
        string icon_file = "";
        string categories = "";
        bool is_cli = false;

        try {
            var keyfile = new KeyFile ();
            keyfile.load_from_file (path, KeyFileFlags.KEEP_TRANSLATIONS);
            string[] splited_path = path.split ("/");
            string basename = splited_path[splited_path.length - 1];

            file_name = basename.slice (0, basename.length - ".desktop".length);
            app_name = keyfile.get_locale_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_NAME, preferred_language);
            comment = keyfile.get_locale_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_COMMENT, preferred_language);
            exec_file = keyfile.get_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_EXEC);
            icon_file = keyfile.get_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_ICON);
            categories = keyfile.get_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_CATEGORIES);
            is_cli = keyfile.get_boolean (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_TERMINAL);
        } catch (KeyFileError e) {
            warning (e.message);
        } catch (FileError e) {
            warning (e.message);
        }

        var desktop_file = new DesktopFile (
            file_name,
            app_name,
            comment,
            exec_file,
            icon_file,
            categories,
            is_cli
        );

        return desktop_file;
    }

    public DesktopFile? get_unsaved_file () {
        return Application.settings.get_boolean ("has-unsaved-file") ? load_from_file (UNSAVED_FILE_PATH) : null;
    }

    public void delete_file (DesktopFile desktop_file) {
        string path = Path.build_filename (DESTINATION_PATH, desktop_file.file_name + ".desktop");
        var file = File.new_for_path (path);

        try {
            file.delete ();
        } catch (Error e) {
            warning ("Could not delete file %s: %s", path, e.message);
        }
    }
}
