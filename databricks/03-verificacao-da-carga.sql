-- Verificacao da carga do AdventureWorks
-- Rodar DEPOIS do 02-carga e ANTES de qualquer analise. Se algo aqui falhar,
-- todo numero da exploracao fica suspeito.
--
-- Os valores "esperado" vem da contagem de linhas dos proprios arquivos de
-- origem, medida localmente.

/* ------------------------------------------------------------------------
   1. Contagem por tabela: o que chegou e igual ao que saiu do arquivo?
   ------------------------------------------------------------------------ */
with contagem as (
    select
        'businessentity' as tabela
        , 20777 as esperado
        , count(*) as carregado
    from workspace.adventure_works.businessentity
    union all
    select
        'person' as tabela
        , 19972 as esperado
        , count(*) as carregado
    from workspace.adventure_works.person
    union all
    select
        'stateprovince' as tabela
        , 181 as esperado
        , count(*) as carregado
    from workspace.adventure_works.stateprovince
    union all
    select
        'address' as tabela
        , 19614 as esperado
        , count(*) as carregado
    from workspace.adventure_works.address
    union all
    select
        'addresstype' as tabela
        , 6 as esperado
        , count(*) as carregado
    from workspace.adventure_works.addresstype
    union all
    select
        'businessentityaddress' as tabela
        , 19614 as esperado
        , count(*) as carregado
    from workspace.adventure_works.businessentityaddress
    union all
    select
        'contacttype' as tabela
        , 20 as esperado
        , count(*) as carregado
    from workspace.adventure_works.contacttype
    union all
    select
        'businessentitycontact' as tabela
        , 909 as esperado
        , count(*) as carregado
    from workspace.adventure_works.businessentitycontact
    union all
    select
        'emailaddress' as tabela
        , 19972 as esperado
        , count(*) as carregado
    from workspace.adventure_works.emailaddress
    union all
    select
        'password' as tabela
        , 19972 as esperado
        , count(*) as carregado
    from workspace.adventure_works.password
    union all
    select
        'phonenumbertype' as tabela
        , 3 as esperado
        , count(*) as carregado
    from workspace.adventure_works.phonenumbertype
    union all
    select
        'personphone' as tabela
        , 19972 as esperado
        , count(*) as carregado
    from workspace.adventure_works.personphone
    union all
    select
        'countryregion' as tabela
        , 238 as esperado
        , count(*) as carregado
    from workspace.adventure_works.countryregion
    union all
    select
        'department' as tabela
        , 16 as esperado
        , count(*) as carregado
    from workspace.adventure_works.department
    union all
    select
        'employee' as tabela
        , 290 as esperado
        , count(*) as carregado
    from workspace.adventure_works.employee
    union all
    select
        'employeedepartmenthistory' as tabela
        , 296 as esperado
        , count(*) as carregado
    from workspace.adventure_works.employeedepartmenthistory
    union all
    select
        'employeepayhistory' as tabela
        , 316 as esperado
        , count(*) as carregado
    from workspace.adventure_works.employeepayhistory
    union all
    select
        'jobcandidate' as tabela
        , 13 as esperado
        , count(*) as carregado
    from workspace.adventure_works.jobcandidate
    union all
    select
        'shift' as tabela
        , 3 as esperado
        , count(*) as carregado
    from workspace.adventure_works.shift
    union all
    select
        'billofmaterials' as tabela
        , 2679 as esperado
        , count(*) as carregado
    from workspace.adventure_works.billofmaterials
    union all
    select
        'culture' as tabela
        , 8 as esperado
        , count(*) as carregado
    from workspace.adventure_works.culture
    union all
    select
        'productcategory' as tabela
        , 4 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productcategory
    union all
    select
        'productsubcategory' as tabela
        , 37 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productsubcategory
    union all
    select
        'productmodel' as tabela
        , 128 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productmodel
    union all
    select
        'product' as tabela
        , 504 as esperado
        , count(*) as carregado
    from workspace.adventure_works.product
    union all
    select
        'productcosthistory' as tabela
        , 395 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productcosthistory
    union all
    select
        'productdescription' as tabela
        , 762 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productdescription
    union all
    select
        'productdocument' as tabela
        , 32 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productdocument
    union all
    select
        'location' as tabela
        , 14 as esperado
        , count(*) as carregado
    from workspace.adventure_works.location
    union all
    select
        'productinventory' as tabela
        , 1069 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productinventory
    union all
    select
        'productlistpricehistory' as tabela
        , 395 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productlistpricehistory
    union all
    select
        'illustration' as tabela
        , 5 as esperado
        , count(*) as carregado
    from workspace.adventure_works.illustration
    union all
    select
        'productmodelillustration' as tabela
        , 7 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productmodelillustration
    union all
    select
        'productmodelproductdescriptionculture' as tabela
        , 762 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productmodelproductdescriptionculture
    union all
    select
        'productproductphoto' as tabela
        , 504 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productproductphoto
    union all
    select
        'scrapreason' as tabela
        , 16 as esperado
        , count(*) as carregado
    from workspace.adventure_works.scrapreason
    union all
    select
        'transactionhistory' as tabela
        , 113443 as esperado
        , count(*) as carregado
    from workspace.adventure_works.transactionhistory
    union all
    select
        'transactionhistoryarchive' as tabela
        , 89253 as esperado
        , count(*) as carregado
    from workspace.adventure_works.transactionhistoryarchive
    union all
    select
        'unitmeasure' as tabela
        , 38 as esperado
        , count(*) as carregado
    from workspace.adventure_works.unitmeasure
    union all
    select
        'workorder' as tabela
        , 72591 as esperado
        , count(*) as carregado
    from workspace.adventure_works.workorder
    union all
    select
        'workorderrouting' as tabela
        , 67131 as esperado
        , count(*) as carregado
    from workspace.adventure_works.workorderrouting
    union all
    select
        'productvendor' as tabela
        , 460 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productvendor
    union all
    select
        'purchaseorderdetail' as tabela
        , 8845 as esperado
        , count(*) as carregado
    from workspace.adventure_works.purchaseorderdetail
    union all
    select
        'purchaseorderheader' as tabela
        , 4012 as esperado
        , count(*) as carregado
    from workspace.adventure_works.purchaseorderheader
    union all
    select
        'shipmethod' as tabela
        , 5 as esperado
        , count(*) as carregado
    from workspace.adventure_works.shipmethod
    union all
    select
        'vendor' as tabela
        , 104 as esperado
        , count(*) as carregado
    from workspace.adventure_works.vendor
    union all
    select
        'countryregioncurrency' as tabela
        , 109 as esperado
        , count(*) as carregado
    from workspace.adventure_works.countryregioncurrency
    union all
    select
        'creditcard' as tabela
        , 19118 as esperado
        , count(*) as carregado
    from workspace.adventure_works.creditcard
    union all
    select
        'currency' as tabela
        , 105 as esperado
        , count(*) as carregado
    from workspace.adventure_works.currency
    union all
    select
        'currencyrate' as tabela
        , 13532 as esperado
        , count(*) as carregado
    from workspace.adventure_works.currencyrate
    union all
    select
        'customer' as tabela
        , 19820 as esperado
        , count(*) as carregado
    from workspace.adventure_works.customer
    union all
    select
        'personcreditcard' as tabela
        , 19118 as esperado
        , count(*) as carregado
    from workspace.adventure_works.personcreditcard
    union all
    select
        'salesorderdetail' as tabela
        , 121317 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesorderdetail
    union all
    select
        'salesorderheader' as tabela
        , 31465 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesorderheader
    union all
    select
        'salesorderheadersalesreason' as tabela
        , 27647 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesorderheadersalesreason
    union all
    select
        'salesperson' as tabela
        , 17 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesperson
    union all
    select
        'salespersonquotahistory' as tabela
        , 163 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salespersonquotahistory
    union all
    select
        'salesreason' as tabela
        , 10 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesreason
    union all
    select
        'salestaxrate' as tabela
        , 29 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salestaxrate
    union all
    select
        'salesterritory' as tabela
        , 10 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesterritory
    union all
    select
        'salesterritoryhistory' as tabela
        , 17 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesterritoryhistory
    union all
    select
        'shoppingcartitem' as tabela
        , 3 as esperado
        , count(*) as carregado
    from workspace.adventure_works.shoppingcartitem
    union all
    select
        'specialoffer' as tabela
        , 16 as esperado
        , count(*) as carregado
    from workspace.adventure_works.specialoffer
    union all
    select
        'specialofferproduct' as tabela
        , 538 as esperado
        , count(*) as carregado
    from workspace.adventure_works.specialofferproduct
    union all
    select
        'store' as tabela
        , 701 as esperado
        , count(*) as carregado
    from workspace.adventure_works.store
)

select
    tabela
    , esperado
    , carregado
    , case
        when esperado = carregado then 'ok'
        else 'DIVERGE'
    end as resultado
from contagem
order by resultado desc, tabela asc;


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
Tem de dar 12646112.16 exato. Se vier arredondado, o tipo virou float
em algum ponto da carga.
------------------------------------------------------------------------ */
select
    12646112.16 as esperado
    , sum(salesorderdetail.unitprice * salesorderdetail.orderqty) as receita_bruta_2011
    , case
        when sum(salesorderdetail.unitprice * salesorderdetail.orderqty) = 12646112.16
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
