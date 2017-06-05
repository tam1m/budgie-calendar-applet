/*
 * This file is part of calendar-applet
 *
 * Copyright (C) 2016 Daniel Pinto <danielpinto8zz6@gmail.com>
 * Copyright (C) 2014-2016 Ikey Doherty <ikey@solus-project.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class CalendarPlugin : Budgie.Plugin, Peas.ExtensionBase {
public Budgie.Applet get_panel_widget(string uuid) {
        return new CalendarApplet();
}
}

enum ClockFormat {
        TWENTYFOUR = 0,
        TWELVE = 1;
}

public const string CALENDAR_MIME = "text/calendar";

public class CalendarApplet : Budgie.Applet {

protected Gtk.EventBox widget;
protected Gtk.Label clock;
protected Gtk.Calendar calendar;
protected Gtk.Popover popover;

protected bool ampm = false;
protected bool show_seconds = false;
protected bool show_date = false;
protected bool date_format = false;

private DateTime time;

protected Settings settings;

protected Settings applet_settings;

private unowned Budgie.PopoverManager ? manager = null;

AppInfo ? calprov = null;

public CalendarApplet() {
        widget = new Gtk.EventBox();
        clock = new Gtk.Label("");
        clock.valign = Gtk.Align.CENTER;
        time = new DateTime.now_local();
        widget.add(clock);
        margin_bottom = 2;

        popover = new Gtk.Popover(widget);
        calendar = new Gtk.Calendar();
        var box = new Gtk.ListBox();

        Gtk.Entry entry = new Gtk.Entry ();

        applet_settings = new Settings ("io.github.budgie-calendar-applet");

        settings = new Settings("org.gnome.desktop.interface");

        var dateformat = applet_settings.get_string ("date-format");

        // Add a default-text:
        entry.set_text (dateformat);

        // Print text to stdout on enter:
        entry.activate.connect (() => {
                        dateformat = entry.get_text ();
                        stdout.printf ("%s\n", dateformat);
                        applet_settings.set_string ("date-format", dateformat);
                        update_clock();
                });

        // Add a delete-button:
        entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "edit-clear");
        entry.icon_press.connect ((pos, event) => {
                        if (pos == Gtk.EntryIconPosition.SECONDARY) {
                                entry.set_text ("");
                        }
                });

        var label_date = new Gtk.Label ("Show date");
        var switch_date = new Gtk.Switch ();
        var label_seconds = new Gtk.Label ("Show seconds");
        var switch_seconds = new Gtk.Switch ();
        var label_format = new Gtk.Label ("Use 24h time");
        var switch_format = new Gtk.Switch ();

        // Get current setting to set the switch button
        if(settings.get_boolean ("clock-show-date") == true) {
                switch_date.set_active (true);
        }
        if(settings.get_boolean ("clock-show-seconds") == true) {
                switch_seconds.set_active (true);
        }
        if(settings.get_enum("clock-format") == ClockFormat.TWENTYFOUR) {
                switch_format.set_active (true);
        }

        switch_date.notify["active"].connect (date_switcher);
        switch_seconds.notify["active"].connect (seconds_switcher);
        switch_format.notify["active"].connect (format_switcher);

        var grid = new Gtk.Grid ();
        grid.set_column_spacing(35);
        grid.set_row_spacing(10);
        grid.set_margin_start(5);
        grid.set_margin_end(5);
        grid.attach(label_date, 0, 0, 1, 1);
        grid.attach(switch_date, 1, 0, 1, 1);
        grid.attach(label_seconds, 0, 1, 1, 1);
        grid.attach(switch_seconds, 1, 1, 1, 1);
        grid.attach(label_format, 0, 2, 1, 1);
        grid.attach(switch_format, 1, 2, 1, 1);

        widget.set_tooltip_text(time.format(dateformat));

        widget.button_press_event.connect((e)=> {
                        if (e.button != 1) {
                                return Gdk.EVENT_PROPAGATE;
                        }
                        Toggle();
                        return Gdk.EVENT_STOP;
                });

        // Create the popover container
        popover.add(box);

        // check current month
        calendar.month_changed.connect(() => {
                        if (calendar.month + 1 == time.get_month())
                                calendar.mark_day(time.get_day_of_month());
                        else
                                calendar.unmark_day(time.get_day_of_month());
                });

        // Setup calprov
        calprov = AppInfo.get_default_for_type(CALENDAR_MIME, false);
        var monitor = AppInfoMonitor.get();
        monitor.changed.connect(update_cal);

        // Cal clicked handler
        calendar.day_selected_double_click.connect(on_cal_activate);

        box.insert(calendar, 0);
        box.insert(grid, 0);
        box.insert(entry, 0);

        // Time and Date settings
        var time_and_date = new Gtk.Button.with_label("Time and date settings");
        time_and_date.clicked.connect(on_date_activate);
        box.insert(time_and_date, 1);

        Timeout.add_seconds_full(GLib.Priority.LOW, 1, update_clock);

        settings.changed.connect(on_settings_change);
        on_settings_change("clock-format");
        on_settings_change("clock-show-seconds");
        on_settings_change("clock-show-date");
        update_clock();
        add(widget);
        show_all();
}

void date_switcher (Object switcher, ParamSpec pspec) {
        if ((switcher as Gtk.Switch).get_active())
        {
                this.settings.set_boolean("clock-show-date", true);
                Idle.add(()=> {
                                this.update_clock();
                                return false;
                        });
        }  else {
                this.settings.set_boolean("clock-show-date", false);
                Idle.add(()=> {
                                this.update_clock();
                                return false;
                        });
        }
}

void seconds_switcher (Object switcher, ParamSpec pspec) {
        if ((switcher as Gtk.Switch).get_active())
        {
                this.settings.set_boolean("clock-show-seconds", true);
                Idle.add(()=> {
                                this.update_clock();
                                return false;
                        });
        }  else {
                this.settings.set_boolean("clock-show-seconds", false);
                Idle.add(()=> {
                                this.update_clock();
                                return false;
                        });
        }
}

void format_switcher (Object switcher, ParamSpec pspec) {
        if ((switcher as Gtk.Switch).get_active())
        {
                this.settings.set_enum("clock-format", ClockFormat.TWENTYFOUR);
                Idle.add(()=> {
                                this.update_clock();
                                return false;
                        });
        }  else {
                this.settings.set_enum("clock-format", ClockFormat.TWELVE);
                Idle.add(()=> {
                                this.update_clock();
                                return false;
                        });
        }
}


public void Toggle(){
        if (popover.get_visible()) {
                popover.hide();
        } else {
                popover.get_child().show_all();
                this.manager.show_popover(widget);
        }
}

public override void invoke_action(Budgie.PanelAction action) {
        Toggle();
}

public override void update_popovers(Budgie.PopoverManager ? manager) {
        this.manager = manager;
        manager.register_popover(widget, popover);
}

protected void on_settings_change(string key) {
        switch (key) {
        case "clock-format":
                ClockFormat f = (ClockFormat) settings.get_enum(key);
                ampm = f == ClockFormat.TWELVE;
                break;
        case "clock-show-seconds":
                show_seconds = settings.get_boolean(key);
                break;
        case "clock-show-date":
                show_date = settings.get_boolean(key);
                break;
        }
        if (get_toplevel() != null) {
                get_toplevel().queue_draw();
        }
        /* Lazy update on next clock sync */
}

