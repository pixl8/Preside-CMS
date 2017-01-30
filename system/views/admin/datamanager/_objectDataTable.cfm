<cfscript>
	param name="args.objectName"          type="string";
	param name="args.useMultiActions"     type="boolean" default=false;
	param name="args.isMultilingual"      type="boolean" default=false;
	param name="args.draftsEnabled"       type="boolean" default=false;
	param name="args.multiActionUrl"      type="string"  default="";
	param name="args.gridFields"          type="array";
	param name="args.allowSearch"         type="boolean" default=true;
	param name="args.allowFilter"         type="boolean" default=true;
	param name="args.clickableRows"       type="boolean" default=true;
	param name="args.batchEditableFields" type="array"   default=[];
	param name="args.datasourceUrl"       type="string"  default=event.buildAdminLink( linkTo="ajaxProxy", queryString="id=#args.objectName#&action=dataManager.getObjectRecordsForAjaxDataTables&useMultiActions=#args.useMultiActions#&gridFields=#ArrayToList( args.gridFields )#&isMultilingual=#args.isMultilingual#&draftsEnabled=#args.draftsEnabled#" );

	objectTitle          = translateResource( uri="preside-objects.#args.objectName#:title", defaultValue=args.objectName );
	deleteSelected       = translateResource( uri="cms:datamanager.deleteSelected.title" );
	deleteSelectedPrompt = translateResource( uri="cms:datamanager.deleteSelected.prompt", data=[ LCase( objectTitle ) ] );
	batchEditTitle       = translateResource( uri="cms:datamanager.batchEditSelected.title" );


	event.include( "/js/admin/specific/datamanager/object/");
	event.include( "/css/admin/specific/datamanager/object/");

	tableId = args.id ?: "object-listing-table-#LCase( args.objectName )#";

	args.allowFilter = args.allowFilter && isFeatureEnabled( "rulesengine" );

	if ( args.allowFilter ) {
		saveFilterFormEndpoint = event.buildAdminLink(
			  linkTo      = "rulesEngine.superQuickAddFilterForm"
			, querystring = "filter_object=#args.objectName#&multiple=false&expressions="
		);
	}
</cfscript>
<cfoutput>
	<div class="table-responsive">
		<cfif args.useMultiActions>
			<form id="multi-action-form" class="form-horizontal" method="post" action="#args.multiActionUrl#">
				<input type="hidden" name="multiAction" value="" />
		</cfif>

		<cfif args.allowFilter>
			<div class="object-listing-table-filter hide" id="#tableId#-filter">
				<div class="row">
					<div class="col-md-12">
						<a class="pull-right back-to-basic-search" href="##">
							<i class="fa fa-fw fa-reply"></i>
							#translateResource( "cms:datatables.show.basic.search" )#
						</a>
						<h4 class="blue">#translateResource( "cms:rulesEngine.saved.filters" )#</h4>
						<p class="grey"><i class="fa fa-fw fa-info-circle"></i> <em>#translateResource( "cms:rulesEngine.saved.filters.help" )#</em></p>
						#renderFormControl(
							  name         = "filters"
							, id           = "filters"
							, type         = "filterPicker"
							, context      = "admin"
							, filterObject = args.objectName
							, multiple     = true
							, quickedit    = true
							, label        = ""
							, layout       = ""
							, compact      = true
							, showCount    = false
						)#
						<br><br>
						<a href="##" data-toggle="collapse" data-target="##quick-filter-form" class="quick-filter-toggler">
							<i class="fa fa-fw fa-caret-down"></i>#translateResource( "cms:rulesEngine.show.quick.filter" )#
						</a>
					</div>
				</div>

				<div id="quick-filter-form" class="in">
					#renderFormControl(
						  name      = "filter"
						, id        = "filter"
						, type      = "rulesEngineFilterBuilder"
						, context   = "admin"
						, object    = args.objectName
						, label     = ""
						, layout    = ""
						, compact   = true
						, showCount = false
					)#

					<div class="form-actions">
						<div class="pull-right">
							<button class="btn btn-info btn-sm save-filter-btn" tabindex="#getNextTabIndex()#" disabled data-save-form-endpoint="#saveFilterFormEndpoint#">
								<i class="fa fa-fw fa-save"></i>
								#translateResource( "cms:rulesEngine.quick.filter.save.btn" )#
							</button>
						</div>
					</div>
				</div>
			</div>
		</cfif>

		<table id="#tableId#" class="table table-hover object-listing-table"
			data-object-name="#args.objectName#"
		    data-datasource-url="#args.datasourceUrl#"
		    data-use-multi-actions="#args.useMultiActions#"
		    data-allow-search="#args.allowSearch#"
		    data-is-multilingual="#args.isMultilingual#"
		    data-drafts-enabled="#args.draftsEnabled#"
		    data-clickable-rows="#args.clickableRows#"
		    data-allow-filter="#args.allowFilter#"
		>
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
					<cfif args.draftsEnabled>
						<th>#translateResource( uri="cms:datamanager.column.draft.status" )#</th>
					</cfif>
					<cfif args.isMultilingual>
						<th>#translateResource( uri="cms:datamanager.translate.column.status" )#</th>
					</cfif>
					<th>&nbsp;</th>
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