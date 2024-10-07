/**
 * @feature rulesEngine
 */
component {

	property name="rulesEngineFilterService" inject="rulesEngineFilterService";

	private array function _selectFields( event, rc, prc ) {
		return [
			  "condition_name"
			, "is_locked"
			, "kind"
			, "applies_to"
			, "is_segmentation_filter"
			, "parent_segmentation_filter"
		];
	}

	private string function _orderBy( event, rc, prc ) {
		return "kind,is_segmentation_filter desc,condition_name";
	}

	private string function _renderLabel(
		  condition_name             = ""
		, is_locked                  = false
		, kind                       = ""
		, applies_to                 = ""
		, is_segmentation_filter     = false
		, parent_segmentation_filter = ""
	) {
		var lockClass = IsTrue( arguments.is_locked ) ? "fa-lock red"    : "fa-lock-open light-grey";
		var typeClass = arguments.kind == "filter"    ? "fa-filter grey" : "fa-map-signs blue";

		if ( isTrue( arguments.is_segmentation_filter ) ) {
			typeClass = "fa-sitemap grey";

			if ( !IsEmpty( arguments.parent_segmentation_filter ) ) {
				var lineage = rulesEngineFilterService.getLineageLabels( arguments.parent_segmentation_filter );
				for( var parent in lineage ) {
					arguments.condition_name = parent.label & " / " & arguments.condition_name;
				}
			}
		}

		var appliesTo = renderContent( renderer="rulesEngineAppliesTo", data={ data=arguments.applies_to, kind=arguments.kind }, context="picker" );

		return '<i class="fa fa-fw #lockClass#"></i><i class="fa fa-fw #typeClass#"></i> #arguments.condition_name# (#appliesTo# )';
	}

}