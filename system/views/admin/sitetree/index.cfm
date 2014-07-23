<cfscript>
	site = event.getSite();

	prc.pageIcon  = "sitemap";
	prc.pageTitle = site.name ?: translateResource( "cms:sitetree" );

	activeTree       = event.getValue( name="activeTree", defaultValue=ArrayNew(1), private=true );
	treeTrash        = event.getValue( name="treeTrash" , defaultValue=ArrayNew(1), private=true );
	noneSelectedText = translateResource( "cms:sitetree.context.pane.noneselected" );
</cfscript>

<cfoutput>
	<div class="row">
		<div class="col-sm-6">
			<div class="widget-box">
				<div class="widget-header">
					<h5><i class="fa fa-sitemap"></i> #prc.pageTitle#</h5>

					<div class="widget-toolbar no-border">
						<ul class="nav nav-tabs" id="myTab">
							<li class="active">
								<a data-toggle="tab" href="##active-tree-tab"><i class="fa fa-check green"></i> #translateResource( "cms:sitetree.active.tab.title" )#</a>
							</li>
							<li>
								<a data-toggle="tab" href="##trash-tree-tab"><i class="fa fa-trash-o red"></i> #translateResource( "cms:sitetree.trash.tab.title" )#</a>
							</li>
						</ul>
					</div>

				</div>

				<div class="widget-body">
					<div class="widget-main">
						<div class="tab-content">
							<div id="active-tree-tab" class="tab-pane in active">
								<div class="site-tree tree tree-unselectable" data-nav-list="1" data-nav-list-child-selector=".tree-folder-header,.tree-item">
									<cfloop array="#activeTree#" index="node">
										#renderView( view="/admin/sitetree/_node", args=node )#
									</cfloop>
								</div>
							</div>

							<div id="trash-tree-tab" class="tab-pane">
								<cfif not treeTrash.len()>
									<p><em>#translateResource( "cms:sitetree.no.trash.nodes.message" )#</em></p>
								<cfelse>
									<div class="site-tree tree tree-unselectable" data-nav-list="2" data-nav-list-child-selector=".tree-folder-header,.tree-item">
										<cfloop array="#treeTrash#" index="node">
											#renderView( view="/admin/sitetree/_node", args=node )#
										</cfloop>
									</div>
									<div class="widget-toolbox padding-8 clearfix">
										<a href="#event.buildAdminLink( linkTo="sitetree.emptyTrashAction" )#" class="confirmation-prompt pull-right" title="#translateResource( 'cms:sitetree.emptytrash.prompt' )#">
											<button class="btn btn-danger btn-sm">
												<i class="fa fa-trash-o"></i>
												#translateResource( 'cms:sitetree.emptytrash.btn' )#
											</button>
										</a>
									</div>
								</cfif>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
		<div class="col-sm-6">
			<div id="tree-context-panel" class="widget-box">
				<div class="widget-header">
					<h5><i class="fa fa-file"></i> #translateResource( "cms:sitetree.context.pane.default.title" )#</h5>

					<div class="widget-toolbar">
						<a href="##" data-action="collapse">
							<i class="fa fa-chevron-up"></i>
						</a>
					</div>
				</div>

				<div class="widget-body">
					<div class="widget-main">
						<dl class="dl-horizontal page-details">
							<dt class="lighter blue">#translateResource( "cms:sitetree.context.pane.pagetitle" )#</dt>
							<dd class="grey pagetitle"><em>#noneSelectedText#</em></dd>
							<dt class="lighter blue">#translateResource( "cms:sitetree.context.pane.template" )#</dt>
							<dd class="grey template"><em>#noneSelectedText#</em></dd>
							<dt class="lighter blue">#translateResource( "cms:sitetree.context.pane.slug" )#</dt>
							<dd class="grey slug"><em>#noneSelectedText#</em></dd>
							<dt class="lighter blue">#translateResource( "cms:sitetree.context.pane.fullslug" )#</dt>
							<dd class="grey fullslug"><em>#noneSelectedText#</em></dd>
							<dt class="lighter blue">#translateResource( "cms:sitetree.context.pane.active" )#</dt>
							<dd class="grey active"><em>#noneSelectedText#</em></dd>
							<dt class="lighter blue">#translateResource( "cms:sitetree.context.pane.created" )#</dt>
							<dd class="grey created"><em>#noneSelectedText#</em></dd>
							<dt class="lighter blue">#translateResource( "cms:sitetree.context.pane.modified" )#</dt>
							<dd class="grey modified"><em>#noneSelectedText#</em></dd>
						</dl>
					</div>
				</div>
			</div>
		</div>
	</div>
</cfoutput>