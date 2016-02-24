<cfscript>
	param name="args.objectName"      type="string";
	param name="args.useMultiActions" type="boolean" default=false;
	param name="args.multiActionUrl"  type="string" default="";
	param name="args.updateActionUrl" type="string" default="";
	param name="args.datasourceUrl"   type="string" default=event.buildAdminLink( linkTo="ajaxProxy", queryString="id=#args.objectName#&action=dataManager.getObjectRecordsForAjaxDataTables&useMultiActions=#args.useMultiActions#&gridFields=#ArrayToList( args.gridFields )#" );
	param name="args.gridFields"      type="array";
	param name="args.fieldset"        type="struct" default={};
	param name="args.allowSearch"     type="boolean" default=true;
	param name="renderSwitch"         type="string"  default="";
	objectTitle          = translateResource( uri="preside-objects.#args.objectName#:title", defaultValue=args.objectName )
	deleteSelected       = translateResource( uri="cms:datamanager.deleteSelected.title" );
	deleteSelectedPrompt = translateResource( uri="cms:datamanager.deleteSelected.prompt", data=[ LCase( objectTitle ) ] );
	selectFieldOption    = translateResource( uri="cms:datamanager.selectFieldOption.title" );
	updateObjectTitle    = translateResource( uri="cms:datamanager.updateObject.title", data=[ LCase( objectTitle ) ] );
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
				formControl.name                = relatedField;
				formControl.label               = relatedField;
				formControl.maxlength           = args.fieldset[relatedField].maxlength ?: "";
				formControl.minlength           = args.fieldset[relatedField].minlength ?: "";
				if( args.fieldset[relatedField].relationship         == "many-to-many") {
					formControl.object          = args.fieldset[relatedField].relatedto;
					formControl.type        	= "objectPicker";
					formControl.multiple        = 1;
					formControl.ajax 			= false;
				} else if( args.fieldset[relatedField].relationship  == "many-to-one" ) {
					formControl.object          = args.fieldset[relatedField].relatedto;
					formControl.type        	= "objectPicker";
					formControl.ajax 			= false;
				} else if(args.fieldset[relatedField].type           == "string" ){
					formControl.type        	= "textinput";
				} else if(args.fieldset[relatedField].type           == "numeric"){
					formControl.maxValue        = args.fieldset[relatedField].maxvalue  ?: "";
					formControl.minValue        = args.fieldset[relatedField].minvalue  ?: "";
					formControl.type            = "number";
				} else if(args.fieldset[relatedField].type           == "boolean"){
					formControl.type        	= "yesNoSwitch";
				} else if(args.fieldset[relatedField].type           == "date"   ){
					formControl.type        	= "datepicker";
				}
				renderObject[relatedField]  = renderFormControl( argumentCollection = formControl );
				structClear(formControl);
				if( args.fieldset[relatedField].relationship  == "many-to-many") {
					renderSwitch            = renderFormControl( type  = "select",
																name   = "overwrite" , 
																values = [ "append", "	overwrite" ], 
																labels = ["APPEND","OVERWRITE" ] );
				}
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
					<button class="btn btn-info" disabled="disabled" data-global-key="m" data-toggle="update-object-dialog" data-target="update-object-form" data-dialog-title="#updateObjectTitle#">
						<i class="fa fa-folder bigger-110"></i>
						#selectFieldOption#
					</button>
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
	<div id="update-object-form" class="hide">
		<form class="form-horizontal row" action="#args.updateActionUrl#" method="post">
			<input type="hidden" name="id" value="" />
			<cfloop collection="#renderObject#" item="getRenderObject">
				#structfind(renderObject,getRenderObject)#
				<input type="checkbox" name="checkbox_#getRenderObject#">
			</cfloop>
			#renderSwitch#
		</form>
	</div>
</cfoutput>