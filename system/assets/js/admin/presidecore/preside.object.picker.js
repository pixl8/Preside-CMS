( function( $ ){

	var PresideObjectPicker = (function() {
		function PresideObjectPicker( $originalInput ) {
			this.$originalInput = $originalInput;

			this.setupUberSelect();
			if ( this.$originalInput.hasClass( 'quick-add' ) ) {
				this.setupQuickAdd();
			}
		}

		PresideObjectPicker.prototype.setupUberSelect = function(){
			this.$originalInput.uberSelect({
				  allow_single_deselect  : true
				, inherit_select_classes : true
			});
			this.$uberSelect = this.$originalInput.next();
			this.uberSelect = this.$originalInput.data( "uberSelect" );
		};

		PresideObjectPicker.prototype.setupQuickAdd = function(){
			var iframeSrc       = this.$originalInput.data( "quickAddUrl" )
			  , modalTitle      = this.$originalInput.data( "quickAddModalTitle" )
			  , iframeId        = this.$originalInput.attr('id') + "_quickadd_frame"
			  , onLoadCallback  = "cb" + iframeId
			  , presideObjectPicker = this;

			window[ onLoadCallback ] = function( iframe ){
				iframe.presideObjectPicker = presideObjectPicker;
			};
			this.$quickAddIframeContainer = $( '<div id="' + iframeId + '" style="display:none;"><iframe class="quick-add-iframe" src="' + iframeSrc + '" width="900" height="250" frameBorder="0" onload="' + onLoadCallback + '( this.contentWindow )"></iframe></div>' );
			this.$quickAddButton = $( '<a class="btn btn-default quick-add-btn" href="#' + iframeId + '" title="' + modalTitle + '"><i class="fa fa-plus"></i></a>' );
			if ( this.uberSelect.search_field.attr( "tabindex" ) &&  this.uberSelect.search_field.attr( "tabindex" ) != "-1" ) {
				this.$quickAddButton.attr( "tabindex", this.uberSelect.search_field.attr( "tabindex" ) );
			} else if ( this.$originalInput.attr( "tabindex" ) && this.$originalInput.attr( "tabindex" ) != "-1" ) {
				this.$quickAddButton.attr( "tabindex", this.$originalInput.attr( "tabindex" ) );
			}

			this.$uberSelect.after( this.$quickAddIframeContainer );
			this.$uberSelect.after( this.$quickAddButton );

			this.$quickAddButton.data( 'modalClass', 'quick-add-modal' );

			this.$quickAddButton.presideBootboxModal({
				buttons : {
					cancel : {
						  label     : '<i class="fa fa-reply"></i> ' + i18n.translateResource( "cms:cancel.btn" )
						, className : "btn-default"
					},
					add : {
						  label     : '<i class="fa fa-plus"></i> ' + i18n.translateResource( "cms:add.btn" )
						, className : "btn-primary"
						, callback  : function(){ return presideObjectPicker.processAddRecord(); }
					}
				},
				onShow : function( modal ){
					var uploadIFrame = presideObjectPicker.getQuickAddIFrame();

					if ( typeof uploadIFrame.quickAdd !== "undefined" ) {
						uploadIFrame.quickAdd.focusForm();

						return false;
					}

					modal.on('hidden.bs.modal', function (e) {
		  				modal.remove();
					} );
				}
			});
		};

		PresideObjectPicker.prototype.addRecordToControl = function( recordId ){
			this.uberSelect.select( recordId );
		};

		PresideObjectPicker.prototype.closeQuickAddDialog = function(){
			var modal = this.$quickAddButton.data( 'modal' );

			modal.modal( 'hide' );

			this.uberSelect.search_field.focus();
		};

		PresideObjectPicker.prototype.processAddRecord = function(){
			var uploadIFrame = this.getQuickAddIFrame();

			if ( typeof uploadIFrame.quickAdd !== "undefined" ) {
				uploadIFrame.quickAdd.submitForm();

				return false;
			}

			return true;
		};

		PresideObjectPicker.prototype.quickAddFinished = function(){
			var modal = this.$quickAddButton.data( 'modal' );

			modal.on('hidden.bs.modal', function (e) {
  				modal.remove();
			} );
			modal.modal( 'hide' );
		};

		PresideObjectPicker.prototype.getQuickAddIFrame = function(){
			var $iframe = $( '.modal-dialog iframe.quick-add-iframe' );
			if ( $iframe.length ) {
				return $iframe.get(0).contentWindow;
			}

			return {};
		};

		return PresideObjectPicker;
	})();


	$.fn.presideObjectPicker = function(){
		return this.each( function(){
			new PresideObjectPicker( $(this) );
		} );
	};

} )( presideJQuery );