( function( $ ){

	var PresideObjectPicker = (function() {
		function PresideObjectPicker( $originalInput ) {
			this.$originalInput = $originalInput;
			var _this           = this
			  , filteredOn      = []
			  , filterBy        = $originalInput.data( "filterBy" )
			  , $filterObjectPicker, i;

			if ( typeof filterBy !== "undefined" && filterBy.length ) {
				filterBy = filterBy.split( ',' );

				for( i=0; i<filterBy.length; i++ ) {
					$filterObjectPicker = $( "input[name='" + filterBy[ i ] + "'], select[name='" + filterBy[ i ] + "']" ).closest( '.form-group' ).find( '.object-picker' );

					if ( $filterObjectPicker.length ) {
						var formFieldDeferred       = "objectPicker_" + $filterObjectPicker.attr( "id" );
	 					window[ formFieldDeferred ] = window[ formFieldDeferred ] || $.Deferred();

	 					filteredOn.push( window[ formFieldDeferred ] );
	 				}
				}
			}

			$.when.apply( $, filteredOn ).done( function() {
				var formFieldDeferred       = "objectPicker_" + _this.$originalInput.attr( "id" )
				  , formFieldAjaxDeferred   = formFieldDeferred + "_ajax";

 				window[ formFieldDeferred ]  = window[ formFieldDeferred ] || $.Deferred();
 				_this.fieldPopulatedDeferred = $.Deferred();

				_this.setupUberSelect();

				if ( _this.$originalInput.hasClass( 'quick-add' ) ) {
					_this.setupQuickAdd();
				}
				if ( _this.$originalInput.hasClass( 'quick-edit' ) ) {
					_this.setupQuickEdit();
				}

 				$.when( _this.uberSelect.fieldPopulatedDeferred ).done( function() {
 					window[ formFieldDeferred ].resolve();
 				} );
			} );

		}

		PresideObjectPicker.prototype.setupUberSelect = function(){
			this.$originalInput.uberSelect({
				  allow_single_deselect  : !this.$originalInput.hasClass( 'non-deselectable' )
				, inherit_select_classes : true
				, searchable             : !this.$originalInput.hasClass( 'non-searchable' )
				, superQuickAdd          : this.$originalInput.hasClass( 'super-quick-add' )
				, superQuickAddUrl       : this.$originalInput.data( 'superQuickAddUrl' )
			});
			this.$uberSelect = this.$originalInput.next();
			this.uberSelect = this.$originalInput.data( "uberSelect" );
		};

		PresideObjectPicker.prototype.setupQuickAdd = function(){
			var iframeSrc           = this.$originalInput.data( "quickAddUrl" )
			  , modalTitle          = this.$originalInput.data( "quickAddModalTitle" )
			  , presideObjectPicker = this
			  , modalOptions        = {
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
							, callback  : function(){ return presideObjectPicker.processAddRecord(); }
						}
					}
				}
			  , callbacks = {
					onLoad : function( iframe ) {
						iframe.presideObjectPicker = presideObjectPicker;
						presideObjectPicker.quickAddIframe = iframe;
					},
					onShow : function( modal, iframe ){
						if ( typeof iframe !== "undefined" && typeof iframe.quickAdd !== "undefined" ) {
							iframe.quickAdd.focusForm();

							return false;
						}

						modal.on('hidden.bs.modal', function (e) {
							modal.remove();
						} );
					}
				};

			this.$quickAddButton = $( '<a class="btn btn-default quick-add-btn" href="#"><i class="fa fa-plus"></i></a>' );
			if ( this.uberSelect.isSearchable() && this.uberSelect.search_field.attr( "tabindex" ) &&  this.uberSelect.search_field.attr( "tabindex" ) != "-1" ) {
				this.$quickAddButton.attr( "tabindex", this.uberSelect.search_field.attr( "tabindex" ) );
			} else if ( this.$originalInput.attr( "tabindex" ) && this.$originalInput.attr( "tabindex" ) != "-1" ) {
				this.$quickAddButton.attr( "tabindex", this.$originalInput.attr( "tabindex" ) );
			}

			this.$quickAddButton.on( "click", function( e ) {
				var filters = presideObjectPicker.getFiltersForQuickAdd();

				if ( presideObjectPicker.uberSelect.is_disabled ) {
					return;
				}

				presideObjectPicker.quickAddIframeModal = new PresideIframeModal( iframeSrc + filters, "100%", "100%", callbacks, modalOptions );
				presideObjectPicker.quickAddIframeModal.open();
			} );

			this.$uberSelect.after( this.$quickAddButton );
		};

		PresideObjectPicker.prototype.setupQuickEdit = function(){
			var iframeSrc           = this.$originalInput.data( "quickEditUrl" )
			  , modalTitle          = this.$originalInput.data( "quickEditModalTitle" )
			  , presideObjectPicker = this
			  , modalOptions        = {
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
							, callback  : function(){ return presideObjectPicker.processEditRecord(); }
						}
					}
				}
			  , callbacks = {
					onLoad : function( iframe ) {
						iframe.presideObjectPicker = presideObjectPicker;
						presideObjectPicker.quickEditIframe = iframe;
					},
					onShow : function( modal, iframe ){
						if ( typeof iframe !== "undefined" && typeof iframe.quickEdit !== "undefined" ) {
							iframe.quickEdit.focusForm();

							return false;
						}

						modal.on('hidden.bs.modal', function (e) {
							modal.remove();
						} );
					}
				};

			this.uberSelect.container.on( "click", ".quick-edit-link", function(e){
				e.preventDefault();

				var $quickEditLink = $( this )
				  , href           = $quickEditLink.attr( "href" );

				presideObjectPicker.quickEditIframeModal = new PresideIframeModal( href, "100%", "100%", callbacks, modalOptions );

				presideObjectPicker.quickEditIframeModal.open();
			} );
		};

		PresideObjectPicker.prototype.addRecordToControl = function( recordId ){
			this.uberSelect.select( recordId );
		};

		PresideObjectPicker.prototype.closeQuickAddDialog = function(){
			this.quickAddIframeModal.close();

			this.uberSelect.isSearchable() && this.uberSelect.search_field.focus();
		};

		PresideObjectPicker.prototype.processAddRecord = function(){
			var uploadIFrame = this.getQuickAddIFrame();

			if ( typeof uploadIFrame.quickAdd !== "undefined" ) {
				uploadIFrame.quickAdd.submitForm();

				return false;
			}

			return true;
		};

		PresideObjectPicker.prototype.processEditRecord = function(){
			var editIFrame = this.getQuickEditIFrame();

			if ( typeof editIFrame.quickEdit !== "undefined" ) {
				editIFrame.quickEdit.submitForm();

				return false;
			}

			return true;
		};

		PresideObjectPicker.prototype.editSuccess = function( message ){
			$.gritter.add({
				  title      : i18n.translateResource( "cms:info.notification.title" )
				, text       : message
				, class_name : "gritter-success"
				, sticky     : false
			});

			this.closeQuickEditDialog();
		};

		PresideObjectPicker.prototype.closeQuickEditDialog = function(){
			this.quickEditIframeModal.close();

			this.uberSelect.isSearchable() && this.uberSelect.search_field.focus();
		};

		PresideObjectPicker.prototype.quickAddFinished = function(){
			this.quickAddIframeModal.close();
		};

		PresideObjectPicker.prototype.getQuickAddIFrame = function(){
			return this.quickAddIframe;
		};

		PresideObjectPicker.prototype.getQuickEditIFrame = function(){
			return this.quickEditIframe;
		};

		PresideObjectPicker.prototype.getFiltersForQuickAdd = function(){
			var filterBy      = this.$originalInput.data( 'filterBy' )
			  , filterByField = this.$originalInput.data( 'filterByField' ) || filterBy
			  , filters       = []
			  , filterByValue, i;

			if ( typeof filterBy !== "undefined" && filterBy.length ) {
				filterBy      = filterBy.split( ',' );
				filterByField = filterByField.split( ',' );

				for( i=0; i<=filterBy.length; i++ ) {
					filterByValue = this.getFilterValue( filterBy[ i ] );

					if ( filterByValue !== null && typeof filterByValue !== "undefined" ) {
						filters.push ( '&', filterByField[ i ], '=', filterByValue, '&filterByFields=', filterByField[ i ] );
					}
				}
			}

			return filters.join( '' );
		};

		PresideObjectPicker.prototype.getFilterValue = function( filterBy ) {
			var field = $( 'input[name="' + filterBy + '"]' );

			if ( field.length ) {
				return field.val();
			}

			return cfrequest[ filterBy ] || null;
		}

		return PresideObjectPicker;
	})();


	$.fn.presideObjectPicker = function(){
		return this.each( function(){
			new PresideObjectPicker( $(this) );
		} );
	};

} )( presideJQuery );