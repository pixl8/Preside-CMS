component output=false accessors=true {

	property name="generalMessage" type="string";
	property name="messages"       type="struct";

	public any function init() output=false {
		setMessages({});
		setGeneralMessage("");

		return this;
	}

	public boolean function validated() output=false {
		return not Len( Trim( getGeneralMessage() ) ) and not StructCount( getMessages() );
	}

	public void function addError( required string fieldName, required string message, array params=[] ) output=false {
		var messages = getMessages();

		messages[ arguments.fieldName ] = {
			  message = arguments.message
			, params  = arguments.params
		};
	}

	public array function listErrorFields() output=false {
		var fields = StructKeyArray( getMessages() );

		ArraySort( fields, "textnocase" );

		return fields;
	}

	public string function getError( required string fieldName ) output=false {
		var messages = getMessages();

		if ( StructKeyExists( messages, arguments.fieldName ) ) {
			return getMessages()[ arguments.fieldName ].message;
		}

		return "";
	}

	public boolean function fieldHasError( required string fieldName ) output=false {
		return StructKeyExists( getMessages(), arguments.fieldName );
	}

	public array function listErrorParameterValues( required string fieldName ) output=false {
		var messages = getMessages();

		if ( StructKeyExists( messages, arguments.fieldName ) ) {
			return getMessages()[ arguments.fieldName ].params;
		}

		return [];
	}

}