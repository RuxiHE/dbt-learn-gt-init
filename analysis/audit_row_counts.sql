{% set old_etl_relation=ref('customer_orders_legacy') %} 

{% set dbt_relation=ref('fact_customers_orders') %} 

{{ audit_helper.compare_row_counts(
        a_relation=old_etl_relation,
        b_relation=dbt_relation
    ) }}

