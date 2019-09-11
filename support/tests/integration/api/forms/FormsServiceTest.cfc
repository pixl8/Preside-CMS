component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run(){
		describe( "init()", function(){

			it( "should throw informative error when form field binding is malforrmed", function(){
				var errorThrown = false;

				try {
					_getFormsService( "/tests/resources/formsService/malformedBinding" );
				} catch ( "FormsService.MalformedBinding" e ) {
					expect( e.message ).toBe( "The binding [malformed] was malformed. Bindings should take the form, [presideObjectName.fieldName]" );
					errorThrown = true;
				}

				expect( errorThrown ).toBeTrue();
			} );

			it( "should do nothing when object referred to in binding does not exist", function(){
				var formsService = _getFormsService( "/tests/resources/formsService/bindingWithMissingObject" );
				var theForm      = formsService.getForm( "missing" );

				expect( theForm.tabs[1].fieldsets[1].fields[2].name ?: "" ).toBe( "id" );
			} );

			it( "should do nothing when field referred to in binding does not exist", function(){
				var formsService = _getFormsService( "/tests/resources/formsService/bindingWithMissingField" );
				var theForm      = formsService.getForm( "missing.field" );

				expect( theForm.tabs[1].fieldsets[1].fields[2].name ?: "" ).toBe( "missingField" );
			} );

		} );

		describe( "formExists()", function(){

			it( "should return true when passed form ID that maps to the file name of a form in the configured directories", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/forms1" );

				expect( formsSvc.formExists( "test.form" ) ).toBeTrue();
			} );

			it( "should return false when passed a form ID that does not map to any forms in the configured directories", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/forms1" );

				expect( formsSvc.formExists( "test.form.that.does.not.exist" ) ).toBeFalse();
			} );

			it( "should return true when the form exists in one of many folders", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/forms1,/tests/resources/formsService/forms2,/tests/resources/formsService/forms3,/tests/resources/formsService/forms4" );

				expect( formsSvc.formExists( "test.form.unique.to.set3" ) ).toBeTrue();
			} );

			it( "should return true when form exists in many of many folders", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/forms1,/tests/resources/formsService/forms2,/tests/resources/formsService/forms3,/tests/resources/formsService/forms4" );

				expect( formsSvc.formExists( "test.form" ) ).toBeTrue();
			} );

			it( "should return false when form does not exst in any of many folders", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/forms1,/tests/resources/formsService/forms2,/tests/resources/formsService/forms3,/tests/resources/formsService/forms4" );

				expect( formsSvc.formExists( "test.form.that.does.not.exist" ) ).toBeFalse();
			} );

		} );

		describe( "getForm()", function(){

			it( "should return structure of form definition as defined in XML", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/forms1" );
				var result   = formsSvc.getForm( "test.form" );
				var expected = {
					tabs = [{
						title="{forms:tab1.title}",
						description="{forms:tab1.description}",
						id="",
						fieldsets=[{
							title="",
							description="",
							id="",
							fields=[{
								name="somefield1", control="testcontrol", required="true", maxLength="50", label="{forms:some.field.label}", hint="{forms.some.field.hint}", rules=[]
							},{
								name="somefield2", control="spinner", step="2", minValue="0", maxValue="10", required="false", label="{forms:some.field2.label}", hint="{forms.some.field2.hint}", rules=[]
							}]
						}]

					},{
						title="{forms:tab2.title}",
						description="{forms:tab2.description}",
						id="",
						fieldsets=[{
							title="{test:test.fieldset.title}",
							description="",
							id="",
							fields=[{
								name="somefield3", control="spinner", step="3", minValue="0", maxValue="10", required="false", label="{forms:some.field3.label}", hint="{forms.some.field3.hint}", rules=[]
							}]
						},{
							title="{test:test.fieldset2.title}",
							description="{test:test.fieldset2.description}",
							id="",
							fields=[{
								name="somefield4", control="spinner", step="5", minValue="0", maxValue="100", required="false", default="10", rules=[
									  { validator="required", serverCondition="${somefield3} gt 10", clientCondition="${somefield3}.val() > 10", params={} }
									, { validator="sameAs", params={field="somefield1"} }
								]
							}]
						}]
					}]
				};

				expect( result ).toBe( expected );
			} );

			it( "should return default form for preside object when form does not exist and first part of form name is a valid preside object", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/forms1" );
				var result   = formsSvc.getForm( "preside-objects.security_group.add.form" );
				var expected = {
					tabs = [{
						id="default",
						title="preside-objects.security_group:tab.default.title",
						description="preside-objects.security_group:tab.default.description",
						iconClass="preside-objects.security_group:tab.default.iconClass",
						autoGeneratedAttributes=["title","description","iconClass"],
						fieldsets=[{
							id="default",
							title="preside-objects.security_group:fieldset.default.title",
							description="preside-objects.security_group:fieldset.default.description",
							autoGeneratedAttributes=["title","description"],
							fields=[{
								name="label", control="textinput", type="string", dbtype="varchar", maxLength="250", uniqueindexes="role_name", relationship="none", relatedTo="none", generator="none", generate="never", required="true", sourceObject="security_group", label="preside-objects.security_group:field.label.title", help="preside-objects.security_group:field.label.help", placeholder="preside-objects.security_group:field.label.placeholder", sortorder=10
							},{
								name="description", control="default", type="string", dbtype="varchar", maxLength="200", required="false", relationship="none", relatedTo="none", generator="none", generate="never", sourceObject="security_group", label="preside-objects.security_group:field.description.title", help="preside-objects.security_group:field.description.help", placeholder="preside-objects.security_group:field.description.placeholder", sortorder=20
							},{
								name="users", adminrenderer="objectRelatedRecordsList", control="default", dbtype="none", generate="never", generator="none", help="preside-objects.security_group:field.users.help", label="preside-objects.security_group:field.users.title", maxlength="0", placeholder="preside-objects.security_group:field.users.placeholder", relatedto="security_user", relatedvia="security_group__join__security_user", relatedviasourcefk="security_group", relatedviatargetfk="security_user", relationship="many-to-many", relationshipissource=true , required=false , sortorder=30 , sourceobject="security_group", type="string"
							},{
								name="roles", control="rolepicker", multiple="true", type="string", dbtype="varchar", maxLength="1000", relationship="none", relatedTo="none", generator="none", generate="never", required="false", sourceObject="security_group", label="preside-objects.security_group:field.roles.title", help="preside-objects.security_group:field.roles.help", placeholder="preside-objects.security_group:field.roles.placeholder", sortorder=40, renderer="adminGroupRoles"
							}]
						}]
					}]
				};

				expect( result ).toBe( expected );
			} );

			it( "should throw informative error when form does not exist", function(){
				var formsSvc    = _getFormsService( "/tests/resources/formsService/forms1" );
				var errorThrown = false;

				try {
					formsSvc.getForm( "someform.that.does.not.exist" );
				} catch( "FormsService.MissingForm" e ) {
					expect( e.message, "The form, [someform.that.does.not.exist], could not be found" );
					errorThrown = true;
				} catch( any e ) {
					fail( "The wrong kind of error was thrown. Expected [FormsService.MissingForm], but received, [#e.type#]")
				}

				expect( errorThrown ).toBeTrue();
			} );

			it( "should return a merged form definition when the given form name is defined in two or more of the base source folders", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/automerging/folder1,/tests/resources/formsService/automerging/folder2" );
				var result   = formsSvc.getForm( "someForm" );
				var expected = {
					tabs = [{
						title="A new title",
						description="",
						id = "sometab",
						fieldsets=[{
							title="Another new title",
							description="A description",
							id="somefieldset",
							fields=[
								{ name="anotherfield", rules=[], sortorder=5 },
								{ name="somename", control="overridenControl", required="false", rules=[], sortorder=10 }
							]
						},{
							title="",
							description="",
							id="",
							fields=[
								{ name="meh", required=false, rules=[] }
							]
						},{
							title="",
							description="",
							id="",
							fields=[
								{ name="meh2", blah="blah", rules=[] }
							]
						}]

					},{
						title="",
						description="",
						id = "",
						fieldsets=[{
							title="",
							description="",
							id="",
							fields=[
								{ name="mehsomemore", required="false", rules=[] }
							]
						}]
					},{
						title="",
						description="",
						id = "",
						fieldsets=[{
							title="",
							description="",
							id="",
							fields=[
								{ name="intab3", required="false", rules=[] }
							]
						}]
					}]
				};

				expect( result ).toBe( expected );
			} );

			it( "should NOT return a merged form when the extra definition is defined in a site template that is not active for the request", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/forms1,/tests/resources/formsService/site-templates/mysite/forms" );
				var result   = formsSvc.getForm( "test.form" );
				var expected = {
					tabs = [{
						title="{forms:tab1.title}",
						description="{forms:tab1.description}",
						id="",
						fieldsets=[{
							title="",
							description="",
							id="",
							fields=[{
								name="somefield1", control="testcontrol", required="true", maxLength="50", label="{forms:some.field.label}", hint="{forms.some.field.hint}", rules=[]
							},{
								name="somefield2", control="spinner", step="2", minValue="0", maxValue="10", required="false", label="{forms:some.field2.label}", hint="{forms.some.field2.hint}", rules=[]
							}]
						}]

					},{
						title="{forms:tab2.title}",
						description="{forms:tab2.description}",
						id="",
						fieldsets=[{
							title="{test:test.fieldset.title}",
							description="",
							id="",
							fields=[{
								name="somefield3", control="spinner", step="3", minValue="0", maxValue="10", required="false", label="{forms:some.field3.label}", hint="{forms.some.field3.hint}", rules=[]
							}]
						},{
							title="{test:test.fieldset2.title}",
							description="{test:test.fieldset2.description}",
							id="",
							fields=[{
								name="somefield4", control="spinner", step="5", minValue="0", maxValue="100", required="false", default="10", rules=[
									  { validator="required", serverCondition="${somefield3} gt 10", clientCondition="${somefield3}.val() > 10", params={} }
									, { validator="sameAs", params={field="somefield1"} }
								]
							}]
						}]
					}]
				};

				expect( result ).toBe( expected );
			} );

			it( "should return a merged form when extra definition defined in a site template that is active for the request", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/forms1,/tests/resources/formsService/site-templates/mysite/forms", "mysite" );
				var result   = formsSvc.getForm( "test.form" );
				var expected = {
					tabs = [{
						title="{forms:tab1.title}",
						description="{forms:tab1.description}",
						id="",
						fieldsets=[{
							title="",
							description="",
							id="",
							fields=[{
								name="somefield1", control="testcontrol", required="true", maxLength="50", label="{forms:some.field.label}", hint="{forms.some.field.hint}", rules=[]
							},{
								name="somefield2", control="spinner", step="2", minValue="0", maxValue="10", required="false", label="{forms:some.field2.label}", hint="{forms.some.field2.hint}", rules=[]
							}]
						}]

					},{
						title="{forms:tab2.title}",
						description="{forms:tab2.description}",
						id="",
						fieldsets=[{
							title="{test:test.fieldset.title}",
							description="",
							id="",
							fields=[{
								name="somefield3", control="spinner", step="3", minValue="0", maxValue="10", required="false", label="{forms:some.field3.label}", hint="{forms.some.field3.hint}", rules=[]
							}]
						},{
							title="{test:test.fieldset2.title}",
							description="{test:test.fieldset2.description}",
							id="",
							fields=[{
								name="somefield4", control="spinner", step="5", minValue="0", maxValue="100", required="false", default="10", rules=[
									  { validator="required", serverCondition="${somefield3} gt 10", clientCondition="${somefield3}.val() > 10", params={} }
									, { validator="sameAs", params={field="somefield1"} }
								]
							}]
						}]
					},{
						title="",
						description="",
						id="",
						fieldsets=[{
							title="",
							description="",
							id="",
							fields=[{ name="test", rules=[] }]
						}]

					}]
				};

				result = formsSvc.getForm( "test.form" );

				expect( result ).toBe( expected );
			} );

			it( "should return the struct _minus_ any fields, tabs or fieldsets that the currently logged in admin user does not have access to when 'stripPermissionedFields' is passed as true", function(){
				var formsSvc        = _getFormsService( "/tests/resources/formsService/forms1" );
				var stripped        = { tabs=[] };
				var permContext     = CreateUUId();
				var permContextKeys = [ CreateUUId() ];
				var formName        = "test.form";
				var realDefinition  = formsSvc.getForm( formName );

				formsSvc.$( "removePermissionedFieldsFromFormDefinition" ).$args(
					  formDefinition        = realDefinition
					, permissionContext     = permContext
					, permissionContextKeys = permContextKeys
				).$results( stripped );

				expect( formsSvc.getForm(
					  formName                = formName
					, stripPermissionedFields = true
					, permissionContext       = permContext
					, permissionContextKeys   = permContextKeys
				) ).toBe( stripped );
			} );

			it( "should return a merged form when requested form has an 'extends' definition for another valid form", function(){
				var formsSvc   = _getFormsService( "/tests/resources/formsService/extending" );
				var definition = formsSvc.getForm( "form1" );

				expect( definition ).toBe( {
					  extends = "form2"
					, tabs    = [{
						  id          = "tab1"
						, title       = ""
						, description = ""
						, fieldsets   = [{
							  id          = "fieldset1"
							, title       = ""
							, description = ""
							, fields      = [
								  { name="field1", rules=[] }
								, { name="testfield", rules=[] }
							  ]
						  },{
							  id          = "fieldset6"
							, title       = ""
							, description = ""
							, fields      = [
								{ name="testfield2", rules=[] }
							  ]
						  }]
					  },{
						  id          = "tab3"
						, title       = ""
						, description = ""
						, fieldsets   = [{
							  id          = "fieldset5"
							, title       = ""
							, description = ""
							, fields      = [
								{ name="anothertestfield", rules=[] }
							  ]
						  }]
					  }]
				} );
			} );

		} );

		describe( "readForm()", function(){

			it( "should throw informative error when form definition file contains malformed XML", function(){
				var errorThrown = false;

				try {
					_getFormsService( "/tests/resources/formsService/forms1,/tests/resources/formsService/forms3,/tests/resources/formsService/badForm" );
				} catch ( "FormsService.BadFormXml" e ) {
					expect( e.message ).toBe( "The form definition file, [bad.form.xml], does not contain valid XML" );
					expect( e.detail ).toBe( "XML document structures must start and end within the same entity." );
					errorThrown = true;
				}

				expect( errorThrown ).toBeTrue();
			} );


			it( "should merge field definitions from preside object fields when form fields specify object bindings, form field definitions taking precidence over imported attributes" , function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/forms1,/tests/resources/formsService/forms2,/tests/resources/formsService/forms3,/tests/resources/formsService/forms4" );
				var result   = formsSvc.getForm( "event.cms.add" );
				var expected = {
					feature = "enabled-feature",
					tabs = [{
						title       = "",
						description = "",
						id="",
						fieldsets   = [{
							title       = "",
							description = "",
							id          = "",
							fields      = [ {
								  name         = "known_as"
								, type         = "string"
								, dbtype       = "varchar"
								, maxLength    = "50"
								, required     = "false"
								, control      = "overridenControl"
								, generator    = "none"
								, generate     = "never"
								, relatedto    = "none"
								, relationship = "none"
								, sourceObject = "security_user"
								, binding      = "security_user.known_as"
								, rules        = []
								, label        = "preside-objects.security_user:field.known_as.title"
								, placeholder  = "preside-objects.security_user:field.known_as.placeholder"
								, help         = "preside-objects.security_user:field.known_as.help"
								, sortorder    = 40
							} ]
						}]

					}]
				};

				expect( result ).toBe( expected );
			} );

		} );

		describe( "getDefaultFormForPresideObject()", function(){

			it( "should return a form with one tab and one fieldset containing all fields from the given preside object", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/forms4" );
				var result   = formsSvc.getDefaultFormForPresideObject( objectName="security_group" );
				var expected = {
					tabs = [{
						id="default",
						title="preside-objects.security_group:tab.default.title",
						description="preside-objects.security_group:tab.default.description",
						iconClass="preside-objects.security_group:tab.default.iconClass",
						autoGeneratedAttributes=["title","description","iconClass"],
						fieldsets=[{
							id="default",
							title="preside-objects.security_group:fieldset.default.title",
							description="preside-objects.security_group:fieldset.default.description",
							autoGeneratedAttributes=["title","description"],
							fields=[{
								name="label", control="textinput", type="string", dbtype="varchar", maxLength="250", uniqueindexes="role_name", relationship="none", relatedTo="none", generator="none", generate="never", required="true", sourceObject="security_group", label="preside-objects.security_group:field.label.title", help="preside-objects.security_group:field.label.help", placeholder="preside-objects.security_group:field.label.placeholder", sortorder=10
							},{
								name="description", control="default", type="string", dbtype="varchar", maxLength="200", required="false", relationship="none", relatedTo="none", generator="none", generate="never", sourceObject="security_group", label="preside-objects.security_group:field.description.title", help="preside-objects.security_group:field.description.help", placeholder="preside-objects.security_group:field.description.placeholder", sortorder=20
							},{
								name="users", adminrenderer="objectRelatedRecordsList", control="default", dbtype="none", generate="never", generator="none", help="preside-objects.security_group:field.users.help", label="preside-objects.security_group:field.users.title", maxlength="0", placeholder="preside-objects.security_group:field.users.placeholder", relatedto="security_user", relatedvia="security_group__join__security_user", relatedviasourcefk="security_group", relatedviatargetfk="security_user", relationship="many-to-many", relationshipissource=true , required=false , sortorder=30 , sourceobject="security_group", type="string"
							},{
								name="roles", control="rolepicker", multiple="true", type="string", dbtype="varchar", maxLength="1000", relationship="none", relatedTo="none", generator="none", generate="never", required="false", sourceObject="security_group", label="preside-objects.security_group:field.roles.title", help="preside-objects.security_group:field.roles.help", placeholder="preside-objects.security_group:field.roles.placeholder", sortorder=40, renderer="adminGroupRoles"
							}]
						}]
					}]
				};

				expect( result ).toBe( expected );
			} );

		} );

		describe( "listForms()", function(){

			it( "should return an empty array when no forms registered", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/idonotexist" );
				var result   = formsSvc.listForms();

				expect( result ).toBe( [] );
			} );

			it( "should return array of registered form names", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/forms4" );
				var expected = [ "event.cms.add", "event.cms.edit" ];
				var result   = formsSvc.listForms();

				expect( result ).toBe( expected );
			} );

		} );

		describe( "listFields()", function(){

			it( "should return an array of field names in the given form", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/forms1" );
				var result   = formsSvc.listFields( "test.form" );
				var expected = [ "somefield1", "somefield2", "somefield3", "somefield4" ];

				expect( result ).toBe( expected );
			} );

		} );

		describe( "listAutoTrimFields()", function(){

			it( "should return a struct of autoTrim-enabled/disabled field names in the given form", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/forms1" );
				var result   = formsSvc.listAutoTrimFields( "test.form.autotrim" );
				var expected = { enabled=[ "somefield4" ], disabled=[ "somefield1", "somefield3" ] };

				expect( result ).toBe( expected );
			} );

		} );

		describe( "getFormField()", function(){

			it( "should return specified field from form", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/forms1" );
				var result   = formsSvc.getFormField( formName="test.form", fieldName="somefield3" );
				var expected = { name="somefield3", control="spinner", step="3", minValue="0", maxValue="10", required="false", label="{forms:some.field3.label}", hint="{forms.some.field3.hint}", rules=[] };

				expect( result ).toBe( expected );
			} );

			it( "should throw informative error when field does not exist", function(){
				var formsSvc    = _getFormsService( "/tests/resources/formsService/forms1" );
				var errorThrown = false;

				try {
					formsSvc.getFormField( formName="test.form", fieldName="Does not exist" );
				} catch( "FormsService.MissingField" e ) {
					expect( e.message ).toBe( "The form field, [Does not exist], could not be found in the form, [test.form]" );
					errorThrown = true;
				} catch( any e ) {
					fail( "The wrong kind of error was thrown. Expected [FormsService.MissingField], but received, [#e.type#]" )
				}

				expect( errorThrown ).toBe( true );
			} );

		} );

		describe( "getMergedFormName()", function(){

			it( "should return a single form name combining two form names", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/merging" );
				var result   = formsSvc.getMergedFormName( "form1", "form2" );
				var expected = "form1.merged.with.form2";

				expect( result ).toBe( expected );
			} );

			it( "should return a single form name combining three form names", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/merging" );
				var result   = formsSvc.getMergedFormName( "form1", [ "form2", "form3" ] );
				var expected = "form1.merged.with.form2.merged.with.form3";

				expect( result ).toBe( expected );
			} );

		} );

		describe( "mergeForms()", function(){

			it( "should return a single form definition composed of two form definitions", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/merging" );
				var result   = formsSvc.mergeForms( "form1", "form2" );
				var expected = {
					tabs = [{
						title="A new title",
						description="",
						id = "sometab",
						fieldsets=[{
							title="Another new title",
							description="A description",
							id="somefieldset",
							fields=[
								{ name="anotherfield", rules=[], sortorder=5 },
								{ name="somename", control="overridenControl", required="false", rules=[], sortorder=10 }
							]
						},{
							title="",
							description="",
							id="",
							fields=[
								{ name="meh", required=false, rules=[] }
							]
						},{
							title="",
							description="",
							id="",
							fields=[
								{ name="meh2", blah="blah", rules=[] }
							]
						}]

					},{
						title="",
						description="",
						id = "",
						fieldsets=[{
							title="",
							description="",
							id="",
							fields=[
								{ name="mehsomemore", required="false", rules=[] }
							]
						}]
					},{
						title="",
						description="",
						id = "",
						fieldsets=[{
							title="",
							description="",
							id="",
							fields=[
								{ name="intab3", required="false", rules=[] }
							]
						}]
					}]
				};

				expect( result ).toBe( expected );
			} );

			it( "should return a single form definition composed of three form definitions", function(){
				var formsSvc = _getFormsService( "/tests/resources/formsService/merging" );
				var result   = formsSvc.mergeForms( "form1", [ "form2", "form3" ] );
				var expected = {
					tabs = [{
						title="A new title",
						description="",
						id = "sometab",
						fieldsets=[{
							title="Another new title",
							description="A description",
							id="somefieldset",
							fields=[
								{ name="anotherfield", rules=[], sortorder=5 },
								{ name="somename", control="overridenControl", required="false", rules=[], sortorder=10 },
								{ name="fieldfromform3", rules=[], sortorder=30 }
							]
						},{
							title="",
							description="",
							id="",
							fields=[
								{ name="meh", required=false, rules=[] }
							]
						},{
							title="",
							description="",
							id="",
							fields=[
								{ name="meh2", blah="blah", rules=[] }
							]
						}]

					},{
						title="",
						description="",
						id = "",
						fieldsets=[{
							title="",
							description="",
							id="",
							fields=[
								{ name="mehsomemore", required="false", rules=[] }
							]
						}]
					},{
						title="",
						description="",
						id = "",
						fieldsets=[{
							title="",
							description="",
							id="",
							fields=[
								{ name="intab3", required="false", rules=[] }
							]
						}]
					}]
				};

				expect( result ).toBe( expected );
			} );

		} );

		describe( "createForm()", function(){

			it( "should create an empty form and return the new form name if no arguments passed", function(){
				var service     = _getFormsService( "" );
				var newFormName = service.createForm();
				var theForm     = service.getForm( newFormName );

				expect( theForm ).toBe( { tabs=[] } );
			} );

			it( "should pass an empty form definition to the passed 'generator' argument (a closure) so that calling code can build the form definition", function(){
				var service     = _getFormsService( "" );
				var newFormName = service.createForm( generator=function( definition ){
					definition.addField( name="testfield", fieldset="default", tab="default" );
				} );

				expect( service.getForm( newFormName ) ).toBe( { tabs=[
					{ id="default", fieldsets=[
						{ id="default", fields=[
							{ name="testfield" }
						] }
					] }
				] } );
			} );

			it( "should create a new form definition based on the form matching the passed 'basedOn' argument (if supplied)", function(){
				var service     = _getFormsService( "/tests/resources/formsService/forms1" );
				var newFormName = service.createForm( basedOn="test.form", generator=function( formDefinition ){
					formDefinition.addField( name="myfield", fieldset="default", tab="default", control="mycontrol" );
				} );

				expect( service.getForm( newFormName ) ).toBe( {
					tabs = [{
						title="{forms:tab1.title}",
						description="{forms:tab1.description}",
						id="",
						fieldsets=[{
							title="",
							description="",
							id="",
							fields=[{
								name="somefield1", control="testcontrol", required="true", maxLength="50", label="{forms:some.field.label}", hint="{forms.some.field.hint}", rules=[]
							},{
								name="somefield2", control="spinner", step="2", minValue="0", maxValue="10", required="false", label="{forms:some.field2.label}", hint="{forms.some.field2.hint}", rules=[]
							}]
						}]

					},{
						title="{forms:tab2.title}",
						description="{forms:tab2.description}",
						id="",
						fieldsets=[{
							title="{test:test.fieldset.title}",
							description="",
							id="",
							fields=[{
								name="somefield3", control="spinner", step="3", minValue="0", maxValue="10", required="false", label="{forms:some.field3.label}", hint="{forms.some.field3.hint}", rules=[]
							}]
						},{
							title="{test:test.fieldset2.title}",
							description="{test:test.fieldset2.description}",
							id="",
							fields=[{
								name="somefield4", control="spinner", step="5", minValue="0", maxValue="100", required="false", default="10", rules=[
									  { validator="required", serverCondition="${somefield3} gt 10", clientCondition="${somefield3}.val() > 10", params={} }
									, { validator="sameAs", params={field="somefield1"} }
								]
							}]
						}]
					},{
						id="default",
						fieldsets=[{
							id="default",
							fields=[{
								name="myfield", control="mycontrol"
							}]
						}]
					}]
				} );
			} );

			it( "should use the supplied form name when non-empty", function(){
				var service     = _getFormsService( "" );
				var newFormName = service.createForm( formName="mynewform", generator=function( definition ){
					definition.addField( name="testfield", fieldset="default", tab="default" );
				} );

				expect( newFormName ).toBe( "mynewform" );
			} );

		} );

		describe( "removePermissionedFieldsFromFormDefinition()", function(){
			var service         = _getFormsService( "/tests/resources/formsService/forms1" );
			var permContext     = "testcontext";
			var permContextKeys = [ CreateUUId(), CreateUUId() ];

			service.$( "$hasAdminPermission" ).$args(
				  permissionKey = "yes.permission"
				, context       = permContext
				, contextKeys   = permContextKeys
			).$results( true );
			service.$( "$hasAdminPermission" ).$args(
				  permissionKey = "no.permission"
				, context       = permContext
				, contextKeys   = permContextKeys
			).$results( false );

			it( "should do nothing to a form that does not have any permissions defined", function(){
				var formDefinition  = {
					tabs = [
						  { id="one"  , fieldsets=[ { fields=[ { name="field1" } ] } ] }
						, { id="two"  , fieldsets=[ { fields=[ { name="field2" } ] } ] }
						, { id="three", fieldsets=[ { fields=[ { name="field3" } ] } ] }
					]
				};

				expect( service.removePermissionedFieldsFromFormDefinition( formDefinition ) ).toBe( formDefinition );
			} );


			it( "should remove fields that are tagged with permission keys that the user does not have access to", function(){
				var formDefinition  = {
					tabs = [
						  { id="one"  , fieldsets=[ { fields=[ { name="field1", permissionKey=""               } ] } ] }
						, { id="two"  , fieldsets=[ { fields=[ { name="field2", permissionKey="no.permission"  } ] } ] }
						, { id="three", fieldsets=[ { fields=[ { name="field3", permissionKey="yes.permission" } ] } ] }
					]
				};
				var expectedStrippedForm = Duplicate( formDefinition );

				expectedStrippedForm.tabs[2].fieldsets[1].fields.deleteAt( 1 );

				expect( service.removePermissionedFieldsFromFormDefinition(
					  formDefinition        = formDefinition
					, permissionContext     = permContext
					, permissionContextKeys = permContextKeys
				) ).toBe( expectedStrippedForm );
			} );

			it( "should remove entire fieldsets that are tagged with permission keys that the user does not have access to", function(){
				var formDefinition  = {
					tabs = [
						  { id="one"  , fieldsets=[ { permissionKey="no.permission" , fields=[ { name="field1" } ] } ] }
						, { id="two"  , fieldsets=[ { permissionKey="yes.permission", fields=[ { name="field2" } ] } ] }
						, { id="three", fieldsets=[ { permissionKey=""              , fields=[ { name="field3" } ] } ] }
					]
				};
				var expectedStrippedForm = Duplicate( formDefinition );

				expectedStrippedForm.tabs[1].fieldsets.deleteAt( 1 );

				expect( service.removePermissionedFieldsFromFormDefinition(
					  formDefinition        = formDefinition
					, permissionContext     = permContext
					, permissionContextKeys = permContextKeys
				) ).toBe( expectedStrippedForm );
			} );

			it( "should remove entire tabs that are tagged with permission keys that the user does not have access to", function(){
				var formDefinition  = {
					tabs = [
						  { id="one"  , permissionKey=""              , fieldsets=[ { fields=[ { name="field1" } ] } ] }
						, { id="two"  , permissionKey="yes.permission", fieldsets=[ { fields=[ { name="field2" } ] } ] }
						, { id="three", permissionKey="no.permission" , fieldsets=[ { fields=[ { name="field3" } ] } ] }
					]
				};
				var expectedStrippedForm = Duplicate( formDefinition );
				expectedStrippedForm.tabs.deleteAt( 3 );

				expect( service.removePermissionedFieldsFromFormDefinition(
					  formDefinition        = formDefinition
					, permissionContext     = permContext
					, permissionContextKeys = permContextKeys
				) ).toBe( expectedStrippedForm );
			} );
		} );
	}

	private any function _getFormsService(
		  required string formDirectories
		,          string activeSiteTemplate = ""
	) {
		mockI18nPlugin              = createMock( "preside.system.services.i18n.i18n" );
		mockColdBox                 = createMock( "preside.system.coldboxModifications.Controller" );
		mockSiteService             = createMock( "preside.system.services.siteTree.SiteService" );
		mockValidationRuleGenerator = createEmptyMock( "preside.system.services.validation.PresideFieldRuleGenerator" );
		mockFeatureService          = createEmptyMock( "preside.system.services.features.FeatureService" );
		poService                   = _getPresideObjectService();

		mockSiteService.$( "getActiveSiteTemplate", arguments.activeSiteTemplate );
		mockValidationRuleGenerator.$( "generateRulesFromPresideForm", [] );

		mockFeatureService.$( "isFeatureEnabled" ).$args( "enabled-feature" ).$results( true );
		mockFeatureService.$( "isFeatureEnabled" ).$args( "disabled-feature" ).$results( false );
		mockFeatureService.$( "isFeatureEnabled", true );

		var service = createMock( object=new preside.system.services.forms.FormsService(
			  presideObjectService = poService
			, siteService          = mockSiteService
			, logger               = _getTestLogger()
			, formDirectories      = ListToArray( arguments.formDirectories )
			, validationEngine     = new preside.system.services.validation.ValidationEngine()
			, i18n                 = mockI18nPlugin
			, coldbox              = mockColdBox
			, presideFieldRuleGenerator = mockValidationRuleGenerator
			, defaultContextName   = "index"
			, configuredControls   = {}
			, featureService       = mockFeatureService
		) );

		service.$( "$hasAdminPermission", true );

		return service;
	}
}
