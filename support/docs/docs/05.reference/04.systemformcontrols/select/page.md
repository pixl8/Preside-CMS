---
id: formcontrol-select
title: "Form control: Select"
---

The `select` control allows the user to select either a single or multiple items for an array of values and optional labels, offering a text search feature to quickly find items for selection.

### Arguments


<div class="table-responsive">
    <table class="table">
        <tbody>
            <tr>
                <th>values (required)</th>
                <td>Either an array or comma separated list of values for the select list</td>
            </tr>
            <tr>
                <th>labels (optional)</th>
                <td>Either a comma separated list or array of labels that correspond with the values for each item in the list (must be same length as the values list/array). If not supplied, the values will be used for the labels. Can also be i18n resource URIs</td>
            </tr>
            <tr>
                <th>multiple (optional)</th>
                <td>True or false (default). Whether or not multiple selection is enabled</td>
            </tr>
            <tr>
                <th>sortable (optional)</th>
                <td>True or false (default). Whether or not select items can be sorted (only relevant when multiple is true)</td>
            </tr>
            <tr>
                <th>addMissingValues (optional)</th>
                <td>True or false (default). If the control is being rendered with a pre-selected saved value, and the value is not already present in the provided values list/array - this option allows the saved value to be added to the list</td>
            </tr>
        </tbody>
    </table>
</div>

### Example

```xml
<field name="colours" values="red,blue,aquamarine" labels="colours:red,colours:blue,colours:aquamarine" multiple="true" />
```

### "Extending" the control

The `select` control is particularly useful for extending to make more specific controls that dynamically generate their values and labels. For example, the [[formcontrol-derivativePicker|Derivative picker control]]. This can be done easily by creating a form control that uses a handler based viewlet:

```luceescript
component {

	property name="assetManagerService"  inject="assetManagerService";

	public string function index( event, rc, prc, args={} ) {
		// Dynamically build args.labels and args.values
		var derivatives   = assetManagerService.listEditorDerivatives();

		args.labels       = [ translateResource( "derivatives:none.title" ) ];
		args.values       = [ "none" ];
		args.extraClasses = "derivative-select-option";

		if ( !derivatives.len() ) {
		    return "";
		}

		for( var derivative in derivatives ) {
		    args.values.append( derivative );
			args.labels.append( translateResource( uri="derivatives:#derivative#.title", defaultValue="derivatives:#derivative#.title" ) );
		}

		// send them to select control's view directly
		return renderView( view="formcontrols/select/index", args=args );
	}
}
```
