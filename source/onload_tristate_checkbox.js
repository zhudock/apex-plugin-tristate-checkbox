function onload_tristate_checkbox(checkbox_element, options) {
    var checkbox_item = apex.jQuery("#" + checkbox_element),
        value_item = apex.jQuery("#" + checkbox_element + "_HIDDEN");

    checkbox_item.addClass('tristate').removeAttr('value').tristate({
        value: options.value,
        state: options.state,
        checked: options.checked,
        unchecked: options.unchecked,
        indeterminate: options.indeterminate
    });

    function change_value() {
        value_item.val(checkbox_item.val());
    }
    apex.jQuery("#" + checkbox_element).change(change_value);
    apex.jQuery(document).bind("apexbeforepagesubmit", change_value);
    apex.widget.initPageItem(checkbox_element, {
        setValue: function(val) {
            checkbox_item.attr("checked", (val === options.checked));
            change_value();
        },
        getValue: function() {
            return value_item.val();
        }
    })
};
