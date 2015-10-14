component {

	public any function init() {
		_setupNoticeStyles();
		return this;
	}

	public string function renderNoticeBoxes( required string html ) {
		var rendered = arguments.html;

		for( var noticeStyle in styles ) {

			do {
				var regexMatch = ReFind( noticeStyle.regex, rendered, 1, true );

				if ( regexMatch.len[1] ) {
					var raw    = Mid( rendered, regexMatch.pos[1], regexMatch.len[1] );
					var notice = Mid( rendered, regexMatch.pos[2], regexMatch.len[2] );

					rendered = Replace( rendered, raw, _renderNoticeBox( noticeStyle, notice ) );
				}
			} while( regexMatch.len[1] );
		}

		return rendered;
	}

// PRIVATE
	private void function _setupNoticeStyles() {
		styles = [
			  { blockQuoteCount=6, colour="green" , icon="info", title="Tip" }
			, { blockQuoteCount=5, colour="red"   , icon="info", title="Important" }
			, { blockQuoteCount=4, colour="yellow", icon="info", title="Warning" }
			, { blockQuoteCount=3, colour="blue"  , icon="info", title="Info" }
		];
		for( var i=1; i<=styles.len(); i++ ) {
			styles[i].regex = RepeatString( "<blockquote>\s*", styles[i].blockQuoteCount ) & "(.*?)" & RepeatString( "<\/blockquote>\s*", styles[i].blockQuoteCount );
		}
	}

	private string function _renderNoticeBox( required struct style, required string notice ) {
		return '<div class="card-wrap">
			<div class="card card-#arguments.style.colour#">
				<aside class="card-side">
					<span class="card-heading icon icon-#arguments.style.icon#"></span>
				</aside>
				<div class="card-main">
					<div class="card-inner">
						<p class="card-heading">#arguments.style.title#</p>
						#arguments.notice#
					</div>
				</div>
			</div>
		</div>';
	}

}