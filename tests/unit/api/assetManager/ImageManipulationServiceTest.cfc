component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP, TEARDOWN, ETC.
	function setup() {
		super.setup();

		mockNativeImageImplementation = getMockBox().createMock( "preside.system.services.assetManager.NativeImageService" );
		mockImageMagickImplementation = getMockBox().createMock("preside.system.services.assetManager.imageMagickService");
		mockLibVipsImplementation     = getMockBox().createMock("preside.system.services.assetManager.VipsImageSizingService" );
		imageManipulationService      = getMockBox().createMock("preside.system.services.assetManager.imageManipulationService");
		helpers                       = getMockBox().createStub();

		mockImageMagickImplementation.init("",30);

		mockLibVipsImplementation.$( "enabled", false );

		imageManipulationService.$( "$getPresideCategorySettings", {
			  retrieve_metadata     = false
			, use_imagemagick       = false
			, imagemagick_path      = ""
			, imagemagick_timeout   = 30
			, imagemagick_interlace = false
		} );
		imageManipulationService.$( "$getPresideSetting" ).$args( "asset-manager", "use_imagemagick" ).$results( false );
		imageManipulationService.$property( propertyName="$helpers", mock=helpers );
		helpers.$( method="isTrue", callback=function( val ){
			return IsBoolean( arguments.val ?: "" ) && arguments.val;
		} );

		imageManipulationService = imageManipulationService.init(
			  nativeImageImplementation = mockNativeImageImplementation
			, imageMagickImplementation = mockImageMagickImplementation
			, libVipsImplementation     = mockLibVipsImplementation
		);
	}

