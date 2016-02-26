<cfscript>
	param name="args.objectName"      type="string";
	param name="args.useMultiActions" type="boolean" default=false;
	param name="args.multiActionUrl"  type="string"  default="";
	param name="args.gridFields"      type="array";
	param name="args.allowSearch"     type="boolean" default=true;
	param name="args.fieldset"        type="struct"  default={};
	param name="args.datasourceUrl"   type="string"  default=event.buildAdminLink( linkTo="ajaxProxy", queryString="id=#args.objectName#&action=dataManager.getObjectRecordsForAjaxDataTables&useMultiActions=#args.useMultiActions#&gridFields=#ArrayToList( args.gridFields )#" );
	objectTitle          = translateResource( uri="preside-objects.#args.objectName#:title", defaultValue=args.objectName )
	deleteSelected       = translateResource( uri="cms:datamanager.deleteSelected.title" );
	deleteSelectedPrompt = translateResource( uri="cms:datamanager.deleteSelected.prompt", data=[ LCase( objectTitle ) ] );
	selectFieldOption    = translateResource( uri="cms:datamanager.selectFieldOption.title" );
	event.include( "/js/admin/specific/datamanager/object/");
	event.include( "/css/admin/specific/datamanager/object/");
	event.includeData( {
		  objectName      = args.objectName
		, datasourceUrl   = args.datasourceUrl
		, useMultiActions = args.useMultiActions
		, allowSearch     = args.allowSearch
	} );
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
					<div class="col-md-4">
						<div class="form-group"> 
							<label class="col-md-3 control-label no-padding-right" for="overwrite">
								 Pick field 
							</label> 
							<div class="col-md-8"> 
								<div class="clearfix"> 
									<select class=" object-picker " name="pickField" id="overwrite" tabindex="2" data-placeholder="" data-sortable="false" data-value="" >
										<cfloop collection="#args.fieldset#" item="getRenderObject">
											<option value="#getRenderObject#">#getRenderObject#</option>
										</cfloop>
									</select>
								 </div>
							</div> 
						</div> 
					</div>
					<button class="btn btn-info" type="submit" name="update" disabled="disabled">
						<i class="fa fa-check bigger-110"></i>
						#selectFieldOption#
					</button>					
				</div>
			</form>
		</cfif>
	</div>
</cfoutput>