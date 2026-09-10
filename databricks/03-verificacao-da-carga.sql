-- Verificacao da carga do AdventureWorks
-- Rodar DEPOIS do 02-carga e ANTES de qualquer analise. Se algo aqui falhar,
-- todo numero da exploracao fica suspeito.
--
-- Os valores "esperado" vem da contagem de linhas dos proprios arquivos de
-- origem, medida localmente.
--
-- A conferencia 1 marca cada tabela como `analise` (uma das 17 que as perguntas
-- do briefing usam) ou `camada bruta`. Serve para ler o resultado num estado de
-- carga parcial: se a cota da Free Edition interromper a carga, `nao carregada`
-- na camada bruta e esperado, mas na analise e bloqueio.
--
-- As conferencias 2 a 5 dependem so das 17 do escopo da analise.

/* ------------------------------------------------------------------------
   1. Contagem por tabela: o que chegou e igual ao que saiu do arquivo?
   ------------------------------------------------------------------------ */
with contagem as (
    select
        'businessentity' as tabela
        , 'camada bruta' as escopo
        , 20777 as esperado
        , count(*) as carregado
    from workspace.adventure_works.businessentity
    union all
    select
        'person' as tabela
        , 'analise' as escopo
        , 19972 as esperado
        , count(*) as carregado
    from workspace.adventure_works.person
    union all
    select
        'stateprovince' as tabela
        , 'analise' as escopo
        , 181 as esperado
        , count(*) as carregado
    from workspace.adventure_works.stateprovince
    union all
    select
        'address' as tabela
        , 'analise' as escopo
        , 19614 as esperado
        , count(*) as carregado
    from workspace.adventure_works.address
    union all
    select
        'addresstype' as tabela
        , 'camada bruta' as escopo
        , 6 as esperado
        , count(*) as carregado
    from workspace.adventure_works.addresstype
    union all
    select
        'businessentityaddress' as tabela
        , 'camada bruta' as escopo
        , 19614 as esperado
        , count(*) as carregado
    from workspace.adventure_works.businessentityaddress
    union all
    select
        'contacttype' as tabela
        , 'camada bruta' as escopo
        , 20 as esperado
        , count(*) as carregado
    from workspace.adventure_works.contacttype
    union all
    select
        'businessentitycontact' as tabela
        , 'camada bruta' as escopo
        , 909 as esperado
        , count(*) as carregado
    from workspace.adventure_works.businessentitycontact
    union all
    select
        'emailaddress' as tabela
        , 'camada bruta' as escopo
        , 19972 as esperado
        , count(*) as carregado
    from workspace.adventure_works.emailaddress
    union all
    select
        'password' as tabela
        , 'camada bruta' as escopo
        , 19972 as esperado
        , count(*) as carregado
    from workspace.adventure_works.password
    union all
    select
        'phonenumbertype' as tabela
        , 'camada bruta' as escopo
        , 3 as esperado
        , count(*) as carregado
    from workspace.adventure_works.phonenumbertype
    union all
    select
        'personphone' as tabela
        , 'camada bruta' as escopo
        , 19972 as esperado
        , count(*) as carregado
    from workspace.adventure_works.personphone
    union all
    select
        'countryregion' as tabela
        , 'analise' as escopo
        , 238 as esperado
        , count(*) as carregado
    from workspace.adventure_works.countryregion
    union all
    select
        'department' as tabela
        , 'camada bruta' as escopo
        , 16 as esperado
        , count(*) as carregado
    from workspace.adventure_works.department
    union all
    select
        'employee' as tabela
        , 'camada bruta' as escopo
        , 290 as esperado
        , count(*) as carregado
    from workspace.adventure_works.employee
    union all
    select
        'employeedepartmenthistory' as tabela
        , 'camada bruta' as escopo
        , 296 as esperado
        , count(*) as carregado
    from workspace.adventure_works.employeedepartmenthistory
    union all
    select
        'employeepayhistory' as tabela
        , 'camada bruta' as escopo
        , 316 as esperado
        , count(*) as carregado
    from workspace.adventure_works.employeepayhistory
    union all
    select
        'jobcandidate' as tabela
        , 'camada bruta' as escopo
        , 13 as esperado
        , count(*) as carregado
    from workspace.adventure_works.jobcandidate
    union all
    select
        'shift' as tabela
        , 'camada bruta' as escopo
        , 3 as esperado
        , count(*) as carregado
    from workspace.adventure_works.shift
    union all
    select
        'billofmaterials' as tabela
        , 'camada bruta' as escopo
        , 2679 as esperado
        , count(*) as carregado
    from workspace.adventure_works.billofmaterials
    union all
    select
        'culture' as tabela
        , 'camada bruta' as escopo
        , 8 as esperado
        , count(*) as carregado
    from workspace.adventure_works.culture
    union all
    select
        'productcategory' as tabela
        , 'analise' as escopo
        , 4 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productcategory
    union all
    select
        'productsubcategory' as tabela
        , 'analise' as escopo
        , 37 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productsubcategory
    union all
    select
        'productmodel' as tabela
        , 'camada bruta' as escopo
        , 128 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productmodel
    union all
    select
        'product' as tabela
        , 'analise' as escopo
        , 504 as esperado
        , count(*) as carregado
    from workspace.adventure_works.product
    union all
    select
        'productcosthistory' as tabela
        , 'camada bruta' as escopo
        , 395 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productcosthistory
    union all
    select
        'productdescription' as tabela
        , 'camada bruta' as escopo
        , 762 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productdescription
    union all
    select
        'productdocument' as tabela
        , 'camada bruta' as escopo
        , 32 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productdocument
    union all
    select
        'location' as tabela
        , 'camada bruta' as escopo
        , 14 as esperado
        , count(*) as carregado
    from workspace.adventure_works.location
    union all
    select
        'productinventory' as tabela
        , 'camada bruta' as escopo
        , 1069 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productinventory
    union all
    select
        'productlistpricehistory' as tabela
        , 'camada bruta' as escopo
        , 395 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productlistpricehistory
    union all
    select
        'illustration' as tabela
        , 'camada bruta' as escopo
        , 5 as esperado
        , count(*) as carregado
    from workspace.adventure_works.illustration
    union all
    select
        'productmodelillustration' as tabela
        , 'camada bruta' as escopo
        , 7 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productmodelillustration
    union all
    select
        'productmodelproductdescriptionculture' as tabela
        , 'camada bruta' as escopo
        , 762 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productmodelproductdescriptionculture
    union all
    select
        'productproductphoto' as tabela
        , 'camada bruta' as escopo
        , 504 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productproductphoto
    union all
    select
        'scrapreason' as tabela
        , 'camada bruta' as escopo
        , 16 as esperado
        , count(*) as carregado
    from workspace.adventure_works.scrapreason
    union all
    select
        'transactionhistory' as tabela
        , 'camada bruta' as escopo
        , 113443 as esperado
        , count(*) as carregado
    from workspace.adventure_works.transactionhistory
    union all
    select
        'transactionhistoryarchive' as tabela
        , 'camada bruta' as escopo
        , 89253 as esperado
        , count(*) as carregado
    from workspace.adventure_works.transactionhistoryarchive
    union all
    select
        'unitmeasure' as tabela
        , 'camada bruta' as escopo
        , 38 as esperado
        , count(*) as carregado
    from workspace.adventure_works.unitmeasure
    union all
    select
        'workorder' as tabela
        , 'camada bruta' as escopo
        , 72591 as esperado
        , count(*) as carregado
    from workspace.adventure_works.workorder
    union all
    select
        'workorderrouting' as tabela
        , 'camada bruta' as escopo
        , 67131 as esperado
        , count(*) as carregado
    from workspace.adventure_works.workorderrouting
    union all
    select
        'productvendor' as tabela
        , 'camada bruta' as escopo
        , 460 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productvendor
    union all
    select
        'purchaseorderdetail' as tabela
        , 'camada bruta' as escopo
        , 8845 as esperado
        , count(*) as carregado
    from workspace.adventure_works.purchaseorderdetail
    union all
    select
        'purchaseorderheader' as tabela
        , 'camada bruta' as escopo
        , 4012 as esperado
        , count(*) as carregado
    from workspace.adventure_works.purchaseorderheader
    union all
    select
        'shipmethod' as tabela
        , 'camada bruta' as escopo
        , 5 as esperado
        , count(*) as carregado
    from workspace.adventure_works.shipmethod
    union all
    select
        'vendor' as tabela
        , 'camada bruta' as escopo
        , 104 as esperado
        , count(*) as carregado
    from workspace.adventure_works.vendor
    union all
    select
        'countryregioncurrency' as tabela
        , 'camada bruta' as escopo
        , 109 as esperado
        , count(*) as carregado
    from workspace.adventure_works.countryregioncurrency
    union all
    select
        'creditcard' as tabela
        , 'analise' as escopo
        , 19118 as esperado
        , count(*) as carregado
    from workspace.adventure_works.creditcard
    union all
    select
        'currency' as tabela
        , 'camada bruta' as escopo
        , 105 as esperado
        , count(*) as carregado
    from workspace.adventure_works.currency
    union all
    select
        'currencyrate' as tabela
        , 'camada bruta' as escopo
        , 13532 as esperado
        , count(*) as carregado
    from workspace.adventure_works.currencyrate
    union all
    select
        'customer' as tabela
        , 'analise' as escopo
        , 19820 as esperado
        , count(*) as carregado
    from workspace.adventure_works.customer
    union all
    select
        'personcreditcard' as tabela
        , 'camada bruta' as escopo
        , 19118 as esperado
        , count(*) as carregado
    from workspace.adventure_works.personcreditcard
    union all
    select
        'salesorderdetail' as tabela
        , 'analise' as escopo
        , 121317 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesorderdetail
    union all
    select
        'salesorderheader' as tabela
        , 'analise' as escopo
        , 31465 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesorderheader
    union all
    select
        'salesorderheadersalesreason' as tabela
        , 'analise' as escopo
        , 27647 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesorderheadersalesreason
    union all
    select
        'salesperson' as tabela
        , 'analise' as escopo
        , 17 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesperson
    union all
    select
        'salespersonquotahistory' as tabela
        , 'camada bruta' as escopo
        , 163 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salespersonquotahistory
    union all
    select
        'salesreason' as tabela
        , 'analise' as escopo
        , 10 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesreason
    union all
    select
        'salestaxrate' as tabela
        , 'camada bruta' as escopo
        , 29 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salestaxrate
    union all
    select
        'salesterritory' as tabela
        , 'analise' as escopo
        , 10 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesterritory
    union all
    select
        'salesterritoryhistory' as tabela
        , 'camada bruta' as escopo
        , 17 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesterritoryhistory
    union all
    select
        'shoppingcartitem' as tabela
        , 'camada bruta' as escopo
        , 3 as esperado
        , count(*) as carregado
    from workspace.adventure_works.shoppingcartitem
    union all
    select
        'specialoffer' as tabela
        , 'analise' as escopo
        , 16 as esperado
        , count(*) as carregado
    from workspace.adventure_works.specialoffer
    union all
    select
        'specialofferproduct' as tabela
        , 'camada bruta' as escopo
        , 538 as esperado
        , count(*) as carregado
    from workspace.adventure_works.specialofferproduct
    union all
    select
        'store' as tabela
        , 'analise' as escopo
        , 701 as esperado
        , count(*) as carregado
    from workspace.adventure_works.store
)

