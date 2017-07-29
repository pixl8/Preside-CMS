---
id: formcontrol-filterpicker
title: "Form control: Filter picker"
---

The `filterPicker` control is an [[formcontrol-objectPicker| object picker]] with custom options and interface specific to rules engine filters.

### Arguments

You can use any arguments that can be used with the [[object picker]]. In addition, the control accepts the following attributes:

<div class="table-responsive">
    <table class="table">
        <tbody>
            <tr>
                <th>filterObject (required)</th>
                <td>The target object for the filter</td>
            </tr>
            <tr>
                <th>rulesEngineContextData (optional)</th>
                <td>Struct of data that will be passed to all filter field configuration forms in the quick add / edit filter builder. This allows you to limit choices on fields when creating dynamic filters within specific contexts. As this is a stuct, it can only be injected using `additionalArgs` argument to renderForm().</td>
            </tr>
            <tr>
                <th>preSavedFilters (optional)</th>
                <td>For use with the quick add/edit filter builders. A list of saved filters that will be used additionally filter the "filter count" shown in the filter builder.</td>
            </tr>
            <tr>
                <th>preRulesEngineFilters (optional)</th>
                <td>For use with the quick add/edit filter builders. A list of saved rules engine filter IDs that will be used additionally filter the "filter count" shown in the filter builder.</td>
            </tr>
        </tbody>
    </table>
</div> 

expects a single **required** option, `filterObject` indicating the object that selected / added filters should apply to.


### Example

```xml
<field name="optional_filters" control="filterPicker" filterObject="news" multiple="true" sortable="true"  />
```