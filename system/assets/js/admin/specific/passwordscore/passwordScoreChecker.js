( function( $ ){

	$.fn.passwordScoreChecker = function(){
		var scoreTemplate   = '<div class="password-score"><div class="score-bar-container"><div class="score-bar"></div></div><div class="score-title"></div><div class="clearfix"></div></div>'
		  , scoreCheckerUrl = cfrequest.passwordScoreCheckerUrl
		  , typingDelay     = 600

		return this.each( function(){
			var $passwordInput  = $( this )
			  , $scoreContainer = $( scoreTemplate )
			  , context         = $passwordInput.data( "passwordPolicyContext" )
			  , updateScore, showScore, scoreCache={};

			$passwordInput.after( $scoreContainer );


			recalculateScore = function(){
				var password = $passwordInput.val();

				setTimeout( function(){
					if ( password === $passwordInput.val() ) {
						if ( scoreCache.hasOwnProperty( password ) ) {
							showScore( scoreCache[ password ] );
						} else {
							$.getJSON( scoreCheckerUrl, { password : password, context : context }, function( scoreData ){
								scoreCache[ password ] = scoreData;
								if ( password === $passwordInput.val() ) {
									showScore( scoreData );
								}
							} );
						}
					}

				}, typingDelay );
			};

			showScore = function( scoreData ){
				$scoreContainer.attr( "class", "password-score " + scoreData.name );
				$scoreContainer.find( ".score-bar" ).animate( { width : scoreData.score + "%" } );
				$scoreContainer.find( ".score-title" ).html( scoreData.title );
			};

			$passwordInput.on( "keyup", recalculateScore );

		} );
	};

	$( "input[ type='password' ]" ).filter( function(){
		var $input        = $( this )
		  , policyContext = $input.data( "passwordPolicyContext" );

		return policyContext && policyContext.length > 0;
	} ).passwordScoreChecker();

} )( typeof presideJQuery !== 'undefined' ? presideJQuery : jQuery );