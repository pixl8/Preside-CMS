component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP, TEARDOWN, ETC.
	function setup() {
		super.setup();

		mockNativeImageImplementation = getMockBox().createMock( "preside.system.services.assetManager.NativeImageService" );
		mockImageMagickImplementation = getMockBox().createMock("preside.system.services.assetManager.imageMagickService");
		imageManipulationService  = getMockBox().createMock("preside.system.services.assetManager.imageManipulationService");

		mockImageMagickImplementation.init("",30);

		imageManipulationService.$( "$getPresideCategorySettings", {
			  retrieve_metadata     = false
			, use_imagemagick       = false
			, imagemagick_path      = ""
			, imagemagick_timeout   = 30
			, imagemagick_interlace = false
		} );
		imageManipulationService.$( "$getPresideSetting" ).$args( "asset-manager", "use_imagemagick" ).$results( false );

		imageManipulationService = imageManipulationService.init( mockNativeImageImplementation,mockImageMagickImplementation );
	}

// TESTS
	function test01_resize_shouldThrowAnInformativeError_whenPassedAssetIsNotAnImage() output=false {
		var errorThrown = false;
		var assetBinary = FileReadBinary( "/tests/resources/assetManager/testfile.txt" );

		try {
			imageManipulationService.resize(
				  asset     = assetBinary
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
		var assetBinary = FileReadBinary( "/tests/resources/assetManager/testlandscape.jpg" );
		var resized     = imageManipulationService.resize(
			  asset     = assetBinary
			, width     = 100
			, filename  = "testlandscape.jpg"
		);
		var imgInfo     = ImageInfo( ImageNew( resized ) );

		super.assertEquals( 100, imgInfo.width );
		super.assertTrue( imgInfo.height >= 69 && imgInfo.height <= 71, imgInfo.height );
	}

	function test03_resize_shouldReturnResizedBinaryImage_withSpecifiedHeight_whenNoWidthSpecified() output=false {
		var assetBinary = FileReadBinary( "/tests/resources/assetManager/testlandscape.jpg" );
		var resized     = imageManipulationService.resize(
			  asset     = assetBinary
			, height    = 200
			, filename  = "testlandscape.jpg"
		);
		var imgInfo     = ImageInfo( ImageNew( resized ) );

		super.assertEquals( 200, imgInfo.height );
		super.assertTrue( imgInfo.width >= 281 && imgInfo.width <= 283, imgInfo.width );
	}

	function test04_resize_shouldReturnResizedBinaryImage_withSpecifiedHeightAndWidth() output=false {
		var assetBinary = FileReadBinary( "/tests/resources/assetManager/testlandscape.jpg" );
		var resized     = imageManipulationService.resize(
			  asset     = assetBinary
			, height    = 200
			, width     = 300
			, filename  = "testlandscape.jpg"
		);
		var imgInfo     = ImageInfo( ImageNew( resized ) );

		super.assertEquals( 200, imgInfo.height );
		super.assertEquals( 300, imgInfo.width );
	}

	function test05_resize_shouldReturnCroppedAndResizedBinaryImage_whenPassedHeightAndWidthThatDoNotMatchAspectRatio_andWhenMaintainAspectRatioIsSetToTrue() output=false {
		var assetBinary = FileReadBinary( "/tests/resources/assetManager/testportrait.jpg" );
		var resized     = imageManipulationService.resize(
			  asset               = assetBinary
			, height              = 400
			, width               = 400
			, filename            = "testlandscape.jpg"
			, maintainAspectRatio = true
		);
		var imgInfo     = ImageInfo( ImageNew( resized ) );

		super.assertEquals( 400, imgInfo.height );
		super.assertEquals( 400, imgInfo.width );
	}

	function test06_shrinkToFit_shouldLeaveImageUntouched_whenImageAlreadySmallerThanDimensionsPassed() output=false {
		var assetBinary = FileReadBinary( "/tests/resources/assetManager/testportrait.jpg" );
		var imgInfo     = ImageInfo( ImageNew( assetBinary ) );
		var resized     = imageManipulationService.shrinkToFit(
			  asset     = assetBinary
			, height    = imgInfo.height + 1
			, width     = imgInfo.width + 1
			, filename  = "testlandscape.jpg"
		);
		var newImgInfo  = ImageInfo( ImageNew( resized ) );

		super.assertEquals( imgInfo, newImgInfo );
	}

	function test07_shrinkToFit_shouldScaleImageDownByXAxis_whenOnlyWidthIsLargerThanPassedDimensions() output=false {
		var assetBinary = FileReadBinary( "/tests/resources/assetManager/testportrait.jpg" );
		var imgInfo     = ImageInfo( ImageNew( assetBinary ) );
		var resized     = imageManipulationService.shrinkToFit(
			  asset     = assetBinary
			, height    = imgInfo.height + 10
			, width     = imgInfo.width - 10
			, filename  = "testlandscape.jpg"
		);
		var newImgInfo  = ImageInfo( ImageNew( resized ) );

		super.assertEquals( imgInfo.width - 10, newImgInfo.width );
		super.assert( newImgInfo.height < imgInfo.height );
	}

	function test08_shrinkToFit_shouldScaleImageDownByYAxis_whenOnlyHeightIsLargerThanPassedDimensions() output=false {
		var assetBinary = FileReadBinary( "/tests/resources/assetManager/testportrait.jpg" );
		var imgInfo     = ImageInfo( ImageNew( assetBinary ) );
		var resized     = imageManipulationService.shrinkToFit(
			  asset     = assetBinary
			, height    = imgInfo.height - 10
			, width     = imgInfo.width + 10
			, filename  = "testlandscape.jpg"
		);
		var newImgInfo  = ImageInfo( ImageNew( resized ) );

		super.assertEquals( imgInfo.height - 10, newImgInfo.height );
		super.assert( newImgInfo.width < imgInfo.width );
	}

	function test09_shrinkToFit_shouldScaleImageDownByYAxis_whenBothHeightAndWidthAreLargerThanPassedDimensions_andHeightTransformationWouldReduceWidthToWithinMaxWidth() output=false {
		var assetBinary = FileReadBinary( "/tests/resources/assetManager/testportrait.jpg" );
		var imgInfo     = ImageInfo( ImageNew( assetBinary ) );
		var resized     = imageManipulationService.shrinkToFit(
			  asset     = assetBinary
			, height    = 100
			, width     = 100
			, filename  = "testlandscape.jpg"
		);
		var newImgInfo  = ImageInfo( ImageNew( resized ) );

		super.assertEquals( 100, newImgInfo.height );
		super.assert( newImgInfo.width < imgInfo.width && newImgInfo.width < 100 );
	}

	function test10_shrinkToFit_shouldScaleImageDownByXAxis_whenBothHeightAndWidthAreLargerThanPassedDimensions_andWidthTransformationWouldReduceHeightToWithinMaxHeight() output=false {
		var assetBinary = FileReadBinary( "/tests/resources/assetManager/testlandscape.jpg" );
		var imgInfo     = ImageInfo( ImageNew( assetBinary ) );
		var resized     = imageManipulationService.shrinkToFit(
			  asset     = assetBinary
			, height    = 400
			, width     = 400
			, filename  = "testlandscape.jpg"
		);
		var newImgInfo  = ImageInfo( ImageNew( resized ) );

		super.assertEquals( 400, newImgInfo.width );
		super.assert( newImgInfo.height < imgInfo.height && newImgInfo.height < 400 );
	}
}