/**
 * This is called once every second, updating the time
 */
protected bool update_clock() {

        time = new DateTime.now_local();
        string format = "";

        if (show_date) {
                format += applet_settings.get_string ("date-format");
        }
        if (ampm) {
                format += "%l:%M";
        } else {
                format += "%H:%M";
        }
        if (show_seconds) {
                format += ":%S";
        }
        if (ampm) {
                format += " %p";
        }
        string ftime = " <big>%s</big> ".printf(format);

        var ctime = time.format(ftime);
        clock.set_markup(ctime);

        return true;
}
void update_cal()
{
        calprov = AppInfo.get_default_for_type(CALENDAR_MIME, false);
}

void on_date_activate()
{
        var app_info = new DesktopAppInfo("gnome-datetime-panel.desktop");

        if (app_info == null) {
                return;
        }
        try {
                app_info.launch(null, null);
        } catch (Error e) {
                message("Unable to launch gnome-datetime-panel.desktop: %s", e.message);
        }
}

void on_cal_activate()
{
        if (calprov == null) {
                return;
        }
        try {
                calprov.launch(null, null);
        } catch (Error e) {
                message("Unable to launch %s: %s", calprov.get_name(), e.message);
        }
}
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
        var objmodule = module as Peas.ObjectModule;
        objmodule.register_extension_type(typeof (Budgie.Plugin), typeof (CalendarPlugin));
}
