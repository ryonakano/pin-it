/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021-2022 Ryo Nakano <ryonakaknock3@gmail.com>
 */

public class EditView : Gtk.Box {
    public MainWindow window { private get; construct; }
    public bool is_unsaved {
        get {
            return (
                file_name_entry.text.length > 0 || name_entry.text.length > 0 ||
                comment_entry.text.length > 0 || exec_entry.text.length > 0 ||
                icon_entry.text.length > 0 || category_chooser.selected != "" || terminal_checkbox.active
            );
        }
    }

    private Gtk.Button cancel_button;
    private Gtk.Button save_button;
    private Adw.HeaderBar headerbar;

    private RegexEntry file_name_entry;
    private RegexEntry name_entry;
    private RegexEntry comment_entry;
    private Gtk.Entry exec_entry;
    private Gtk.Entry icon_entry;
    private CategoryChooser category_chooser;
    private Gtk.CheckButton terminal_checkbox;

    private Gtk.Stack stack;

    public EditView (MainWindow window) {
        Object (window: window);
    }

    construct {
        // Headerbar part
        cancel_button = new Gtk.Button ();

        save_button = new Gtk.Button.with_label (_("Save"));
        save_button.get_style_context ().add_class ("suggested-action");

        headerbar = new Adw.HeaderBar () {
            title_widget = new Gtk.Label ("")
        };
        headerbar.pack_start (cancel_button);
        headerbar.pack_end (save_button);

        // Main part
        var file_name_label = new Gtk.Label (_("File Name")) {
            halign = Gtk.Align.START
        };
        file_name_label.get_style_context ().add_class ("heading");
        var file_name_desc_label = new Gtk.Label (
            _("Name of the file where these app info is saved.")
        ) {
            halign = Gtk.Align.START,
            margin_bottom = 6
        };
        file_name_desc_label.get_style_context ().add_class ("dim-label");
        file_name_entry = new RegexEntry (/^[^.0-9]{1}([A-Za-z0-9]*\.)+[A-Za-z0-9]*[^.]$/, false) { //vala-lint=space-before-paren
            hexpand = true
        };
        var suffix_label = new Gtk.Label (".desktop") {
            tooltip_text = _("Suffix of the file"),
            margin_start = 6
        };
        var file_name_grid = new Gtk.Grid () {
            margin_bottom = 12
        };
        file_name_grid.attach (file_name_label, 0, 0, 1, 1);
        file_name_grid.attach (file_name_desc_label, 0, 1, 1, 1);
        file_name_grid.attach (file_name_entry, 0, 2, 1, 1);
        file_name_grid.attach (suffix_label, 1, 2, 1, 1);
        file_name_grid.attach (create_info_button (), 2, 2, 1, 1);

        var name_label = new Gtk.Label (_("App Name")) {
            halign = Gtk.Align.START
        };
        name_label.get_style_context ().add_class ("heading");
        var name_desc_label = new Gtk.Label (_("Shown in the launcher or Dock.")) {
            halign = Gtk.Align.START,
            margin_bottom = 6
        };
        name_desc_label.get_style_context ().add_class ("dim-label");
        name_entry = new RegexEntry (/^.+$/) {
            hexpand = true
        };
        var name_grid = new Gtk.Grid () {
            margin_bottom = 12
        };
        name_grid.attach (name_label, 0, 0, 1, 1);
        name_grid.attach (name_desc_label, 0, 1, 1, 1);
        name_grid.attach (name_entry, 0, 2, 1, 1);

        var comment_label = new Gtk.Label (_("Comment")) {
            halign = Gtk.Align.START
        };
        comment_label.get_style_context ().add_class ("heading");
        var comment_desc_label = new Gtk.Label (_("A tooltip text to describe what the app helps you to do.")) {
            halign = Gtk.Align.START,
            margin_bottom = 6
        };
        comment_desc_label.get_style_context ().add_class ("dim-label");
        comment_entry = new RegexEntry (/^.+$/) {
            hexpand = true
        };
        var comment_grid = new Gtk.Grid () {
            margin_bottom = 12
        };
        comment_grid.attach (comment_label, 0, 0, 1, 1);
        comment_grid.attach (comment_desc_label, 0, 1, 1, 1);
        comment_grid.attach (comment_entry, 0, 2, 1, 1);

        var exec_label = new Gtk.Label (_("Exec File")) {
            halign = Gtk.Align.START
        };
        exec_label.get_style_context ().add_class ("heading");
        var exec_desc_label = new Gtk.Label (
            _("The command/app launched when you click the app entry in the launcher. Specify in an absolute path or an app's alias name.")
        ) {
            halign = Gtk.Align.START,
            margin_bottom = 6
        };
        exec_desc_label.get_style_context ().add_class ("dim-label");
        exec_entry = new Gtk.Entry () {
            hexpand = true,
            secondary_icon_name = "document-open-symbolic"
        };
        var exec_grid = new Gtk.Grid () {
            margin_bottom = 12
        };
        exec_grid.attach (exec_label, 0, 0, 1, 1);
        exec_grid.attach (exec_desc_label, 0, 1, 1, 1);
        exec_grid.attach (exec_entry, 0, 2, 1, 1);

        var icon_label = new Gtk.Label (_("Icon File")) {
            halign = Gtk.Align.START
        };
        icon_label.get_style_context ().add_class ("heading");
        var icon_desc_label = new Gtk.Label (
            _("The icon branding the app. Specify in an absolute path or an icon's alias name.")
        ) {
            halign = Gtk.Align.START,
            margin_bottom = 6
        };
        icon_desc_label.get_style_context ().add_class ("dim-label");
        icon_entry = new Gtk.Entry () {
            hexpand = true,
            secondary_icon_name = "document-open-symbolic"
        };
        var icon_grid = new Gtk.Grid () {
            margin_bottom = 12
        };
        icon_grid.attach (icon_label, 0, 0, 1, 1);
        icon_grid.attach (icon_desc_label, 0, 1, 1, 1);
        icon_grid.attach (icon_entry, 0, 2, 1, 1);

        var categories_label = new Gtk.Label (_("App Categories")) {
            halign = Gtk.Align.START
        };
        categories_label.get_style_context ().add_class ("heading");
        var categories_desc_label = new Gtk.Label (_("Type of the app, multiplly selectable.")) {
            halign = Gtk.Align.START,
            margin_bottom = 6
        };
        categories_desc_label.get_style_context ().add_class ("dim-label");
        category_chooser = new CategoryChooser ();
        var categories_grid = new Gtk.Grid () {
            margin_bottom = 24
        };
        categories_grid.attach (categories_label, 0, 0, 1, 1);
        categories_grid.attach (categories_desc_label, 0, 1, 1, 1);
        categories_grid.attach (category_chooser, 0, 2, 1, 1);

        terminal_checkbox = new Gtk.CheckButton.with_label (_("Run in Terminal")) {
            margin_bottom = 6
        };
        var terminal_desc_label = new Gtk.Label (_("Check this in if you want to registar a CUI app.")) {
            halign = Gtk.Align.START,
            margin_bottom = 6
        };
        terminal_desc_label.get_style_context ().add_class ("dim-label");

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 12,
            margin_bottom = 24,
            margin_start = 24,
            margin_end = 24
        };
        main_box.append (file_name_grid);
        main_box.append (name_grid);
        main_box.append (comment_grid);
        main_box.append (exec_grid);
        main_box.append (icon_grid);
        main_box.append (categories_grid);
        main_box.append (terminal_checkbox);
        main_box.append (terminal_desc_label);

