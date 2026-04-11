/**
 * Chunked File Upload Interface for Preside-CMS
 *
 * This module handles large file uploads by splitting files into chunks
 * on the client side and reassembling them on the server.
 *
 * @version 1.0.0
 */

(function( $ ){
	
	// Configuration
	// CHUNK_SIZE: each individual chunk sent per HTTP request - kept small to stay well within proxy limits (e.g. Cloudflare)
	var CHUNK_SIZE = 10 * 1024 * 1024; // 10MB chunks - safe within CommandBox default 200MB entity limit
	// CHUNKING_THRESHOLD: files larger than this are uploaded in chunks to avoid proxy/CDN request size limits.
	// This is NOT Preside's file size limit - Preside's limit is enforced separately via maxFileSize/Dropzone.
	var CHUNKING_THRESHOLD = ( cfrequest.chunkingThreshold !== undefined ? cfrequest.chunkingThreshold : 10 ) * 1024 * 1024;
	
	var $form = $( "#add-assets-form" );
	var $uploadTemplate = $( "#file-preview-template" );
	
	if ( $form.length && $uploadTemplate.length ) {
		var filePreviewTemplate = $uploadTemplate.get(0).innerHTML;
		var $previewsContainer  = $( "#upload-previews" );
		var uploadedIds         = [];
		var failedUploads       = 0;
		var successfulUploads   = 0;
		var totalFilesQueued    = 0;
		var batchOptions        = {};
		var queueTriggered      = false;
		
		$uploadTemplate.remove();
		
		// Initialize Dropzone with chunking support
		var dropzone = new Dropzone( $( "body" ).get(0), {
			url: $form.attr( "action" ),
			thumbnailWidth: 50,
			thumbnailHeight: 50,
			parallelUploads: cfrequest.parallelUploads || 5,
			autoQueue: false,
			clickable: ".choose-files-trigger",
			maxFilesize: cfrequest.maxFileSize || 100,
			maxFiles: cfrequest.maxFiles || null,
			acceptedFiles: cfrequest.allowedExtensions || '',
			dictDefaultMessage: i18n.translateResource( "cms:assetmanager.uploader.messages.dictDefaultMessage" ),
			dictFallbackMessage: i18n.translateResource( "cms:assetmanager.uploader.messages.dictFallbackMessage" ),
			dictFallbackText: i18n.translateResource( "cms:assetmanager.uploader.messages.dictFallbackText" ),
			dictFileTooBig: i18n.translateResource( "cms:assetmanager.uploader.messages.dictFileTooBig" ),
			dictInvalidFileType: i18n.translateResource( "cms:assetmanager.uploader.messages.dictInvalidFileType" ),
			dictResponseError: i18n.translateResource( "cms:assetmanager.uploader.messages.dictResponseError" ),
			dictCancelUpload: i18n.translateResource( "cms:assetmanager.uploader.messages.dictCancelUpload" ),
			dictCancelUploadConfirmation: i18n.translateResource( "cms:assetmanager.uploader.messages.dictCancelUploadConfirmation" ),
			dictRemoveFile: i18n.translateResource( "cms:assetmanager.uploader.messages.dictRemoveFile" ),
			dictRemoveFileConfirmation: i18n.translateResource( "cms:assetmanager.uploader.messages.dictRemoveFileConfirmation" ),
			dictMaxFilesExceeded: i18n.translateResource( "cms:assetmanager.uploader.messages.dictMaxFilesExceeded" ),
			
			// Disable default upload - we'll handle it ourselves
			init: function() {
				this.on("addedfile", function( file ) {
					// Remove Dropzone's auto-generated preview before we replace it
					if ( file.previewElement && file.previewElement.parentNode ) {
						file.previewElement.parentNode.removeChild( file.previewElement );
					}

					file.previewElement = $( Mustache.render( filePreviewTemplate, {
						name:     file.name,
						size:     dropzone.filesize( file.size ),
						type:     file.type,
						tabindex: getNextTabIndex()
					} ) ).get( 0 );

					$previewsContainer.append( file.previewElement );
					$( file.previewElement ).data( "file", file );
					toggleFeaturesOnFileListPopulation();
				});
				
				this.on("removedfile", function( file ){
					$( file.previewElement ).fadeOut( 200, function(){
						$( this ).remove();
					} );
					toggleFeaturesOnFileListPopulation();
				});
				
				this.on("thumbnail", function(file, dataUrl) {
					$( file.previewElement ).find( "img.preview-thumbnail" ).attr( "src", dataUrl );
				});
				
				// Standard upload setup for small files (large files are handled via uploadFileInChunks, never enqueued here)
				this.on("sending", function( file, xhr, formData ){
					var $previewContainer = $( file.previewElement );
					var $input            = $previewContainer.find( "input[ name='asset-title' ]" );
					var title             = $input.val() || file.name;
					var progressWidth     = $input.length ? $input.width() : "100%";

					formData.append( "title", title );
					for ( var key in batchOptions ) {
						formData.append( key, batchOptions[ key ] );
					}

					$previewContainer.find( ".upload-detail" ).html(
						'<div class="progress progress-striped active" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0" style="width:' + progressWidth + ( typeof progressWidth === "number" ? "px" : "" ) + ';"><span class="progress-bar-placeholder">' + title + '</span><div class="progress-bar progress-bar-success" style="width:0%;"></div></div>'
					);
				});
				
				this.on("uploadprogress", function( file, progress, bytesSent ){
					var $previewContainer = $( file.previewElement );
					var $progressBar = $previewContainer.find( ".progress-bar" );
					$progressBar.width( progress + "%" );
				});
				
				this.on("totaluploadprogress", function( progress ) {
					var $progressBar = $form.find( ".total-progress .progress-bar" );
					$progressBar.width( progress + "%" );
				});
				
				this.on("error", function( file, message, xhr ) {
					if ( typeof message == "object" && typeof message.message != "undefined" ) {
						markFailure( file, message.message );
					} else if ( typeof xhr === "undefined" ) {
						markFailure( file, message );
						toggleFeaturesOnFileListPopulation();
					} else {
						markFailure( file, i18n.translateResource( "cms:assetmanager.upload.failure.http.message", { data : [ xhr.status + ' ' + xhr.statusText ] } ) );
					}
				});
				
				this.on("success", function( file, message ) {
					if ( typeof message == "object" && typeof message.success != "undefined" ) {
						if ( message.success ) {
							markSuccess( file, message.message, message.id );
						} else {
							markFailure( file, message.message );
						}
					} else {
						markFailure( file, i18n.translateResource( "cms:assetmanager.upload.failure.http.message", { data : [ "200 OK" ] } ) );
					}
				});
				
				this.on("queuecomplete", function(){
					checkAllComplete();
				});
				
				this.on("maxfilesreached", function(){
					$form.find( ".choose-files-trigger" ).prop( "disabled", true ).addClass( "disabled" );
				});
			}
		} );
		
		/**
		 * Generate a UUID v4 for identifying this upload client-side
		 */
		function generateUUID() {
			return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace( /[xy]/g, function( c ) {
				var r = Math.random() * 16 | 0;
				return ( c === 'x' ? r : ( r & 0x3 | 0x8 ) ).toString( 16 );
			} );
		}

		/**
		 * Upload a file in chunks.
		 * No separate session creation — UUID is generated here and passed with every request.
		 */
		function uploadFileInChunks( file, title, $previewContainer ) {
			var uuid          = generateUUID();
			var chunkCount    = Math.ceil( file.size / CHUNK_SIZE );
			var folder        = batchOptions.asset_folder || "";
			var $input        = $previewContainer.find( "input[ name='asset-title' ]" );
			var progressWidth = $input.length ? $input.width() : "100%";

			$previewContainer.find( ".upload-detail" ).html(
				'<div class="progress progress-striped active" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0" style="width:' + progressWidth + ( typeof progressWidth === "number" ? "px" : "" ) + ';">'
				+ '<span class="progress-bar-placeholder">' + title + '</span>'
				+ '<div class="progress-bar progress-bar-success" style="width:0%;"></div>'
				+ '</div>'
			);

			uploadChunks( file, uuid, chunkCount, 0, $previewContainer, function( isComplete ) {
				if ( isComplete ) {
					$.ajax({
						url:  cfrequest.chunkedUploadFinalizeUrl,
						type: "POST",
						data: {
							uuid:             uuid,
							folder:           folder,
							title:            title,
							totalChunks:      chunkCount,
							originalFilename: file.name,
							assetId:          batchOptions.asset_id || ""
						},
						success: function( response ) {
							if ( response.success ) {
								if ( response.redirect ) {
									window.location.href = response.redirect;
								} else {
									markSuccess( file, response.message, response.assetId );
								}
							} else {
								markFailure( file, response.message );
							}
						},
						error: function( xhr ) {
							markFailure( file, i18n.translateResource( "cms:assetmanager.chunked.upload.error.http.finalize" ) );
						}
					});
				}
			});
		}

		/**
		 * Recursively upload chunks sequentially
		 */
		function uploadChunks( file, uuid, totalChunks, currentChunk, $previewContainer, onComplete ) {
			if ( currentChunk >= totalChunks ) {
				onComplete( true );
				return;
			}

			var start    = currentChunk * CHUNK_SIZE;
			var end      = Math.min( start + CHUNK_SIZE, file.size );
			var formData = new FormData();

			formData.append( "uuid",        uuid );
			formData.append( "chunkNumber", currentChunk + 1 );
			formData.append( "chunkData",   file.slice( start, end ) );

			var pct = Math.round( ( currentChunk / totalChunks ) * 100 );
			$previewContainer.find( ".progress-bar" ).width( pct + "%" );
			$form.find( ".total-progress .progress-bar" ).width( pct + "%" );

			$.ajax({
				url:         cfrequest.chunkedUploadChunkUrl,
				type:        "POST",
				data:        formData,
				processData: false,
				contentType: false,
				success: function( response ) {
					if ( response.success ) {
						uploadChunks( file, uuid, totalChunks, currentChunk + 1, $previewContainer, onComplete );
					} else {
						onComplete( false );
						markFailure( file, response.message || i18n.translateResource( "cms:assetmanager.chunked.upload.error.http.chunk" ) );
					}
				},
				error: function( xhr ) {
					onComplete( false );
					markFailure( file, i18n.translateResource( "cms:assetmanager.chunked.upload.error.http.chunk" ) );
				}
			});
		}
		
		// Re-validate queued files when folder selection changes.
		// Restrictions (max size, allowed types) are per-folder so changing folder
		// must re-check any files already queued — otherwise users could bypass limits.
		var currentMaxFileSize        = cfrequest.maxFileSize        || 100;
		var currentAllowedExtensions  = ( cfrequest.allowedExtensions || "" ).toLowerCase().split( "," ).filter( function( s ) { return s.length; } );

		$form.on( "change", "[name='asset_folder']", function() {
			var folderId = $( this ).val();

			$.ajax({
				url:      cfrequest.getUploadRestrictionsUrl,
				type:     "GET",
				data:     { folder: folderId },
				dataType: "json",
				success: function( restrictions ) {
					currentMaxFileSize       = restrictions.maxFileSize       || 100;
					currentAllowedExtensions = ( restrictions.allowedExtensions || "" ).toLowerCase().split( "," ).filter( function( s ) { return s.length; } );

					// Re-validate every queued file against the new folder's restrictions.
					// Show an inline error on invalid files rather than silently removing
					// them — the user can then decide to remove them manually.
					// Also clear errors on files that become valid again.
					var queued = dropzone.getFilesWithStatus( Dropzone.ADDED );

					for ( var i = 0; i < queued.length; i++ ) {
						var file              = queued[ i ];
						var $previewContainer = $( file.previewElement );
						var $detail           = $previewContainer.find( ".upload-detail" );
						var ext               = "." + file.name.split( "." ).pop().toLowerCase();
						var sizeMB            = file.size / ( 1024 * 1024 );
						var errorMsg          = null;

						if ( currentAllowedExtensions.length && currentAllowedExtensions.indexOf( ext ) === -1 ) {
							errorMsg = i18n.translateResource( "cms:assetmanager.uploader.messages.dictInvalidFileType" );
						} else if ( sizeMB > currentMaxFileSize ) {
							errorMsg = i18n.translateResource( "cms:assetmanager.chunked.upload.error.file.too.big", { data: [ dropzone.filesize( file.size ), currentMaxFileSize ] } );
						}

						if ( errorMsg ) {
							// Save original detail content before replacing (only once)
							if ( !$previewContainer.data( "folderErrorSaved" ) ) {
								$previewContainer.data( "folderErrorSaved", $detail.html() );
							}
							$detail.html( errorMsg );
							$previewContainer.addClass( "upload-error" ).removeClass( "upload-success" );
						} else if ( $previewContainer.data( "folderErrorSaved" ) ) {
							// Restore the original title input that was saved before the error
							$detail.html( $previewContainer.data( "folderErrorSaved" ) );
							$previewContainer.removeData( "folderErrorSaved" );
							$previewContainer.removeClass( "upload-error" );
						}
					}
				}
			});
		});

		// Event handlers
		$form.on( "click", ".cancel-file-trigger", function() {
			var $previewContainer = $( this ).closest( ".asset-preview" );
			var file = $previewContainer && $previewContainer.data( "file" );
			
			if ( typeof file !== "undefined" ) {
				dropzone.removeFile( file );
				// Only re-enable choose-files if no other errored files remain
				if ( $form.find( ".asset-preview.upload-error" ).length === 0 ) {
					$form.find( ".choose-files-trigger" ).prop( "disabled", false ).removeClass( "disabled" );
				}
				toggleFeaturesOnFileListPopulation();
			}
			
			return false;
		});
		
		$form.on( "click", ".upload-files-trigger", function(){
			if ( $form.valid() ) {
				var files = dropzone.getFilesWithStatus( Dropzone.ADDED );

				if ( files.length ) {
					batchOptions      = $form.serializeObject();
					failedUploads     = 0;
					successfulUploads = 0;
					totalFilesQueued  = files.length;

					queueTriggered = true;

					var allowedExtensions = currentAllowedExtensions;
					var maxFileSizeMB     = currentMaxFileSize;
					var smallFiles        = [];

					for ( var i = 0; i < files.length; i++ ) {
						var file          = files[ i ];
						var $previewContainer = $( file.previewElement );
						var ext           = "." + file.name.split( "." ).pop().toLowerCase();

						if ( allowedExtensions.length && allowedExtensions.indexOf( ext ) === -1 ) {
							markFailure( file, i18n.translateResource( "cms:assetmanager.uploader.messages.dictInvalidFileType" ) );
						} else if ( ( file.size / ( 1024 * 1024 ) ) > maxFileSizeMB ) {
							markFailure( file, i18n.translateResource( "cms:assetmanager.uploader.messages.dictFileTooBig", { data: [ dropzone.filesize( file.size ), maxFileSizeMB ] } ) );
						} else if ( file.size >= CHUNKING_THRESHOLD ) {
							var $input = $previewContainer.find( "input[ name='asset-title' ]" );
							uploadFileInChunks( file, $input.val() || file.name, $previewContainer );
						} else {
							smallFiles.push( file );
						}
					}

					if ( smallFiles.length ) {
						dropzone.enqueueFiles( smallFiles );
					}

					$form.find( "li[data-step='1']" ).addClass( "complete" ).removeClass( "active" );
					$form.find( "li[data-step='2']" ).addClass( "active" );

					$form.find( ".upload-options" ).fadeOut( 200, function(){
						$( this ).remove();
						$form.find( ".upload-progress" ).removeClass( "hide" );
					} );
				}
			}

			return false;
		});
		
		// Helper functions
		function checkAllComplete() {
			if ( !queueTriggered ) { return; }
			if ( successfulUploads + failedUploads < totalFilesQueued ) { return; }

			$form.trigger( "assetsUploaded" );

			$form.find( ".upload-progress" ).fadeOut( 200, function(){
				$( this ).remove();

				var assetFolder    = typeof batchOptions.asset_folder !== "undefined" ? batchOptions.asset_folder : "";
				var uploadStatus   = getUploadResultStatus();
				var deleteMessages = [ ".complete-success", ".partial-success", ".complete-failure" ];
				var $returnLink    = $form.find( ".return-to-folder-link" );
				var $startOverLink = $form.find( ".start-over-link" );

				deleteMessages.splice( uploadStatus, 1 );
				for ( var i = 0; i < deleteMessages.length; i++ ) {
					$form.find( deleteMessages[ i ] ).remove();
				}

				$returnLink.attr( "href", $returnLink.attr( "href" ) + assetFolder );
				$startOverLink.attr( "href", $startOverLink.attr( "href" ) + assetFolder );

				$form.find( ".upload-results" ).removeClass( "hide" );
			} );

			$form.find( "li[data-step='2']" ).addClass( "complete" ).removeClass( "active" );
			$form.find( "li[data-step='3']" ).addClass( "active" );
		}

		function markSuccess( file, message, id ) {
			var $previewContainer = $( file.previewElement );
			var $detail           = $previewContainer.find( ".upload-detail" );

			uploadedIds.push( id );
			successfulUploads++;

			$detail.html( message );
			$previewContainer.addClass( "upload-success" );
			$previewContainer.find( ".action-buttons" ).html(
				'<i class="fa fa-fw fa-check bigger-130 green"></i>'
			);

			checkAllComplete();
		}

		function markFailure( file, message ) {
			var $previewContainer = $( file.previewElement );
			var $detail           = $previewContainer.find( ".upload-detail" );

			failedUploads++;

			$detail.html( message );
			$previewContainer.addClass( "upload-error" );
			$previewContainer.find( ".action-buttons" ).html(
				'<i class="fa fa-fw fa-ban bigger-130 red"></i>' +
				' <a class="red cancel-file-trigger" href="#">' +
				'<i class="fa fa-trash-o bigger-130"></i></a>'
			);

			// Prevent adding more files while an invalid file is in the list
			$form.find( ".choose-files-trigger" ).prop( "disabled", true ).addClass( "disabled" );

			checkAllComplete();
		}
		
		function toggleFeaturesOnFileListPopulation(){
			var files = dropzone.getFilesWithStatus( Dropzone.ADDED );
			
			if ( files.length ) {
				$form.find( ".no-files-chosen-message" ).hide();
				$form.find( ".upload-files-trigger" ).removeAttr( "disabled" );
			} else {
				$form.find( ".no-files-chosen-message" ).show();
				$form.find( ".upload-files-trigger" ).attr( "disabled", "disabled" );
			}
		}
		
		function getUploadResultStatus(){
			if ( failedUploads > 0 && successfulUploads > 0 ) {
				return 1; // PARTIALSUCCESS
			}
			
			if ( successfulUploads > 0 ) {
				return 0; // SUCCESS
			}
			
			return 2; // FAILURE
		}
		
		function getNextTabIndex(){
			var max = 0;
			$( "[tabindex]" ).each( function(){
				var ix = parseInt( $(this).attr( 'tabindex' ) );
				if ( !isNaN( ix ) && ix > max ) {
					max = ix;
				}
			} );
			
			return max+1;
		}
		
		$form.data( "presdideUploader", {
			getUploadedAssetIds: function(){ return uploadedIds }
		} );
	}
	
})( presideJQuery );
