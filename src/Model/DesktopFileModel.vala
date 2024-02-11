/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021-2024 Ryo Nakano <ryonakaknock3@gmail.com>
 *
 * Inspired from:
 * - https://github.com/elementary/switchboard-plug-keyboard/blob/caef4fd900b41c669d48fc1c91eced6a89709f62/src/Views/InputMethod.vala#L369
 * - https://github.com/pantheon-tweaks/pantheon-tweaks/blob/7d366f5e4774175be2d7177d1b8486e0c97d7bfe/src/Settings/ThemeSettings.vala#L62
 */

/**
 * The class to load desktop files and stores in the form of {@link DesktopFile} class.
 */
public class DesktopFileModel : Object {
    /**
     * Notifies loading desktop files succeeded.
     */
    public signal void load_success ();

    /**
     * Notifies loading desktop files failed.
     */
    public signal void load_failure ();

    /**
     * List of {@link DesktopFile}.
     */
    public ListStore files_list { get; private set; }

    /**
     * The representation of the {@link desktop_files_path} in the File type.
     */
    private File desktop_files_dir;

    public DesktopFileModel () {
    }

    construct {
        files_list = new ListStore (typeof (DesktopFile));

        string desktop_files_path = Path.build_filename (Environment.get_home_dir (), ".local/share/applications");
        desktop_files_dir = File.new_for_path (desktop_files_path);

        // Create the desktop files directory if not exists
        if (!FileUtils.test (desktop_files_path, FileTest.EXISTS)) {
            try {
                desktop_files_dir.make_directory_with_parents ();
            } catch (Error e) {
                warning (e.message);
            }
        }
    }

    /**
     * Search for desktop files and stores in the {@link DesktopFile} data type.
     *
     * Search ~/.local/share/applications for files with .desktop suffix. Create a new
     * {@link DesktopFile} if a matching file found and is valid. Repeat this for all files in the directory
     * and then return the list of {@link DesktopFile}.
     *
     * Emits {@link DesktopFileModel.load_success} if loaded successfully, {@link DesktopFileModel.load_failure}
     * otherwise.
     */
    public void load () {
        files_list.remove_all ();

        try {
            var enumerator = desktop_files_dir.enumerate_children (FileAttribute.STANDARD_NAME, FileQueryInfoFlags.NONE);
            FileInfo file_info = null;

            // Check and address the files in the desktop_files_path directory one by one
            while ((file_info = enumerator.next_file ()) != null) {
                // We handle only the desktop file in this app, so ignore any files without the .desktop suffix
                string name = file_info.get_name ();
                if (!name.has_suffix (DesktopFile.DESKTOP_SUFFIX)) {
                    continue;
                }

                File relative_path = desktop_files_dir.resolve_relative_path (name);
                string path = relative_path.get_path ();

                var file = new DesktopFile (path);
                bool ret = file.load_file ();
                // Skip adding to the list if we fail to load.
                if (!ret) {
                    continue;
                }

                files_list.append (file);
            }
        } catch (Error e) {
            warning (e.message);
            load_failure ();
            return;
        }

        load_success ();
    }
}
