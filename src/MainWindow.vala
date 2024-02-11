/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021-2024 Ryo Nakano <ryonakaknock3@gmail.com>
 */

public class MainWindow : Adw.ApplicationWindow {
    private const ActionEntry[] ACTION_ENTRIES = {
        { "about", on_about_activate },
        { "new", on_new_activate },
    };

    private View.FilesView files_view;
    private View.EditView edit_view;
    private Adw.NavigationSplitView leaflet;

    private Model.DesktopFileModel model;
    private Model.DesktopFile desktop_file;
    private Model.DesktopFile backup_desktop_file;

    public MainWindow () {
        Object (
            // On Pantheon, the app name "Pin It!" is shown in Multitasking View by setting this
            title: Define.APP_NAME
        );
    }

    construct {
        add_action_entries (ACTION_ENTRIES, this);

        width_request = 450;
        height_request = 400;

        model = new Model.DesktopFileModel ();
        model.load ();

        /*
         * The two views are switched/holded using Leaflet
         */
        files_view = new View.FilesView (this, model.files_list);
        edit_view = new View.EditView (this);

        leaflet = new Adw.NavigationSplitView () {
            sidebar = files_view,
            content = edit_view
        };

        var breakpoint = new Adw.Breakpoint (
            new Adw.BreakpointCondition.length (Adw.BreakpointConditionLengthType.MAX_WIDTH, 800, Adw.LengthUnit.SP)
        );
        var val = Value (typeof (bool));
        val.set_boolean (true);
        breakpoint.add_setter (leaflet, "collapsed", val);
        add_breakpoint (breakpoint);

        var overlay = new Adw.ToastOverlay () {
            child = leaflet
        };

        var updated_toast = new Adw.Toast (_("Entry updated.")) {
            timeout = 5
        };

        var deleted_toast = new Adw.Toast (_("Entry deleted.")) {
            timeout = 5
        };

        content = overlay;

        model.load_failure.connect (on_load_failure);
        model.load_success.connect (on_load_success);

        files_view.new_activated.connect (() => {
            on_new_activate ();
        });

        files_view.deleted.connect ((is_success) => {
            desktop_file = null;
            backup_desktop_file = null;
            edit_view.hide_all ();
            model.load ();

            if (is_success) {
                overlay.add_toast (deleted_toast);
            }
        });

        files_view.selected.connect ((entry) => {
            show_edit_view (entry);
        });

        edit_view.file_updated.connect (() => {
            overlay.add_toast (updated_toast);
        });

        close_request.connect (() => {
            prep_destroy ();
            return Gdk.EVENT_STOP;
        });
    }

    private void on_load_failure () {
        var error_dialog = new Adw.MessageDialog (this,
                                                  _("Failed to Load Entries"),
                                                  _("There was an error while loading app entries.")
        );
        error_dialog.add_response (Define.DialogResponse.CLOSE, _("_Close"));
        error_dialog.default_response = Define.DialogResponse.CLOSE;
        error_dialog.close_response = Define.DialogResponse.CLOSE;
        error_dialog.present ();
    }

    private void on_load_success () {
        // NOP
    }

    public void prep_destroy () {
        // Never edited entries
        if (desktop_file == null || backup_desktop_file == null) {
            destroy ();
            return;
        }

        // No changes made
        if (desktop_file.equals (backup_desktop_file)) {
            destroy ();
            return;
        }

        var unsaved_dialog = new Adw.MessageDialog (this, _("Save Changes?"),
                                                    _("Open entries contain unsaved changes. Changes which are not saved will be permanently lost."));
        unsaved_dialog.add_css_class ("save-changes");
        unsaved_dialog.add_responses (Define.DialogResponse.CANCEL, _("_Cancel"),
                                      Define.DialogResponse.DISCARD, _("_Discard"),
                                      Define.DialogResponse.SAVE, _("_Save"));
        unsaved_dialog.set_response_appearance (Define.DialogResponse.DISCARD, Adw.ResponseAppearance.DESTRUCTIVE);
        unsaved_dialog.set_response_appearance (Define.DialogResponse.SAVE, Adw.ResponseAppearance.SUGGESTED);
        unsaved_dialog.response.connect ((response) => {
            if (response == Define.DialogResponse.CANCEL) {
                return;
            }

            if (response == Define.DialogResponse.SAVE) {
                edit_view.save_file ();
            }

            unsaved_dialog.destroy ();
            destroy ();
        });

        unsaved_dialog.present ();
    }

    public void show_files_view () {
        model.load ();
        leaflet.show_content = false;
    }

    public void show_edit_view (Model.DesktopFile file) {
        desktop_file = file;
        backup_desktop_file = new Model.DesktopFile.copy (file);

        edit_view.load_file (desktop_file);
        leaflet.show_content = true;
    }

    private void on_new_activate () {
        string filename = "pinit-" + Uuid.string_random ();
        string path = Path.build_filename (Environment.get_home_dir (), ".local/share/applications",
                                            filename + Model.DesktopFile.DESKTOP_SUFFIX);

        var file = new Model.DesktopFile (path);

        bool ret = file.save_file ();
        if (!ret) {
            return;
        }

        model.load ();
        show_edit_view (file);
    }

    private void on_about_activate () {
        const string[] DEVELOPERS = {
            "Ryo Nakano https://github.com/ryonakano",
            "Jeyson Flores https://github.com/JeysonFlores",
        };
        const string[] ARTISTS = {
            "hanaral https://github.com/hanaral",
        };

        var about_window = new Adw.AboutWindow () {
            transient_for = this,
            modal = true,
            application_icon = Constants.PROJECT_NAME,
            application_name = Define.APP_NAME,
            version = Constants.PROJECT_VERSION,
            comments = _("Pin portable apps to the launcher"),
            website = "https://github.com/ryonakano/pinit",
            support_url = "https://github.com/ryonakano/pinit/discussions",
            issue_url = "https://github.com/ryonakano/pinit/issues",
            copyright = "© 2021-2024 Ryo Nakano",
            license_type = Gtk.License.GPL_3_0,
            developer_name = "Ryo Nakano",
            developers = DEVELOPERS,
            artists = ARTISTS,
            ///TRANSLATORS: Replace with your name; don't translate literally
            translator_credits = _("translator-credits")
        };

        about_window.present ();
    }
}
