with 
-- import ctes
customers as(

    select * from {{ ref('stg_jaffle_shop__customers')}}

),

orders as(
    
    select * from {{ ref('stg_jaffle_shop__orders')}}

),

payments as(

    select * from {{ ref('stg_stripe__payments')}}
        
),

-- logical ctes
total_amounts_per_order as(
    select 
        order_id, 
        max(payment_created_at) as payment_finalized_date, 
        sum(payment_amount) as total_amount_paid
    from payments
    where payment_status <> 'fail'
    group by 1
),

customer_orders as(
     select 
        c.customer_id,
        min(order_placed_at) as first_order_date,
        max(order_placed_at) as most_recent_order_date,
        count(orders.order_id) as number_of_orders
    from customers c 
    left join orders
        on orders.customer_id = c.customer_id 
    group by 1
),

-- final cte
final as (
    select 
        orders.order_id,
        c.customer_id,
        orders.order_placed_at,
        orders.order_status,
        p.total_amount_paid,
        p.payment_finalized_date,
        
        c.customer_first_name,
        c.customer_last_name
    from orders as orders
    left join total_amounts_per_order p 
        on orders.order_id = p.order_id
    left join customers c 
        on orders.customer_id = c.customer_id 
)

select * from final