select
    tabela
    , escopo
    , esperado
    , carregado
    , case
        when esperado = carregado then 'ok'
        when carregado = 0 then 'nao carregada'
        else 'DIVERGE'
    end as resultado
from contagem
order by escopo asc, resultado desc, tabela asc;


/* ------------------------------------------------------------------------
2. As sete juncoes que a analise usa: alguma tem orfao?
Todas deram zero nos arquivos; se der diferente aqui, a carga errou.
------------------------------------------------------------------------ */
select
    'pedido -> address' as juncao
    , count(*) as orfaos
from workspace.adventure_works.salesorderheader
left join workspace.adventure_works.address
    on salesorderheader.billtoaddressid = address.addressid
where address.addressid is null

union all

select
    'pedido -> customer' as juncao
    , count(*) as orfaos
from workspace.adventure_works.salesorderheader
left join workspace.adventure_works.customer
    on salesorderheader.customerid = customer.customerid
where customer.customerid is null

union all

select
    'pedido -> salesterritory' as juncao
    , count(*) as orfaos
from workspace.adventure_works.salesorderheader
left join workspace.adventure_works.salesterritory
    on salesorderheader.territoryid = salesterritory.territoryid
where salesterritory.territoryid is null

union all

select
    'pedido -> creditcard (so quem tem cartao)' as juncao
    , count(*) as orfaos
