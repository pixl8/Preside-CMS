<cfscript>
	param name="args.objectName"          type="string";
	param name="args.useMultiActions"     type="boolean" default=false;
	param name="args.isMultilingual"      type="boolean" default=false;
	param name="args.multiActionUrl"      type="string"  default="";
	param name="args.gridFields"          type="array";
	param name="args.allowSearch"         type="boolean" default=true;
	param name="args.batchEditableFields" type="array"   default=[];
	param name="args.datasourceUrl"       type="string"  default=event.buildAdminLink( linkTo="ajaxProxy", queryString="id=#args.objectName#&action=dataManager.getObjectRecordsForAjaxDataTables&useMultiActions=#args.useMultiActions#&gridFields=#ArrayToList( args.gridFields )#&isMultilingual=#args.isMultilingual#" );
	objectTitle          = translateResource( uri="preside-objects.#args.objectName#:title", defaultValue=args.objectName )
	deleteSelected       = translateResource( uri="cms:datamanager.deleteSelected.title" );
	deleteSelectedPrompt = translateResource( uri="cms:datamanager.deleteSelected.prompt", data=[ LCase( objectTitle ) ] );
	batchEditTitle       = translateResource( uri="cms:datamanager.batchEditSelected.title" );
	event.include( "/js/admin/specific/datamanager/object/");
	event.include( "/css/admin/specific/datamanager/object/");
	event.includeData( {
		  objectName          = args.objectName
		, datasourceUrl       = args.datasourceUrl
		, useMultiActions     = args.useMultiActions
		, allowSearch         = args.allowSearch
		, isMultilingual      = args.isMultilingual
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
					<cfif args.isMultilingual>
						<th>#translateResource( uri="cms:datamanager.translate.column.status" )#</th>
					<cfelse>
						<th>&nbsp;</th>
					</cfif>
				</tr>
			</thead>
			<tbody data-nav-list="1" data-nav-list-child-selector="> tr<cfif args.useMultiActions> > td :checkbox<cfelse> a:nth-of-type(1)</cfif>">
			</tbody>
		</table>
		<cfif args.useMultiActions>
				<div class="form-actions" id="multi-action-buttons">
					<cfif args.batchEditableFields.len()>
						<div class="btn-group batch-update-menu">
							<button data-toggle="dropdown" class="btn btn-info">
								<span class="fa fa-caret-down"></span>
								<i class="fa fa-pencil"></i>
								#batchEditTitle#
							</button>

							<ul class="dropdown-menu" role="menu" aria-labelledby="dLabel">
								<li><h5 class="instructions">#translateResource( uri="cms:datamanager.batchedit.choose.field")#</h5></li>
								<cfloop array="#args.batchEditableFields#" index="i" item="field">
									<li data-field="#HtmlEditFormat( field )#" class="field">
										<a href="##">
											<i class="fa fa-fw fa-pencil"></i>&nbsp;
											#translateResource( uri="preside-objects.#args.objectName#:field.#field#.title", defaultValue=field )#
										</a>
									</li>
								</cfloop>
							</ul>
						</div>
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