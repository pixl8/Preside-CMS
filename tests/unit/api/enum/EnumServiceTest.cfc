component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "listItems()", function(){
			it( "should return an array of translated items for the corresponding enum in the order in which they are defined", function(){
				var service = _getService();
				var enum    = "assetAccess";
				var uriBase = "enum.#enum#:";

				for( var item in _getTestConfiguredEnums()[ enum ] ) {
					service.$( "$translateResource" ).$args( uri=uriBase & "#item#.label"      , defaultValue=item, data=[] ).$results( "#item# label" );
					service.$( "$translateResource" ).$args( uri=uriBase & "#item#.description", defaultValue=""  , data=[] ).$results( "#item# description" );
				}

				expect( service.listItems( enum ) ).toBe( [
					  { id="inherit", label="inherit label", description="inherit description" }
					, { id="none"   , label="none label"   , description="none description"    }
					, { id="full"   , label="full label"   , description="full description"    }
				] );
			} );

			it( "should honour registered translation templates", function(){
				var service = _getService();

				service.registerEnum(
					  enum         = "presideobjects"
					, keys         = [ "crm_contact" ]
					, translations = {
						  label       = "preside-objects.{key}:title"
						, description = "preside-objects.{key}:description"
					  }
				);
				service.$( "$translateResource" )
					.$args( uri="preside-objects.crm_contact:title", defaultValue="crm_contact", data=[] )
					.$results( "Contacts" );
				service.$( "$translateResource" )
					.$args( uri="preside-objects.crm_contact:description", defaultValue="", data=[] )
					.$results( "CRM contacts" );

				expect( service.listItems( "presideobjects" ) ).toBe( [
					{ id="crm_contact", label="Contacts", description="CRM contacts" }
				] );
			} );
		} );

		describe( "translate()", function(){
			it( "should use the default enum URI and the key as the label fallback", function(){
				var service = _getService();

				service.$( "$translateResource" )
					.$args( uri="enum.assetAccess:inherit.label", defaultValue="inherit", data=[] )
					.$results( "Inherit" );

				expect( service.translate( enum="assetAccess", key="inherit", property="label" ) ).toBe( "Inherit" );
			} );

			it( "should default non-label properties to an empty string", function(){
				var service = _getService();

				service.$( "$translateResource" )
					.$args( uri="enum.assetAccess:inherit.iconClass", defaultValue="", data=[] )
					.$results( "" );

				expect( service.translate( enum="assetAccess", key="inherit", property="iconClass" ) ).toBe( "" );
			} );

			it( "should pass explicit fallback and translation data through", function(){
				var service = _getService();
				var data    = [ "one", "two" ];

				service.$( "$translateResource" )
					.$args( uri="enum.assetAccess:inherit.message", defaultValue="Fallback", data=data )
					.$results( "Translated" );

				expect( service.translate(
					  enum         = "assetAccess"
					, key          = "inherit"
					, property     = "message"
					, defaultValue = "Fallback"
					, data         = data
				) ).toBe( "Translated" );
			} );

			it( "should replace key and enum placeholders in registered templates", function(){
				var service = _getService();

				service.registerEnum(
					  enum         = "custom"
					, keys         = [ "first" ]
					, translations = { label="registered.{enum}.{key}:title" }
				);

				expect( service.getTranslationUri( enum="custom", key="first", property="label" ) ).toBe( "registered.custom.first:title" );
			} );
		} );

		describe( "registerEnum()", function(){
			it( "should add keys to the configured enum struct", function(){
				var configuredEnums = _getTestConfiguredEnums();
				var service         = _getService( configuredEnums );

				service.registerEnum( enum="custom", keys=[ "first", "second" ] );

				expect( configuredEnums.custom ).toBe( [ "first", "second" ] );
			} );

			it( "should replace existing keys and translation templates", function(){
				var configuredEnums = _getTestConfiguredEnums();
				var service         = _getService( configuredEnums );

				service.registerEnum(
					  enum         = "custom"
					, keys         = [ "first" ]
					, translations = { label="registered.{key}:title" }
				);
				service.registerEnum( enum="custom", keys=[ "second" ] );

				expect( configuredEnums.custom ).toBe( [ "second" ] );
				expect( service.getTranslationUri( enum="custom", key="second", property="label" ) ).toBe( "enum.custom:second.label" );
			} );

			it( "should make custom templates available to getLabelByKey()", function(){
				var service = _getService();

				service.registerEnum(
					  enum         = "custom"
					, keys         = [ "first" ]
					, translations = { label="registered.{key}:title" }
				);
				service.$( "$translateResource" )
					.$args( uri="registered.first:title", defaultValue="first", data=[] )
					.$results( "First item" );

				expect( service.getLabelByKey( enum="custom", key="first" ) ).toBe( "First item" );
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService( struct configuredEnums=_getTestConfiguredEnums() ) {
		var service = createMock( object=new preside.system.services.enum.EnumService( configuredEnums ) );

		return service;
	}

	private struct function _getTestConfiguredEnums() {
		return {
			  assetAccess  = [ "inherit", "none", "full"        ]
			, linkType     = [ "blank", "self", "parent", "top" ]
			, linkProtocol = [ "http", "https", "ftp", "sftp"   ]
		};
	}
}