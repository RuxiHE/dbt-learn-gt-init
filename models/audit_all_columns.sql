{% set old_etl_relation = adapter.get_relation(
      database = target.database,
      schema = target.schema,
      identifier = "customer_orders_legacy"
) -%}

{% set old_etl_relation = adapter.get_relation(
      database = target.database,
      schema = target.schema,
      identifier = "fact_customers_orders"
) -%}


{% if execute %}
{{ audit_helper.compare_all_columns(
        a_relation=old_etl_relation,
        b_relation=dbt_relation,
        primary_key="order_id"
    ) }}
{% endif %}