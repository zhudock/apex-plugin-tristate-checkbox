--===============================================================================
-- Renders the Tristate Checkbox item type based on the configuration of the page item.
--===============================================================================
function render_tristate_checkbox (
    p_item                in apex_plugin.t_page_item,
    p_plugin              in apex_plugin.t_plugin,
    p_value               in varchar2,
    p_is_readonly         in boolean,
    p_is_printer_friendly in boolean )
    return apex_plugin.t_page_item_render_result
is
    -- Use named variables instead of the generic attribute variables
    l_checked_value    varchar2(255)  := nvl(p_item.attribute_01, 'Y');
    l_unchecked_value  varchar2(255)  := p_item.attribute_02;
    l_indeterminate_value  varchar2(255)  := p_item.attribute_03;
    l_checked_label    varchar2(4000) := p_item.attribute_04;

    l_name             varchar2(30);
    l_value            varchar2(255);
    l_state            boolean;
    l_checkbox_postfix varchar2(8);
    l_result           apex_plugin.t_page_item_render_result;
begin
    -- if the current value doesn't match our checked, indeterminate or unchecked value
    -- we fallback to the unchecked value
    if p_value in (l_checked_value, l_indeterminate_value, l_unchecked_value) then
        l_value := p_value;
    else
        l_value := l_unchecked_value;
    end if;

    -- if the current value doesn't match our checked or indeterminate value
    -- we fallback to the unchecked state
    l_state := CASE l_value WHEN l_checked_value THEN true WHEN l_unchecked_value THEN false WHEN l_indeterminate_value THEN null ELSE false END;

    if p_is_readonly or p_is_printer_friendly then
        -- if the checkbox is readonly we will still render a hidden field with
        -- the value so that it can be used when the page gets submitted
        wwv_flow_plugin_util.print_hidden_if_readonly (
            p_item_name           => p_item.name,
            p_value               => p_value,
            p_is_readonly         => p_is_readonly,
            p_is_printer_friendly => p_is_printer_friendly );
        l_checkbox_postfix := '_DISPLAY';

        -- Tell APEX that this field is NOT navigable
        l_result.is_navigable := false;
    else
        -- If a page item saves state, we have to call the get_input_name_for_page_item
        -- to render the internal hidden p_arg_names field. It will also return the
        -- HTML field name which we have to use when we render the HTML input field.
        l_name := wwv_flow_plugin.get_input_name_for_page_item(false);

        -- render the hidden field which actually stores the checkbox value
        sys.htp.prn (
            '<input type="hidden" id="'||p_item.name||'_HIDDEN" name="'||l_name||'" '||
            'value="'||l_value||'" />');

        -- Add the JavaScript library and the call to initialize the widget
        apex_javascript.add_library (
            p_name      => 'jquery.tristate',
            p_directory => p_plugin.file_prefix,
            p_version   => null );

        -- Add the JavaScript library and the call to initialize the widget
        apex_javascript.add_library (
            p_name      => 'onload_tristate_checkbox',
            p_directory => p_plugin.file_prefix,
            p_version   => null );

        apex_javascript.add_onload_code (
            p_code => 'onload_tristate_checkbox('||
                      apex_javascript.add_value(p_item.name)||
                      '{'||
                      apex_javascript.add_attribute('value', l_value, false)||
                      apex_javascript.add_attribute('state', l_state, false)||
                      apex_javascript.add_attribute('unchecked', l_unchecked_value, false)||
                      apex_javascript.add_attribute('indeterminate', l_indeterminate_value, false)||
                      apex_javascript.add_attribute('checked',   l_checked_value, false, false)||
                      '});' );

        -- Tell APEX that this field is navigable
        l_result.is_navigable := true;
    end if;

    -- render the checkbox widget
    sys.htp.prn (
        '<input type="checkbox" id="'||p_item.name||l_checkbox_postfix||'" '||
        'value="'||l_value||'" '||
        'checkedvalue="'||l_checked_value||'" '||
        'uncheckedvalue="'||l_unchecked_value||'" '||
        'indeterminatevalue="'||l_indeterminate_value||'" '||
        case when l_value = l_checked_value then 'checked="checked" ' end||
        case when p_is_readonly or p_is_printer_friendly then 'disabled="disabled" ' end||
        coalesce(p_item.element_attributes, 'class="tristate_checkbox tristate"')||' />');

    -- print label after checkbox
    if l_checked_label is not null then
        sys.htp.prn('<label for="'||p_item.name||l_checkbox_postfix||'">'||l_checked_label||'</label>');
    end if;

    return l_result;
end render_tristate_checkbox;

--==============================================================================
-- Validates the submitted "Tristate Checkbox" value against the configuration to
-- make sure that invalid values submitted by hackers are detected.
--==============================================================================
function validate_tristate_checkbox (
    p_item   in apex_plugin.t_page_item,
    p_plugin in apex_plugin.t_plugin,
    p_value  in varchar2 )
    return apex_plugin.t_page_item_validation_result
is
    l_checked_value   varchar2(255) := nvl(p_item.attribute_01, 'Y');
    l_unchecked_value varchar2(255) := p_item.attribute_02;
    l_indeterminate_value  varchar2(255)  := p_item.attribute_03;

    l_result          apex_plugin.t_page_item_validation_result;
begin
    if not (   p_value in (l_checked_value, l_unchecked_value, l_indeterminate_value)
            or (p_value is null and (l_unchecked_value is null or l_indeterminate_value is null))
           )
    then
        l_result.message := 'Checkbox contains invalid value!';
    end if;
    return l_result;
end validate_tristate_checkbox;
