/*! DateTime 2.0.0 for DataTables.net
 * Copyright (c) SpryMedia Ltd - datatables.net/license
 */

(function(factory){
	if (typeof define === 'function' && define.amd) {
		// AMD
		define(['datatables.net'], function (dt) {
			return factory(window, document, dt);
		});
	}
	else if (typeof exports === 'object') {
		// CommonJS
		var cjsRequires = function (root) {
			if (! root.DataTable) {
				require('datatables.net')(root);
			}
		};

		if (typeof window === 'undefined') {
			module.exports = function (root) {
				if (! root) {
					// CommonJS environments without a window global must pass a
					// root. This will give an error otherwise
					root = window;
				}

				cjsRequires(root);
				return factory(root, root.document, root.DataTable);
			};
		}
		else {
			cjsRequires(window);
			module.exports = factory(window, window.document, window.DataTable);
		}
	}
	else {
		// Browser
		factory(window, document, window.DataTable);
	}
}(function(window, document, DataTable) {
'use strict';

var Dom = DataTable.Dom;
var util = DataTable.util;


// Supported formatting and parsing libraries:
// * Moment
// * Luxon
// * DayJS
var dateLib;
class DateTime {
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Statics
     */
    /**
     * Use a specific compatible date library
     */
    static use(lib) {
        dateLib = lib;
    }
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Public methods
     */
    /**
     * Destroy the control
     */
    destroy() {
        var namespace = this.s.namespace;
        clearTimeout(this.s.showTo);
        this._hide(true);
        this.dom.container.off().empty();
        this.dom.input
            .classRemove('dt-datetime')
            .attrRemove('autocomplete')
            .off('.datetime');
        Dom.s(document).off('.' + namespace);
        Dom.w.off('.' + namespace);
    }
    display(year, month) {
        if (year !== undefined) {
            this.s.display.setUTCFullYear(year);
        }
        if (month !== undefined) {
            this.s.display.setUTCMonth(month - 1);
        }
        if (year !== undefined || month !== undefined) {
            this._setTitle();
            this._setCalander();
            return this;
        }
        return this.s.display
            ? {
                month: this.s.display.getUTCMonth() + 1,
                year: this.s.display.getUTCFullYear()
            }
            : {
                month: null,
                year: null
            };
    }
    errorMsg(msg) {
        var error = this.dom.error;
        if (msg) {
            error.html(msg);
        }
        else {
            error.empty();
        }
        return this;
    }
    hide() {
        this._hide();
        return this;
    }
    max(date) {
        this.c.maxDate = typeof date === 'string' ? new Date(date) : date;
        this._optionsTitle();
        this._setCalander();
        return this;
    }
    min(date) {
        this.c.minDate = typeof date === 'string' ? new Date(date) : date;
        this._optionsTitle();
        this._setCalander();
        return this;
    }
    /**
     * Check if an element belongs to this control
     *
     * @param  {node} node Element to check
     * @return {boolean}   true if owned by this control, false otherwise
     */
    owns(node) {
        return Dom.s(node).closest(this.dom.container.get(0)).count() > 0;
    }
    val(set, write = true) {
        if (set === undefined) {
            return this.s.d;
        }
        var oldVal = this.s.d;
        if (set instanceof Date) {
            this.s.d = this._dateToUtc(set);
        }
        else if (set === null || set === '') {
            this.s.d = null;
        }
        else if (set === '--now') {
            this.s.d = this._dateToUtc(new Date());
        }
        else if (typeof set === 'string') {
            this.s.d = this._dateToUtc(this._convert(set, this.c.format, null));
        }
        if (write || write === undefined) {
            if (this.s.d) {
                this._writeOutput(false, (oldVal === null && this.s.d !== null) ||
                    (oldVal !== null && this.s.d === null) ||
                    oldVal.toString() !== this.s.d.toString());
            }
            else {
                // The input value was not valid...
                this.dom.input.val(set);
            }
        }
        // Need something to display
        if (this.s.d) {
            this.s.display = new Date(this.s.d.toString());
        }
        else if (this.c.display) {
            this.s.display = new Date();
            this.s.display.setUTCDate(1);
            this.display(this.c.display.year, this.c.display.month);
        }
        else {
            this.s.display = new Date();
        }
        // Set the day of the month to be 1 so changing between months doesn't
        // run into issues when going from day 31 to 28 (for example)
        this.s.display.setUTCDate(1);
        // Update the display elements for the new value
        this._setTitle();
        this._setCalander();
        this._setTime();
        return this;
    }
    /**
     * Similar to `val()` but uses a given date / time format
     *
     * @param format Format to get the data as (getter) or that is input
     *   (setter)
     * @param val Value to write (if undefined, used as a getter)
     * @returns
     */
    valFormat(format, val) {
        if (!val) {
            return this._convert(this.val(), null, format);
        }
        // Convert from the format given here to the instance's configured
        // format
        this.val(this._convert(val, format, null));
        return this;
    }
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Constructor
     */
    constructor(input, opts) {
        // Attempt to auto detect the formatting library (if there is one).
        // Having it in the constructor allows load order independence.
        let win = window;
        if (typeof dateLib === 'undefined') {
            dateLib = win.moment
                ? win.moment
                : win.dayjs
                    ? win.dayjs
                    : win.luxon
                        ? win.luxon
                        : null;
        }
        this.c = util.object.assignDeep({}, DateTime.defaults, opts);
        var classPrefix = this.c.classPrefix;
        // Only IS8601 dates are supported without moment, dayjs or luxon
        if (!dateLib && this.c.format !== 'YYYY-MM-DD') {
            throw "DateTime: Without momentjs, dayjs or luxon only the format 'YYYY-MM-DD' can be used";
        }
        if (this._isLuxon() && this.c.format == 'YYYY-MM-DD') {
            this.c.format = 'yyyy-MM-dd';
        }
        // Min and max need to be `Date` objects in the config
        if (typeof this.c.minDate === 'string') {
            this.c.minDate = new Date(this.c.minDate);
        }
        if (typeof this.c.maxDate === 'string') {
            this.c.maxDate = new Date(this.c.maxDate);
        }
        // DOM structure
        var structure = Dom.c('div')
            .classAdd(classPrefix)
            .html('<div class="' +
            classPrefix +
            '-date">' +
            '<div class="' +
            classPrefix +
            '-title">' +
            '<div class="' +
            classPrefix +
            '-iconLeft">' +
            '<button type="button"></button>' +
            '</div>' +
            '<div class="' +
            classPrefix +
            '-iconRight">' +
            '<button type="button"></button>' +
            '</div>' +
            '<div class="' +
            classPrefix +
            '-label">' +
            '<span></span>' +
            '<select class="' +
            classPrefix +
            '-month"></select>' +
            '</div>' +
            '<div class="' +
            classPrefix +
            '-label">' +
            '<span></span>' +
            '<select class="' +
            classPrefix +
            '-year"></select>' +
            '</div>' +
            '</div>' +
            '<div class="' +
            classPrefix +
            '-buttons">' +
            '<a class="' +
            classPrefix +
            '-clear"></a>' +
            '<a class="' +
            classPrefix +
            '-today"></a>' +
            '<a class="' +
            classPrefix +
            '-selected"></a>' +
            '</div>' +
            '<div class="' +
            classPrefix +
            '-calendar"></div>' +
            '</div>' +
            '<div class="' +
            classPrefix +
            '-time">' +
            '<div class="' +
            classPrefix +
            '-hours"></div>' +
            '<div class="' +
            classPrefix +
            '-minutes"></div>' +
            '<div class="' +
            classPrefix +
            '-seconds"></div>' +
            '</div>' +
            '<div class="' +
            classPrefix +
            '-error"></div>');
        this.dom = {
            container: structure,
            date: structure.find('.' + classPrefix + '-date'),
            title: structure.find('.' + classPrefix + '-title'),
            calendar: structure.find('.' + classPrefix + '-calendar'),
            time: structure.find('.' + classPrefix + '-time'),
            error: structure.find('.' + classPrefix + '-error'),
            buttons: structure.find('.' + classPrefix + '-buttons'),
            clear: structure.find('.' + classPrefix + '-clear'),
            today: structure.find('.' + classPrefix + '-today'),
            selected: structure.find('.' + classPrefix + '-selected'),
            previous: structure.find('.' + classPrefix + '-iconLeft'),
            next: structure.find('.' + classPrefix + '-iconRight'),
            input: Dom.s(input)
        };
        this.s = {
            d: null,
            display: null,
            minutesRange: null,
            secondsRange: null,
            namespace: 'datetime-' + DateTime._instance++,
            parts: {
                date: this.c.format.match(/[yYMDd]|L(?!T)|l/) !== null,
                time: this.c.format.match(/[Hhm]|LT|LTS/) !== null,
                seconds: this.c.format.indexOf('s') !== -1,
                hours12: this.c.format.match(/[haA]/) !== null
            },
            showTo: null
        };
        this.dom.container
            .append(this.dom.date)
            .append(this.dom.time)
            .append(this.dom.error);
        this.dom.date
            .append(this.dom.title)
            .append(this.dom.buttons)
            .append(this.dom.calendar);
        this.dom.input.classAdd('dt-datetime');
        this._init();
    }
    /**
     * Build the control and assign initial event handlers
     */
    _init() {
        var that = this;
        var classPrefix = this.c.classPrefix;
        var last = this.dom.input.val();
        var namespace = this.s.namespace;
        var onChange = function () {
            var curr = that.dom.input.val();
            if (curr !== last) {
                that.c.onChange.call(that, curr, that.s.d, that.dom.input.get(0));
                last = curr;
            }
        };
        if (!this.s.parts.date) {
            this.dom.date.css('display', 'none');
        }
        if (!this.s.parts.time) {
            this.dom.time.css('display', 'none');
        }
        if (!this.s.parts.seconds) {
            this.dom.time.children('div.' + classPrefix + '-seconds').remove();
            this.dom.time.children('span').eq(1).remove();
        }
        if (!this.c.buttons.clear) {
            this.dom.clear.css('display', 'none');
        }
        if (!this.c.buttons.today) {
            this.dom.today.css('display', 'none');
        }
        if (!this.c.buttons.selected) {
            this.dom.selected.css('display', 'none');
        }
        // Render the options
        this._optionsTitle();
        Dom.s(document).on('i18n.dt.' + namespace, function (e, settings) {
            if (settings.language.datetime) {
                util.object.assignDeep(that.c.i18n, settings.language.datetime);
                that._optionsTitle();
            }
        });
        // When attached to a hidden input, we always show the input picker, and
        // do so inline
        if (this.dom.input.attr('type') === 'hidden' || this.c.alwaysVisible) {
            this.dom.container.classAdd('inline');
            this.c.attachTo = 'input';
            this.val(this.dom.input.val(), false);
            this._show();
        }
        // Set the initial value
        if (last) {
            this.val(last, false);
        }
        // Trigger the display of the widget when clicking or focusing on the
        // input element
        this.dom.input
            .attr('autocomplete', 'off')
            .on('focus.datetime click.datetime', function () {
            // If already visible - don't do anything
            if (that.dom.container.isVisible() ||
                that.dom.input.is(':disabled')) {
                return;
            }
            // In case the value has changed by text
            last = that.dom.input.val();
            that.val(last, false);
            that._show();
        })
            .on('keyup.datetime', function () {
            // Update the calendar's displayed value as the user types
            that.val(that.dom.input.val(), false);
        });
        // Want to prevent the focus bubbling up the document to account for
        // focus capture in modals (e.g. Editor and Bootstrap). They can see the
        // focus as outside the modal and thus immediately blur focus on the
        // picker. Need to use a native addEL since jQuery changes the focusin
        // to focus for some reason! focusin bubbles, focus does not.
        this.dom.container.get(0).addEventListener('focusin', function (e) {
            e.stopPropagation();
        });
        // Main event handlers for input in the widget
        this.dom.container
            .on('change', 'select', function () {
            var select = Dom.s(this);
            var val = parseInt(select.val());
            if (select.classHas(classPrefix + '-month')) {
                // Month select
                that._correctMonth(that.s.display, val);
                that._setTitle();
                that._setCalander();
            }
            else if (select.classHas(classPrefix + '-year')) {
                // Year select
                that.s.display.setUTCFullYear(val);
                that._setTitle();
                that._setCalander();
            }
            else if (select.classHas(classPrefix + '-hours') ||
                select.classHas(classPrefix + '-ampm')) {
                // Hours - need to take account of AM/PM input if present
                if (that.s.parts.hours12) {
                    var hours = parseInt(that.dom.container
                        .find('.' + classPrefix + '-hours')
                        .val(), 10);
                    var pm = that.dom.container
                        .find('.' + classPrefix + '-ampm')
                        .val() === 'pm';
                    that.s.d.setUTCHours(hours === 12 && !pm
                        ? 0
                        : pm && hours !== 12
                            ? hours + 12
                            : hours);
                }
                else {
                    that.s.d.setUTCHours(val);
                }
                that._setTime();
                that._writeOutput(true);
                onChange();
            }
            else if (select.classHas(classPrefix + '-minutes')) {
                // Minutes select
                that.s.d.setUTCMinutes(val);
                that._setTime();
                that._writeOutput(true);
                onChange();
            }
            else if (select.classHas(classPrefix + '-seconds')) {
                // Seconds select
                that.s.d.setSeconds(val);
                that._setTime();
                that._writeOutput(true);
                onChange();
            }
            that.dom.input.focus();
            that._position();
        })
            .on('click', function (e) {
            var d = that.s.d;
            var nodeName = e.target.nodeName.toLowerCase();
            var target = nodeName === 'span' ? e.target.parentNode : e.target;
            nodeName = target.nodeName.toLowerCase();
            if (nodeName === 'select') {
                return;
            }
            e.stopPropagation();
            if (nodeName === 'a') {
                e.preventDefault();
                if (Dom.s(target).classHas(classPrefix + '-clear')) {
                    // Clear the value and don't change the display
                    that.s.d = null;
                    that.dom.input.val('');
                    that._writeOutput();
                    that._setCalander();
                    that._setTime();
                    onChange();
                }
                else if (Dom.s(target).classHas(classPrefix + '-today')) {
                    // Don't change the value, but jump to the month
                    // containing today
                    that.s.display = new Date();
                    that._setTitle();
                    that._setCalander();
                }
                else if (Dom.s(target).classHas(classPrefix + '-selected')) {
                    // Don't change the value, but jump to where the
                    // selected value is
                    that.s.display = new Date(that.s.d.getTime());
                    that._setTitle();
                    that._setCalander();
                }
            }
            if (nodeName === 'button') {
                var button = Dom.s(target);
                var parent = button.parent();
                if (parent.classHas('disabled') &&
                    !parent.classHas('range')) {
                    button.blur();
                    return;
                }
                if (parent.classHas(classPrefix + '-iconLeft')) {
                    // Previous month
                    that.s.display.setUTCMonth(that.s.display.getUTCMonth() - 1);
                    that._setTitle();
                    that._setCalander();
                    that.dom.input.focus();
                }
                else if (parent.classHas(classPrefix + '-iconRight')) {
                    // Next month
                    that._correctMonth(that.s.display, that.s.display.getUTCMonth() + 1);
                    that._setTitle();
                    that._setCalander();
                    that.dom.input.focus();
                }
                else if (button.closest('.' + classPrefix + '-time').count()) {
                    var val = button.data('value');
                    var unit = button.data('unit');
                    d = that._needValue();
                    if (unit === 'minutes') {
                        if (parent.classHas('disabled') &&
                            parent.classHas('range')) {
                            that.s.minutesRange = val;
                            that._setTime();
                            return;
                        }
                        else {
                            that.s.minutesRange = null;
                        }
                    }
                    if (unit === 'seconds') {
                        if (parent.classHas('disabled') &&
                            parent.classHas('range')) {
                            that.s.secondsRange = val;
                            that._setTime();
                            return;
                        }
                        else {
                            that.s.secondsRange = null;
                        }
                    }
                    // Specific to hours for 12h clock
                    if (val === 'am') {
                        if (d.getUTCHours() >= 12) {
                            val = d.getUTCHours() - 12;
                        }
                        else {
                            return;
                        }
                    }
                    else if (val === 'pm') {
                        if (d.getUTCHours() < 12) {
                            val = d.getUTCHours() + 12;
                        }
                        else {
                            return;
                        }
                    }
                    var set = unit === 'hours'
                        ? 'setUTCHours'
                        : unit === 'minutes'
                            ? 'setUTCMinutes'
                            : 'setSeconds';
                    d[set](val);
                    that._setCalander();
                    that._setTime();
                    that._writeOutput(true);
                    onChange();
                }
                else {
                    // Calendar click
                    d = that._needValue();
                    // Can't be certain that the current day will exist in
                    // the new month, and likewise don't know that the
                    // new day will exist in the old month, But 1 always
                    // does, so we can change the month without worry of a
                    // recalculation being done automatically by `Date`
                    d.setUTCDate(1);
                    d.setUTCFullYear(button.data('year'));
                    d.setUTCMonth(button.data('month'));
                    d.setUTCDate(button.data('day'));
                    that._writeOutput(true);
                    // Don't hide if there is a time picker, since we want to
                    // be able to select a time as well.
                    if (!that.s.parts.time) {
                        // This is annoying but IE has some kind of async
                        // behaviour with focus and the focus from the above
                        // write would occur after this hide - resulting in
                        // the calendar opening immediately
                        setTimeout(function () {
                            that._hide();
                        }, 10);
                    }
                    else {
                        that._setCalander();
                        that._setTime();
                    }
                    onChange();
                }
            }
            else {
                // Click anywhere else in the widget - return focus to the
                // input element
                that.dom.input.focus();
            }
        });
    }
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Private
     */
    /**
     * Compare the date part only of two dates - this is made super easy by the
     * toDateString method!
     *
     * @param a Date 1
     * @param b Date 2
     */
    _compareDates(a, b) {
        // Can't use toDateString as that converts to local time
        // luxon uses different method names so need to be able to call them
        return this._isLuxon()
            ? dateLib.DateTime.fromJSDate(a).toUTC().toISODate() ===
                dateLib.DateTime.fromJSDate(b).toUTC().toISODate()
            : this._dateToUtcString(a) === this._dateToUtcString(b);
    }
    /**
     * Convert from one format to another
     *
     * @param val Value
     * @param from Format to convert from. If null a `Date` must be given
     * @param to Format to convert to. If null a `Date` will be returned
     * @returns Converted value
     */
    _convert(val, from, to) {
        if (!val) {
            return val;
        }
        if (!dateLib) {
            // Note that in here from and to can either be null or YYYY-MM-DD
            // They cannot be anything else
            if ((!from && !to) || (from && to)) {
                // No conversion
                return val;
            }
            else if (!from && val instanceof Date) {
                // Date in, string back
                return (val.getUTCFullYear() +
                    '-' +
                    this._pad(val.getUTCMonth() + 1) +
                    '-' +
                    this._pad(val.getUTCDate()));
            }
            else if (typeof val === 'string') {
                // (! to)
                // String in, date back
                var match = val.match(/(\d{4})\-(\d{2})\-(\d{2})/);
                return match
                    ? new Date(parseInt(match[1]), parseInt(match[2]) - 1, parseInt(match[3]))
                    : null;
            }
        }
        else if (this._isLuxon()) {
            // Luxon
            var dtLux = val instanceof Date
                ? dateLib.DateTime.fromJSDate(val).toUTC()
                : dateLib.DateTime.fromFormat(val, from);
            if (!dtLux.isValid) {
                return null;
            }
            return to ? dtLux.toFormat(to) : dtLux.toJSDate();
        }
        else {
            // Moment / DayJS
            var dtMo = val instanceof Date
                ? dateLib.utc(val, undefined, this.c.locale, this.c.strict)
                : dateLib(val, from, this.c.locale, this.c.strict);
            if (!dtMo.isValid()) {
                return null;
            }
            return to ? dtMo.format(to) : dtMo.toDate();
        }
    }
    /**
     * When changing month, take account of the fact that some months don't have
     * the same number of days. For example going from January to February you
     * can have the 31st of Jan selected and just add a month since the date
     * would still be 31, and thus drop you into March.
     *
     * @param date  Date - will be modified
     * @param month Month to set
     */
    _correctMonth(date, month) {
        var days = this._daysInMonth(date.getUTCFullYear(), month);
        var correctDays = date.getUTCDate() > days;
        date.setUTCMonth(month);
        if (correctDays) {
            date.setUTCDate(days);
            date.setUTCMonth(month);
        }
    }
    /**
     * Get the number of days in a method. Based on
     * http://stackoverflow.com/a/4881951 by Matti Virkkunen
     *
     * @param  year  Year
     * @param  month Month (starting at 0)
     */
    _daysInMonth(year, month) {
        //
        var isLeap = year % 4 === 0 && (year % 100 !== 0 || year % 400 === 0);
        var months = [
            31,
            isLeap ? 29 : 28,
            31,
            30,
            31,
            30,
            31,
            31,
            30,
            31,
            30,
            31
        ];
        return months[month];
    }
    /**
     * Create a new date object which has the UTC values set to the local time.
     * This allows the local time to be used directly for the library which
     * always bases its calculations and display on UTC.
     *
     * @param  s Date to "convert"
     * @return Shifted date
     */
    _dateToUtc(s) {
        if (!s) {
            return s;
        }
        return new Date(Date.UTC(s.getFullYear(), s.getMonth(), s.getDate(), s.getHours(), s.getMinutes(), s.getSeconds()));
    }
    /**
     * Create a UTC ISO8601 date part from a date object
     *
     * @param  d Date to "convert"
     * @return ISO formatted date
     */
    _dateToUtcString(d) {
        // luxon uses different method names so need to be able to call them
        return this._isLuxon()
            ? dateLib.DateTime.fromJSDate(d).toUTC().toISODate()
            : d.getUTCFullYear() +
                '-' +
                this._pad(d.getUTCMonth() + 1) +
                '-' +
                this._pad(d.getUTCDate());
    }
    /**
     * Hide the control and remove events related to its display
     *
     * @param destroy Flag to indicate that the instance is being destroyed
     */
    _hide(destroy = false) {
        if (!destroy &&
            (this.dom.input.attr('type') === 'hidden' || this.c.alwaysVisible)) {
            // Normally we wouldn't need to redraw the calander if it changes
            // and then hides, but if it is hidden, then we do need to make sure
            // that it is correctly up to date.
            this._setCalander();
            this._setTime();
            return;
        }
        var namespace = this.s.namespace;
        this.dom.container.detach();
        Dom.w.off('.' + namespace);
        Dom.s(document)
            .off('keydown.' + namespace)
            .off('keyup.' + namespace)
            .off('click.' + namespace);
        Dom.s('div.dt-scroll').off('scroll.' + namespace);
        Dom.s('div.DTE_Body_Content').off('scroll.' + namespace);
        Dom.s(this.dom.input.get(0).offsetParent).off('.' + namespace);
    }
    /**
     * Convert a 24 hour value to a 12 hour value
     *
     * @param val 24 hour value
     * @return 12 hour value
     */
    _hours24To12(val) {
        return val === 0 ? 12 : val > 12 ? val - 12 : val;
    }
    /**
     * Generate the HTML for a single day in the calendar - this is basically
     * and HTML cell with a button that has data attributes so we know what was
     * clicked on (if it is clicked on) and a bunch of classes for styling.
     *
     * @param  {object} day Day object from the `_htmlMonth` method
     * @return {string}     HTML cell
     */
    _htmlDay(day) {
        var classPrefix = this.c.classPrefix;
        if (day.empty) {
            return '<td class="' + classPrefix + '-empty"></td>';
        }
        var classes = ['selectable'];
        if (day.disabled) {
            classes.push('disabled');
        }
        if (day.today) {
            classes.push('now');
        }
        if (day.selected) {
            classes.push('selected');
        }
        return ('<td data-day="' +
            day.day +
            '" class="' +
            classes.join(' ') +
            '">' +
            '<button class="' +
            classPrefix +
            '-button ' +
            classPrefix +
            '-day" type="button" ' +
            'data-year="' +
            day.year +
            '" data-month="' +
            day.month +
            '" data-day="' +
            day.day +
            '">' +
            '<span>' +
            day.day +
            '</span>' +
            '</button>' +
            '</td>');
    }
    /**
     * Create the HTML for a month to be displayed in the calendar table.
     *
     * Based upon the logic used in Pikaday - MIT licensed
     * Copyright (c) 2014 David Bushell
     * https://github.com/dbushell/Pikaday
     *
     * @param  year  Year
     * @param  month Month (starting at 0)
     * @return Calendar month HTML
     */
    _htmlMonth(year, month) {
        var now = this._dateToUtc(new Date()), days = this._daysInMonth(year, month), before = new Date(Date.UTC(year, month, 1)).getUTCDay(), data = [], row = [];
        if (this.c.firstDay === null) {
            this.c.firstDay = this._localeFirstDay();
        }
        if (this.c.firstDay > 0) {
            before -= this.c.firstDay;
            if (before < 0) {
                before += 7;
            }
        }
        var cells = days + before, after = cells;
        while (after > 7) {
            after -= 7;
        }
        cells += 7 - after;
        var minDate = this.c.minDate;
        var maxDate = this.c.maxDate;
        if (minDate) {
            minDate.setUTCHours(0);
            minDate.setUTCMinutes(0);
            minDate.setSeconds(0);
        }
        if (maxDate) {
            maxDate.setUTCHours(23);
            maxDate.setUTCMinutes(59);
            maxDate.setSeconds(59);
        }
        for (var i = 0, r = 0; i < cells; i++) {
            var day = new Date(Date.UTC(year, month, 1 + (i - before))), selected = this.s.d ? this._compareDates(day, this.s.d) : false, today = this._compareDates(day, now), empty = i < before || i >= days + before, disabled = (minDate && day < minDate) || (maxDate && day > maxDate);
            var disableDays = this.c.disableDays;
            if (Array.isArray(disableDays) &&
                disableDays.includes(day.getUTCDay())) {
                disabled = true;
            }
            else if (typeof disableDays === 'function' &&
                disableDays(day) === true) {
                disabled = true;
            }
            var dayConfig = {
                day: 1 + (i - before),
                month: month,
                year: year,
                selected: selected,
                today: today,
                disabled: disabled,
                empty: empty
            };
            row.push(this._htmlDay(dayConfig));
            if (++r === 7) {
                if (this.c.showWeekNumber) {
                    row.unshift(this._htmlWeekOfYear(i - before, month, year));
                }
                data.push('<tr>' + row.join('') + '</tr>');
                row = [];
                r = 0;
            }
        }
        var classPrefix = this.c.classPrefix;
        var className = classPrefix + '-table';
        if (this.c.showWeekNumber) {
            className += ' weekNumber';
        }
        // Show / hide month icons based on min/max
        if (minDate) {
            var underMin = minDate >= new Date(Date.UTC(year, month, 1, 0, 0, 0));
            this.dom.title
                .find('div.' + classPrefix + '-iconLeft')
                .css('display', underMin ? 'none' : 'block');
        }
        if (maxDate) {
            var overMax = maxDate < new Date(Date.UTC(year, month + 1, 1, 0, 0, 0));
            this.dom.title
                .find('div.' + classPrefix + '-iconRight')
                .css('display', overMax ? 'none' : 'block');
        }
        return ('<table class="' +
            className +
            '">' +
            '<thead>' +
            this._htmlMonthHead() +
            '</thead>' +
            '<tbody>' +
            data.join('') +
            '</tbody>' +
            '</table>');
    }
    /**
     * Create the calendar table's header (week days)
     *
     * @return {string} HTML cells for the row
     */
    _htmlMonthHead() {
        var a = [];
        var firstDay = this.c.firstDay;
        var i18n = this.c.i18n;
        // Take account of the first day shift
        var dayName = function (day) {
            day += firstDay;
            while (day >= 7) {
                day -= 7;
            }
            return i18n.weekdays[day];
        };
        // Empty cell in the header
        if (this.c.showWeekNumber) {
            a.push('<th></th>');
        }
        for (var i = 0; i < 7; i++) {
            a.push('<th>' + dayName(i) + '</th>');
        }
        return a.join('');
    }
    /**
     * Create a cell that contains week of the year - ISO8601
     *
     * Based on https://stackoverflow.com/questions/6117814/ and
     * http://techblog.procurios.nl/k/n618/news/view/33796/14863/
     *
     * @param  d Day of month
     * @param  m Month of year (zero index)
     * @param  y Year
     * @return HTML string for a day
     */
    _htmlWeekOfYear(d, m, y) {
        var date = new Date(y, m, d, 0, 0, 0, 0);
        // First week of the year always has 4th January in it
        date.setDate(date.getDate() + 4 - (date.getDay() || 7));
        var oneJan = new Date(y, 0, 1);
        var weekNum = Math.ceil(((date - oneJan) / 86400000 + 1) / 7);
        return ('<td class="' + this.c.classPrefix + '-week">' + weekNum + '</td>');
    }
    /**
     * Determine if Luxon is being used
     *
     * @returns Flag for Luxon
     */
    _isLuxon() {
        return dateLib &&
            dateLib.DateTime &&
            dateLib.Duration &&
            dateLib.Settings
            ? true
            : false;
    }
    /**
     * Determine if Moment is being used
     *
     * @returns Flag for Moment
     */
    _isMoment() {
        return dateLib &&
            typeof dateLib.isDate === 'function' &&
            typeof dateLib.weekdays === 'function'
            ? true
            : false;
    }
    /**
     * Determine the first day of the week based on the current locale
     */
    _localeFirstDay() {
        let locale = this.c.locale;
        if (locale === 'en') {
            // Somewhat bonkers way to get the current locale, but there doesn't
            // seem to be a better way
            let browserLocale = new Intl.NumberFormat().resolvedOptions()
                .locale;
            // Not yet in Firefox
            if (Intl.Locale) {
                let loc = new Intl.Locale(browserLocale);
                if (loc.getWeekInfo) {
                    let weekInfo = loc.getWeekInfo();
                    // Safari and new Chrome have it as a function
                    if (typeof weekInfo.firstDay === 'function') {
                        return weekInfo.firstDay();
                    }
                    else if (typeof weekInfo.firstDay === 'number') {
                        // Old Chrome as an accessor property
                        return weekInfo.firstDay;
                    }
                }
            }
        }
        if (this._isMoment()) {
            return dateLib.localeData(this.c.locale).firstDayOfWeek();
        }
        // There doesn't appear to be a way to do it in luxon
        // Default to Monday
        return 1;
    }
    /**
     * Check if the instance has a date object value - it might be null.
     * If is doesn't set one to now.
     * @returns A Date object
     */
    _needValue() {
        if (!this.s.d) {
            this.s.d = this._dateToUtc(new Date());
            if (!this.s.parts.time) {
                this.s.d.setUTCHours(0);
                this.s.d.setUTCMinutes(0);
                this.s.d.setSeconds(0);
                this.s.d.setMilliseconds(0);
            }
        }
        return this.s.d;
    }
    /**
     * Create option elements from a range in an array
     *
     * @param selector Class name unique to the select element to use
     * @param values   Array of values
     * @param labels Array of labels. If given must be the same length as the
     *   values parameter.
     */
    _options(selector, values, labels) {
        if (!labels) {
            labels = values;
        }
        var select = this.dom.container.find('select.' + this.c.classPrefix + '-' + selector);
        select.empty();
        for (var i = 0, ien = values.length; i < ien; i++) {
            select.append(Dom.c('option').attr('value', values[i]).text(labels[i]));
        }
    }
    /**
     * Set an option and update the option's span pair (since the select element
     * has opacity 0 for styling)
     *
     * @param selector Class name unique to the select element to use
     * @param val      Value to set
     */
    _optionSet(selector, val) {
        var select = this.dom.container.find('select.' + this.c.classPrefix + '-' + selector);
        var span = select.parent().children('span');
        select.val(val);
        var selected = select
            .find('option')
            .filter(e => e.selected);
        span.html(selected.count() !== 0 ? selected.text() : this.c.i18n.unknown);
    }
    /**
     * Create time options list.
     *
     * @param unit Time unit - hours, minutes or seconds
     * @param count Count range - 12, 24 or 60
     * @param val Existing value for this unit
     * @param allowed Values allow for selection
     * @param range Override range
     */
    _optionsTime(unit, count, val, allowed, range) {
        var classPrefix = this.c.classPrefix;
        var container = this.dom.container.find('div.' + classPrefix + '-' + unit);
        var i, j;
        var render = count === 12
            ? function (i) {
                return i;
            }
            : this._pad;
        var className = classPrefix + '-table';
        var i18n = this.c.i18n;
        if (!container.count()) {
            return;
        }
        var a = '';
        var span = 10;
        var button = function (value, label, className = null) {
            // Shift the value for PM
            if (count === 12 && typeof value === 'number') {
                if (val >= 12) {
                    value += 12;
                }
                if (value == 12) {
                    value = 0;
                }
                else if (value == 24) {
                    value = 12;
                }
            }
            var selected = val === value ||
                (value === 'am' && val < 12) ||
                (value === 'pm' && val >= 12)
                ? 'selected'
                : '';
            if (typeof value === 'number' &&
                allowed &&
                !allowed.includes(value)) {
                selected += ' disabled';
            }
            if (className) {
                selected += ' ' + className;
            }
            return ('<td class="selectable ' +
                selected +
                '">' +
                '<button class="' +
                classPrefix +
                '-button ' +
                classPrefix +
                '-day" type="button" data-unit="' +
                unit +
                '" data-value="' +
                value +
                '">' +
                '<span>' +
                label +
                '</span>' +
                '</button>' +
                '</td>');
        };
        if (count === 12) {
            // Hours with AM/PM
            a += '<tr>';
            for (i = 1; i <= 6; i++) {
                a += button(i, render(i));
            }
            a += button('am', i18n.amPm[0]);
            a += '</tr>';
            a += '<tr>';
            for (i = 7; i <= 12; i++) {
                a += button(i, render(i));
            }
            a += button('pm', i18n.amPm[1]);
            a += '</tr>';
            span = 7;
        }
        else if (count === 24) {
            // Hours - 24
            var c = 0;
            for (j = 0; j < 4; j++) {
                a += '<tr>';
                for (i = 0; i < 6; i++) {
                    a += button(c, render(c));
                    c++;
                }
                a += '</tr>';
            }
            span = 6;
        }
        else {
            // Minutes and seconds
            a += '<tr>';
            for (j = 0; j < 60; j += 10) {
                a += button(j, render(j), 'range');
            }
            a += '</tr>';
            // Slight hack to allow for the different number of columns
            a +=
                '</tbody></thead><table class="' +
                    className +
                    ' ' +
                    className +
                    '-nospace"><tbody>';
            var start = range !== null
                ? range
                : val === -1
                    ? 0
                    : Math.floor(val / 10) * 10;
            a += '<tr>';
            for (j = start + 1; j < start + 10; j++) {
                a += button(j, render(j));
            }
            a += '</tr>';
            span = 6;
        }
        container
            .empty()
            .html('<table class="' +
            className +
            '">' +
            '<thead><tr><th colspan="' +
            span +
            '">' +
            i18n[unit] +
            '</th></tr></thead>' +
            '<tbody>' +
            a +
            '</tbody>' +
            '</table>');
    }
    /**
     * Create the options for the month and year
     */
    _optionsTitle() {
        var i18n = this.c.i18n;
        var min = this.c.minDate;
        var max = this.c.maxDate;
        var minYear = min ? min.getFullYear() : null;
        var maxYear = max ? max.getFullYear() : null;
        var i = minYear !== null
            ? minYear
            : new Date().getFullYear() - this.c.yearRange;
        var j = maxYear !== null
            ? maxYear
            : new Date().getFullYear() + this.c.yearRange;
        this._options('month', this._range(0, 11), i18n.months);
        this._options('year', this._range(i, j));
        // Set the language strings in case any have changed
        this.dom.today.text(i18n.today).text(i18n.today);
        this.dom.selected.text(i18n.selected).text(i18n.selected);
        this.dom.clear.text(i18n.clear).text(i18n.clear);
        this.dom.previous
            .attr('title', i18n.previous)
            .children('button')
            .text(i18n.previous);
        this.dom.next
            .attr('title', i18n.next)
            .children('button')
            .text(i18n.next);
    }
    /**
     * Simple two digit pad
     *
     * @param  {integer} i      Value that might need padding
     * @return {string|integer} Padded value
     */
    _pad(i) {
        return i < 10 ? '0' + i : i;
    }
    /**
     * Position the calendar to look attached to the input element
     */
    _position() {
        var offset = this.c.attachTo === 'input'
            ? this.dom.input.position()
            : this.dom.input.offset();
        var container = this.dom.container;
        var inputHeight = this.dom.input.height('outer');
        if (container.classHas('inline')) {
            container.insertAfter(this.dom.input);
            return;
        }
        if (this.s.parts.date && this.s.parts.time && Dom.w.width() > 550) {
            container.classAdd('horizontal');
        }
        else {
            container.classRemove('horizontal');
        }
        if (this.c.attachTo === 'input') {
            container
                .css({
                top: offset.top + inputHeight + 'px',
                left: offset.left + 'px'
            })
                .insertAfter(this.dom.input);
        }
        else {
            container
                .css({
                top: offset.top + inputHeight + 'px',
                left: offset.left + 'px'
            })
                .appendTo('body');
        }
        var calHeight = container.height('outer');
        var calWidth = container.width('outer');
        var scrollTop = Dom.w.scrollTop();
        // Correct to the bottom
        if (offset.top + inputHeight + calHeight - scrollTop > Dom.w.height()) {
            var newTop = offset.top - calHeight;
            container.css('top', newTop < 0 ? '0' : newTop + 'px');
        }
        // Correct to the right
        if (calWidth + offset.left > Dom.w.width()) {
            var newLeft = Dom.w.width() - calWidth - 5;
            // Account for elements which are inside a position absolute element
            if (this.c.attachTo === 'input') {
                newLeft -= container
                    .map(e => e.offsetParent)
                    .offset().left;
            }
            container.css('left', newLeft < 0 ? '0' : newLeft + 'px');
        }
    }
    /**
     * Create a simple array with a range of values
     *
     * @param  start   Start value (inclusive)
     * @param  end     End value (inclusive)
     * @param  inc Increment value
     * @return Created array
     */
    _range(start, end, inc = 1) {
        var a = [];
        for (var i = start; i <= end; i += inc) {
            a.push(i);
        }
        return a;
    }
    /**
     * Redraw the calendar based on the display date - this is a destructive
     * operation
     */
    _setCalander() {
        if (this.s.display) {
            this.dom.calendar
                .empty()
                .html(this._htmlMonth(this.s.display.getUTCFullYear(), this.s.display.getUTCMonth()));
        }
    }
    /**
     * Set the month and year for the calendar based on the current display date
     */
    _setTitle() {
        this._optionSet('month', this.s.display.getUTCMonth());
        this._optionSet('year', this.s.display.getUTCFullYear());
    }
    /**
     * Set the time based on the current value of the widget
     */
    _setTime() {
        var that = this;
        var d = this.s.d;
        // luxon uses different method names so need to be able to call them.
        // This happens a few time later in this method too
        var luxDT = null;
        if (this._isLuxon()) {
            luxDT = dateLib.DateTime.fromJSDate(d).toUTC();
        }
        var hours = luxDT != null ? luxDT.hour : d ? d.getUTCHours() : -1;
        var allowed = function (prop) {
            // Backwards compt with `Increment` option
            return that.c[prop + 'Available']
                ? that.c[prop + 'Available']
                : that._range(0, 59, that.c[prop + 'Increment']);
        };
        this._optionsTime('hours', this.s.parts.hours12 ? 12 : 24, hours, this.c.hoursAvailable);
        this._optionsTime('minutes', 60, luxDT != null ? luxDT.minute : d ? d.getUTCMinutes() : -1, allowed('minutes'), this.s.minutesRange);
        this._optionsTime('seconds', 60, luxDT != null ? luxDT.second : d ? d.getSeconds() : -1, allowed('seconds'), this.s.secondsRange);
    }
    /**
     * Show the widget and add events to the document required only while it
     * is displayed
     *
     */
    _show() {
        var that = this;
        var namespace = this.s.namespace;
        this._position();
        // Need to reposition on scroll
        Dom.w.on('scroll.' + namespace + ' resize.' + namespace, function () {
            that._position();
        });
        Dom.s('div.DTE_Body_Content').on('scroll.' + namespace, function () {
            that._position();
        });
        Dom.s('div.dt-scroll').on('scroll.' + namespace, function () {
            that._position();
        });
        var offsetParent = this.dom.input.get(0).offsetParent;
        if (offsetParent !== document.body) {
            Dom.s(offsetParent).on('scroll.' + namespace, function () {
                that._position();
            });
        }
        // On tab focus will move to a different field (no keyboard navigation
        // in the date picker - this might need to be changed).
        Dom.s(document).on('keydown.' + namespace, function (e) {
            if (that.dom.container.isVisible() &&
                (e.keyCode === 9 || // tab
                    e.keyCode === 13) // return
            ) {
                that._hide();
            }
        });
        // Esc is on keyup to allow Editor to know that the container was hidden
        // and thus not act on the esc itself.
        Dom.s(document).on('keyup.' + namespace, function (e) {
            if (that.dom.container.isVisible() && e.keyCode === 27) {
                // esc
                e.preventDefault();
                that._hide();
            }
        });
        clearTimeout(this.s.showTo);
        // We can't use blur to hide, as we want to keep the picker open while
        // to let the user select from it. But if focus is moved outside of of
        // the picker, then we auto hide.
        this.dom.input.on('blur', function (e) {
            that.s.showTo = setTimeout(function () {
                let name = document.activeElement.tagName.toLowerCase();
                if (document.activeElement === that.dom.input.get(0)) {
                    return;
                }
                if (that.dom.container.find(document.activeElement).count()) {
                    return;
                }
                if (['input', 'select', 'button'].includes(name)) {
                    that.hide();
                }
            }, 10);
        });
        // Hide if clicking outside of the widget - but in a different click
        // event from the one that was used to trigger the show (bubble and
        // inline)
        setTimeout(function () {
            Dom.s(document).on('click.' + namespace, function (e) {
                if (!Dom.s(e.target)
                    .closest(that.dom.container.get(0))
                    .count() &&
                    e.target !== that.dom.input.get(0)) {
                    that._hide();
                }
            });
        }, 10);
    }
    /**
     * Write the formatted string to the input element this control is attached
     * to
     */
    _writeOutput(focus = false, change = true) {
        var date = this.s.d;
        var out = '';
        var input = this.dom.input;
        if (date) {
            out = this._convert(date, null, this.c.format);
        }
        input.val(out);
        if (change) {
            // Create a DOM synthetic event. Can't use $().trigger() as
            // that doesn't actually trigger non-jQuery event listeners
            var event = new Event('change', { bubbles: true });
            input.get(0).dispatchEvent(event);
        }
        if (input.attr('type') === 'hidden') {
            this.val(out, false);
        }
        if (focus) {
            input.focus();
        }
    }
}
/**
 * For generating unique namespaces
 */
DateTime._instance = 0;
/**
 * To indicate to DataTables what type of library this is
 */
DateTime.type = 'DateTime';
/**
 * Defaults for the date time picker
 */
DateTime.defaults = {
    alwaysVisible: false,
    attachTo: 'body',
    buttons: {
        clear: false,
        selected: false,
        today: false
    },
    classPrefix: 'dt-datetime',
    disableDays: null,
    display: null,
    firstDay: null,
    format: 'YYYY-MM-DD',
    hoursAvailable: null,
    i18n: {
        clear: 'Clear',
        previous: 'Previous',
        next: 'Next',
        months: [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December'
        ],
        weekdays: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
        amPm: ['am', 'pm'],
        hours: 'Hour',
        minutes: 'Minute',
        seconds: 'Second',
        unknown: '-',
        today: 'Today',
        selected: 'Selected'
    },
    maxDate: null,
    minDate: null,
    minutesAvailable: null,
    minutesIncrement: 1, // deprecated
    strict: true,
    locale: 'en',
    onChange: () => { },
    secondsAvailable: null,
    secondsIncrement: 1, // deprecated
    showWeekNumber: false,
    yearRange: 25
};
DateTime.version = '2.0.0';
// Global export - if no conflicts
// TODO is this right in the UDM?
if (!window.DateTime) {
    window.DateTime = DateTime;
}
// Make available via jQuery
if (window.jQuery) {
    window.jQuery.fn.dtDateTime = function (options) {
        return this.each(function () {
            new DateTime(this, options);
        });
    };
}
// Attach to DataTables
DataTable.DateTime = DateTime;
DataTable.use('datetime', DateTime);
// And to Editor (legacy)
if (DataTable.Editor) {
    DataTable.Editor.DateTime = DateTime;
}




return DateTime;
}));