// TESTS
	function test01_resize_shouldThrowAnInformativeError_whenPassedAssetIsNotAnImage() output=false {
		var errorThrown = false;
		var filePath    = "/tests/resources/assetManager/testfile.txt";

		try {
			imageManipulationService.resize(
				  filePath  = filePath
				, width     = 100
				, height    = 100
				, filename  = "testlandscape.jpg"
			);
		} catch ( "assetTransformer.resize.notAnImage" e ) {
			errorThrown = true;
		} catch ( any e ) {
			super.fail( "Expected an error of type [assetTransformer.resize.notAnImage] but received type [#e.type#] with message [#e.message#] instead" );
		}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test02_resize_shouldReturnResizedBinaryImage_withSpecifiedWidth_whenNoHeightSpecified() output=false {
		var tmpFile = _tmpFile( "/tests/resources/assetManager/testlandscape.jpg" );

		imageManipulationService.resize(
			  filePath  = tmpFile
			, width     = 100
			, filename  = "testlandscape.jpg"
		);

		var imgInfo = ImageInfo( ImageNew( tmpFile ) );

		FileDelete( tmpFile );

		super.assertEquals( 100, imgInfo.width );
		super.assertTrue( imgInfo.height >= 69 && imgInfo.height <= 71, imgInfo.height );
	}

	function test03_resize_shouldReturnResizedBinaryImage_withSpecifiedHeight_whenNoWidthSpecified() output=false {
		var tmpFile = _tmpFile( "/tests/resources/assetManager/testlandscape.jpg" );

		imageManipulationService.resize(
			  filePath  = tmpFile
			, height    = 200
			, filename  = "testlandscape.jpg"
		);
		var imgInfo = ImageInfo( ImageNew( tmpFile ) );

		FileDelete( tmpFile );

		super.assertEquals( 200, imgInfo.height );
		super.assertTrue( imgInfo.width >= 281 && imgInfo.width <= 283, imgInfo.width );
	}

	function test04_resize_shouldReturnResizedBinaryImage_withSpecifiedHeightAndWidth() output=false {
		var tmpFile = _tmpFile( "/tests/resources/assetManager/testlandscape.jpg" );

		imageManipulationService.resize(
			  filePath  = tmpFile
			, height    = 200
			, width     = 300
			, filename  = "testlandscape.jpg"
		);
		var imgInfo = ImageInfo( ImageNew( tmpFile ) );

		FileDelete( tmpFile );

		super.assertEquals( 200, imgInfo.height );
		super.assertEquals( 300, imgInfo.width );
	}

	function test05_resize_shouldReturnCroppedAndResizedBinaryImage_whenPassedHeightAndWidthThatDoNotMatchAspectRatio_andWhenMaintainAspectRatioIsSetToTrue() output=false {
		var tmpFile = _tmpFile( "/tests/resources/assetManager/testportrait.jpg" );

		imageManipulationService.resize(
			  filePath            = tmpFile
			, height              = 400
			, width               = 400
			, filename            = "testlandscape.jpg"
			, maintainAspectRatio = true
		);
		var imgInfo = ImageInfo( ImageNew( tmpFile ) );

		FileDelete( tmpFile );

		super.assertEquals( 400, imgInfo.height );
		super.assertEquals( 400, imgInfo.width );
	}

	function test06_shrinkToFit_shouldLeaveImageUntouched_whenImageAlreadySmallerThanDimensionsPassed() output=false {
		var tmpFile = _tmpFile( "/tests/resources/assetManager/testportrait.jpg" );
		var imgInfo = ImageInfo( ImageNew( tmpFile ) );

		imageManipulationService.shrinkToFit(
			  filePath  = tmpFile
			, height    = imgInfo.height + 1
			, width     = imgInfo.width + 1
		);

		var newImgInfo  = ImageInfo( ImageNew( tmpFile ) );

		FileDelete( tmpFile );

		super.assertEquals( imgInfo, newImgInfo );
	}

	function test07_shrinkToFit_shouldScaleImageDownByXAxis_whenOnlyWidthIsLargerThanPassedDimensions() output=false {
		var tmpFile = _tmpFile( "/tests/resources/assetManager/testportrait.jpg" );
		var imgInfo = ImageInfo( ImageNew( tmpFile ) );

		imageManipulationService.shrinkToFit(
			  filePath  = tmpFile
			, height    = imgInfo.height + 10
			, width     = imgInfo.width - 10
		);

		var newImgInfo = ImageInfo( ImageNew( tmpFile ) );

		super.assertEquals( imgInfo.width - 10, newImgInfo.width );
		super.assert( newImgInfo.height < imgInfo.height );
	}

	function test08_shrinkToFit_shouldScaleImageDownByYAxis_whenOnlyHeightIsLargerThanPassedDimensions() output=false {
		var tmpFile = _tmpFile( "/tests/resources/assetManager/testportrait.jpg" );
		var imgInfo = ImageInfo( ImageNew( tmpFile ) );

		imageManipulationService.shrinkToFit(
			  filePath  = tmpFile
			, height    = imgInfo.height - 10
			, width     = imgInfo.width + 10
		);

		var newImgInfo = ImageInfo( ImageNew( tmpFile ) );

		super.assertEquals( imgInfo.height - 10, newImgInfo.height );
		super.assert( newImgInfo.width < imgInfo.width );
	}

	function test09_shrinkToFit_shouldScaleImageDownByYAxis_whenBothHeightAndWidthAreLargerThanPassedDimensions_andHeightTransformationWouldReduceWidthToWithinMaxWidth() output=false {
		var tmpFile = _tmpFile( "/tests/resources/assetManager/testportrait.jpg" );
		var imgInfo = ImageInfo( ImageNew( tmpFile ) );

		imageManipulationService.shrinkToFit(
			  filePath  = tmpFile
			, height    = 100
			, width     = 100
			, filename  = "testlandscape.jpg"
		);

		var newImgInfo = ImageInfo( ImageNew( tmpFile ) );

		super.assertEquals( 100, newImgInfo.height );
		super.assert( newImgInfo.width < imgInfo.width && newImgInfo.width < 100 );
	}

	function test10_shrinkToFit_shouldScaleImageDownByXAxis_whenBothHeightAndWidthAreLargerThanPassedDimensions_andWidthTransformationWouldReduceHeightToWithinMaxHeight() output=false {
		var tmpFile = _tmpFile( "/tests/resources/assetManager/testlandscape.jpg" );
		var imgInfo = ImageInfo( ImageNew( tmpFile ) );

		imageManipulationService.shrinkToFit(
			  filePath  = tmpFile
			, height    = 400
			, width     = 400
		);

		var newImgInfo = ImageInfo( ImageNew( tmpFile ) );

		super.assertEquals( 400, newImgInfo.width );
		super.assert( newImgInfo.height < imgInfo.height && newImgInfo.height < 400 );
	}

// helpers
	private string function _tmpFile( required string originalFile ) {
		var tmpFile = GetTempFile( GetTempDirectory(), "" );

		FileCopy( arguments.originalFile, tmpFile );

		return tmpFile;
	}
}