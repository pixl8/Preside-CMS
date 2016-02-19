<cfscript>
	param name="args.objectName"      type="string";
	param name="args.useMultiActions" type="boolean" default=false;
	param name="args.multiActionUrl"  type="string" default="";
	param name="args.datasourceUrl"   type="string" default=event.buildAdminLink( linkTo="ajaxProxy", queryString="id=#args.objectName#&action=dataManager.getObjectRecordsForAjaxDataTables&useMultiActions=#args.useMultiActions#&gridFields=#ArrayToList( args.gridFields )#" );
	param name="args.gridFields"      type="array";
	param name="args.relatedProperty" type="struct" default={};
	param name="args.allowSearch"     type="boolean" default=true;

	objectTitle          = translateResource( uri="preside-objects.#args.objectName#:title", defaultValue=args.objectName )
	deleteSelected       = translateResource( uri="cms:datamanager.deleteSelected.title" );
	deleteSelectedPrompt = translateResource( uri="cms:datamanager.deleteSelected.prompt", data=[ LCase( objectTitle ) ] );

	event.include( "/js/admin/specific/datamanager/object/");
	event.include( "/css/admin/specific/datamanager/object/");
	event.includeData( {
		  objectName      = args.objectName
		, datasourceUrl   = args.datasourceUrl
		, useMultiActions = args.useMultiActions
		, allowSearch     = args.allowSearch
	} );
			
		if( !structIsEmpty( args.relatedProperty ) ){
			for(relatedField in args.relatedProperty){
				
				formControl.name            = relatedField;
				formControl.object 			= relatedField;
				formControl.type        	= "objectPicker";
				formControl.ajax 			= false;
				formControl.id              = args.objectName;

				if(args.relatedProperty[relatedField] == "many-to-many"){
					formControl.multiple            = 1;
				}

				renderObject[relatedField]    = renderFormControl( argumentCollection = formControl );
			}
		}
</cfscript>

<cfoutput>
	<div class="table-responsive">
		<cfif args.useMultiActions>
			<form id="multi-action-form" class="form-horizontal" method="post" action="#args.multiActionUrl#">
				<input type="hidden" name="multiAction" value="" />
				<cfif !structIsEmpty( args.relatedProperty )>
					<cfloop collection="#renderObject#" item="getRenderObject">
						<input type="hidden" name="relatedFieldName.#getRenderObject#" value="#getRenderObject#" />
					</cfloop>
				</cfif>

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
					<cfif !structIsEmpty( args.relatedProperty )>
							<cfloop collection="#renderObject#" item="getRenderObject">
								#structfind(renderObject,getRenderObject)#
							</cfloop>
							<button class="btn btn-info" type="submit" name="update" disabled="disabled" data-global-key="d" title="update">
								<i class="fa fa-file-o bigger-110"></i>
								update selected
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