        var no_selection_page = new Adw.StatusPage ();

        stack = new Gtk.Stack ();
        stack.add_named (main_box, "main_box");
        stack.add_named (no_selection_page, "no_selection_page");

        hide_all ();
        orientation = Gtk.Orientation.VERTICAL;
        append (headerbar);
        append (stack);

        cancel_button.clicked.connect (() => {
            hide_all ();
            window.show_files_view ();
        });

        save_button.clicked.connect (() => {
            save_file ();
        });

        exec_entry.icon_press.connect ((icon_pos) => {
            if (icon_pos != Gtk.EntryIconPosition.SECONDARY) {
                return;
            }

            var filechooser = new Gtk.FileChooserNative (
                _("Select an executable file"), window, Gtk.FileChooserAction.OPEN,
                _("Open"), _("Cancel")
            ) {
                modal = true
            };
            filechooser.response.connect ((response_id) => {
                if (response_id == Gtk.ResponseType.ACCEPT) {
                    exec_entry.text = filechooser.get_file ().get_path ();
                }
            });
            filechooser.show ();
        });

        icon_entry.icon_press.connect ((icon_pos) => {
            if (icon_pos != Gtk.EntryIconPosition.SECONDARY) {
                return;
            }

            // See https://specifications.freedesktop.org/icon-theme-spec/latest/ar01s02.html
            var filefilter = new Gtk.FileFilter ();
            filefilter.add_mime_type ("image/png");
            filefilter.add_mime_type ("image/svg+xml");
            filefilter.add_mime_type ("image/x-xpixmap");
            filefilter.set_filter_name (_("PNG, SVG, or XMP files"));

            var filechooser = new Gtk.FileChooserNative (
                _("Select an icon file"), window, Gtk.FileChooserAction.OPEN,
                _("Open"), _("Cancel")
            ) {
                modal = true
            };
            filechooser.add_filter (filefilter);
            filechooser.response.connect ((response_id) => {
                if (response_id == Gtk.ResponseType.ACCEPT) {
                    icon_entry.text = filechooser.get_file ().get_path ();
                }
            });
            filechooser.show ();
        });

