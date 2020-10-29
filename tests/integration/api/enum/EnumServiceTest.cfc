component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "listItems()", function(){
			it( "should return an array of translated items for the corresponding enum in the order in which they are defined", function(){
				var service = _getService();
				var enum    = "assetAccess";
				var uriBase = "enum.#enum#:";

				for( var item in _getTestConfiguredEnums()[ enum ] ) {
					service.$( "$translateResource" ).$args( uri=uriBase & "#item#.label"      , defaultValue=item ).$results( "#item# label" );
					service.$( "$translateResource" ).$args( uri=uriBase & "#item#.description", defaultValue=""   ).$results( "#item# description" );
				}

				expect( service.listItems( enum ) ).toBe( [
					  { id="inherit", label="inherit label", description="inherit description" }
					, { id="none"   , label="none label"   , description="none description"    }
					, { id="full"   , label="full label"   , description="full description"    }
				] );
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