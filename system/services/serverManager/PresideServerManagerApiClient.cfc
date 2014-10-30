/**
 * The Server Manager API Client is an API wrapper for calling the Centralized Server Managerment system for PresideCMS
 *
 */
component output=false singleton=true {

// CONSTRUCTOR
	public any function init( required string endpoint, required string publicKey, required string privatekey ) output=false {
		_setEndpoint     ( arguments.endpoint      );
		_setPublicKey    ( arguments.publicKey     );
		_setPrivatekey   ( arguments.privatekey    );

		return this;
	}

// PUBLIC API METHODS
	public struct function getConfig( required string serverId, required string applicationId  ) output=false{
		var result = "";

		try {
			result = _apiCall(
				  apiMethod = "config"
				, args      = { serverId=arguments.serverId, websiteApplicationId=arguments.applicationId }
			);
		} catch ( any e ) {
			return {};
		}

		var config = result.config ?: {};

		return IsStruct( config ) ? config : {};
	}

// PRIVATE HELPERS
	private any function _apiCall( required string apiMethod, struct args={}, string httpMethod="GET" ) output=false {
		var ts         = Now();
		var signature  = _generateSignature( arguments.apiMethod, ts );
		var httpResult = "";
		var paramType  = arguments.httpMethod == "GET" ? "url" : "formfield";

		http url="#_getEndpoint()#/api/#arguments.apiMethod#/" timeout=5 result="httpResult" {
			httpparam name="publickey" value="#_getPublicKey()#"     type="#paramType#";
			httpparam name="timestamp" value="#ts#"                  type="#paramType#";
			httpparam name="signature" value="#signature#"           type="#paramType#";
			httpparam name="method"    value="#arguments.apiMethod#" type="#paramType#";

			for( var arg in arguments.args ){
				httpparam name="#arg#" value="#arguments.args[ arg ]#" type="#paramType#";
			}
		}

		if ( IsJson( httpResult.fileContent ) ) {
			return DeSerializeJson( httpResult.fileContent );
		}

		return httpResult;
	}

	private string function _generateSignature( required string apiMethod, required string timestamp ) output=false {
		var preEncryptedString = Hash( LCase( "method=#arguments.apiMethod#publicKey=#_getPublicKey()#timestamp=#arguments.timestamp#" ) );

		return Encrypt( preEncryptedString, _getPrivateKey(), "AES" );
	}

// GETTERS AND SETTERS
	private string function _getEndpoint() output=false {
		return _endpoint;
	}
	private void function _setEndpoint( required string endpoint ) output=false {
		_endpoint = arguments.endpoint;
	}

	private string function _getPublicKey() output=false {
		return _publicKey;
	}
	private void function _setPublicKey( required string publicKey ) output=false {
		_publicKey = arguments.publicKey;
	}

	private string function _getPrivatekey() output=false {
		return _privatekey;
	}
	private void function _setPrivatekey( required string privatekey ) output=false {
		_privatekey = arguments.privatekey;
	}

	private string function _getApplicationId() output=false {
		return _applicationId;
	}
	private void function _setApplicationId( required string applicationId ) output=false {
		_applicationId = arguments.applicationId;
	}
}