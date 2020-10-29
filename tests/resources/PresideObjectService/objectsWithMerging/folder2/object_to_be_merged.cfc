component output=false {
	property name="somepropertytobedeleted" deleted=true;
	property name="propertyWhosTypeWillChange" type="numeric";
	property name="addedProperty";

	public function functionToBeOverrided() output=false {
		return "changed";
	}

	public function addedFunction() output=false {
		return _privateAddedFunction();
	}

	private function _privateAddedFunction() output=false {
		return "private function result";
	}
}