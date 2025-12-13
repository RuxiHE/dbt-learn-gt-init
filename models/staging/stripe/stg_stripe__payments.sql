with source as (

    select * from {{ source('stripe', 'payment') }}

),

renamed as (

    select
        id as payment_id,
        orderid as order_id,
        paymentmethod as payment_method,
        status,
        -- amount stored in cent, convert it into dollar.
        amount / 100 as amount,
        created as date_creation_payment

    from source

)

select * from renamed