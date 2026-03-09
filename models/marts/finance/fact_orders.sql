{{config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'order_id'        
)    

}}

WITH amounts AS (
    SELECT 
        payment_id,
        order_id,
        payment_method,
        payment_status,
        payment_amount,
        payment_created_at
    FROM {{ ref('stg_stripe__payments') }}
    WHERE payment_status = 'success'
),

orders AS(
    SELECT 
        order_id,
        customer_id,
        order_status,
        order_placed_at
    FROM {{ ref('stg_jaffle_shop__orders') }}
),

customers AS(
    SELECT 
        customer_id,
        customer_first_name,
        customer_last_name
    FROM {{ ref('stg_jaffle_shop__customers') }}
),

final AS (
    SELECT 
        o.order_id,
        o.customer_id,
        c.customer_first_name,
        c.customer_last_name,
        o.order_placed_at,
        o.order_status,
        a.payment_id,
        a.payment_method,
        a.payment_amount,
        a.payment_created_at
    FROM orders o
    LEFT JOIN amounts a ON o.order_id = a.order_id
    LEFT JOIN customers c ON o.customer_id = c.customer_id
)

SELECT * FROM final
{% if is_incremental()%}
where order_placed_at > (select max(order_placed_at) from {{this}})
{% endif %}