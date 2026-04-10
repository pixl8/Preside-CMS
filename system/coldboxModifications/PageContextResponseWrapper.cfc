component {

	function init( required any resp ) {
		variables.resp = arguments.resp;

		return this;
	}

	// this is overriden to ensure compat with jakarta and javax
	// as statusText is no longer supported in jakarta.
	function setStatus( status, text="" ) {
		return variables.resp.setStatus( JavaCast( "int", arguments.status ) );
	}

	// due to not being able to call java object methods with argumentCollection
	// we need to also have wrapper methods for all the other methods on the response
	// object that external code may be calling. See https://presidecms.atlassian.net/browse/PRESIDECMS-3230.

	function addCookie( any cooky ) {
		return variables.resp.addCookie( arguments.cooky );
	}
	function addDateHeader( name, value ) {
		return variables.resp.addDateHeader( arguments.name, arguments.value );
	}
	function addHeader( name, value ) {
		return variables.resp.addHeader( arguments.name, arguments.value );
	}
	function addIntHeader( name, value ) {
		return variables.resp.addIntHeader( arguments.name, arguments.value );
	}
	function addOverridenRequestParameter( name, value ) {
		return variables.resp.addOverridenRequestParameter( arguments.name, arguments.value );
	}
	function containsHeader( name ) {
		return variables.resp.containsHeader( arguments.name );
	}
	function encodeRedirectURL( url ) {
		return variables.resp.encodeRedirectURL( arguments.url );
	}
	function encodeURL( url ) {
		return variables.resp.encodeURL( arguments.url );
	}
	function flushBuffer() {
		return variables.resp.flushBuffer();
	}
	function getBufferSize() {
		return variables.resp.getBufferSize();
	}
	function getCharacterEncoding() {
		return variables.resp.getCharacterEncoding();
	}
	function getContentType() {
		return variables.resp.getContentType();
	}
	function getHeader( name ) {
		return variables.resp.getHeader( arguments.name );
	}
	function getHeaderNames() {
		return variables.resp.getHeaderNames();
	}
	function getHeaders( name ) {
		return variables.resp.getHeaders( arguments.name );
	}
	function getLocale() {
		return variables.resp.getLocale();
	}
	function getOutputStream() {
		return variables.resp.getOutputStream();
	}
	function getOverridenMethod() {
		return variables.resp.getOverridenMethod();
	}
	function getOverridenRequestParameters() {
		return variables.resp.getOverridenRequestParameters();
	}
	function getResponse() {
		return variables.resp.getResponse();
	}
	function getStatus() {
		return variables.resp.getStatus();
	}
	function getTrailerFields() {
		return variables.resp.getTrailerFields();
	}
	function getWriter() {
		return variables.resp.getWriter();
	}
	function isCommitted() {
		return variables.resp.isCommitted();
	}
	function isWrapperFor( any obj ) {
		return variables.resp.isWrapperFor( arguments.obj );
	}
	function reset() {
		return variables.resp.reset();
	}
	function resetBuffer() {
		return variables.resp.resetBuffer();
	}
	function sendError( num, message ) {
		if ( StructKeyExists( arguments, "message" ) ) {
			return variables.resp.sendError( arguments.num, arguments.message );
		}
		return variables.resp.sendError( arguments.num );
	}
	function sendRedirect( url ) {
		return variables.resp.sendRedirect( arguments.url );
	}
	function setBufferSize( num ) {
		return variables.resp.setBufferSize( arguments.num );
	}
	function setCharacterEncoding( encoding ) {
		return variables.resp.setCharacterEncoding( arguments.encoding );
	}
	function setContentLength( num ) {
		return variables.resp.setContentLength( arguments.num );
	}
	function setContentLengthLong( num ) {
		return variables.resp.setContentLengthLong( arguments.num );
	}
	function setContentType( contentType ) {
		return variables.resp.setContentType( arguments.contentType );
	}
	function setDateHeader( name, value ) {
		return variables.resp.setDateHeader( arguments.name, arguments.value );
	}
	function setHeader( name, value ) {
		return variables.resp.setHeader( arguments.name, arguments.value );
	}
	function setIntHeader( name, value ) {
		return variables.resp.setIntHeader( arguments.name, arguments.value );
	}
	function setLocale( locale ) {
		return variables.resp.setLocale( arguments.locale );
	}
	function setOverridenMethod( method ) {
		return variables.resp.setOverridenMethod( arguments.method );
	}
	function setResponse( any resp ) {
		return variables.resp.setResponse( arguments.resp );
	}
	function setTrailerFields( any supplier ) {
		return variables.resp.setTrailerFields( arguments.supplier );
	}

}