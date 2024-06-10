component extends="testbox.system.BaseSpec"{

	function beforeAll() {
		generator = new preside.system.services.qrcodes.QrCodeGenerator();
	}

	function run(){
		describe( "generateQrCode", function(){
			it( "should produce a predictable barcode image binary from text input", function(){
				var generated = generator.generateQrCode( "hello world" );
				var expected  = FileReadBinary( "/resources/qrcodes/helloWorldDefaults.gif" );

				expect( generated ).toBe( expected );

			} );

			it( "Should produce a square image with specified dimension size (pixels)", function(){
				var generated = generator.generateQrCode( input="hello world", size=300 );
				var expected  = FileReadBinary( "/resources/qrcodes/helloWorld300x300.gif" );

				expect( generated ).toBe( expected );
			} );

			it( "should produce a jpg when 'jpg' specified as image type", function(){
				var generated = generator.generateQrCode( input="hello world", imageType="jpg" );
				var expected  = FileReadBinary( "/resources/qrcodes/helloWorld.jpg" );

				expect( generated ).toBe( expected );
			} );
		} );
	}
}