component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "sign()", function(){
			it( "accepts the parameters it signed", function(){
				var service   = _getService();
				var params    = _params();
				var signature = service.sign( params );

				expect( service.isValid( params=params, signature=signature ) ).toBeTrue();
			} );

			it( "returns a url safe signature", function(){
				var signature = _getService().sign( _params() );

				expect( ReFind( "[+/=]", signature ) ).toBe( 0 );
				expect( Len( signature ) ).toBeGT( 0 );
			} );

			it( "ignores request parameters that do not shape the result", function(){
				var service   = _getService();
				var params    = _params();
				var signature = service.sign( params );

				params.q              = "search term";
				params.maxRows        = "50";
				params.defaultValue   = "abc";
				params.sourceIdValue  = "record-1";

				expect( service.isValid( params=params, signature=signature ) ).toBeTrue();
			} );

			it( "treats a missing parameter as empty", function(){
				var service   = _getService();
				var params    = _params();
				var signature = service.sign( { object="security_user" } );

				expect( service.isValid( params=params, signature=signature ) ).toBeFalse();

				params = { object="security_user" };

				expect( service.isValid( params=params, signature=signature ) ).toBeTrue();
			} );
		} );

		describe( "isValid()", function(){
			it( "rejects a tampered object", function(){
				var service   = _getService();
				var params    = _params();
				var signature = service.sign( params );

				params.object = "website_user";

				expect( service.isValid( params=params, signature=signature ) ).toBeFalse();
			} );

			it( "rejects a tampered label renderer", function(){
				var service   = _getService();
				var params    = _params();
				var signature = service.sign( params );

				params.labelRenderer = "otherRenderer";

				expect( service.isValid( params=params, signature=signature ) ).toBeFalse();
			} );

			it( "rejects a tampered saved filter list", function(){
				var service   = _getService();
				var params    = _params();
				var signature = service.sign( params );

				params.savedFilters = "otherFilter";

				expect( service.isValid( params=params, signature=signature ) ).toBeFalse();
			} );

			it( "rejects a signature from another session", function(){
				var params    = _params();
				var signature = _getService().sign( params );

				expect( _getService().isValid( params=params, signature=signature ) ).toBeFalse();
			} );

			it( "rejects a blank signature", function(){
				expect( _getService().isValid( params=_params(), signature="" ) ).toBeFalse();
			} );
		} );
	}

	private struct function _params() {
		return {
			  object            = "security_user"
			, targetIdField     = "id"
			, savedFilters      = "activeUsers"
			, orderBy           = "known_as"
			, labelRenderer     = "security_user"
			, filterBy          = ""
			, filterByField     = ""
			, bypassTenants     = ""
			, useCache          = "false"
			, sourceObject      = ""
			, sourceObjectField = ""
		};
	}

	private any function _getService() {
		var store          = { key="" };
		var sessionStorage = getMockBox().createStub();
		var service        = getMockBox().prepareMock( new preside.system.services.admin.AjaxSelectSignatureService() );
		var cfsignatures   = new preside.system.modules.cfsignatures.models.CfSignatures();

		sessionStorage.$( "getVar" ).$callback( function(){
			return store.key;
		} );
		sessionStorage.$( "setVar" ).$callback( function(){
			store.key = arguments.value ?: ( arguments[ 2 ] ?: "" );
		} );
		service.$property( propertyName="sessionStorage", mock=sessionStorage );
		service.$property( propertyName="cfsignatures"  , mock=cfsignatures );

		return service;
	}

}
