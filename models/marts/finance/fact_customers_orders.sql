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

paid_orders as (
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
),

customer_orders as (
    select 
        c.customer_id,
        min(order_placed_at) as first_order_date,
        max(order_placed_at) as most_recent_order_date,
        count(orders.order_id) as number_of_orders
    from customers c 
    left join orders
        on orders.customer_id = c.customer_id 
    group by 1),

-- final cte
final as (
    select
        order_id,
        customer_id,
        order_placed_at,
        order_status,
        total_amount_paid,
        payment_finalized_date,
        customer_first_name,
        customer_last_name, 

        -- sales transaction sequence       
        row_number() over (order by order_id) as transaction_seq,

        -- customer sales sequence
        row_number() over (partition by customer_id order by order_id asc) as customer_sales_seq,
        
        -- new vs returning customer
        case 
            when (
            rank() over(
                    partition by customer_id 
                    order by order_placed_at, order_id
                    )=1
            ) then 'new'
            else 'return' end as nvsr,

        -- customer lifetime value
        sum(total_amount_paid) over(
            partition by customer_id
            order by order_placed_at
        ) as customer_life_time_values,

        -- first day of sale
        first_value(order_placed_at) over(
            partition by customer_id 
            order by order_id asc
        )as fdos

    from paid_orders 
    order by order_id
)

-- simple select statment
select * from final
