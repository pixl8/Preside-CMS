<!---@feature formbuilder--->
<cfparam name="args.renderedItem" type="string" default="" />
<cfparam name="args.label"        type="string" default="" />

<cfoutput>
	<dt>#args.label#</dt>
	<dd>#args.renderedItem#</dd>
</cfoutput>