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
		  , uploadProgressHandler
		  , totalUploadProgressHandler
		  , errorHandler
		  , toggleFeaturesOnFileListPopulation
		  , thumbnailGeneratedHandler;

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
			var files = dropzone.getFilesWithStatus( Dropzone.ADDED )
			  , $previewContainer, $input, filename, i, progressBarWidth=0;

			if ( files.length ) {
				dropzone.enqueueFiles( files );

				for( i=0; i<files.length; i++ ) {
					$previewContainer = $( files[ i ].previewElement );
					$input = $previewContainer.find( "input[ name='asset-title' ]" );
					filename = $input.val();
					progressBarWidth = progressBarWidth || $input.width();

					if ( !$.trim( filename ).length ) {
						filename = files[ i ].name;
					}

					$previewContainer.find( ".upload-detail" ).html(
						'<div class="progress progress-striped active" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0" style="width:' + progressBarWidth + 'px;"><span class="progress-bar-placeholder">' + filename + '</span><div class="progress-bar progress-bar-success" style="width:0%;"></div></div>'
					);
				}


				$form.find( ".upload-options" ).fadeOut( 500, function(){
					$( this ).remove();
					$form.find( ".upload-next-steps" ).removeClass( "hide" );
				} );

				$form.find( "li[data-step='1']" ).addClass( "complete" ).removeClass( "active" );
				$form.find( "li[data-step='2']" ).addClass( "active" );
			}

			return false;
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

		errorHandler = function( file, message ) {
			var $previewContainer = $( file.previewElement )
			  , $detail           = $previewContainer.find( ".upload-detail" );

			$detail.html( 'TODO: Produce meaningfull error message here' );
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

		dropzone = new Dropzone( document.body, {
			  url                 : $form.attr( "action" )
			, thumbnailWidth      : 50
			, thumbnailHeight     : 50
			, parallelUploads     : 1
			, autoQueue           : false
			, clickable           : ".choose-files-trigger"
			, addedfile           : fileAddedHandler
			, thumbnail           : thumbnailGeneratedHandler
			, uploadprogress      : uploadProgressHandler
			, totaluploadprogress : totalUploadProgressHandler
			, error               : errorHandler
		} );

		$form.on( "click", ".cancel-file-trigger", cancelFileHandler );
		$form.on( "click", ".upload-files-trigger", uploadFilesHandler );
	}

} )( presideJQuery );