/*
 * Copyright 2021 Ryo Nakano
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class MainWindow : Hdy.Window {
    private uint configure_id;

    private WelcomeView welcome_view;
    private FilesView files_view;
    private EditView edit_view;
    private Hdy.Deck deck;
    private Gtk.ToolButton home_button;
    private Hdy.HeaderBar header_bar;

    public MainWindow () {
        Object (
            resizable: false,
            default_width: 400
        );
    }

    construct {
        Hdy.init ();

        welcome_view = new WelcomeView (this);
        files_view = new FilesView (this);
        edit_view = new EditView (this);

        deck = new Hdy.Deck () {
            can_swipe_back = true,
            transition_type = Hdy.DeckTransitionType.SLIDE
        };
        deck.add (welcome_view);
        deck.add (files_view);
        deck.add (edit_view);

        var overlay = new Gtk.Overlay ();
        overlay.add (deck);

        var toast = new Granite.Widgets.Toast (_("Saved changes!"));
        overlay.add_overlay (toast);

        var home_image = new Gtk.Image.from_icon_name ("go-home", Gtk.IconSize.SMALL_TOOLBAR);
        home_button = new Gtk.ToolButton (home_image, null) {
            tooltip_markup = Granite.markup_accel_tooltip ({"<Alt>Home"}, _("Create new or edit"))
        };

        header_bar = new Hdy.HeaderBar () {
            show_close_button = true,
            has_subtitle = false,
        };
        header_bar.pack_start (home_button);

        unowned var header_bar_style = header_bar.get_style_context ();
        header_bar_style.add_class (Gtk.STYLE_CLASS_FLAT);
        header_bar_style.add_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.add (header_bar);
        main_box.add (overlay);

        add (main_box);
        show_welcome_view ();
        show_all ();

        home_button.clicked.connect (() => {
            show_welcome_view ();
        });

        DesktopFileOperator.get_default ().file_updated.connect (() => {
            show_welcome_view ();
            toast.send_notification ();
        });

        key_press_event.connect ((key) => {
            if (Gdk.ModifierType.CONTROL_MASK in key.state && key.keyval == Gdk.Key.q) {
                destroy ();
            }

            return false;
        });

        deck.notify["transition-running"].connect (() => {
            if (!deck.transition_running && deck.visible_child == welcome_view) {
                show_welcome_view ();
            }
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
        deck.visible_child = welcome_view;
    }

    public void show_files_view () {
        files_view.update_list ();
        header_bar.title = _("Edit a desktop file");
        home_button.sensitive = true;
        deck.reorder_child_after (files_view, welcome_view);
        deck.visible_child = files_view;
    }

    public void show_edit_view (DesktopFile desktop_file) {
        edit_view.set_desktop_file (desktop_file);
        set_header_file_info (desktop_file);
        home_button.sensitive = true;
        deck.reorder_child_after (edit_view, welcome_view);
        deck.visible_child = edit_view;
    }

    private void set_header_file_info (DesktopFile desktop_file) {
        if (desktop_file.id != "") {
            header_bar.title = _("Editing “%s”").printf (desktop_file.app_name);
        } else {
            header_bar.title = _("Untitled desktop file");
        }
    }

    protected override bool configure_event (Gdk.EventConfigure event) {
        if (configure_id != 0) {
            Source.remove (configure_id);
        }

        configure_id = Timeout.add (100, () => {
            configure_id = 0;
            int x, y;
            get_position (out x, out y);
            Application.settings.set ("window-position", "(ii)", x, y);

            return false;
        });

        return base.configure_event (event);
    }
}
