/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021-2024 Ryo Nakano <ryonakaknock3@gmail.com>
 */

public class FilesView : Adw.NavigationPage {
    public signal void create_new ();
    public signal void file_deleted (bool is_success);

    public MainWindow window { private get; construct; }

    private Adw.HeaderBar headerbar;
    private Gtk.ListBox files_list;
    private Gtk.Stack stack;

    public FilesView (MainWindow window) {
        Object (window: window);
    }

    construct {
        /*
         * Headerbar part
         */
        var create_button = new Gtk.Button.from_icon_name ("list-add-symbolic") {
            tooltip_text = _("Create a new entry")
        };

        // Construct the settings menu
        var theme_submenu = new GLib.Menu ();
        theme_submenu.append (_("Light"), "app.style-light");
        theme_submenu.append (_("Dark"), "app.style-dark");
        theme_submenu.append (_("System"), "app.style-system");

        var menu = new GLib.Menu ();
        menu.append_submenu (_("Style"), theme_submenu);
        menu.append (_("Keyboard Shortcuts"), "win.show-help-overlay");
        ///TRANSLATORS: %s will be replaced by the app name (Pin It!)
        menu.append (_("About %s").printf (Constants.APP_NAME), "win.about");

        var preferences_button = new Gtk.MenuButton () {
            tooltip_text = _("Preferences"),
            icon_name = "open-menu",
            menu_model = menu
        };

        headerbar = new Adw.HeaderBar ();
        headerbar.pack_start (create_button);
        headerbar.pack_end (preferences_button);

        /*
         * Content part
         */
        // FilesListPage: The page to list available desktop files.
        files_list = new Gtk.ListBox ();
        files_list.add_css_class ("navigation-sidebar");

        // Pack into a scrolled window in case there are many desktop files in the files list
        var files_list_page = new Gtk.ScrolledWindow () {
            child = files_list,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vexpand = true,
            hexpand = true
        };

        // NoFilesPage: Shown when no desktop files available.
        var no_files_page = new Adw.StatusPage () {
            title = _("No valid app entries found"),
            description = _("If you've never created one, click the + button on the top."),
            icon_name = "dialog-information",
            vexpand = true,
            hexpand = true
        };

        stack = new Gtk.Stack ();
        stack.add_named (files_list_page, "files_list_page");
        stack.add_named (no_files_page, "no_files_page");

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (headerbar);
        toolbar_view.set_content (stack);

        title = Constants.APP_NAME;
        child = toolbar_view;

        update_list ();

        create_button.clicked.connect (() => {
            create_new ();
        });
    }

    /*
     * Update the files list.
     */
    public void update_list () {
        // Clear all of the currently added entries
        for (
            var child = (Gtk.ListBoxRow) files_list.get_last_child ();
                child != null;
                child = (Gtk.ListBoxRow) files_list.get_last_child ()
        ) {
            files_list.remove (child);
        }

        var files = DesktopFileOperator.get_default ().files;

        // Create a listbox per each entry
        for (int i = 0; i < files.size; i++) {
            var file = files.get (i);

            var app_icon = new Gtk.Image.from_gicon (new ThemedIcon ("application-x-executable")) {
                pixel_size = 48,
                margin_top = 6,
                margin_bottom = 6
            };
            try {
                app_icon.gicon = Icon.new_for_string (file.get_string (KeyFileDesktop.KEY_ICON, false));
            } catch (Error e) {
                warning ("Failed to update app_icon: %s", e.message);
            }

            string locale = file.get_locale_for_key (KeyFileDesktop.KEY_NAME, DesktopFileOperator.get_default ().preferred_language);
            string app_name = file.get_locale_string (KeyFileDesktop.KEY_NAME, locale);

            string dialog_title = _("Are you sure you want to delete entry?");
            if (app_name != "") {
                dialog_title = _("Are you sure you want to delete entry of “%s”?").printf (app_name);
            }

            var delete_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic") {
                tooltip_text = _("Delete…"),
                valign = Gtk.Align.CENTER
            };
            delete_button.add_css_class ("flat");
            delete_button.clicked.connect (() => {
                var delete_dialog = new Adw.MessageDialog (
                    window,
                    dialog_title,
                    _("This removes the app from the launcher.")
                );
                delete_dialog.add_response (DialogResponse.CANCEL, _("Cancel"));
                delete_dialog.add_response (DialogResponse.OK, _("Delete"));
                delete_dialog.set_response_appearance (DialogResponse.OK, Adw.ResponseAppearance.DESTRUCTIVE);
                delete_dialog.default_response = DialogResponse.CANCEL;
                delete_dialog.close_response = DialogResponse.CANCEL;
                delete_dialog.response.connect ((response_id) => {
                    if (response_id == DialogResponse.OK) {
                        bool ret = false;

                        try {
                            ret = file.delete_file ();
                        } catch (Error e) {
                            var error_dialog = new Adw.MessageDialog (
                                window,
                                _("Could not delete entry of “%s”").printf (app_name),
                                e.message
                            );
                            error_dialog.add_response (DialogResponse.CLOSE, _("Close"));
                            error_dialog.default_response = DialogResponse.CLOSE;
                            error_dialog.close_response = DialogResponse.CLOSE;
                            error_dialog.response.connect ((response_id) => {
                                if (response_id == DialogResponse.CLOSE) {
                                    error_dialog.destroy ();
                                }
                            });
                            error_dialog.present ();
                        }

                        file_deleted (ret);
                    }

                    delete_dialog.destroy ();
                });

                delete_dialog.show ();
            });

            locale = file.get_locale_for_key (KeyFileDesktop.KEY_COMMENT, DesktopFileOperator.get_default ().preferred_language);
            string comment = file.get_locale_string (KeyFileDesktop.KEY_COMMENT, locale);

            var list_item = new Adw.ActionRow () {
                title = app_name,
                subtitle = comment,
                title_lines = 1,
                subtitle_lines = 1,
                activatable = true
            };
            list_item.width_request = 350;
            list_item.add_prefix (app_icon);
            list_item.add_suffix (delete_button);
            list_item.activated.connect (() => {
                DesktopFileOperator.get_default ().desktop_file = file;
                window.show_edit_view ();
            });

            files_list.append (list_item);
        }

        // Set visible page
        if (files_list.get_last_child () != null) {
            stack.visible_child_name = "files_list_page";
        } else {
            // There are no listboxes, that means we have no valid desktop files
            stack.visible_child_name = "no_files_page";
        }
    }
}
