( function( $ ){
	var $progressContainer = $( "#ad-hoc-task-progress-container" )
	  , statusUpdateUrl    = cfrequest.adhocTaskStatusUpdateUrl || "";

	if ( !$progressContainer.length || !statusUpdateUrl.length ) {
		return;
	}

	var $logArea  = $( '#taskmanager-log' )
	  , $timeArea = $( '#task-log-timetaken' )
	  , $progressBar = $progressContainer.find( ".progress:first" )
	  , $cancelBtn   = $( '#task-cancel-button' )
	  , $resultBtn   = $( '#view-result-button' )
	  , updateUrl = cfrequest.logUpdateUrl || ""
	  , lineCount = cfrequest.lineCount || ""
	  , fetchRate = 1000
	  , fetchUpdate, processUpdate, intervalId, scrollToBottom, setProgress;


	scrollToBottom = function(){
		var logArea = $logArea.get(0);
		$logArea.animate( {scrollTop: logArea.scrollHeight - logArea.clientHeight}, 400 );
	};

	fetchUpdate = function(){
		$.ajax( statusUpdateUrl, {
			  data    : { fetchAfterLines : lineCount }
			, success : processUpdate
		} );
	};

	setProgress = function( progress ){
		$progressBar.attr( "data-percent", progress + "%" );
		$progressBar.find( ".progress-bar:first" ).css( "width", progress + "%" );
	};

	processUpdate = function( data ) {
		var isRunning          = data.status == "running"
		  , logArea            = $logArea.get(0)
		  , isScrolledToBottom = logArea.scrollHeight - logArea.clientHeight <= logArea.scrollTop + 1;

		$timeArea.html( data.timeTaken );
		if ( $.trim( data.log ).length ) {
			$logArea.html( $logArea.html() + String.fromCharCode( 10 ) + data.log );
			lineCount = data.lineCount;

			if ( isScrolledToBottom ) {
				scrollToBottom();
			}
		}

		setProgress( data.progress );

		if ( !isRunning ) {
			clearInterval( intervalId );
			$timeArea.parent().removeClass( "running blue" );
			$timeArea.parent().addClass( "complete" );

			if ( data.status == "succeeded" ) {
				$timeArea.parent().addClass( "green" );
			} else {
				$timeArea.parent().addClass( "red" );
			}

			if ( data.status == "succeeded" && data.resultUrl.length && $resultBtn.length ) {
				$resultBtn.prop( "disabled", false );
				$resultBtn.removeAttr( "disabled" );
				$resultBtn.removeClass( "btn-disabled" );
				$resultBtn.removeClass( "disabled" );
				$resultBtn.attr( "href", data.resultUrl );
			} else if ( $resultBtn.length ) {
				$resultBtn.prop( "disabled", true );
				$resultBtn.addClass( "btn-disabled" );
				$resultBtn.addClass( "disabled" );
				console.log( "damn...!" );
			}

			if ( $cancelBtn.length ) {
				$cancelBtn.prop( "disabled", true );
				$cancelBtn.addClass( "btn-disabled disabled" );
			}
		}
	};

	intervalId = setInterval( fetchUpdate, fetchRate );
	setTimeout( scrollToBottom, 2000 );

} )( presideJQuery );