from workspace.adventure_works.salesorderheader
left join workspace.adventure_works.creditcard
    on salesorderheader.creditcardid = creditcard.creditcardid
where salesorderheader.creditcardid is not null
    and creditcard.creditcardid is null

union all

select
    'item -> product' as juncao
    , count(*) as orfaos
from workspace.adventure_works.salesorderdetail
left join workspace.adventure_works.product
    on salesorderdetail.productid = product.productid
where product.productid is null

union all

select
    'item -> specialoffer' as juncao
    , count(*) as orfaos
from workspace.adventure_works.salesorderdetail
left join workspace.adventure_works.specialoffer
    on salesorderdetail.specialofferid = specialoffer.specialofferid
where specialoffer.specialofferid is null

union all

select
    'cliente -> nome (person ou store)' as juncao
    , count(*) as orfaos
from workspace.adventure_works.customer
left join workspace.adventure_works.person
    on customer.personid = person.businessentityid
left join workspace.adventure_works.store
    on customer.storeid = store.businessentityid
where person.businessentityid is null
    and store.businessentityid is null;


/* ------------------------------------------------------------------------
3. O NULL sobreviveu a carga?
27.659 pedidos nao tem vendedor. Se aparecer 0 em vez de NULL, o
nullValue do COPY INTO nao pegou e a analise de canal fica errada.
------------------------------------------------------------------------ */
select
    count(*) as pedidos
    , count(salespersonid) as com_vendedor
    , sum(case when salespersonid = 0 then 1 else 0 end) as vendedor_zero_suspeito
    , count(*) - count(salespersonid) as sem_vendedor_esperado_27659
