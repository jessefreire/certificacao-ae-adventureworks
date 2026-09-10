-- Carga do AdventureWorks: schema Purchasing (4 de 5)
-- 5 tabelas. Cast explicito por posicao (_c0.._cN) porque o TSV
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
-- CUIDADO: rodar este arquivo duas vezes DUPLICA as linhas. O COPY INTO
-- sempre acrescenta, e `force = true` desliga a protecao de idempotencia
-- que ignoraria arquivo ja carregado. Para recarregar, use o
-- 02.99-recarga-limpa.sql, que esvazia a tabela antes.
--
-- Nome em tres niveis de proposito: nao depende do catalogo selecionado no
-- editor. O `use catalog` faria o mesmo, mas quebra o parser do sqlfluff 1.4.5.

-- Purchasing.ProductVendor: 11 colunas
copy into workspace.adventure_works.productvendor
from (
    select
        cast(_c0 as int) as productid
        , cast(_c1 as int) as businessentityid
        , cast(_c2 as decimal(19, 4)) as averageleadtime
        , cast(_c3 as decimal(19, 4)) as standardprice
        , cast(_c4 as decimal(19, 4)) as lastreceiptcost
        , cast(_c5 as timestamp) as lastreceiptdate
        , cast(_c6 as decimal(19, 4)) as minorderqty
        , cast(_c7 as decimal(19, 4)) as maxorderqty
        , cast(_c8 as decimal(19, 4)) as onorderqty
        , cast(_c9 as decimal(19, 4)) as unitmeasurecode
        , cast(_c10 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductVendor.csv'
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

-- Purchasing.PurchaseOrderDetail: 11 colunas
copy into workspace.adventure_works.purchaseorderdetail
from (
    select
        cast(_c0 as int) as purchaseorderid
        , cast(_c1 as int) as purchaseorderdetailid
        , cast(_c2 as timestamp) as duedate
        , cast(_c3 as smallint) as orderqty
        , cast(_c4 as int) as productid
        , cast(_c5 as decimal(19, 4)) as unitprice
        , cast(_c6 as decimal(19, 4)) as linetotal
        , cast(_c7 as string) as receivedqty
        , cast(_c8 as string) as rejectedqty
        , cast(_c9 as decimal(19, 4)) as stockedqty
        , cast(_c10 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/PurchaseOrderDetail.csv'
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

-- Purchasing.PurchaseOrderHeader: 13 colunas
copy into workspace.adventure_works.purchaseorderheader
from (
    select
        cast(_c0 as int) as purchaseorderid
        , cast(_c1 as smallint) as revisionnumber
        , cast(_c2 as smallint) as status
        , cast(_c3 as int) as employeeid
        , cast(_c4 as int) as vendorid
        , cast(_c5 as int) as shipmethodid
        , cast(_c6 as timestamp) as orderdate
        , cast(_c7 as timestamp) as shipdate
        , cast(_c8 as decimal(19, 4)) as subtotal
        , cast(_c9 as decimal(19, 4)) as taxamt
        , cast(_c10 as decimal(19, 4)) as freight
        , cast(_c11 as decimal(19, 4)) as totaldue
        , cast(_c12 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/PurchaseOrderHeader.csv'
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

-- Purchasing.ShipMethod: 6 colunas
copy into workspace.adventure_works.shipmethod
from (
    select
        cast(_c0 as int) as shipmethodid
        , cast(_c1 as string) as name
        , cast(_c2 as decimal(19, 4)) as shipbase
        , cast(_c3 as decimal(19, 4)) as shiprate
        , cast(_c4 as string) as rowguid
        , cast(_c5 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ShipMethod.csv'
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

-- Purchasing.Vendor: 8 colunas
copy into workspace.adventure_works.vendor
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as string) as accountnumber
        , cast(_c2 as string) as name
        , cast(_c3 as smallint) as creditrating
        , cast(_c4 as boolean) as preferredvendorstatus
        , cast(_c5 as boolean) as activeflag
        , cast(_c6 as string) as purchasingwebserviceurl
        , cast(_c7 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Vendor.csv'
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
