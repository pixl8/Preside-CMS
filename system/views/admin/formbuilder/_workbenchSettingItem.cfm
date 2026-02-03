<!---@feature admin and formbuilder--->
<cfparam name="args.formId"       type="string" />
<cfparam name="args.itemTitle"    type="string" />
<cfparam name="args.itemSubTitle" type="string" default="" />
<cfparam name="args.iconClass"    type="string" />
<cfoutput>
	<li class="item-type form-item item-type-setting">
		<div class="pull-left">
			<i class="fa fa-fw #args.iconClass#"></i>&nbsp;
			#args.itemTitle# #args.itemSubTitle#
		</div>
		<div class="pull-right">
			<span class="item-type-name">#args.itemTitle#</span>
			<div class="action-buttons btn-group">
				<a href="#event.buildAdminLink( linkTo='formbuilder.editForm', queryString='id=#args.formId#' )#" >
					<i class="fa fa-pencil"></i>
				</a>
			</div>
		</div>
		<div class="clearfix"></div>
	</li>
</cfoutput>