from workspace.adventure_works.salesorderheader;


/* ------------------------------------------------------------------------
   4. O teste de aceite do CEO

      Tem de dar 12646112.16 em centavos. A soma exata e 12646112.1607: o
      unitprice tem 4 casas decimais e 2.832 dos 5.642 itens de 2011 usam as
      quatro. O briefing informa o numero ja arredondado, entao a comparacao e
      com round(soma, 2) — comparar com igualdade exata contra um literal de
      duas casas nunca poderia fechar, e foi o erro da primeira versao deste
      teste.

A quarta casa e justamente o que se perderia com double: 2.832
multiplicacoes de preco com 4 decimais acumulam residuo binario, e o
arredondamento pode cair para .15 ou .17. Com decimal(19, 4) a soma bate
digito por digito com a aritmetica exata medida nos arquivos de origem.
------------------------------------------------------------------------ */
select
    12646112.16 as esperado_em_centavos
    , 12646112.1607 as esperado_exato
    , sum(salesorderdetail.unitprice * salesorderdetail.orderqty) as receita_bruta_2011
    , case
        when round(sum(salesorderdetail.unitprice * salesorderdetail.orderqty), 2)
            = 12646112.16
            then 'FECHA'
        else 'DIVERGE'
    end as resultado
from workspace.adventure_works.salesorderdetail
inner join workspace.adventure_works.salesorderheader
    on salesorderdetail.salesorderid = salesorderheader.salesorderid
where year(salesorderheader.orderdate) = 2011;


/* ------------------------------------------------------------------------
5. A integridade do linetotal
Nesta porta o campo NAO e calculado pelo banco. A identidade vale nas
121.317 linhas do arquivo; aqui confirmamos que a carga preservou.
------------------------------------------------------------------------ */
select
    count(*) as linhas
    , sum(
        case
            when abs(
                salesorderdetail.unitprice
                * (1 - salesorderdetail.unitpricediscount)
                * salesorderdetail.orderqty
                - salesorderdetail.linetotal
            ) > 0.01 then 1
            else 0
        end
    ) as fora_de_um_centavo
from workspace.adventure_works.salesorderdetail;
