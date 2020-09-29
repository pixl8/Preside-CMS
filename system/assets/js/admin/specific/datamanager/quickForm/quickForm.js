( function( $ ){

	var QuickForm = (function() {
        function QuickForm( $originalInput,options, success ) {
            this.$originalInput = $originalInput;
            var $this = this;
            if(this.$originalInput.data( "quickForm" )){
                return;
            }
            $.when.apply( $ ).done( function() {
                $this.setupQuickForm(options,success);
			} );
        }
        QuickForm.prototype.setupQuickForm = function(options,success){
                this.$originalInput.data( "quickForm",true );
                var urlValue = this.$originalInput.data( "url" );
                if(options.url != undefined){
                    urlValue = options.url;
                }

                var titleValue = this.$originalInput.data( "title" );
                if(options.title != undefined){
                    titleValue = options.title;
                }
                if(titleValue  == undefined){
                    titleValue =  i18n.translateResource( "cms:cms.editForm" )
                }

                var className = "full-screen-dialog";
                if(options.className != undefined){
                    className = options.className;
                }

                var width = "100%";
                if(options.width != undefined){
                    width = options.width;
                }

                var height = "100%";
                if(options.height != undefined){
                    height = options.height;
                }

                var labelSubmit = '<i class="fa fa-plus"></i> ' + i18n.translateResource( "cms:add.btn" )
                if( urlValue.indexOf( "quickEditForm" ) > 0){
                    labelSubmit = '<i class="fa fa-pencil"></i> ' + i18n.translateResource( "cms:edit.btn" )
                };
                var iframeSrc           = urlValue
                , modalTitle          = titleValue
                , quickForm = this
                , modalOptions        = {
                    title     : modalTitle,
                    className : className,
                    buttons   : {
                        cancel : {
                                label     : '<i class="fa fa-reply"></i> ' + i18n.translateResource( "cms:cancel.btn" )
                            , className : "btn-default"
                        },
                        add : {
                              label     :  labelSubmit
                            , className : "btn-primary"
                            , callback  : function(){ return quickForm.processAddRecord(); }
                        }
                    }
                }
                , callbacks = {
                    onLoad : function( iframe ) {
                        iframe.presideObjectPicker = quickForm;
                        quickForm.quickFormIframe = iframe;
                        quickForm.success = success;
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
                this.$originalInput.on( "click", function( e ) {
                    quickForm.quickFormIframeModal = new PresideIframeModal( iframeSrc, width, height, callbacks, modalOptions );
                    quickForm.quickFormIframeModal.open();
                } );
        };
        QuickForm.prototype.processAddRecord = function(){
			var uploadIFrame = this.quickFormIframe;

			if ( uploadIFrame.quickAdd !== undefined ) {
                uploadIFrame.quickAdd.submitForm();
				return false;
			}else if ( uploadIFrame.quickEdit !== undefined ) {
                uploadIFrame.quickEdit.submitForm();
				return false;
			}

			return true;
        };

        QuickForm.prototype.addRecordToControl = function( recordId ){
            if (typeof this.success === 'function') {
                this.success();
            }
            else if (typeof this.success === 'object') {
                this.success._fnReDraw();
            }else if(typeof this.$originalInput.context.onsubmit === 'function'){
                this.$originalInput.context.onsubmit();
            }
        };
        
		QuickForm.prototype.closeQuickAddDialog = function(){
            this.quickFormIframeModal.close();
            $.gritter.add({
                title      : i18n.translateResource( "cms:info.notification.title" )
              , text       : i18n.translateResource( "cms:datamanager.quick.add.added.confirmation" )
              , class_name : "gritter-success"
              , sticky     : false
            });
        };
        QuickForm.prototype.editSuccess = function( message ){
			$.gritter.add({
				  title      : i18n.translateResource( "cms:info.notification.title" )
				, text       : message
				, class_name : "gritter-success"
				, sticky     : false
			});
            this.quickFormIframeModal.close();
            if (typeof this.success === 'function') {
                this.success();
            }
            else if (typeof this.success === 'object') {
                this.success._fnReDraw();
            }
		};
        addAnother = function(){
            return $quickAddForm.find( "input[name='_addAnother']:checked" ).length;
        };
        return QuickForm;
    })();

	$.fn.quickForm = function(options,success){
        if (typeof options === 'function' || typeof options  === 'object') {
            success = options
            options = {}
        } else if (typeof options === 'undefined') {
            options = {}
        }
		return this.each( function(){
			new QuickForm( $(this),options,success);
		} );
    };
    quickForm = function(originalInput,options,success){
        if (typeof options === 'function') {
            success = options
            options = {}
        } else if (typeof options === 'undefined') {
            options = {}
        }
		return originalInput.each( function(index,value){
			new QuickForm( $(value),options,success);
		} );
    };

    $('.quickForm').quickForm();

} )( presideJQuery );