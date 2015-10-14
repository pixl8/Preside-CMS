<cfparam name="args.title" type="string" />

<cfoutput>
	<ul class="breadcrumb margin-no-top margin-right margin-no-bottom margin-left">
		<li><a href="index.html">Home</a></li>
		<li class="active">#HtmlEditFormat( args.title )#</li>
	</ul>
</cfoutput>
