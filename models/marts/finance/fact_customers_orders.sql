with 
-- import ctes
raw_orders as(
    select * from {{source('jaffle_shop', 'orders')}}
),

raw_payments as(
    select * from {{source('stripe','payment')}}
),

raw_customers as(
    select * from {{source('jaffle_shop', 'customers')}} 
),

-- logical ctes
total_amounts_per_order as(
    select orderid as order_id, 
        max(created) as payment_finalized_date, 
        sum(amount) / 100.0 as total_amount_paid
    from raw_payments
    where status <> 'fail'
    group by 1
),

paid_orders as (
    select orders.id as order_id,
        orders.user_id as customer_id,
        orders.order_date as order_placed_at,
        orders.status as order_status,
        p.total_amount_paid,
        p.payment_finalized_date,
        c.first_name as customer_first_name,
        c.last_name as customer_last_name
    from raw_orders as orders
    left join total_amounts_per_order p 
        on orders.id = p.order_id
    left join raw_customers c 
        on orders.user_id = c.id 
),

customer_orders as 
    (select c.id as customer_id
        , min(order_date) as first_order_date
        , max(order_date) as most_recent_order_date
        , count(orders.id) as number_of_orders
    from raw_customers c 
    left join raw_orders as orders
        on orders.user_id = c.id 
    group by 1),

customer_life_time_values as(
    select
            p.order_id,
            sum(t2.total_amount_paid) as clv_bad
        from paid_orders p
        left join paid_orders t2 
            on p.customer_id = t2.customer_id and p.order_id >= t2.order_id
        group by 1
        order by p.order_id
),

-- final cte
final as (
    select
        p.*,
        row_number() over (order by p.order_id) as transaction_seq,
        row_number() over (partition by p.customer_id order by p.order_id asc) as customer_sales_seq,
        case 
            when (
            rank() over(
                    partition by p.customer_id 
                    order by p.order_placed_at, p.order_id
                    )=1
            ) then 'new'
            else 'return' end as nvsr,
        x.clv_bad as customer_lifetime_value,
        first_value(o.order_date) over(
            partition by p.customer_id 
            order by p.order_id asc
        )as fdos
    from paid_orders p
    left join raw_orders o on p.customer_id = o.user_id and p.order_id = o.id
    left join customer_life_time_values x on x.order_id = p.order_id
    order by order_id
)

-- simple select statment
select * from final
