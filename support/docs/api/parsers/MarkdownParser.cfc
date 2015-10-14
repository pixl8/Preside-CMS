component {
	public any function init() {
		_setupMarkdownProcessor();
		_setupNoticeBoxRenderer();

		return this;
	}

	public string function markdownToHtml( required string markdown ) {
		var html = _getMarkdownProcessor().markdownToHtml( arguments.markdown );
		return _getNoticeBoxRenderer().renderNoticeBoxes( html );
	}

// PRIVATE
	private void function _setupMarkdownProcessor() {
		var javaLib   = [ "../lib/parboiled-core-1.1.7.jar", "../lib/parboiled-java-1.1.7.jar",  "../lib/pegdown-1.5.0.jar" ];
		var processor = CreateObject( "java", "org.pegdown.PegDownProcessor", javaLib ).init();

		_setMarkdownProcessor( processor );
	}

	private void function _setupNoticeBoxRenderer() {
		var javaLib   = [ "../lib/parboiled-core-1.1.7.jar", "../lib/parboiled-java-1.1.7.jar",  "../lib/pegdown-1.5.0.jar" ];
		var processor = CreateObject( "java", "org.pegdown.PegDownProcessor", javaLib ).init();

		_setNoticeBoxRenderer( new api.rendering.NoticeBoxRenderer() );
	}

	private any function _getMarkdownProcessor() output=false {
		return _markdownProcessor;
	}
	private void function _setMarkdownProcessor( required any markdownProcessor ) output=false {
		_markdownProcessor = arguments.markdownProcessor;
	}

	private any function _getNoticeBoxRenderer() {
		return _noticeBoxRenderer;
	}
	private void function _setNoticeBoxRenderer( required any noticeBoxRenderer ) {
		_noticeBoxRenderer = arguments.noticeBoxRenderer;
	}
}