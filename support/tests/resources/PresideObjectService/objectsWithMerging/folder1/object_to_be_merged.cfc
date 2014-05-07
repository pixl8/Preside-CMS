component output=false versioned="false" {
	property name="somepropertytobedeleted";
	property name="propertyThatWillBePreserved";
	property name="propertyWhosTypeWillChange" type="boolean";

	public function functionToBeOverrided() output=false {
		return "original";
	}

	public function functionToBePreserved() output=false {
		return "I was preserved";
	}
}