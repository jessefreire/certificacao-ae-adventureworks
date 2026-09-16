-- Dimensao de cartao de credito, pronta para o Power BI. Seleciona do int_,
-- que ja acrescentou o membro "Sem cartao".

with

int_credit_card as (

    select * from {{ ref('int_adventure_works__creditcard') }}

)

, final as (

    select
        credit_card_id as credit_card_key
        , card_type
    from int_credit_card

)

select * from final