-- Carga do escopo minimo da analise: 17 tabelas
--
-- ATALHO OPERACIONAL, nao mudanca de arquitetura. A camada bruta continua
-- sendo as 65 tabelas dos arquivos 02.01 a 02.05; este arquivo carrega apenas
-- o que as seis perguntas do briefing e os catorze aprofundamentos exigem,
-- para a Etapa 2 poder andar quando a cota da Free Edition nao permite a
-- carga completa numa sentada.
--
-- As quatro tabelas do schema Person ja entram pelo 02.01 e estao marcadas:
-- se aquele arquivo rodou, pule as quatro.
--
-- Depois, quando a cota renovar, rodar 02.02 a 02.05 completa a camada bruta.
-- Recarregar tabela ja carregada e seguro: force = true reescreve, nao duplica.

-- Ja entra pelo 02.01-carga-person.sql: se aquele arquivo rodou,
-- pule esta instrucao e economize cota.
-- Person.Person: 13 colunas
copy into workspace.adventure_works.person
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as string) as persontype
        , cast(_c2 as boolean) as namestyle
        , cast(_c3 as string) as title
        , cast(_c4 as string) as firstname
        , cast(_c5 as string) as middlename
        , cast(_c6 as string) as lastname
        , cast(_c7 as string) as suffix
        , cast(_c8 as int) as emailpromotion
        , cast(_c9 as string) as additionalcontactinfo
        , cast(_c10 as string) as demographics
        , cast(_c11 as string) as rowguid
        , cast(_c12 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Person.csv'
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

-- Ja entra pelo 02.01-carga-person.sql: se aquele arquivo rodou,
-- pule esta instrucao e economize cota.
-- Person.StateProvince: 8 colunas
copy into workspace.adventure_works.stateprovince
from (
    select
        cast(_c0 as int) as stateprovinceid
        , cast(_c1 as string) as stateprovincecode
        , cast(_c2 as string) as countryregioncode
        , cast(_c3 as boolean) as isonlystateprovinceflag
        , cast(_c4 as string) as name
        , cast(_c5 as int) as territoryid
        , cast(_c6 as string) as rowguid
        , cast(_c7 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/StateProvince.csv'
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

-- Ja entra pelo 02.01-carga-person.sql: se aquele arquivo rodou,
-- pule esta instrucao e economize cota.
-- Person.Address: 9 colunas
copy into workspace.adventure_works.address
from (
    select
        cast(_c0 as int) as addressid
        , cast(_c1 as string) as addressline1
        , cast(_c2 as string) as addressline2
        , cast(_c3 as string) as city
        , cast(_c4 as int) as stateprovinceid
        , cast(_c5 as string) as postalcode
        , cast(_c6 as string) as spatiallocation
        , cast(_c7 as string) as rowguid
        , cast(_c8 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Address.csv'
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

-- Ja entra pelo 02.01-carga-person.sql: se aquele arquivo rodou,
-- pule esta instrucao e economize cota.
-- Person.CountryRegion: 3 colunas
copy into workspace.adventure_works.countryregion
from (
    select
        cast(_c0 as string) as countryregioncode
        , cast(_c1 as string) as name
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/CountryRegion.csv'
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

-- Production.ProductCategory: 4 colunas
copy into workspace.adventure_works.productcategory
from (
    select
        cast(_c0 as int) as productcategoryid
        , cast(_c1 as string) as name
        , cast(_c2 as string) as rowguid
        , cast(_c3 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductCategory.csv'
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

-- Production.ProductSubcategory: 5 colunas
copy into workspace.adventure_works.productsubcategory
from (
    select
        cast(_c0 as int) as productsubcategoryid
        , cast(_c1 as int) as productcategoryid
        , cast(_c2 as string) as name
        , cast(_c3 as string) as rowguid
        , cast(_c4 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductSubcategory.csv'
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

-- Production.Product: 25 colunas
copy into workspace.adventure_works.product
from (
    select
        cast(_c0 as int) as productid
        , cast(_c1 as string) as name
        , cast(_c2 as string) as productnumber
        , cast(_c3 as boolean) as makeflag
        , cast(_c4 as boolean) as finishedgoodsflag
        , cast(_c5 as string) as color
        , cast(_c6 as smallint) as safetystocklevel
        , cast(_c7 as smallint) as reorderpoint
        , cast(_c8 as decimal(19, 4)) as standardcost
        , cast(_c9 as decimal(19, 4)) as listprice
        , cast(_c10 as string) as size
        , cast(_c11 as string) as sizeunitmeasurecode
        , cast(_c12 as string) as weightunitmeasurecode
        , cast(_c13 as decimal(19, 4)) as weight
        , cast(_c14 as int) as daystomanufacture
        , cast(_c15 as string) as productline
        , cast(_c16 as string) as class
        , cast(_c17 as string) as style
        , cast(_c18 as int) as productsubcategoryid
        , cast(_c19 as int) as productmodelid
        , cast(_c20 as timestamp) as sellstartdate
        , cast(_c21 as timestamp) as sellenddate
        , cast(_c22 as timestamp) as discontinueddate
        , cast(_c23 as string) as rowguid
        , cast(_c24 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Product.csv'
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
