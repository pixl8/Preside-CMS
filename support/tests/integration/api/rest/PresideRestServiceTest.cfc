component extends="testbox.system.BaseSpec"{

	function run(){

		describe( "getResourceForRestPath()", function(){

			it( "should find first regex match for a passed URI", function(){
				var restService = getService();

				expect( restService.getResourceForRestPath( "/test/my-pattern/#CreateUUId()#/" ) ).toBe( {
					  handler    = "ResourceX"
					, tokens     = [ "pattern", "id" ]
					, uriPattern = "/test/(.*?)/(.*?)/"
					, verbs      = { post="post", get="get", delete="delete", put="putDataTest" }
				} );
			} );

			it( "should return an empty struct when no resource is found", function(){
				var restService = getService();

				expect( restService.getResourceForRestPath( "/whatever/this/is/#CreateUUId()#/" ) ).toBe( {} );
			} );

		} );

	}

	private any function getService( ) {
		variables.mockController = createStub();
		return createMock( object=new preside.system.services.rest.PresideRestService(
			  coldboxController   = mockController
			, resourceDirectories = [ "/resources/rest/dir1", "/resources/rest/dir2" ]
		) );
	}

}