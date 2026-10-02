component extends="preside.system.base.AdminHandler" {

	public void function index( event, rc, prc ) {
		event.renderData( data={
			  ok         = true
			, label      = "Category is widgets"
			, expression = [{
				  expression = "presideobject_stringmatches_my_extension_object.category"
				, fields     = { value="widgets", _stringOperator="eq" }
			  }]
		}, type="json" );
	}

}
