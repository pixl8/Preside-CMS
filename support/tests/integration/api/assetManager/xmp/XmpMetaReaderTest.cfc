component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "readMeta()", function(){

			it( "should read XMP metadata from an image file that has embedded XMP meta", function(){
				var reader = new preside.system.services.assetManager.xmp.XmpMetaReader();
				var testFile = FileReadBinary( "/resources/assetManager/xmptest.jpg" );
				var expectedMeta = {
					"CreateDate"                   = "2014-02-11T15:17:58Z",
					"LegacyIPTCDigest"             = "FCE11F89C8B7C9782F346234075877EB",
					"History/stEvt:changed"        = "/",
					"History/stEvt:action"         = "saved",
					"InstanceID"                   = "xmp.iid:2acdfeb1-9552-ad41-b064-3f84568a09cf",
					"DerivedFrom/stRef:instanceID" = "xmp.iid:0eaf65f6-69a0-d040-89ac-2e328de4bcf2",
					"CreatorTool"                  = "Adobe Photoshop Lightroom 5.0 (Windows)",
					"History/stEvt:softwareAgent"  = "Adobe Photoshop CC (Windows)",
					"ColorMode"                    = "3",
					"MetadataDate"                 = "2014-05-08T12:15:32+01:00",
					"OriginalDocumentID"           = "1F3F278841660447490FAA7DA6619C2C",
					"ModifyDate"                   = "2014-05-08T12:15:32+01:00",
					"DocumentID"                   = "xmp.did:B08AED6E932F11E3983EBEB18EBCE0CA",
					"History/stEvt:when"           = "2014-05-08T12:15:32+01:00",
					"History/stEvt:instanceID"     = "xmp.iid:2acdfeb1-9552-ad41-b064-3f84568a09cf",
					"DerivedFrom/stRef:documentID" = "xmp.did:0eaf65f6-69a0-d040-89ac-2e328de4bcf2",
					"format"                       = "image/jpeg"
				};

				expect( reader.readMeta( testFile ) ).toBe( expectedMeta );
			} );

			it( "should return an empty structure when the file has no XMP data embedded", function(){
				var reader = new preside.system.services.assetManager.xmp.XmpMetaReader();
				var testFile = FileReadBinary( "/resources/assetManager/testlandscape.jpg" );

				expect( reader.readMeta( testFile ) ).toBe( {} );
			} );

			it( "should return an empty structure when the file is not an image", function(){
				var reader = new preside.system.services.assetManager.xmp.XmpMetaReader();
				var testFile = FileReadBinary( "/resources/assetManager/testfile.txt" );

				expect( reader.readMeta( testFile ) ).toBe( {} );
			} );

		} );
	}

}