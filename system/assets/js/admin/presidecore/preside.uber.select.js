/**
 * jQuery Uber Select, a plugin by Dominic Watson based on
 * the Chosen plugin that can be found here: https://github.com/harvesthq/chosen
 *
 * The codebase and usage is much the same, but we now have ajax and sortable support as well as the option
 * to provide templates for rendering results and selected items.
 */

(function( $ ) {
	var UberSelect, SelectParser;

	SelectParser = (function() {
		function SelectParser() {
			this.options_index = 0;
			this.parsed = [];
		}

		SelectParser.prototype.add_option = function( option ) {
			if (option.nodeName.toUpperCase() === "OPTION") {
				if ( option.text !== "" ) {
					this.parsed.push({
						value: option.value,
						text: option.text,
						selected: option.selected,
						disabled: option.disabled,
						classes: option.className,
						style: option.style.cssText,
						active: option.active
					});
				} else {
					this.parsed.push({
						empty: true
					});
				}
			}
		};

		return SelectParser;
	})();

	SelectParser.select_to_array = function(select) {
		var child, parser, _i, _len, _ref;

		parser = new SelectParser();
		_ref = select.childNodes;
		for (_i = 0, _len = _ref.length; _i < _len; _i++) {
			child = _ref[_i];
			parser.add_option( child );
		}
		return parser.parsed;
	};

	UberSelect = (function() {
		function UberSelect( form_field, options ) {
			this.form_field = form_field;
			this.options = options != null ? options : {};
			this.is_multiple = this.form_field.multiple;
			this.selected = [];
			this.fieldPopulatedDeferred = $.Deferred();
			this.setup_preselected_value();
			this.set_sortable_options();
			this.set_rendering_templates();
			this.set_default_text();
			this.set_default_values();
			this.setup();
			this.set_up_html();
			this.register_observers();
		}

		UberSelect.prototype.setup_preselected_value = function(){
			var options, _i=0, _len;

			this.value = this.form_field.getAttribute( "data-value" );
			this.value = !this.value ? [] : this.value.split( ',' );

			if ( !this.value.length ) {
				options = SelectParser.select_to_array( this.form_field );
				_len    = options.length;
				for( ; _i<_len; _i++ ){
					if ( options[ _i ].selected ) {
						this.value.push( options[ _i ].value );
					}
				}
			}
		};

		UberSelect.prototype.set_sortable_options = function(){
			this.is_sortable = this.form_field.getAttribute( "data-sortable" );
			this.is_sortable = this.is_sortable && this.is_sortable === "true";
		};

		UberSelect.prototype.set_rendering_templates = function(){
			var templateId = this.form_field.getAttribute( "data-result-template" )
			  , $template;

			this.result_template   = "{{text}}";
			this.selected_template = "{{text}}";

			if ( templateId ){
				$template = $( "#" + templateId );
				if ( $template.length ) {
					this.result_template = $template.html();
				}
			}

			templateId = this.form_field.getAttribute( "data-selected-template" );
			if ( templateId ){
				$template = $( "#" + templateId );
				if ( $template.length ) {
					this.selected_template = $template.html();
				}
			}
		};

		UberSelect.prototype.set_default_values = function() {
			var _this = this;

			this.click_test_action = function(evt) {
				return _this.test_active_click(evt);
			};
			this.activate_action = function(evt) {
				return _this.activate_field(evt);
			};
			this.active_field = false;
			this.mouse_on_container = false;
			this.results_showing = false;
			this.result_highlighted = null;
			this.result_single_selected = null;
			this.allow_single_deselect = this.options.allow_single_deselect || false;
			this.disable_search_threshold = this.options.disable_search_threshold || 0;
			this.disable_search = this.options.disable_search || false;
			this.enable_split_word_search = this.options.enable_split_word_search != null ? this.options.enable_split_word_search : true;
			this.search_contains = this.options.search_contains || false;
			this.single_backstroke_delete = this.options.single_backstroke_delete != null ? this.options.single_backstroke_delete : true;
			this.max_selected_options = this.options.max_selected_options || Infinity;
			this.inherit_select_classes = this.options.inherit_select_classes || false;
			this.display_selected_options = this.options.display_selected_options != null ? this.options.display_selected_options : true;
			this.quick_add_text = this.form_field.getAttribute( "data-quick-add-text" ) || "Press ENTER to create a new tag, '{{value}}'";
			return this.display_disabled_options = this.options.display_disabled_options != null ? this.options.display_disabled_options : true;
		};

		UberSelect.prototype.set_default_text = function() {
			if (this.form_field.getAttribute("data-placeholder")) {
				this.default_text = this.form_field.getAttribute("data-placeholder");
			} else if (this.is_multiple) {
				this.default_text = this.options.placeholder_text_multiple || this.options.placeholder_text || UberSelect.default_multiple_text;
			} else {
				this.default_text = this.options.placeholder_text_single || this.options.placeholder_text || UberSelect.default_single_text;
			}
			return this.results_none_found = this.form_field.getAttribute("data-no_results_text") || this.options.no_results_text || UberSelect.default_no_result_text;
		};

		UberSelect.prototype.mouse_enter = function() {
			return this.mouse_on_container = true;
		};

		UberSelect.prototype.mouse_leave = function() {
			return this.mouse_on_container = false;
		};

		UberSelect.prototype.input_focus = function(evt) {
			var _this = this;

			if (this.is_multiple) {
				if (!this.active_field) {
					return setTimeout((function() {
						return _this.container_mousedown();
					}), 50);
				}
			} else {
				if (!this.active_field) {
					return this.activate_field();
				}
			}
		};

		UberSelect.prototype.input_blur = function(evt) {
			var _this = this;

			if (!this.mouse_on_container) {
				this.active_field = false;
				return setTimeout((function() {
					return _this.blur_test();
				}), 100);
			}
		};

		UberSelect.prototype.result_add_option = function( option ) {
			var classes, style;

			option = $.extend( {}, {
				  disabled      : false
				, superQuickAdd : false
				, classes       : ""
				, style         : { cssText : "" }
				, text          : ""
				, value         : ""
				, active        : true
				, inactiveClass : ""
			}, option );

			if ( option.active === "" ) {
				option.active = true;
			}

			if (!this.include_option_in_results(option)) {
				return '';
			}
			classes = [];

			option.selected = this.is_option_selected( option );

			if (!option.disabled && !(option.selected && this.is_multiple)) {
				classes.push("active-result");
			}
			if (option.disabled && !(option.selected && this.is_multiple)) {
				classes.push("disabled-result");
			}
			if (option.selected) {
				classes.push("result-selected");
			}
			if ( option.superQuickAdd ) {
				classes.push("result-super-quick-add-suggestion");
			}
			if (option.classes !== "") {
				classes.push(option.classes);
			}
			if( !option.active ) {
				option.inactiveClass  = "inactive";
			}

			style = option.style.cssText !== "" ? " style=\"" + option.style + "\"" : "";
			return "<li class=\"" + (classes.join(' ')) + "\"" + style + ">"
					+ Mustache.render( this.result_template , option ) +
					"</li>";
		};

		UberSelect.prototype.results_update_field = function() {
			this.set_default_text();
			if (!this.is_multiple) {
				this.results_reset_cleanup();
			}
			this.result_clear_highlight();
			this.result_single_selected = null;
			this.results_build( function(){
				if (this.results_showing) {
					return this.winnow_results();
				}
			} );
		};

		UberSelect.prototype.results_toggle = function() {
			if (this.results_showing) {
				return this.results_hide();
			} else {
				return this.results_show();
			}
		};

		UberSelect.prototype.results_search = function(evt) {
			if (this.results_showing) {
				return this.winnow_results();
			} else {
				return this.results_show();
			}
		};

		UberSelect.prototype.winnow_results = function() {
			var $uberSelect = this
			  , searchText  = $uberSelect.get_search_text();

			$uberSelect.search_engine.get( searchText, function( suggestions ){
				var userHasChangedSearch = searchText != $uberSelect.get_search_text()

				if ( !userHasChangedSearch ){
					if ( $uberSelect.allowSuperQuickAdd() && searchText.length && ( !suggestions.length || suggestions[0].text.toLowerCase() != searchText.toLowerCase() ) ) {
						if ( suggestions.length && suggestions[0].superQuickAdd ) {
							suggestions.shift();
						}
						suggestions.unshift( {
							  text          : $uberSelect.get_quick_add_text( searchText )
							, value         : searchText
							, superQuickAdd : true
						} );
					}
					if ( suggestions.length < 1 && searchText.length ) {
						$uberSelect.clear_suggestions();
						return $uberSelect.no_results( searchText );
					} else {
						$uberSelect.render_suggestions( suggestions );
						return $uberSelect.winnow_results_set_highlight();
					}
				}
			} );
		};


		UberSelect.prototype.choices_count = function() {
			var option, _i, _len, _ref;

			if (this.selected_option_count != null) {
				return this.selected_option_count;
			}
			this.selected_option_count = 0;
			_ref = this.form_field.options;
			if ( _ref ){
				for (_i = 0, _len = _ref.length; _i < _len; _i++) {
					option = _ref[_i];
					if (option.selected) {
						this.selected_option_count += 1;
					}
				}
			}
			return this.selected_option_count;
		};

		UberSelect.prototype.choices_click = function(evt) {
			evt.preventDefault();
			if (!(this.results_showing || this.is_disabled)) {
				return this.results_show();
			}
		};

		UberSelect.prototype.keyup_checker = function(evt) {
			var stroke, _ref;

			stroke = (_ref = evt.which) != null ? _ref : evt.keyCode;
			this.search_field_scale();
			switch (stroke) {
				case 8:
					if (this.is_multiple && this.backstroke_length < 1 && this.choices_count() > 0) {
						return this.keydown_backstroke();
					} else if (!this.pending_backstroke) {
						this.result_clear_highlight();
						return this.results_search();
					}
					break;
				case 13:
					evt.preventDefault();
					return this.result_select(evt);
				case 27:
					if (this.results_showing) {
						this.results_hide();
					}
					return true;
				case 9:
				case 38:
				case 40:
				case 16:
				case 91:
				case 17:
					break;
				default:
					return this.results_search();
			}
		};

		UberSelect.prototype.container_width = function() {
			if (this.options.width != null) {
				return this.options.width;
			} else {
				return "" + this.form_field.offsetWidth + "px";
			}
		};

		UberSelect.prototype.include_option_in_results = function(option) {
			if (this.is_multiple && (!this.display_selected_options && option.selected)) {
				return false;
			}
			if (!this.display_disabled_options && option.disabled) {
				return false;
			}
			if (option.empty) {
				return false;
			}
			return true;
		};

		UberSelect.prototype.setup_search_engine = function(){
			var uberSelect = this
			  , i
			  , prefetch_url  = this.form_field.getAttribute( "data-prefetch-url" )
			  , remote_url    = this.form_field.getAttribute( "data-remote-url" )
			  , display_limit = this.form_field.getAttribute( "data-display-limit" );

			if ( isNaN( this.prefetch_ttl ) ) {
				this.prefetch_ttl = 0;
			}

			if ( display_limit === null || isNaN( display_limit ) ) {
				this.display_limit = 200;
			} else {
				this.display_limit = parseInt( display_limit );
			}

			this.local_options = SelectParser.select_to_array( this.form_field );

			for( i=this.local_options.length-1; i>=0; i-- ){
				if ( this.local_options[i].empty ) { this.local_options.splice( i, 1 ); }
			}

			if( this.filter && this.filter.length ){
				this.prefetch_url = prefetch_url + this.filter;
				this.remote_url   = remote_url + this.filter;
			}else{
				this.prefetch_url = prefetch_url;
				this.remote_url   = remote_url;
			}

			this.search_engine = new Bloodhound( {
				  local          : this.local_options
				, prefetch       : this.prefetch_url
				, remote         : this.remote_url
				, datumTokenizer : function(d) { return Bloodhound.tokenizers.nonwordandunderscore( d.text ); }
			 	, queryTokenizer : Bloodhound.tokenizers.nonwordandunderscore
			 	, limit          : this.display_limit
			 	, dupDetector    : function( remote, local ){ return remote.value == local.value }
			} );

			( this.search_engine.initialize() ).done( function(){
				if ( uberSelect.isSearchable() ) {
					uberSelect.results_build( function(){
						uberSelect.set_selected_order();
						uberSelect.set_tab_index();
						uberSelect.set_label_behavior();
						uberSelect.form_field_jq.trigger("chosen:ready", {
							chosen: uberSelect
						});
					} );
				} else {
					uberSelect.form_field_jq.trigger("chosen:ready", {
						chosen: uberSelect
					});
				}
				uberSelect.fieldPopulatedDeferred.resolve();
				$( uberSelect.form_field ).closest( "form" ).trigger( "uberSelectInit" );
			} );
		};

		UberSelect.prototype.get_option_by_value = function( value ){
			var _i=0, _ref=this.select_options || [], _len=_ref.length;
			for( ; _i<_len; _i++ ){
				if ( _ref[_i].value === value ) {
					return _ref[_i];
				}
			}
			return;
		};

		UberSelect.prototype.fetch_items_by_value = function( value, callback ){
			$.ajax( this.remote_url.replace( '%QUERY', '' ), {
				  data    : { values : value }
				, cache   : false
				, method  : "post"
				, success : callback
				, async   : false
			} );
		};

		UberSelect.prototype.is_option_selected = function( option ){
			var selected = this.hidden_field.val(), _i=0, _len;
			selected = selected.length ? selected.split( "," ) : [];

			_len = selected.length;
			for( ; _i<_len; _i++ ){
				if ( selected[_i] == option.value ) {
					return true;
				}
			}

			return false;
		};

		UberSelect.prototype.setup = function() {
			this.form_field_jq = $(this.form_field);

			return this.is_rtl = this.form_field_jq.hasClass("chosen-rtl");
		};

		UberSelect.prototype.set_up_html = function() {
			var container_classes, container_props, $uberSelect=this, searchable=this.isSearchable();

			container_classes = ["chosen-container"];
			container_classes.push("chosen-container-" + (this.is_multiple ? "multi" : "single"));
			if (this.inherit_select_classes && this.form_field.className) {
				container_classes.push(this.form_field.className);
			}
			if (this.is_rtl) {
				container_classes.push("chosen-rtl");
			}
			container_props = {
				'class': container_classes.join(' '),
				'title': this.form_field.title
			};
			if (this.form_field.id.length) {
				container_props.id = this.form_field.id.replace(/[^\w]/g, '_') + "_chosen";
			}
			this.container = $("<div />", container_props);

			if ( searchable ) {
				if (this.is_multiple) {
					this.container.html('<ul class="chosen-choices"><li class="search-field"><input type="text" value="' + this.default_text + '" class="default" autocomplete="off" style="width:25px;" /></li></ul><div class="chosen-drop"><ul class="chosen-results"></ul></div>');
				} else {
					this.container.html('<a class="chosen-single chosen-default" tabindex="-1"><span>' + this.default_text + '</span><div class="chosen-action-icon"><b></b></div></a><div class="chosen-drop"><div class="chosen-search"><input type="text" autocomplete="off" /></div><ul class="chosen-results"></ul></div>');
				}
			} else {
				if (this.is_multiple) {
					this.container.html('<ul class="chosen-choices"></ul>');
				} else {
					this.container.html('<a class="chosen-single chosen-default" tabindex="-1"><span>' + this.default_text + '</span></a>');
				}
			}

			this.container.append( '<input type="hidden" class="chosen-hidden-field" />');
			this.disabled_if_unfiltered = this.form_field_jq.data( 'disabledIfUnfiltered' ) == true;
			this.hidden_field = this.container.find( 'input.chosen-hidden-field' ).first();
			this.hidden_field.attr( 'name', this.form_field_jq.attr( 'name' ) );
			this.hidden_field.data( "uberSelect", this );
			this.form_field_jq.removeAttr( 'name' );

			this.form_field_jq.hide().after(this.container);

			if ( searchable ) {
				this.dropdown = this.container.find('div.chosen-drop').first();
				this.search_field = this.container.find('input').first();
				this.search_results = this.container.find('ul.chosen-results').first();
				this.search_field_scale();
				this.search_no_results = this.container.find('li.no-results').first();

				if ( this.is_multiple ) {
					this.search_container = this.container.find('li.search-field').first();
				} else {
					this.search_container = this.container.find('div.chosen-search').first();
				}
			}

			if ( this.is_multiple ) {
				this.search_choices = this.container.find('ul.chosen-choices').first();
				this.form_field_jq.on( "change", function(){ $uberSelect.set_selected_order() } );

				if (this.is_sortable) {
					this.search_choices.sortable( { items:".search-choice", update:function(){ $uberSelect.form_field_jq.trigger( "change" ); } } );
				}
			} else {
				this.selected_item = this.container.find('.chosen-single').first();
			}

			this.setup_filter();
			this.setup_search_engine();
			this.disable_if_unfiltered();

			if ( typeof this.filter_field !== "undefined" ) {
				this.filter_field.on('change',function(){
					$uberSelect.setup_filter();
					$uberSelect.setup_search_engine();
					$uberSelect.disable_if_unfiltered();
				});
			}
		};

		UberSelect.prototype.setup_filter = function() {
			var filterBy      = this.form_field.getAttribute( "data-filter-by" )
			  , filterByField = this.form_field.getAttribute( "data-filter-by-field" )
			  , filters       = []
			  , filterInput, filterByValue, i;

			if ( filterBy !== null && filterBy.length ) {
				filterBy      = filterBy.split( ',' );
				filterByField = filterByField.split( ',' );

				for( i=0; i<filterBy.length; i++ ) {
					filterInput = $( "input[name='" + filterBy[ i ] + "']" );

					if ( filterInput.length ) {
						this.filter_field = filterInput;
						filterByValue = this.filter_field.val();
					} else {
						filterByValue = cfrequest[ filterBy[ i ] ] || null;
					}

					if ( filterByValue !== null && typeof filterByValue !== "undefined" ) {
						filters.push ( '&', filterByField[ i ], '=', filterByValue, '&filterByFields=', filterByField[ i ] );
					}
				}

				if ( filters.length ) {
					this.filter = filters.join( '' );
				}
			}

		};

		UberSelect.prototype.disable_if_unfiltered = function() {
			if ( this.disabled_if_unfiltered ) {
				if ( this.filter_field.val().length ) {
					this.form_field_jq.removeAttr( 'disabled' );
					this.container.siblings( '.quick-add-btn' ).removeClass( 'disabled' );
				} else {
					this.form_field_jq.attr( 'disabled', 'disabled' );
					this.container.siblings( '.quick-add-btn' ).addClass( 'disabled' );
				}
				this.search_field_disabled();
			}
		}

		UberSelect.prototype.register_observers = function() {
			var _this = this;

			this.container.bind('mousedown.chosen', function(evt) {
				_this.container_mousedown(evt);
			});
			this.container.bind('mouseup.chosen', function(evt) {
				_this.container_mouseup(evt);
			});
			this.container.bind('mouseenter.chosen', function(evt) {
				_this.mouse_enter(evt);
			});
			this.container.bind('mouseleave.chosen', function(evt) {
				_this.mouse_leave(evt);
			});

			this.form_field_jq.bind("chosen:updated.chosen", function(evt) {
				_this.results_update_field(evt);
			});
			this.form_field_jq.bind("chosen:activate.chosen", function(evt) {
				_this.activate_field(evt);
			});
			this.form_field_jq.bind("chosen:open.chosen", function(evt) {
				_this.container_mousedown(evt);
			});

			if ( this.isSearchable() ) {
				this.search_field.bind('blur.chosen', function(evt) {
					_this.input_blur(evt);
				});
				this.search_field.bind('keyup.chosen', function(evt) {
					_this.keyup_checker(evt);
				});
				this.search_field.bind('keydown.chosen', function(evt) {
					_this.keydown_checker(evt);
				});
				this.search_field.bind('focus.chosen', function(evt) {
					_this.input_focus(evt);
				});
				this.search_results.bind('mouseup.chosen', function(evt) {
					_this.search_results_mouseup(evt);
				});
				this.search_results.bind('mouseover.chosen', function(evt) {
					_this.search_results_mouseover(evt);
				});
				this.search_results.bind('mouseout.chosen', function(evt) {
					_this.search_results_mouseout(evt);
				});
				this.search_results.bind('mousewheel.chosen DOMMouseScroll.chosen', function(evt) {
					_this.search_results_mousewheel(evt);
				});
				if (this.is_multiple) {
					return this.search_choices.bind('click.chosen', function(evt) {
						_this.choices_click(evt);
					});
				}
			}
			if ( !this.is_multiple ) {
				return this.container.bind('click.chosen', function(evt) {
					evt.preventDefault();
				});
			}
		};

		UberSelect.prototype.destroy = function() {
			$(document).unbind("click.chosen", this.click_test_action);
			if (this.search_field[0].tabIndex) {
				this.form_field_jq[0].tabIndex = this.search_field[0].tabIndex;
			}
			this.container.remove();
			this.form_field_jq.removeData('uberSelect');
			this.form_field_jq.attr( 'name', this.hidden_field.attr('name') );
			this.hidden_field.remove();
			return this.form_field_jq.show();
		};

		UberSelect.prototype.search_field_disabled = function() {
			this.is_disabled = this.form_field_jq[0].disabled;
			if (this.is_disabled) {
				this.container.addClass('chosen-disabled');
				this.search_field[0].disabled = true;
				if (!this.is_multiple) {
					this.selected_item.unbind("focus.chosen", this.activate_action);
				}
				return this.close_field();
			} else {
				this.container.removeClass('chosen-disabled');
				this.search_field[0].disabled = false;
				if (!this.is_multiple) {
					return this.selected_item.bind("focus.chosen", this.activate_action);
				}
			}
		};

		UberSelect.prototype.container_mousedown = function(evt) {
			if (!this.is_disabled) {
				if (evt && evt.type === "mousedown" && !this.results_showing) {
					evt.preventDefault();
				}
				if ( this.isSearchable() && !((evt != null) && ($(evt.target)).hasClass("remove-choice-link"))) {
					if (!this.active_field) {
						if (this.is_multiple) {
							this.search_field.val("");
						}
						$(document).bind('click.chosen', this.click_test_action);
						this.results_show();
					} else if (!this.is_multiple && evt && (($(evt.target)[0] === this.selected_item[0]) || $(evt.target).parents("a.chosen-single").length)) {
						evt.preventDefault();
						this.results_toggle();
					}
					return this.activate_field();
				}
			}
		};

		UberSelect.prototype.container_mouseup = function(evt) {
			if (this.isSearchable() && evt.target.nodeName === "ABBR" && !this.is_disabled) {
				return this.results_reset(evt);
			}
		};

		UberSelect.prototype.search_results_mousewheel = function(evt) {
			var delta, _ref1, _ref2;

			delta = -((_ref1 = evt.originalEvent) != null ? _ref1.wheelDelta : void 0) || ((_ref2 = evt.originialEvent) != null ? _ref2.detail : void 0);
			if (delta != null) {
				evt.preventDefault();
				if (evt.type === 'DOMMouseScroll') {
					delta = delta * 40;
				}
				return this.search_results.scrollTop(delta + this.search_results.scrollTop());
			}
		};

		UberSelect.prototype.blur_test = function(evt) {
			if (!this.active_field && this.container.hasClass("chosen-container-active")) {
				return this.close_field();
			}
		};

		UberSelect.prototype.close_field = function() {
			$(document).unbind("click.chosen", this.click_test_action);
			this.active_field = false;
			this.results_hide();
			this.container.removeClass("chosen-container-active");
			this.clear_backstroke();
			this.show_search_field_default();
			return this.search_field_scale();
		};

		UberSelect.prototype.activate_field = function() {
			this.container.addClass("chosen-container-active");
			this.active_field = true;
			this.search_field.val(this.search_field.val());
			return this.search_field.focus();
		};

		UberSelect.prototype.test_active_click = function(evt) {
			if (this.container.is($(evt.target).closest('.chosen-container'))) {
				return this.active_field = true;
			} else {
				return this.close_field();
			}
		};

		UberSelect.prototype.results_build = function( callback ) {
			var uberSelect = this
			  , _build;

			_build = function( suggestions ){
				uberSelect.parsing               = true;
				uberSelect.selected_option_count = null;
				uberSelect.select_options        = suggestions;

				if ( uberSelect.is_multiple ) {
					uberSelect.search_choices.find( "li.search-choice" ).remove();
				} else {
					uberSelect.single_set_selected_text();
					if ( uberSelect.disable_search || ( uberSelect.disable_search_threshold && uberSelect.form_field.options.length <= uberSelect.disable_search_threshold ) ) {
						uberSelect.search_field[0].readOnly = true;
						uberSelect.container.addClass( "chosen-container-single-nosearch" );
					} else {
						uberSelect.search_field[0].readOnly = false;
						uberSelect.container.removeClass( "chosen-container-single-nosearch" );
					}
				}

				uberSelect.populate_preselections();
				uberSelect.render_suggestions( uberSelect.select_options );
				uberSelect.search_field_disabled();
				uberSelect.show_search_field_default();
				uberSelect.search_field_scale();
				uberSelect.parsing = false;

				callback.call( uberSelect );

			};

			if ( this.local_options.length || ( this.prefetch_url && this.prefetch_url.length ) ) {
				uberSelect.search_engine.get( "", _build );
			} else {
				_build( [] );
			}
		};

		UberSelect.prototype.populate_preselections = function(){
			var uberSelect = this
			  , _ref  = uberSelect.value
			  , _i    = 0
			  , _len  = _ref.length
			  , _data = []
			  , _option
			  , _addOption
			  , _valueSelected;

			_addOption = function( option ){
				if ( uberSelect.is_multiple ) {
					uberSelect.choice_build( option );
					uberSelect.hidden_field.val( uberSelect.hidden_field.val() + "," + option.value );
				} else {
					uberSelect.single_set_selected_text( Mustache.render( uberSelect.selected_template, option ) );
					uberSelect.hidden_field.val( option.value );
				}
			};

			_valueSelected = function( value ){
				var _i=0, _len=_ref.length;
				for( ; _i<_len; _i++ ){
					if ( value == _ref[_i] ) {
						return true;
					}
				}
				return false;
			};

			for( ; _i<_len; _i++ ){
				_option = uberSelect.get_option_by_value( _ref[_i] );
				if ( typeof _option === "undefined" ) {
					break;
				}
				_data.push( _option );
			}

			if ( _data.length != _ref.length && uberSelect.remote_url && uberSelect.remote_url.length ) {
				for( ; _i<_len; _i++ ){
					uberSelect.add_to_hidden_field( _ref[_i] );
				}
				uberSelect.fetch_items_by_value( uberSelect.value.join( ","), function( data ){
					var _i=0; _len=data.length;
					for( ; _i<_len; _i++ ){
						if ( _valueSelected( data[_i].value ) ) {
							_addOption( data[ _i ] );
						}
					}
				} );

			} else {
				for( _i=0; _i<_data.length; _i++ ){ _addOption( _data[ _i ] ); }
			}
		};

		UberSelect.prototype.render_suggestions = function( suggestions ){
			var $suggestion, _i=0, _len=suggestions.length;

			this.clear_suggestions();

			for( ; _i<_len; _i++ ){
				$suggestion = $( this.result_add_option( suggestions[_i] ) );
				$suggestion.data( "item", suggestions[_i] );
				this.search_results.append( $suggestion );
			}
		};

		UberSelect.prototype.result_do_highlight = function(el) {
			var high_bottom, high_top, maxHeight, visible_bottom, visible_top;

			if (el.length) {
				this.result_clear_highlight();
				this.result_highlight = el;
				this.result_highlight.addClass("highlighted");
				maxHeight = parseInt(this.search_results.css("maxHeight"), 10);
				visible_top = this.search_results.scrollTop();
				visible_bottom = maxHeight + visible_top;
				high_top = this.result_highlight.position().top + this.search_results.scrollTop();
				high_bottom = high_top + this.result_highlight.outerHeight();
				if (high_bottom >= visible_bottom) {
					return this.search_results.scrollTop((high_bottom - maxHeight) > 0 ? high_bottom - maxHeight : 0);
				} else if (high_top < visible_top) {
					return this.search_results.scrollTop(high_top);
				}
			}
		};

		UberSelect.prototype.result_clear_highlight = function() {
			if (this.result_highlight) {
				this.result_highlight.removeClass("highlighted");
			}
			return this.result_highlight = null;
		};

		UberSelect.prototype.results_show = function() {
			if (this.is_multiple && this.max_selected_options <= this.choices_count()) {
				this.form_field_jq.trigger("chosen:maxselected", {
					uberSelect: this
				});
				return false;
			}
			this.container.addClass("chosen-with-drop");
			this.form_field_jq.trigger("chosen:showing_dropdown", {
				uberSelect: this
			});
			this.results_showing = true;
			this.search_field.focus();
			this.search_field.val(this.search_field.val());
			return this.winnow_results();
		};

		UberSelect.prototype.clear_suggestions = function() {
			this.search_results.html("");
		};

		UberSelect.prototype.results_hide = function() {
			if (this.results_showing) {
				this.result_clear_highlight();
				this.container.removeClass("chosen-with-drop");
				this.form_field_jq.trigger("chosen:hiding_dropdown", {
					uberSelect: this
				});
			}
			return this.results_showing = false;
		};

		UberSelect.prototype.set_tab_index = function(el) {
			var ti;

			if (this.form_field.tabIndex) {
				ti = this.form_field.tabIndex;
				this.form_field.tabIndex = -1;
				return this.search_field[0].tabIndex = ti;
			}
		};

		UberSelect.prototype.set_label_behavior = function() {
			var _this = this;

			this.form_field_label = this.form_field_jq.parents("label");
			if (!this.form_field_label.length && this.form_field.id.length) {
				this.form_field_label = $("label[for='" + this.form_field.id + "']");
			}
			if (this.form_field_label.length > 0) {
				return this.form_field_label.bind('click.chosen', function(evt) {
					if (_this.is_multiple) {
						return _this.container_mousedown(evt);
					} else {
						return _this.activate_field();
					}
				});
			}
		};

		UberSelect.prototype.show_search_field_default = function() {
			if (this.is_multiple && this.choices_count() < 1 && !this.active_field) {
				this.search_field.val(this.default_text);
				return this.search_field.addClass("default");
			} else {
				this.search_field.val("");
				return this.search_field.removeClass("default");
			}
		};

		UberSelect.prototype.search_results_mouseup = function(evt) {
			var target;

			target = $(evt.target).hasClass("active-result") ? $(evt.target) : $(evt.target).parents(".active-result").first();
			if (target.length) {
				this.result_highlight = target;
				this.result_select(evt);
				return this.search_field.focus();
			}
		};

		UberSelect.prototype.search_results_mouseover = function(evt) {
			var target;

			target = $(evt.target).hasClass("active-result") ? $(evt.target) : $(evt.target).parents(".active-result").first();
			if (target) {
				return this.result_do_highlight(target);
			}
		};

		UberSelect.prototype.search_results_mouseout = function(evt) {
			if ($(evt.target).hasClass("active-result" || $(evt.target).parents('.active-result').first())) {
				return this.result_clear_highlight();
			}
		};

		UberSelect.prototype.choice_build = function(item) {
			var choice, close_link,
				_this = this;

			choice = $('<li />', {
				"class": "search-choice"
			}).html("<span>" + Mustache.render( this.selected_template, item ) + "</span>");
			if ( item.disabled ) {
				choice.addClass('search-choice-disabled');
			} else {
				close_link = $('<a />', {
					"class": 'remove-choice-link fa fa-times'
				});
				close_link.bind('click.chosen', function(evt) {
					return _this.choice_destroy_link_click(evt);
				});
				choice.append( close_link );
			}

			choice.data( "item", item );
			return this.isSearchable() ? this.search_container.before(choice) : this.search_choices.append(choice);
		};

		UberSelect.prototype.choice_destroy_link_click = function(evt) {
			evt.preventDefault();
			evt.stopPropagation();
			if (!this.is_disabled) {
				return this.choice_destroy($(evt.target));
			}
		};

		UberSelect.prototype.clear = function() {
			var uberSelect = this;

			uberSelect.clear_suggestions();
			uberSelect.search_choices.find( ".search-choice" ).each( function(){
				uberSelect.choice_destroy( $( this ) );
			} );
		};

		UberSelect.prototype.choice_destroy = function(link) {
			var $li = link.closest( "li.search-choice" )
			  , item = $li.data( "item" );

			if ( this.result_deselect( item ) ) {
				$li.remove();

				this.hidden_field.trigger("change");
				this.form_field_jq.trigger("change", {
					deselected: item.__value || item.value
				});

				if ( this.isSearchable() ) {
					this.show_search_field_default();
					if (this.is_multiple && this.choices_count() > 0 && this.search_field.val().length < 1) {
						this.results_hide();
					}
					item.selected = false;
					this.winnow_results();
					return this.search_field_scale();
				}
			}
		};

		UberSelect.prototype.results_reset = function() {
			this.hidden_field.val( "" );
			this.selected = [];
			this.selected_option_count = null;
			this.single_set_selected_text();
			this.show_search_field_default();
			this.results_reset_cleanup();
			this.hidden_field.trigger("change");
			this.form_field_jq.trigger("change");
			if (this.active_field) {
				return this.results_hide();
			}
		};

		UberSelect.prototype.results_reset_cleanup = function() {
			return this.selected_item.find("abbr").remove();
		};

		UberSelect.prototype.result_select = function(evt) {
			var high, item, selected_index;

			if ( this.result_highlight && this.result_highlight.data( 'item' ) ) {
				high = this.result_highlight;
				this.result_clear_highlight();

				if ( this.is_multiple && this.max_selected_options <= this.choices_count() ) {
					this.form_field_jq.trigger("chosen:maxselected", {
						userSelect: this
					} );
					return false;
				}
				if ( this.is_multiple ) {
					high.removeClass( "active-result" );
				} else {
					if ( this.result_single_selected ) {
						this.result_single_selected.removeClass( "result-selected" );
					}
					this.result_single_selected = high;
				}
				high.addClass( "result-selected" );

				item = high.data( 'item' );

				this.selected_option_count = null;

				if ( item.superQuickAdd ) {
					this.super_quick_add(  item.value );
				} else {
					this.select_item( item );
				}

				if ( !( (evt.metaKey || evt.ctrlKey ) && this.is_multiple ) ) {
					this.results_hide();
				}
				this.search_field.val( "" );
				this.hidden_field.trigger("change");
				this.form_field_jq.trigger("change", {
					'selected': this.hidden_field.val()
				});

				return this.search_field_scale();
			}
		};

		UberSelect.prototype.select = function( value, text ){
			var item, uberSelect;

			if ( !this.is_option_selected( { value:value } ) ) {
				item       = this.get_option_by_value( value );
				uberSelect = this;

				if ( item ) {
					uberSelect.select_item( item );
				} else if ( uberSelect.remote_url && uberSelect.remote_url.length ) {
					this.add_to_hidden_field( value );
					uberSelect.fetch_items_by_value( value, function( data ){
						var _i=0; _len=data.length;
						for( ; _i<_len; _i++ ){
							uberSelect.select_item( data[_i] );
						}
					} );
				} else if ( text && text.length ) {
					uberSelect.select_item( { text:text, value:value } );
				}
			}
		};

		UberSelect.prototype.select_item = function( item ){
			if ( this.is_multiple && this.max_selected_options <= this.choices_count() ) {
				this.form_field_jq.trigger("chosen:maxselected", {
					userSelect: this
				} );
				return false;
			}

			this.add_to_hidden_field( item.__value || item.value );

			if ( this.is_multiple ) {
				this.choice_build( item );
			} else {
				this.selected = [];
				this.single_set_selected_text( Mustache.render( this.selected_template, item ) );
			}

			this.selected.push( item );

			this.hidden_field.trigger( "change" );
			this.form_field_jq.trigger( "change" );
		}

		UberSelect.prototype.add_to_hidden_field = function( value ){
			var selectedValues, i;

			if ( this.is_multiple && this.max_selected_options <= this.choices_count() ) {
				this.form_field_jq.trigger("chosen:maxselected", {
					userSelect: this
				} );
				return false;
			}

			if ( this.is_multiple ) {
				selectedValues = this.hidden_field.val().split( "," );
				for( i=0; i<selectedValues.length; i++ ) {
					if ( selectedValues[ i ] == value ) {
						return;
					}
				}

				this.hidden_field.val( this.hidden_field.val() + "," + value );
			} else {
				this.hidden_field.val( value );
			}
		}

		UberSelect.prototype.single_set_selected_text = function(text) {
			if (text == null) {
				text = this.default_text;
			}
			if (text === this.default_text) {
				this.selected_item.addClass("chosen-default");
			} else {
				this.single_deselect_control_build();
				this.selected_item.removeClass("chosen-default");
			}
			return this.selected_item.find("span").html(text);
		};

		UberSelect.prototype.result_deselect = function( item ) {
			var values, itemIndex;
			if ( this.is_multiple ) {
				values = this.hidden_field.val();
				if ( values.length ) {
					values    = values.split( ',' );
					itemIndex = values.indexOf( item.__value || item.value );
					if ( itemIndex !== -1 ){
						values.splice( itemIndex, 1 );
					}
					this.hidden_field.val( values.join( ',' ) );
				}

				for( itemIndex=0; itemIndex<this.selected.length; itemIndex++ ){
					if ( this.selected[itemIndex].value == item.__value || item.value ) {
						this.selected.splice( itemIndex, 1 );
						break;
					}
				}

			} else {
				this.hidden_field.val( "" );
				this.selected = [];
			}

			this.result_clear_highlight();
			this.selected_option_count = null;

			return true;
		};

		UberSelect.prototype.single_deselect_control_build = function() {
			if (!this.allow_single_deselect) {
				return;
			}
			if (!this.selected_item.find("abbr").length) {
				this.selected_item.find("span").first().after("<abbr class=\"remove-choice-link fa fa-times\"></abbr>");
			}
			return this.selected_item.addClass("chosen-single-with-deselect");
		};

		UberSelect.prototype.get_search_text = function() {
			if (this.search_field.val() === this.default_text) {
				return "";
			} else {
				return $('<div/>').text($.trim(this.search_field.val())).html();
			}
		};

		UberSelect.prototype.winnow_results_set_highlight = function() {
			var do_high, selected_results;

			selected_results = !this.is_multiple ? this.search_results.find(".result-selected.active-result") : [];
			do_high = selected_results.length ? selected_results.first() : this.search_results.find(".active-result").first();
			if (do_high != null) {
				return this.result_do_highlight(do_high);
			}
		};

		UberSelect.prototype.no_results = function(terms) {
			var no_results_html;

			no_results_html = $('<li class="no-results">' + this.results_none_found + ' "<span></span>"</li>');
			no_results_html.find("span").first().html(terms);
			return this.search_results.append(no_results_html);
		};

		UberSelect.prototype.no_results_clear = function() {
			return this.search_results.find(".no-results").remove();
		};

		UberSelect.prototype.keydown_arrow = function() {
			var next_sib;

			if (this.results_showing && this.result_highlight) {
				next_sib = this.result_highlight.nextAll("li.active-result").first();
				if (next_sib) {
					return this.result_do_highlight(next_sib);
				}
			} else {
				return this.results_show();
			}
		};

		UberSelect.prototype.keyup_arrow = function() {
			var prev_sibs;

			if (!this.results_showing && !this.is_multiple) {
				return this.results_show();
			} else if (this.result_highlight) {
				prev_sibs = this.result_highlight.prevAll("li.active-result");
				if (prev_sibs.length) {
					return this.result_do_highlight(prev_sibs.first());
				} else {
					if (this.choices_count() > 0) {
						this.results_hide();
					}
					return this.result_clear_highlight();
				}
			}
		};

		UberSelect.prototype.keydown_backstroke = function() {
			var next_available_destroy;

			if (this.pending_backstroke) {
				this.choice_destroy(this.pending_backstroke.find("a").first());
				return this.clear_backstroke();
			} else {
				next_available_destroy = this.search_container.siblings("li.search-choice").last();
				if (next_available_destroy.length && !next_available_destroy.hasClass("search-choice-disabled")) {
					this.pending_backstroke = next_available_destroy;
					if (this.single_backstroke_delete) {
						return this.keydown_backstroke();
					} else {
						return this.pending_backstroke.addClass("search-choice-focus");
					}
				}
			}
		};

		UberSelect.prototype.clear_backstroke = function() {
			if (this.pending_backstroke) {
				this.pending_backstroke.removeClass("search-choice-focus");
			}
			return this.pending_backstroke = null;
		};

		UberSelect.prototype.keydown_checker = function(evt) {
			var stroke, _ref1;

			stroke = (_ref1 = evt.which) != null ? _ref1 : evt.keyCode;
			this.search_field_scale();
			if (stroke !== 8 && this.pending_backstroke) {
				this.clear_backstroke();
			}
			switch (stroke) {
				case 8:
					this.backstroke_length = this.search_field.val().length;
					break;
				case 9:
					if (this.results_showing && !this.is_multiple) {
						this.result_select(evt);
					}
					this.mouse_on_container = false;
					break;
				case 13:
					evt.preventDefault();
					break;
				case 38:
					evt.preventDefault();
					this.keyup_arrow();
					break;
				case 40:
					evt.preventDefault();
					this.keydown_arrow();
					break;
			}
		};

		UberSelect.prototype.search_field_scale = function() {
			var div, f_width, h, style, style_block, styles, w, _i, _len;

			if (this.is_multiple) {
				h = 0;
				w = 0;
				style_block = "position:absolute; left: -1000px; top: -1000px; display:none;";
				styles = ['font-size', 'font-style', 'font-weight', 'font-family', 'line-height', 'text-transform', 'letter-spacing'];
				for (_i = 0, _len = styles.length; _i < _len; _i++) {
					style = styles[_i];
					style_block += style + ":" + this.search_field.css(style) + ";";
				}
				div = $('<div />', {
					'style': style_block
				});
				div.text(this.search_field.val());
				$('body').append(div);
				w = div.width() + 25;
				div.remove();

				if ( this.container.is( ":visible" ) ) {
					f_width = this.container.outerWidth();
					if (w > f_width - 10) {
						w = f_width - 10;
					}
				}
				return this.search_field.css({
					'width': w + 'px'
				});
			}
		};

		UberSelect.prototype.set_selected_order = function(){
			var newVal = [], optionVal, $uberSelect = this;
			if ( $uberSelect.is_multiple ) {
				$uberSelect.search_choices.find( "li.search-choice" ).each( function(){
					var $li = $(this)
					  , item = $li.data( "item" );

					newVal.push( item.__value || item.value );
				} );

				$uberSelect.hidden_field.val( newVal.length ? newVal.join( "," ) : "" );
			}
		};

		UberSelect.prototype.getSelected = function(){
			return this.selected;
		};

		UberSelect.prototype.isSearchable = function(){
			return typeof this.options.searchable === "undefined" || this.options.searchable;
		};

		UberSelect.prototype.allowSuperQuickAdd = function(){
			return typeof this.options.superQuickAdd !== "undefined" && this.options.superQuickAddUrl !== "undefined" && this.options.superQuickAdd;
		};

		UberSelect.prototype.super_quick_add = function( newValue ) {
			if ( !$.trim( newValue ).length ) {
				return false;
			}

			var uberSelect = this;
			var _addOption = function( option ){
				if ( uberSelect.is_multiple ) {
					uberSelect.choice_build( option );
					uberSelect.hidden_field.val( uberSelect.hidden_field.val() + "," + option.value );
				} else {
					uberSelect.single_set_selected_text( Mustache.render( uberSelect.selected_template, option ) );
					uberSelect.hidden_field.val( option.value );
				}
			};

			$.ajax( this.options.superQuickAddUrl, {
				  data    : { value : newValue }
				, cache   : false
				, method  : "post"
				, async   : false
				, success : function( data ){ _addOption( data ); }
			} );

			return true;
		}

		UberSelect.prototype.get_quick_add_text = function( searchText ) {
			return Mustache.render( this.quick_add_text, { value:searchText } );
		}

		UberSelect.browser_is_supported = function() {
			if (window.navigator.appName === "Microsoft Internet Explorer") {
				return document.documentMode >= 8;
			}
			if (/iP(od|hone)/i.test(window.navigator.userAgent)) {
				return true;
			}
			if (/Android/i.test(window.navigator.userAgent)) {
				if (/Mobile/i.test(window.navigator.userAgent)) {
					return true;
				}
			}
			return true;
		};

		UberSelect.default_multiple_text = "Select Some Options";

		UberSelect.default_single_text = "Select an Option";

		UberSelect.default_no_result_text = "No results match";

		return UberSelect;

	})();

	$.fn.extend({
		uberSelect: function( options ) {
			if ( !UberSelect.browser_is_supported() ) {
				return this;
			}
			return this.each( function( input_field ) {
				var $this, uberSelect;

				$this = $( this );
				uberSelect = $this.data( 'uberSelect' );
				if ( options === 'destroy' && uberSelect ) {
					uberSelect.destroy();
					$this.removeData( 'uberSelect' );
				} else if ( !uberSelect ) {
					$this.data( 'uberSelect', new UberSelect( this, options ) );
				}
			});
		}
	});

}).call( this, presideJQuery );
