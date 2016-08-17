function render_tristate_checkbox (
  p_item                in apex_plugin.t_page_item,
  p_plugin              in apex_plugin.t_plugin,
  p_value               in varchar2,
  p_is_readonly         in boolean,
  p_is_printer_friendly in boolean )
  return apex_plugin.t_page_item_render_result
as
  l_html varchar2(32767); -- Dummy variable to store HTML
  l_input_name varchar2(30);
  l_result apex_plugin.t_page_item_render_result; -- Result object to be returned

  -- %PLUGIN_ATTRIBUTES%
  -- Use named variables instead of the generic attribute variables
  l_checked_value    varchar2(255)  := nvl(p_item.attribute_01, 'Y');
  l_unchecked_value  varchar2(255)  := p_item.attribute_02;
  l_indeterminate_value  varchar2(255)  := p_item.attribute_03;
  l_inline_label    varchar2(4000) := p_item.attribute_04;
  -- %ITEM_ATTRIBUTES%
  l_value            varchar2(255);
  l_state            boolean;
  l_checkbox_postfix varchar2(8);
begin
  -- if the current value doesn't match an attribute defined value
  -- fallback to the unchecked value
  if p_value in (l_checked_value, l_indeterminate_value, l_unchecked_value) then
      l_value := p_value;
  else
      l_value := l_unchecked_value;
  end if;

  -- set state based on value
  l_state := CASE l_value WHEN l_checked_value THEN true WHEN l_unchecked_value THEN false WHEN l_indeterminate_value THEN null ELSE false END;
  if p_is_readonly or p_is_printer_friendly then
    -- if the checkbox is readonly we will still render a hidden field with
    -- the value so that it can be used when the page gets submitted
    apex_plugin_util.print_hidden_if_readonly (
        p_item_name           => p_item.name,
        p_value               => p_value,
        p_is_readonly         => p_is_readonly,
        p_is_printer_friendly => p_is_printer_friendly );
    l_checkbox_postfix := '_DISPLAY';

    -- -- print the display span with the value
    -- apex_plugin_util.print_display_only (
    --   p_item_name => p_item.name,
    --   p_display_value => p_value,
    --   p_show_line_breaks => false,
    --   p_escape => true, -- this is recommended to help prevent XSS
    --   p_attributes => p_item.element_attributes);

    -- Tell APEX that this field is NOT navigable
    l_result.is_navigable := false;
  else
    l_input_name := apex_plugin.get_input_name_for_page_item(false);

    -- create hidden field to store checkbox value
    l_html := '<input type="hidden" id="%ID%_HIDDEN" name="%NAME%" value="%VALUE%" />';
    l_html := replace(l_html, '%ID%', p_item.name);
    l_html := replace(l_html, '%NAME%', l_input_name);
    l_html := replace(l_html, '%VALUE%', l_value);
    sys.htp.prn (l_html);

    -- Include the jQuery.Tristate plugin
    apex_javascript.add_library (
        p_name      => 'jquery.tristate',
        p_directory => p_plugin.file_prefix,
        p_version   => null );

    -- Load file containing simple call to initialize the item
    apex_javascript.add_library (
        p_name      => 'onload_tristate_checkbox',
        p_directory => p_plugin.file_prefix,
        p_version   => null );

    -- Add onload code to execute the initialize defined above
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

  -- create tristate checkbox field
  l_html := '<input type="checkbox" id="%ID%" value="%VALUE%" '||
            'checkedvalue="%CHECKEDVALUE%" uncheckedvalue="%UNCHECKEDVALUE%" indeterminatevalue="%INDETERMINATEVALUE%" '||
            '%CHECKEDATTRIB%%DISABLEDATTRIB%%ELEMENTATTRIB% />';
  l_html := replace(l_html, '%ID%', p_item.name||l_checkbox_postfix);
  l_html := replace(l_html, '%NAME%', l_input_name);
  l_html := replace(l_html, '%VALUE%', l_value);
  l_html := replace(l_html, '%CHECKEDVALUE%', l_checked_value);
  l_html := replace(l_html, '%UNCHECKEDVALUE%', l_unchecked_value);
  l_html := replace(l_html, '%INDETERMINATEVALUE%', l_indeterminate_value);
  l_html := replace(l_html, '%CHECKEDATTRIB%', case when l_value = l_checked_value then 'checked="checked" ' end);
  l_html := replace(l_html, '%DISABLEDATTRIB%', case when p_is_readonly or p_is_printer_friendly then 'disabled="disabled" ' end);
  l_html := replace(l_html, '%ELEMENTATTRIB%', coalesce(p_item.element_attributes, 'class="tristate"'));
  sys.htp.prn (l_html);

  -- create label field if inline checkbox label is set
  if l_inline_label is not null then
    l_html := '<label for="%ID%">%INLINELABEL%</label>';
    l_html := replace(l_html, '%ID%', p_item.name||l_checkbox_postfix);
    l_html := replace(l_html, '%INLINELABEL%', l_inline_label);
    sys.htp.prn (l_html);
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
