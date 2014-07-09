( function( $ ){
	var $form = $( "#assetUploadDropzone" )
	  , dz
	  , initDz
	  , setupEventHandlers
	  , configureDropzone
	  , fileUploadedHandler
	  , fileRemovedHandler;

	if ( !$form.length ) {
		return;
	}

	initDz = function(){
		dz = this;
		$form.data( 'dropzone', dz );
		setupEventHandlers();
	};

	setupEventHandlers = function(){
		$form.on( "click", ".reset-btn", function( e ){
			e.preventDefault();
			e.stopPropagation();

			dz.removeAllFiles( true );
		} );

		$form.on( "click", function( e ){
			if ( !$(e.target).hasClass( "btn" ) ) {
				dz.hiddenFileInput.click();
			}
		} );

		dz.on( "success", fileUploadedHandler );
		dz.on( "removedfile", fileRemovedHandler );
	};

	fileUploadedHandler = function( file, response ) {
		if ( typeof response === "object" && typeof response.fileid !== "undefined" && response.fileid.length ) {
			$( file.previewTemplate ).append( '<input name="fileid" type="hidden" value="' + response.fileid + '" />' );
		}
	};

	fileRemovedHandler = function( file ) {
		var $fileidField = $( file.previewTemplate ).find( "input[name=fileid]" )
		  , fileId = $fileidField.length && $fileidField.val();

		if ( fileId ) {
			$.post( buildAdminLink( "assetmanager", "deleteTempFile" ), { fileid : fileId } );
		}
	};

	configureDropZone = function(){
		Dropzone.options.assetUploadDropzone = {
			  init            : initDz
			, url             : $form.data( "uploadUrl" )
			, paramName       : "file"
			, clickable       : $form.find( '.upload-instructions' ).get()
			, addRemoveLinks  : true
			, maxFilesize     : cfrequest.maxFileSize || 5
			, maxFiles        : cfrequest.maxFiles    || null
			, acceptedFiles   : cfrequest.allowedExtensions || ''
			, previewTemplate : '<div class="dz-preview dz-file-preview">\
			                        <div class="dz-details">\
			                            <div class="dz-filename"><span data-dz-name></span></div>\
		                                <div class="dz-size" data-dz-size></div>\
		                                <img data-dz-thumbnail />\
		                            </div>\
		                            <div class="progress progress-small progress-striped active">\
		                            	<div class="progress-bar progress-bar-success" data-dz-uploadprogress></div>\
		                            </div>\
		                            <div class="dz-success-mark"><span></span></div>\
		                            <div class="dz-error-mark"><span></span></div>\
		                            <div class="dz-error-message"><span data-dz-errormessage></span></div>\
		                        </div>'
		};
	};

	configureDropZone();

} )( presideJQuery );