        var event_controller = new Gtk.EventControllerKey ();
        event_controller.key_released.connect ((keyval, keycode, state) => {
            save_button.sensitive = get_save_button_sensitivity ();
        });
        ((Gtk.Widget) this).add_controller (event_controller);

        category_chooser.toggled.connect (() => {
            save_button.sensitive = get_save_button_sensitivity ();
        });
    }

    public void set_desktop_file (DesktopFile desktop_file) {
        file_name_entry.text = desktop_file.file_name;
        name_entry.text = desktop_file.app_name;
        comment_entry.text = desktop_file.comment;
        exec_entry.text = desktop_file.exec_file;
        icon_entry.text = desktop_file.icon_file;
        category_chooser.selected = desktop_file.categories;
        terminal_checkbox.active = desktop_file.is_cli;

        stack.visible_child_name = "main_box";
        file_name_entry.grab_focus ();

        if (desktop_file.file_name != "") {
            if (desktop_file.app_name != "") {
                ((Gtk.Label) headerbar.title_widget).label = _("Editing “%s”").printf (desktop_file.app_name);
            } else {
                ((Gtk.Label) headerbar.title_widget).label = _("Editing Entry");
            }
        } else {
            ((Gtk.Label) headerbar.title_widget).label = _("New Entry");
        }

        cancel_button.visible = true;
        save_button.visible = true;
        save_button.sensitive = get_save_button_sensitivity ();
    }

    public void hide_all () {
        stack.visible_child_name = "no_selection_page";

        ((Gtk.Label) headerbar.title_widget).label = "";
        cancel_button.visible = false;
        save_button.visible = false;
    }

    public void update_cancel_button_form (bool folded) {
        // Clear the current form
        cancel_button.child = null;

        if (folded) {
            cancel_button.icon_name = "go-previous-symbolic";
        } else {
            cancel_button.label = _("Cancel");
        }
    }

    private bool get_save_button_sensitivity () {
        return (
            file_name_entry.is_valid && name_entry.is_valid && comment_entry.is_valid &&
            exec_entry.text.length > 0 && category_chooser.selected != ""
        );
    }

    public void save_file (bool is_backup = false) {
        var desktop_file = new DesktopFile (
            file_name_entry.text,
            name_entry.text,
            comment_entry.text,
            exec_entry.text,
            icon_entry.text,
            category_chooser.selected,
            terminal_checkbox.active,
            is_backup
        );
        DesktopFileOperator.get_default ().write_to_file (desktop_file);
    }

    private Gtk.MenuButton create_info_button () {
        var label = new Gtk.Label (
            _("Only use alphabets, numbers, and underscores, and none begins with numbers.") + "\n" +
            _("Use at least one period to make sure to be separated into at least two elements.")
        ) {
            halign = Gtk.Align.START
        };

        var detailed_label = new Gtk.Label (
            _("For more info, see %s.").printf (
            "<a href=\"https://dbus.freedesktop.org/doc/dbus-specification.html#message-protocol-names-bus\">%s</a>").printf (
            _("the file naming specification by freedesktop.org")
        )) {
            use_markup = true,
            halign = Gtk.Align.START
        };

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12
        };
        box.append (label);
        box.append (detailed_label);

        var popover = new Gtk.Popover () {
            child = box
        };

        var menu_button = new Gtk.MenuButton () {
            icon_name = "dialog-information-symbolic",
            margin_start = 6,
            tooltip_text = _("Recommendations for naming"),
            popover = popover
        };

        menu_button.activate.connect (() => {
            popover.popup ();
        });

        return menu_button;
    }
}
