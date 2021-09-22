/*
 * Copyright 2021 Ryo Nakano
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class MainWindow : Gtk.ApplicationWindow {
    private EditView edit_view;
    private Gtk.Stack stack;
    private Gtk.ToolButton home_button;
    private Gtk.HeaderBar header_bar;

    public MainWindow () {
        Object (
            resizable: false,
            default_width: 400
        );
    }

    construct {
        var welcome_view = new WelcomeView (this);
        var files_view = new FilesView (this);
        edit_view = new EditView (this);

        stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT
        };
        stack.add_named (welcome_view, "welcome_view");
        stack.add_named (files_view, "files_view");
        stack.add_named (edit_view, "edit_view");
        add (stack);

        var home_image = new Gtk.Image.from_icon_name ("go-home", Gtk.IconSize.SMALL_TOOLBAR);
        home_button = new Gtk.ToolButton (home_image, null) {
            tooltip_markup = Granite.markup_accel_tooltip ({"<Alt>Home"}, _("Create new or open"))
        };

        header_bar = new Gtk.HeaderBar () {
            show_close_button = true,
            has_subtitle = false,
        };
        header_bar.pack_start (home_button);

        unowned var header_bar_style = header_bar.get_style_context ();
        header_bar_style.add_class (Gtk.STYLE_CLASS_FLAT);
        header_bar_style.add_class ("default-decoration");

        set_titlebar (header_bar);
        show_welcome_view ();
        show_all ();

        home_button.clicked.connect (() => {
            show_welcome_view ();
        });

        DesktopFileOperator.get_default ().notify["last-edited"].connect (() => {
            set_header_file_info ();
        });

        key_press_event.connect ((key) => {
            if (Gdk.ModifierType.CONTROL_MASK in key.state && key.keyval == Gdk.Key.q) {
                destroy ();
            }

            return false;
        });

        // Follow elementary OS-wide dark preference
        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });
    }

    public void show_welcome_view () {
        header_bar.title = "Pin It!";
        home_button.sensitive = false;
        stack.visible_child_name = "welcome_view";
    }

    public void show_files_view () {
        header_bar.title = _("Open a desktop file");
        home_button.sensitive = true;
        stack.visible_child_name = "files_view";
    }

    public void show_edit_view (DesktopFile desktop_file) {
        edit_view.set_desktop_file (desktop_file);
        set_header_file_info ();
        home_button.sensitive = true;
        stack.visible_child_name = "edit_view";
    }

    private void set_header_file_info () {
        if (DesktopFileOperator.get_default ().last_edited != null) {
            header_bar.title = _("Editing “%s”").printf (DesktopFileOperator.get_default ().last_edited.id + ".desktop");
        } else {
            header_bar.title = _("Untitled desktop file");
        }
    }
}
