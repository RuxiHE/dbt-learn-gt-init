with payment as(
    select * from {{ ref('stg_stripe__payments') }}
)

select sum(payment_amount)
from payment
where payment_status = 'success'