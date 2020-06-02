/**
 * A Validation Result object is used throughout the system
 * as part of the validation and forms framework. It is mostly a plain
 * bean but with the addition of some helper methods to make
 * interacting with the result intuitive for the developer.
 *
 * @autodoc
 *
 */
component accessors=true displayname="Validation result" {

	property name="generalMessage" type="string";
	property name="messages"       type="struct";

	public any function init() {
		setMessages({});
		setGeneralMessage("");

		return this;
	}

	/**
	 * Returns whether or not there are no reported
	 * errors in the result. i.e. if there are no errors
	 * reported, the method will return `true`; otherwise
	 * `false`.
	 *
	 * @autodoc
	 */
	public boolean function validated() {
		return not Len( Trim( getGeneralMessage() ) ) and not StructCount( getMessages() );
	}

	/**
	 * Adds an error report to the result.
	 *
	 * @autodoc
	 * @fieldName.hint The name of the field to which the message pertains
	 * @message.hint   The error message, can be plain text or an i18n resource key
	 * @params.hint    If the message is an i18n resource key, params can be passed here to be used as token replacements in the translation
	 *
	 */
	public void function addError( required string fieldName, required string message, array params=[] ) {
		var messages = getMessages();

		messages[ arguments.fieldName ] = {
			  message = arguments.message
			, params  = arguments.params
		};
	}

	/**
	 * Returns an array of fieldnames that have errors
	 * registered against them.
	 *
	 * @autodoc
	 */
	public array function listErrorFields() {
		var fields = StructKeyArray( getMessages() );

		ArraySort( fields, "textnocase" );

		return fields;
	}

	/**
	 * Returns the error message for a given field.
	 *
	 * @autodoc
	 * @fieldName.hint The name of the field whose error you wish to get.
	 */
	public string function getError( required string fieldName ) {
		var messages = getMessages();

		if ( StructKeyExists( messages, arguments.fieldName ) ) {
			return getMessages()[ arguments.fieldName ].message;
		}

		return "";
	}

	/**
	 * Returns whether or not the given field has an error.
	 *
	 * @autodoc
	 * @fieldName.hint The name of the field that you wish to check.
	 */
	public boolean function fieldHasError( required string fieldName ) {
		return StructKeyExists( getMessages(), arguments.fieldName );
	}

	/**
	 * Returns the i18n resource params registered for a particular
	 * field's error
	 *
	 * @autodoc
	 * @fieldname.hint The name of the field whose parameters you wish to get.
	 *
	 */
	public array function listErrorParameterValues( required string fieldName ) {
		var messages = getMessages();

		if ( StructKeyExists( messages, arguments.fieldName ) ) {
			return getMessages()[ arguments.fieldName ].params;
		}

		return [];
	}

}