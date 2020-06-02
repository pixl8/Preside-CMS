/**
 * @singleton      true
 * @presideservice true
 *
 */
component {

	public any function init() {
		this.ERROR_CODES = {
			  PARSE_ERROR      = -32700
			, INVALID_REQUEST  = -32600
			, METHOD_NOT_FOUND = -32601
			, INVALID_PARAMS   = -32602
			, INTERNAL_ERROR   = -32603
		};

		return this;
	}

	public boolean function readRequest() {
		var event       = $getRequestContext();
		var prc         = event.getCollection( private = true );
		var rawInput    = event.getHTTPContent();
		var parsedInput = {};

		try {
			parsedInput = DeSerializeJson( rawInput );
		} catch ( any e ) {
			error( this.ERROR_CODES.PARSE_ERROR, "Invalid JSON-RPC request: invalid json" );
			return false;
		}

		if ( ( parsedInput.jsonrpc ?: "" ) != "2.0" ) {
			error( this.ERROR_CODES.INVALID_REQUEST, "Invalid JSON-RPC request: missing or invalid protocol version. Expected 2.0 but received [#( parsedInput.jsonrpc ?: '' )#]. Request body was: [#request.body#]." );
			return false;
		}

		if ( !Len( Trim( parsedInput.method ?: "" ) ) ) {
			error( this.ERROR_CODES.INVALID_REQUEST, "Invalid JSON-RPC request: no method specified", parsedInput  );
			return false;
		}

		if ( StructKeyExists( parsedInput, "params" ) ) {
			if ( !IsArray( parsedInput.params ) && !IsStruct( parsedInput.params  ) ) {
				error( this.ERROR_CODES.INVALID_REQUEST, "Invalid JSON-RPC request: input params must be either an array or structure" );
				return false;
			}
		}

		prc._jsonRpc2Request = {
			  id     : parsedInput.id ?: NullValue()
			, method : parsedInput.method
			, params : parsedInput.params ?: []
		};

		return true;
	}

	public struct function getJsonRpcRequest() {
		var prc = $getRequestContext().getCollection( private = true );

		if ( not StructKeyExists( prc, "_jsonRpc2Request" ) ) {
			if ( !readRequest() ) {
				return {};
			}
		}

		return prc._jsonRpc2Request;
	}

	public string function getRequestId() {
		var rq = getJsonRpcRequest();
		return rq.id ?: NullValue();
	}

	public any function getRequestParams() {
		var rq = getJsonRpcRequest();

		return rq.params ?: [];
	}

	public any function getRequestMethod() {
		var rq = getJsonRpcRequest();
		return rq.method ?: "";
	}

	public void function success( required any result ) {
		var event    = $getRequestContext();
		var response = {
			  jsonrpc = "2.0"
			, id      = getRequestId()
			, result  = arguments.result
		}

		event.renderData( data=response, type="JSON" );
	}

	public void function error( required numeric code, required string message, any data ) {
		var event = $getRequestContext();
		var prc   = event.getCollection( private = true );
		var response = {
			  jsonrpc = "2.0"
			, id      = prc._jsonRpc2Request.id ?: NullValue()
			, error   = { code : arguments.code, message=arguments.message }
		}

		if ( StructKeyExists( arguments, "data" ) ) {
			response.error.data = arguments.data;
		}

		event.renderData( data=response, type="JSON" );
	}
}