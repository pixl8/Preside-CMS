( function( $ ){

	var PresideObjectConfigurator = (function() {
		function PresideObjectConfigurator( $originalInput ) {
			this.$originalInput = $originalInput;
			this.labelRenderer  = $originalInput.data( "configuratorLabelUrl" )
			this.setupUberSelect();

			if ( this.$originalInput.hasClass( 'configurator-add' ) ) {
				this.setupConfiguratorAdd();
			}
			if ( this.$originalInput.hasClass( 'configurator-edit' ) ) {
			 	this.setupConfiguratorEdit();
			}
		}

		PresideObjectConfigurator.prototype.setupUberSelect = function(){
			var presideObjectConfigurator = this;

			this.$originalInput.uberSelect({
				  allow_single_deselect  : true
				, inherit_select_classes : true
				, searchable             : !this.$originalInput.hasClass( 'non-searchable' )
				, removable              : !this.$originalInput.hasClass( 'non-removable' )
				, editable               : this.$originalInput.hasClass( 'configurator-edit' )
			});
			this.$uberSelect = this.$originalInput.next();
			this.uberSelect = this.$originalInput.data( "uberSelect" );

			this.uberSelect.setup_configurator_preselected_value = function(){
				var options, _i=0, _len;

				this.value = this.form_field.getAttribute( "data-value" );
				this.value = !this.value ? [] : JSON.parse( '['+this.value+']' );

				if ( this.value.length ) {
					_len = this.value.length;
					for( ; _i<_len; _i++ ){
						this.select_item( this.value[ _i ] );
					}
				}
			};

			this.uberSelect.choice_build = function( item, index ) {
				var choice, close_link, edit_link,
					_this = this;

				choice = $('<li />', {
					"class": "search-choice"
				}).html("<span>" + item.__label + "</span>");
				if ( item.disabled ) {
					choice.addClass('search-choice-disabled');
				} else {
					if(_this.options.editable) {
						edit_link = $('<a />', {
							"class": 'edit-choice-link fa fa-pencil'
						});
						choice.append( edit_link );
					}
					if(_this.options.removable) {
						close_link = $('<a />', {
							"class": 'remove-choice-link fa fa-times'
						});
						close_link.bind('click.chosen', function(evt) {
							return _this.choice_destroy_link_click(evt);
						});
						choice.append( close_link );
					}
				}

				choice.data( "item", item );

				if ( typeof index !== 'undefined' ) {
					return this.search_choices.children().eq( index ).replaceWith( choice );
				} else {
					return this.search_choices.append( choice );
				}
			};

			this.uberSelect.select_item = function( item ){
				var index = item.configurator__index;

				if ( this.is_multiple && this.max_selected_options <= this.choices_count() ) {
					this.form_field_jq.trigger("chosen:maxselected", {
						userSelect: this
					} );
					return false;
				}

				item.__value = JSON.stringify( item );

				if ( typeof index !== 'undefined' ) {
					delete item.configurator__index;
					this.selected[ index ] = item;
				} else {
					this.selected.push( item );
				}

				if ( this.is_multiple ) {
					this.choice_build( item, index );
					this.hidden_field.val( this.selected.map( function( item ){ return item.__value } ).join() );
				} else {
					this.selected = [];
					this.single_set_selected_text( item.__label );
					this.hidden_field.val( item.__value );
				}
			}

			this.uberSelect.single_deselect_control_build = function() {
				var _this = this, close_link;

				if (!this.allow_single_deselect) {
					return;
				}
				if (!this.selected_item.find("abbr").length) {
					close_link = $('<abbr />', {
						"class": 'remove-choice-link fa fa-times'
					});
					close_link.bind('click.chosen', function(evt) {
						_this.hidden_field.val( "" );
						_this.single_set_selected_text();
						_this.selected_item.find("abbr").remove();
						_this.selected = [];
					});
					this.selected_item.find("span").first().after( close_link );
				}
				return this.selected_item.addClass("chosen-single-with-deselect");
			};

			this.uberSelect.setup_configurator_preselected_value();
		};

		PresideObjectConfigurator.prototype.setupConfiguratorAdd = function(){
			var iframeSrc                 = this.$originalInput.data( "configuratorFormUrl" )
			  , modalTitle                = this.$originalInput.data( "configuratorModalTitle" )
			  , relationshipKey           = this.$originalInput.data( "relationshipKey" )
			  , sourceObject              = this.$originalInput.data( "sourceObject" )
			  , fields                    = this.$originalInput.data( "configuratorFields" ).split( "," )
			  , targetFields              = this.$originalInput.data( "configuratorTargetFields" ).split( "," )
			  , $form                     = this.$originalInput.closest( 'form' )
			  , presideObjectConfigurator = this
			  , configuratorArgs          = {}
			  , modalOptions              = {
					title     : modalTitle,
					className : "full-screen-dialog",
					buttons   : {
						cancel : {
							  label     : '<i class="fa fa-reply"></i> ' + i18n.translateResource( "cms:cancel.btn" )
							, className : "btn-default"
						},
						add : {
							  label     : '<i class="fa fa-plus"></i> ' + i18n.translateResource( "cms:add.btn" )
							, className : "btn-primary"
							, callback  : function(){ return presideObjectConfigurator.processRecord(); }
						}
					}
				}
			  , callbacks                 = {
					onLoad : function( iframe ) {
						iframe.presideObjectConfigurator = presideObjectConfigurator;
						presideObjectConfigurator.configuratorIframe = iframe;
					},
					onShow : function( modal, iframe ){
						if ( typeof iframe !== "undefined" && typeof iframe.configurator !== "undefined" ) {
							iframe.configurator.focusForm();

							return false;
						}

						modal.on('hidden.bs.modal', function (e) {
							modal.remove();
						} );
					}
				};

			configuratorArgs[ 'sourceId' ]      = $( '[name=id] ', $form ).filter( ':first' ).val();
			configuratorArgs[ 'sourceIdField' ] = relationshipKey;

			this.$configuratorAddButton = $( '<a class="btn btn-default configurator-add-btn" href="#"><i class="fa fa-plus"></i></a>' );
			if ( this.$originalInput.attr( "tabindex" ) && this.$originalInput.attr( "tabindex" ) != "-1" ) {
				this.$configuratorAddButton.attr( "tabindex", this.$originalInput.attr( "tabindex" ) );
			}

			this.$configuratorAddButton.on( "click", function( e ) {
				var dynamicIframeSrc = iframeSrc;
				for( var i=0; i<fields.length; i++ ) {
					var targetField = targetFields[ i ]
					  , $field      = $( '[name=' + fields[ i ] + ']', presideObjectConfigurator.$originalInput.closest( 'form' ) );

					if ( $field.length ) {
						configuratorArgs[ targetField ] = $field.map( function() { return $( this ).val(); } ).get().join();
					}
				}
				for( var arg in configuratorArgs ) {
					dynamicIframeSrc += '&' + arg + '=' + configuratorArgs[ arg ];
				}
				presideObjectConfigurator.configuratorIframeModal = new PresideIframeModal( dynamicIframeSrc, "100%", "100%", callbacks, modalOptions );
				presideObjectConfigurator.configuratorIframeModal.open();
			} );

			this.$uberSelect.after( this.$configuratorAddButton );
		};

		PresideObjectConfigurator.prototype.setupConfiguratorEdit = function(){
			var iframeSrc                 = this.$originalInput.data( "configuratorFormUrl" )
			  , modalTitle                = this.$originalInput.data( "configuratorModalTitle" )
			  , $form                     = this.$originalInput.closest( 'form' )
			  , presideObjectConfigurator = this
			  , modalOptions              = {
					title     : modalTitle,
					className : "full-screen-dialog",
					buttons   : {
						cancel : {
							  label     : '<i class="fa fa-reply"></i> ' + i18n.translateResource( "cms:cancel.btn" )
							, className : "btn-default"
						},
						ok : {
							  label     : '<i class="fa fa-check"></i> ' + i18n.translateResource( "cms:ok.btn" )
							, className : "btn-primary"
							, callback  : function(){ return presideObjectConfigurator.processRecord(); }
						}
					}
				}
			  , callbacks                 = {
					onLoad : function( iframe ) {
						iframe.presideObjectConfigurator = presideObjectConfigurator;
						presideObjectConfigurator.configuratorIframe = iframe;
					},
					onShow : function( modal, iframe ){
						if ( typeof iframe !== "undefined" && typeof iframe.configurator !== "undefined" ) {
							iframe.configurator.focusForm();

							return false;
						}

						modal.on('hidden.bs.modal', function (e) {
							modal.remove();
						} );
					}
				};

			this.uberSelect.container.on( "click", ".edit-choice-link", function(e){
				e.preventDefault();
				e.stopPropagation();

				var $li              = $( this ).closest( "li.search-choice" )
				  , item             = $li.data( "item" )
				  , href             = iframeSrc
				  , fields           = presideObjectConfigurator.$originalInput.data( "configuratorFields" ).split( "," )
				  , targetFields     = presideObjectConfigurator.$originalInput.data( "configuratorTargetFields" ).split( "," )
				  , configuratorArgs = {};

				item.configurator__index = $li.index();

				for( var field in item ) {
					if ( field != '__value' && field != '__label' ) {
						configuratorArgs[ field ] = item[ field ];
					}
				}
				for( var i=0; i<fields.length; i++ ) {
					var targetField = targetFields[ i ]
					  , $field      = $( '[name=' + fields[ i ] + ']', presideObjectConfigurator.$originalInput.closest( 'form' ) );

					if ( $field.length ) {
						configuratorArgs[ targetField ] = $field.map( function() { return $( this ).val(); } ).get().join();
					}
				}
				for( var arg in configuratorArgs ) {
					href += '&' + arg + '=' + configuratorArgs[ arg ];
				}

				presideObjectConfigurator.configuratorIframeModal = new PresideIframeModal( href, "100%", "100%", callbacks, modalOptions );
				presideObjectConfigurator.configuratorIframeModal.open();
			} );

		};

		PresideObjectConfigurator.prototype.addRecordToControl = function( recordData ){
			var presideObjectConfigurator = this, labelData = {};

			for( var key in recordData ) {
				labelData[ key ] = recordData[ key ];
			}

			$.get( this.labelRenderer, labelData, function( data ) {
				recordData.__label = data.label;
				presideObjectConfigurator.uberSelect.select_item( recordData );
			} );
		};

		PresideObjectConfigurator.prototype.closeConfiguratorDialog = function(){
			this.configuratorIframeModal.close();
		};

		PresideObjectConfigurator.prototype.processRecord = function(){
			var uploadIFrame = this.getConfiguratorIFrame();

			if ( typeof uploadIFrame.configurator !== "undefined" ) {
				uploadIFrame.configurator.submitForm();

				return false;
			}

			return true;
		};

		PresideObjectConfigurator.prototype.configuratorFinished = function(){
			this.configuratorIframeModal.close();
		};

		PresideObjectConfigurator.prototype.getConfiguratorIFrame = function(){
			return this.configuratorIframe;
		};

		return PresideObjectConfigurator;
	})();


	$.fn.presideObjectConfigurator = function(){
		return this.each( function(){
			new PresideObjectConfigurator( $(this) );
		} );
	};

} )( presideJQuery );