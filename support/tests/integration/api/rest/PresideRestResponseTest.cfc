component extends="testbox.system.BaseSpec"{

	function beforeAll() {
		variables.restResponse = new preside.system.services.rest.PresideRestResponse();
	}

	function run(){
		describe( "getMemento()", function(){

			it( "should return a struct with default values for all response settings when no methods called on the object", function(){
				var memento = restResponse.getMemento();

				expect( memento ).toBe( {
					  data         = NullValue()
					, mimeType     = "application/json"
					, statusCode   = 200
					, headers      = NullValue()
				} );

			} );

		} );

		describe( "withStatus", function(){

			it( "should result in status code being set to the provided status", function(){
				restResponse.withStatus( 301 );

				expect( restResponse.getMemento().statusCode ).toBe( 301 );
			} );

			it( "should return a reference to itself so that methods can be chained", function(){
				var result = restResponse.withStatus( 404 );

				expect( result ).toBe( restResponse );
			} );

		} );

		describe( "withHeaders", function(){

			it( "should result in headers struct being set to the headers", function(){
				var testHeaders = { "X-Rest-Stuff" = CreateUUId(), "X-Test-Stuff" = true };

				restResponse.withHeaders( testHeaders );

				expect( restResponse.getMemento().headers ).toBe( testHeaders );
			} );

			it( "should append new headers to pre-existing headers when called multiple times", function(){
				var testHeaders  = { "X-Rest-Stuff" = CreateUUId(), "X-Test-Stuff" = true };
				var testHeaders2 = { "X-Rest-Stuff" = CreateUUId(), another="test" };
				var expected     = Duplicate( testHeaders );

				expected.append( testHeaders2 );

				restResponse.withHeaders( testHeaders );
				restResponse.withHeaders( testHeaders2 );

				expect( restResponse.getHeaders() ).toBe( expected );

			} );

			it( "should return a reference to itself so that methods can be chained", function(){
				var result = restResponse.withHeaders( { test=true } );

				expect( result ).toBe( restResponse );
			} );

		} );

		describe( "representationOf()", function(){

			it( "should set the data of the response to the passed value", function(){
				var someResponse = { "lovely" = "response", test = CreateUUId() };

				restResponse.representationOf( someResponse );

				expect( restResponse.getMemento().data ).toBe( someResponse );
			} );

			it( "should return a reference to itself so that methods can be chained", function(){
				var result = restResponse.representationOf( { test=true } );

				expect( result ).toBe( restResponse );
			} );

		} );

		describe( "noData()", function(){

			it( "should set the response data to NULL", function(){
				restResponse.setData( "sjfljksldfj" );

				restResponse.noData();

				expect( restResponse.getData() ).toBeNull();
			} );

			it( "should return a reference to itself so that methods can be chained", function(){
				var result = restResponse.noData();

				expect( result ).toBe( restResponse );
			} );

		} );

		describe( "withMimeType", function(){
			it( "should result in mime type being set to the provided mime type", function(){
				restResponse.withMimeType( "text/plain" );

				expect( restResponse.getMemento().mimeType ).toBe( "text/plain" );
			} );

			it( "should return a reference to itself so that methods can be chained", function(){
				var result = restResponse.withMimeType( "duumy/type" );

				expect( result ).toBe( restResponse );
			} );
		} );

	}

}