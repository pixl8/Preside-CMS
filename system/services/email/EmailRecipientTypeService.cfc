/**
 * Service to provide logic around recipient types
 *
 * @singleton      true
 * @presideservice true
 * @autodoc        true
 *
 */
component displayName="Email Recipient Type Service" {

// CONSTRUCTOR
	/**
	 * @configuredRecipientTypes.inject coldbox:setting:email.recipientTypes
	 *
	 */
	public any function init(
		  required struct configuredRecipientTypes
	) {
		_setConfiguredRecipientTypes( arguments.configuredRecipientTypes );

		return this;
	}

// PUBLIC API
	/**
	 * Returns an array of recipient types with translated titles and descriptions,
	 * ordered by title.
	 *
	 * @autodoc true
	 */
	public array function listRecipientTypes() {
		var types           = [];
		var configuredTypes = _getConfiguredRecipientTypes();

		for( var typeId in configuredTypes ){
			types.append({
				  id          = typeId
				, title       = $translateResource( uri="email.recipienttype.#typeId#:title"      , defaultValue=typeId )
				, description = $translateResource( uri="email.recipienttype.#typeId#:description", defaultValue=""     )
			});
		}

		types.sort( function( a, b ){
			return a.title > b.title ? 1 : -1;
		} );

		return types;
	}

	/**
	 * Returns a single type as a structure
	 *
	 */
	public struct function getRecipientTypeDetails( required string recipientType ) {
		return {
			  id          = recipientType
			, title       = $translateResource( uri="email.recipienttype.#recipientType#:title"      , defaultValue=recipientType )
			, description = $translateResource( uri="email.recipienttype.#recipientType#:description", defaultValue=""     )
		};
	}

	/**
	 * Returns whether or not the passed recipient type exists.
	 *
	 * @autodoc            true
	 * @recipientType.hint ID of the type to check
	 *
	 */
	public boolean function recipientTypeExists( required string recipientType ) {
		return StructKeyExists( _getConfiguredRecipientTypes(), arguments.recipientType );
	}

	/**
	 * Returns an array of configurable parameters for the given
	 * recipient type. Each item in the array is a struct
	 * with the keys, `id`, `title`, `description` and `required`.
	 * The array is sorted by title.
	 *
	 * @autodoc            true
	 * @recipientType.hint ID of the recipient type whose parameters you wish to get
	 *
	 */
	public array function listRecipientTypeParameters( required string recipientType ) {
		var params     = [];
		var types      = _getConfiguredRecipientTypes();
		var typeParams = types[ arguments.recipientType ].parameters ?: [];

		for( var param in typeParams ) {
			var translatedParam = {};

			if ( IsSimpleValue( param ) ) {
				translatedParam = {
					  id = param
					, required = false
				};
			} else {
				translatedParam = {
					  id       = param.id ?: CreateUUId()
					, required = IsBoolean( param.required ?: "" ) && param.required
				};
			}

			translatedParam.title       = $translateResource( uri="email.recipientType.#arguments.recipientType#:param.#translatedParam.id#.title"      , defaultValue=translatedParam.id );
			translatedParam.description = $translateResource( uri="email.recipientType.#arguments.recipientType#:param.#translatedParam.id#.description", defaultValue="" );

			params.append( translatedParam );
		}

		params.sort( function( a, b ){
			return a.title > b.title ? 1 : -1;
		} );

		return params;
	}

	/**
	 * Prepares email parameters (variables for substituting in subject + body)
	 * for the given recipient type and provided args (e.g. could contain user id)
	 *
	 * @autodoc             true
	 * @recipientType.hint  The ID of the recipient type whose params we are to prepare
	 * @recipientId.hint    The ID of the recipient
	 * @args.hint           Structure of variables sent to the sendEmail() method, should contain enough data to inform the method how to prepare the params. e.g. { userId=idofUserToSendEmailTo }.
	 * @template.hint       ID of the template being prepared
	 * @templateDetail.hint Structure with details of the template being prepared
	 */
	public struct function prepareParameters(
		  required string recipientType
		, required string recipientId
		,          struct args           = {}
		,          string template       = ""
		,          struct templateDetail = {}
	) {
		var handlerAction = "email.recipientType.#recipientType#.prepareParameters";

		if ( recipientTypeExists( arguments.recipientType ) && $getColdbox().handlerExists( handlerAction ) ) {
			return $getColdbox().runEvent(
				  event          = handlerAction
				, private        = true
				, prePostExempt  = true
				, eventArguments = {
					  args           = arguments.args
					, recipientId    = arguments.recipientId
					, template       = arguments.template
					, templateDetail = arguments.templateDetail
				  }
			);
		}

		return {};
	}

	/**
	 * Returns a struct of "preview" parameters that can be used to preview an
	 * email template.
	 *
	 * @autodoc            true
	 * @recipientType.hint The ID of the recipient type whose preview params we are to get
	 */
	public struct function getPreviewParameters( required string recipientType ) {
		var handlerAction = "email.recipientType.#recipientType#.getPreviewParameters";

		if ( recipientTypeExists( arguments.recipientType ) && $getColdbox().handlerExists( handlerAction ) ) {
			return $getColdbox().runEvent(
				  event          = handlerAction
				, private        = true
				, prePostExempt  = true
			);
		}

		return {};
	}

	/**
	 * Returns the to address for the given recipient type and message
	 * args.
	 *
	 * @autodoc            true
	 * @recipientType.hint The ID of the recipient type whose to address we are to get
	 * @recipientId.hint   ID of the recipient of the email
	 */
	public string function getToAddress(
		  required string recipientType
		, required string recipientId
	) {
		var handlerAction = "email.recipientType.#recipientType#.getToAddress";

		if ( recipientTypeExists( arguments.recipientType ) && $getColdbox().handlerExists( handlerAction ) ) {
			return $getColdbox().runEvent(
				  event          = handlerAction
				, eventArguments = { recipientId=arguments.recipientId }
				, private        = true
				, prePostExempt  = true
			);
		}

		return "";
	}

	/**
	 * Returns and unsubscribe link for the given recipient and template ID
	 *
	 * @autodoc            true
	 * @recipientType.hint The ID of the recipient type whose link we will get
	 * @recipientId.hint   ID of the recipient of the email
	 * @templateId.hint    ID of the email template
	 */
	public string function getUnsubscribeLink(
		  required string recipientType
		, required string recipientId
		, required string templateId
	) {
		var handlerAction = "email.recipientType.#recipientType#.getUnsubscribeLink";

		if ( recipientTypeExists( arguments.recipientType ) && $getColdbox().handlerExists( handlerAction ) ) {
			return $getColdbox().runEvent(
				  event          = handlerAction
				, eventArguments = { recipientId=arguments.recipientId, templateId=arguments.templateId }
				, private        = true
				, prePostExempt  = true
			);

		}

		var interceptData = {
			  templateId    = arguments.templateId
			, recipientId   = arguments.recipientId
			, recipientType = arguments.recipientType
		};

		$announceInterception(
			  state         = "onGenerateEmailUnsubscribeLink"
			, interceptData = interceptData
		);

		return interceptData.unsubscribeLink ?: "";
	}

	/**
	 * Returns the configured filter object for the given recipient type
	 *
	 * @autodoc            true
	 * @recipientType.hint The ID of the recipient type whose filter object we are to get
	 */
	public string function getFilterObjectForRecipientType( required string recipientType ) {
		var types = _getConfiguredRecipientTypes();

		return types[ arguments.recipientType ].filterObject ?: "";
	}

	/**
	 * Returns the configured foreign key property name on the email log table that
	 * corresponds to this recipient type
	 *
	 * @autodoc            true
	 * @recipientType.hint The ID of the recipient type whose log property name we are to get
	 */
	public string function getRecipientIdLogPropertyForRecipientType( required string recipientType ) {
		var types = _getConfiguredRecipientTypes();

		return types[ arguments.recipientType ].recipientIdLogProperty ?: "";
	}

	/**
	 * Returns the configured additional data keys / selectors on the email log table that
	 * corresponds to this recipient type
	 *
	 * @autodoc            true
	 * @recipientType.hint The ID of the recipient type whose log property name we are to get
	 */
	public struct function getRecipientAdditionalLogProperties( required string recipientType ) {
		var types = _getConfiguredRecipientTypes();

		return types[ arguments.recipientType ].additionalLogProperties ?: {};
	}


	/**
	 * Returns the configured grid fields for showing recipients of this type
	 *
	 * @autodoc            true
	 * @recipientType.hint The ID of the recipient type whose grid fields we are to get
	 */
	public array function getGridFieldsForRecipientType( required string recipientType ) {
		var types = _getConfiguredRecipientTypes();
		var gridFields = types[ arguments.recipientType ].gridFields ?: [];

		if ( IsArray( gridFields ) ) {
			return gridFields;
		}

		return [];
	}

// GETTERS AND SETTERS
	private any function _getConfiguredRecipientTypes() {
		return _configuredRecipientTypes;
	}
	private void function _setConfiguredRecipientTypes( required any configuredRecipientTypes ) {
		_configuredRecipientTypes = {};

		for( var typeId in arguments.configuredRecipientTypes ) {
			var type    = arguments.configuredRecipientTypes[ typeId ];
			var feature = Trim( type.feature ?: "" );

			if ( !feature.len() || $isFeatureEnabled( feature ) ) {
				_configuredRecipientTypes[ typeId ] = type;
			}
		}
	}
}