<cfscript>
	param name="args.objectName"      type="string";
	param name="args.useMultiActions" type="boolean" default=false;
	param name="args.multiActionUrl"  type="string" default="";
	param name="args.datasourceUrl"   type="string" default=event.buildAdminLink( linkTo="ajaxProxy", queryString="id=#args.objectName#&action=dataManager.getObjectRecordsForAjaxDataTables&useMultiActions=#args.useMultiActions#&gridFields=#ArrayToList( args.gridFields )#" );
	param name="args.gridFields"      type="array";
	param name="args.fieldset"        type="struct" default={};
	param name="args.allowSearch"     type="boolean" default=true;

	objectTitle          = translateResource( uri="preside-objects.#args.objectName#:title", defaultValue=args.objectName )
	deleteSelected       = translateResource( uri="cms:datamanager.deleteSelected.title" );
	deleteSelectedPrompt = translateResource( uri="cms:datamanager.deleteSelected.prompt", data=[ LCase( objectTitle ) ] );
	updateSelected       = translateResource( uri="cms:datamanager.updateSelected.title" );
	updateSelectedPrompt = translateResource( uri="cms:datamanager.updateSelected.prompt", data=[ LCase( objectTitle ) ] );

	event.include( "/js/admin/specific/datamanager/object/");
	event.include( "/css/admin/specific/datamanager/object/");
	event.includeData( {
		  objectName      = args.objectName
		, datasourceUrl   = args.datasourceUrl
		, useMultiActions = args.useMultiActions
		, allowSearch     = args.allowSearch
	} );	
	
	if( !structIsEmpty( args.fieldset ) ){
		for( relatedField in args.fieldset ){
			if(args.fieldset[relatedField].relationship != "one-to-many"){
				formControl.name       = relatedField;
				formControl.label      = relatedField;
				formControl.required   = args.fieldset[relatedField].required;
				formControl.maxlength  = args.fieldset[relatedField].maxlength ?: "";
				formControl.minlength  = args.fieldset[relatedField].minlength ?: "";
				formControl.maxValue   = args.fieldset[relatedField].maxvalue  ?: "";
				formControl.minValue   = args.fieldset[relatedField].minvalue  ?: "";
				if( args.fieldset[relatedField].relationship == "many-to-many") {
					formControl.object          = args.fieldset[relatedField].relatedto;
					formControl.type        	= "objectPicker";
					formControl.multiple        = 1;
					formControl.ajax 			= false;
				} else if( args.fieldset[relatedField].relationship == "many-to-one" ) {
					formControl.object          = args.fieldset[relatedField].relatedto;
					formControl.type        	= "objectPicker";
					formControl.ajax 			= false;
				} else if(args.fieldset[relatedField].type == "string" ){
					formControl.type        	= "textinput";
				} else if(args.fieldset[relatedField].type == "numeric"){
					formControl.type        	= "number";
				} else if(args.fieldset[relatedField].type == "boolean"){
					formControl.type        	= "yesNoSwitch";
				} else if(args.fieldset[relatedField].type == "date"   ){
					formControl.type        	= "datepicker";
				}
				renderObject[relatedField]  = renderFormControl( argumentCollection = formControl );
				structClear(formControl);
			}
		}
	}

</cfscript>		
<cfoutput>
	<div class="table-responsive">
		<cfif args.useMultiActions>
			<form id="multi-action-form" class="form-horizontal" method="post" action="#args.multiActionUrl#">
				<input type="hidden" name="multiAction" value="" />
		</cfif>
		<table id="object-listing-table-#LCase( args.objectName )#" class="table table-hover object-listing-table">
			<thead>
				<tr>
					<cfif args.useMultiActions>
						<th class="center">
							<label>
								<input type="checkbox" class="ace" />
								<span class="lbl"></span>
							</label>
						</th>
					</cfif>
					<cfloop array="#args.gridFields#" index="fieldName">
						<th data-field="#fieldName#">#translateResource( uri="preside-objects.#args.objectName#:field.#fieldName#.title", defaultValue=translateResource( "cms:preside-objects.default.field.#fieldName#.title" ) )#</th>
					</cfloop>
					<th>&nbsp;</th>
				</tr>
			</thead>
			<tbody data-nav-list="1" data-nav-list-child-selector="> tr<cfif args.useMultiActions> > td :checkbox<cfelse> a:nth-of-type(1)</cfif>">
			</tbody>
		</table>

		<cfif args.useMultiActions>
				<div class="form-actions" id="multi-action-buttons">
					<cfif !structIsEmpty( args.fieldset )>
						<cfloop collection="#renderObject#" item="getRenderObject">
							#structfind(renderObject,getRenderObject)#
						</cfloop>
						<button class="btn btn-success" type="submit" name="update" disabled="disabled" title="#updateSelectedPrompt#">
							<i class="fa fa-check bigger-110"></i>
							#updateSelected#
						</button>
					</cfif>
					<cfif hasCmsPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ args.objectName ] )>
						<button class="btn btn-danger confirmation-prompt" type="submit" name="delete" disabled="disabled" data-global-key="d" title="#deleteSelectedPrompt#">
							<i class="fa fa-trash-o bigger-110"></i>
							#deleteSelected#
						</button>
					</cfif>
				</div>
			</form>
		</cfif>
	</div>
</cfoutput>