<!---@feature presideForms and customFields--->
<cfscript>
	catalogue      = args.catalogue ?: [];
	tabId          = args.tabId ?: "";
	tabLabel       = args.tabLabel ?: "";
	fieldsetId     = args.fieldsetId ?: "";
	fieldsetLabel  = args.fieldsetLabel ?: "";
	controlId      = "cf-placement-#Hash( CreateUUID() )#";
	catalogueJson  = Replace( SerializeJson( catalogue ), "<", Chr( 92 ) & "u003c", "all" );
	newTabSelected = tabId == "__new__" || ( !Len( tabId ) && Len( tabLabel ) );
	newSetSelected = fieldsetId == "__new__" || ( !Len( fieldsetId ) && Len( fieldsetLabel ) );
	selectedSet    = newSetSelected ? "__new__" : fieldsetId;
</cfscript>
<cfoutput>
	<div id="#controlId#" class="custom-field-form-placement">
		<div class="custom-field-form-placement-group">
			<label class="control-label" for="#controlId#-tab">#translateResource( "customFields:formPlacement.tab.title" )#</label>
			<select name="form_tab" id="#controlId#-tab" class="form-control custom-field-form-placement-tab">
				<option value="">#translateResource( "customFields:formPlacement.validation.tab" )#</option>
				<cfloop array="#catalogue#" item="tab">
					<option value="#EncodeForHTMLAttribute( tab.id )#"<cfif tab.id eq tabId> selected</cfif>>#EncodeForHTML( tab.label ?: tab.id )#</option>
				</cfloop>
				<option value="__new__"<cfif newTabSelected> selected</cfif>>#translateResource( "customFields:formPlacement.tab.new" )#</option>
			</select>
		</div>
		<div class="custom-field-form-placement-group custom-field-form-placement-tab-label"<cfif !newTabSelected> style="display:none"</cfif>>
			<label class="control-label" for="#controlId#-tab-label">#translateResource( "customFields:formPlacement.tabLabel.title" )#</label>
			<input type="text" name="form_tab_label" id="#controlId#-tab-label" class="form-control" value="#EncodeForHTMLAttribute( tabLabel )#" />
		</div>
		<div class="custom-field-form-placement-group">
			<label class="control-label" for="#controlId#-fieldset">#translateResource( "customFields:formPlacement.fieldset.title" )#</label>
			<select name="form_fieldset" id="#controlId#-fieldset" class="form-control custom-field-form-placement-fieldset"></select>
		</div>
		<div class="custom-field-form-placement-group custom-field-form-placement-fieldset-label"<cfif !newSetSelected> style="display:none"</cfif>>
			<label class="control-label" for="#controlId#-fieldset-label">#translateResource( "customFields:formPlacement.fieldsetLabel.title" )#</label>
			<input type="text" name="form_fieldset_label" id="#controlId#-fieldset-label" class="form-control" value="#EncodeForHTMLAttribute( fieldsetLabel )#" />
		</div>
		<script type="application/json" class="custom-field-form-placement-catalogue">#catalogueJson#</script>
		<script>
			( function(){
				var root = document.getElementById( "#controlId#" );
				if ( !root ) {
					return;
				}

				var catalogue = JSON.parse( root.querySelector( ".custom-field-form-placement-catalogue" ).textContent || "[]" );
				var tabSelect = root.querySelector( ".custom-field-form-placement-tab" );
				var setSelect = root.querySelector( ".custom-field-form-placement-fieldset" );
				var tabLabelWrap = root.querySelector( ".custom-field-form-placement-tab-label" );
				var setLabelWrap = root.querySelector( ".custom-field-form-placement-fieldset-label" );
				var selectedSet = "#JsStringFormat( selectedSet )#";
				var newSetLabel = "#JsStringFormat( translateResource( 'customFields:formPlacement.fieldset.new' ) )#";
				var chooseSetLabel = "#JsStringFormat( translateResource( 'customFields:formPlacement.validation.fieldset' ) )#";

				function fieldsetsForTab( tabId ) {
					if ( tabId === "__new__" ) {
						return [];
					}
					for ( var i = 0; i < catalogue.length; i++ ) {
						if ( catalogue[ i ].id === tabId ) {
							return catalogue[ i ].fieldsets || [];
						}
					}
					return [];
				}

				function addOption( value, label, selected ) {
					var option = document.createElement( "option" );
					option.value = value;
					option.textContent = label;
					if ( selected ) {
						option.selected = true;
					}
					setSelect.appendChild( option );
				}

				function renderFieldsets() {
					var tabId = tabSelect.value;
					var fieldsets = fieldsetsForTab( tabId );

					setSelect.innerHTML = "";
					addOption( "", chooseSetLabel, selectedSet === "" );
					for ( var i = 0; i < fieldsets.length; i++ ) {
						addOption( fieldsets[ i ].id, fieldsets[ i ].label || fieldsets[ i ].id, fieldsets[ i ].id === selectedSet );
					}
					addOption( "__new__", newSetLabel, selectedSet === "__new__" );
					setLabelWrap.style.display = setSelect.value === "__new__" ? "" : "none";
				}

				tabSelect.addEventListener( "change", function(){
					selectedSet = "";
					tabLabelWrap.style.display = tabSelect.value === "__new__" ? "" : "none";
					renderFieldsets();
				} );
				setSelect.addEventListener( "change", function(){
					selectedSet = setSelect.value;
					setLabelWrap.style.display = setSelect.value === "__new__" ? "" : "none";
				} );

				renderFieldsets();
			} )();
		</script>
	</div>
</cfoutput>
