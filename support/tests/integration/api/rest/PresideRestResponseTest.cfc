component extends="testbox.system.BaseSpec"{

	function beforeAll() {
		variables.restResponse = new preside.system.services.rest.PresideRestResponse();
	}

	function run(){
		describe( "getMemento()", function(){

			it( "should return a struct with default values for all response settings when no methods called on the object", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();
				var memento = restResponse.getMemento();

				expect( memento ).toBe( {
					  data         = NullValue()
					, mimeType     = "application/json"
					, renderer     = "json"
					, statusCode   = 200
					, statusText   = ""
					, headers      = NullValue()
					, finished     = false
				} );

			} );

		} );

		describe( "setStatus", function(){

			it( "should result in status code being set to the provided status code", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();
				restResponse.setStatus( 301 );

				expect( restResponse.getMemento().statusCode ).toBe( 301 );
			} );

			it( "should set the provided status text", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();
				restResponse.setStatus( text="Everything is awesome" );

				expect( restResponse.getMemento().statusText ).toBe( "Everything is awesome" );

			} );

			it( "should return a reference to itself so that methods can be chained", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();
				var result = restResponse.setStatus( 404 );

				expect( result ).toBe( restResponse );
			} );

		} );

		describe( "setHeaders", function(){

			it( "should result in headers struct being set to the headers", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();
				var testHeaders = { "X-Rest-Stuff" = CreateUUId(), "X-Test-Stuff" = true };

				restResponse.setHeaders( testHeaders );

				expect( restResponse.getMemento().headers ).toBe( testHeaders );
			} );

			it( "should append new headers to pre-existing headers when called multiple times", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();
				var testHeaders  = { "X-Rest-Stuff" = CreateUUId(), "X-Test-Stuff" = true };
				var testHeaders2 = { "X-Rest-Stuff" = CreateUUId(), another="test" };
				var expected     = Duplicate( testHeaders );

				expected.append( testHeaders2 );

				restResponse.setHeaders( testHeaders );
				restResponse.setHeaders( testHeaders2 );

				expect( restResponse.getHeaders() ).toBe( expected );

			} );

			it( "should return a reference to itself so that methods can be chained", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();
				var result = restResponse.setHeaders( { test=true } );

				expect( result ).toBe( restResponse );
			} );

		} );

		describe( "setHeader", function(){

			it( "should append the passed header (name and value) to the response headers", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();
				var testHeaders  = { "X-Rest-Stuff" = CreateUUId(), "X-Test-Stuff" = true };
				var testHeaders2 = { another="test" };
				var expected     = Duplicate( testHeaders );

				expected.append( testHeaders2 );

				restResponse.setHeaders( testHeaders );
				restResponse.setHeader( "another", "test" );

				expect( restResponse.getHeaders() ).toBe( expected );
			} );

		} );

		describe( "setData()", function(){

			it( "should set the data of the response to the passed value", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();
				var someResponse = { "lovely" = "response", test = CreateUUId() };

				restResponse.setData( someResponse );

				expect( restResponse.getMemento().data ).toBe( someResponse );
			} );

			it( "should return a reference to itself so that methods can be chained", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();
				var result = restResponse.setData( { test=true } );

				expect( result ).toBe( restResponse );
			} );

		} );

		describe( "noData()", function(){

			it( "should set the response data to NULL", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();
				restResponse.setData( "sjfljksldfj" );

				restResponse.noData();

				expect( restResponse.getData() ).toBeNull();
			} );

			it( "should set the renderer to 'plain'", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();

				restResponse.noData();

				expect( restResponse.getRenderer() ).toBe( "plain" );
			} );

			it( "should set the mime type to 'text/plain'", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();

				restResponse.noData();

				expect( restResponse.getMimeType() ).toBe( "text/plain" );
			} );

			it( "should return a reference to itself so that methods can be chained", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();
				var result = restResponse.noData();

				expect( result ).toBe( restResponse );
			} );

		} );

		describe( "setMimeType", function(){
			it( "should result in mime type being set to the provided mime type", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();
				restResponse.setMimeType( "text/plain" );

				expect( restResponse.getMemento().mimeType ).toBe( "text/plain" );
			} );

			it( "should return a reference to itself so that methods can be chained", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();
				var result = restResponse.setMimeType( "duumy/type" );

				expect( result ).toBe( restResponse );
			} );
		} );

		describe( "setRenderer", function(){
			it( "should result in renderer being set to the provided renderer", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();
				restResponse.setRenderer( "plain" );

				expect( restResponse.getMemento().renderer ).toBe( "plain" );
			} );

			it( "should return a reference to itself so that methods can be chained", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();
				var result = restResponse.setRenderer( "duumytype" );

				expect( result ).toBe( restResponse );
			} );
		} );

		describe( "setError", function(){
			it( "should result in a default set of error status codes and headers when no arguments passed", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();

				restResponse.setData( "test" );
				restResponse.setError();

				expect( restResponse.getData() ).toBeNull();
				expect( restResponse.getStatusCode() ).toBe( 500 );
				expect( restResponse.getStatusText() ).toBe( "Unspecified error" );

				var headers = restResponse.getHeaders();
				expect( headers[ "X-REST-ERROR-MESSAGE" ] ?: "" ).toBe( "An unhandled exception occurred within the REST API" );


			} );

			it( "should use the supplied error code as the response status code", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();

				restResponse.setError( errorCode=451 );

				expect( restResponse.getStatusCode() ).toBe( 451 );
			} );

			it( "should use the supplied error type as the status text", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();

				restResponse.setError( type="Verb not supported" );

				expect( restResponse.getStatusText() ).toBe( "Verb not supported" );
			} );

			it( "should use set X-REST-ERROR-MESSAGE header for error message", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();

				restResponse.setError( message="Verb not supported" );

				expect( restResponse.getHeaders()[ "X-REST-ERROR-MESSAGE"] ).toBe( "Verb not supported" );
			} );

			it( "should use set X-REST-ERROR-DETAIL header for error detail", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();

				restResponse.setError( detail="Verb not supported" );

				expect( restResponse.getHeaders()[ "X-REST-ERROR-DETAIL"] ).toBe( "Verb not supported" );
			} );
		} );

		describe( "finish", function(){
			it( "should set the finished flag on the response", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();

				restResponse.finish();

				expect( restResponse.getFinished() ).toBe( true );
			} );

			it( "should return a reference to itself so that methods can be chained", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();
				var result = restResponse.finish();

				expect( result ).toBe( restResponse );
			} );
		} );

		describe( "isFinished", function(){
			it( "should return false when response is not finished", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();

				expect( restResponse.isFinished() ).toBe( false );
			} );
			it( "should return true when response is finished", function(){
				var restResponse = new preside.system.services.rest.PresideRestResponse();

				restResponse.finish();

				expect( restResponse.isFinished() ).toBe( true );
			} );

		} );

	}

}