component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "getFieldListingLabel()", function(){
			it( "should return the field label", function(){
				expect( _getService().getFieldListingLabel( { label="Nickname", key="nickname" } ) ).toBe( "Nickname" );
			} );

			it( "should fall back to the field key when label is missing", function(){
				expect( _getService().getFieldListingLabel( { key="nickname" } ) ).toBe( "nickname" );
			} );
		} );

		describe( "getFieldKeyValidationError()", function(){
			it( "should reject reserved keys", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "getIdField" ).$args( "elf_test_object" ).$results( "id" );
				variables.mockPoService.$( "getLabelField" ).$args( "elf_test_object" ).$results( "label" );
				variables.mockPoService.$( "getDateCreatedField" ).$args( "elf_test_object" ).$results( "datecreated" );
				variables.mockPoService.$( "getDateModifiedField" ).$args( "elf_test_object" ).$results( "datemodified" );
				svc.$( "$translateResource", "reserved" );

				expect( Len( svc.getFieldKeyValidationError( "elf_test_object", "id" ) ) ).toBeGT( 0 );
			} );

			it( "should reject malformed keys", function(){
				var svc = _getService();
				svc.$( "$translateResource", "bad format" );

				expect( svc.getFieldKeyValidationError( "elf_test_object", "Bad Key" ) ).toBe( "bad format" );
			} );
		} );

		describe( "objectHasAggregateRelationships()", function(){
			it( "should return true when the object has a one-to-many or many-to-many property", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					gallery = { relationship="many-to-many", relatedTo="asset" }
				} );
				svc.$( "$translatePropertyName", "Gallery" );

				expect( svc.objectHasAggregateRelationships( "elf_test_object" ) ).toBeTrue();
			} );

			it( "should return false when the object has no related collections", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					label = { relationship="none" }
				} );

				expect( svc.objectHasAggregateRelationships( "elf_test_object" ) ).toBeFalse();
			} );
		} );

		describe( "objectHasRelatedDataRelationships()", function(){
			it( "should return true when the object has a many-to-one property", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					logo = { relationship="many-to-one", relatedTo="asset" }
				} );
				svc.$( "$translatePropertyName", "Logo" );

				expect( svc.objectHasRelatedDataRelationships( "elf_test_object" ) ).toBeTrue();
			} );

			it( "should return false when the object has no many-to-one properties", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					gallery = { relationship="many-to-many", relatedTo="asset" }
				} );

				expect( svc.objectHasRelatedDataRelationships( "elf_test_object" ) ).toBeFalse();
			} );
		} );

		describe( "listRelatedDataRelationshipPaths()", function(){
			it( "should include nested many-to-one hops", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset_folder" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					logo = { relationship="many-to-one", relatedTo="asset" }
				} );
				variables.mockPoService.$( "getObjectProperties" ).$args( "asset" ).$results( {
					  title        = { relationship="none", type="string" }
					, asset_folder = { relationship="many-to-one", relatedTo="asset_folder" }
				} );
				variables.mockPoService.$( "getObjectProperties" ).$args( "asset_folder" ).$results( {
					label = { relationship="none", type="string" }
				} );
				svc.$( "$translatePropertyName" ).$args( "elf_test_object", "logo" ).$results( "Logo" );
				svc.$( "$translatePropertyName" ).$args( "asset", "asset_folder" ).$results( "Folder" );

				var paths = svc.listRelatedDataRelationshipPaths( "elf_test_object" );
				var ids   = [];
				for( var path in paths ) {
					ArrayAppend( ids, path.id );
				}

				expect( ids ).toInclude( "logo" );
				expect( ids ).toInclude( "logo.asset_folder" );
			} );
		} );

		describe( "listRelatedDataTreeNodes()", function(){
			it( "should list only many-to-one relationships at the root", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					  label = { relationship="none", type="string" }
					, logo  = { relationship="many-to-one", relatedTo="asset" }
					, gallery = { relationship="many-to-many", relatedTo="asset" }
				} );
				svc.$( "$translatePropertyName" ).$args( "elf_test_object", "logo" ).$results( "Logo" );

				var nodes = svc.listRelatedDataTreeNodes( "elf_test_object" );
				var ids   = [];
				for( var node in nodes ) {
					ArrayAppend( ids, node.id );
				}

				expect( ids ).toInclude( "logo" );
				expect( ids ).notToInclude( "label" );
				expect( ids ).notToInclude( "gallery" );
				expect( nodes[ 1 ].type ).toBe( "relationship" );
				expect( nodes[ 1 ].hasChildren ).toBeTrue();
				expect( nodes[ 1 ].property ).toBe( "logo" );
			} );

			it( "should include fields, custom fields, formula fields and nested many-to-one hops", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset_folder" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					logo = { relationship="many-to-one", relatedTo="asset" }
				} );
				variables.mockPoService.$( "getObjectProperties" ).$args( "asset" ).$results( {
					  title        = { relationship="none", type="string" }
					, nickname     = { relationship="none", type="string", formula="( select shorttext_value from _cfv_pobj_asset where record = ${prefix}id )", customField=true, customFieldLabel="Nickname" }
					, asset_folder = { relationship="many-to-one", relatedTo="asset_folder" }
					, versions     = { relationship="one-to-many", relatedTo="asset_version" }
				} );
				svc.$( "$translatePropertyName" ).$args( "asset", "title" ).$results( "Title" );
				svc.$( "$translatePropertyName" ).$args( "asset", "asset_folder" ).$results( "Folder" );

				var nodes = svc.listRelatedDataTreeNodes( "elf_test_object", "logo" );
				var byId  = {};
				for( var node in nodes ) {
					byId[ node.id ] = node;
				}

				expect( byId ).toHaveKey( "logo.title" );
				expect( byId ).toHaveKey( "logo.nickname" );
				expect( byId ).toHaveKey( "logo.asset_folder" );
				expect( byId ).notToHaveKey( "logo.versions" );
				expect( byId[ "logo.title" ].type ).toBe( "property" );
				expect( byId[ "logo.nickname" ].label ).toBe( "Nickname" );
				expect( byId[ "logo.asset_folder" ].type ).toBe( "relationship" );
				expect( byId[ "logo.asset_folder" ].hasChildren ).toBeTrue();
				expect( byId[ "logo.asset_folder" ].relationshipPath ).toBe( "logo" );
				expect( byId[ "logo.asset_folder" ].property ).toBe( "asset_folder" );
				expect( nodes[ 1 ].type ).toBe( "relationship" );
				expect( nodes[ ArrayLen( nodes ) ].type ).toBe( "property" );
			} );

			it( "should not offer further hops once the maximum depth is reached", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset_folder" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					logo = { relationship="many-to-one", relatedTo="asset" }
				} );
				variables.mockPoService.$( "getObjectProperties" ).$args( "asset" ).$results( {
					asset_folder = { relationship="many-to-one", relatedTo="asset_folder" }
				} );
				variables.mockPoService.$( "getObjectProperties" ).$args( "asset_folder" ).$results( {
					  label         = { relationship="none", type="string" }
					, parent_folder = { relationship="many-to-one", relatedTo="asset_folder" }
				} );
				svc.$( "$translatePropertyName" ).$args( "asset_folder", "label" ).$results( "Label" );
				svc.$( "$translatePropertyName" ).$args( "asset_folder", "parent_folder" ).$results( "Parent folder" );

				var nodes = svc.listRelatedDataTreeNodes(
					  objectName       = "elf_test_object"
					, relationshipPath = "logo.asset_folder.parent_folder"
					, maxHops          = 3
				);
				var byId = {};
				for( var node in nodes ) {
					byId[ node.id ] = node;
				}

				expect( byId ).toHaveKey( "logo.asset_folder.parent_folder.label" );
				expect( byId ).toHaveKey( "logo.asset_folder.parent_folder.parent_folder" );
				expect( byId[ "logo.asset_folder.parent_folder.parent_folder" ].hasChildren ).toBeFalse();
			} );
		} );

		describe( "getRelatedDataSelectionLabel()", function(){
			it( "should join translated relationship hops and the terminal field", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					logo = { relationship="many-to-one", relatedTo="asset" }
				} );
				variables.mockPoService.$( "getObjectProperties" ).$args( "asset" ).$results( {
					title = { relationship="none", type="string" }
				} );
				svc.$( "$translatePropertyName" ).$args( "elf_test_object", "logo" ).$results( "Logo" );
				svc.$( "$translatePropertyName" ).$args( "asset", "title" ).$results( "Title" );

				expect( svc.getRelatedDataSelectionLabel( "elf_test_object", "logo", "title" ) ).toBe( "Logo → Title" );
			} );
		} );

		describe( "resolveRelatedDataPath()", function(){
			it( "should resolve a field on a related record, including formula properties", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					logo = { relationship="many-to-one", relatedTo="asset" }
				} );
				variables.mockPoService.$( "getObjectProperties" ).$args( "asset" ).$results( {
					nickname = { relationship="none", type="string", formula="( select shorttext_value from _cfv_pobj_asset where record = ${prefix}id )", customFieldLabel="Nickname" }
				} );

				var resolved = svc.resolveRelatedDataPath( "elf_test_object", "logo", "nickname" );

				expect( resolved.valid ).toBeTrue();
				expect( resolved.path ).toBe( "logo.nickname" );
				expect( resolved.relatedObject ).toBe( "asset" );
				expect( resolved.formula ).toInclude( "${prefix}id" );
			} );

			it( "should reject a one-to-many collection as the source field", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					logo = { relationship="many-to-one", relatedTo="asset" }
				} );
				variables.mockPoService.$( "getObjectProperties" ).$args( "asset" ).$results( {
					versions = { relationship="one-to-many", relatedTo="asset_version" }
				} );

				expect( svc.resolveRelatedDataPath( "elf_test_object", "logo", "versions" ).valid ).toBeFalse();
			} );
		} );

		describe( "getRelatedObjectForAggregateProperty()", function(){
			it( "should return the relatedTo of the collection property", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "getObjectPropertyAttribute" ).$args(
					  objectName    = "elf_test_object"
					, propertyName  = "gallery"
					, attributeName = "relatedTo"
					, defaultValue  = ""
				).$results( "asset" );

				expect( svc.getRelatedObjectForAggregateProperty( "elf_test_object", "gallery" ) ).toBe( "asset" );
			} );
		} );

		describe( "evaluateConditionalLabels()", function(){
			it( "should return only the first matching rule in single mode", function(){
				var svc = _getConditionalLabelService( "single" );

				expect( svc.evaluateConditionalLabels( "15.record-1" ) ).toBe( [ "rule-1" ] );
				expect( svc.evaluateConditionalLabel( "15.record-1" ) ).toBe( "rule-1" );
			} );

			it( "should return every matching rule in multiple mode", function(){
				var svc = _getConditionalLabelService( "multiple" );

				expect( svc.evaluateConditionalLabels( "15.record-1" ) ).toBe( [ "rule-1", "rule-2" ] );
			} );

			it( "should ignore rules without a condition", function(){
				var svc = _getConditionalLabelService( "multiple" );

				svc.$( "listConditionalRules", [
					  { id="empty", filter="" }
					, { id="rule-1", filter="filter-1" }
				] );

				expect( svc.evaluateConditionalLabels( "15.record-1" ) ).toBe( [ "rule-1" ] );
			} );
		} );

		describe( "buildFormPlacementCatalogueFromSources()", function(){
			it( "should union add and edit tabs with created custom field tabs without duplicating ids", function(){
				var svc = _getService();
				var catalogue = svc.buildFormPlacementCatalogueFromSources(
					  sourceForms = [
						  { tabs=[ { id="basic", title="Basic", fieldsets=[ { id="details", title="Details" } ] } ] }
						, { tabs=[
							  { id="basic", title="Basic", fieldsets=[ { id="details", title="Details" }, { id="extra", title="Extra" } ] }
							, { id="notes", title="Notes", fieldsets=[ { id="notes", title="Notes" } ] }
						  ] }
					  ]
					, fields = [
						  { form_placement="manual", form_tab="cf_billing", form_tab_label="Billing", form_fieldset="cf_main", form_fieldset_label="Main", sort_order=10, label="A" }
						, { form_placement="manual", form_tab="cf_billing", form_tab_label="Other", form_fieldset="cf_main", form_fieldset_label="Other set", sort_order=20, label="B" }
						, { form_placement="auto", sort_order=1, label="Auto" }
					  ]
				);
				var ids     = [];
				var basic   = {};
				var billing = {};

				for( var tab in catalogue ) {
					ArrayAppend( ids, tab.id );
					if ( tab.id == "basic" ) {
						basic = tab;
					}
					if ( tab.id == "cf_billing" ) {
						billing = tab;
					}
				}

				expect( ArrayLen( ids ) ).toBe( 3 );
				expect( ArrayLen( basic.fieldsets ) ).toBe( 2 );
				expect( billing.label ).toBe( "Billing" );
				expect( billing.created ).toBeTrue();
				expect( ArrayLen( billing.fieldsets ) ).toBe( 1 );
				expect( billing.fieldsets[ 1 ].label ).toBe( "Main" );
			} );
		} );

		describe( "prepareFormPlacement()", function(){
			it( "should clear placement when automatic and slug new tabs without colliding", function(){
				var svc = _getService();
				var catalogue = [
					  { id="basic", label="Basic", created=false, fieldsets=[ { id="details", label="Details", created=false } ] }
					, { id="cf_billing", label="Billing", created=true, fieldsets=[ { id="cf_main", label="Main", created=true } ] }
				];
				var automatic = svc.prepareFormPlacement(
					  formData  = { form_placement="auto", include_in_add_form=false, include_in_edit_form=true }
					, catalogue = catalogue
				);
				var created = svc.prepareFormPlacement(
					  formData  = { form_placement="manual", form_tab="__new__", form_tab_label="Billing", form_fieldset="__new__", form_fieldset_label="Main", include_in_add_form=true, include_in_edit_form=true, form_required=1 }
					, catalogue = catalogue
				);
				var existing = svc.prepareFormPlacement(
					  formData  = { form_placement="manual", form_tab="basic", form_fieldset="details", include_in_add_form=true, include_in_edit_form=true }
					, catalogue = catalogue
				);
				var createdExisting = svc.prepareFormPlacement(
					  formData  = { form_placement="manual", form_tab="cf_billing", form_fieldset="cf_main", include_in_add_form=true, include_in_edit_form=true }
					, catalogue = catalogue
				);
				var missing = svc.prepareFormPlacement(
					  formData  = { form_placement="manual", form_tab="nope", form_fieldset="details", include_in_add_form=true, include_in_edit_form=true }
					, catalogue = catalogue
				);

				expect( automatic.form_tab ).toBe( "" );
				expect( automatic.include_in_add_form ).toBeFalse();
				expect( automatic.include_in_edit_form ).toBeTrue();
				expect( automatic.form_required ).toBeFalse();
				expect( created.form_tab ).toBe( "cf_billing_2" );
				expect( created.form_required ).toBeTrue();
				expect( created.form_tab_label ).toBe( "Billing" );
				expect( created.form_fieldset ).toBe( "cf_main" );
				expect( existing.form_tab_label ).toBe( "" );
				expect( existing.form_fieldset_label ).toBe( "" );
				expect( createdExisting.form_tab_label ).toBe( "Billing" );
				expect( createdExisting.form_fieldset_label ).toBe( "Main" );
				expect( missing.error ).toBe( "customFields:formPlacement.validation.tab" );
			} );
		} );

		describe( "filterFieldsForRecordForm()", function(){
			it( "should keep static fields included on the requested form and default missing flags to included", function(){
				var svc = _getService();
				var editFields = svc.filterFieldsForRecordForm(
					  fields = [
						  { key="add_only", kind="static", include_in_add_form=true, include_in_edit_form=false }
						, { key="edit_only", kind="static", include_in_add_form=false, include_in_edit_form=true }
						, { key="aggregate", kind="aggregate", include_in_add_form=true, include_in_edit_form=true }
						, { key="unset", kind="static" }
					  ]
					, operation = "edit"
				);
				var keys = [];

				for( var field in editFields ) {
					ArrayAppend( keys, field.key );
				}

				expect( keys ).toBe( [ "edit_only", "unset" ] );
			} );
		} );

		describe( "buildRecordFormDefinition()", function(){
			it( "should put automatic fields on the custom fields tab and manual fields on the chosen or created tab", function(){
				var svc = _getService();
				var definition = "";
				var customTab  = {};
				var basicTab   = {};
				var billingTab = {};

				variables.mockTypesService.$( "getType", { control="textinput" } );

				definition = svc.buildRecordFormDefinition( [
					  { key="nickname", label="Nickname", data_type="text", sort_order=5, form_placement="auto", kind="static" }
					, { key="website", label="Website", data_type="text", sort_order=8, form_placement="manual", form_tab="basic", form_fieldset="details", kind="static" }
					, { key="po_number", label="PO number", data_type="text", sort_order=3, form_placement="manual", form_tab="cf_billing", form_tab_label="Billing", form_fieldset="cf_main", form_fieldset_label="Main", kind="static" }
				] );

				for( var tab in definition.tabs ) {
					if ( tab.id == "customFields" ) {
						customTab = tab;
					}
					if ( tab.id == "basic" ) {
						basicTab = tab;
					}
					if ( tab.id == "cf_billing" ) {
						billingTab = tab;
					}
				}

				expect( customTab.title ).toBe( "customFields:formtab.customFields.title" );
				expect( customTab.fieldsets[ 1 ].fields[ 1 ].name ).toBe( "nickname" );
				expect( customTab.fieldsets[ 1 ].fields[ 1 ].label ).toBe( "Nickname" );
				expect( customTab.fieldsets[ 1 ].fields[ 1 ].required ).toBeFalse();
				expect( basicTab.fieldsets[ 1 ].fields[ 1 ].name ).toBe( "website" );
				expect( Val( basicTab.sortorder ?: basicTab.sortOrder ?: 0 ) ).toBe( 0 );
				expect( billingTab.title ).toBe( "Billing" );
				expect( Val( billingTab.sortorder ?: billingTab.sortOrder ?: 0 ) ).toBe( 1000000000 );
				expect( Val( customTab.sortorder ?: customTab.sortOrder ?: 0 ) ).toBeGT( 999999999 );
				expect( billingTab.fieldsets[ 1 ].fields[ 1 ].name ).toBe( "po_number" );
				expect( billingTab.fieldsets[ 1 ].title ).toBe( "Main" );
			} );

			it( "should place automatic fields for a custom object on the general tab after the label", function(){
				var svc        = _getService();
				var definition = "";
				var generalTab = {};
				var tabIds     = [];

				variables.mockTypesService.$( "getType", { control="textinput" } );

				definition = svc.buildRecordFormDefinition( [
					  { key="store_note", label="Store note", data_type="text", sort_order=5, form_placement="auto", kind="static", target_object="cobj_e2e_store_oct7", form_required=true }
					, { key="website", label="Website", data_type="text", sort_order=8, form_placement="manual", form_tab="basic", form_fieldset="details", kind="static", target_object="cobj_e2e_store_oct7" }
				] );

				for ( var tab in definition.tabs ) {
					ArrayAppend( tabIds, tab.id );
					if ( tab.id == "default" ) {
						generalTab = tab;
					}
				}

				expect( tabIds ).notToInclude( "customFields" );
				expect( generalTab.fieldsets[ 1 ].fields[ 1 ].name ).toBe( "store_note" );
				expect( Val( generalTab.fieldsets[ 1 ].fields[ 1 ].sortOrder ) ).toBe( 1000000005 );
				expect( generalTab.fieldsets[ 1 ].fields[ 1 ].required ).toBeTrue();
			} );

			it( "should offer a multiple object picker when a related record allows more than one", function(){
				var svc        = _getService();
				var definition = "";
				var field      = {};

				variables.mockTypesService.$( "getType", { control="objectPicker" } );

				definition = svc.buildRecordFormDefinition( [
					{ key="related_record", label="Related record", data_type="object_ref", related_object="cobj_e2e_store_oct7", related_multiple=true, form_placement="auto", kind="static" }
				] );
				field = definition.tabs[ 1 ].fieldsets[ 1 ].fields[ 1 ];

				expect( field.control ).toBe( "objectPicker" );
				expect( field.object ).toBe( "cobj_e2e_store_oct7" );
				expect( field.multiple ).toBeTrue();
			} );
		} );

		describe( "deletion confirmation", function(){
			it( "should match the field label exactly, ignoring surrounding spaces", function(){
				var svc   = _getService();
				var field = { label="Newsletter opt in", key="newsletter_opt_in", kind="static" };

				expect( svc.getDeletionConfirmationName( field ) ).toBe( "Newsletter opt in" );
				expect( svc.deletionConfirmationMatches( field, "Newsletter opt in" ) ).toBeTrue();
				expect( svc.deletionConfirmationMatches( field, "  Newsletter opt in  " ) ).toBeTrue();
				expect( svc.deletionConfirmationMatches( field, "newsletter opt in" ) ).toBeFalse();
			} );

			it( "should fall back to the field key when the label is empty", function(){
				var svc = _getService();

				expect( svc.getDeletionConfirmationName( { label="", key="joined_on" } ) ).toBe( "joined_on" );
			} );

			it( "should count stored values only for static fields", function(){
				var svc = _getService();

				variables.mockValueTables.$( "valueObjectExists", true );
				variables.mockValueTables.$( "getValueObjectName", "_cfv_crm_contact" );
				variables.mockPoService.$( "selectData", 3 );

				expect( svc.countStoredValues( { id=19, kind="aggregate", target_object="crm_contact" } ) ).toBe( 0 );
				expect( svc.countStoredValues( { id=19, kind="static", target_object="crm_contact" } ) ).toBe( 3 );
			} );
		} );
	}

	private any function _getConditionalLabelService( required string mode ) {
		var svc = _getService();

		svc.$( "getField", {
			  id                     = "15"
			, kind                   = "conditional_label"
			, target_object          = "elf_test_object"
			, conditional_label_mode = arguments.mode
		} );
		svc.$( "listConditionalRules", [
			  { id="rule-1", filter="filter-1" }
			, { id="rule-2", filter="filter-2" }
		] );
		variables.mockFilterService.$( method="prepareFilter", callback=function( required string objectName, required string filterId ){
			return { filter=arguments.filterId };
		} );
		variables.mockPoService.$( method="dataExists", callback=function(){
			return true;
		} );

		return svc;
	}

	private any function _getService() {
		var svc     = CreateMock( object=new preside.system.services.customFields.CustomFieldsService() );
		var helpers = createStub();

		variables.mockPoService      = createStub();
		variables.mockTypesService   = createStub();
		variables.mockInjector       = createStub();
		variables.mockValueTables    = createStub();
		variables.mockFormsService   = createStub();
		variables.mockEnumService    = createStub();
		variables.mockFilterService  = createStub();

		helpers.$( method="isTrue", callback=function( val ){
			return IsBoolean( arguments.val ?: "" ) && arguments.val;
		} );

		svc.$( "$isFeatureEnabled", true );
		svc.$( "$translateResource", "" );

		svc.$property( propertyName="presideObjectService"         , mock=variables.mockPoService );
		svc.$property( propertyName="customFieldTypesService"      , mock=variables.mockTypesService );
		svc.$property( propertyName="customFieldsPropertyInjector" , mock=variables.mockInjector );
		svc.$property( propertyName="customFieldsValueTableService", mock=variables.mockValueTables );
		svc.$property( propertyName="formsService"                 , mock=variables.mockFormsService );
		svc.$property( propertyName="enumService"                  , mock=variables.mockEnumService );
		svc.$property( propertyName="rulesEngineFilterService"     , mock=variables.mockFilterService );
		svc.$property( propertyName="$helpers"                     , mock=helpers );

		return svc;
	}

}
