-- Dimensao de datas, gerada por dbt_utils.date_spine — sem staging de
-- origem, padrao da casa (ADR013, documento 2.3) do referencial). Cobre os
-- anos completos de 2011 a 2014, a janela das vendas (mai/2011 a jun/2014).
--
-- is_full_year marca 2012 e 2013 como anos completos: 2011 comeca em maio
-- e 2014 termina em junho, entao comparacao ano a ano sobre eles engana.

with

date_spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2011-01-01' as date)",
        end_date="cast('2015-01-01' as date)"
    ) }}

)

, com_atributos as (

    select
        cast(date_day as date) as date_day
        , extract(year from date_day) as year
        , extract(month from date_day) as month
        , case extract(month from date_day)
            when 1 then 'Janeiro'
            when 2 then 'Fevereiro'
            when 3 then 'Março'
            when 4 then 'Abril'
            when 5 then 'Maio'
            when 6 then 'Junho'
            when 7 then 'Julho'
            when 8 then 'Agosto'
            when 9 then 'Setembro'
            when 10 then 'Outubro'
            when 11 then 'Novembro'
            when 12 then 'Dezembro'
        end as month_name
        , extract(quarter from date_day) as quarter
        , extract(year from date_day) in (2012, 2013) as is_full_year
    from date_spine

)

select * from com_atributos