<cfparam name="args.page" type="page" />

<cfset pg = args.page />

<cfoutput>
	<a class="pull-right" href="#getSourceLink( path=pg.getSourceFile() )#" title="Improve the docs"><i class="fa fa-pencil fa-fw"></i></a>
	#markdownToHtml( pg.getBody() )#
</cfoutput>