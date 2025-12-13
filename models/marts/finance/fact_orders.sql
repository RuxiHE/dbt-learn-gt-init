WITH amounts AS (
    SELECT 
        payment_id,
        order_id,
        payment_method,
        status,
        amount,
        date_creation_payment
    FROM {{ ref('stg_stripe__payments') }}
    WHERE status = 'success'
),

orders AS(
    SELECT 
        order_id,
        customer_id,
        status as order_status,
        order_date
    FROM {{ ref('stg_jaffle_shop__orders') }}
),

customers AS(
    SELECT 
        customer_id,
        first_name,
        last_name
    FROM {{ ref('stg_jaffle_shop__customers') }}
),

final AS (
    SELECT 
        o.order_id,
        o.customer_id,
        c.first_name,
        c.last_name,
        o.order_date,
        o.order_status,
        a.payment_id,
        a.payment_method,
        a.amount,
        a.date_creation_payment
    FROM orders o
    LEFT JOIN amounts a ON o.order_id = a.order_id
    LEFT JOIN customers c ON o.customer_id = c.customer_id
)

SELECT * FROM final