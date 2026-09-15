-- Cartoes de credito. cardtype e o corte que o briefing pede.
--
-- cardnumber fica de fora: nao e usado em nenhuma pergunta, e e o tipo de
-- campo que o referencial (2.5) trata como sensivel mesmo em dado fictício.
-- rowguid nao existe nesta tabela.

with

source as (

    select * from {{ source('adventure_works', 'creditcard') }}

)

, renamed as (

    select
        creditcardid as credit_card_id
        , cardtype as card_type
        , expmonth as expiration_month
        , expyear as expiration_year
        , modifieddate as modified_at
    from source

)

select * from renamed