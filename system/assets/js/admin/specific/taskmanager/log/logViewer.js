( function( $ ){

	var $logArea  = $( '#taskmanager-log' )
	  , $timeArea = $( '#task-log-timetaken' )
	  , $runBtn   = $( '#run-task-btn' )
	  , updateUrl = cfrequest.logUpdateUrl || ""
	  , lineCount = cfrequest.lineCount || ""
	  , fetchRate = 1000
	  , fetchUpdate, intervalId, scrollToBottom;

	if ( $logArea.length && updateUrl.length ) {
		scrollToBottom = function(){
			var logArea = $logArea.get(0);
			$logArea.animate( {scrollTop: logArea.scrollHeight - logArea.clientHeight}, 400 );
		};
		fetchUpdate = function(){
			$.ajax( updateUrl, {
				  data    : { fetchAfterLines : lineCount }
				, success : function( data ){
					if ( typeof data.log !== "undefined" ) {
						var logArea = $logArea.get(0)
						  , isScrolledToBottom = logArea.scrollHeight - logArea.clientHeight <= logArea.scrollTop + 1;

						$timeArea.html( data.time_taken );
						if ( $.trim( data.log ).length ) {
							$logArea.html( $logArea.html() + String.fromCharCode( 10 ) + data.log );
							lineCount = data.lineCount;
						}


						if ( isScrolledToBottom ) {
							scrollToBottom();
						}

						if ( data.complete ) {
							clearInterval( intervalId );
							$timeArea.parent().removeClass( "running blue" );
							$timeArea.parent().addClass( "complete green" );
							if ( $runBtn.length ) {
								$runBtn.removeAttr( "disabled" );
								$runBtn.removeClass( "btn-disabled" );
							}
						}
					}
				}
			} );
		};

		intervalId = setInterval( fetchUpdate, fetchRate );
		setTimeout( scrollToBottom, 2000 );
	}

} )( presideJQuery );