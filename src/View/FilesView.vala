/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021-2024 Ryo Nakano <ryonakaknock3@gmail.com>
 */

public class View.FilesView : Adw.NavigationPage {
    public signal void new_activated ();
    public signal void deleted (bool is_success);
    public signal void selected (Model.DesktopFile file);

    private ListStore list_store;

    public FilesView () {
    }

    construct {
        list_store = new ListStore (typeof (Model.DesktopFile));

        var headerbar = setup_headerbar ();
        var content = setup_content ();

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (headerbar);
        toolbar_view.set_content (content);

        title = Define.APP_NAME;
        child = toolbar_view;
        width_request = 350;
    }

    private Gtk.Widget setup_headerbar () {
        var create_button = new Gtk.Button.from_icon_name ("list-add-symbolic") {
            tooltip_text = _("Create a new entry")
        };

        // Construct the settings menu
        var theme_submenu = new GLib.Menu ();
        // See https://valadoc.org/gio-2.0/GLib.Action.parse_detailed_name.html for the format
        theme_submenu.append (_("S_ystem"), "app.color-scheme(\"%s\")".printf (Define.ColorScheme.DEFAULT));
        theme_submenu.append (_("_Light"), "app.color-scheme(\"%s\")".printf (Define.ColorScheme.FORCE_LIGHT));
        theme_submenu.append (_("_Dark"), "app.color-scheme(\"%s\")".printf (Define.ColorScheme.FORCE_DARK));

        var menu = new GLib.Menu ();
        menu.append_submenu (_("_Style"), theme_submenu);
        menu.append (_("_Keyboard Shortcuts"), "win.show-help-overlay");
        // Pantheon prefers AppCenter instead of an about dialog for app details, so prevent it from being shown on Pantheon
        if (!Application.IS_ON_PANTHEON) {
            ///TRANSLATORS: %s will be replaced by the app name (Pin It!)
            menu.append (_("_About %s").printf (Define.APP_NAME), "app.about");
        }

        var menu_button = new Gtk.MenuButton () {
            tooltip_text = _("Main Menu"),
            icon_name = "open-menu-symbolic",
            menu_model = menu,
            primary = true
        };

        var headerbar = new Adw.HeaderBar ();
        headerbar.pack_start (create_button);
        headerbar.pack_end (menu_button);

        create_button.clicked.connect (() => {
            new_activated ();
        });

        return headerbar;
    }

    private Gtk.Widget setup_content () {
        // NoFilesPage: Shown when no desktop files available.
        var no_files_page = new Adw.StatusPage () {
            title = _("No Entries Found"),
            description = _("Click the + button on the top to create one."),
            icon_name = "dialog-information",
            vexpand = true,
            hexpand = true
        };

        // FilesListPage: The page to list available desktop files.
        var files_list = new Gtk.ListBox ();
        files_list.set_placeholder (no_files_page);
        files_list.bind_model (list_store, create_files_row);
        files_list.add_css_class ("navigation-sidebar");

        // Pack into a scrolled window in case there are many desktop files in the files list
        var files_list_page = new Gtk.ScrolledWindow () {
            child = files_list,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vexpand = true,
            hexpand = true
        };

        return files_list_page;
    }

    public void set_list_data (Gee.ArrayList<Model.DesktopFile> list) {
        list_store.remove_all ();

        list.foreach ((item) => {
            list_store.append (item);
            return true;
        });
    }

    private Gtk.Widget create_files_row (Object item) {
        var file = item as Model.DesktopFile;

        var app_icon = new Gtk.Image.from_gicon (new ThemedIcon ("application-x-executable")) {
            pixel_size = 48,
            margin_top = 6,
            margin_bottom = 6
        };
        try {
            app_icon.gicon = Icon.new_for_string (file.get_string (KeyFileDesktop.KEY_ICON));
        } catch (Error err) {
            warning ("Failed to update app_icon: %s", err.message);
        }

        string locale = file.get_locale_for_key (KeyFileDesktop.KEY_NAME, Application.preferred_language);
        string app_name = file.get_locale_string (KeyFileDesktop.KEY_NAME, locale);

        locale = file.get_locale_for_key (KeyFileDesktop.KEY_COMMENT, Application.preferred_language);
        string comment = file.get_locale_string (KeyFileDesktop.KEY_COMMENT, locale);

        var delete_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic") {
            tooltip_text = _("Delete…"),
            valign = Gtk.Align.CENTER
        };
        delete_button.add_css_class ("flat");
        delete_button.clicked.connect (() => {
            var delete_dialog = setup_delete_dialog (app_name);

            delete_dialog.response.connect ((response_id) => {
                if (response_id != Define.DialogResponse.OK) {
                    return;
                }

                bool ret = file.delete_file ();
                if (!ret) {
                    var error_dialog = new Adw.MessageDialog (
                        (Gtk.Window) get_root (),
                        _("Failed to Delete Entry of “%s”").printf (app_name),
                        _("There was an error while removing the app entry.")
                    );

                    error_dialog.add_response (Define.DialogResponse.CLOSE, _("_Close"));

                    error_dialog.default_response = Define.DialogResponse.CLOSE;
                    error_dialog.close_response = Define.DialogResponse.CLOSE;

                    error_dialog.present ();
                }

                deleted (ret);
    
                delete_dialog.destroy ();
            });

            delete_dialog.present ();
        });

        var row = new Adw.ActionRow () {
            title = app_name,
            subtitle = comment,
            title_lines = 1,
            subtitle_lines = 1,
            activatable = true
        };
        row.add_prefix (app_icon);
        row.add_suffix (delete_button);
        row.activated.connect (() => {
            selected (file);
        });

        return row;
    }

    private Adw.MessageDialog setup_delete_dialog (string app_name) {
        string dialog_title = _("Delete Entry?");
        if (app_name != "") {
            dialog_title = _("Delete Entry of “%s”?").printf (app_name);
        }

        var delete_dialog = new Adw.MessageDialog (
            (Gtk.Window) get_root (),
            dialog_title,
            _("This removes the app from the launcher.")
        );

        delete_dialog.add_response (Define.DialogResponse.CANCEL, _("_Cancel"));
        delete_dialog.add_response (Define.DialogResponse.OK, _("_Delete"));

        delete_dialog.set_response_appearance (Define.DialogResponse.OK, Adw.ResponseAppearance.DESTRUCTIVE);

        delete_dialog.default_response = Define.DialogResponse.CANCEL;
        delete_dialog.close_response = Define.DialogResponse.CANCEL;

        return delete_dialog;
    }
}
