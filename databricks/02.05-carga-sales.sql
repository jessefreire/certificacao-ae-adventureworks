-- Carga do AdventureWorks: schema Sales (5 de 5)
-- 19 tabelas. Cast explicito por posicao (_c0.._cN) porque o TSV
-- nao tem cabecalho.
--
-- Por que a carga vem quebrada em cinco arquivos: rodar as 65 instrucoes de
-- uma vez estoura o limite de recurso da Free Edition (RESOURCE_EXHAUSTED).
-- O corte segue os cinco schemas da origem, entao cada arquivo e uma area do
-- negocio. Rodar na ordem 02.01 a 02.05 e o esperado, mas eles sao
-- independentes entre si: cada tabela le do seu proprio arquivo.
--
-- nullValue = '' e obrigatorio: sem ele, coluna int com campo vazio recebe
-- 0 em vez de NULL. So no salesorderheader sao 27.659 pedidos sem vendedor.
--
-- force = true faz a recarga ser segura: reescreve a tabela, nao duplica.
-- Entao repetir um arquivo depois de uma falha nao suja o dado.
--
-- Nome em tres niveis de proposito: nao depende do catalogo selecionado no
-- editor. O `use catalog` faria o mesmo, mas quebra o parser do sqlfluff 1.4.5.

-- Sales.CountryRegionCurrency: 3 colunas
copy into workspace.adventure_works.countryregioncurrency
from (
    select
        cast(_c0 as string) as countryregioncode
        , cast(_c1 as string) as currencycode
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/CountryRegionCurrency.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.CreditCard: 6 colunas
copy into workspace.adventure_works.creditcard
from (
    select
        cast(_c0 as int) as creditcardid
        , cast(_c1 as string) as cardtype
        , cast(_c2 as string) as cardnumber
        , cast(_c3 as smallint) as expmonth
        , cast(_c4 as smallint) as expyear
        , cast(_c5 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/CreditCard.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.Currency: 3 colunas
copy into workspace.adventure_works.currency
from (
    select
        cast(_c0 as string) as currencycode
        , cast(_c1 as string) as name
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Currency.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.CurrencyRate: 7 colunas
copy into workspace.adventure_works.currencyrate
from (
    select
        cast(_c0 as int) as currencyrateid
        , cast(_c1 as timestamp) as currencyratedate
        , cast(_c2 as string) as fromcurrencycode
        , cast(_c3 as string) as tocurrencycode
        , cast(_c4 as decimal(19, 4)) as averagerate
        , cast(_c5 as decimal(19, 4)) as endofdayrate
        , cast(_c6 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/CurrencyRate.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.Customer: 7 colunas
copy into workspace.adventure_works.customer
from (
    select
        cast(_c0 as int) as customerid
        , cast(_c1 as int) as personid
        , cast(_c2 as int) as storeid
        , cast(_c3 as int) as territoryid
        , cast(_c4 as string) as accountnumber
        , cast(_c5 as string) as rowguid
        , cast(_c6 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Customer.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.PersonCreditCard: 3 colunas
copy into workspace.adventure_works.personcreditcard
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as int) as creditcardid
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/PersonCreditCard.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SalesOrderDetail: 11 colunas
copy into workspace.adventure_works.salesorderdetail
from (
    select
        cast(_c0 as int) as salesorderid
        , cast(_c1 as int) as salesorderdetailid
        , cast(_c2 as string) as carriertrackingnumber
        , cast(_c3 as smallint) as orderqty
        , cast(_c4 as int) as productid
        , cast(_c5 as int) as specialofferid
        , cast(_c6 as decimal(19, 4)) as unitprice
        , cast(_c7 as decimal(19, 4)) as unitpricediscount
        , cast(_c8 as decimal(19, 4)) as linetotal
        , cast(_c9 as string) as rowguid
        , cast(_c10 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesOrderDetail.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SalesOrderHeader: 26 colunas
copy into workspace.adventure_works.salesorderheader
from (
    select
        cast(_c0 as int) as salesorderid
        , cast(_c1 as smallint) as revisionnumber
        , cast(_c2 as timestamp) as orderdate
        , cast(_c3 as timestamp) as duedate
        , cast(_c4 as timestamp) as shipdate
        , cast(_c5 as smallint) as status
        , cast(_c6 as boolean) as onlineorderflag
        , cast(_c7 as string) as salesordernumber
        , cast(_c8 as string) as purchaseordernumber
        , cast(_c9 as string) as accountnumber
        , cast(_c10 as int) as customerid
        , cast(_c11 as int) as salespersonid
        , cast(_c12 as int) as territoryid
        , cast(_c13 as int) as billtoaddressid
        , cast(_c14 as int) as shiptoaddressid
        , cast(_c15 as int) as shipmethodid
        , cast(_c16 as int) as creditcardid
        , cast(_c17 as string) as creditcardapprovalcode
        , cast(_c18 as int) as currencyrateid
        , cast(_c19 as decimal(19, 4)) as subtotal
        , cast(_c20 as decimal(19, 4)) as taxamt
        , cast(_c21 as decimal(19, 4)) as freight
        , cast(_c22 as decimal(19, 4)) as totaldue
        , cast(_c23 as string) as comment
        , cast(_c24 as string) as rowguid
        , cast(_c25 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesOrderHeader.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SalesOrderHeaderSalesReason: 3 colunas
copy into workspace.adventure_works.salesorderheadersalesreason
from (
    select
        cast(_c0 as int) as salesorderid
        , cast(_c1 as int) as salesreasonid
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesOrderHeaderSalesReason.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SalesPerson: 9 colunas
copy into workspace.adventure_works.salesperson
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as int) as territoryid
        , cast(_c2 as decimal(19, 4)) as salesquota
        , cast(_c3 as decimal(19, 4)) as bonus
        , cast(_c4 as decimal(19, 4)) as commissionpct
        , cast(_c5 as decimal(19, 4)) as salesytd
        , cast(_c6 as decimal(19, 4)) as saleslastyear
        , cast(_c7 as string) as rowguid
        , cast(_c8 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesPerson.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SalesPersonQuotaHistory: 5 colunas
copy into workspace.adventure_works.salespersonquotahistory
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as timestamp) as quotadate
        , cast(_c2 as decimal(19, 4)) as salesquota
        , cast(_c3 as string) as rowguid
        , cast(_c4 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesPersonQuotaHistory.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SalesReason: 4 colunas
copy into workspace.adventure_works.salesreason
from (
    select
        cast(_c0 as int) as salesreasonid
        , cast(_c1 as string) as name
        , cast(_c2 as string) as reasontype
        , cast(_c3 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesReason.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SalesTaxRate: 7 colunas
copy into workspace.adventure_works.salestaxrate
from (
    select
        cast(_c0 as int) as salestaxrateid
        , cast(_c1 as int) as stateprovinceid
        , cast(_c2 as smallint) as taxtype
        , cast(_c3 as decimal(19, 4)) as taxrate
        , cast(_c4 as string) as name
        , cast(_c5 as string) as rowguid
        , cast(_c6 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesTaxRate.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SalesTerritory: 10 colunas
copy into workspace.adventure_works.salesterritory
from (
    select
        cast(_c0 as int) as territoryid
        , cast(_c1 as string) as name
        , cast(_c2 as string) as countryregioncode
        , cast(_c3 as string) as `group`
        , cast(_c4 as decimal(19, 4)) as salesytd
        , cast(_c5 as decimal(19, 4)) as saleslastyear
        , cast(_c6 as decimal(19, 4)) as costytd
        , cast(_c7 as decimal(19, 4)) as costlastyear
        , cast(_c8 as string) as rowguid
        , cast(_c9 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesTerritory.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SalesTerritoryHistory: 6 colunas
copy into workspace.adventure_works.salesterritoryhistory
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as int) as territoryid
        , cast(_c2 as timestamp) as startdate
        , cast(_c3 as timestamp) as enddate
        , cast(_c4 as string) as rowguid
        , cast(_c5 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesTerritoryHistory.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.ShoppingCartItem: 6 colunas
copy into workspace.adventure_works.shoppingcartitem
from (
    select
        cast(_c0 as int) as shoppingcartitemid
        , cast(_c1 as string) as shoppingcartid
        , cast(_c2 as int) as quantity
        , cast(_c3 as int) as productid
        , cast(_c4 as timestamp) as datecreated
        , cast(_c5 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ShoppingCartItem.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SpecialOffer: 11 colunas
copy into workspace.adventure_works.specialoffer
from (
    select
        cast(_c0 as int) as specialofferid
        , cast(_c1 as string) as description
        , cast(_c2 as decimal(19, 4)) as discountpct
        , cast(_c3 as string) as type
        , cast(_c4 as string) as category
        , cast(_c5 as timestamp) as startdate
        , cast(_c6 as timestamp) as enddate
        , cast(_c7 as int) as minqty
        , cast(_c8 as int) as maxqty
        , cast(_c9 as string) as rowguid
        , cast(_c10 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SpecialOffer.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SpecialOfferProduct: 4 colunas
copy into workspace.adventure_works.specialofferproduct
from (
    select
        cast(_c0 as int) as specialofferid
        , cast(_c1 as int) as productid
        , cast(_c2 as string) as rowguid
        , cast(_c3 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SpecialOfferProduct.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.Store: 6 colunas
copy into workspace.adventure_works.store
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as string) as name
        , cast(_c2 as int) as salespersonid
        , cast(_c3 as string) as demographics
        , cast(_c4 as string) as rowguid
        , cast(_c5 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Store.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');
