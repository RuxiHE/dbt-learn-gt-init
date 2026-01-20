-- this macro converts a column of cent to dollar and rounds the result at a desired decimal. 
{%- macro cents_to_dollars(column_name, decimals=2) -%}
    ROUND(1.0 * {{ column_name }}/100, {{  decimals }})
{%- endmacro -%}