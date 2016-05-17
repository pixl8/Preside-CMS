<cfparam name="args.action"      type="string"/>
<cfparam name="args.detail"      type="string"/>
<cfparam name="args.datecreated" type="date"/>
<cfparam name="args.known_as"    type="string"/>

<cfscript>
	message = translateResource( uri="cms:auditTrail.#args.action#.message", data=[ arguments.args.detail ] );
</cfscript>

<cfoutput>
	<div class="widget-header widget-header-small">
		<h5 class="widget-title smaller">
			<a href="##" class="blue">#args.known_as#</a>
		</h5>
		<span class="widget-toolbar no-border">
			<i class="fa fa-fw bigger-110 fa-clock-o"></i>
			#TimeFormat( args.datecreated, "HH:mm" )#
		</span>
	</div>

	<div class="widget-body">
		<div class="widget-main">
			#message#
		</div>
	</div>
</cfoutput>