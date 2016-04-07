( function( $ ){

	var $form           = $( "#add-assets-form" )
	  , $uploadTemplate = $( "#file-preview-template" );

	if ( $form.length && $uploadTemplate ) {
		var filePreviewTemplate = $uploadTemplate.get(0).innerHTML
		  , $previewsContainer  = $( "#upload-previews" )
		  , dropzone
		  , fileAddedHandler
		  , fileRemovedHandler
		  , cancelFileHandler
		  , uploadFilesHandler
		  , sendingHandler
		  , uploadProgressHandler
		  , totalUploadProgressHandler
		  , queueCompleteHandler
		  , errorHandler
		  , toggleFeaturesOnFileListPopulation
		  , thumbnailGeneratedHandler
		  , getUploadResultStatus
		  , batchOptions
		  , markSuccess
		  , markFailure
		  , failedUploads     = 0
		  , successfulUploads = 0
		  , SUCCESS           = 0
		  , PARTIALSUCCESS    = 1
		  , FAILURE           = 2;

		$uploadTemplate.remove();

		fileAddedHandler = function( file ) {
			file.previewElement = $( Mustache.render( filePreviewTemplate, {
				  name : file.name
				, size : dropzone.filesize( file.size )
				, type : file.type
			} ) ).get( 0 );

			$previewsContainer.append( file.previewElement );
			$( file.previewElement ).data( "file", file );

			toggleFeaturesOnFileListPopulation();
		};

		fileRemovedHandler = function( file ){
			$( file.previewElement ).fadeOut( 200, function(){
				$( this ).remove();
			} );
			toggleFeaturesOnFileListPopulation();
		};

		thumbnailGeneratedHandler = function(file, dataUrl) {
			$( file.previewElement ).find( "img.preview-thumbnail" ).attr( "src", dataUrl );
		};

		cancelFileHandler = function() {
			var $previewContainer = $( this ).closest( ".asset-preview" )
			  , file              = $previewContainer && $previewContainer.data( "file" );

			if ( typeof file !== "undefined" ) {
				dropzone.removeFile( file );
			}

			return false;
		};

		uploadFilesHandler = function(){
			if ( $form.valid() ) {
				var files = dropzone.getFilesWithStatus( Dropzone.ADDED )

				if ( files.length ) {
					batchOptions      = $form.serializeObject();
					failedUploads     = 0;
					successfulUploads = 0;

					dropzone.enqueueFiles( files );

					$form.find( "li[data-step='1']" ).addClass( "complete" ).removeClass( "active" );
					$form.find( "li[data-step='2']" ).addClass( "active" );

					$form.find( ".upload-options" ).fadeOut( 200, function(){
						$( this ).remove();
						$form.find( ".upload-progress" ).removeClass( "hide" );
					} );
				}
			}

			return false;
		};

		sendingHandler = function( file, xhr, formData ){
			var $previewContainer = $( file.previewElement )
			  , $input            = $previewContainer.find( "input[ name='asset-title' ]" )
			  , title             = $input.val()
			  , progressBarWidth  = progressBarWidth || $input.width()
			  , i;

			if ( !$.trim( title ).length ) {
				title = file.name;
			}
			formData.append( "title", title );
			for( var key in batchOptions ) {
				formData.append( key, batchOptions[ key ] );
			}

			$previewContainer.find( ".upload-detail" ).html(
				'<div class="progress progress-striped active" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0" style="width:' + progressBarWidth + 'px;"><span class="progress-bar-placeholder">' + title + '</span><div class="progress-bar progress-bar-success" style="width:0%;"></div></div>'
			);
		};

		uploadProgressHandler = function( file, progress, bytesSent ){
			var $previewContainer = $( file.previewElement )
			  , $progressBar      = $previewContainer.find( ".progress-bar" );

			$progressBar.width( progress + "%" );
		};

		totalUploadProgressHandler = function( progress ) {
			$progressBar = $form.find( ".total-progress .progress-bar" );

			$progressBar.width( progress + "%" );
		};

		errorHandler = function( file, message, xhr ) {
			if ( typeof message == "object" && typeof message.message != "undefined" ) {
				markFailure( file, message.message );
			} else {
				markFailure( file, i18n.translateResource( "cms:assetmanager.upload.failure.http.message", { data : [ xhr.status + ' ' + xhr.statusText ] } ) );
			}
		};

		successHandler = function( file, message ) {
			if ( typeof message == "object" && typeof message.success != "undefined" ) {
				if ( message.success ) {
					markSuccess( file, message.message );
				} else {
					markFailure( file, message.message );
				}
			} else {
				markFailure( file, i18n.translateResource( "cms:assetmanager.upload.failure.http.message", { data : [ "200 OK" ] } ) );
			}
		};

		markSuccess = function( file, message ) {
			var $previewContainer = $( file.previewElement )
			  , $detail           = $previewContainer.find( ".upload-detail" );

			successfulUploads++;

			$detail.html( message );
			$previewContainer.addClass( "upload-success" );

			$previewContainer.find( ".action-buttons" ).html(
				'<i class="fa fa-fw fa-check bigger-130 green"></i>'
			);
		};

		markFailure = function( file, message ) {
			var $previewContainer = $( file.previewElement )
			  , $detail           = $previewContainer.find( ".upload-detail" );

			failedUploads++;

			$detail.html( message );
			$previewContainer.addClass( "upload-error" );

			$previewContainer.find( ".action-buttons" ).html(
				'<i class="fa fa-fw fa-ban bigger-130 red"></i>'
			);
		};

		toggleFeaturesOnFileListPopulation = function(){
			if ( $previewsContainer.find( "tr.asset-preview" ).length ) {
				$form.find( ".no-files-chosen-message" ).hide();
				$form.find( ".upload-files-trigger" ).removeAttr( "disabled" );
			} else {
				$form.find( ".no-files-chosen-message" ).show();
				$form.find( ".upload-files-trigger" ).attr( "disabled", "disabled" );
			}
		};

		queueCompleteHandler = function(){
			$form.find( ".upload-progress" ).fadeOut( 200, function(){
				$( this ).remove();

				var assetFolder    = typeof batchOptions.asset_folder !== "undefined" ? batchOptions.asset_folder : ""
				  , uploadStatus   = getUploadResultStatus()
				  , deleteMessages = [ ".complete-success", ".partial-success", ".complete-failure" ]
				  , $returnLink    = $form.find( ".return-to-folder-link" )
				  , $startOverLink = $form.find( ".start-over-link"       )
				  , i;

				deleteMessages.splice( uploadStatus, 1 );
				for( i=0; i<deleteMessages.length; i++ ) {
					$form.find( deleteMessages[ i ] ).remove();
				}

				$returnLink.attr( "href", $returnLink.attr( "href" ) + assetFolder );
				$startOverLink.attr( "href", $startOverLink.attr( "href" ) + assetFolder );

				$form.find( ".upload-results" ).removeClass( "hide" );
			} );

			$form.find( "li[data-step='2']" ).addClass( "complete" ).removeClass( "active" );
			$form.find( "li[data-step='3']" ).addClass( "active" );
		};

		getUploadResultStatus = function(){
			if ( failedUploads > 0 && successfulUploads > 0 ) {
				return PARTIALSUCCESS;
			}

			if ( successfulUploads > 0 ) {
				return SUCCESS;
			}

			return FAILURE;
		};

		dropzone = new Dropzone( $( "body" ).get(0), {
			  url                 : $form.attr( "action" )
			, thumbnailWidth      : 50
			, thumbnailHeight     : 50
			, parallelUploads     : 1
			, autoQueue           : false
			, clickable           : ".choose-files-trigger"
			, addedfile           : fileAddedHandler
			, thumbnail           : thumbnailGeneratedHandler
			, sending             : sendingHandler
			, uploadprogress      : uploadProgressHandler
			, totaluploadprogress : totalUploadProgressHandler
			, queuecomplete       : queueCompleteHandler
			, error               : errorHandler
			, success             : successHandler
		} );

		$form.on( "click", ".cancel-file-trigger", cancelFileHandler );
		$form.on( "click", ".upload-files-trigger", uploadFilesHandler );
	}

} )( presideJQuery );