-- Cartao de credito com o membro "Sem cartao" (-1), para os 1.131 pedidos
-- que nao tem cartao registrado. Sem esse membro, filtrar por cartao
-- apagaria esses pedidos de qualquer visual.

with

credit_cards as (

    select * from {{ ref('stg_adventure_works__creditcard') }}

)

, com_membro_desconhecido as (

    select
        credit_card_id
        , card_type
    from credit_cards

    union all

    select
        -1 as credit_card_id
        , 'Sem cartao' as card_type

)

select * from com_membro_desconhecido